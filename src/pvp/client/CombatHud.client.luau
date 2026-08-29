local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("BankersPvPRemotes")
local hitConfirm = remotes:WaitForChild("HitConfirm")
local playerGui = player:WaitForChild("PlayerGui")

local old = playerGui:FindFirstChild("BankersPvPHud")
if old then
	old:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = "BankersPvPHud"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.DisplayOrder = 200
gui.Parent = playerGui

local crosshair = Instance.new("Frame")
crosshair.Name = "Crosshair"
crosshair.AnchorPoint = Vector2.new(0.5, 0.5)
crosshair.Position = UDim2.fromScale(0.5, 0.5)
crosshair.Size = UDim2.fromOffset(36, 36)
crosshair.BackgroundTransparency = 1
crosshair.Visible = false
crosshair.Parent = gui

local function line(name: string, position: UDim2, size: UDim2)
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.Position = position
	frame.Size = size
	frame.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
	frame.BorderSizePixel = 0
	frame.Parent = crosshair
	return frame
end

line("Top", UDim2.new(0.5, -1, 0, 0), UDim2.fromOffset(2, 10))
line("Bottom", UDim2.new(0.5, -1, 1, -10), UDim2.fromOffset(2, 10))
line("Left", UDim2.new(0, 0, 0.5, -1), UDim2.fromOffset(10, 2))
line("Right", UDim2.new(1, -10, 0.5, -1), UDim2.fromOffset(10, 2))

local ammo = Instance.new("TextLabel")
ammo.Name = "Ammo"
ammo.AnchorPoint = Vector2.new(1, 1)
ammo.Position = UDim2.new(1, -34, 1, -34)
ammo.Size = UDim2.fromOffset(250, 54)
ammo.BackgroundTransparency = 1
ammo.Font = Enum.Font.GothamBold
ammo.TextColor3 = Color3.fromRGB(245, 245, 245)
ammo.TextSize = 26
ammo.TextXAlignment = Enum.TextXAlignment.Right
ammo.Text = ""
ammo.Parent = gui

local weaponName = Instance.new("TextLabel")
weaponName.Name = "WeaponName"
weaponName.AnchorPoint = Vector2.new(1, 1)
weaponName.Position = UDim2.new(1, -36, 1, -84)
weaponName.Size = UDim2.fromOffset(300, 24)
weaponName.BackgroundTransparency = 1
weaponName.Font = Enum.Font.GothamMedium
weaponName.TextColor3 = Color3.fromRGB(185, 185, 185)
weaponName.TextSize = 13
weaponName.TextXAlignment = Enum.TextXAlignment.Right
weaponName.Text = ""
weaponName.Parent = gui

local hitMarker = Instance.new("TextLabel")
hitMarker.Name = "HitMarker"
hitMarker.AnchorPoint = Vector2.new(0.5, 0.5)
hitMarker.Position = UDim2.fromScale(0.5, 0.5)
hitMarker.Size = UDim2.fromOffset(54, 54)
hitMarker.BackgroundTransparency = 1
hitMarker.Font = Enum.Font.GothamBold
hitMarker.Text = "×"
hitMarker.TextColor3 = Color3.fromRGB(255, 255, 255)
hitMarker.TextSize = 32
hitMarker.TextTransparency = 1
hitMarker.Parent = gui

local function equippedWeapon(): Tool?
	local character = player.Character
	if not character then
		return nil
	end
	for _, child in ipairs(character:GetChildren()) do
		if child:IsA("Tool") and child:GetAttribute("BankersWeapon") == true then
			return child
		end
	end
	return nil
end

RunService.RenderStepped:Connect(function()
	local tool = equippedWeapon()
	crosshair.Visible = tool ~= nil
	if not tool then
		ammo.Text = ""
		weaponName.Text = ""
		return
	end

	local current = tool:GetAttribute("Ammo")
	local reserve = tool:GetAttribute("ReserveAmmo")
	local reloading = tool:GetAttribute("Reloading") == true
	if reloading then
		ammo.Text = "RELOADING"
	else
		ammo.Text = string.format("%s / %s", tostring(current or 0), tostring(reserve or 0))
	end
	weaponName.Text = tool.Name
end)

hitConfirm.OnClientEvent:Connect(function(_, killed)
	hitMarker.TextColor3 = killed and Color3.fromRGB(255, 115, 115) or Color3.fromRGB(255, 255, 255)
	hitMarker.TextTransparency = 0
	local tween = TweenService:Create(hitMarker, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		TextTransparency = 1,
	})
	tween:Play()
end)

print("[BankersPvP] combat HUD ready")
