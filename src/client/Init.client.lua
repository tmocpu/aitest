-- Client Bootstrap
-- Initializes all client controllers and wires them to server remotes

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Modules"):WaitForChild("Config"))

local player = Players.LocalPlayer

-- Wait for remotes folder
local remotesFolder = ReplicatedStorage:WaitForChild("Remotes", 15)
if not remotesFolder then
	warn("[Client] Remotes folder not found!")
	return
end

local remotes = {
	RequestKiss = remotesFolder:WaitForChild("RequestKiss"),
	KissReaction = remotesFolder:WaitForChild("KissReaction"),
	ComboUpdate = remotesFolder:WaitForChild("ComboUpdate"),
	SuperKissEvent = remotesFolder:WaitForChild("SuperKissEvent"),
	LeaderboardUpdate = remotesFolder:WaitForChild("LeaderboardUpdate"),
	MilestoneAnnouncement = remotesFolder:WaitForChild("MilestoneAnnouncement"),
}

-- Load controllers
local Controllers = script:WaitForChild("Controllers")
local UIController = require(Controllers:WaitForChild("UIController"))
local VFXController = require(Controllers:WaitForChild("VFXController"))
local SoundController = require(Controllers:WaitForChild("SoundController"))
local LeaderboardController = require(Controllers:WaitForChild("LeaderboardController"))
local KissController = require(Controllers:WaitForChild("KissController"))

-- Initialize all controllers
print("[Client] Initializing controllers...")

SoundController:Init()
print("[Client] SoundController initialized")

VFXController:Init()
print("[Client] VFXController initialized")

UIController:Init()
print("[Client] UIController initialized")

-- LeaderboardController gets the HUD's ScreenGui
local hudGui = player:WaitForChild("PlayerGui"):WaitForChild("BrainrotHUD")
LeaderboardController:Init(hudGui)
print("[Client] LeaderboardController initialized")

-- KissController gets remotes + other controllers for immediate feedback
KissController:Init(remotes, VFXController, SoundController)
print("[Client] KissController initialized")

-- Track total kisses locally
local localKissCount = 0

-- Wire up remote events to controllers --

-- Kiss Reaction: show reaction popup + VFX
remotes.KissReaction.OnClientEvent:Connect(function(characterName, reactionType, globalCount)
	UIController:ShowReaction(characterName, reactionType, globalCount)

	localKissCount = localKissCount + 1
	UIController:UpdateKissCount(localKissCount)

	-- Coin popup at NPC position
	local npcsFolder = Workspace:FindFirstChild("NPCs")
	if npcsFolder then
		local npcModel = npcsFolder:FindFirstChild(characterName)
		if npcModel then
			local body = npcModel:FindFirstChild("Body") or npcModel.PrimaryPart
			if body then
				UIController:AddCoins(Config.BASE_KISS_COINS)
				VFXController:SpawnCoinPopup(body.Position, Config.BASE_KISS_COINS)
			end
		end
	end
end)

-- Combo Update: show combo counter + sound
remotes.ComboUpdate.OnClientEvent:Connect(function(comboCount, multiplier)
	UIController:UpdateCombo(comboCount, multiplier)
	SoundController:PlayComboTick(comboCount)

	-- Extra VFX at high combos
	if comboCount >= 5 then
		local nearest = KissController:GetNearestCharacter()
		if nearest then
			local body = nearest:FindFirstChild("Body") or nearest.PrimaryPart
			if body then
				VFXController:SpawnSparkles(body.Position)
			end
		end
	end
end)

-- Super Kiss: full screen celebration
remotes.SuperKissEvent.OnClientEvent:Connect(function(characterName, coinsAwarded)
	UIController:ShowSuperKiss(characterName, coinsAwarded)
	SoundController:PlaySuperKiss()

	-- Mega VFX at NPC
	local npcsFolder = Workspace:FindFirstChild("NPCs")
	if npcsFolder then
		local npcModel = npcsFolder:FindFirstChild(characterName)
		if npcModel then
			local body = npcModel:FindFirstChild("Body") or npcModel.PrimaryPart
			if body then
				VFXController:SpawnSuperKissVFX(body.Position)
				VFXController:SpawnCoinPopup(body.Position + Vector3.new(0, 2, 0), coinsAwarded)
			end
		end
	end

	-- Add the bonus coins to display
	UIController:AddCoins(coinsAwarded)
end)

-- Leaderboard Update: refresh leaderboard UI
remotes.LeaderboardUpdate.OnClientEvent:Connect(function(topKissers)
	LeaderboardController:UpdateEntries(topKissers)
end)

-- Milestone Announcement: banner + sound
remotes.MilestoneAnnouncement.OnClientEvent:Connect(function(characterName, milestone)
	UIController:ShowMilestone(characterName, milestone)
	SoundController:PlayMilestone()

	-- Sparkle at NPC
	local npcsFolder = Workspace:FindFirstChild("NPCs")
	if npcsFolder then
		local npcModel = npcsFolder:FindFirstChild(characterName)
		if npcModel then
			local body = npcModel:FindFirstChild("Body") or npcModel.PrimaryPart
			if body then
				VFXController:SpawnSparkles(body.Position)
			end
		end
	end
end)

print("[Client] All controllers wired up - game ready!")
