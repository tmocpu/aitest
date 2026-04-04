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
local AnimationController = require(Controllers:WaitForChild("AnimationController"))

-- Initialize all controllers
print("[Client] Initializing controllers...")

SoundController:Init()
print("[Client] SoundController initialized")

VFXController:Init()
print("[Client] VFXController initialized")

UIController:Init()
UIController:Start()
print("[Client] UIController initialized")

-- LeaderboardController gets the HUD's ScreenGui
local hudGui = UIController:GetScreenGui()
LeaderboardController:Init(hudGui)
print("[Client] LeaderboardController initialized")

AnimationController:Init()
print("[Client] AnimationController initialized")

-- KissController gets remotes + other controllers for immediate feedback
KissController:Init(remotes, VFXController, SoundController)
print("[Client] KissController initialized")

-- Track total kisses locally
local localKissCount = 0

-- Wire up remote events to controllers --

-- Kiss Reaction: show reaction popup + VFX + NPC animation + coins
remotes.KissReaction.OnClientEvent:Connect(function(characterName, reactionType, globalCount)
	AnimationController:OnKissReaction(characterName, reactionType, globalCount)

	localKissCount = localKissCount + 1
	UIController:AddCoins(Config.BASE_KISS_COINS)

	-- Screen-space kiss popup + 3D coin VFX at NPC position
	local npcsFolder = Workspace:FindFirstChild("NPCs")
	if npcsFolder then
		local npcModel = npcsFolder:FindFirstChild(characterName)
		if npcModel then
			local body = npcModel:FindFirstChild("Body") or npcModel.PrimaryPart
			if body then
				UIController:SpawnKissPopup(body.Position, Config.BASE_KISS_COINS, false)
				VFXController:SpawnCoinPopup(body.Position, Config.BASE_KISS_COINS)
			end
		end
	end
end)

-- Combo Update: combo display + banner + sound + camera shake
remotes.ComboUpdate.OnClientEvent:Connect(function(comboCount, multiplier)
	UIController:SetCombo(comboCount)
	UIController:ShowComboBanner(comboCount)
	SoundController:PlayComboTick(comboCount)
	AnimationController:OnComboUpdate(comboCount, multiplier)

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

-- Super Kiss: celebration + flash + camera shake
remotes.SuperKissEvent.OnClientEvent:Connect(function(characterName, coinsAwarded)
	SoundController:PlaySuperKiss()
	AnimationController:OnSuperKissEvent(characterName, coinsAwarded)
	UIController:AddCoins(coinsAwarded)

	-- Screen-space super kiss popup + 3D VFX at NPC
	local npcsFolder = Workspace:FindFirstChild("NPCs")
	if npcsFolder then
		local npcModel = npcsFolder:FindFirstChild(characterName)
		if npcModel then
			local body = npcModel:FindFirstChild("Body") or npcModel.PrimaryPart
			if body then
				UIController:SpawnKissPopup(body.Position, coinsAwarded, true)
				VFXController:SpawnSuperKissVFX(body.Position)
				VFXController:SpawnCoinPopup(body.Position + Vector3.new(0, 2, 0), coinsAwarded)
			end
		end
	end
end)

-- Leaderboard Update: refresh leaderboard panel
remotes.LeaderboardUpdate.OnClientEvent:Connect(function(topKissers)
	LeaderboardController:UpdateEntries(topKissers)
	UIController:UpdateLeaderboard(topKissers)
end)

-- Milestone Announcement: banner + sound + NPC animation
remotes.MilestoneAnnouncement.OnClientEvent:Connect(function(characterName, milestone)
	UIController:ShowMilestone(characterName, milestone)
	SoundController:PlayMilestone()
	AnimationController:OnMilestoneAnnouncement(characterName, milestone)

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
