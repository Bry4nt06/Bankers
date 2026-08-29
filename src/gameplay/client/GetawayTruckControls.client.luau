local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local ACTION_NAME = "BankersExitGetawayTruck"
local TRUCK_NAME = "GetawayArmoredTruck"

local remotes = ReplicatedStorage:WaitForChild("BankersGameplayRemotes")
local exitRemote = remotes:WaitForChild("ExitGetawayTruck")

local humanoid: Humanoid? = nil

local function isInTruck(): boolean
	if not humanoid then
		return false
	end
	local seat = humanoid.SeatPart
	return seat ~= nil and seat:FindFirstAncestor(TRUCK_NAME) ~= nil
end

local function onExitAction(_actionName: string, inputState: Enum.UserInputState, _inputObject: InputObject)
	if inputState ~= Enum.UserInputState.Begin then
		return Enum.ContextActionResult.Pass
	end
	if not isInTruck() then
		return Enum.ContextActionResult.Pass
	end
	exitRemote:FireServer()
	return Enum.ContextActionResult.Sink
end

local function bindCharacter(character: Model)
	local found = character:WaitForChild("Humanoid", 10)
	if found and found:IsA("Humanoid") then
		humanoid = found
	end
end

if player.Character then
	task.defer(bindCharacter, player.Character)
end
player.CharacterAdded:Connect(bindCharacter)

ContextActionService:BindAction(
	ACTION_NAME,
	onExitAction,
	true,
	Enum.KeyCode.E,
	Enum.KeyCode.ButtonB
)
ContextActionService:SetTitle(ACTION_NAME, "EXIT")
ContextActionService:SetPosition(ACTION_NAME, UDim2.fromScale(0.86, 0.72))

print("[BankersTruckControls] E / gamepad B exits the getaway truck")
