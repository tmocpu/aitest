local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Modules"):WaitForChild("Config"))

local DataService = {}
DataService.__index = DataService

local DATA_STORE_NAME = "BrainrotKissData_v1"
local DATA_TEMPLATE = {
	TotalKisses = 0,
	HighestCombo = 0,
	CoinsEarned = 0,
	FavoriteCharacter = "",
	KissHistory = {},
}

local playerData = {}
local dataStore = nil

function DataService:Init()
	local ok, store = pcall(function()
		return DataStoreService:GetDataStore(DATA_STORE_NAME)
	end)
	if ok then
		dataStore = store
	else
		warn("[DataService] Failed to get DataStore: " .. tostring(store))
	end
end

function DataService:Start()
	Players.PlayerAdded:Connect(function(player)
		self:LoadData(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		self:SaveData(player)
		playerData[player] = nil
	end)

	-- Load data for any players already in game
	for _, player in ipairs(Players:GetPlayers()) do
		self:LoadData(player)
	end

	-- Auto-save loop
	task.spawn(function()
		while true do
			task.wait(Config.AUTO_SAVE_INTERVAL)
			self:SaveAllData()
		end
	end)

	game:BindToClose(function()
		self:SaveAllData()
	end)
end

function DataService:LoadData(player)
	if not dataStore then
		playerData[player] = self:GetDefaultData()
		return
	end

	local key = "Player_" .. player.UserId
	local ok, data = pcall(function()
		return dataStore:GetAsync(key)
	end)

	if ok and data then
		-- Fill missing fields with defaults
		local merged = self:GetDefaultData()
		for field, value in pairs(data) do
			merged[field] = value
		end
		playerData[player] = merged
	else
		playerData[player] = self:GetDefaultData()
	end

	if Config.DEBUG_MODE then
		print("[DataService] Loaded data for " .. player.Name)
	end
end

function DataService:SaveData(player)
	local data = playerData[player]
	if not data or not dataStore then
		return
	end

	local key = "Player_" .. player.UserId
	local ok, err = pcall(function()
		dataStore:SetAsync(key, data)
	end)

	if not ok then
		warn("[DataService] Failed to save data for " .. player.Name .. ": " .. tostring(err))
	end
end

function DataService:SaveAllData()
	for player, _ in pairs(playerData) do
		self:SaveData(player)
	end
end

function DataService:GetData(player)
	return playerData[player]
end

function DataService:UpdateData(player, key, value)
	local data = playerData[player]
	if data then
		data[key] = value
	end
end

function DataService:IncrementKisses(player, amount)
	local data = playerData[player]
	if not data then
		return
	end
	data.TotalKisses = data.TotalKisses + (amount or 1)
end

function DataService:AddCoins(player, amount)
	local data = playerData[player]
	if not data then
		return
	end
	data.CoinsEarned = data.CoinsEarned + amount
end

function DataService:UpdateCombo(player, combo)
	local data = playerData[player]
	if not data then
		return
	end
	if combo > data.HighestCombo then
		data.HighestCombo = combo
	end
end

function DataService:RecordKiss(player, characterName)
	local data = playerData[player]
	if not data then
		return
	end

	-- Update kiss history
	if not data.KissHistory[characterName] then
		data.KissHistory[characterName] = 0
	end
	data.KissHistory[characterName] = data.KissHistory[characterName] + 1

	-- Update favorite character
	local maxKisses = 0
	local favorite = ""
	for name, count in pairs(data.KissHistory) do
		if count > maxKisses then
			maxKisses = count
			favorite = name
		end
	end
	data.FavoriteCharacter = favorite
end

function DataService:GetDefaultData()
	local data = {}
	for key, value in pairs(DATA_TEMPLATE) do
		if type(value) == "table" then
			data[key] = {}
		else
			data[key] = value
		end
	end
	return data
end

return DataService
