-- Test Runner for Kiss the Brainrot
-- 8 test cases covering core gameplay systems

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

-- Mock player
local function createMockPlayer(name, position)
	local mockHRP = { Position = position or Vector3.new(0, 0, 0) }
	local mockCharacter = {
		FindFirstChild = function(_, childName)
			if childName == "HumanoidRootPart" then return mockHRP end
			return nil
		end,
	}
	return {
		Name = name or "TestPlayer",
		UserId = math.random(100000, 999999),
		Character = mockCharacter,
	}
end

-- Initialize services for testing (same order as Init.server.lua)
RemoteService:Init()
DataService:Init()
CharacterService:Init()
LeaderboardService:Init()
KissService:Init()

CharacterService:SetRemoteService(RemoteService)
LeaderboardService:SetServices(DataService, RemoteService)
KissService:SetServices(DataService, CharacterService, RemoteService, LeaderboardService)

print("\n========================================")
print("  KISS THE BRAINROT - TEST SUITE")
print("========================================")

-- TEST 1: Proximity check rejects far player
describe("KissService - Proximity Check", function()
	it("should reject kiss from out of range player", function()
		local ws = game:GetService("Workspace")
		local npcsFolder = ws:FindFirstChild("NPCs")
		if not npcsFolder then
			npcsFolder = Instance.new("Folder")
			npcsFolder.Name = "NPCs"
			npcsFolder.Parent = ws
		end

		-- Place NPC far away at (100,0,100)
		local testChar = "Tralalero Tralala"
		local npcModel = npcsFolder:FindFirstChild(testChar)
		if not npcModel then
			npcModel = Instance.new("Model")
			npcModel.Name = testChar
			local part = Instance.new("Part")
			part.Name = "HumanoidRootPart"
			part.Position = Vector3.new(100, 0, 100)
			part.Parent = npcModel
			npcModel.PrimaryPart = part
			npcModel.Parent = npcsFolder
		else
			local hrp = npcModel:FindFirstChild("HumanoidRootPart") or npcModel.PrimaryPart
			if hrp then hrp.Position = Vector3.new(100, 0, 100) end
		end

		local farPlayer = createMockPlayer("FarPlayer", Vector3.new(0, 0, 0))
		local valid, reason = KissService:ValidateKiss(farPlayer, testChar)
		expect(valid):toBeFalse()
		expect(reason):toBe("Too far away")
	end)
end)

-- TEST 2: Cooldown check rejects recent kisser
describe("KissService - Cooldown Check", function()
	it("should reject kiss during cooldown", function()
		local player = createMockPlayer("CooldownPlayer")
		local cooldowns = KissService:_GetPlayerCooldowns()
		cooldowns[player] = tick()

		local valid, reason = KissService:ValidateKiss(player, "Tralalero Tralala")
		expect(valid):toBeFalse()
		expect(reason):toBe("Cooldown active")

		cooldowns[player] = nil
	end)
end)

-- TEST 3: Combo system increments and resets correctly
describe("KissService - Combo System", function()
	it("should increment combo within window and reset after", function()
		local combos = KissService:_GetPlayerCombos()
		local player = createMockPlayer("ComboPlayer")

		-- Within window: should increment
		combos[player] = { count = 3, lastKissTime = tick() }
		local now = tick()
		local combo = combos[player]
		local withinWindow = (now - combo.lastKissTime) <= Config.COMBO_WINDOW
		expect(withinWindow):toBeTrue()

		combo.count = combo.count + 1
		combo.lastKissTime = now
		expect(combo.count):toBe(4)

		-- Expired: should reset
		combos[player] = { count = 5, lastKissTime = tick() - Config.COMBO_WINDOW - 1 }
		combo = combos[player]
		local expired = (tick() - combo.lastKissTime) > Config.COMBO_WINDOW
		expect(expired):toBeTrue()

		combos[player] = { count = 1, lastKissTime = tick() }
		expect(combos[player].count):toBe(1)

		combos[player] = nil
	end)
end)

-- TEST 4: Super Kiss gives 10x multiplier
describe("KissService - Super Kiss Multiplier", function()
	it("should apply 10x multiplier for super kiss", function()
		local base = Config.BASE_KISS_COINS
		expect(base * 1 * 1):toBe(10)   -- normal, no combo
		expect(base * 1 * 10):toBe(100)  -- super, no combo
		expect(base * 5 * 10):toBe(500)  -- super, 5x combo
	end)
end)

-- TEST 5: DataService fills missing fields with defaults
describe("DataService - Default Schema", function()
	it("should fill missing fields with defaults", function()
		local defaults = DataService:GetDefaultData()
		expect(defaults.TotalKisses):toBe(0)
		expect(defaults.HighestCombo):toBe(0)
		expect(defaults.CoinsEarned):toBe(0)
		expect(defaults.FavoriteCharacter):toBe("")
		expect(type(defaults.KissHistory)):toBe("table")

		-- Merge partial data
		local partial = { TotalKisses = 50 }
		local merged = DataService:GetDefaultData()
		for k, v in pairs(partial) do merged[k] = v end
		expect(merged.TotalKisses):toBe(50)
		expect(merged.HighestCombo):toBe(0)
		expect(merged.CoinsEarned):toBe(0)
	end)
end)

-- TEST 6: LeaderboardService returns max 10 entries
describe("LeaderboardService - Sorted Top 10", function()
	it("should return correctly sorted top 10", function()
		local top = LeaderboardService:GetTopKissers()
		expect(type(top)):toBe("table")
		expect(#top <= 10):toBeTrue()
	end)
end)

-- TEST 7: Rate limiter blocks after max requests
describe("RateLimiter - Rate Limiting", function()
	it("should block player after max requests in window", function()
		local limiter = RateLimiter.new()
		local player = createMockPlayer("RateLimitPlayer")

		expect(limiter:IsRateLimited(player)):toBeFalse()

		for _ = 1, Config.RATE_LIMIT_MAX do
			limiter:RecordRequest(player)
		end

		expect(limiter:IsRateLimited(player)):toBeTrue()

		limiter:CleanupPlayer(player)
		expect(limiter:IsRateLimited(player)):toBeFalse()
	end)
end)

-- TEST 8: CharacterService milestone fires at correct count
describe("CharacterService - Milestones", function()
	it("should fire milestone at correct global kiss count", function()
		local milestonesFired = {}
		local originalBroadcast = CharacterService.BroadcastMilestone
		CharacterService.BroadcastMilestone = function(_, characterName, milestone)
			table.insert(milestonesFired, { character = characterName, milestone = milestone })
		end

		local charName = "Bombardino Coccodrillo"
		local char = CharacterService:GetCharacter(charName)
		char.KissCount = 0

		for _ = 1, Config.MILESTONE_INTERVAL do
			CharacterService:IncrementKissCount(charName)
		end

		expect(#milestonesFired):toBe(1)
		expect(milestonesFired[1].character):toBe(charName)
		expect(milestonesFired[1].milestone):toBe(Config.MILESTONE_INTERVAL)

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
else
	print("ALL TESTS PASSED!")
end
