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

-- Strict init order: remotes first, then data, then world/models, then gameplay
local serviceList = {
	{ name = "RemoteService",    module = RemoteService },
	{ name = "DataService",      module = DataService },
	{ name = "CharacterService", module = CharacterService },
	{ name = "ModelService",     module = ModelService },
	{ name = "WorldService",     module = WorldService },
	{ name = "KissService",      module = KissService },
	{ name = "LeaderboardService", module = LeaderboardService },
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
KissService:SetServices(DataService, CharacterService, RemoteService, LeaderboardService)

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
	-- Wait for DataService to load this player's data
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

-- Send initial data to any players already connected
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

-- Phase 4: Server-side ProximityPrompt connection
-- When any player activates a KissPrompt, fire RequestKiss to server pipeline
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

print("====================================")
print("  ALL SERVICES LOADED")
print("  Characters: " .. #ModelService:GetCharacterNames())
print("  Remotes: active")
print("  ProximityPrompts: wired")
print("====================================")
