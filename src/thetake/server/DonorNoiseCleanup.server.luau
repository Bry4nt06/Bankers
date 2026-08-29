local ServerScriptService = game:GetService("ServerScriptService")

local silencedSounds = 0

local function silenceSound(instance: Instance)
	if not instance:IsA("Sound") then
		return
	end

	pcall(function()
		instance:Stop()
	end)
	instance.SoundId = ""
	instance.Volume = 0
	instance.Looped = false
	silencedSounds += 1
end

-- Audio is intentionally muted for the current cleanup pass. We keep the Sound
-- instances themselves so donor weapon scripts that call Sound:Play() do not
-- lose their expected object references.
for _, descendant in ipairs(game:GetDescendants()) do
	silenceSound(descendant)
end

game.DescendantAdded:Connect(function(descendant)
	if descendant:IsA("Sound") then
		task.defer(function()
			if descendant.Parent then
				silenceSound(descendant)
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

print(string.format("[TheTakeCleanup] donor audio muted for cleanup pass (%d sounds silenced)", silencedSounds))
