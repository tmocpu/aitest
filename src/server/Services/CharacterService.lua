local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Modules"):WaitForChild("Config"))
local ReactionData = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Modules"):WaitForChild("ReactionData"))

local CharacterService = {}
CharacterService.__index = CharacterService

local characters = {}
local RemoteService = nil

local CHARACTER_DEFINITIONS = {
	{
		Name = "Tralalero Tralala",
		RarityTier = "Common",
		Cooldown = 0.8,
	},
	{
		Name = "Bombardino Coccodrillo",
		RarityTier = "Common",
		Cooldown = 0.8,
	},
	{
		Name = "Tung Tung Tung Sahur",
		RarityTier = "Uncommon",
		Cooldown = 0.8,
	},
	{
		Name = "Brr Brr Patapim",
		RarityTier = "Uncommon",
		Cooldown = 0.8,
	},
	{
		Name = "Cappuccino Assassino",
		RarityTier = "Rare",
		Cooldown = 0.8,
	},
	{
		Name = "Ballerina Cappuccina",
		RarityTier = "Rare",
		Cooldown = 0.8,
	},
}

function CharacterService:Init()
	for _, def in ipairs(CHARACTER_DEFINITIONS) do
		local reactions = ReactionData[def.Name] or { normal = {}, combo = {}, super = {} }
		characters[def.Name] = {
			Name = def.Name,
			KissCount = 0,
			ReactionPool = reactions,
			Cooldown = def.Cooldown,
			RarityTier = def.RarityTier,
		}
	end
end

function CharacterService:Start()
	-- RemoteService reference is set via SetRemoteService
end

function CharacterService:SetRemoteService(service)
	RemoteService = service
end

function CharacterService:GetCharacter(name)
	return characters[name]
end

function CharacterService:GetAllCharacters()
	return characters
end

function CharacterService:IncrementKissCount(characterName)
	local character = characters[characterName]
	if not character then
		return 0
	end

	character.KissCount = character.KissCount + 1

	-- Check for milestone
	if character.KissCount % Config.MILESTONE_INTERVAL == 0 then
		self:BroadcastMilestone(characterName, character.KissCount)
	end

	return character.KissCount
end

function CharacterService:GetGlobalKissCount(characterName)
	local character = characters[characterName]
	if character then
		return character.KissCount
	end
	return 0
end

function CharacterService:BroadcastMilestone(characterName, milestone)
	if RemoteService then
		RemoteService:FireAllClients("MilestoneAnnouncement", characterName, milestone)
	end

	if Config.DEBUG_MODE then
		print("[CharacterService] Milestone: " .. characterName .. " reached " .. milestone .. " kisses!")
	end
end

function CharacterService:GetReaction(characterName, reactionTier)
	local character = characters[characterName]
	if not character then
		return "smiles"
	end

	local pool = character.ReactionPool[reactionTier]
	if not pool or #pool == 0 then
		return "smiles"
	end

	return pool[math.random(1, #pool)]
end

function CharacterService:GetCharacterPosition(characterName)
	-- Look for the NPC model in workspace
	local workspace = game:GetService("Workspace")
	local npcsFolder = workspace:FindFirstChild("NPCs")
	if not npcsFolder then
		return nil
	end

	local npcModel = npcsFolder:FindFirstChild(characterName)
	if not npcModel then
		return nil
	end

	local primaryPart = npcModel.PrimaryPart or npcModel:FindFirstChild("HumanoidRootPart")
	if primaryPart then
		return primaryPart.Position
	end

	return nil
end

return CharacterService
