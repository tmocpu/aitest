-- Client Bootstrap — Kiss the Brainrot
-- Loads all controllers, wires all remotes with pcall safety

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Modules"):WaitForChild("Config"))

local player = Players.LocalPlayer

-- Wait for remotes
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
	CoinsUpdate = remotesFolder:WaitForChild("CoinsUpdate"),
}

-- Load controllers
local Controllers = script:WaitForChild("Controllers")
local UIController = require(Controllers:WaitForChild("UIController"))
local VFXController = require(Controllers:WaitForChild("VFXController"))
local SoundController = require(Controllers:WaitForChild("SoundController"))
local LeaderboardController = require(Controllers:WaitForChild("LeaderboardController"))
local KissController = require(Controllers:WaitForChild("KissController"))
local AnimationController = require(Controllers:WaitForChild("AnimationController"))

print("====================================")
print("  KISS THE BRAINROT - CLIENT START")
print("====================================")

-- Init controllers in order
SoundController:Init()
print("  [+] SoundController")

VFXController:Init()
print("  [+] VFXController")

UIController:Init()
UIController:Start()
print("  [+] UIController")

local hudGui = UIController:GetScreenGui()
LeaderboardController:Init(hudGui)
print("  [+] LeaderboardController")

AnimationController:Init()
print("  [+] AnimationController")

KissController:Init(remotes, VFXController, SoundController)
print("  [+] KissController")

-- Helper: find NPC body part by name
local function findNPCBody(characterName)
	local npcsFolder = Workspace:FindFirstChild("NPCs")
	if not npcsFolder then return nil end
	local npcModel = npcsFolder:FindFirstChild(characterName)
	if not npcModel then return nil end
	return npcModel:FindFirstChild("Body") or npcModel.PrimaryPart
end

---------------------------------------------------------------------------
-- Wire remote events (all wrapped in pcall)
---------------------------------------------------------------------------

-- CoinsUpdate: server sends starting coins on join
remotes.CoinsUpdate.OnClientEvent:Connect(function(startingCoins)
	pcall(function()
		UIController:AddCoins(startingCoins)
	end)
end)

-- KissReaction: NPC animation + kiss popup + coins
remotes.KissReaction.OnClientEvent:Connect(function(characterName, reactionType, globalCount)
	pcall(function()
		AnimationController:OnKissReaction(characterName, reactionType, globalCount)
		UIController:AddCoins(Config.BASE_KISS_COINS)

		local body = findNPCBody(characterName)
		if body then
			UIController:SpawnKissPopup(body.Position, Config.BASE_KISS_COINS, false)
			VFXController:SpawnCoinPopup(body.Position, Config.BASE_KISS_COINS)
		end
	end)
end)

-- ComboUpdate: combo HUD + banner + sound + camera shake
remotes.ComboUpdate.OnClientEvent:Connect(function(comboCount, multiplier)
	pcall(function()
		UIController:SetCombo(comboCount)
		UIController:ShowComboBanner(comboCount)
		SoundController:PlayComboTick(comboCount)
		AnimationController:OnComboUpdate(comboCount, multiplier)

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
end)

-- SuperKissEvent: celebration VFX + popup + coins
remotes.SuperKissEvent.OnClientEvent:Connect(function(characterName, coinsAwarded)
	pcall(function()
		SoundController:PlaySuperKiss()
		AnimationController:OnSuperKissEvent(characterName, coinsAwarded)
		UIController:AddCoins(coinsAwarded)

		local body = findNPCBody(characterName)
		if body then
			UIController:SpawnKissPopup(body.Position, coinsAwarded, true)
			VFXController:SpawnSuperKissVFX(body.Position)
			VFXController:SpawnCoinPopup(body.Position + Vector3.new(0, 2, 0), coinsAwarded)
		end
	end)
end)

-- LeaderboardUpdate: refresh both leaderboard UIs
remotes.LeaderboardUpdate.OnClientEvent:Connect(function(topKissers)
	pcall(function()
		LeaderboardController:UpdateEntries(topKissers)
		UIController:UpdateLeaderboard(topKissers)
	end)
end)

-- MilestoneAnnouncement: banner + sound + NPC animation + sparkles
remotes.MilestoneAnnouncement.OnClientEvent:Connect(function(characterName, milestone)
	pcall(function()
		UIController:ShowMilestone(characterName, milestone)
		SoundController:PlayMilestone()
		AnimationController:OnMilestoneAnnouncement(characterName, milestone)

		local body = findNPCBody(characterName)
		if body then
			VFXController:SpawnSparkles(body.Position)
		end
	end)
end)

print("====================================")
print("  ALL CONTROLLERS LOADED")
print("  Remotes: wired")
print("  Game ready!")
print("====================================")
