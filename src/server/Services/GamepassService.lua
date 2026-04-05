-- GamepassService: Manages gamepass ownership with retry, instant activation
-- Effects applied by KissService, WorldService, and auto-kiss loop

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Modules"):WaitForChild("Config"))

local GamepassService = {}
GamepassService.__index = GamepassService

-- { [player] = { DOUBLE_COINS = bool, VIP_AURA = bool, AUTO_KISS = bool, LUCKY_LIPS = bool } }
local ownership = {}

-- Combo boost state (set by ProductService)
local comboBoosts = {} -- { [player] = { active = bool, expiry = number } }

-- Cross-service refs (set via :SetServices)
local KissService = nil
local CharacterService = nil
local RemoteService = nil
local DataService = nil

-- All gamepass definitions: internal name -> Config key
local PASS_DEFS = {
	{ name = "DOUBLE_COINS", configKey = "GAMEPASS_DOUBLE_COINS" },
	{ name = "VIP_AURA",     configKey = "GAMEPASS_VIP_AURA" },
	{ name = "AUTO_KISS",    configKey = "GAMEPASS_AUTO_KISS" },
	{ name = "LUCKY_LIPS",   configKey = "GAMEPASS_LUCKY_LIPS" },
}

---------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------

local function checkOwnership(player, gamepassId)
	-- Retry up to 3 times with pcall
	for attempt = 1, 3 do
		local ok, owns = pcall(function()
			return MarketplaceService:UserOwnsGamePassAsync(player.UserId, gamepassId)
		end)
		if ok then
			return owns
		end
		if attempt < 3 then
			task.wait(1)
		end
	end
	return false
end

local function loadAllPasses(player)
	local data = {}
	for _, def in ipairs(PASS_DEFS) do
		local id = Config[def.configKey]
		if id and id ~= 0 then
			data[def.name] = checkOwnership(player, id)
		else
			data[def.name] = false
		end
	end
	ownership[player] = data
end

---------------------------------------------------------------------------
-- VIP Aura (gold ring + PointLight on character)
---------------------------------------------------------------------------

local vipAuras = {} -- [player] = { ring, light, conn }

local function applyVIPAura(player)
	local character = player.Character
	if not character then return end
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	-- Already has aura
	if vipAuras[player] then return end

	-- Gold ring part
	local ring = Instance.new("Part")
	ring.Name = "VIPAuraRing"
	ring.Shape = Enum.PartType.Cylinder
	ring.Size = Vector3.new(0.3, 5, 5)
	ring.Color = Color3.fromHex("#FFD700")
	ring.Material = Enum.Material.Neon
	ring.Anchored = false
	ring.CanCollide = false
	ring.CastShadow = false
	ring.Massless = true
	ring.Transparency = 0.3
	ring.Parent = character

	-- Weld ring to HRP
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = hrp
	weld.Part1 = ring
	weld.Parent = ring
	ring.CFrame = hrp.CFrame * CFrame.Angles(0, 0, math.rad(90)) * CFrame.new(0, -2, 0)

	-- PointLight
	local light = Instance.new("PointLight")
	light.Name = "VIPAuraLight"
	light.Color = Color3.fromHex("#FFD700")
	light.Brightness = 1.5
	light.Range = 12
	light.Shadows = false
	light.Parent = hrp

	-- Slow rotation via Heartbeat
	local rotAngle = 0
	local conn = RunService.Heartbeat:Connect(function(dt)
		if not ring.Parent then return end
		rotAngle = rotAngle + dt * 0.8
		ring.CFrame = hrp.CFrame * CFrame.Angles(0, rotAngle, math.rad(90)) * CFrame.new(0, -2, 0)
	end)

	vipAuras[player] = { ring = ring, light = light, conn = conn }
end

local function removeVIPAura(player)
	local aura = vipAuras[player]
	if aura then
		if aura.conn then aura.conn:Disconnect() end
		if aura.ring and aura.ring.Parent then aura.ring:Destroy() end
		if aura.light and aura.light.Parent then aura.light:Destroy() end
		vipAuras[player] = nil
	end
end

---------------------------------------------------------------------------
-- Auto Kiss loop
---------------------------------------------------------------------------

local autoKissConns = {} -- [player] = thread

local function startAutoKiss(player)
	if autoKissConns[player] then return end

	autoKissConns[player] = task.spawn(function()
		while player.Parent do
			task.wait(Config.AUTO_KISS_INTERVAL)

			if not KissService or not CharacterService then continue end

			local character = player.Character
			if not character then continue end
			local hrp = character:FindFirstChild("HumanoidRootPart")
			if not hrp then continue end

			-- Find closest NPC within AUTO_KISS_RANGE
			local npcsFolder = Workspace:FindFirstChild("NPCs")
			if not npcsFolder then continue end

			local closestName = nil
			local closestDist = Config.AUTO_KISS_RANGE + 1

			for _, model in ipairs(npcsFolder:GetChildren()) do
				if model:IsA("Model") then
					local nameVal = model:FindFirstChild("CharacterName")
					local npcRoot = model.PrimaryPart or model:FindFirstChild("HumanoidRootPart")
					if nameVal and npcRoot then
						local dist = (hrp.Position - npcRoot.Position).Magnitude
						if dist < closestDist and dist <= Config.AUTO_KISS_RANGE then
							closestDist = dist
							closestName = nameVal.Value
						end
					end
				end
			end

			if closestName then
				-- Process through normal pipeline (still subject to rate limiter)
				pcall(function()
					KissService:HandleKissRequest(player, closestName)
				end)
			end
		end
	end)
end

local function stopAutoKiss(player)
	local thread = autoKissConns[player]
	if thread then
		task.cancel(thread)
		autoKissConns[player] = nil
	end
end

---------------------------------------------------------------------------
-- Service Interface
---------------------------------------------------------------------------

function GamepassService:Init()
	-- Listen for purchases completing (instant activation)
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamepassId, purchased)
		if not purchased then return end

		local data = ownership[player]
		if not data then return end

		for _, def in ipairs(PASS_DEFS) do
			if Config[def.configKey] == gamepassId then
				data[def.name] = true

				-- Activate immediately
				if def.name == "VIP_AURA" then
					pcall(applyVIPAura, player)
				elseif def.name == "AUTO_KISS" then
					startAutoKiss(player)
				end

				break
			end
		end
	end)
end

function GamepassService:Start()
	-- Load passes for all current and future players
	Players.PlayerAdded:Connect(function(player)
		loadAllPasses(player)

		-- Apply VIP aura on spawn if owned
		if self:HasPass(player, "VIP_AURA") then
			player.CharacterAdded:Connect(function()
				task.wait(0.5) -- wait for character to load
				pcall(applyVIPAura, player)
			end)
			if player.Character then
				pcall(applyVIPAura, player)
			end
		end

		-- Start auto-kiss if owned
		if self:HasPass(player, "AUTO_KISS") then
			startAutoKiss(player)
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		ownership[player] = nil
		comboBoosts[player] = nil
		removeVIPAura(player)
		stopAutoKiss(player)
	end)

	-- Load for already-connected players
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(function()
			loadAllPasses(player)
			if self:HasPass(player, "VIP_AURA") and player.Character then
				pcall(applyVIPAura, player)
			end
			if self:HasPass(player, "AUTO_KISS") then
				startAutoKiss(player)
			end
		end)
	end

	print("[GamepassService] loaded")
end

function GamepassService:SetServices(kissService, characterService, remoteService, dataService)
	KissService = kissService
	CharacterService = characterService
	RemoteService = remoteService
	DataService = dataService
end

function GamepassService:HasPass(player, passName)
	local data = ownership[player]
	if not data then return false end
	return data[passName] == true
end

-- Combo boost state (used by ProductService, read by KissService)
function GamepassService:SetComboBoost(player, active)
	comboBoosts[player] = {
		active = active,
		expiry = active and (tick() + Config.COMBO_BOOST_DURATION) or 0,
	}
end

function GamepassService:HasComboBoost(player)
	local boost = comboBoosts[player]
	if not boost or not boost.active then return false end
	if tick() > boost.expiry then
		boost.active = false
		return false
	end
	return true
end

return GamepassService
