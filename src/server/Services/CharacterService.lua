local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Modules"):WaitForChild("Config"))
local ReactionData = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Modules"):WaitForChild("ReactionData"))

local CharacterService = {}
CharacterService.__index = CharacterService

local characters = {}
local RemoteService = nil

local CHARACTER_DEFINITIONS = {
	{ Name = "Tralalero Tralala", RarityTier = "Common", Cooldown = 0.8 },
	{ Name = "Bombardino Coccodrillo", RarityTier = "Common", Cooldown = 0.8 },
	{ Name = "Tung Tung Tung Sahur", RarityTier = "Uncommon", Cooldown = 0.8 },
	{ Name = "Brr Brr Patapim", RarityTier = "Uncommon", Cooldown = 0.8 },
	{ Name = "Cappuccino Assassino", RarityTier = "Rare", Cooldown = 0.8 },
	{ Name = "Ballerina Cappuccina", RarityTier = "Rare", Cooldown = 0.8 },
	-- ModelService characters
	{ Name = "Pizzicato Pangolino", RarityTier = "Common", Cooldown = 0.8 },
	{ Name = "Bombardino Bufalo", RarityTier = "Uncommon", Cooldown = 0.8 },
	{ Name = "Trombettino Tartaruga", RarityTier = "Common", Cooldown = 0.8 },
	{ Name = "Cappellino Capibara", RarityTier = "Common", Cooldown = 0.8 },
	{ Name = "Fischietto Fenicottero", RarityTier = "Uncommon", Cooldown = 0.8 },
	{ Name = "Urlando Unicorno", RarityTier = "Rare", Cooldown = 0.8 },
	{ Name = "Saltellino Salamandra", RarityTier = "Uncommon", Cooldown = 0.8 },
	{ Name = "Magnifico Macarone", RarityTier = "Rare", Cooldown = 0.8 },
}

function CharacterService:Init()
	for _, def in ipairs(CHARACTER_DEFINITIONS) do
		local reactions = ReactionData[def.Name] or { normal = {"smiles"}, combo = {"gets excited"}, super = {"goes legendary"} }
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
	local npcsFolder = Workspace:FindFirstChild("NPCs")
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
