local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local runtime = ReplicatedStorage:WaitForChild("BankersGetawayRuntime")
local playerGui = player:WaitForChild("PlayerGui")

local old = playerGui:FindFirstChild("BankersGetawayHud")
if old then
	old:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = "BankersGetawayHud"
gui.IgnoreGuiInset = false
gui.ResetOnSpawn = false
gui.DisplayOrder = 200
gui.Parent = playerGui

local panel = Instance.new("Frame")
panel.Name = "ObjectivePanel"
panel.Position = UDim2.fromOffset(28, 28)
panel.Size = UDim2.fromOffset(550, 128)
panel.BackgroundColor3 = Color3.fromRGB(8, 9, 11)
panel.BackgroundTransparency = 0.16
panel.BorderSizePixel = 0
panel.Parent = gui

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(220, 220, 220)
stroke.Transparency = 0.78
stroke.Thickness = 1
stroke.Parent = panel

local phase = Instance.new("TextLabel")
phase.Position = UDim2.fromOffset(18, 14)
phase.Size = UDim2.new(1, -36, 0, 22)
phase.BackgroundTransparency = 1
phase.Font = Enum.Font.GothamBold
phase.TextColor3 = Color3.fromRGB(235, 235, 235)
phase.TextSize = 15
phase.TextXAlignment = Enum.TextXAlignment.Left
phase.Text = "BANKERS // GETAWAY"
phase.Parent = panel

local objective = Instance.new("TextLabel")
objective.Position = UDim2.fromOffset(18, 40)
objective.Size = UDim2.new(1, -36, 0, 48)
objective.BackgroundTransparency = 1
objective.Font = Enum.Font.GothamMedium
objective.TextColor3 = Color3.fromRGB(255, 255, 255)
objective.TextSize = 22
objective.TextWrapped = true
objective.TextXAlignment = Enum.TextXAlignment.Left
objective.TextYAlignment = Enum.TextYAlignment.Top
objective.Text = "Waiting for getaway state"
objective.Parent = panel

local status = Instance.new("TextLabel")
status.Position = UDim2.fromOffset(18, 96)
status.Size = UDim2.new(1, -36, 0, 18)
status.BackgroundTransparency = 1
status.Font = Enum.Font.Gotham
status.TextColor3 = Color3.fromRGB(185, 185, 185)
status.TextSize = 13
status.TextXAlignment = Enum.TextXAlignment.Left
status.Text = "CO-OP PvE"
status.Parent = panel

local function updateText()
	phase.Text = tostring(runtime:GetAttribute("PhaseDisplayName") or runtime:GetAttribute("Phase") or "BANKERS // GETAWAY")
	objective.Text = tostring(runtime:GetAttribute("Objective") or "")
end

for _, attributeName in {"Phase", "PhaseDisplayName", "Objective"} do
	runtime:GetAttributeChangedSignal(attributeName):Connect(updateText)
end

RunService.RenderStepped:Connect(function()
	local phaseName = runtime:GetAttribute("Phase")
	local checkpoint = runtime:GetAttribute("CurrentCheckpoint")
	checkpoint = type(checkpoint) == "number" and checkpoint or 0

	if phaseName == "Ready" then
		local endsAt = runtime:GetAttribute("LobbyCountdownEndsAt")
		if type(endsAt) == "number" and endsAt > 0 then
			local remaining = math.max(0, math.ceil(endsAt - workspace:GetServerTimeNow()))
			status.Text = string.format("CO-OP PvE  •  GETAWAY IN %d", remaining)
		else
			status.Text = "CO-OP PvE  •  WAITING FOR CREW"
		end
	elseif phaseName == "Results" then
		status.Text = string.format("ESCAPED  •  CHECKPOINTS %d/8", checkpoint)
	else
		status.Text = string.format("CREW  •  ROUTE %d/8  •  POLICE RESPONSE ACTIVE", checkpoint)
	end
end)

updateText()
print("[BankersGetaway] getaway HUD ready")
