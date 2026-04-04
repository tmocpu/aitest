-- Server Bootstrap
-- Initializes all server services in order

local Services = script:WaitForChild("Services")

local RemoteService = require(Services:WaitForChild("RemoteService"))
local DataService = require(Services:WaitForChild("DataService"))
local CharacterService = require(Services:WaitForChild("CharacterService"))
local LeaderboardService = require(Services:WaitForChild("LeaderboardService"))
local KissService = require(Services:WaitForChild("KissService"))

local serviceList = {
	{ name = "RemoteService", module = RemoteService },
	{ name = "DataService", module = DataService },
	{ name = "CharacterService", module = CharacterService },
	{ name = "LeaderboardService", module = LeaderboardService },
	{ name = "KissService", module = KissService },
}

-- Phase 1: Init all services
print("[Server] Initializing services...")
for _, service in ipairs(serviceList) do
	service.module:Init()
	print("[Server] " .. service.name .. " initialized")
end

-- Wire up cross-service dependencies
CharacterService:SetRemoteService(RemoteService)
LeaderboardService:SetServices(DataService, RemoteService)
KissService:SetServices(DataService, CharacterService, RemoteService, LeaderboardService)

-- Phase 2: Start all services
print("[Server] Starting services...")
for _, service in ipairs(serviceList) do
	service.module:Start()
	print("[Server] " .. service.name .. " started")
end

print("[Server] All services loaded successfully!")
