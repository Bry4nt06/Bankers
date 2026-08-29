local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

local MENU_GUI_NAMES = {
	BankersBootGui = true,
	BankersMenuGui = true,
	CinematicIntroGui = true,
}

local MENU_SCRIPT_NAMES = {
	BankersMenu = true,
	BankersCameraAuthority = true,
	LegacyCameraGuard = true,
	CinematicIntro = true,
}

local function removeMenuGui()
	local playerGui = player:FindFirstChild("PlayerGui")
	if not playerGui then
		return
	end

	for _, child in playerGui:GetChildren() do
		if MENU_GUI_NAMES[child.Name] then
			child:Destroy()
		end
	end
end

local function removeMenuScripts()
	local playerScripts = player:FindFirstChild("PlayerScripts")
	if not playerScripts then
		return
	end

	for _, descendant in playerScripts:GetDescendants() do
		if MENU_SCRIPT_NAMES[descendant.Name] and (descendant:IsA("LocalScript") or descendant:IsA("Script")) then
			descendant.Enabled = false
			descendant:Destroy()
		end
	end
end

local function restoreCoreGui()
	for _, coreType in ipairs({
		Enum.CoreGuiType.Backpack,
		Enum.CoreGuiType.PlayerList,
		Enum.CoreGuiType.Health,
		Enum.CoreGuiType.EmotesMenu,
		Enum.CoreGuiType.Chat,
	}) do
		pcall(function()
			StarterGui:SetCoreGuiEnabled(coreType, true)
		end)
	end
end

local function restoreCamera(character: Model?)
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end

	camera.CameraType = Enum.CameraType.Custom
	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			camera.CameraSubject = humanoid
		end
	end
end

local function sanitize()
	removeMenuGui()
	removeMenuScripts()
	restoreCoreGui()
	UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	UserInputService.MouseIconEnabled = true
	restoreCamera(player.Character)
end

sanitize()

player.CharacterAdded:Connect(function(character)
	task.defer(function()
		sanitize()
		restoreCamera(character)
	end)
end)

local playerGui = player:WaitForChild("PlayerGui")
playerGui.ChildAdded:Connect(function(child)
	if MENU_GUI_NAMES[child.Name] then
		task.defer(function()
			if child.Parent then
				child:Destroy()
			end
		end)
	end
end)

-- One delayed pass catches leftovers created a frame or two after startup.
task.delay(1, sanitize)

print("[BankersGameplay] gameplay sanitizer active; menu camera/blackout leftovers removed")
