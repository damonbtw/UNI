dx9.ShowConsole(false)

--// Check if NPC path is provided
if not _G.NPCPath then
    _G.NPCPath = "Workspace.Entities" -- Default fallback
end

--// Use the WORKING UI library
local Lib = loadstring(dx9.Get("https://raw.githubusercontent.com/soupg/DXLibUI/main/main.lua"))()

local Window = Lib:CreateWindow({
    Title = "Prince Universal ESP - @crossmyheart0551 👑",
    Size = {0,0},
    Resizable = false,
    ToggleKey = "[F5]",
    FooterMouseCoords = false
})

local Tab1 = Window:AddTab("ESP")
local Groupbox1 = Tab1:AddMiddleGroupbox("ESP Settings")

local espEnabled = Groupbox1:AddToggle({Default = true, Text = "ESP Enabled"}):OnChanged(function(value)
    Lib:Notify(value and "ESP Enabled" or "ESP Disabled", 1)
end)

local boxEnabled = Groupbox1:AddToggle({Default = true, Text = "Box ESP"})
local box2D = Groupbox1:AddToggle({Default = false, Text = "2D Box (not corner)"})
local skeletonEnabled = Groupbox1:AddToggle({Default = false, Text = "Skeleton ESP"})
local tracerEnabled = Groupbox1:AddToggle({Default = true, Text = "Tracers"})
local healthbarEnabled = Groupbox1:AddToggle({Default = true, Text = "Health Bar"})
local healthtextEnabled = Groupbox1:AddToggle({Default = true, Text = "Health Text"})
local dynamicHealthColor = Groupbox1:AddToggle({Default = true, Text = "Dynamic Health Color"})

local colorPicker = Groupbox1:AddColorPicker({Default = {255, 100, 100}, Text = "ESP Color"})
local distSlider = Groupbox1:AddSlider({Default = 5000, Text = "Distance Limit", Min = 0, Max = 10000, Rounding = 0})

Groupbox1:AddLabel("Current Path: " .. _G.NPCPath)

--// Get workspace
local workspace = dx9.FindFirstChild(dx9.GetDatamodel(), "Workspace")

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
    else
        current = workspace
    end
    
    for _, part in ipairs(parts) do
        if not current then return nil end
        current = dx9.FindFirstChild(current, part)
    end
    
    return current
end

--// Distance func
function GetDistanceFromPlayer(v)
    local lp = dx9.get_localplayer()
    if not lp then return 99999 end
    local v1 = lp.Position
    local a = (v1.x - v.x) ^ 2 + (v1.y - v.y) ^ 2 + (v1.z - v.z) ^ 2
    return math.floor(math.sqrt(a) + 0.5)
end

--// Draw skeleton with correct body part names from your game
function DrawSkeleton(character, color)
    -- Based on the explorer image you sent
    local connections = {
        -- Head to neck/torso
        {"Head", "Torso"},
        {"Head", "Neck"},
        
        -- Torso to shoulders
        {"Torso", "Left Shoulder"},
        {"Torso", "Right Shoulder"},
        
        -- Arms
        {"Left Shoulder", "Left Arm"},
        {"Right Shoulder", "Right Arm"},
        
        -- Torso to hips
        {"Torso", "Left Hip"},
        {"Torso", "Right Hip"},
        
        -- Legs
        {"Left Hip", "Left Leg"},
        {"Right Hip", "Right Leg"}
    }
    
    for _, connection in ipairs(connections) do
        local part1 = dx9.FindFirstChild(character, connection[1])
        local part2 = dx9.FindFirstChild(character, connection[2])
        
        if part1 and part2 then
            local pos1 = dx9.GetPosition(part1)
            local pos2 = dx9.GetPosition(part2)
            
            if pos1 and pos2 then
                local screen1 = dx9.WorldToScreen({pos1.x, pos1.y, pos1.z})
                local screen2 = dx9.WorldToScreen({pos2.x, pos2.y, pos2.z})
                
                if screen1 and screen2 and screen1.x > 0 and screen1.y > 0 and screen2.x > 0 and screen2.y > 0 then
                    dx9.DrawLine({screen1.x, screen1.y}, {screen2.x, screen2.y}, color)
                end
            end
        end
    end
end

--// BoxESP
function BoxESP(params)
    local target = params.Target
    local box_color = colorPicker.Value

    if type(target) ~= "number" or dx9.GetChildren(target) == nil then return end

    local hrp = dx9.FindFirstChild(target, "HumanoidRootPart") or dx9.FindFirstChild(target, "Torso")
    if not hrp then return end

    local torso = dx9.GetPosition(hrp)
    if not torso then return end

    local dist = GetDistanceFromPlayer(torso)
    if dist > distSlider.Value then return end

    local HeadPosY = torso.y + 3
    local LegPosY = torso.y - 3.5
    local Top = dx9.WorldToScreen({torso.x, HeadPosY, torso.z})
    local Bottom = dx9.WorldToScreen({torso.x, LegPosY, torso.z})

    if not (Top and Bottom and Top.x > 0 and Top.y > 0 and Bottom.y > Top.y) then return end

    local height = Bottom.y - Top.y
    local width = height / 2.4

    -- Skeleton ESP (draw first so it's behind everything)
    if skeletonEnabled.Value then
        DrawSkeleton(target, box_color)
    end

    -- Box ESP
    if boxEnabled.Value then
        if box2D.Value then
            -- Simple 2D box (full rectangle)
            dx9.DrawBox({Top.x - width, Top.y}, {Top.x + width, Bottom.y}, box_color)
        else
            -- Corner box
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
                dx9.DrawLine(line[1], line[2], box_color)
            end
        end
    end

    -- Distance
    local dist_str = tostring(dist) .. " studs"
    dx9.DrawString({Bottom.x - (dx9.CalcTextWidth(dist_str) / 2), Bottom.y + 4}, box_color, dist_str)

    -- Name
    local name = dx9.GetName(target) or "NPC"
    dx9.DrawString({Top.x - (dx9.CalcTextWidth(name) / 2), Top.y - 20}, box_color, name)

    -- Health
    local humanoid = dx9.FindFirstChild(target, "Humanoid")
    local hp = 100
    local maxhp = 100
    if humanoid then
        hp = dx9.GetHealth(humanoid) or 100
        maxhp = dx9.GetMaxHealth(humanoid) or 100
    end

    -- Health Text
    if healthtextEnabled.Value then
        local h_str = math.floor(hp) .. "/" .. math.floor(maxhp)
        dx9.DrawString({Top.x - (dx9.CalcTextWidth(h_str) / 2), Top.y - 38}, box_color, h_str)
    end

    -- Health Bar
    if healthbarEnabled.Value and maxhp > 0 then
        local barWidth = 4
        local barPadding = 2
        local tl = {Top.x + width + barPadding, Top.y}
        local br = {Top.x + width + barPadding + barWidth, Bottom.y}
        
        local healthPercent = math.max(0, math.min(1, hp / maxhp))
        
        local fill_color
        if dynamicHealthColor.Value then
            local red = math.floor(255 * (1 - healthPercent))
            local green = math.floor(255 * healthPercent)
            fill_color = {red, green, 0}
        else
            fill_color = box_color
        end
        
        dx9.DrawBox({tl[1] - 1, tl[2] - 1}, {br[1] + 1, br[2] + 1}, {255, 255, 255})
        dx9.DrawFilledBox({tl[1], tl[2]}, {br[1], br[2]}, {0, 0, 0})
        
        local barHeight = br[2] - tl[2]
        local fillHeight = barHeight * healthPercent
        local fillTop = br[2] - fillHeight
        
        if fillHeight > 1 then
            dx9.DrawFilledBox({tl[1], fillTop}, {br[1], br[2]}, fill_color)
        end
    end

    -- Tracer
    if tracerEnabled.Value then
        local screenCenterBottom = {dx9.size().width / 2, dx9.size().height}
        dx9.DrawLine(screenCenterBottom, {Top.x, Bottom.y}, box_color)
    end
end

--// Main loop
coroutine.wrap(function()
    while true do
        if espEnabled.Value then
            local npcFolder = GetObjectFromPath(_G.NPCPath)
            
            if npcFolder then
                local entities = dx9.GetChildren(npcFolder)
                if entities then
                    for _, ent in ipairs(entities) do
                        pcall(BoxESP, {Target = ent})
                    end
                end
            end
        end
        dx9.Sleep(0)
    end
end)()

Lib:Notify("Universal ESP Loaded! Path: " .. _G.NPCPath, 3)
