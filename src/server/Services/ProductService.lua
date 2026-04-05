-- ProductService: Handles repeatable developer product purchases
-- Receipt deduplication via DataStore, retry logic, product handlers

local MarketplaceService = game:GetService("MarketplaceService")
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Modules"):WaitForChild("Config"))

local ProductService = {}
ProductService.__index = ProductService

-- Cross-service refs
local DataService = nil
local RemoteService = nil
local KissService = nil
local GamepassService = nil

-- Receipt log DataStore for deduplication
local receiptStore = nil

-- Product ID → handler mapping (built in :Init)
local productHandlers = {}

---------------------------------------------------------------------------
-- Receipt Deduplication
---------------------------------------------------------------------------

local function isReceiptProcessed(purchaseId)
	if not receiptStore then return false end
	local ok, result = pcall(function()
		return receiptStore:GetAsync("Receipt_" .. purchaseId)
	end)
	return ok and result == true
end

local function markReceiptProcessed(purchaseId)
	if not receiptStore then return end
	pcall(function()
		receiptStore:SetAsync("Receipt_" .. purchaseId, true)
	end)
end

---------------------------------------------------------------------------
-- Product Handlers
---------------------------------------------------------------------------

local function handleCoinPurchase(player, amount)
	if not DataService then return false end
	DataService:AddCoins(player, amount)

	if RemoteService then
		local data = DataService:GetData(player)
		if data then
			RemoteService:FireClient("CoinsUpdate", player, data.CoinsEarned)
		end
	end

	return true
end

local function handleComboBoost(player)
	if not GamepassService or not RemoteService then return false end

	-- Activate 10x combo boost for 30 seconds
	GamepassService:SetComboBoost(player, true)

	-- Notify client
	RemoteService:FireClient("ComboUpdate", player, Config.COMBO_BOOST_MULTIPLIER, Config.COMBO_BOOST_MULTIPLIER)

	-- Deactivate after duration
	task.delay(Config.COMBO_BOOST_DURATION, function()
		GamepassService:SetComboBoost(player, false)
		if RemoteService and player.Parent then
			RemoteService:FireClient("ComboUpdate", player, 0, 1)
		end
	end)

	return true
end

local function handleKissStorm(player)
	if not KissService then return false end

	local Workspace = game:GetService("Workspace")
	local npcsFolder = Workspace:FindFirstChild("NPCs")
	if not npcsFolder then return false end

	-- Kiss all characters with 0.3s delay between each
	task.spawn(function()
		for _, model in ipairs(npcsFolder:GetChildren()) do
			if model:IsA("Model") then
				local nameVal = model:FindFirstChild("CharacterName")
				if nameVal and nameVal:IsA("StringValue") then
					pcall(function()
						KissService:ProcessKiss(player, nameVal.Value)
					end)
					task.wait(0.3)
				end
			end
		end
	end)

	return true
end

---------------------------------------------------------------------------
-- ProcessReceipt callback
---------------------------------------------------------------------------

local function processReceipt(receiptInfo)
	local playerId = receiptInfo.PlayerId
	local purchaseId = receiptInfo.PurchaseId
	local productId = receiptInfo.ProductId

	-- Check for duplicate receipt
	if isReceiptProcessed(purchaseId) then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	-- Find the player
	local player = Players:GetPlayerByUserId(playerId)
	if not player then
		-- Player left; grant anyway to avoid blocking future purchases
		markReceiptProcessed(purchaseId)
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	-- Find handler
	local handler = productHandlers[productId]
	if not handler then
		warn("[ProductService] Unknown product ID: " .. tostring(productId))
		markReceiptProcessed(purchaseId)
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	-- Execute handler with retry (up to 3 attempts)
	local success = false
	for attempt = 1, 3 do
		local ok, result = pcall(handler, player)
		if ok and result then
			success = true
			break
		end
		if attempt < 3 then
			task.wait(0.5)
		end
	end

	-- Always mark as processed and grant to avoid stuck receipts
	markReceiptProcessed(purchaseId)
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

---------------------------------------------------------------------------
-- Service Interface
---------------------------------------------------------------------------

function ProductService:Init()
	-- Receipt log DataStore
	local ok, store = pcall(function()
		return DataStoreService:GetDataStore("ReceiptLog_v1")
	end)
	if ok then
		receiptStore = store
	else
		warn("[ProductService] Failed to get receipt DataStore: " .. tostring(store))
	end

	-- Register product handlers
	productHandlers[Config.PRODUCT_COIN_SMALL] = function(player)
		return handleCoinPurchase(player, Config.COIN_SMALL_AMOUNT)
	end
	productHandlers[Config.PRODUCT_COIN_MEDIUM] = function(player)
		return handleCoinPurchase(player, Config.COIN_MEDIUM_AMOUNT)
	end
	productHandlers[Config.PRODUCT_COIN_LARGE] = function(player)
		return handleCoinPurchase(player, Config.COIN_LARGE_AMOUNT)
	end
	productHandlers[Config.PRODUCT_COMBO_BOOST] = function(player)
		return handleComboBoost(player)
	end
	productHandlers[Config.PRODUCT_KISS_STORM] = function(player)
		return handleKissStorm(player)
	end

	-- Hook ProcessReceipt
	MarketplaceService.ProcessReceipt = processReceipt
end

function ProductService:Start()
	print("[ProductService] loaded")
end

function ProductService:SetServices(dataService, remoteService, kissService, gamepassService)
	DataService = dataService
	RemoteService = remoteService
	KissService = kissService
	GamepassService = gamepassService
end

return ProductService
