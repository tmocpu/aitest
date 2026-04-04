local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Modules"):WaitForChild("Config"))

local LeaderboardService = {}
LeaderboardService.__index = LeaderboardService

local LEADERBOARD_STORE_NAME = "BrainrotKissLeaderboard_v1"
local leaderboardStore = nil
local DataService = nil
local RemoteService = nil
local cachedTopKissers = {}

function LeaderboardService:Init()
	local ok, store = pcall(function()
		return DataStoreService:GetOrderedDataStore(LEADERBOARD_STORE_NAME)
	end)
	if ok then
		leaderboardStore = store
	else
		warn("[LeaderboardService] Failed to get OrderedDataStore: " .. tostring(store))
	end
end

function LeaderboardService:Start()
	-- Periodic leaderboard refresh
	task.spawn(function()
		while true do
			self:RefreshLeaderboard()
			task.wait(Config.LEADERBOARD_UPDATE_INTERVAL)
		end
	end)
end

function LeaderboardService:SetServices(dataService, remoteService)
	DataService = dataService
	RemoteService = remoteService
end

function LeaderboardService:UpdatePlayerScore(player)
	if not leaderboardStore or not DataService then
		return
	end

	local data = DataService:GetData(player)
	if not data then
		return
	end

	local ok, err = pcall(function()
		leaderboardStore:SetAsync("Player_" .. player.UserId, data.TotalKisses)
	end)

	if not ok and Config.DEBUG_MODE then
		warn("[LeaderboardService] Failed to update score: " .. tostring(err))
	end
end

function LeaderboardService:RefreshLeaderboard()
	if not leaderboardStore then
		return
	end

	local ok, pages = pcall(function()
		return leaderboardStore:GetSortedAsync(false, 50)
	end)

	if not ok or not pages then
		return
	end

	local topKissers = {}
	local currentPage = pages:GetCurrentPage()

	for rank, entry in ipairs(currentPage) do
		local userId = tonumber(string.match(entry.key, "Player_(%d+)"))
		local playerName = "Unknown"

		if userId then
			local nameOk, name = pcall(function()
				return Players:GetNameFromUserIdAsync(userId)
			end)
			if nameOk then
				playerName = name
			end
		end

		table.insert(topKissers, {
			Rank = rank,
			Name = playerName,
			TotalKisses = entry.value,
		})

		if rank >= 50 then
			break
		end
	end

	cachedTopKissers = topKissers

	-- Broadcast top 10 to all clients
	if RemoteService then
		local top10 = self:GetTopKissers()
		RemoteService:FireAllClients("LeaderboardUpdate", top10)
	end
end

function LeaderboardService:GetTopKissers()
	local top10 = {}
	for i = 1, math.min(10, #cachedTopKissers) do
		table.insert(top10, cachedTopKissers[i])
	end
	return top10
end

return LeaderboardService
