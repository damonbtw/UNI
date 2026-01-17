dx9.ShowConsole(false)

--// Check if NPC path is provided
if not _G.NPCPath then
    _G.NPCPath = "Workspace.NPCs" -- Default fallback
end

--// Load UI Library
local Lib = loadstring(dx9.Get("https://raw.githubusercontent.com/damonbtw/UI/main/UI.lua"))()

--// Create Window
local Window = Lib:CreateWindow({
    Title = "Prince Universal ESP - @crossmyheart0551",
    Size = {550, 450},
    Position = {100, 100}
})

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

ESPGroup:AddLabel(""):AddColorPicker("ESPColor", {Default = {r = 255, g = 100, b = 100}})
ESPGroup:AddLabel("Current Path: " .. _G.NPCPath)

--// ESP Tab - Right Side
local ESPSettings = ESPTab:AddRightGroupbox("ESP Options")

local MaxDistance = ESPSettings:AddSlider({Text = "Max Distance", Default = 5000, Min = 100, Max = 10000, Suffix = " studs"})

--// Misc Tab
local MiscGroup = MiscTab:AddLeftGroupbox("Misc Features")

local SpeedHackEnabled = MiscGroup:AddToggle({Default = false, Text = "Speed Hack"})
local SpeedValue = MiscGroup:AddSlider({Text = "Speed Multiplier", Default = 1.5, Min = 1, Max = 5, Rounding = 1})
local SpeedRampUp = MiscGroup:AddToggle({Default = true, Text = "Gradual Speed Ramp"})
local RampSpeed = MiscGroup:AddSlider({Text = "Ramp Speed", Default = 0.1, Min = 0.01, Max = 0.5, Rounding = 2})

--// Settings Tab
local SettingsGroup = SettingsTab:AddLeftGroupbox("Menu Settings")

SettingsGroup:AddLabel("Menu Accent Color"):AddColorPicker("MenuAccent", {Default = {r = 100, g = 150, b = 255}})

--// Get references
local datamodel = dx9.GetDatamodel()
local workspace = dx9.FindFirstChild(datamodel, "Workspace")

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

--// Get skeleton joints for drawing
function GetSkeletonJoints(character)
    local joints = {}
    
    -- Define skeleton connections (from -> to)
    local connections = {
        {"Head", "UpperTorso"},
        {"UpperTorso", "LowerTorso"},
        {"UpperTorso", "LeftUpperArm"},
        {"LeftUpperArm", "LeftLowerArm"},
        {"LeftLowerArm", "LeftHand"},
        {"UpperTorso", "RightUpperArm"},
        {"RightUpperArm", "RightLowerArm"},
        {"RightLowerArm", "RightHand"},
        {"LowerTorso", "LeftUpperLeg"},
        {"LeftUpperLeg", "LeftLowerLeg"},
        {"LeftLowerLeg", "LeftFoot"},
        {"LowerTorso", "RightUpperLeg"},
        {"RightUpperLeg", "RightLowerLeg"},
        {"RightLowerLeg", "RightFoot"}
    }
    
    for _, connection in ipairs(connections) do
        local part1 = dx9.FindFirstChild(character, connection[1])
        local part2 = dx9.FindFirstChild(character, connection[2])
        
        if part1 and part2 then
            local pos1 = dx9.GetPosition(part1)
            local pos2 = dx9.GetPosition(part2)
            
            if pos1 and pos2 then
                table.insert(joints, {pos1, pos2})
            end
        end
    end
    
    return joints
end

--// Draw skeleton
function DrawSkeleton(character, color)
    local joints = GetSkeletonJoints(character)
    
    for _, joint in ipairs(joints) do
        local pos1 = joint[1]
        local pos2 = joint[2]
        
        local screen1 = dx9.WorldToScreen({pos1.x, pos1.y, pos1.z})
        local screen2 = dx9.WorldToScreen({pos2.x, pos2.y, pos2.z})
        
        if screen1 and screen2 and screen1.x > 0 and screen1.y > 0 and screen2.x > 0 and screen2.y > 0 then
            dx9.DrawLine({screen1.x, screen1.y}, {screen2.x, screen2.y}, color)
        end
    end
end

--// Draw ESP
function DrawNPCESP(npc, name)
    if type(npc) ~= "number" then return end
    
    local hrp = dx9.FindFirstChild(npc, "HumanoidRootPart")
    if not hrp then return end
    
    local pos = dx9.GetPosition(hrp)
    if not pos then return end
    
    local dist = GetDistanceFromPlayer(pos)
    if dist > MaxDistance.Value then return end
    
    local color = {
        ESPGroup.ESPColor.Value.r * 255,
        ESPGroup.ESPColor.Value.g * 255,
        ESPGroup.ESPColor.Value.b * 255
    }
    
    -- Skeleton ESP
    if SkeletonESP.Value then
        DrawSkeleton(npc, color)
    end
    
    -- Box ESP
    if BoxESP.Value then
        local HeadPosY = pos.y + 3
        local LegPosY = pos.y - 3.5
        local Top = dx9.WorldToScreen({pos.x, HeadPosY, pos.z})
        local Bottom = dx9.WorldToScreen({pos.x, LegPosY, pos.z})
        
        if Top and Bottom and Top.x > 0 and Top.y > 0 and Bottom.y > Top.y then
            local height = Bottom.y - Top.y
            local width = height / 2.4
            
            dx9.DrawBox({Top.x - width, Top.y}, {Top.x + width, Bottom.y}, color)
            
            -- Name
            if NameESP.Value then
                dx9.DrawString({Top.x - (dx9.CalcTextWidth(name) / 2), Top.y - 20}, color, name)
            end
            
            -- Distance
            if DistanceESP.Value then
                local dist_str = tostring(dist) .. "m"
                dx9.DrawString({Bottom.x - (dx9.CalcTextWidth(dist_str) / 2), Bottom.y + 4}, color, dist_str)
            end
        end
    end
end

--// Speed hack variables
local currentSpeedMultiplier = 1
local targetSpeedMultiplier = 1
local baseWalkSpeed = 16 -- Default Roblox walk speed

--// Speed hack updater
coroutine.wrap(function()
    while true do
        if SpeedHackEnabled.Value then
            targetSpeedMultiplier = SpeedValue.Value
            
            if SpeedRampUp.Value then
                -- Gradually ramp up/down speed
                if currentSpeedMultiplier < targetSpeedMultiplier then
                    currentSpeedMultiplier = currentSpeedMultiplier + RampSpeed.Value
                    if currentSpeedMultiplier > targetSpeedMultiplier then
                        currentSpeedMultiplier = targetSpeedMultiplier
                    end
                elseif currentSpeedMultiplier > targetSpeedMultiplier then
                    currentSpeedMultiplier = currentSpeedMultiplier - RampSpeed.Value
                    if currentSpeedMultiplier < targetSpeedMultiplier then
                        currentSpeedMultiplier = targetSpeedMultiplier
                    end
                end
            else
                -- Instant speed
                currentSpeedMultiplier = targetSpeedMultiplier
            end
            
            -- Apply speed (this part depends on dx9 API - adjust as needed)
            local lp = dx9.get_localplayer()
            if lp then
                -- Try to modify walk speed if possible
                -- Note: This may need adjustment based on dx9 capabilities
                -- For now, this is a placeholder that you may need to modify
                pcall(function()
                    local character = dx9.GetCharacter(lp)
                    if character then
                        local humanoid = dx9.FindFirstChild(character, "Humanoid")
                        if humanoid then
                            -- Attempt to set walk speed
                            -- This may require a different method depending on dx9
                        end
                    end
                end)
            end
        else
            -- Reset to normal speed
            currentSpeedMultiplier = 1
        end
        
        dx9.Sleep(50) -- Update every 50ms
    end
end)()

--// Main ESP Loop
coroutine.wrap(function()
    while true do
        if ESPEnabled.Value then
            local npcFolder = GetObjectFromPath(_G.NPCPath)
            
            if npcFolder then
                local npcs = dx9.GetChildren(npcFolder)
                if npcs then
                    for _, npc in ipairs(npcs) do
                        local npcName = dx9.GetName(npc)
                        if npcName then
                            pcall(DrawNPCESP, npc, npcName)
                        end
                    end
                end
            end
        end
        
        dx9.Sleep(0)
    end
end)()
