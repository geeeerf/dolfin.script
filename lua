-- PlayerTools.local.lua
-- LocalScript -> поместить в StarterPlayerScripts
-- Интерфейс и клиентская логика: GUI, локальная подсветка, локальный Fly, локальный Anti-Knockback,
-- поля для ввода (fly speed 10-400, jump 10-400 отправляется на сервер, hitbox 0-100 отправляется на сервер).

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LOCAL_PLAYER = Players.LocalPlayer
local PLAYER_GUI = LOCAL_PLAYER:WaitForChild("PlayerGui")

-- RemoteEvent
local REMOTE_NAME = "PlayerToolsRemote"
local remoteEvent = ReplicatedStorage:WaitForChild(REMOTE_NAME)

-- UI (создаём простое переносимое меню)
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PlayerToolsGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = PLAYER_GUI

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 380, 0, 520)
mainFrame.Position = UDim2.new(0.02, 0, 0.06, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui
local uiCorner = Instance.new("UICorner", mainFrame)
uiCorner.CornerRadius = UDim.new(0, 8)

local title = Instance.new("TextLabel", mainFrame)
title.Name = "Title"
title.Text = "Player Tools"
title.Size = UDim2.new(1, -16, 0, 36)
title.Position = UDim2.new(0, 8, 0, 8)
title.BackgroundTransparency = 1
title.TextColor3 = Color3.fromRGB(240,240,240)
title.Font = Enum.Font.SourceSansSemibold
title.TextSize = 20

-- draggable
do
	local dragging, dragStart, startPos = false, Vector2.new(), mainFrame.Position
	local function inputBegan(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = mainFrame.Position
		end
	end
	local function inputChanged(input)
		if not dragging then return end
		local delta = input.Position - dragStart
		mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end
	local function inputEnded(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end
	mainFrame.InputBegan:Connect(inputBegan)
	mainFrame.InputChanged:Connect(inputChanged)
	mainFrame.InputEnded:Connect(inputEnded)
end

-- feedback
local feedbackLabel = Instance.new("TextLabel", mainFrame)
feedbackLabel.Size = UDim2.new(1, -16, 0, 24)
feedbackLabel.Position = UDim2.new(0, 8, 0, 460)
feedbackLabel.BackgroundTransparency = 1
feedbackLabel.TextColor3 = Color3.fromRGB(200,200,200)
feedbackLabel.Font = Enum.Font.SourceSans
feedbackLabel.TextSize = 14
local function updateFeedback(msg)
	feedbackLabel.Text = msg or ""
end

-- Players list (локальная подсветка)
local listLabel = Instance.new("TextLabel", mainFrame)
listLabel.Text = "Players (local highlight)"
listLabel.BackgroundTransparency = 1
listLabel.Position = UDim2.new(0, 8, 0, 56)
listLabel.Size = UDim2.new(1, -16, 0, 20)
listLabel.TextColor3 = Color3.fromRGB(220,220,220)
listLabel.Font = Enum.Font.SourceSans
listLabel.TextSize = 16

local scroll = Instance.new("ScrollingFrame", mainFrame)
scroll.Name = "PlayerScroll"
scroll.Position = UDim2.new(0, 8, 0, 80)
scroll.Size = UDim2.new(1, -16, 0, 120)
scroll.BackgroundTransparency = 0.95
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.ScrollBarThickness = 6
local uiListLayout = Instance.new("UIListLayout", scroll)
uiListLayout.SortOrder = Enum.SortOrder.LayoutOrder
uiListLayout.Padding = UDim.new(0, 6)

local localHighlights = {}

local function enableLocalHighlight(targetPlayer)
	if not targetPlayer or not targetPlayer.Character then return end
	if localHighlights[targetPlayer] and localHighlights[targetPlayer].Parent then return end
	local h = Instance.new("Highlight")
	h.Name = "LocalHighlight_"..targetPlayer.Name
	h.Adornee = targetPlayer.Character
	h.FillColor = Color3.fromRGB(255, 120, 20)
	h.OutlineColor = Color3.fromRGB(255,255,255)
	h.FillTransparency = 0.6
	h.OutlineTransparency = 0.2
	h.Parent = PLAYER_GUI
	localHighlights[targetPlayer] = h
	targetPlayer.CharacterAdded:Connect(function(chr)
		wait(0.05)
		if localHighlights[targetPlayer] and localHighlights[targetPlayer].Parent then
			localHighlights[targetPlayer].Adornee = chr
		end
	end)
end

local function disableLocalHighlight(targetPlayer)
	if localHighlights[targetPlayer] then
		pcall(function() localHighlights[targetPlayer]:Destroy() end)
		localHighlights[targetPlayer] = nil
	end
end

local function createPlayerLine(targetPlayer)
	local container = Instance.new("Frame")
	container.Size = UDim2.new(1, -12, 0, 36)
	container.BackgroundTransparency = 1
	container.Parent = scroll

	local nameLabel = Instance.new("TextLabel", container)
	nameLabel.Text = targetPlayer.Name
	nameLabel.Size = UDim2.new(0.6, 0, 1, 0)
	nameLabel.Position = UDim2.new(0, 4, 0, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.TextColor3 = Color3.fromRGB(235,235,235)
	nameLabel.Font = Enum.Font.SourceSans
	nameLabel.TextSize = 16
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left

	local btn = Instance.new("TextButton", container)
	btn.Size = UDim2.new(0.36, -8, 0, 28)
	btn.Position = UDim2.new(0.64, 0, 0, 4)
	btn.Text = "Highlight"
	btn.Font = Enum.Font.SourceSansSemibold
	btn.TextSize = 14
	btn.BackgroundColor3 = Color3.fromRGB(70, 120, 200)
	btn.TextColor3 = Color3.fromRGB(255,255,255)
	btn.AutoButtonColor = true
	local corner = Instance.new("UICorner", btn)

	local toggled = false
	btn.Activated:Connect(function()
		toggled = not toggled
		if toggled then
			btn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
			btn.Text = "Unhighlight"
			enableLocalHighlight(targetPlayer)
		else
			btn.BackgroundColor3 = Color3.fromRGB(70, 120, 200)
			btn.Text = "Highlight"
			disableLocalHighlight(targetPlayer)
		end
	end)
end

local function rebuildPlayerList()
	for _, child in ipairs(scroll:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= LOCAL_PLAYER then createPlayerLine(p) end
	end
	wait()
	scroll.CanvasSize = UDim2.new(0,0,0, uiListLayout.AbsoluteContentSize.Y + 8)
end
Players.PlayerAdded:Connect(rebuildPlayerList)
Players.PlayerRemoving:Connect(rebuildPlayerList)
rebuildPlayerList()

-- Global highlight toggle (через сервер)
local globalBtn = Instance.new("TextButton", mainFrame)
globalBtn.Text = "Toggle Highlight All (server)"
globalBtn.Size = UDim2.new(1, -16, 0, 34)
globalBtn.Position = UDim2.new(0, 8, 0, 210)
globalBtn.Font = Enum.Font.SourceSansSemibold
globalBtn.TextSize = 14
globalBtn.BackgroundColor3 = Color3.fromRGB(90,90,90)
globalBtn.TextColor3 = Color3.fromRGB(255,255,255)
local globalCorner = Instance.new("UICorner", globalBtn)

local globalToggled = false
globalBtn.Activated:Connect(function()
	globalToggled = not globalToggled
	if globalToggled then
		globalBtn.BackgroundColor3 = Color3.fromRGB(200,60,60)
		globalBtn.Text = "Disable Highlight All"
	else
		globalBtn.BackgroundColor3 = Color3.fromRGB(90,90,90)
		globalBtn.Text = "Toggle Highlight All (server)"
	end
	remoteEvent:FireServer("ToggleGlobalHighlight", globalToggled)
end)

-- Fly controls
local flyLabel = Instance.new("TextLabel", mainFrame)
flyLabel.Text = "Fly"
flyLabel.BackgroundTransparency = 1
flyLabel.Position = UDim2.new(0, 8, 0, 250)
flyLabel.Size = UDim2.new(0.4, 0, 0, 20)
flyLabel.TextColor3 = Color3.fromRGB(220,220,220)
flyLabel.Font = Enum.Font.SourceSans
flyLabel.TextSize = 16

local flyToggle = Instance.new("TextButton", mainFrame)
flyToggle.Text = "Toggle Fly"
flyToggle.Size = UDim2.new(0.36, -8, 0, 36)
flyToggle.Position = UDim2.new(0, 12, 0, 282)
flyToggle.Font = Enum.Font.SourceSansSemibold
flyToggle.TextSize = 16
flyToggle.BackgroundColor3 = Color3.fromRGB(60,60,60)
flyToggle.TextColor3 = Color3.fromRGB(240,240,240)
local flyCorner = Instance.new("UICorner", flyToggle)

local speedBox = Instance.new("TextBox", mainFrame)
speedBox.PlaceholderText = "Fly speed (10-400)"
speedBox.Text = ""
speedBox.Size = UDim2.new(0, 140, 0, 30)
speedBox.Position = UDim2.new(0, 150, 0, 282)
speedBox.ClearTextOnFocus = false
speedBox.TextColor3 = Color3.fromRGB(240,240,240)
speedBox.BackgroundColor3 = Color3.fromRGB(80,80,80)
local speedCorner = Instance.new("UICorner", speedBox)

local setSpeedBtn = Instance.new("TextButton", mainFrame)
setSpeedBtn.Text = "Set"
setSpeedBtn.Size = UDim2.new(0, 60, 0, 30)
setSpeedBtn.Position = UDim2.new(0, 300, 0, 282)
setSpeedBtn.Font = Enum.Font.SourceSansSemibold
setSpeedBtn.TextSize = 16
setSpeedBtn.BackgroundColor3 = Color3.fromRGB(70,120,200)
setSpeedBtn.TextColor3 = Color3.fromRGB(255,255,255)
local setSpeedCorner = Instance.new("UICorner", setSpeedBtn)

-- Jump controls (отправляется на сервер)
local jumpBox = Instance.new("TextBox", mainFrame)
jumpBox.PlaceholderText = "Jump power (10-400)"
jumpBox.Text = ""
jumpBox.Size = UDim2.new(0, 200, 0, 30)
jumpBox.Position = UDim2.new(0, 12, 0, 320)
jumpBox.ClearTextOnFocus = false
jumpBox.TextColor3 = Color3.fromRGB(240,240,240)
jumpBox.BackgroundColor3 = Color3.fromRGB(80,80,80)
local jumpCorner = Instance.new("UICorner", jumpBox)

local setJumpBtn = Instance.new("TextButton", mainFrame)
setJumpBtn.Text = "Set Jump"
setJumpBtn.Size = UDim2.new(0, 120, 0, 30)
setJumpBtn.Position = UDim2.new(0, 220, 0, 320)
setJumpBtn.Font = Enum.Font.SourceSansSemibold
setJumpBtn.TextSize = 16
setJumpBtn.BackgroundColor3 = Color3.fromRGB(70,120,200)
setJumpBtn.TextColor3 = Color3.fromRGB(255,255,255)
local setJumpCorner = Instance.new("UICorner", setJumpBtn)

-- Hitbox control (отправляется на сервер)
local hitboxBox = Instance.new("TextBox", mainFrame)
hitboxBox.PlaceholderText = "Hitbox increase 0-100 (%)"
hitboxBox.Text = ""
hitboxBox.Size = UDim2.new(0, 220, 0, 30)
hitboxBox.Position = UDim2.new(0, 12, 0, 360)
hitboxBox.ClearTextOnFocus = false
hitboxBox.TextColor3 = Color3.fromRGB(240,240,240)
hitboxBox.BackgroundColor3 = Color3.fromRGB(80,80,80)
local hitboxCorner = Instance.new("UICorner", hitboxBox)

local setHitboxBtn = Instance.new("TextButton", mainFrame)
setHitboxBtn.Text = "Set Hitbox"
setHitboxBtn.Size = UDim2.new(0, 120, 0, 30)
setHitboxBtn.Position = UDim2.new(0, 244, 0, 360)
setHitboxBtn.Font = Enum.Font.SourceSansSemibold
setHitboxBtn.TextSize = 16
setHitboxBtn.BackgroundColor3 = Color3.fromRGB(70,120,200)
setHitboxBtn.TextColor3 = Color3.fromRGB(255,255,255)
local setHitboxCorner = Instance.new("UICorner", setHitboxBtn)

-- Anti-knockback control (локально)
local antiLabel = Instance.new("TextLabel", mainFrame)
antiLabel.Text = "Anti-Knockback 0-100 (%)"
antiLabel.BackgroundTransparency = 1
antiLabel.Position = UDim2.new(0, 12, 0, 400)
antiLabel.Size = UDim2.new(0.6, 0, 0, 20)
antiLabel.TextColor3 = Color3.fromRGB(220,220,220)
antiLabel.Font = Enum.Font.SourceSans
antiLabel.TextSize = 14

local antiBox = Instance.new("TextBox", mainFrame)
antiBox.PlaceholderText = "0-100"
antiBox.Text = "0"
antiBox.Size = UDim2.new(0, 120, 0, 30)
antiBox.Position = UDim2.new(0, 12, 0, 424)
antiBox.ClearTextOnFocus = false
antiBox.TextColor3 = Color3.fromRGB(240,240,240)
antiBox.BackgroundColor3 = Color3.fromRGB(80,80,80)
local antiCorner = Instance.new("UICorner", antiBox)

local setAntiBtn = Instance.new("TextButton", mainFrame)
setAntiBtn.Text = "Set Anti"
setAntiBtn.Size = UDim2.new(0, 120, 0, 30)
setAntiBtn.Position = UDim2.new(0, 144, 0, 424)
setAntiBtn.Font = Enum.Font.SourceSansSemibold
setAntiBtn.TextSize = 14
setAntiBtn.BackgroundColor3 = Color3.fromRGB(70,120,200)
setAntiBtn.TextColor3 = Color3.fromRGB(255,255,255)
local setAntiCorner = Instance.new("UICorner", setAntiBtn)

-- Utility
local function clampNumber(n, low, high)
	local num = tonumber(n)
	if not num then return nil end
	return math.clamp(math.floor(num), low, high)
end

-- Fly implementation
local flying = false
local flySpeed = 50
local forward, backward, left, right, up, down = false, false, false, false, false, false
local flightBV, flightBG

local function applyFlySpeedValue(val)
	local clamped = clampNumber(val, 10, 400)
	if not clamped then
		updateFeedback("Неправильное значение скорости.")
		return
	end
	flySpeed = clamped
	updateFeedback("Fly speed установлен: "..tostring(flySpeed))
end
setSpeedBtn.Activated:Connect(function() applyFlySpeedValue(speedBox.Text) end)
speedBox.FocusLost:Connect(function(enter) if enter then applyFlySpeedValue(speedBox.Text) end end)

local function startFly()
	local char = LOCAL_PLAYER.Character
	if not char then updateFeedback("Нет персонажа.") return end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	local humanoid = char:FindFirstChildOfClass("Humanoid")
	if not hrp or not humanoid then updateFeedback("Ошибка: нет HRP/Humanoid.") return end

	if flightBV then flightBV:Destroy() end
	if flightBG then flightBG:Destroy() end

	flightBV = Instance.new("BodyVelocity")
	flightBV.Name = "LocalFly_BV"
	flightBV.MaxForce = Vector3.new(1e5, 1e5, 1e5)
	flightBV.Velocity = Vector3.new(0,0,0)
	flightBV.Parent = hrp

	flightBG = Instance.new("BodyGyro")
	flightBG.Name = "LocalFly_BG"
	flightBG.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
	flightBG.P = 3000
	flightBG.Parent = hrp

	flying = true
	updateFeedback("Fly включён. Скорость: "..tostring(flySpeed))
end

local function stopFly()
	flying = false
	if flightBV then pcall(function() flightBV:Destroy() end) flightBV = nil end
	if flightBG then pcall(function() flightBG:Destroy() end) flightBG = nil end
	updateFeedback("Fly выключен.")
end

flyToggle.Activated:Connect(function()
	if flying then stopFly() flyToggle.Text = "Toggle Fly"
	else startFly() flyToggle.Text = "Stop Fly" end
end)

-- Input handling
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.W then forward = true end
	if input.KeyCode == Enum.KeyCode.S then backward = true end
	if input.KeyCode == Enum.KeyCode.A then left = true end
	if input.KeyCode == Enum.KeyCode.D then right = true end
	if input.KeyCode == Enum.KeyCode.Space then up = true end
	if input.KeyCode == Enum.KeyCode.LeftShift then down = true end
end)
UserInputService.InputEnded:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.W then forward = false end
	if input.KeyCode == Enum.KeyCode.S then backward = false end
	if input.KeyCode == Enum.KeyCode.A then left = false end
	if input.KeyCode == Enum.KeyCode.D then right = false end
	if input.KeyCode == Enum.KeyCode.Space then up = false end
	if input.KeyCode == Enum.KeyCode.LeftShift then down = false end
end)

RunService.RenderStepped:Connect(function(dt)
	if flying and flightBV and flightBG then
		local char = LOCAL_PLAYER.Character
		if not char then return end
		local humanoid = char:FindFirstChildOfClass("Humanoid")
		local hrp = char:FindFirstChild("HumanoidRootPart")
		if not hrp or not humanoid then return end

		local cam = workspace.CurrentCamera
		local moveVector = Vector3.new(0,0,0)
		local look = cam.CFrame.LookVector
		local rightVec = cam.CFrame.RightVector

		if forward then moveVector = moveVector + Vector3.new(look.X, 0, look.Z) end
		if backward then moveVector = moveVector - Vector3.new(look.X, 0, look.Z) end
		if right then moveVector = moveVector + Vector3.new(rightVec.X, 0, rightVec.Z) end
		if left then moveVector = moveVector - Vector3.new(rightVec.X, 0, rightVec.Z) end

		local vertical = 0
		if up then vertical = vertical + 1 end
		if down then vertical = vertical - 1 end

		local finalVel = Vector3.new(0,0,0)
		if moveVector.Magnitude > 0 then finalVel = moveVector.Unit * flySpeed end
		finalVel = finalVel + Vector3.new(0, vertical * flySpeed, 0)
		flightBV.Velocity = finalVel

		local lookDir = Vector3.new(cam.CFrame.LookVector.X, 0, cam.CFrame.LookVector.Z)
		if lookDir.Magnitude > 0 then
			flightBG.CFrame = CFrame.new(Vector3.new(), lookDir)
		end
	end
end)

-- Jump: отправка на сервер
local function applyJumpValue(val)
	local clamped = clampNumber(val, 10, 400)
	if not clamped then
		updateFeedback("Неправильное значение прыжка.")
		return
	end
	remoteEvent:FireServer("SetJumpPower", clamped)
	updateFeedback("Запрос на установку JumpPower отправлен: "..tostring(clamped))
end
setJumpBtn.Activated:Connect(function() applyJumpValue(jumpBox.Text) end)
jumpBox.FocusLost:Connect(function(enter) if enter then applyJumpValue(jumpBox.Text) end end)

-- Hitbox: отправка на сервер
local function applyHitboxValue(val)
	local clamped = clampNumber(val, 0, 100)
	if clamped == nil then
		updateFeedback("Неправильное значение хитбокса.")
		return
	end
	remoteEvent:FireServer("SetHitboxPercent", clamped)
	updateFeedback("Запрос хитбокса отправлен: "..tostring(clamped).."%")
end
setHitboxBtn.Activated:Connect(function() applyHitboxValue(hitboxBox.Text) end)
hitboxBox.FocusLost:Connect(function(enter) if enter then applyHitboxValue(hitboxBox.Text) end end)

-- Anti-knockback (локально)
local antiPercent = 0 -- 0..100
local function setAntiPercent(val)
	local clamped = clampNumber(val, 0, 100)
	if clamped == nil then
		updateFeedback("Неправильное значение анти-отбрасывания.")
		return
	end
	antiPercent = clamped
	updateFeedback("Anti-knockback установлен: "..tostring(antiPercent).."%")
end
setAntiBtn.Activated:Connect(function() setAntiPercent(antiBox.Text) end)
antiBox.FocusLost:Connect(function(enter) if enter then setAntiPercent(antiBox.Text) end end)

-- Anti-knockback implementation:
-- На каждом кадре сравниваем текущую скорость HRP с предыдущей.
-- Если произошло резкое изменение (импульс), уменьшаем его на antiPercent.
local prevVel = Vector3.new(0,0,0)
local antiEnabled = true
RunService.Stepped:Connect(function(_, dt)
	if not antiEnabled then return end
	local char = LOCAL_PLAYER.Character
	if not char then
		prevVel = Vector3.new(0,0,0)
		return
	end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then
		prevVel = Vector3.new(0,0,0)
		return
	end

	-- Получаем текущую скорость
	local curVel = hrp.Velocity
	-- Импульс, пришедший за кадр:
	local impulse = curVel - prevVel

	-- Небольшие изменения (например от гравитации при падении) игнорируем:
	local impulseThreshold = 1.0
	if impulse.Magnitude > impulseThreshold and antiPercent > 0 then
		-- ослабляем импульс на заданный процент
		local dampFactor = 1 - (antiPercent / 100)
		local newVel = prevVel + impulse * dampFactor

		-- Устанавливаем результат аккуратно
		-- Не пытаться менять Velocity если у нас BodyVelocity для флая (во избежание конфликтов)
		if not (flightBV and flightBV.Parent) then
			-- Пытаемся избежать резких телепортов — используем small timed set
			hrp.Velocity = newVel
		end
	end

	prevVel = hrp.Velocity
end)

-- Обработка сообщений от сервера
remoteEvent.OnClientEvent:Connect(function(action, data)
	if action == "ServerSetJumpConfirm" then
		updateFeedback("JumpPower установлен на сервере: "..tostring(data))
	elseif action == "GlobalHighlightState" then
		local state = data
		globalToggled = state
		if globalToggled then
			globalBtn.BackgroundColor3 = Color3.fromRGB(200,60,60)
			globalBtn.Text = "Disable Highlight All"
		else
			globalBtn.BackgroundColor3 = Color3.fromRGB(90,90,90)
			globalBtn.Text = "Toggle Highlight All (server)"
		end
	elseif action == "ServerHitboxConfirm" then
		updateFeedback("Hitbox установлен на сервере: "..tostring(data) .. "%")
	end
end)
