local PrepareCityEnvironment = {}

local FINAL_MODEL_NAME = "BankersCityEnvironment"

local function resolveModel(modelOrName: any): Model
	if typeof(modelOrName) == "Instance" then
		if modelOrName:IsA("Model") then
			return modelOrName
		end
		error("[BankersCityPrep] supplied Instance must be a Model")
	end

	if type(modelOrName) == "string" then
		local candidate = workspace:FindFirstChild(modelOrName)
		if candidate and candidate:IsA("Model") then
			return candidate
		end
		error(string.format("[BankersCityPrep] Workspace model '%s' was not found", modelOrName))
	end

	local commonNames = {
		"CITY MAP",
		"City Map",
		"CityMap",
		"City",
	}
	for _, name in ipairs(commonNames) do
		local candidate = workspace:FindFirstChild(name)
		if candidate and candidate:IsA("Model") then
			return candidate
		end
	end

	error("[BankersCityPrep] pass the inserted city Model or its exact Workspace name, for example: PrepareCityEnvironment.Run(workspace[\"CITY MAP\"])")
end

local function shouldStrip(instance: Instance): boolean
	return instance:IsA("Script")
		or instance:IsA("LocalScript")
		or instance:IsA("ModuleScript")
		or instance:IsA("RemoteEvent")
		or instance:IsA("RemoteFunction")
		or instance:IsA("BindableEvent")
		or instance:IsA("BindableFunction")
		or instance:IsA("Seat")
		or instance:IsA("VehicleSeat")
		or instance:IsA("Sound")
		or instance:IsA("BodyMover")
		or instance:IsA("Constraint")
		or instance:IsA("JointInstance")
end

local function sanitize(root: Model): (number, number)
	local removed = 0
	local parts = 0

	for _, descendant in ipairs(root:GetDescendants()) do
		if shouldStrip(descendant) then
			descendant:Destroy()
			removed += 1
		elseif descendant:IsA("BasePart") then
			descendant.Anchored = true
			descendant.AssemblyLinearVelocity = Vector3.zero
			descendant.AssemblyAngularVelocity = Vector3.zero
			parts += 1
		end
	end

	return removed, parts
end

function PrepareCityEnvironment.Run(modelOrName: any?)
	local source = resolveModel(modelOrName)
	if source.Name == "GetawayGraybox" or source.Name == "GetawayArmoredTruck" then
		error("[BankersCityPrep] refusing to sanitize a Bankers gameplay model")
	end

	local existing = workspace:FindFirstChild(FINAL_MODEL_NAME)
	if existing and existing ~= source then
		existing:Destroy()
	end

	local removed, parts = sanitize(source)
	if parts == 0 then
		error("[BankersCityPrep] selected donor contains no usable BaseParts")
	end

	source.Name = FINAL_MODEL_NAME
	source:SetAttribute("BankersEnvironment", true)
	source:SetAttribute("Sanitized", true)
	source:SetAttribute("RemovedDonorObjects", removed)
	source:SetAttribute("EnvironmentPartCount", parts)

	local _, size = source:GetBoundingBox()
	print(string.format(
		"[BankersCityPrep] COMPLETE: %s | %d static parts | %d scripts/network/physics/audio objects stripped | footprint %.0f x %.0f studs. Press Ctrl+S, then send a top-down screenshot so the chase route can be rebuilt through the real streets.",
		FINAL_MODEL_NAME,
		parts,
		removed,
		size.X,
		size.Z
	))

	return source
end

return PrepareCityEnvironment
