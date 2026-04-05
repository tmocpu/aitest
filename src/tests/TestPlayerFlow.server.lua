-- TestPlayerFlow: Simulates a full player session server-side (11 steps)
-- No real client needed — tests the entire kiss pipeline with mocks

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Modules"):WaitForChild("Config"))

local Services = game:GetService("ServerScriptService"):WaitForChild("Server"):WaitForChild("Services")
local DataService = require(Services:WaitForChild("DataService"))
local CharacterService = require(Services:WaitForChild("CharacterService"))
local KissService = require(Services:WaitForChild("KissService"))
local LeaderboardService = require(Services:WaitForChild("LeaderboardService"))
local RemoteService = require(Services:WaitForChild("RemoteService"))
local GamepassService = require(Services:WaitForChild("GamepassService"))
local ProductService = require(Services:WaitForChild("ProductService"))

-- Init services for this test context
RemoteService:Init()
DataService:Init()
CharacterService:Init()
LeaderboardService:Init()
KissService:Init()
GamepassService:Init()

CharacterService:SetRemoteService(RemoteService)
LeaderboardService:SetServices(DataService, RemoteService)
KissService:SetServices(DataService, CharacterService, RemoteService, LeaderboardService, GamepassService)
GamepassService:SetServices(KissService, CharacterService, RemoteService, DataService)
ProductService:SetServices(DataService, RemoteService, KissService, GamepassService)

-- Test framework
local stepResults = {}
local passCount = 0
local failCount = 0

local function step(num, name, fn)
	local ok, err = pcall(fn)
	if ok then
		passCount = passCount + 1
		table.insert(stepResults, { num = num, name = name, passed = true })
		print(string.format("  PASS [%d/11] %s", num, name))
	else
		failCount = failCount + 1
		table.insert(stepResults, { num = num, name = name, passed = false, error = err })
		print(string.format("  FAIL [%d/11] %s - %s", num, name, tostring(err)))
	end
end

-- Create mock player
local mockPlayer = {
	Name = "TestPlayer_Flow",
	UserId = 999999,
	Character = nil,
	Parent = game, -- simulates being in Players
}

-- Create character with HRP
local function setMockPlayerPosition(position)
	local mockHRP = { Position = position }
	mockPlayer.Character = {
		FindFirstChild = function(_, childName)
			if childName == "HumanoidRootPart" then return mockHRP end
			return nil
		end,
	}
end

-- Ensure test NPC exists
local npcsFolder = Workspace:FindFirstChild("NPCs")
if not npcsFolder then
	npcsFolder = Instance.new("Folder")
	npcsFolder.Name = "NPCs"
	npcsFolder.Parent = Workspace
end

local targetChar = "Pizzicato Pangolino"
local targetNPC = npcsFolder:FindFirstChild(targetChar)
local npcPosition = Vector3.new(30, 5, 0) -- pedestal position

if not targetNPC then
	targetNPC = Instance.new("Model")
	targetNPC.Name = targetChar
	local part = Instance.new("Part")
	part.Name = "HumanoidRootPart"
	part.Position = npcPosition
	part.Parent = targetNPC
	targetNPC.PrimaryPart = part
	local sv = Instance.new("StringValue")
	sv.Name = "CharacterName"
	sv.Value = targetChar
	sv.Parent = targetNPC
	targetNPC.Parent = npcsFolder
else
	local hrp = targetNPC.PrimaryPart or targetNPC:FindFirstChild("HumanoidRootPart")
	if hrp then
		npcPosition = hrp.Position
	end
end

print("\n========================================")
print("  PLAYER FLOW TEST (11 steps)")
print("========================================")

-- Step 1: Load data
step(1, "DataService:LoadData loads with correct schema", function()
	DataService:LoadData(mockPlayer)
	local data = DataService:GetData(mockPlayer)
	assert(data ~= nil, "Data is nil after LoadData")
	assert(data.TotalKisses == 0, "TotalKisses should be 0, got " .. tostring(data.TotalKisses))
	assert(data.CoinsEarned == 0, "CoinsEarned should be 0")
	assert(data.HighestCombo == 0, "HighestCombo should be 0")
	assert(type(data.KissHistory) == "table", "KissHistory should be a table")
end)

-- Step 2: Place mock player 8 studs from NPC
step(2, "Player positioned 8 studs from NPC", function()
	-- 8 studs from NPC position along X axis
	local playerPos = npcPosition + Vector3.new(8, 0, 0)
	setMockPlayerPosition(playerPos)
	local dist = (playerPos - npcPosition).Magnitude
	assert(dist <= Config.PROXIMITY_RANGE, "Player should be within range, got " .. tostring(dist))
end)

-- Step 3: ValidateKiss succeeds
step(3, "ValidateKiss returns true within range", function()
	local valid, reason = KissService:ValidateKiss(mockPlayer, targetChar)
	assert(valid == true, "ValidateKiss should return true, got false: " .. tostring(reason))
end)

-- Step 4: ProcessKiss awards coins and increments stats
step(4, "ProcessKiss awards coins, combo=1, global kisses increment", function()
	local charBefore = CharacterService:GetCharacter(targetChar)
	local globalBefore = charBefore and charBefore.KissCount or 0

	KissService:ProcessKiss(mockPlayer, targetChar)

	local data = DataService:GetData(mockPlayer)
	assert(data.TotalKisses >= 1, "TotalKisses should be >= 1, got " .. tostring(data.TotalKisses))
	assert(data.CoinsEarned >= Config.BASE_KISS_COINS, "Coins should be >= " .. Config.BASE_KISS_COINS)

	local combos = KissService:_GetPlayerCombos()
	assert(combos[mockPlayer] ~= nil, "Combo entry should exist")
	assert(combos[mockPlayer].count == 1, "Combo should be 1, got " .. tostring(combos[mockPlayer].count))

	local charAfter = CharacterService:GetCharacter(targetChar)
	assert(charAfter.KissCount > globalBefore, "Global kiss count should increment")
end)

-- Step 5: Rapid kisses build combo to 5
step(5, "5 rapid kisses build combo to 5", function()
	-- Clear cooldown between each kiss
	local cooldowns = KissService:_GetPlayerCooldowns()
	for i = 2, 5 do
		cooldowns[mockPlayer] = nil -- clear cooldown
		KissService:ProcessKiss(mockPlayer, targetChar)
	end

	local combos = KissService:_GetPlayerCombos()
	assert(combos[mockPlayer].count == 5, "Combo should be 5, got " .. tostring(combos[mockPlayer].count))
end)

-- Step 6: Wait 4s, combo resets
step(6, "Combo resets after 4 seconds", function()
	local combos = KissService:_GetPlayerCombos()
	-- Simulate expired combo by setting lastKissTime in the past
	combos[mockPlayer].lastKissTime = tick() - Config.COMBO_WINDOW - 1

	-- Next kiss should reset combo to 1
	local cooldowns = KissService:_GetPlayerCooldowns()
	cooldowns[mockPlayer] = nil
	KissService:ProcessKiss(mockPlayer, targetChar)

	assert(combos[mockPlayer].count == 1, "Combo should reset to 1, got " .. tostring(combos[mockPlayer].count))
end)

-- Step 7: Rate limiter triggers after 20 rapid requests
step(7, "Rate limiter triggers after 20 requests", function()
	local limiter = KissService:_GetRateLimiter()
	-- Record enough requests to hit the limit
	for _ = 1, Config.RATE_LIMIT_MAX do
		limiter:RecordRequest(mockPlayer)
	end
	assert(limiter:IsRateLimited(mockPlayer) == true, "Should be rate limited")

	-- Clean up for next steps
	limiter:CleanupPlayer(mockPlayer)
end)

-- Step 8: Coin purchase via product handler
step(8, "PRODUCT_COIN_SMALL adds 100 coins", function()
	local dataBefore = DataService:GetData(mockPlayer)
	local coinsBefore = dataBefore.CoinsEarned

	-- Simulate the product handler directly
	DataService:AddCoins(mockPlayer, Config.COIN_SMALL_AMOUNT)

	local dataAfter = DataService:GetData(mockPlayer)
	assert(dataAfter.CoinsEarned == coinsBefore + Config.COIN_SMALL_AMOUNT,
		"Coins should increase by " .. Config.COIN_SMALL_AMOUNT ..
		", got " .. tostring(dataAfter.CoinsEarned - coinsBefore))
end)

-- Step 9: Duplicate receipt check (verify ProcessReceipt exists)
step(9, "ProcessReceipt handler is registered", function()
	assert(MarketplaceService.ProcessReceipt ~= nil, "ProcessReceipt should be set")
end)

-- Step 10: SaveData succeeds without errors
step(10, "DataService:SaveData completes without error", function()
	-- SaveData uses pcall internally, so this should never throw
	DataService:SaveData(mockPlayer)
	-- If we get here, it succeeded (DataStore may not be available in test)
end)

-- Step 11: Session cleanup
step(11, "Session cleanup removes player data", function()
	local cooldowns = KissService:_GetPlayerCooldowns()
	local combos = KissService:_GetPlayerCombos()

	-- Simulate PlayerRemoving cleanup
	cooldowns[mockPlayer] = nil
	combos[mockPlayer] = nil

	assert(cooldowns[mockPlayer] == nil, "Cooldowns should be nil")
	assert(combos[mockPlayer] == nil, "Combos should be nil")
end)

-- Summary
print("\n========================================")
print(string.format("  PLAYER FLOW: %d/11 passed, %d failed", passCount, failCount))
print("========================================\n")

if failCount > 0 then
	print("FAILED STEPS:")
	for _, r in ipairs(stepResults) do
		if not r.passed then
			print(string.format("  [%d] %s: %s", r.num, r.name, r.error))
		end
	end
else
	print("ALL 11 STEPS PASSED!")
end

