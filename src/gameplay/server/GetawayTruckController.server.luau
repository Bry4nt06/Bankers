local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local shared = ReplicatedStorage:WaitForChild("BankersGameplay")
local GetawayConfig = require(shared:WaitForChild("GetawayConfig"))

local TRUCK_NAME = GetawayConfig.TruckModelName or "GetawayArmoredTruck"
local MAX_FORWARD_SPEED = 82
local MAX_REVERSE_SPEED = 24
local ACCELERATION = 34
local COAST_DECELERATION = 18
local BRAKE_DECELERATION = 50
local MAX_YAW_RATE = math.rad(52)
local MIN_STEER_SPEED = 5
local DAMAGE_EVENT_NAME = "DamageGetawayTruck"

local runtime = ReplicatedStorage:FindFirstChild("BankersGetawayRuntime")

local serverEvents = game:GetService("ServerStorage"):FindFirstChild("BankersGameplayEvents")
if not serverEvents then
	serverEvents = Instance.new("Folder")
	serverEvents.Name = "BankersGameplayEvents"
	serverEvents.Parent = game:GetService("ServerStorage")
end

local damageEvent = serverEvents:FindFirstChild(DAMAGE_EVENT_NAME)
if not damageEvent then
	damageEvent = Instance.new("BindableEvent")
	damageEvent.Name = DAMAGE_EVENT_NAME
	damageEvent.Parent = serverEvents
end

local truck: Model? = nil
local chassis: BasePart? = nil
local driverSeat: VehicleSeat? = nil
local spawnCFrame: CFrame? = nil
local currentForwardSpeed = 0
local heartbeatConnection: RBXScriptConnection? = nil

local function approach(current: number, target: number, maxDelta: number): number
	if current < target then
		return math.min(current + maxDelta, target)
	elseif current > target then
		return math.max(current - maxDelta, target)
	end
	return current
end

local function currentDriverPlayer(): Player?
	if not driverSeat or not driverSeat.Occupant then
		return nil
	end
	local character = driverSeat.Occupant.Parent
	if not character then
		return nil
	end
	return Players:GetPlayerFromCharacter(character)
end

local function updateNetworkOwner()
	if not chassis then
		return
	end
	-- Keep motion server authoritative during the PvE chase so checkpoint and
	-- police-AI interactions see one canonical truck state.
	pcall(function()
		chassis:SetNetworkOwner(nil)
	end)
end

local function resetTruck(reason: string?)
	if not truck or not chassis or not spawnCFrame then
		return
	end
	truck:PivotTo(spawnCFrame)
	chassis.AssemblyLinearVelocity = Vector3.zero
	chassis.AssemblyAngularVelocity = Vector3.zero
	currentForwardSpeed = 0
	truck:SetAttribute("Health", truck:GetAttribute("MaxHealth") or 1000)
	truck:SetAttribute("Destroyed", false)
	truck:SetAttribute("LastResetReason", reason or "reset")
	updateNetworkOwner()
	print(string.format("[BankersTruck] reset (%s)", reason or "reset"))
end

local function bindTruck(model: Model)
	if heartbeatConnection then
		heartbeatConnection:Disconnect()
		heartbeatConnection = nil
	end

	truck = model
	chassis = model:FindFirstChild("Chassis") :: BasePart?
	driverSeat = model:FindFirstChild("DriverSeat") :: VehicleSeat?
	if not chassis or not chassis:IsA("BasePart") or not driverSeat or not driverSeat:IsA("VehicleSeat") then
		warn("[BankersTruck] truck is missing Chassis or DriverSeat; rebake BuildGetawayTruck")
		return
	end

	spawnCFrame = model:GetPivot()
	currentForwardSpeed = 0
	updateNetworkOwner()

	driverSeat:GetPropertyChangedSignal("Occupant"):Connect(function()
		local driver = currentDriverPlayer()
		model:SetAttribute("DriverUserId", driver and driver.UserId or 0)
		updateNetworkOwner()
	end)

	heartbeatConnection = RunService.Heartbeat:Connect(function(dt)
		if not truck or not chassis or not driverSeat or truck:GetAttribute("Destroyed") == true then
			return
		end

		local throttle = driverSeat.ThrottleFloat
		local steer = driverSeat.SteerFloat
		local targetSpeed
		if throttle > 0.05 then
			targetSpeed = throttle * MAX_FORWARD_SPEED
		elseif throttle < -0.05 then
			targetSpeed = throttle * MAX_REVERSE_SPEED
		else
			targetSpeed = 0
		end

		local accelRate = ACCELERATION
		if math.abs(throttle) <= 0.05 then
			accelRate = COAST_DECELERATION
		elseif currentForwardSpeed * targetSpeed < 0 then
			accelRate = BRAKE_DECELERATION
		end
		currentForwardSpeed = approach(currentForwardSpeed, targetSpeed, accelRate * dt)

		local forward = chassis.CFrame.LookVector
		local existing = chassis.AssemblyLinearVelocity
		local horizontal = forward * currentForwardSpeed
		chassis.AssemblyLinearVelocity = Vector3.new(horizontal.X, existing.Y, horizontal.Z)

		local speedFactor = math.clamp(math.abs(currentForwardSpeed) / MAX_FORWARD_SPEED, 0, 1)
		local steerAuthority = math.clamp(speedFactor * 1.35, 0, 1)
		if math.abs(currentForwardSpeed) < MIN_STEER_SPEED then
			steerAuthority = 0
		end
		local directionSign = currentForwardSpeed >= 0 and 1 or -1
		chassis.AssemblyAngularVelocity = Vector3.new(0, -steer * MAX_YAW_RATE * steerAuthority * directionSign, 0)

		model:SetAttribute("Speed", math.abs(currentForwardSpeed))
	end)

	print("[BankersTruck] armored getaway truck controller active")
end

damageEvent.Event:Connect(function(amount, source)
	if not truck or truck:GetAttribute("Destroyed") == true then
		return
	end
	if type(amount) ~= "number" or amount <= 0 then
		return
	end
	local maxHealth = truck:GetAttribute("MaxHealth") or 1000
	local health = truck:GetAttribute("Health") or maxHealth
	health = math.max(0, health - amount)
	truck:SetAttribute("Health", health)
	truck:SetAttribute("LastDamageSource", type(source) == "string" and source or "unknown")
	if health <= 0 then
		truck:SetAttribute("Destroyed", true)
		if chassis then
			chassis.AssemblyLinearVelocity *= 0.25
			chassis.AssemblyAngularVelocity = Vector3.zero
		end
		warn("[BankersTruck] truck disabled")
	end
end)

if runtime then
	runtime:GetAttributeChangedSignal("Phase"):Connect(function()
		if runtime:GetAttribute("Phase") == "Ready" and truck then
			resetTruck("mission ready")
		end
	end)
end

local existing = workspace:FindFirstChild(TRUCK_NAME)
if existing and existing:IsA("Model") then
	bindTruck(existing)
else
	warn("[BankersTruck] GetawayArmoredTruck not found. Bake it in Edit mode with BuildGetawayTruck.Run().")
end

workspace.ChildAdded:Connect(function(child)
	if child.Name == TRUCK_NAME and child:IsA("Model") then
		task.defer(bindTruck, child)
	end
end)
