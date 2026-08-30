local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local agentNames = {}
local agents = ReplicatedStorage:FindFirstChild("Agents")
if agents then
	for _, agent in ipairs(agents:GetChildren()) do
		agentNames[agent.Name] = true
	end
end

local main = ServerScriptService:FindFirstChild("Main") or ServerScriptService:WaitForChild("Main", 5)
if main then
	local spawnNPCs = main:FindFirstChild("SpawnNPCs")
	if spawnNPCs and spawnNPCs:IsA("Script") then
		spawnNPCs.Enabled = false
		print("[TheTakeCleanup] donor SpawnNPCs disabled for current gameplay baseline")
	end
end

local function removeSpawnedAgent(child: Instance)
	if child:IsA("Model") and agentNames[child.Name] then
		print("[TheTakeCleanup] removing donor NPC from menu/game baseline: " .. child.Name)
		child:Destroy()
	end
end

for _, child in ipairs(Workspace:GetChildren()) do
	removeSpawnedAgent(child)
end

Workspace.ChildAdded:Connect(function(child)
	if agentNames[child.Name] then
		task.defer(function()
			if child.Parent == Workspace then
				removeSpawnedAgent(child)
			end
		end)
	end
end)
