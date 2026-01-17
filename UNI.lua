dx9.ShowConsole(false)

--// Check if NPC path is provided
if not _G.NPCPath then
    _G.NPCPath = "Workspace.Entities" -- Default fallback
end

--// Use the WORKING UI library from your script
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

local tracerEnabled = Groupbox1:AddToggle({Default = true, Text = "Tracers Enabled"})
local healthbarEnabled = Groupbox1:AddToggle({Default = true, Text = "Health Bars"})
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

--// BoxESP
function BoxESP(params)
    local target = params.Target
    local box_color = colorPicker.Value

    if type(target) ~= "number" or dx9.GetChildren(target) == nil then return end

    local hrp = dx9.FindFirstChild(target, "HumanoidRootPart") or dx9.FindFirstChild(target, "Torso") or dx9.FindFirstChild(target, "UpperTorso")
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

    -- Distance
    local dist_str = tostring(dist) .. " studs"
    dx9.DrawString({Bottom.x - (dx9.CalcTextWidth(dist_str) / 2), Bottom.y + 4}, box_color, dist_str)

    -- Name
    local name = dx9.GetName(target) or "NPC"
    dx9.DrawString({Top.x - (dx9.CalcTextWidth(name) / 2), Top.y - 20}, box_color, name)

    -- Health
    if healthbarEnabled.Value or healthtextEnabled.Value then
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
        if healthbarEnabled.Value then
            local tl = {Top.x + width + 2, Top.y + 1}
            local br = {Top.x + width + 6, Bottom.y - 1}

            dx9.DrawBox({tl[1] - 1, tl[2] - 1}, {br[1] + 1, br[2] + 1}, box_color)
            dx9.DrawFilledBox({tl[1], tl[2]}, {br[1], br[2]}, {0,0,0})

            if maxhp > 0 then
                local healthPercent = math.clamp(hp / maxhp, 0, 1)
                local fill_height = (br[2] - tl[2]) * healthPercent
                local fill_top = br[2] - fill_height

                local fill_color = dynamicHealthColor.Value and 
                    {255 * (1 - healthPercent), 255 * healthPercent, 0} or 
                    box_color

                dx9.DrawFilledBox({tl[1] + 1, fill_top}, {br[1] - 1, br[2]}, fill_color)
            end
        end
    end

    -- Tracer
    if tracerEnabled.Value then
        local screenCenterBottom = {dx9.size().width / 2, dx9.size().height}
        local targetBottom = {Top.x, Bottom.y}
        dx9.DrawLine(screenCenterBottom, targetBottom, box_color)
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
