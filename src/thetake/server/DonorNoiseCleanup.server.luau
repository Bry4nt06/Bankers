local ServerScriptService = game:GetService("ServerScriptService")

local removedSounds = 0

local function removeSound(instance: Instance)
	if instance:IsA("Sound") then
		removedSounds += 1
		instance:Destroy()
	end
end

-- Audio is intentionally stripped for the current cleanup pass. We can add
-- owned/authorized THE TAKE audio back later after the gameplay foundation is
-- stable and the Output is clean.
for _, descendant in ipairs(game:GetDescendants()) do
	removeSound(descendant)
end

game.DescendantAdded:Connect(function(descendant)
	if descendant:IsA("Sound") then
		task.defer(function()
			if descendant.Parent then
				descendant:Destroy()
			end
		end)
	end
end)

local audioScript = workspace:FindFirstChild("AudioScript")
if audioScript and (audioScript:IsA("Script") or audioScript:IsA("LocalScript")) then
	audioScript.Enabled = false
end

local main = ServerScriptService:FindFirstChild("Main")
if main then
	for _, scriptName in ipairs({"Inventory", "TimePlayed"}) do
		local donorScript = main:FindFirstChild(scriptName)
		if donorScript and donorScript:IsA("Script") then
			donorScript.Enabled = false
		end
	end
end

print(string.format("[TheTakeCleanup] donor audio stripped for cleanup pass (%d sounds removed)", removedSounds))
