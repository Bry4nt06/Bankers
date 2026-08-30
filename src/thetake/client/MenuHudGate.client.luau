local Players = game:GetService("Players")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local STARTED_ATTRIBUTE = "TheTakeGameplayStarted"
local TAKE_GUI_NAMES = {
	TheTakeBootGui = true,
	TheTakeMenuGui = true,
	-- Studio-only Vault fitting controls are part of THE TAKE frontend and must
	-- remain visible while donor gameplay HUDs are suppressed.
	TheTakeVaultFitGui = true,
}

local savedEnabled = setmetatable({}, { __mode = "k" })

local function isTakeGui(gui: Instance): boolean
	return TAKE_GUI_NAMES[gui.Name] == true
end

local function gateScreenGui(gui: ScreenGui)
	if isTakeGui(gui) then
		gui.Enabled = true
		return
	end

	if savedEnabled[gui] == nil then
		savedEnabled[gui] = gui.Enabled
	end

	if player:GetAttribute(STARTED_ATTRIBUTE) == true then
		local previous = savedEnabled[gui]
		if previous ~= nil then
			gui.Enabled = previous
		end
	else
		gui.Enabled = false
	end
end

local function applyGate()
	for _, child in ipairs(playerGui:GetChildren()) do
		if child:IsA("ScreenGui") then
			gateScreenGui(child)
		end
	end
end

playerGui.ChildAdded:Connect(function(child)
	if child:IsA("ScreenGui") then
		task.defer(gateScreenGui, child)
	end
end)

player:GetAttributeChangedSignal(STARTED_ATTRIBUTE):Connect(function()
	applyGate()
	if player:GetAttribute(STARTED_ATTRIBUTE) == true then
		print("[TheTakeMenu] donor gameplay HUD restored after PLAY")
	else
		print("[TheTakeMenu] donor gameplay HUD hidden for cinematic menu")
	end
end)

applyGate()
print("[TheTakeMenu] menu HUD gate active")
