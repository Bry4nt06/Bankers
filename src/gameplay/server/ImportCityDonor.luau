local InsertService = game:GetService("InsertService")

local ImportCityDonor = {}

local DEFAULT_CITY_ASSET_ID = 11420888914
local MODEL_NAME = "BankersCityDonor"
local GRAYBOX_NAME = "GetawayGraybox"

local function stripExecutableContent(root: Instance): number
	local removed = 0
	for _, descendant in ipairs(root:GetDescendants()) do
		if descendant:IsA("Script")
			or descendant:IsA("LocalScript")
			or descendant:IsA("ModuleScript")
			or descendant:IsA("RemoteEvent")
			or descendant:IsA("RemoteFunction")
			or descendant:IsA("BindableEvent")
			or descendant:IsA("BindableFunction") then
			descendant:Destroy()
			removed += 1
		end
	end
	return removed
end

local function freezeEnvironment(root: Instance): number
	local count = 0
	for _, descendant in ipairs(root:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.Anchored = true
			descendant.AssemblyLinearVelocity = Vector3.zero
			descendant.AssemblyAngularVelocity = Vector3.zero
			count += 1
		end
	end
	return count
end

local function centerOnGameplayArea(city: Model)
	local cityCf, citySize = city:GetBoundingBox()
	local targetCenter = Vector3.new(0, 0, 0)

	local graybox = workspace:FindFirstChild(GRAYBOX_NAME)
	if graybox and graybox:IsA("Model") then
		local routeCf = select(1, graybox:GetBoundingBox())
		targetCenter = Vector3.new(routeCf.Position.X, 0, routeCf.Position.Z)
	end

	local bottomY = cityCf.Position.Y - citySize.Y * 0.5
	local delta = Vector3.new(
		targetCenter.X - cityCf.Position.X,
		-bottomY,
		targetCenter.Z - cityCf.Position.Z
	)
	city:PivotTo(CFrame.new(delta) * city:GetPivot())
end

function ImportCityDonor.Run(assetId: number?)
	assetId = assetId or DEFAULT_CITY_ASSET_ID

	local old = workspace:FindFirstChild(MODEL_NAME)
	if old then
		old:Destroy()
	end

	print(string.format("[BankersCityImport] loading Creator Store city asset %d...", assetId))
	local ok, loadedOrError = pcall(function()
		return InsertService:LoadAsset(assetId)
	end)
	if not ok then
		error(string.format(
			"[BankersCityImport] asset %d could not be loaded: %s. If Studio reports a permission error, acquire the free model in Creator Store first, then run this command again.",
			assetId,
			tostring(loadedOrError)
		))
	end

	local loaded = loadedOrError
	if not loaded or not loaded:IsA("Model") then
		error("[BankersCityImport] InsertService did not return a Model")
	end

	loaded.Name = MODEL_NAME
	loaded:SetAttribute("BankersEnvironmentDonor", true)
	loaded:SetAttribute("SourceAssetId", assetId)

	-- Sanitize while the model is still outside Workspace, so donor scripts never
	-- get a chance to execute in the gameplay place.
	local removed = stripExecutableContent(loaded)
	local partCount = freezeEnvironment(loaded)
	if partCount == 0 then
		loaded:Destroy()
		error("[BankersCityImport] donor contained no usable BaseParts")
	end

	loaded.Parent = workspace
	centerOnGameplayArea(loaded)

	local _, size = loaded:GetBoundingBox()
	print(string.format(
		"[BankersCityImport] COMPLETE: asset %d imported as %s | %d parts | %d executable/network objects stripped | footprint %.0f x %.0f studs. Inspect the streets before saving.",
		assetId,
		MODEL_NAME,
		partCount,
		removed,
		size.X,
		size.Z
	))
	return loaded
end

return ImportCityDonor
