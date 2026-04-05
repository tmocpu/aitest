-- Server Bootstrap — Kiss the Brainrot
-- Loads all services sequentially: each :Init() completes before the next starts

local Players = game:GetService("Players")
local Services = script:WaitForChild("Services")

local RemoteService = require(Services:WaitForChild("RemoteService"))
local DataService = require(Services:WaitForChild("DataService"))
local CharacterService = require(Services:WaitForChild("CharacterService"))
local ModelService = require(Services:WaitForChild("ModelService"))
local WorldService = require(Services:WaitForChild("WorldService"))
local KissService = require(Services:WaitForChild("KissService"))
local LeaderboardService = require(Services:WaitForChild("LeaderboardService"))
local GamepassService = require(Services:WaitForChild("GamepassService"))
local ProductService = require(Services:WaitForChild("ProductService"))

-- Strict init order per spec
local serviceList = {
	{ name = "RemoteService",      module = RemoteService },
	{ name = "DataService",        module = DataService },
	{ name = "CharacterService",   module = CharacterService },
	{ name = "ModelService",       module = ModelService },
	{ name = "WorldService",       module = WorldService },
	{ name = "KissService",        module = KissService },
	{ name = "LeaderboardService", module = LeaderboardService },
	{ name = "GamepassService",    module = GamepassService },
	{ name = "ProductService",     module = ProductService },
}

print("====================================")
print("  KISS THE BRAINROT - SERVER START")
print("====================================")

-- Phase 1: Init all services sequentially
for _, service in ipairs(serviceList) do
	local ok, err = pcall(function()
		service.module:Init()
	end)
	if ok then
		print("  [+] " .. service.name .. " initialized")
	else
		warn("  [X] " .. service.name .. " FAILED init: " .. tostring(err))
	end
end

-- Wire cross-service dependencies
CharacterService:SetRemoteService(RemoteService)
LeaderboardService:SetServices(DataService, RemoteService)
KissService:SetServices(DataService, CharacterService, RemoteService, LeaderboardService, GamepassService)
GamepassService:SetServices(KissService, CharacterService, RemoteService, DataService)
ProductService:SetServices(DataService, RemoteService, KissService, GamepassService)

-- Phase 2: Start all services sequentially
for _, service in ipairs(serviceList) do
	local ok, err = pcall(function()
		service.module:Start()
	end)
	if ok then
		print("  [+] " .. service.name .. " started")
	else
		warn("  [X] " .. service.name .. " FAILED start: " .. tostring(err))
	end
end

-- Phase 3: Player join flow
Players.PlayerAdded:Connect(function(player)
	task.wait(1)

	pcall(function()
		local data = DataService:GetData(player)
		if data then
			RemoteService:FireClient("CoinsUpdate", player, data.CoinsEarned)
		end
	end)

	pcall(function()
		local top10 = LeaderboardService:GetTopKissers()
		RemoteService:FireClient("LeaderboardUpdate", player, top10)
	end)
end)

-- Send initial data to already-connected players
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(function()
		task.wait(1)
		pcall(function()
			local data = DataService:GetData(player)
			if data then
				RemoteService:FireClient("CoinsUpdate", player, data.CoinsEarned)
			end
		end)
		pcall(function()
			local top10 = LeaderboardService:GetTopKissers()
			RemoteService:FireClient("LeaderboardUpdate", player, top10)
		end)
	end)
end

-- Phase 4: ProximityPrompt wiring
local ProximityPromptService = game:GetService("ProximityPromptService")
ProximityPromptService.PromptTriggered:Connect(function(prompt, triggeringPlayer)
	if prompt.Name ~= "KissPrompt" then return end

	local model = prompt.Parent and prompt.Parent.Parent
	if not model then return end

	local nameValue = model:FindFirstChild("CharacterName")
	local characterName = nameValue and nameValue.Value or model.Name

	pcall(function()
		KissService:HandleKissRequest(triggeringPlayer, characterName)
	end)
end)

-- Phase 5: Performance monitor (every 30s)
local totalServerKisses = 0

-- Patch KissService to count kisses for monitoring
local origProcessKiss = KissService.ProcessKiss
KissService.ProcessKiss = function(self2, player, characterName, ...)
	totalServerKisses = totalServerKisses + 1
	return origProcessKiss(self2, player, characterName, ...)
end

task.spawn(function()
	while true do
		task.wait(30)
		local stats = game:GetService("Stats")
		local memMB = 0
		pcall(function()
			memMB = stats:GetTotalMemoryUsageMb()
		end)
		local playerCount = #Players:GetPlayers()
		print(string.format(
			"[Perf] Memory: %.0fMB | Players: %d | Kisses: %d",
			memMB, playerCount, totalServerKisses
		))
		if memMB > 2000 then
			warn("[Perf] WARNING: Memory exceeds 2000MB!")
		end
	end
end)

print("====================================")
print("  ALL SERVICES LOADED")
print("  Characters: " .. #ModelService:GetCharacterNames())
print("  Gamepasses: 4 registered")
print("  Products: 5 registered")
print("  MonetizationSystem loaded")
print("  Performance monitor: active (30s)")
print("====================================")
