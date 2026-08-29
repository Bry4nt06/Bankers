local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local SKIN_NAME = "BankersBrokenMenuSkin"
local SEARCH_TIMEOUT = 20

local function normalize(value: string): string
	return string.lower((value:gsub("%s+", "")))
end

local function buttonScore(button: GuiButton): number
	local score = 0
	local name = normalize(button.Name)
	if name == "play" or name == "playbutton" or name == "start" or name == "startbutton" then
		score += 10
	elseif string.find(name, "play", 1, true) or string.find(name, "start", 1, true) then
		score += 5
	end

	if button:IsA("TextButton") then
		local text = normalize(button.Text)
		if text == "play" or text == "start" then
			score += 12
		elseif string.find(text, "play", 1, true) or string.find(text, "start", 1, true) then
			score += 6
		end
	end

	return score
end

local function findBrokenPlayButton(): GuiButton?
	local bestButton = nil
	local bestScore = 0

	for _, descendant in ipairs(playerGui:GetDescendants()) do
		if descendant:IsA("GuiButton") then
			local screenGui = descendant:FindFirstAncestorOfClass("ScreenGui")
			if screenGui then
				local score = buttonScore(descendant)
				if score > bestScore then
					bestScore = score
					bestButton = descendant
				end
			end
		end
	end

	if bestScore < 10 then
		return nil
	end
	return bestButton
end

local function findWithTimeout(): GuiButton?
	local deadline = os.clock() + SEARCH_TIMEOUT
	repeat
		local button = findBrokenPlayButton()
		if button then
			return button
		end
		task.wait(0.1)
	until os.clock() >= deadline
	return nil
end

local function addGradient(frame: Frame)
	local gradient = Instance.new("UIGradient")
	gradient.Rotation = 0
	gradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.04),
		NumberSequenceKeypoint.new(0.68, 0.58),
		NumberSequenceKeypoint.new(1, 1),
	})
	gradient.Parent = frame
end

local function createSkin(screenGui: ScreenGui, playButton: GuiButton)
	local old = screenGui:FindFirstChild(SKIN_NAME)
	if old then
		old:Destroy()
	end

	-- Keep Broken's real PLAY button instance so all of its existing event
	-- connections and round/loadout initialization continue to work.
	playButton.Parent = screenGui
	playButton.AnchorPoint = Vector2.new(0, 0.5)
	playButton.Position = UDim2.fromScale(0.065, 0.79)
	playButton.Size = UDim2.fromOffset(190, 50)
	playButton.AutoButtonColor = false
	playButton.BackgroundTransparency = 1
	playButton.ZIndex = 1002

	if playButton:IsA("TextButton") then
		playButton.Text = "PLAY"
		playButton.Font = Enum.Font.GothamMedium
		playButton.TextColor3 = Color3.fromRGB(245, 245, 245)
		playButton.TextSize = 22
		playButton.TextXAlignment = Enum.TextXAlignment.Left
		playButton.TextTransparency = 0
	end

	-- Hide the rest of Broken's starter-menu visuals without touching other
	-- ScreenGuis such as the combat/round HUD.
	for _, child in ipairs(screenGui:GetChildren()) do
		if child ~= playButton and child.Name ~= SKIN_NAME and child:IsA("GuiObject") then
			child.Visible = false
		end
	end

	screenGui.DisplayOrder = math.max(screenGui.DisplayOrder, 1500)
	screenGui.IgnoreGuiInset = true

	local skin = Instance.new("Frame")
	skin.Name = SKIN_NAME
	skin.Size = UDim2.fromScale(1, 1)
	skin.BackgroundTransparency = 1
	skin.BorderSizePixel = 0
	skin.ZIndex = 900
	skin.Parent = screenGui

	local topBar = Instance.new("Frame")
	topBar.Size = UDim2.fromScale(1, 0.055)
	topBar.BackgroundColor3 = Color3.new(0, 0, 0)
	topBar.BorderSizePixel = 0
	topBar.ZIndex = 910
	topBar.Parent = skin

	local bottomBar = topBar:Clone()
	bottomBar.Position = UDim2.fromScale(0, 0.945)
	bottomBar.Parent = skin

	local shade = Instance.new("Frame")
	shade.Size = UDim2.fromScale(0.42, 1)
	shade.BackgroundColor3 = Color3.new(0, 0, 0)
	shade.BackgroundTransparency = 0.22
	shade.BorderSizePixel = 0
	shade.ZIndex = 905
	shade.Parent = skin
	addGradient(shade)

	local menuFrame = Instance.new("Frame")
	menuFrame.AnchorPoint = Vector2.new(0, 0.5)
	menuFrame.Position = UDim2.fromScale(0.065, 0.69)
	menuFrame.Size = UDim2.fromOffset(360, 150)
	menuFrame.BackgroundTransparency = 1
	menuFrame.ZIndex = 920
	menuFrame.Parent = skin

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 66)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBlack
	title.Text = "BANKERS"
	title.TextColor3 = Color3.fromRGB(245, 245, 245)
	title.TextSize = 46
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextTransparency = 1
	title.ZIndex = 930
	title.Parent = menuFrame

	local rule = Instance.new("Frame")
	rule.Position = UDim2.fromOffset(0, 72)
	rule.Size = UDim2.fromOffset(0, 2)
	rule.BackgroundColor3 = Color3.fromRGB(235, 235, 235)
	rule.BackgroundTransparency = 0.18
	rule.BorderSizePixel = 0
	rule.ZIndex = 930
	rule.Parent = menuFrame

	local accent = Instance.new("Frame")
	accent.Name = "BankersAccent"
	accent.AnchorPoint = Vector2.new(0, 0.5)
	accent.Position = UDim2.new(0, -16, 0.5, 0)
	accent.Size = UDim2.fromOffset(3, 0)
	accent.BackgroundColor3 = Color3.fromRGB(245, 245, 245)
	accent.BorderSizePixel = 0
	accent.ZIndex = 1003
	accent.Parent = playButton

	TweenService:Create(title, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		TextTransparency = 0,
	}):Play()
	TweenService:Create(rule, TweenInfo.new(0.55, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
		Size = UDim2.fromOffset(132, 2),
	}):Play()

	playButton.MouseEnter:Connect(function()
		TweenService:Create(accent, TweenInfo.new(0.16, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
			Size = UDim2.fromOffset(3, 32),
		}):Play()
	end)

	playButton.MouseLeave:Connect(function()
		TweenService:Create(accent, TweenInfo.new(0.16, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
			Size = UDim2.fromOffset(3, 0),
		}):Play()
	end)

	print(string.format(
		"[BankersBrokenOverlay] replaced Broken starter visuals using existing PLAY button %s.%s",
		screenGui.Name,
		playButton.Name
	))
end

local playButton = findWithTimeout()
if not playButton then
	warn("[BankersBrokenOverlay] could not identify Broken's PLAY button; starter UI was left untouched")
	return
end

local screenGui = playButton:FindFirstAncestorOfClass("ScreenGui")
if not screenGui then
	warn("[BankersBrokenOverlay] PLAY button has no ScreenGui ancestor")
	return
end

createSkin(screenGui, playButton)
