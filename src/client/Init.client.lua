-- Client Bootstrap
-- Initializes client-side controllers and connects to server remotes

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Modules"):WaitForChild("Config"))

local player = Players.LocalPlayer

-- Wait for remotes folder to be created by server
local remotesFolder = ReplicatedStorage:WaitForChild("Remotes", 10)
if not remotesFolder then
	warn("[Client] Remotes folder not found!")
	return
end

-- Get remotes
local RequestKiss = remotesFolder:WaitForChild("RequestKiss")
local KissReaction = remotesFolder:WaitForChild("KissReaction")
local ComboUpdate = remotesFolder:WaitForChild("ComboUpdate")
local SuperKissEvent = remotesFolder:WaitForChild("SuperKissEvent")
local LeaderboardUpdate = remotesFolder:WaitForChild("LeaderboardUpdate")
local MilestoneAnnouncement = remotesFolder:WaitForChild("MilestoneAnnouncement")

-- Controllers (loaded from Controllers folder if present)
local Controllers = script:FindFirstChild("Controllers")

-- Kiss Reaction Handler
KissReaction.OnClientEvent:Connect(function(characterName, reactionType, globalCount)
	if Config.DEBUG_MODE then
		print(string.format("[Client] %s: %s (Global: %d)", characterName, reactionType, globalCount))
	end
	-- UI controllers would display the reaction here
end)

-- Combo Update Handler
ComboUpdate.OnClientEvent:Connect(function(comboCount, multiplier)
	if Config.DEBUG_MODE then
		print(string.format("[Client] Combo: %d (x%d)", comboCount, multiplier))
	end
	-- UI controllers would update combo display here
end)

-- Super Kiss Event Handler
SuperKissEvent.OnClientEvent:Connect(function(characterName, coinsAwarded)
	if Config.DEBUG_MODE then
		print(string.format("[Client] SUPER KISS on %s! +%d coins!", characterName, coinsAwarded))
	end
	-- UI controllers would show super kiss VFX here
end)

-- Leaderboard Update Handler
LeaderboardUpdate.OnClientEvent:Connect(function(topKissers)
	if Config.DEBUG_MODE then
		print("[Client] Leaderboard updated with " .. #topKissers .. " entries")
	end
	-- UI controllers would refresh leaderboard display here
end)

-- Milestone Announcement Handler
MilestoneAnnouncement.OnClientEvent:Connect(function(characterName, milestone)
	if Config.DEBUG_MODE then
		print(string.format("[Client] MILESTONE: %s has been kissed %d times!", characterName, milestone))
	end
	-- UI controllers would show milestone announcement here
end)

-- Public function for UI to call when kiss button is pressed
local ClientKiss = {}

function ClientKiss.RequestKiss(characterName)
	RequestKiss:FireServer(characterName)
end

-- Load controllers if they exist
if Controllers then
	for _, controller in ipairs(Controllers:GetChildren()) do
		if controller:IsA("ModuleScript") then
			local ok, mod = pcall(require, controller)
			if ok and type(mod) == "table" and mod.Init then
				mod:Init(ClientKiss)
			end
		end
	end
end

print("[Client] Initialized successfully!")

return ClientKiss
