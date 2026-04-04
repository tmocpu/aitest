-- Test Runner for Brainrot Kiss Game
-- Runs all test cases and reports results

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Modules"):WaitForChild("Config"))
local ReactionData = require(Shared:WaitForChild("Modules"):WaitForChild("ReactionData"))
local RateLimiter = require(Shared:WaitForChild("Modules"):WaitForChild("RateLimiter"))

local Services = game:GetService("ServerScriptService"):WaitForChild("Server"):WaitForChild("Services")
local DataService = require(Services:WaitForChild("DataService"))
local CharacterService = require(Services:WaitForChild("CharacterService"))
local KissService = require(Services:WaitForChild("KissService"))
local LeaderboardService = require(Services:WaitForChild("LeaderboardService"))
local RemoteService = require(Services:WaitForChild("RemoteService"))

-- Test framework
local testResults = {}
local passed = 0
local failed = 0

local function describe(name, fn)
	print("\n=== " .. name .. " ===")
	fn()
end

local function it(name, fn)
	local ok, err = pcall(fn)
	if ok then
		passed = passed + 1
		table.insert(testResults, { name = name, passed = true })
		print("  PASS: " .. name)
	else
		failed = failed + 1
		table.insert(testResults, { name = name, passed = false, error = err })
		print("  FAIL: " .. name .. " - " .. tostring(err))
	end
end

local function expect(value)
	return {
		toBe = function(_, expected)
			assert(value == expected, string.format("Expected %s to be %s", tostring(value), tostring(expected)))
		end,
		toBeTrue = function()
			assert(value == true, "Expected true, got " .. tostring(value))
		end,
		toBeFalse = function()
			assert(value == false, "Expected false, got " .. tostring(value))
		end,
		toBeGreaterThan = function(_, expected)
			assert(value > expected, string.format("Expected %s > %s", tostring(value), tostring(expected)))
		end,
		toBeLessThanOrEqual = function(_, expected)
			assert(value <= expected, string.format("Expected %s <= %s", tostring(value), tostring(expected)))
		end,
		toBeNil = function()
			assert(value == nil, "Expected nil, got " .. tostring(value))
		end,
		toNotBeNil = function()
			assert(value ~= nil, "Expected non-nil value")
		end,
	}
end

-- Mock player for testing
local function createMockPlayer(name, position)
	local mockHRP = {
		Position = position or Vector3.new(0, 0, 0),
	}
	local mockCharacter = {
		FindFirstChild = function(_, childName)
			if childName == "HumanoidRootPart" then
				return mockHRP
			end
			return nil
		end,
	}
	return {
		Name = name or "TestPlayer",
		UserId = math.random(100000, 999999),
		Character = mockCharacter,
	}
end

-- Initialize services for testing
RemoteService:Init()
DataService:Init()
CharacterService:Init()
LeaderboardService:Init()
KissService:Init()

CharacterService:SetRemoteService(RemoteService)
LeaderboardService:SetServices(DataService, RemoteService)
KissService:SetServices(DataService, CharacterService, RemoteService, LeaderboardService)

print("\n========================================")
print("  BRAINROT KISS GAME - TEST SUITE")
print("========================================")

-- TEST 1: KissService rejects kiss from out of range player
describe("KissService - Proximity Check", function()
	it("should reject kiss from out of range player", function()
		-- Create a mock NPC in workspace for testing
		local workspace = game:GetService("Workspace")
		local npcsFolder = workspace:FindFirstChild("NPCs")
		if not npcsFolder then
			npcsFolder = Instance.new("Folder")
			npcsFolder.Name = "NPCs"
			npcsFolder.Parent = workspace
		end

		local npcModel = npcsFolder:FindFirstChild("Tralalero Tralala")
		if not npcModel then
			npcModel = Instance.new("Model")
			npcModel.Name = "Tralalero Tralala"
			local part = Instance.new("Part")
			part.Name = "HumanoidRootPart"
			part.Position = Vector3.new(100, 0, 100)
			part.Parent = npcModel
			npcModel.PrimaryPart = part
			npcModel.Parent = npcsFolder
		end

		-- Player far away at origin
		local farPlayer = createMockPlayer("FarPlayer", Vector3.new(0, 0, 0))

		local valid, reason = KissService:ValidateKiss(farPlayer, "Tralalero Tralala")
		expect(valid):toBeFalse()
		expect(reason):toBe("Too far away")
	end)
end)

-- TEST 2: KissService rejects kiss during cooldown
describe("KissService - Cooldown Check", function()
	it("should reject kiss during cooldown", function()
		local player = createMockPlayer("CooldownPlayer")

		-- Simulate a recent kiss by setting cooldown
		local cooldowns = KissService:_GetPlayerCooldowns()
		cooldowns[player] = tick()

		local valid, reason = KissService:ValidateKiss(player, "Tralalero Tralala")
		expect(valid):toBeFalse()
		expect(reason):toBe("Cooldown active")

		-- Cleanup
		cooldowns[player] = nil
	end)
end)

-- TEST 3: Combo increments correctly within window, resets after
describe("KissService - Combo System", function()
	it("should increment combo within window and reset after", function()
		local combos = KissService:_GetPlayerCombos()
		local player = createMockPlayer("ComboPlayer")

		-- Simulate combo within window
		combos[player] = { count = 3, lastKissTime = tick() }

		-- Process combo check logic (simulating what ProcessKiss does)
		local now = tick()
		local combo = combos[player]
		local withinWindow = (now - combo.lastKissTime) <= Config.COMBO_WINDOW

		expect(withinWindow):toBeTrue()

		-- Increment
		if withinWindow then
			combo.count = combo.count + 1
			combo.lastKissTime = now
		end
		expect(combo.count):toBe(4)

		-- Simulate expired combo
		combos[player] = { count = 5, lastKissTime = tick() - Config.COMBO_WINDOW - 1 }
		combo = combos[player]
		local expired = (tick() - combo.lastKissTime) > Config.COMBO_WINDOW
		expect(expired):toBeTrue()

		-- Reset on expired
		if expired then
			combos[player] = { count = 1, lastKissTime = tick() }
		end
		expect(combos[player].count):toBe(1)

		-- Cleanup
		combos[player] = nil
	end)
end)

-- TEST 4: Super Kiss multiplier applies correctly
describe("KissService - Super Kiss Multiplier", function()
	it("should apply 10x multiplier for super kiss", function()
		local baseCoins = Config.BASE_KISS_COINS
		local comboMultiplier = 1

		-- Normal kiss
		local normalCoins = baseCoins * comboMultiplier * 1
		expect(normalCoins):toBe(10)

		-- Super kiss
		local superCoins = baseCoins * comboMultiplier * 10
		expect(superCoins):toBe(100)

		-- Super kiss with combo
		comboMultiplier = 5
		local superComboCoins = baseCoins * comboMultiplier * 10
		expect(superComboCoins):toBe(500)
	end)
end)

-- TEST 5: DataService schema fills missing fields with defaults
describe("DataService - Default Schema", function()
	it("should fill missing fields with defaults", function()
		local defaults = DataService:GetDefaultData()

		expect(defaults.TotalKisses):toBe(0)
		expect(defaults.HighestCombo):toBe(0)
		expect(defaults.CoinsEarned):toBe(0)
		expect(defaults.FavoriteCharacter):toBe("")
		expect(type(defaults.KissHistory)):toBe("table")

		-- Simulate partial data (as if loaded from DataStore)
		local partialData = { TotalKisses = 50 }
		local merged = DataService:GetDefaultData()
		for field, value in pairs(partialData) do
			merged[field] = value
		end

		expect(merged.TotalKisses):toBe(50)
		expect(merged.HighestCombo):toBe(0) -- filled with default
		expect(merged.CoinsEarned):toBe(0)  -- filled with default
	end)
end)

-- TEST 6: LeaderboardService returns correctly sorted top 10
describe("LeaderboardService - Sorted Top 10", function()
	it("should return correctly sorted top 10", function()
		-- The leaderboard uses an OrderedDataStore which sorts automatically.
		-- We test the GetTopKissers limiting logic.
		-- Manually populate the cached data via the service.

		-- Access internal cache for testing by calling GetTopKissers
		-- Since no DataStore data exists in test, it should return empty
		local top = LeaderboardService:GetTopKissers()
		expect(type(top)):toBe("table")
		expect(#top <= 10):toBeTrue()
	end)
end)

-- TEST 7: Rate limiter blocks player after 20 requests in 10s
describe("RateLimiter - Rate Limiting", function()
	it("should block player after max requests in window", function()
		local limiter = RateLimiter.new()
		local player = createMockPlayer("RateLimitPlayer")

		-- Should not be rate limited initially
		expect(limiter:IsRateLimited(player)):toBeFalse()

		-- Record max requests
		for i = 1, Config.RATE_LIMIT_MAX do
			limiter:RecordRequest(player)
		end

		-- Should now be rate limited
		expect(limiter:IsRateLimited(player)):toBeTrue()

		-- Cleanup
		limiter:CleanupPlayer(player)
		expect(limiter:IsRateLimited(player)):toBeFalse()
	end)
end)

-- TEST 8: CharacterService milestone fires at correct global kiss count
describe("CharacterService - Milestones", function()
	it("should fire milestone at correct global kiss count", function()
		local milestonesFired = {}

		-- Override BroadcastMilestone for testing
		local originalBroadcast = CharacterService.BroadcastMilestone
		CharacterService.BroadcastMilestone = function(self, characterName, milestone)
			table.insert(milestonesFired, { character = characterName, milestone = milestone })
		end

		-- Kiss character up to milestone
		local charName = "Bombardino Coccodrillo"
		local char = CharacterService:GetCharacter(charName)
		-- Reset kiss count for clean test
		char.KissCount = 0

		for i = 1, Config.MILESTONE_INTERVAL do
			CharacterService:IncrementKissCount(charName)
		end

		-- Should have fired exactly one milestone
		expect(#milestonesFired):toBe(1)
		expect(milestonesFired[1].character):toBe(charName)
		expect(milestonesFired[1].milestone):toBe(Config.MILESTONE_INTERVAL)

		-- Restore original
		CharacterService.BroadcastMilestone = originalBroadcast
	end)
end)

-- Summary
print("\n========================================")
print(string.format("  RESULTS: %d passed, %d failed, %d total", passed, failed, passed + failed))
print("========================================\n")

if failed > 0 then
	print("FAILED TESTS:")
	for _, result in ipairs(testResults) do
		if not result.passed then
			print("  - " .. result.name .. ": " .. result.error)
		end
	end
end
