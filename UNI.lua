dx9.ShowConsole(true) -- Enable console for debugging

--// Check if NPC path is provided
if not _G.NPCPath then
    _G.NPCPath = "Workspace.Entities" -- Default fallback
end

print("=== Universal ESP Starting ===")
print("NPC Path:", _G.NPCPath)

--// Load UI Library
local Lib = loadstring(dx9.Get("https://raw.githubusercontent.com/damonbtw/UI/main/UI.lua"))()
print("UI Library loaded")

--// Create Window
local Window = Lib:CreateWindow({
    Title = "Prince Universal ESP - @crossmyheart0551",
    Size = {550, 450},
    Position = {100, 100}
})
print("Window created")

--// Create Tabs
local ESPTab = Window:AddTab("ESP")
local MiscTab = Window:AddTab("Misc")
local SettingsTab = Window:AddTab("Settings")

--// ESP Tab - Left Side
local ESPGroup = ESPTab:AddLeftGroupbox("ESP Settings")

local ESPEnabled = ESPGroup:AddToggle({Default = true, Text = "Enable ESP"})
local BoxESP = ESPGroup:AddToggle({Default = true, Text = "Box ESP"})
local SkeletonESP = ESPGroup:AddToggle({Default = false, Text = "Skeleton ESP"})
local NameESP = ESPGroup:AddToggle({Default = true, Text = "Name ESP"})
local DistanceESP = ESPGroup:AddToggle({Default = true, Text = "Distance ESP"})
local TracerESP = ESPGroup:AddToggle({Default = true, Text = "Tracer ESP"})
local HealthBarESP = ESPGroup:AddToggle({Default = true, Text = "Health Bar"})
local HealthTextESP = ESPGroup:AddToggle({Default = true, Text = "Health Text"})

--// ESP Color Picker
local ESPColorPicker = ESPGroup:AddLabel("ESP Color"):AddColorPicker("ESPColor", {
    Default = Color3.fromRGB(255, 100, 100),
    Title = "ESP Color"
})

ESPGroup:AddLabel("Current Path: " .. _G.NPCPath)

--// ESP Tab - Right Side
local ESPSettings = ESPTab:AddRightGroupbox("ESP Options")

local MaxDistance = ESPSettings:AddSlider({Text = "Max Distance", Default = 5000, Min = 100, Max = 10000, Suffix = " studs"})
local DynamicHealthColor = ESPSettings:AddToggle({Default = true, Text = "Dynamic Health Color"})
local CornerBox = ESPSettings:AddToggle({Default = true, Text = "Corner Box Style"})

--// Misc Tab
local MiscGroup = MiscTab:AddLeftGroupbox("Movement")

local SpeedHackEnabled = MiscGroup:AddToggle({Default = false, Text = "Speed Hack"})
local SpeedValue = MiscGroup:AddSlider({Text = "Speed Multiplier", Default = 2, Min = 1, Max = 5, Rounding = 1})
local SpeedRampUp = MiscGroup:AddToggle({Default = true, Text = "Gradual Speed Ramp"})
local RampSpeed = MiscGroup:AddSlider({Text = "Ramp Speed", Default = 0.05, Min = 0.01, Max = 0.2, Rounding = 2})

--// Settings Tab
local SettingsGroup = SettingsTab:AddLeftGroupbox("Menu Settings")

local MenuAccentPicker = SettingsGroup:AddLabel("Menu Accent Color"):AddColorPicker("MenuAccent", {
    Default = Color3.fromRGB(100, 150, 255),
    Title = "Menu Accent"
})

print("GUI setup complete")

--// Get references
local datamodel = dx9.GetDatamodel()
local workspace = dx9.FindFirstChild(datamodel, "Workspace")

print("Datamodel:", datamodel)
print("Workspace:", workspace)

--// Distance calculation
function GetDistanceFromPlayer(pos)
    local lp = dx9.get_localplayer()
    if not lp then return 99999 end
    local v1 = lp.Position
    local a = (v1.x - pos.x) ^ 2 + (v1.y - pos.y) ^ 2 + (v1.z - pos.z) ^ 2
    return math.floor(math.sqrt(a) + 0.5)
end

--// Parse path to get NPC folder
function GetObjectFromPath(pathString)
    if not pathString or pathString == "" then return nil end
    
    local parts = {}
    for part in string.gmatch(pathString, "[^%.]+") do
        table.insert(parts, part)
    end
    
    if #parts == 0 then return nil end
    
    local current
    if parts[1] == "Workspace" or parts[1] == "workspace" then
        current = workspace
        table.remove(parts, 1)
    elseif parts[1] == "game" then
        current = datamodel
        table.remove(parts, 1)
        if parts[1] == "Workspace" or parts[1] == "workspace" then
            current = workspace
            table.remove(parts, 1)
        end
    else
        current = workspace
    end
    
    for _, part in ipairs(parts) do
        if not current then return nil end
        current = dx9.FindFirstChild(current, part)
    end
    
    return current
end

--// Get color from color picker
function GetESPColor()
    local colorValue = ESPColorPicker.Value
    if type(colorValue) == "table" and colorValue.r then
        return {
            math.floor(colorValue.r * 255),
            math.floor(colorValue.g * 255),
            math.floor(colorValue.b * 255)
        }
    else
        return {255, 100, 100}
    end
end

--// Draw corner box
function DrawCornerBox(Top, Bottom, width, height, color)
    local lines = {
        {{Top.x - width, Top.y}, {Top.x - width + (width/2), Top.y}},
        {{Top.x - width, Top.y}, {Top.x - width, Top.y + (height/4)}},
        {{Top.x + width, Top.y}, {Top.x + width - (width/2), Top.y}},
        {{Top.x + width, Top.y}, {Top.x + width, Top.y + (height/4)}},
        {{Top.x - width, Bottom.y}, {Top.x - width + (width/2), Bottom.y}},
        {{Top.x - width, Bottom.y}, {Top.x - width, Bottom.y - (height/4)}},
        {{Top.x + width, Bottom.y}, {Top.x + width - (width/2), Bottom.y}},
        {{Top.x + width, Bottom.y}, {Top.x + width, Bottom.y - (height/4)}}
    }
    for _, line in ipairs(lines) do
        dx9.DrawLine(line[1], line[2], color)
    end
end

--// Draw ESP
function DrawNPCESP(npc, name)
    if type(npc) ~= "number" then return end
    
    local hrp = dx9.FindFirstChild(npc, "HumanoidRootPart") or dx9.FindFirstChild(npc, "Torso") or dx9.FindFirstChild(npc, "UpperTorso")
    if not hrp then return end
    
    local pos = dx9.GetPosition(hrp)
    if not pos then return end
    
    local dist = GetDistanceFromPlayer(pos)
    if dist > MaxDistance.Value then return end
    
    local color = GetESPColor()
    
    local HeadPosY = pos.y + 3
    local LegPosY = pos.y - 3.5
    local Top = dx9.WorldToScreen({pos.x, HeadPosY, pos.z})
    local Bottom = dx9.WorldToScreen({pos.x, LegPosY, pos.z})
    
    if not (Top and Bottom and Top.x > 0 and Top.y > 0 and Bottom.y > Top.y) then return end
    
    local height = Bottom.y - Top.y
    local width = height / 2.4
    
    -- Box ESP
    if BoxESP.Value then
        if CornerBox.Value then
            DrawCornerBox(Top, Bottom, width, height, color)
        else
            dx9.DrawBox({Top.x - width, Top.y}, {Top.x + width, Bottom.y}, color)
        end
    end
    
    -- Health Bar (right side, vertical)
    if HealthBarESP.Value then
        local humanoid = dx9.FindFirstChild(npc, "Humanoid")
        local hp = 100
        local maxhp = 100
        
        if humanoid then
            hp = dx9.GetHealth(humanoid) or 100
            maxhp = dx9.GetMaxHealth(humanoid) or 100
        end
        
        local tl = {Top.x + width + 2, Top.y + 1}
        local br = {Top.x + width + 6, Bottom.y - 1}
        
        -- Outline
        dx9.DrawBox({tl[1] - 1, tl[2] - 1}, {br[1] + 1, br[2] + 1}, color)
        
        -- Black background
        dx9.DrawFilledBox({tl[1], tl[2]}, {br[1], br[2]}, {0, 0, 0})
        
        -- Health fill
        if maxhp > 0 then
            local healthPercent = math.min(math.max(hp / maxhp, 0), 1)
            local fill_height = (br[2] - tl[2]) * healthPercent
            local fill_top = br[2] - fill_height
            
            local fill_color = color
            if DynamicHealthColor.Value then
                fill_color = {
                    math.floor(255 * (1 - healthPercent)),
                    math.floor(255 * healthPercent),
                    0
                }
            end
            
            dx9.DrawFilledBox({tl[1] + 1, fill_top}, {br[1] - 1, br[2]}, fill_color)
        end
        
        -- Health text
        if HealthTextESP.Value and humanoid then
            local h_str = math.floor(hp) .. "/" .. math.floor(maxhp)
            dx9.DrawString({Top.x - (dx9.CalcTextWidth(h_str) / 2), Top.y - 38}, color, h_str)
        end
    end
    
    -- Tracer ESP
    if TracerESP.Value then
        local screenSize = dx9.size()
        local screenCenterBottom = {screenSize.width / 2, screenSize.height}
        dx9.DrawLine(screenCenterBottom, {Top.x, Bottom.y}, color)
    end
    
    -- Name
    if NameESP.Value then
        dx9.DrawString({Top.x - (dx9.CalcTextWidth(name) / 2), Top.y - 20}, color, name)
    end
    
    -- Distance
    if DistanceESP.Value then
        local dist_str = tostring(dist) .. " studs"
        dx9.DrawString({Bottom.x - (dx9.CalcTextWidth(dist_str) / 2), Bottom.y + 4}, color, dist_str)
    end
end

--// Speed hack variables
local currentSpeedMultiplier = 1
local normalSpeed = 16

--// Main ESP Loop
print("Starting ESP loop...")
coroutine.wrap(function()
    local loopCount = 0
    while true do
        loopCount = loopCount + 1
        
        -- Debug every 100 loops
        if loopCount % 100 == 0 then
            print("ESP Loop running:", loopCount, "ESP Enabled:", ESPEnabled.Value)
        end
        
        if ESPEnabled.Value then
            local npcFolder = GetObjectFromPath(_G.NPCPath)
            
            if loopCount == 1 then
                print("NPC Folder pointer:", npcFolder)
            end
            
            if npcFolder then
                local npcs = dx9.GetChildren(npcFolder)
                
                if loopCount == 1 then
                    print("NPCs found:", npcs and #npcs or 0)
                end
                
                if npcs then
                    for _, npc in ipairs(npcs) do
                        local npcName = dx9.GetName(npc)
                        if npcName then
                            pcall(DrawNPCESP, npc, npcName)
                        end
                    end
                end
            else
                if loopCount % 100 == 0 then
                    print("WARNING: NPC folder not found at path:", _G.NPCPath)
                end
            end
        end
        
        dx9.Sleep(0)
    end
end)()

print("=== ESP fully loaded ===")
