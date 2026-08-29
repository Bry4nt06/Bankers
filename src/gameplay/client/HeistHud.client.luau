local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local runtime = ReplicatedStorage:WaitForChild("BankersHeistRuntime")

local playerGui = player:WaitForChild("PlayerGui")
local old = playerGui:FindFirstChild("BankersHeistHud")
if old then
	old:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = "BankersHeistHud"
gui.IgnoreGuiInset = false
gui.ResetOnSpawn = false
gui.DisplayOrder = 200
gui.Parent = playerGui

local panel = Instance.new("Frame")
panel.Name = "ObjectivePanel"
panel.Position = UDim2.fromOffset(28, 28)
panel.Size = UDim2.fromOffset(520, 118)
panel.BackgroundColor3 = Color3.fromRGB(8, 9, 11)
panel.BackgroundTransparency = 0.18
panel.BorderSizePixel = 0
panel.Parent = gui

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(220, 220, 220)
stroke.Transparency = 0.78
stroke.Thickness = 1
stroke.Parent = panel

local phase = Instance.new("TextLabel")
phase.Name = "Phase"
phase.Position = UDim2.fromOffset(18, 14)
phase.Size = UDim2.new(1, -36, 0, 22)
phase.BackgroundTransparency = 1
phase.Font = Enum.Font.GothamBold
phase.TextColor3 = Color3.fromRGB(235, 235, 235)
phase.TextSize = 15
phase.TextXAlignment = Enum.TextXAlignment.Left
phase.Text = "BANKERS"
phase.Parent = panel

local objective = Instance.new("TextLabel")
objective.Name = "Objective"
objective.Position = UDim2.fromOffset(18, 40)
objective.Size = UDim2.new(1, -36, 0, 48)
objective.BackgroundTransparency = 1
objective.Font = Enum.Font.GothamMedium
objective.TextColor3 = Color3.fromRGB(255, 255, 255)
objective.TextSize = 22
objective.TextWrapped = true
objective.TextXAlignment = Enum.TextXAlignment.Left
objective.TextYAlignment = Enum.TextYAlignment.Top
objective.Text = "Waiting for heist state"
objective.Parent = panel

local status = Instance.new("TextLabel")
status.Name = "Status"
status.Position = UDim2.fromOffset(18, 90)
status.Size = UDim2.new(1, -36, 0, 18)
status.BackgroundTransparency = 1
status.Font = Enum.Font.Gotham
status.TextColor3 = Color3.fromRGB(185, 185, 185)
status.TextSize = 13
status.TextXAlignment = Enum.TextXAlignment.Left
status.Text = "CO-OP PvE"
status.Parent = panel

local function updateText()
	phase.Text = tostring(runtime:GetAttribute("PhaseDisplayName") or runtime:GetAttribute("Phase") or "BANKERS")
	objective.Text = tostring(runtime:GetAttribute("Objective") or "")
end

for _, attributeName in {"Phase", "PhaseDisplayName", "Objective"} do
	runtime:GetAttributeChangedSignal(attributeName):Connect(updateText)
end

RunService.RenderStepped:Connect(function()
	if runtime:GetAttribute("Phase") ~= "Lobby" then
		status.Text = "CO-OP PvE  •  CREW"
		return
	end

	local endsAt = runtime:GetAttribute("LobbyCountdownEndsAt")
	if type(endsAt) == "number" and endsAt > 0 then
		local remaining = math.max(0, math.ceil(endsAt - workspace:GetServerTimeNow()))
		status.Text = string.format("CO-OP PvE  •  DEPLOYING IN %d", remaining)
	else
		status.Text = "CO-OP PvE  •  WAITING FOR CREW"
	end
end)

updateText()
print("[BankersGameplay] objective HUD ready")
