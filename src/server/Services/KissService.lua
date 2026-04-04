local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Modules"):WaitForChild("Config"))
local RateLimiter = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Modules"):WaitForChild("RateLimiter"))

local KissService = {}
KissService.__index = KissService

local DataService = nil
local CharacterService = nil
local RemoteService = nil
local LeaderboardService = nil

local playerCooldowns = {} -- [player] = lastKissTime
local playerCombos = {}    -- [player] = { count, lastKissTime }
local rateLimiter = nil

function KissService:Init()
	rateLimiter = RateLimiter.new()
end

function KissService:Start()
	RemoteService:OnServerEvent("RequestKiss", function(player, characterName)
		self:HandleKissRequest(player, characterName)
	end)

	-- Cleanup on player leave
	local Players = game:GetService("Players")
	Players.PlayerRemoving:Connect(function(player)
		playerCooldowns[player] = nil
		playerCombos[player] = nil
		rateLimiter:CleanupPlayer(player)
	end)
end

function KissService:SetServices(dataService, characterService, remoteService, leaderboardService)
	DataService = dataService
	CharacterService = characterService
	RemoteService = remoteService
	LeaderboardService = leaderboardService
end

function KissService:HandleKissRequest(player, characterName)
	-- Rate limit check
	if rateLimiter:IsRateLimited(player) then
		warn("[KissService] Rate limited: " .. player.Name)
		return
	end
	rateLimiter:RecordRequest(player)

	-- Validate the kiss
	local valid, reason = self:ValidateKiss(player, characterName)
	if not valid then
		if Config.DEBUG_MODE then
			print("[KissService] Kiss rejected for " .. player.Name .. ": " .. reason)
		end
		return
	end

	-- Process the kiss
	self:ProcessKiss(player, characterName)
end

function KissService:ValidateKiss(player, characterName)
	-- Check character exists
	local character = CharacterService:GetCharacter(characterName)
	if not character then
		return false, "Invalid character"
	end

	-- Check cooldown
	local now = tick()
	local lastKiss = playerCooldowns[player]
	if lastKiss and (now - lastKiss) < Config.KISS_COOLDOWN then
		return false, "Cooldown active"
	end

	-- Check proximity
	local characterPos = CharacterService:GetCharacterPosition(characterName)
	if characterPos then
		local playerCharacter = player.Character
		if not playerCharacter then
			return false, "No character"
		end
		local hrp = playerCharacter:FindFirstChild("HumanoidRootPart")
		if not hrp then
			return false, "No HumanoidRootPart"
		end
		local distance = (hrp.Position - characterPos).Magnitude
		if distance > Config.PROXIMITY_RANGE then
			return false, "Too far away"
		end
	end

	return true, nil
end

function KissService:ProcessKiss(player, characterName)
	local now = tick()

	-- Set cooldown
	playerCooldowns[player] = now

	-- Handle combo
	local combo = playerCombos[player]
	if combo and (now - combo.lastKissTime) <= Config.COMBO_WINDOW then
		combo.count = combo.count + 1
		combo.lastKissTime = now
	else
		playerCombos[player] = { count = 1, lastKissTime = now }
		combo = playerCombos[player]
	end

	local comboCount = combo.count
	local comboMultiplier = comboCount

	-- Roll for Super Kiss
	local isSuperKiss = math.random() < Config.SUPER_KISS_CHANCE
	local coinMultiplier = isSuperKiss and 10 or 1

	-- Calculate coins
	local coinsAwarded = Config.BASE_KISS_COINS * comboMultiplier * coinMultiplier

	-- Determine reaction tier
	local reactionTier = "normal"
	if isSuperKiss then
		reactionTier = "super"
	elseif comboCount >= 5 then
		reactionTier = "combo"
	end

	local reaction = CharacterService:GetReaction(characterName, reactionTier)

	-- Update data
	DataService:IncrementKisses(player, 1)
	DataService:AddCoins(player, coinsAwarded)
	DataService:UpdateCombo(player, comboCount)
	DataService:RecordKiss(player, characterName)

	-- Update global character kiss count
	local globalCount = CharacterService:IncrementKissCount(characterName)

	-- Update leaderboard
	if LeaderboardService then
		LeaderboardService:UpdatePlayerScore(player)
	end

	-- Fire reactions to nearby clients
	local characterPos = CharacterService:GetCharacterPosition(characterName)
	if characterPos then
		RemoteService:FireNearbyClients(
			"KissReaction",
			characterPos,
			50,
			characterName,
			reaction,
			globalCount
		)
	else
		RemoteService:FireAllClients("KissReaction", characterName, reaction, globalCount)
	end

	-- Send combo update to the kissing player
	RemoteService:FireClient("ComboUpdate", player, comboCount, comboMultiplier)

	-- Super Kiss event
	if isSuperKiss then
		RemoteService:FireAllClients("SuperKissEvent", characterName, coinsAwarded)
	end

	if Config.DEBUG_MODE then
		print(string.format(
			"[KissService] %s kissed %s | Combo: %d | Coins: %d | Super: %s",
			player.Name, characterName, comboCount, coinsAwarded, tostring(isSuperKiss)
		))
	end
end

-- Exposed for testing
function KissService:_GetRateLimiter()
	return rateLimiter
end

function KissService:_GetPlayerCooldowns()
	return playerCooldowns
end

function KissService:_GetPlayerCombos()
	return playerCombos
end

return KissService
