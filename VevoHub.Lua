-- Venom Hub
-- V.1.2 (Updated with new features)

local repo = 'https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/'

local Library = loadstring(game:HttpGet(repo .. 'Library.lua'))()
local ThemeManager = loadstring(game:HttpGet(repo .. 'addons/ThemeManager.lua'))()
local SaveManager = loadstring(game:HttpGet(repo .. 'addons/SaveManager.lua'))()

-- ============== KEY SYSTEM ==============
local HttpService = game:GetService('HttpService')
local Players = game:GetService('Players')
local LocalPlayer = Players.LocalPlayer

-- Persistent HWID Generator (Stable across sessions) - FIXED VERSION
local function GetStableHWID()
    local success, result = pcall(function()
        return readfile("VevoHub/hwid.dat")
    end)
    
    if success and result and result ~= "" then
        return result
    else
        -- Generate a stable HWID using only Roblox-specific values
        local userId = LocalPlayer.UserId
        local accountId = LocalPlayer.AccountAge
        local nameHash = string.gsub(LocalPlayer.Name, "[^%w]", "")
        
        -- Create a unique identifier from Roblox account data
        local hwidBase = string.format("%d-%d-%s", 
            userId, 
            accountId, 
            nameHash:sub(1, math.min(10, #nameHash))
        )
        
        -- Generate a GUID and combine with the hash for consistent format
        local guid = HttpService:GenerateGUID(false)
        local stableHwid = guid:sub(1, 8) .. "-" .. string.sub(hwidBase, 1, 8) .. "-" .. guid:sub(25, 32)
        
        -- Save it for future sessions
        pcall(function()
            writefile("VevoHub/hwid.dat", stableHwid)
        end)
        
        return stableHwid
    end
end

-- Key Database (Saved to file)
local function LoadKeyDatabase()
    local success, data = pcall(function()
        return readfile("VevoHub/keydb.json")
    end)
    
    if success and data and data ~= "" then
        local decoded = HttpService:JSONDecode(data)
        return decoded
    else
        -- Initialize with master key
        local defaultDB = {
            ["blankvevo"] = {   -- Master key - accepts any HWID
                hwid = "MASTER",
                activated = true,
                expiry = "never"
            }
        }
        
        -- Save default database
        pcall(function()
            writefile("VevoHub/keydb.json", HttpService:JSONEncode(defaultDB))
        end)
        
        return defaultDB
    end
end

local function SaveKeyDatabase(database)
    pcall(function()
        writefile("VevoHub/keydb.json", HttpService:JSONEncode(database))
    end)
end

local keyDatabase = LoadKeyDatabase()
local currentHWID = GetStableHWID()

-- Check if current HWID is already activated
local function IsHWIDActivated()
    for key, data in pairs(keyDatabase) do
        if data.hwid == currentHWID or data.hwid == "MASTER" then
            return true, key
        end
    end
    return false, nil
end

-- Validate and activate key
local function ValidateAndActivateKey(inputKey)
    inputKey = inputKey:gsub("%s+", ""):lower()
    
    -- Check if key exists
    if keyDatabase[inputKey] then
        local keyData = keyDatabase[inputKey]
        
        -- Master key (blankvevo) accepts any HWID
        if inputKey == "blankvevo" then
            return true, "activated"
        end
        
        -- Check if key is already used
        if keyData.hwid and keyData.hwid ~= "" then
            if keyData.hwid == currentHWID then
                return true, "registered" -- Already activated on this HWID
            else
                return false, "inuse" -- Used by another HWID
            end
        else
            -- Activate the key
            keyDatabase[inputKey] = {
                hwid = currentHWID,
                activated = true,
                activatedDate = os.date("%Y-%m-%d"),
                expiry = "never"
            }
            SaveKeyDatabase(keyDatabase)
            return true, "activated"
        end
    end
    
    return false, "invalid"
end

-- Create Registration Window with Gray Accent
local RegistrationWindow = Library:CreateWindow({
    Title = 'Vevo Hub | Key System',
    Center = true,
    AutoShow = false,
    TabPadding = 8,
    MenuFadeTime = 0.2,
    Size = UDim2.new(0, 400, 0, 250)
})

-- Set gray accent for registration window
Library.AccentColor = Color3.fromHex('#333333')
RegistrationWindow.AccentColor = Color3.fromHex('#333333')
RegistrationWindow.MainColor = Color3.fromHex('#1c1c1c')
RegistrationWindow.BackgroundColor = Color3.fromHex('#141414')
RegistrationWindow.OutlineColor = Color3.fromHex('#323232')

local RegistrationTab = RegistrationWindow:AddTab('Authentication')
local RegistrationGroup = RegistrationTab:AddLeftGroupbox('Key Authentication')

local keyStatus = "Not Activated"
local isAuthenticated = false

-- Check existing activation first
local activated, activatedKey = IsHWIDActivated()
if activated then
    isAuthenticated = true
    keyStatus = "Activated (" .. activatedKey .. ")"
    
    RegistrationWindow:Notification({
        Title = 'Already Activated',
        Content = 'HWID already verified! Loading hub...',
        Duration = 2
    })
    
    task.wait(1)
    RegistrationWindow:Unload()
    LoadMainScript()
else
    -- UI Elements
    RegistrationGroup:AddLabel('━━━━━━━━━━━━━━━━━━━━')
    
    local hwidDisplay = RegistrationGroup:AddLabel('HWID: ' .. currentHWID:sub(1, 15) .. '...')
    local statusDisplay = RegistrationGroup:AddLabel('Status: ' .. keyStatus)
    statusDisplay.TextColor3 = Color3.fromRGB(255, 100, 100)
    
    RegistrationGroup:AddDivider()
    
    local keyInput = RegistrationGroup:AddInput('KeyInput', {
        Text = 'Enter your key',
        Default = '',
        Placeholder = 'Enter your activation key',
        Numeric = false,
        Finished = false
    })
    
    RegistrationGroup:AddButton('Activate Key', function()
        local key = keyInput.Value
        if key and #key > 0 then
            local valid, reason = ValidateAndActivateKey(key)
            
            if valid then
                if reason == "activated" then
                    keyStatus = "Activated Successfully!"
                    isAuthenticated = true
                    
                    statusDisplay.Text = 'Status: ' .. keyStatus
                    statusDisplay.TextColor3 = Color3.fromRGB(100, 255, 100)
                    
                    RegistrationWindow:Notification({
                        Title = 'Success',
                        Content = 'Key activated successfully!',
                        Duration = 2
                    })
                    
                    task.wait(1)
                    RegistrationWindow:Unload()
                    LoadMainScript()
                    
                elseif reason == "registered" then
                    keyStatus = "Key Already Activated!"
                    isAuthenticated = true
                    
                    statusDisplay.Text = 'Status: ' .. keyStatus
                    statusDisplay.TextColor3 = Color3.fromRGB(255, 200, 0)
                    
                    RegistrationWindow:Notification({
                        Title = 'Already Activated',
                        Content = 'Key is already activated on this device!',
                        Duration = 2
                    })
                    
                    task.wait(1)
                    RegistrationWindow:Unload()
                    LoadMainScript()
                end
            else
                if reason == "inuse" then
                    keyStatus = "Key Already in Use!"
                    statusDisplay.TextColor3 = Color3.fromRGB(255, 100, 100)
                    
                    RegistrationWindow:Notification({
                        Title = 'Error',
                        Content = 'This key is already activated on another device!',
                        Duration = 3
                    })
                else
                    keyStatus = "Invalid Key!"
                    statusDisplay.TextColor3 = Color3.fromRGB(255, 100, 100)
                    
                    RegistrationWindow:Notification({
                        Title = 'Error',
                        Content = 'Invalid key. Please check and try again.',
                        Duration = 3
                    })
                end
                statusDisplay.Text = 'Status: ' .. keyStatus
            end
        else
            RegistrationWindow:Notification({
                Title = 'Error',
                Content = 'Please enter a key!',
                Duration = 2
            })
        end
    end)
    
    RegistrationGroup:AddButton('Copy HWID', function()
        setclipboard(currentHWID)
        RegistrationWindow:Notification({
            Title = 'Copied',
            Content = 'HWID copied to clipboard!',
            Duration = 2
        })
    end)
    
    RegistrationGroup:AddDivider()
    RegistrationGroup:AddLabel('━━━━━━━━━━━━━━━━━━━━')
    
    -- Status indicator
    local statusFrame = Instance.new("Frame")
    statusFrame.Size = UDim2.new(1, -20, 0, 30)
    statusFrame.Position = UDim2.new(0, 10, 0, 10)
    statusFrame.BackgroundColor3 = Color3.fromHex('#1e1e1e')
    statusFrame.BorderSizePixel = 0
    statusFrame.Parent = RegistrationTab:GetLeftGroupbox('Key Authentication').Frame
    
    local statusCorner = Instance.new("UICorner")
    statusCorner.CornerRadius = UDim.new(0, 4)
    statusCorner.Parent = statusFrame
    
    local statusText = Instance.new("TextLabel")
    statusText.Size = UDim2.new(1, 0, 1, 0)
    statusText.BackgroundTransparency = 1
    statusText.Text = "🔐 Enter your key to activate"
    statusText.TextColor3 = Color3.fromHex('#aaaaaa')
    statusText.Font = Enum.Font.Gotham
    statusText.TextSize = 14
    statusText.Parent = statusFrame
end

-- ============== MAIN SCRIPT ==============
function LoadMainScript()
    -- Set grayish accent color
    Library.AccentColor = Color3.fromHex('#333333')
    
    local Window = Library:CreateWindow({
        Title = 'Vevo Hub v1.2',
        Center = true,
        AutoShow = true,
        TabPadding = 8,
        MenuFadeTime = 0.2
    })
    
    -- Set window accent color
    Window.AccentColor = Color3.fromHex('#333333')
    Window.MainColor = Color3.fromHex('#1c1c1c')
    Window.BackgroundColor = Color3.fromHex('#141414')
    Window.OutlineColor = Color3.fromHex('#323232')
    
    local Tabs = {
        Main = Window:AddTab('Main'),
        Interpolation = Window:AddTab('Interpolation'),
        Pack = Window:AddTab('Pack'),
        Configuration = Window:AddTab('Configuration'),
        ['UI Settings'] = Window:AddTab('UI Settings'),
    }
    
    -- Animation ID tracking for Rin pack (ONLY for Aimbot V1 and Prehold)
    local Animations = {
        Prehold = 'rbxassetid://15434792076',
        AimbotV1 = 'rbxassetid://15434792076'
    }
    
    local RinAnimations = {
        Prehold = 'rbxassetid://139333593369314',
        AimbotV1 = 'rbxassetid://139333593369314'
    }
    
    -- LEFT SIDE GROUPS (MAIN TAB)
    local SpeedGroup = Tabs.Main:AddLeftGroupbox('Speed Hack')
    SpeedGroup:AddToggle('SpeedToggle', {
        Text = 'Enable Speed Hack',
        Default = false,
        Callback = function(Value)
            if Value then
                local speedValue = Options.SpeedSlider.Value
                loadstring([[
                    local ReplicatedStorage = game:GetService("ReplicatedStorage")
                    local PSSettings = ReplicatedStorage:WaitForChild("PSSettings")
                    local runSpeedMult = PSSettings:WaitForChild("RunSpeedMult")
                    local LOCKED_VALUE = ]] .. speedValue .. [[
                    runSpeedMult.Value = LOCKED_VALUE
                    runSpeedMult:GetPropertyChangedSignal("Value"):Connect(function()
                        if runSpeedMult.Value ~= LOCKED_VALUE then
                            runSpeedMult.Value = LOCKED_VALUE
                        end
                    end)
                    task.spawn(function()
                        while true do
                            if runSpeedMult.Value ~= LOCKED_VALUE then
                                runSpeedMult.Value = LOCKED_VALUE
                            end
                            task.wait(0.05)
                        end
                    end)
                ]])()
            end
        end
    })
    
    SpeedGroup:AddSlider('SpeedSlider', {
        Text = 'Speed Multiplier',
        Default = 1.03,
        Min = 1.00,
        Max = 5.00,
        Rounding = 2,
        Callback = function(Value)
            if Toggles.SpeedToggle.Value then
                loadstring([[
                    local ReplicatedStorage = game:GetService("ReplicatedStorage")
                    local PSSettings = ReplicatedStorage:WaitForChild("PSSettings")
                    local runSpeedMult = PSSettings:WaitForChild("RunSpeedMult")
                    runSpeedMult.Value = ]] .. Value .. [[
                ]])()
            end
        end
    })
    
    local StaminaGroup = Tabs.Main:AddLeftGroupbox('Stamina')
    StaminaGroup:AddToggle('StaminaToggle', {
        Text = 'Infinite Stamina',
        Default = false,
        Callback = function(Value)
            if Value then
                loadstring([[
                    getgenv().on = true
                    while on do
                    wait()
                    local playerStats = game.Players.LocalPlayer.Character:FindFirstChild("Stats")
                    if playerStats then
                        playerStats.Stamina.Value = 100
                        playerStats.StaminaCheck.Value = 100
                    end
                    wait()
                    end
                ]])()
            else
                getgenv().on = false
            end
        end
    })
    
    local KickGroup = Tabs.Main:AddLeftGroupbox('No Kick CD')
    KickGroup:AddToggle('KickToggle', {
        Text = 'No Kick Cooldown',
        Default = false,
        Callback = function(Value)
            if Value then
                loadstring([[
                    getgenv().on = true
                    while on do
                    if game.Players.LocalPlayer.Character.Status:FindFirstChild("KickCD") then
                        game.Players.LocalPlayer.Character.Status:FindFirstChild("KickCD"):Destroy()
                    end
                    wait()
                    end
                ]])()
            else
                getgenv().on = false
            end
        end
    })
    
    local LastDiscGroup = Tabs.Main:AddLeftGroupbox('Auto Last Disc')
    LastDiscGroup:AddToggle('LastDiscToggle', {
        Text = 'Enable Auto Last Disc',
        Default = false,
        Callback = function(Value)
            if Value then
                Library:Notify('Auto Last Disc is not functional yet', 3)
            end
        end
    })
    
    LastDiscGroup:AddLabel('Keybind: J')
    
    -- SHOVE REACH FEATURE
    local ShoveGroup = Tabs.Main:AddLeftGroupbox('Shove Reach')
    ShoveGroup:AddToggle('ShoveToggle', {
        Text = 'Enable Shove Reach',
        Default = false,
        Callback = function(Value)
            if Value then
                local reachValue = Options.ShoveReachSlider.Value
                loadstring([[
                    local Players = game:GetService("Players")
                    local ReplicatedStorage = game:GetService("ReplicatedStorage")
                    local Workspace = game:GetService("Workspace")
                    local RunService = game:GetService("RunService")

                    local Knit = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Knit"))
                    local KeyHandlerService = Knit.GetService("KeyHandlerService")
                    local shoveRemote = KeyHandlerService:GetKey("ShoveCheck")

                    local reachDistance = ]] .. reachValue .. [[
                    local cooldownTime = 15
                    local lastUsedTime = 0
                    local animationId = 'rbxassetid://15417325996'
                    local scriptActive = true

                    local function getNearestPlayer()
                        local localPlayer = Players.LocalPlayer
                        local character = localPlayer.Character
                        if not character or not character:FindFirstChild("HumanoidRootPart") then return nil end

                        local nearestPlayer = nil
                        local shortestDistance = math.huge

                        for _, player in ipairs(Players:GetPlayers()) do
                            if player ~= localPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                                local dist = (character.HumanoidRootPart.Position - player.Character.HumanoidRootPart.Position).Magnitude
                                
                                if dist < shortestDistance then
                                    shortestDistance = dist
                                    nearestPlayer = player
                                end
                            end
                        end
                        return nearestPlayer, shortestDistance
                    end

                    local function playShoveAnimation()
                        local character = Players.LocalPlayer.Character
                        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
                        local animator = humanoid and (humanoid:FindFirstChildOfClass("Animator") or humanoid:WaitForChild("Animator"))
                        
                        if animator then
                            local anim = Instance.new("Animation")
                            anim.AnimationId = animationId
                            local track = animator:LoadAnimation(anim)
                            track:Play()
                        end
                    end

                    RunService.Heartbeat:Connect(function()
                        if not scriptActive or not Toggles.ShoveToggle.Value then return end
                        
                        local currentTime = tick()
                        if currentTime - lastUsedTime < cooldownTime then return end

                        local ball = Workspace:FindFirstChild("Temp") and Workspace.Temp:FindFirstChild("Ball")
                        if not (ball and ball:FindFirstChild("PossessionHighlight")) then return end

                        local targetPlayer, distance = getNearestPlayer()
                        if targetPlayer and distance <= reachDistance then
                            local container = Workspace:FindFirstChild("CharacterContainer")
                            local targetChar = container and container:FindFirstChild(targetPlayer.Name)

                            if targetChar then
                                shoveRemote:FireServer(targetChar)
                                playShoveAnimation()
                                lastUsedTime = currentTime
                            end
                        end
                    end)
                ]])()
            end
        end
    })
    
    ShoveGroup:AddSlider('ShoveReachSlider', {
        Text = 'Reach Distance',
        Default = 25,
        Min = 10,
        Max = 50,
        Rounding = 0,
        Callback = function(Value) end
    })
    
    ShoveGroup:AddLabel('Auto-shoves nearest player when you have ball')
    
    -- AUTO CHIP FEATURE
    local AutoChipGroup = Tabs.Main:AddLeftGroupbox('Auto Chip')
    AutoChipGroup:AddToggle('AutoChipToggle', {
        Text = 'Enable Auto Chip',
        Default = false,
        Callback = function(Value)
            if Value then
                local chipForce = Options.ChipForceSlider.Value
                local chipVector = Options.ChipVectorSlider.Value
                loadstring([[
                    local Players = game:GetService('Players')
                    local ReplicatedStorage = game:GetService('ReplicatedStorage')
                    local UserInputService = game:GetService('UserInputService')
                    local Knit = require(ReplicatedStorage.Packages.Knit)
                    local KeyHandlerService = Knit.GetService('KeyHandlerService')
                    local TapInRemote = KeyHandlerService:GetKey('TapInHit')

                    local player = Players.LocalPlayer
                    local CHIP_FORCE = ]] .. chipForce .. [[
                    local CHIP_VECTOR_MULT = ]] .. chipVector .. [[
                    local CHIP_ANIM_ID = 'rbxassetid://15134077897'
                    local autoChipEnabled = true
                    local TOGGLE_KEY = Enum.KeyCode.Five

                    local function getBall()
                        local folder = workspace:FindFirstChild('Temp')
                        return folder and folder:FindFirstChild('Ball')
                    end

                    local function playAnimation(id)
                        local char = player.Character
                        if not char then return end
                        local hum = char:FindFirstChildOfClass('Humanoid')
                        local animator = hum and (hum:FindFirstChildOfClass('Animator') or Instance.new('Animator', hum))
                        if not animator then return end
                        
                        local anim = Instance.new('Animation')
                        anim.AnimationId = id
                        local track = animator:LoadAnimation(anim)
                        track:Play()
                    end

                    local function getDirectionAndFlick()
                        local char = player.Character
                        local hrp = char and char:FindFirstChild("HumanoidRootPart")
                        local hum = char and char:FindFirstChild("Humanoid")
                        
                        if not hrp or not hum then return nil end
                        
                        local moveDir = hum.MoveDirection
                        
                        if moveDir.Magnitude == 0 then
                            local camDir = workspace.CurrentCamera.CFrame.LookVector
                            moveDir = Vector3.new(camDir.X, 0, camDir.Z).Unit
                        end
                        
                        hrp.CFrame = CFrame.new(hrp.Position, hrp.Position + moveDir)
                        
                        local baseVector = Vector3.new(14.2802124 * CHIP_VECTOR_MULT, 21.8535023 * CHIP_VECTOR_MULT, 32.024025 * CHIP_VECTOR_MULT)
                        local horizontalMag = Vector3.new(baseVector.X, 0, baseVector.Z).Magnitude
                        return Vector3.new(moveDir.X * horizontalMag, baseVector.Y, moveDir.Z * horizontalMag)
                    end

                    UserInputService.InputBegan:Connect(function(input, gp)
                        if gp or not autoChipEnabled then return end
                        if input.KeyCode == TOGGLE_KEY then
                            local ball = getBall()
                            if not ball then return end

                            local finalVector = getDirectionAndFlick()
                            if not finalVector then return end

                            playAnimation(CHIP_ANIM_ID)
                            TapInRemote:FireServer(ball, false, CHIP_FORCE, finalVector, 'Right')
                        end
                    end)
                ]])()
            end
        end
    })
    
    AutoChipGroup:AddSlider('ChipForceSlider', {
        Text = 'Chip Force',
        Default = 27.13,
        Min = 10,
        Max = 100,
        Rounding = 2,
        Callback = function(Value) end
    })
    
    AutoChipGroup:AddSlider('ChipVectorSlider', {
        Text = 'Chip Vector Multiplier',
        Default = 1.0,
        Min = 0.5,
        Max = 3.0,
        Rounding = 1,
        Callback = function(Value) end
    })
    
    AutoChipGroup:AddLabel('Keybind: 5')
    
    -- AIMBOT V2 (STANDALONE)
    local AimbotV2Group = Tabs.Main:AddLeftGroupbox('Aimbot V2 (Top/Bottom Bins)')
    AimbotV2Group:AddToggle('AimbotV2Toggle', {
        Text = 'Enable Aimbot V2',
        Default = false,
        Callback = function(Value)
            if Value then
                local fireRange = Options.AimbotV2RangeSlider.Value
                local kickPower = Options.AimbotV2PowerSlider.Value
                loadstring([[
                    local Players = game:GetService("Players")
                    local ReplicatedStorage = game:GetService("ReplicatedStorage")
                    local Workspace = game:GetService("Workspace")
                    local RunService = game:GetService("RunService")
                    local UserInputService = game:GetService("UserInputService")

                    local player = Players.LocalPlayer
                    local Knit = require(ReplicatedStorage.Packages.Knit)
                    local KeyHandlerService = Knit.GetService("KeyHandlerService")
                    local kickRemote = KeyHandlerService:GetKey("Kick")

                    local FIRE_RANGE = ]] .. fireRange .. [[
                    local KICK_POWER = ]] .. kickPower .. [[
                    local COOLDOWN = 1
                    local animationId = 'rbxassetid://15434792076'

                    local topEnabled = false
                    local bottomEnabled = false
                    local lastFire = 0

                    local gui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
                    gui.Name = "AimbotV2Indicator"

                    local function mkLabel(y, text)
                        local l = Instance.new("TextLabel")
                        l.Parent = gui
                        l.Size = UDim2.new(0, 120, 0, 30)
                        l.Position = UDim2.new(1, -130, 0, y)
                        l.BackgroundTransparency = 0.5
                        l.BackgroundColor3 = Color3.new(0, 0, 0)
                        l.TextColor3 = Color3.new(1, 1, 1)
                        l.TextScaled = true
                        l.Font = Enum.Font.SourceSansBold
                        l.Text = text
                        return l
                    end

                    local topLbl = mkLabel(10, "TOP OFF")
                    local botLbl = mkLabel(45, "BOT OFF")

                    local function updateUI()
                        topLbl.Text = topEnabled and "TOP ON" or "TOP OFF"
                        topLbl.TextColor3 = topEnabled and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
                        
                        botLbl.Text = bottomEnabled and "BOT ON" or "BOT OFF"
                        botLbl.TextColor3 = bottomEnabled and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
                    end

                    local function playAnimation(character)
                        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
                        local animator = humanoid and (humanoid:FindFirstChildOfClass("Animator") or humanoid:WaitForChild("Animator"))
                        
                        if animator then
                            local anim = Instance.new("Animation")
                            anim.AnimationId = animationId
                            local track = animator:LoadAnimation(anim)
                            track:Play()
                        end
                    end

                    local function getBall()
                        local temp = Workspace:FindFirstChild("Temp")
                        return temp and temp:FindFirstChild("Ball")
                    end

                    local function getField()
                        for _, v in ipairs(Workspace:GetDescendants()) do
                            if v.Name == "Field" and v:FindFirstChild("GoalboxHome") then return v end
                        end
                    end

                    local function getTarget(parts)
                        local cam = Workspace.CurrentCamera
                        local best, bestScore
                        for _, p in ipairs(parts) do
                            if p and p:IsA("BasePart") then
                                local dir = (p.Position - cam.CFrame.Position).Unit
                                local score = cam.CFrame.LookVector:Dot(dir)
                                if not bestScore or score > bestScore then
                                    bestScore = score
                                    best = p
                                end
                            end
                        end
                        return best
                    end

                    local function fire(target)
                        if tick() - lastFire < COOLDOWN then return end
                        lastFire = tick()

                        local ball = getBall()
                        local char = player.Character
                        local hrp = char and char:FindFirstChild("HumanoidRootPart")
                        local hum = char and char:FindFirstChildOfClass("Humanoid")
                        if not ball or not hrp or not hum or not target then return end

                        Workspace.CurrentCamera.CFrame = CFrame.new(Workspace.CurrentCamera.CFrame.Position, target.Position)
                        hrp.CFrame = CFrame.new(hrp.Position, Vector3.new(target.Position.X, hrp.Position.Y, target.Position.Z))

                        local side = hrp.CFrame.RightVector:Dot(ball.Position - hrp.Position) > 0 and "Right" or "Left"
                        kickRemote:FireServer((target.Position - hrp.Position).Unit * 200, ball, false, true, KICK_POWER, side, hrp.CFrame, {Enum.KeyCode.One}, false, false)
                        hum:ChangeState(Enum.HumanoidStateType.Jumping)
                        playAnimation(char)
                    end

                    UserInputService.InputBegan:Connect(function(input, gp)
                        if gp then return end
                        if not Toggles.AimbotV2Toggle.Value then return end
                        
                        if input.KeyCode == Enum.KeyCode.One then
                            topEnabled = not topEnabled
                            bottomEnabled = false
                        elseif input.KeyCode == Enum.KeyCode.Two then
                            bottomEnabled = not bottomEnabled
                            topEnabled = false
                        end
                        updateUI()
                    end)

                    RunService.RenderStepped:Connect(function()
                        if not Toggles.AimbotV2Toggle.Value or (not topEnabled and not bottomEnabled) then return end
                        
                        local ball = getBall()
                        local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                        if ball and hrp and (ball.Position - hrp.Position).Magnitude <= FIRE_RANGE then
                            local f = getField()
                            if not f then return end
                            
                            if topEnabled then
                                fire(getTarget({f.GoalboxHome["TOP RIGHT"], f.GoalboxHome["TOP LEFT"], f.GoalboxAway["TOP RIGHT"], f.GoalboxAway["TOP LEFT"]}))
                            else
                                fire(getTarget({f.GoalboxHome["BOTTOM RIGHT"], f.GoalboxHome["BOTTOM LEFT"], f.GoalboxAway["BOTTOM RIGHT"], f.GoalboxAway["BOTTOM LEFT"]}))
                            end
                        end
                    end)

                    updateUI()
                ]])()
            end
        end
    })
    
    AimbotV2Group:AddSlider('AimbotV2RangeSlider', {
        Text = 'Activation Range',
        Default = 7,
        Min = 3,
        Max = 20,
        Rounding = 0,
        Callback = function(Value) end
    })
    
    AimbotV2Group:AddSlider('AimbotV2PowerSlider', {
        Text = 'Kick Power',
        Default = 140,
        Min = 100,
        Max = 999,
        Rounding = 0,
        Callback = function(Value) end
    })
    
    AimbotV2Group:AddLabel('Key 1: Top Bins | Key 2: Bottom Bins')
    
    -- AIMBOT V1
    local AimGroup = Tabs.Main:AddLeftGroupbox('Aimbot V1')
    AimGroup:AddToggle('AimbotToggle', {
        Text = 'Enable Aimbot V1',
        Default = false,
        Callback = function(Value)
            if Value then
                local animId = Toggles.RinPackToggle and Toggles.RinPackToggle.Value and 'rbxassetid://139333593369314' or 'rbxassetid://15434792076'
                loadstring([[
                    --!nocheck
                    local Players = game:GetService('Players')
                    local ReplicatedStorage = game:GetService('ReplicatedStorage')
                    local UserInputService = game:GetService('UserInputService')
                    local Workspace = game:GetService('Workspace')
                    local RunService = game:GetService('RunService')

                    local Knit = require(ReplicatedStorage.Packages.Knit)
                    local KeyHandlerService = Knit.GetService('KeyHandlerService')
                    local kickRemote = KeyHandlerService:GetKey('Kick')

                    local camera = Workspace.CurrentCamera
                    local smoothness = 0.4 
                    local midfieldZ = 22
                    local animationId = ']] .. animId .. [['

                    local RIGHT_X = 280 
                    local LEFT_X = 252  

                    local HITBOX_SIZE = 6
                    local KICK_COOLDOWN = 0.6 

                    local activeMode = 0
                    local lastKickTime = 0
                    local POWER_VALUE = ]] .. (Options.AimbotPowerSlider and Options.AimbotPowerSlider.Value or 100) .. [[

                    local player = Players.LocalPlayer
                    local pGui = player:WaitForChild("PlayerGui")

                    if pGui:FindFirstChild("VolleyGui") then pGui.VolleyGui:Destroy() end

                    local screenGui = Instance.new("ScreenGui")
                    screenGui.Name = "VolleyGui"
                    screenGui.Parent = pGui

                    local statusLabel = Instance.new("TextLabel")
                    statusLabel.Size = UDim2.new(0, 220, 0, 50)
                    statusLabel.Position = UDim2.new(0.5, -110, 0.85, 0)
                    statusLabel.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
                    statusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                    statusLabel.TextSize = 16
                    statusLabel.Font = Enum.Font.GothamBold
                    statusLabel.Text = "SYSTEM: READY"
                    statusLabel.BorderSizePixel = 2
                    statusLabel.Parent = screenGui

                    local corner = Instance.new("UICorner")
                    corner.CornerRadius = UDim.new(0, 8)
                    corner.Parent = statusLabel

                    local powerLabel = Instance.new("TextLabel")
                    powerLabel.Size = UDim2.new(0, 150, 0, 30)
                    powerLabel.Position = UDim2.new(0.5, -75, 0.9, 0)
                    powerLabel.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
                    powerLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                    powerLabel.TextSize = 14
                    powerLabel.Font = Enum.Font.GothamBold
                    powerLabel.Text = "POWER: " .. POWER_VALUE
                    powerLabel.BorderSizePixel = 2
                    powerLabel.Parent = screenGui
                    Instance.new("UICorner", powerLabel)

                    local function updateGui(text, color)
                        statusLabel.Text = text
                        statusLabel.TextColor3 = color
                    end

                    local function updatePower(value)
                        POWER_VALUE = value
                        powerLabel.Text = "POWER: " .. value
                    end
                    getgenv().updatePower = updatePower

                    local function playAnimation(character)
                        local humanoid = character:FindFirstChildOfClass('Humanoid')
                        local animator = humanoid and (humanoid:FindFirstChildOfClass('Animator') or humanoid:WaitForChild('Animator'))
                        if animator then
                            local animation = Instance.new('Animation')
                            animation.AnimationId = animationId
                            local track = animator:LoadAnimation(animation)
                            track:Play()
                        end
                    end

                    local function getTargetX(humanoid)
                        local moveDir = humanoid.MoveDirection
                        if moveDir.X > 0.1 then
                            return RIGHT_X
                        elseif moveDir.X < -0.1 then
                            return LEFT_X
                        else
                            return RIGHT_X 
                        end
                    end

                    local function performKick()
                        local char = player.Character
                        local root = char and char:FindFirstChild("HumanoidRootPart")
                        local ball = Workspace:FindFirstChild('Temp') and Workspace.Temp:FindFirstChild('Ball')
                        
                        if root and ball then
                            lastKickTime = tick()

                            local direction = camera.CFrame.LookVector * 200
                            local args = {
                                direction, ball, false, true, POWER_VALUE, 'Right', root.CFrame, {}, false, false
                            }
                            kickRemote:FireServer(table.unpack(args))
                            char.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                            playAnimation(char)
                            
                            activeMode = 0 
                            updateGui("SYSTEM: READY", Color3.fromRGB(255, 255, 255))
                        end
                    end

                    UserInputService.InputBegan:Connect(function(input, processed)
                        if processed then return end

                        if input.KeyCode == Enum.KeyCode.V then
                            if activeMode == 1 then 
                                activeMode = 0 
                                updateGui("SYSTEM: READY", Color3.fromRGB(255, 255, 255))
                            else
                                activeMode = 1 
                                updateGui("MODE: HIGH (AUTO-VOLLEY)", Color3.fromRGB(0, 255, 0))
                            end
                        elseif input.KeyCode == Enum.KeyCode.B then
                            if activeMode == 2 then 
                                activeMode = 0 
                                updateGui("SYSTEM: READY", Color3.fromRGB(255, 255, 255))
                            else
                                activeMode = 2
                                updateGui("MODE: LOW (AUTO-VOLLEY)", Color3.fromRGB(85, 170, 255))
                            end
                        end
                    end)

                    RunService.RenderStepped:Connect(function()
                        local char = player.Character
                        local root = char and char:FindFirstChild("HumanoidRootPart")
                        local humanoid = char and char:FindFirstChildOfClass("Humanoid")
                        if not root or not humanoid then return end

                        if activeMode ~= 0 then
                            local currentTargetX = getTargetX(humanoid)
                            local baseTargetY = (activeMode == 1) and 19.80 or 9.68
                            local targetZ = (root.Position.Z < midfieldZ) and -254.21 or 300
                            
                            local finalTarget = Vector3.new(currentTargetX, baseTargetY, targetZ)
                            
                            if activeMode == 1 then
                                local distance = (root.Position - finalTarget).Magnitude
                                local heightOffset = (distance / 40) + (distance^2 / 4000)
                                finalTarget = Vector3.new(finalTarget.X, baseTargetY + heightOffset, targetZ)
                            end
                            
                            local targetCF = CFrame.lookAt(camera.CFrame.Position, finalTarget)
                            camera.CFrame = camera.CFrame:Lerp(targetCF, smoothness)

                            local ballFolder = Workspace:FindFirstChild('Temp')
                            local ball = ballFolder and ballFolder:FindFirstChild('Ball')
                            
                            if ball then
                                local distance = (root.Position - ball.Position).Magnitude
                                if distance <= HITBOX_SIZE and (tick() - lastKickTime >= KICK_COOLDOWN) then
                                    performKick()
                                end
                            end
                        end
                    end)
                ]])()
            end
        end
    })
    
    AimGroup:AddLabel('High Mode: V')
    AimGroup:AddLabel('Low Mode: B')
    AimGroup:AddSlider('AimbotPowerSlider', {
        Text = 'Kick Power',
        Default = 100,
        Min = 100,
        Max = 999,
        Rounding = 0,
        Callback = function(Value)
            if Toggles.AimbotToggle.Value then
                loadstring([[
                    if getgenv().updatePower then
                        getgenv().updatePower(]] .. Value .. [[)
                    end
                ]])()
            end
        end
    })
    
    local PreholdGroup = Tabs.Main:AddLeftGroupbox('Auto Prehold')
    PreholdGroup:AddToggle('PreholdToggle', {
        Text = 'Enable Auto Prehold',
        Default = false,
        Callback = function(Value)
            if Value then
                local animId = Toggles.RinPackToggle and Toggles.RinPackToggle.Value and 'rbxassetid://139333593369314' or 'rbxassetid://15434792076'
                loadstring([[
                    --!nocheck
                    local Players = game:GetService('Players')
                    local ReplicatedStorage = game:GetService('ReplicatedStorage')
                    local UserInputService = game:GetService('UserInputService')
                    local Workspace = game:GetService('Workspace')
                    local RunService = game:GetService('RunService')

                    local Knit = require(ReplicatedStorage.Packages.Knit)
                    local KeyHandlerService = Knit.GetService('KeyHandlerService')

                    local kickRemote = KeyHandlerService:GetKey('Kick')
                    local animationId = ']] .. animId .. [['
                    local procSize = ]] .. (Options.PreholdRangeSlider and Options.PreholdRangeSlider.Value or 4) .. [[
                    local HITBOX_SIZE = procSize
                    local TOGGLE_KEY = Enum.KeyCode.Four
                    local MANUAL_KEY = Enum.KeyCode.G

                    local autoVolleyEnabled = false
                    local lastKickTime = 0
                    local KICK_COOLDOWN = 4

                    local visualCircle = Instance.new("Part")
                    visualCircle.Name = "RangeVisual"
                    visualCircle.Shape = Enum.PartType.Cylinder
                    visualCircle.Material = Enum.Material.ForceField
                    visualCircle.Transparency = 0.5
                    visualCircle.CanCollide = false
                    visualCircle.CanQuery = false
                    visualCircle.CanTouch = false
                    visualCircle.Anchored = false
                    visualCircle.Parent = Workspace

                    local circleVisible = true
                    local scriptActive = true

                    local function updateCircle()
                        local character = Players.LocalPlayer.Character
                        local root = character and character:FindFirstChild("HumanoidRootPart")
                        
                        if root and scriptActive and circleVisible then
                            local timeLeft = math.max(0, (lastKickTime + KICK_COOLDOWN) - tick())
                            
                            if timeLeft > 0 then
                                visualCircle.Color = Color3.fromRGB(255, 50, 50)
                            else
                                visualCircle.Color = Color3.fromRGB(0, 255, 100)
                            end
                            
                            visualCircle.Transparency = 0.5
                            visualCircle.CFrame = root.CFrame * CFrame.new(0, -2.8, 0) * CFrame.Angles(0, 0, math.rad(90))
                            visualCircle.Size = Vector3.new(0.1, procSize * 2, procSize * 2)
                        else
                            visualCircle.Transparency = 1
                        end
                    end

                    local screenGui = Instance.new("ScreenGui", game.CoreGui)
                    local mainFrame = Instance.new("Frame", screenGui)
                    mainFrame.Size = UDim2.new(0, 160, 0, 110)
                    mainFrame.Position = UDim2.new(1, -170, 0, 140)
                    mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
                    mainFrame.BorderSizePixel = 0
                    Instance.new("UICorner", mainFrame)

                    local function createLabel(pos, text, color)
                        local lbl = Instance.new("TextLabel", mainFrame)
                        lbl.Size = UDim2.new(1, 0, 0.25, 0)
                        lbl.Position = pos
                        lbl.TextColor3 = color
                        lbl.Text = text
                        lbl.BackgroundTransparency = 1
                        lbl.Font = Enum.Font.GothamBold
                        lbl.TextSize = 12
                        return lbl
                    end

                    local statusLabel = createLabel(UDim2.new(0,0,0,0), "READY", Color3.new(0, 1, 0))
                    local autoLabel = createLabel(UDim2.new(0,0,0.25,0), "AUTO (1): OFF", Color3.new(1, 0.3, 0.3))
                    local procLabel = createLabel(UDim2.new(0,0,0.5,0), "RANGE (N-M): " .. procSize, Color3.new(1, 0.8, 0.2))
                    local visualLabel = createLabel(UDim2.new(0,0,0.75,0), "CIRCLE (L): ON", Color3.new(0.7, 0.7, 0.7))

                    local function playAnimation(character)
                        local humanoid = character:FindFirstChildOfClass('Humanoid')
                        local animator = humanoid and (humanoid:FindFirstChildOfClass('Animator') or humanoid:WaitForChild('Animator'))
                        
                        if animator then
                            local animation = Instance.new('Animation')
                            animation.AnimationId = animationId
                            local track = animator:LoadAnimation(animation)
                            track:Play()
                        end
                    end

                    local function performKick()
                        local player = Players.LocalPlayer
                        local character = player.Character
                        if not character then return end
                        
                        local root = character:FindFirstChild('HumanoidRootPart')
                        local humanoid = character:FindFirstChildOfClass('Humanoid')
                        if not root or not humanoid then return end

                        local ballFolder = Workspace:FindFirstChild('Temp')
                        local ball = ballFolder and ballFolder:FindFirstChild('Ball')
                        if not ball then return end

                        local distance = (root.Position - ball.Position).Magnitude
                        if distance <= procSize and (tick() - lastKickTime >= KICK_COOLDOWN) then
                            lastKickTime = tick()
                            
                            local direction = Workspace.CurrentCamera.CFrame.LookVector * 200
                            local args = { direction, ball, false, true, 100, 'Right', root.CFrame, {}, false, false }

                            kickRemote:FireServer(table.unpack(args))
                            playAnimation(character)
                        end
                    end

                    UserInputService.InputBegan:Connect(function(input, gp)
                        if gp then return end
                        
                        if input.KeyCode == TOGGLE_KEY then
                            autoVolleyEnabled = not autoVolleyEnabled
                            autoLabel.Text = "AUTO (1): " .. (autoVolleyEnabled and "ON" or "OFF")
                            autoLabel.TextColor3 = autoVolleyEnabled and Color3.new(0.3, 1, 0.3) or Color3.new(1, 0.3, 0.3)
                        elseif input.KeyCode == MANUAL_KEY then
                            performKick()
                        elseif input.KeyCode == Enum.KeyCode.Zero then
                            scriptActive = not scriptActive
                            mainFrame.Visible = scriptActive
                        elseif input.KeyCode == Enum.KeyCode.L then
                            circleVisible = not circleVisible
                            visualLabel.Text = "CIRCLE (L): " .. (circleVisible and "ON" or "OFF")
                        elseif input.KeyCode == Enum.KeyCode.M then
                            procSize = procSize + 0.5
                            procLabel.Text = "RANGE (N-M): " .. procSize
                        elseif input.KeyCode == Enum.KeyCode.N then
                            procSize = math.max(0.5, procSize - 0.5)
                            procLabel.Text = "RANGE (N-M): " .. procSize
                        end
                    end)

                    RunService.RenderStepped:Connect(function()
                        updateCircle()
                        
                        local timeLeft = math.max(0, (lastKickTime + KICK_COOLDOWN) - tick())
                        if not scriptActive then
                            statusLabel.Text = "DISABLED"
                            statusLabel.TextColor3 = Color3.new(0.5, 0.5, 0.5)
                        elseif timeLeft > 0 then
                            statusLabel.Text = string.format("CD: %.1fs", timeLeft)
                            statusLabel.TextColor3 = Color3.new(1, 0.2, 0.2)
                        else
                            statusLabel.Text = "READY"
                            statusLabel.TextColor3 = Color3.new(0, 1, 0)
                        end

                        if autoVolleyEnabled and scriptActive then
                            performKick()
                        end
                    end)
                ]])()
            end
        end
    })
    
    PreholdGroup:AddLabel('Toggle: 4')
    PreholdGroup:AddLabel('Manual: G')
    PreholdGroup:AddSlider('PreholdRangeSlider', {
        Text = 'Range',
        Default = 4,
        Min = 1,
        Max = 15,
        Rounding = 1,
        Callback = function(Value) end
    })
    
    local DoubleTapGroup = Tabs.Main:AddLeftGroupbox('Double Tap')
    DoubleTapGroup:AddToggle('DoubleTapToggle', {
        Text = 'Enable Double Tap',
        Default = false,
        Callback = function(Value)
            if Value then
                loadstring([[
                    local Players = game:GetService('Players')
                    local ReplicatedStorage = game:GetService('ReplicatedStorage')
                    local UserInputService = game:GetService('UserInputService')
                    local VirtualInputManager = game:GetService('VirtualInputManager')
                    local Knit = require(ReplicatedStorage.Packages.Knit)

                    local KeyHandlerService = Knit.GetService('KeyHandlerService')
                    local KickRemote = KeyHandlerService:GetKey('Kick')
                    local TapInRemote = KeyHandlerService:GetKey('TapInHit')

                    local player = Players.LocalPlayer

                    local CHIP_FORCE = 37.63837890769355
                    local CHIP_VECTOR = Vector3.new(33.2738037109375, 27.290828704833984, -27.609731674194336)
                    local CHIP_CFRAME = CFrame.new(216.23738, 12.676937, -96.496208, 0.6732608,0,-0.7394051,0,1,0,0.7394051,0,0.6732608)
                    local CHIP_ANIM_ID = 'rbxassetid://15134077897'

                    local DTAP_FORCE = 27.13375797914341
                    local DTAP_VECTOR = Vector3.new(14.2802124, 21.8535023, 32.024025)
                    local DTAP_ANIM_ID = 'rbxassetid://16859143160'
                    
                    local lastActivation = 0
                    local cooldown = 1.5
                    local doubleTapKey = Enum.KeyCode.X
                    local doubleTapEnabled = true

                    local function getBall()
                        local folder = workspace:FindFirstChild('Temp')
                        return folder and folder:FindFirstChild('Ball')
                    end

                    local function playAnimation(id)
                        local char = player.Character
                        if not char then return end
                        local hum = char:FindFirstChildOfClass('Humanoid')
                        local animator = hum and (hum:FindFirstChildOfClass('Animator') or Instance.new('Animator', hum))
                        if not animator then return end
                        local anim = Instance.new('Animation')
                        anim.AnimationId = id
                        animator:LoadAnimation(anim):Play()
                    end

                    local function alignVector(vec)
                        local camDir = workspace.CurrentCamera.CFrame.LookVector
                        local flat = Vector3.new(camDir.X,0,camDir.Z).Unit
                        local mag = Vector3.new(vec.X,0,vec.Z).Magnitude
                        return Vector3.new(flat.X*mag, vec.Y, flat.Z*mag)
                    end

                    UserInputService.InputBegan:Connect(function(i,gp)
                        if gp or i.KeyCode ~= doubleTapKey then return end
                        if not doubleTapEnabled then return end
                        
                        local currentTime = tick()
                        if currentTime - lastActivation < cooldown then return end
                        lastActivation = currentTime

                        local ball = getBall()
                        if not ball then return end

                        playAnimation(CHIP_ANIM_ID)
                        KickRemote:FireServer(
                            alignVector(CHIP_VECTOR), ball, false, false,
                            CHIP_FORCE, "Left", CHIP_CFRAME, {}, false, false
                        )

                        task.wait(0.2)
                        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
                        task.wait(0.05)
                        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)

                        task.wait(0.2)
                        playAnimation(DTAP_ANIM_ID)
                        TapInRemote:FireServer(ball, false, DTAP_FORCE, alignVector(DTAP_VECTOR), 'Right')
                    end)
                ]])()
            end
        end
    })
    
    DoubleTapGroup:AddLabel('Keybind: X')
    
    local AutoM2Group = Tabs.Main:AddLeftGroupbox('Auto M2')
    AutoM2Group:AddToggle('AutoM2Toggle', {
        Text = 'Enable Auto M2',
        Default = false,
        Callback = function(Value)
            if Value then
                loadstring([[
                    local ReplicatedStorage = game:GetService("ReplicatedStorage")
                    local Workspace = game:GetService("Workspace")
                    local UserInputService = game:GetService("UserInputService")
                    local RunService = game:GetService("RunService")
                    local Players = game:GetService("Players")
                    local VirtualInputManager = game:GetService("VirtualInputManager")
                    local CoreGui = game:GetService("CoreGui")

                    local player = Players.LocalPlayer
                    local scriptActive = true         
                    local autoM2Enabled = false       
                    local lastHighlightState = false  
                    local isBursting = false          

                    local lastM2Time = 0
                    local m2Interval = 0.2 
                    local procSize = 4.5   

                    local visualCircle = Instance.new("Part")
                    visualCircle.Name = "M2RangeVisual"
                    visualCircle.Shape = Enum.PartType.Cylinder
                    visualCircle.Material = Enum.Material.ForceField
                    visualCircle.Transparency = 1 
                    visualCircle.CanCollide = false
                    visualCircle.CanQuery = false
                    visualCircle.CanTouch = false
                    visualCircle.Anchored = true
                    visualCircle.Parent = Workspace

                    local function updateCircle()
                        local character = player.Character
                        local root = character and character:FindFirstChild("HumanoidRootPart")
                        
                        if root and scriptActive and autoM2Enabled then
                            visualCircle.Transparency = 0.5
                            if isBursting then
                                visualCircle.Color = Color3.fromRGB(255, 50, 50)
                            else
                                visualCircle.Color = Color3.fromRGB(255, 255, 255)
                            end
                            
                            visualCircle.CFrame = root.CFrame * CFrame.new(0, -2.8, 0) * CFrame.Angles(0, 0, math.rad(90))
                            visualCircle.Size = Vector3.new(0.1, procSize * 2, procSize * 2)
                        else
                            visualCircle.Transparency = 1
                        end
                    end

                    local screenGui = Instance.new("ScreenGui", CoreGui)
                    local mainFrame = Instance.new("Frame", screenGui)
                    mainFrame.Size = UDim2.new(0, 220, 0, 100)
                    mainFrame.Position = UDim2.new(1, -230, 0, 10)
                    mainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
                    Instance.new("UICorner", mainFrame)

                    local function makeLabel(text, pos, size)
                        local lbl = Instance.new("TextLabel", mainFrame)
                        lbl.Size = size
                        lbl.Position = pos
                        lbl.BackgroundTransparency = 1
                        lbl.Font = Enum.Font.GothamBold
                        lbl.TextColor3 = Color3.fromRGB(200, 200, 200)
                        lbl.TextSize = 12
                        lbl.Text = text
                        return lbl
                    end

                    local statusLabel = makeLabel("AUTO M2: OFF", UDim2.new(0,0,0,0), UDim2.new(1,0,0.4,0))
                    statusLabel.TextColor3 = Color3.fromRGB(255, 60, 60)
                    local speedLabel = makeLabel("SPEED: 0.20s ([ / ])", UDim2.new(0,0,0.4,0), UDim2.new(1,0,0.3,0))
                    local rangeLabel = makeLabel("RANGE: 4.5 (N / M)", UDim2.new(0,0,0.7,0), UDim2.new(1,0,0.3,0))

                    local function runPostStealBurst()
                        if isBursting then return end
                        isBursting = true
                        
                        task.wait(0.2)
                        
                        for i = 1, 2 do
                            VirtualInputManager:SendMouseButtonEvent(0, 0, 1, true, game, 0)
                            task.wait(0.01)
                            VirtualInputManager:SendMouseButtonEvent(0, 0, 1, false, game, 0)
                            
                            if i < 2 then 
                                task.wait(0.2)
                            end
                        end
                        
                        isBursting = false
                    end

                    local function isBallInAir(ball)
                        local char = player.Character
                        local root = char and char:FindFirstChild("HumanoidRootPart")
                        if root then
                            return (ball.Position.Y - root.Position.Y) > 6
                        end
                        return false
                    end

                    local function handleAutoM2(ball, highlight)
                        if not scriptActive or not autoM2Enabled then return end

                        if highlight and not lastHighlightState then
                            lastHighlightState = true
                            task.spawn(runPostStealBurst)
                        elseif not highlight then
                            lastHighlightState = false
                        end

                        if isBursting or highlight or isBallInAir(ball) then return end

                        local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                        if root and (root.Position - ball.Position).Magnitude <= procSize then
                            if tick() - lastM2Time >= m2Interval then
                                lastM2Time = tick()
                                VirtualInputManager:SendMouseButtonEvent(0, 0, 1, true, game, 0)
                                task.wait(0.01)
                                VirtualInputManager:SendMouseButtonEvent(0, 0, 1, false, game, 0)
                            end
                        end
                    end

                    RunService.RenderStepped:Connect(function()
                        updateCircle()
                        local ball = Workspace:FindFirstChild("Temp") and Workspace.Temp:FindFirstChild("Ball") or Workspace:FindFirstChild("Ball")
                        local highlight = ball and ball:FindFirstChild("PossessionHighlight")
                        if ball then handleAutoM2(ball, highlight) end
                    end)

                    UserInputService.InputBegan:Connect(function(input, gp)
                        if gp then return end
                        
                        if input.KeyCode == Enum.KeyCode.Three then
                            autoM2Enabled = not autoM2Enabled
                            statusLabel.Text = autoM2Enabled and "AUTO M2: ON" or "AUTO M2: OFF"
                            statusLabel.TextColor3 = autoM2Enabled and Color3.fromRGB(80, 255, 80) or Color3.fromRGB(255, 60, 60)
                            
                        elseif input.KeyCode == Enum.KeyCode.Zero then
                            scriptActive = not scriptActive
                            mainFrame.Visible = scriptActive
                            
                        elseif input.KeyCode == Enum.KeyCode.RightBracket then
                            m2Interval = math.clamp(m2Interval + 0.05, 0.05, 1.5)
                            speedLabel.Text = string.format("SPEED: %.2fs ([ / ])", m2Interval)
                            
                        elseif input.KeyCode == Enum.KeyCode.LeftBracket then
                            m2Interval = math.clamp(m2Interval - 0.05, 0.05, 1.5)
                            speedLabel.Text = string.format("SPEED: %.2fs ([ / ])", m2Interval)

                        elseif input.KeyCode == Enum.KeyCode.M then
                            procSize = math.clamp(procSize + 0.5, 1, 15)
                            rangeLabel.Text = "RANGE: " .. procSize .. " (N / M)"

                        elseif input.KeyCode == Enum.KeyCode.N then
                            procSize = math.clamp(procSize - 0.5, 1, 15)
                            rangeLabel.Text = "RANGE: " .. procSize .. " (N / M)"
                        end
                    end)
                ]])()
            end
        end
    })
    
    AutoM2Group:AddLabel('Toggle: 3')
    AutoM2Group:AddLabel('Speed: [ / ]')
    AutoM2Group:AddLabel('Range: N / M')
    AutoM2Group:AddLabel('Disable: 0')
    
    -- RIGHT SIDE GROUPS (MAIN TAB)
    local TPMossGroup = Tabs.Main:AddRightGroupbox('TP Moss')
    TPMossGroup:AddToggle('TPMossToggle', {
        Text = 'Enable TP Moss',
        Default = false,
        Callback = function(Value)
            if Value then
                loadstring([[
                    local UserInputService = game:GetService("UserInputService")
                    local Players = game:GetService("Players")
                    local Workspace = game:GetService("Workspace")
                    local RunService = game:GetService("RunService")

                    local player = Players.LocalPlayer
                    local character = player.Character or player.CharacterAdded:Wait()
                    local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
                    local head = character:WaitForChild("Head")

                    local screenGui = Instance.new("ScreenGui")
                    screenGui.Parent = player:WaitForChild("PlayerGui")

                    local toggleLabel = Instance.new("TextLabel")
                    toggleLabel.Size = UDim2.new(0, 200, 0, 50)
                    toggleLabel.Position = UDim2.new(0.05, 0, 0.1, 0)
                    toggleLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
                    toggleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                    toggleLabel.Font = Enum.Font.SourceSansBold
                    toggleLabel.TextSize = 22
                    toggleLabel.Text = "Toggled: OFF"
                    toggleLabel.Parent = screenGui

                    local toggled = false
                    local labelVisible = true
                    local stepCount = 20
                    local timeStep = 0.1
                    local gravity = Vector3.new(0, -Workspace.Gravity * timeStep, 0)

                    UserInputService.InputBegan:Connect(function(input, gameProcessed)
                    	if gameProcessed then return end
                    	
                    	if input.KeyCode == Enum.KeyCode.Y then
                    		toggled = not toggled
                    		toggleLabel.Text = toggled and "Toggled: ON" or "Toggled: OFF"
                    	elseif input.KeyCode == Enum.KeyCode.P then
                    		labelVisible = not labelVisible
                    		toggleLabel.Visible = labelVisible
                    	end
                    end)

                    local function isPlayerNearPredictedPath(ballPos, ballVel)
                    	local currentPos = ballPos
                    	local currentVel = ballVel

                    	for _ = 1, stepCount do
                    		currentVel += gravity
                    		local nextPos = currentPos + currentVel * timeStep

                    		if (humanoidRootPart.Position - nextPos).Magnitude <= 5 then
                    			return true
                    		end

                    		currentPos = nextPos
                    	end
                    	return false
                    end

                    RunService.Heartbeat:Connect(function()
                    	if toggled then
                    		local tempFolder = Workspace:FindFirstChild("Temp")
                    		local ball = tempFolder and tempFolder:FindFirstChild("Ball")
                    		if not ball or not ball:IsA("Part") then return end

                    		if ball:FindFirstChild("PossessionHighlight") then
                    			toggled = false
                    			toggleLabel.Text = "Toggled: OFF"
                    			return
                    		end

                    		local nearPath = isPlayerNearPredictedPath(ball.Position, ball.Velocity)
                    		local nearBall = (ball.Position - humanoidRootPart.Position).Magnitude <= 7

                    		if nearPath and nearBall then
                    			ball.Position = head.Position
                    		end
                    	end
                    end)
                ]])()
            end
        end
    })
    
    TPMossGroup:AddLabel('Keybind: Y')
    TPMossGroup:AddLabel('Hide UI: P')
    
    local HitboxGroup = Tabs.Main:AddRightGroupbox('Hitbox Extender')
    HitboxGroup:AddToggle('HitboxToggle', {
        Text = 'Enable Hitbox Extender',
        Default = false,
        Callback = function(Value)
            if Value then
                local hitboxValue = Options.HitboxSlider.Value
                loadstring([[
                    local ReplicatedStorage = game:GetService("ReplicatedStorage")
                    local Workspace = game:GetService("Workspace")
                    local UserInputService = game:GetService("UserInputService")
                    local RunService = game:GetService("RunService")
                    local scriptActive = true
                    local showSphere = true
                    local manualSize = ]] .. hitboxValue .. [[
                    local currentSize = ]] .. hitboxValue .. [[
                    local originalCreate = nil
                    local visualizer = nil
                    local function updateVisualizer()
                        local tempFolder = Workspace:FindFirstChild("Temp")
                        local ball = tempFolder and tempFolder:FindFirstChild("Ball")
                        local highlight = ball and ball:FindFirstChild("PossessionHighlight")
                        if not highlight then
                            currentSize = 7
                        else
                            currentSize = manualSize
                        end
                        if not ball or not scriptActive or not showSphere then
                            if visualizer then visualizer.Visible = false end
                            return
                        end
                        if not visualizer then
                            visualizer = Instance.new("SphereHandleAdornment")
                            visualizer.Name = "HitboxVisual"
                            visualizer.Color3 = Color3.fromRGB(0, 170, 255)
                            visualizer.Transparency = 0.7
                            visualizer.AlwaysOnTop = true
                            visualizer.ZIndex = 10
                            visualizer.Parent = game.CoreGui
                        end
                        visualizer.Visible = true
                        visualizer.Adornee = ball
                        visualizer.Radius = currentSize / 2
                    end
                    local function hook()
                        local module = require(ReplicatedStorage.Modules.HitboxHandler)
                        if originalCreate then return end
                        originalCreate = module.Create
                        module.Create = function(config)
                            if scriptActive then
                                config.size = Vector3.new(currentSize, currentSize, currentSize)
                            end
                            return originalCreate(config)
                        end
                    end
                    UserInputService.InputBegan:Connect(function(input, processed)
                        if processed then return end
                        if input.KeyCode == Enum.KeyCode.Zero then
                            scriptActive = not scriptActive
                            print("Script Active:", scriptActive)
                        elseif input.KeyCode == Enum.KeyCode.H then
                            showSphere = not showSphere
                            if not showSphere and visualizer then visualizer.Visible = false end
                            print("Sphere Visible:", showSphere)
                        elseif input.KeyCode == Enum.KeyCode.M then
                            manualSize = manualSize + 1
                            print("Target Size set to:", manualSize)
                        elseif input.KeyCode == Enum.KeyCode.N then
                            manualSize = math.max(1, manualSize - 1)
                            print("Target Size set to:", manualSize)
                        end
                    end)
                    RunService.RenderStepped:Connect(updateVisualizer)
                    hook()
                ]])()
            end
        end
    })
    
    HitboxGroup:AddSlider('HitboxSlider', {
        Text = 'Hitbox Size',
        Default = 15,
        Min = 1,
        Max = 50,
        Rounding = 0,
        Callback = function(Value)
            if Toggles.HitboxToggle.Value then
                loadstring([[
                    getgenv().manualSize = ]] .. Value .. [[
                    getgenv().currentSize = ]] .. Value .. [[
                ]])()
            end
        end
    })
    
    local HeaderGroup = Tabs.Main:AddRightGroupbox('Auto Header')
    HeaderGroup:AddToggle('HeaderToggle', {
        Text = 'Enable Auto Header',
        Default = false,
        Callback = function(Value)
            if Value then
                loadstring([[
                    --!nocheck
                    local Players = game:GetService("Players")
                    local RunService = game:GetService("RunService")
                    local UserInputService = game:GetService("UserInputService")
                    local ReplicatedStorage = game:GetService("ReplicatedStorage")
                    local Workspace = game:GetService("Workspace")
                    local player = Players.LocalPlayer
                    local AutoHeaderKey = Enum.KeyCode.T
                    local HEADER_ANIM_ID = "rbxassetid://15684799301"
                    local slipConeSize = Vector3.new(9, 5, 9)
                    local autoHeaderActive = false
                    local debounce = false
                    local ballWasInside = false
                    local gui = Instance.new("ScreenGui")
                    gui.IgnoreGuiInset = true
                    gui.ResetOnSpawn = false
                    gui.Parent = player:WaitForChild("PlayerGui")
                    local topBar = Instance.new("Frame")
                    topBar.Size = UDim2.new(1, 0, 0, 4)
                    topBar.BackgroundColor3 = Color3.fromRGB(0, 255, 255)
                    topBar.BorderSizePixel = 0
                    topBar.Visible = false
                    topBar.Parent = gui
                    local Knit = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Knit"))
                    Knit.Start():await()
                    local HeaderService = Knit.GetService("KeyHandlerService")
                    local headerRemote = HeaderService:GetKey("Header")
                    local slipCone
                    RunService.Heartbeat:Connect(function()
                        if slipCone and slipCone.Parent then return end
                        local container = Workspace:FindFirstChild("CharacterContainer")
                        local charFolder = container and container:FindFirstChild(player.Name)
                        local cone = charFolder and charFolder:FindFirstChild("SlipCone")
                        if cone then
                            slipCone = cone
                            slipCone.CanCollide = false
                            local oldY = cone.Size.Y
                            local bottom = cone.CFrame * CFrame.new(0, -oldY / 2, 0)
                            cone.Size = slipConeSize
                            cone.CFrame = bottom * CFrame.new(0, slipConeSize.Y / 2, 0)
                        end
                    end)
                    UserInputService.InputBegan:Connect(function(input, gp)
                        if gp then return end
                        if input.KeyCode == AutoHeaderKey then
                            autoHeaderActive = not autoHeaderActive
                        end
                    end)
                    RunService.Heartbeat:Connect(function()
                        topBar.Visible = autoHeaderActive
                        if not autoHeaderActive or not slipCone or not headerRemote then
                            ballWasInside = false
                            return
                        end
                        local char = player.Character
                        local ball = Workspace:FindFirstChild("Temp") and Workspace.Temp:FindFirstChild("Ball")
                        if not ball then ball = Workspace:FindFirstChild("Ball") end
                        if not char or not ball or ball:FindFirstChild("PossessionHighlight") then
                            ballWasInside = false
                            return
                        end
                        local params = OverlapParams.new()
                        params.FilterType = Enum.RaycastFilterType.Include
                        params.FilterDescendantsInstances = { ball }
                        if #Workspace:GetPartsInPart(slipCone, params) == 0 then
                            ballWasInside = false
                            return
                        end
                        if debounce or ballWasInside then return end
                        ballWasInside = true
                        debounce = true
                        task.spawn(function()
                            local humanoid = char:FindFirstChildOfClass("Humanoid")
                            if humanoid then
                                humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                            end
                            task.wait(0.1)
                            local cam = Workspace.CurrentCamera
                            local dir = cam.CFrame.LookVector * 140
                            dir = Vector3.new(dir.X, math.clamp(dir.Y, 12, 24), dir.Z)
                            headerRemote:FireServer(dir, ball)
                            local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
                            if animator then
                                local anim = Instance.new("Animation")
                                anim.AnimationId = HEADER_ANIM_ID
                                animator:LoadAnimation(anim):Play()
                            end
                            task.wait(0.5)
                            debounce = false
                        end)
                    end)
                ]])()
            end
        end
    })
    
    HeaderGroup:AddLabel('Keybind: T')
    
    local AutoGkGroup = Tabs.Main:AddRightGroupbox('Auto GK')
    AutoGkGroup:AddToggle('AutoGkToggle', {
        Text = 'Enable Auto GK',
        Default = false,
        Callback = function(Value)
            if Value then
                loadstring([[
                    local RunService = game:GetService("RunService")
                    local Workspace = game:GetService("Workspace")
                    local Players = game:GetService("Players")
                    local VirtualInputManager = game:GetService("VirtualInputManager")
                    local UserInputService = game:GetService("UserInputService")
                    local Player = Players.LocalPlayer
                    local Character = Player.Character or Player.CharacterAdded:Wait()
                    local RootPart = Character:WaitForChild("HumanoidRootPart")
                    local CONFIG = {
                    	Enabled = true,
                    	ShowVisuals = false,
                    	ActivationKey = Enum.KeyCode.One,
                    	MinBallVelocity = 10,
                    	DelayMidDive  = 0.02,
                    	DelayHighDive = 0.13,
                    	TimeThresholdFar    = 0.32,
                    	TimeThresholdMidFar = 0.23,
                    	TimeThresholdMid    = 0.2,
                    	Height_Split_LowMid = -1.0,
                    	Height_Split_MidHigh = 3,
                    	ReachX = 40,
                    	ReachY = 25,
                    	BallRadius = 1.0,
                    	BounceElasticity = 0.7,
                    	Gravity = Vector3.new(0, -workspace.Gravity, 0),
                    	Keys = {
                    		Left = Enum.KeyCode.A,
                    		Right = Enum.KeyCode.D,
                    		Jump = Enum.KeyCode.Space
                    	}
                    }
                    local DiveCooldown = false
                    local VisContainer = Instance.new("Folder", Workspace)
                    VisContainer.Name = "GK_Exact_Plane_System"
                    local function DrawPoint(pos, col, size)
                    	if not CONFIG.ShowVisuals then return end
                    	local p = Instance.new("Part")
                    	p.Anchored, p.CanCollide, p.CastShadow = true, false, false
                    	p.Shape, p.Material = "Ball", "Neon"
                    	p.Size = Vector3.new(size, size, size)
                    	p.Position = pos
                    	p.Color = col
                    	p.Parent = VisContainer
                    	game.Debris:AddItem(p, 0.1)
                    end
                    local function PerformDive(Direction, Mode)
                    	if DiveCooldown then return end
                    	DiveCooldown = true
                    	local holdKey = nil
                    	if Direction == "Right" then holdKey = CONFIG.Keys.Right
                    	elseif Direction == "Left" then holdKey = CONFIG.Keys.Left
                    	end
                    	task.spawn(function()
                    		if holdKey then
                    			VirtualInputManager:SendKeyEvent(true, holdKey, false, game)
                    		end
                    		if Mode == "High" then
                    			VirtualInputManager:SendKeyEvent(true, CONFIG.Keys.Jump, false, game)
                    			task.wait(CONFIG.DelayHighDive)
                    			VirtualInputManager:SendMouseButtonEvent(0, 0, 1, true, game, 1)
                    		elseif Mode == "Mid" then
                    			VirtualInputManager:SendKeyEvent(true, CONFIG.Keys.Jump, false, game)
                    			task.wait(CONFIG.DelayMidDive)
                    			VirtualInputManager:SendMouseButtonEvent(0, 0, 1, true, game, 1)
                    		elseif Mode == "Low" then
                    			VirtualInputManager:SendMouseButtonEvent(0, 0, 1, true, game, 1)
                    		end
                    		task.wait(0.1)
                    		VirtualInputManager:SendMouseButtonEvent(0, 0, 1, false, game, 1)
                    		if Mode == "High" or Mode == "Mid" then
                    			VirtualInputManager:SendKeyEvent(false, CONFIG.Keys.Jump, false, game)
                    		end
                    		if holdKey then
                    			VirtualInputManager:SendKeyEvent(false, holdKey, false, game)
                    		end
                    		task.wait(0.8)
                    		DiveCooldown = false
                    	end)
                    end
                    local function GetReactionThreshold(sidewaysDist)
                    	local DistCenter, DistFar = 4.0, 16.0
                    	if sidewaysDist >= DistFar then return CONFIG.TimeThresholdFar end
                    	if sidewaysDist <= DistCenter then return CONFIG.TimeThresholdMid end
                    	local alpha = (sidewaysDist - DistCenter) / (DistFar - DistCenter)
                    	return CONFIG.TimeThresholdMid + (CONFIG.TimeThresholdFar - CONFIG.TimeThresholdMid) * alpha
                    end
                    local function Update(dt)
                    	if not CONFIG.Enabled or not RootPart then return end
                    	if not UserInputService:IsKeyDown(CONFIG.ActivationKey) then
                    		return
                    	end
                    	local Ball = Workspace:FindFirstChild("Temp") and Workspace.Temp:FindFirstChild("Ball")
                    	if not Ball then Ball = Workspace:FindFirstChild("Ball") end
                    	if not Ball then return end
                    	local currentVel = Ball.AssemblyLinearVelocity
                    	if currentVel.Magnitude < CONFIG.MinBallVelocity then return end
                    	local externalAcc = Vector3.zero
                    	local mfObj = Ball:FindFirstChildWhichIsA("VectorForce", true)
                    	if mfObj and mfObj.Enabled then
                    		local rawForce = mfObj.Force
                    		if mfObj.RelativeTo == Enum.ActuatorRelativeTo.Attachment0 and mfObj.Attachment0 then
                    			rawForce = mfObj.Attachment0.WorldCFrame:VectorToWorldSpace(rawForce)
                    		elseif mfObj.RelativeTo == Enum.ActuatorRelativeTo.Attachment1 and mfObj.Attachment1 then
                    			rawForce = mfObj.Attachment1.WorldCFrame:VectorToWorldSpace(rawForce)
                    		end
                    		externalAcc = rawForce / Ball.AssemblyMass
                    	end
                    	local simPos = Ball.Position
                    	local simVel = currentVel
                    	local stepDt = 0.015
                    	local rootCF = RootPart.CFrame
                    	local startRelPos = rootCF:PointToObjectSpace(simPos)
                    	local lastRelZ = startRelPos.Z
                    	for i = 1, 100 do
                    		local oldPos = simPos
                    		local oldRelZ = lastRelZ
                    		simVel = simVel + ((CONFIG.Gravity + externalAcc) * stepDt)
                    		simPos = simPos + (simVel * stepDt)
                    		if simPos.Y < CONFIG.BallRadius then
                    			simPos = Vector3.new(simPos.X, CONFIG.BallRadius, simPos.Z)
                    			simVel = Vector3.new(simVel.X, -simVel.Y * CONFIG.BounceElasticity, simVel.Z)
                    		end
                    		if CONFIG.ShowVisuals and i % 3 == 0 then
                    			DrawPoint(simPos, Color3.new(1,0,0), 0.2)
                    		end
                    		local currentRelPos = rootCF:PointToObjectSpace(simPos)
                    		local currentRelZ = currentRelPos.Z
                    		if (oldRelZ * currentRelZ) <= 0 then
                    			local totalZDist = math.abs(oldRelZ - currentRelZ)
                    			local alpha = 0
                    			if totalZDist > 0.0001 then alpha = math.abs(oldRelZ) / totalZDist end
                    			local exactImpactPos = oldPos:Lerp(simPos, alpha)
                    			local relImpact = rootCF:PointToObjectSpace(exactImpactPos)
                    			local impactTime = (i - 1 + alpha) * stepDt
                    			if relImpact.Y > -5 and relImpact.Y < CONFIG.ReachY and math.abs(relImpact.X) < CONFIG.ReachX then
                    				local sidewaysDist = math.abs(relImpact.X)
                    				local relativeHeight = relImpact.Y
                    				if impactTime <= GetReactionThreshold(sidewaysDist) then
                    					local mode = "Low"
                    					local color = Color3.new(0,1,0)
                    					if relativeHeight < CONFIG.Height_Split_LowMid then
                    						mode = "Low"
                    						color = Color3.new(0, 1, 0)
                    					elseif relativeHeight <= CONFIG.Height_Split_MidHigh then
                    						mode = "Mid"
                    						color = Color3.new(1, 0.5, 0)
                    					else
                    						mode = "High"
                    						color = Color3.new(1, 0, 1)
                    					end
                    					local dir = "Center"
                    					if relImpact.X > 2.5 then dir = "Right"
                    					elseif relImpact.X < -2.5 then dir = "Left"
                    					end
                    					DrawPoint(exactImpactPos, color, 1.0)
                    					PerformDive(dir, mode)
                    				end
                    			end
                    			break
                    		end
                    		lastRelZ = currentRelZ
                    	end
                    end
                    RunService.RenderStepped:Connect(Update)
                ]])()
            end
        end
    })
    
    AutoGkGroup:AddLabel('Keybind: 1')
    
    local ZoomGroup = Tabs.Main:AddRightGroupbox('Zoom')
    ZoomGroup:AddToggle('ZoomToggle', {
        Text = 'Enable Zoom',
        Default = false,
        Callback = function(Value)
            if Value then
                loadstring([[
                    local Players = game:GetService("Players")
                    local player = Players.LocalPlayer
                    player.CameraMaxZoomDistance = 10000
                ]])()
            else
                loadstring([[
                    local Players = game:GetService("Players")
                    local player = Players.LocalPlayer
                    player.CameraMaxZoomDistance = 12
                ]])()
            end
        end
    })
    
    -- PACK TAB (RIN PACK - ONLY AFFECTS AIMBOT V1 AND PREHOLD)
    local PackGroup = Tabs.Pack:AddLeftGroupbox('Rin Animation Pack')
    PackGroup:AddToggle('RinPackToggle', {
        Text = 'Enable Rin Animation Pack',
        Default = false,
        Callback = function(Value)
            if Value then
                Library:Notify('Rin Animation Pack Enabled - Affects Aimbot V1 and Prehold only', 3)
            else
                Library:Notify('Rin Animation Pack Disabled - Default animations restored', 3)
            end
        end
    })
    
    PackGroup:AddLabel('Changes animations to Rin pack for:')
    PackGroup:AddLabel('• Aimbot V1')
    PackGroup:AddLabel('• Auto Prehold')
    PackGroup:AddLabel('')
    PackGroup:AddLabel('Other features keep their default animations')
    
    -- INTERPOLATION TAB
    local InterpGroup = Tabs.Interpolation:AddLeftGroupbox('Interpolation')
    local interpValues = {100, 95, 90, 85, 80, 75, 70, 65, 60, 55, 50, 45, 40, 35, 30, 25, 20, 15, 10, 5}
    
    for i = 1, math.min(10, #interpValues) do
        InterpGroup:AddButton(interpValues[i] .. ' Interpolation', function()
            pcall(function()
                setfflag("InterpolationMaxDelayMSec", tostring(interpValues[i]))
                Library:Notify('Set interpolation to: ' .. interpValues[i], 3)
            end)
        end)
    end
    
    local InterpGroup2 = Tabs.Interpolation:AddLeftGroupbox('Interpolation (Continued)')
    for i = 11, #interpValues do
        InterpGroup2:AddButton(interpValues[i] .. ' Interpolation', function()
            pcall(function()
                setfflag("InterpolationMaxDelayMSec", tostring(interpValues[i]))
                Library:Notify('Set interpolation to: ' .. interpValues[i], 3)
            end)
        end)
    end
    
    local DynamicInterpGroup = Tabs.Interpolation:AddRightGroupbox('Dynamic Interpolation')
    DynamicInterpGroup:AddToggle('DynamicInterpToggle', {
        Text = 'Enable Dynamic Interpolation',
        Default = false,
        Callback = function(Value)
            if Value then
                loadstring([[
                    local Workspace = game:GetService("Workspace")
                    local RunService = game:GetService("RunService")
                    
                    local normalInterp = ]] .. (Options.NormalInterpSlider and Options.NormalInterpSlider.Value or 35) .. [[
                    local ballInterp = ]] .. (Options.BallInterpSlider and Options.BallInterpSlider.Value or 15) .. [[
                    
                    local function getBall()
                        local tempFolder = Workspace:FindFirstChild("Temp")
                        return tempFolder and tempFolder:FindFirstChild("Ball") or Workspace:FindFirstChild("Ball")
                    end
                    
                    local function hasBall()
                        local ball = getBall()
                        if ball then
                            local highlight = ball:FindFirstChild("PossessionHighlight")
                            return highlight and true or false
                        end
                        return false
                    end
                    
                    RunService.Heartbeat:Connect(function()
                        if hasBall() then
                            setfflag("InterpolationMaxDelayMSec", tostring(ballInterp))
                        else
                            setfflag("InterpolationMaxDelayMSec", tostring(normalInterp))
                        end
                    end)
                ]])()
            else
                setfflag("InterpolationMaxDelayMSec", tostring(35))
            end
        end
    })
    
    DynamicInterpGroup:AddSlider('NormalInterpSlider', {
        Text = 'Normal Interpolation',
        Default = 35,
        Min = 5,
        Max = 100,
        Rounding = 0,
        Callback = function(Value)
            if not Toggles.DynamicInterpToggle.Value then
                setfflag("InterpolationMaxDelayMSec", tostring(Value))
            end
        end
    })
    
    DynamicInterpGroup:AddSlider('BallInterpSlider', {
        Text = 'With Ball Interpolation',
        Default = 15,
        Min = 5,
        Max = 100,
        Rounding = 0,
        Callback = function(Value) end
    })
    
    DynamicInterpGroup:AddLabel('Automatically changes interpolation')
    DynamicInterpGroup:AddLabel('when you have ball possession')
    
    -- CONFIGURATION TAB
    local KeybindGroup = Tabs.Configuration:AddLeftGroupbox('Keybind Configuration')
    KeybindGroup:AddLabel('Auto Header Key'):AddKeyPicker('AutoHeaderKeybind', {
        Default = 'T',
        NoUI = false,
        Text = 'Auto Header',
        Mode = 'Toggle',
        Callback = function(Value) print('Auto Header keybind clicked:', Value) end,
        ChangedCallback = function(New) print('Auto Header keybind changed:', New) end
    })
    
    KeybindGroup:AddLabel('TP Moss Key'):AddKeyPicker('TPMossKeybind', {
        Default = 'Y',
        NoUI = false,
        Text = 'TP Moss',
        Mode = 'Toggle',
        Callback = function(Value) print('TP Moss keybind clicked:', Value) end,
        ChangedCallback = function(New) print('TP Moss keybind changed:', New) end
    })
    
    KeybindGroup:AddLabel('Double Tap Key'):AddKeyPicker('DoubleTapKeybind', {
        Default = 'X',
        NoUI = false,
        Text = 'Double Tap',
        Mode = 'Toggle',
        Callback = function(Value) print('Double Tap keybind clicked:', Value) end,
        ChangedCallback = function(New) print('Double Tap keybind changed:', New) end
    })
    
    KeybindGroup:AddLabel('Auto GK Key'):AddKeyPicker('AutoGkKeybind', {
        Default = 'One',
        NoUI = false,
        Text = 'Auto GK',
        Mode = 'Hold',
        Callback = function(Value) print('Auto GK keybind clicked:', Value) end,
        ChangedCallback = function(New) print('Auto GK keybind changed:', New) end
    })
    
    KeybindGroup:AddLabel('Aimbot High Key'):AddKeyPicker('AimbotHighKeybind', {
        Default = 'V',
        NoUI = false,
        Text = 'Aimbot High',
        Mode = 'Toggle',
        Callback = function(Value) print('Aimbot High keybind clicked:', Value) end,
        ChangedCallback = function(New) print('Aimbot High keybind changed:', New) end
    })
    
    KeybindGroup:AddLabel('Aimbot Low Key'):AddKeyPicker('AimbotLowKeybind', {
        Default = 'B',
        NoUI = false,
        Text = 'Aimbot Low',
        Mode = 'Toggle',
        Callback = function(Value) print('Aimbot Low keybind clicked:', Value) end,
        ChangedCallback = function(New) print('Aimbot Low keybind changed:', New) end
    })
    
    KeybindGroup:AddLabel('Auto Prehold Toggle'):AddKeyPicker('PreholdToggleKeybind', {
        Default = 'Four',
        NoUI = false,
        Text = 'Auto Prehold Toggle',
        Mode = 'Toggle',
        Callback = function(Value) print('Auto Prehold Toggle keybind clicked:', Value) end,
        ChangedCallback = function(New) print('Auto Prehold Toggle keybind changed:', New) end
    })
    
    KeybindGroup:AddLabel('Auto Prehold Manual'):AddKeyPicker('PreholdManualKeybind', {
        Default = 'G',
        NoUI = false,
        Text = 'Auto Prehold Manual',
        Mode = 'Toggle',
        Callback = function(Value) print('Auto Prehold Manual keybind clicked:', Value) end,
        ChangedCallback = function(New) print('Auto Prehold Manual keybind changed:', New) end
    })
    
    KeybindGroup:AddLabel('Auto M2 Toggle'):AddKeyPicker('AutoM2Keybind', {
        Default = 'Three',
        NoUI = false,
        Text = 'Auto M2 Toggle',
        Mode = 'Toggle',
        Callback = function(Value) print('Auto M2 keybind clicked:', Value) end,
        ChangedCallback = function(New) print('Auto M2 keybind changed:', New) end
    })
    
    KeybindGroup:AddLabel('Auto Chip Key'):AddKeyPicker('AutoChipKeybind', {
        Default = 'Five',
        NoUI = false,
        Text = 'Auto Chip',
        Mode = 'Toggle',
        Callback = function(Value) print('Auto Chip keybind clicked:', Value) end,
        ChangedCallback = function(New) print('Auto Chip keybind changed:', New) end
    })
    
    KeybindGroup:AddLabel('Aimbot V2 Top'):AddKeyPicker('AimbotV2TopKeybind', {
        Default = 'One',
        NoUI = false,
        Text = 'Aimbot V2 Top',
        Mode = 'Toggle',
        Callback = function(Value) print('Aimbot V2 Top keybind clicked:', Value) end,
        ChangedCallback = function(New) print('Aimbot V2 Top keybind changed:', New) end
    })
    
    KeybindGroup:AddLabel('Aimbot V2 Bottom'):AddKeyPicker('AimbotV2BottomKeybind', {
        Default = 'Two',
        NoUI = false,
        Text = 'Aimbot V2 Bottom',
        Mode = 'Toggle',
        Callback = function(Value) print('Aimbot V2 Bottom keybind clicked:', Value) end,
        ChangedCallback = function(New) print('Aimbot V2 Bottom keybind changed:', New) end
    })
    
    local SettingsGroup = Tabs.Configuration:AddRightGroupbox('Settings')
    SettingsGroup:AddSlider('SpeedDefaultSlider', {
        Text = 'Default Speed Multiplier',
        Default = 1.24,
        Min = 1.00,
        Max = 5.00,
        Rounding = 2,
        Callback = function(Value)
            Options.SpeedSlider:SetValue(Value)
        end
    })
    
    SettingsGroup:AddSlider('HitboxDefaultSlider', {
        Text = 'Default Hitbox Size',
        Default = 15,
        Min = 1,
        Max = 50,
        Rounding = 0,
        Callback = function(Value)
            Options.HitboxSlider:SetValue(Value)
        end
    })
    
    SettingsGroup:AddSlider('AimbotPowerDefaultSlider', {
        Text = 'Default Aimbot Power',
        Default = 100,
        Min = 100,
        Max = 999,
        Rounding = 0,
        Callback = function(Value)
            if Options.AimbotPowerSlider then
                Options.AimbotPowerSlider:SetValue(Value)
            end
        end
    })
    
    SettingsGroup:AddSlider('PreholdRangeDefaultSlider', {
        Text = 'Default Prehold Range',
        Default = 4,
        Min = 1,
        Max = 15,
        Rounding = 1,
        Callback = function(Value)
            if Options.PreholdRangeSlider then
                Options.PreholdRangeSlider:SetValue(Value)
            end
        end
    })
    
    SettingsGroup:AddSlider('ShoveReachDefaultSlider', {
        Text = 'Default Shove Reach',
        Default = 25,
        Min = 10,
        Max = 50,
        Rounding = 0,
        Callback = function(Value)
            if Options.ShoveReachSlider then
                Options.ShoveReachSlider:SetValue(Value)
            end
        end
    })
    
    SettingsGroup:AddSlider('ChipForceDefaultSlider', {
        Text = 'Default Chip Force',
        Default = 27.13,
        Min = 10,
        Max = 100,
        Rounding = 2,
        Callback = function(Value)
            if Options.ChipForceSlider then
                Options.ChipForceSlider:SetValue(Value)
            end
        end
    })
    
    SettingsGroup:AddSlider('ChipVectorDefaultSlider', {
        Text = 'Default Chip Vector',
        Default = 1.0,
        Min = 0.5,
        Max = 3.0,
        Rounding = 1,
        Callback = function(Value)
            if Options.ChipVectorSlider then
                Options.ChipVectorSlider:SetValue(Value)
            end
        end
    })
    
    SettingsGroup:AddSlider('AimbotV2RangeDefaultSlider', {
        Text = 'Default Aimbot V2 Range',
        Default = 7,
        Min = 3,
        Max = 20,
        Rounding = 0,
        Callback = function(Value)
            if Options.AimbotV2RangeSlider then
                Options.AimbotV2RangeSlider:SetValue(Value)
            end
        end
    })
    
    SettingsGroup:AddSlider('AimbotV2PowerDefaultSlider', {
        Text = 'Default Aimbot V2 Power',
        Default = 140,
        Min = 100,
        Max = 999,
        Rounding = 0,
        Callback = function(Value)
            if Options.AimbotV2PowerSlider then
                Options.AimbotV2PowerSlider:SetValue(Value)
            end
        end
    })
    
    SettingsGroup:AddButton('Reset All Settings', function()
        Toggles.SpeedToggle:SetValue(false)
        Toggles.StaminaToggle:SetValue(false)
        Toggles.KickToggle:SetValue(false)
        Toggles.LastDiscToggle:SetValue(false)
        Toggles.TPMossToggle:SetValue(false)
        Toggles.HitboxToggle:SetValue(false)
        Toggles.HeaderToggle:SetValue(false)
        Toggles.AutoGkToggle:SetValue(false)
        Toggles.ZoomToggle:SetValue(false)
        Toggles.AimbotToggle:SetValue(false)
        Toggles.PreholdToggle:SetValue(false)
        Toggles.DoubleTapToggle:SetValue(false)
        Toggles.AutoM2Toggle:SetValue(false)
        Toggles.ShoveToggle:SetValue(false)
        Toggles.AutoChipToggle:SetValue(false)
        Toggles.AimbotV2Toggle:SetValue(false)
        Toggles.RinPackToggle:SetValue(false)
        Toggles.DynamicInterpToggle:SetValue(false)
        
        Options.SpeedSlider:SetValue(1.24)
        Options.HitboxSlider:SetValue(15)
        Options.AimbotPowerSlider:SetValue(100)
        Options.PreholdRangeSlider:SetValue(4)
        Options.ShoveReachSlider:SetValue(25)
        Options.ChipForceSlider:SetValue(27.13)
        Options.ChipVectorSlider:SetValue(1.0)
        Options.AimbotV2RangeSlider:SetValue(7)
        Options.AimbotV2PowerSlider:SetValue(140)
        Options.NormalInterpSlider:SetValue(35)
        Options.BallInterpSlider:SetValue(15)
        
        Library:Notify('All settings reset to default', 3)
    end)
    
    -- Original UI Settings code
    Library:SetWatermarkVisibility(true)
    
    local FrameTimer = tick()
    local FrameCounter = 0;
    local FPS = 60;
    
    local WatermarkConnection = game:GetService('RunService').RenderStepped:Connect(function()
        FrameCounter += 1;
    
        if (tick() - FrameTimer) >= 1 then
            FPS = FrameCounter;
            FrameTimer = tick();
            FrameCounter = 0;
        end;
    
        Library:SetWatermark(('Vevo Hub v1.2 | %s fps | %s ms'):format(
            math.floor(FPS),
            math.floor(game:GetService('Stats').Network.ServerStatsItem['Data Ping']:GetValue())
        ));
    end);
    
    Library.KeybindFrame.Visible = true;
    
    Library:OnUnload(function()
        WatermarkConnection:Disconnect()
        print('Unloaded!')
        Library.Unloaded = true
    end)
    
    local MenuGroup = Tabs['UI Settings']:AddLeftGroupbox('Menu')
    
    MenuGroup:AddButton('Unload', function() Library:Unload() end)
    MenuGroup:AddLabel('Menu bind'):AddKeyPicker('MenuKeybind', { Default = 'End', NoUI = true, Text = 'Menu keybind' })
    
    Library.ToggleKeybind = Options.MenuKeybind 
    
    -- Apply theme with grayish accent color
    ThemeManager:SetLibrary(Library)
    SaveManager:SetLibrary(Library)
    
    SaveManager:IgnoreThemeSettings()
    
    SaveManager:SetIgnoreIndexes({ 'MenuKeybind' })
    
    ThemeManager:SetFolder('VevoHub')
    SaveManager:SetFolder('VevoHub/Freestyle Football')
    
    -- Set accent color to grayish
    Library.AccentColor = Color3.fromHex('#333333')
    Library.MainColor = Color3.fromHex('#1c1c1c')
    Library.BackgroundColor = Color3.fromHex('#141414')
    Library.OutlineColor = Color3.fromHex('#323232')
    Library.FontColor = Color3.fromHex('#ffffff')
    Library.AccentColorDark = Library:GetDarkerColor(Library.AccentColor)
    Library:UpdateColorsUsingRegistry()
    
    SaveManager:BuildConfigSection(Tabs['UI Settings'])
    ThemeManager:ApplyToTab(Tabs['UI Settings'])
    SaveManager:LoadAutoloadConfig()
end

-- Start the key system
if not isAuthenticated and not IsHWIDActivated() then
    RegistrationWindow:Show()
end
