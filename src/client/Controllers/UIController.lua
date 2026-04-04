-- UIController: Base controller + HUD (coins, leaderboard button, combo)
-- Design: chunky cartoony, rounded corners, bold fonts, bouncy tweens

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

local UIController = {}

-- Colors
local HOT_PINK = Color3.fromHex("#FF6EB4")
local YELLOW = Color3.fromHex("#FFE44D")
local SKY_BLUE = Color3.fromHex("#6EC6FF")
local MINT = Color3.fromHex("#6EFFB4")
local WHITE = Color3.fromRGB(255, 255, 255)

-- Tween infos
local ANIM_IN = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local ANIM_OUT = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In)
local POP = TweenInfo.new(0.1, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local POP_RETURN = TweenInfo.new(0.1, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

-- Refs
local screenGui = nil
local coinLabel = nil
local comboFrame = nil
local comboLabel = nil
local leaderboardOpen = false

-- State
local displayedCoins = 0
local currentCombo = 0
local comboVisible = false

---------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------

local function corner(parent)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0.12, 0)
	c.Parent = parent
	return c
end

local function shadow(parent)
	local s = Instance.new("UIStroke")
	s.Color = Color3.fromRGB(0, 0, 0)
	s.Thickness = 3
	s.Transparency = 0.7
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = parent
	return s
end

function UIController.animateIn(frame)
	frame.Visible = true
	frame.AnchorPoint = frame.AnchorPoint -- keep existing
	-- Scale from 0 to 1 via UIScale
	local uiScale = frame:FindFirstChildOfClass("UIScale")
	if not uiScale then
		uiScale = Instance.new("UIScale")
		uiScale.Parent = frame
	end
	uiScale.Scale = 0
	TweenService:Create(uiScale, ANIM_IN, { Scale = 1 }):Play()
end

function UIController.animateOut(frame)
	local uiScale = frame:FindFirstChildOfClass("UIScale")
	if not uiScale then
		uiScale = Instance.new("UIScale")
		uiScale.Scale = 1
		uiScale.Parent = frame
	end
	local tween = TweenService:Create(uiScale, ANIM_OUT, { Scale = 0 })
	tween:Play()
	tween.Completed:Connect(function()
		frame.Visible = false
	end)
end

local function popScale(frame)
	local uiScale = frame:FindFirstChildOfClass("UIScale")
	if not uiScale then
		uiScale = Instance.new("UIScale")
		uiScale.Scale = 1
		uiScale.Parent = frame
	end
	local up = TweenService:Create(uiScale, POP, { Scale = 1.3 })
	up:Play()
	up.Completed:Connect(function()
		TweenService:Create(uiScale, POP_RETURN, { Scale = 1 }):Play()
	end)
end

local function comboPopScale()
	if not comboFrame then return end
	local uiScale = comboFrame:FindFirstChildOfClass("UIScale")
	if not uiScale then
		uiScale = Instance.new("UIScale")
		uiScale.Scale = 1
		uiScale.Parent = comboFrame
	end
	local up = TweenService:Create(uiScale, POP, { Scale = 1.2 })
	up:Play()
	up.Completed:Connect(function()
		TweenService:Create(uiScale, POP_RETURN, { Scale = 1 }):Play()
	end)
end

---------------------------------------------------------------------------
-- Build HUD
---------------------------------------------------------------------------

local function buildCoinDisplay()
	local frame = Instance.new("Frame")
	frame.Name = "CoinDisplay"
	frame.Size = UDim2.new(0, 180, 0, 50)
	frame.Position = UDim2.new(0, 16, 0, 16)
	frame.BackgroundColor3 = HOT_PINK
	frame.BorderSizePixel = 0
	frame.Parent = screenGui
	corner(frame)
	shadow(frame)

	-- Coin icon: yellow circle placeholder
	local icon = Instance.new("Frame")
	icon.Name = "CoinIcon"
	icon.Size = UDim2.new(0, 34, 0, 34)
	icon.Position = UDim2.new(0, 8, 0.5, -17)
	icon.BackgroundColor3 = YELLOW
	icon.BorderSizePixel = 0
	icon.Parent = frame

	local iconCorner = Instance.new("UICorner")
	iconCorner.CornerRadius = UDim.new(0.5, 0)
	iconCorner.Parent = icon

	local dollarSign = Instance.new("TextLabel")
	dollarSign.Name = "Dollar"
	dollarSign.Size = UDim2.new(1, 0, 1, 0)
	dollarSign.BackgroundTransparency = 1
	dollarSign.Text = "$"
	dollarSign.TextColor3 = HOT_PINK
	dollarSign.Font = Enum.Font.GothamBold
	dollarSign.TextSize = 20
	dollarSign.Parent = icon

	-- Coin count label
	coinLabel = Instance.new("TextLabel")
	coinLabel.Name = "CoinCount"
	coinLabel.Size = UDim2.new(1, -52, 1, 0)
	coinLabel.Position = UDim2.new(0, 48, 0, 0)
	coinLabel.BackgroundTransparency = 1
	coinLabel.Text = "0"
	coinLabel.TextColor3 = WHITE
	coinLabel.Font = Enum.Font.GothamBold
	coinLabel.TextSize = 22
	coinLabel.TextXAlignment = Enum.TextXAlignment.Left
	coinLabel.Parent = frame

	return frame
end

local function buildLeaderboardButton()
	local btn = Instance.new("TextButton")
	btn.Name = "LeaderboardButton"
	btn.Size = UDim2.new(0, 50, 0, 50)
	btn.Position = UDim2.new(1, -66, 0, 16)
	btn.BackgroundColor3 = YELLOW
	btn.BorderSizePixel = 0
	btn.Text = "\xF0\x9F\x91\x91"
	btn.TextSize = 28
	btn.Font = Enum.Font.GothamBold
	btn.AutoButtonColor = false
	btn.Parent = screenGui
	corner(btn)
	shadow(btn)

	-- Hover / press feedback
	btn.MouseEnter:Connect(function()
		TweenService:Create(btn, POP, { BackgroundColor3 = Color3.fromHex("#FFD700") }):Play()
	end)
	btn.MouseLeave:Connect(function()
		TweenService:Create(btn, POP_RETURN, { BackgroundColor3 = YELLOW }):Play()
	end)
	btn.MouseButton1Click:Connect(function()
		popScale(btn)
		UIController.toggleLeaderboard()
	end)

	return btn
end

local function buildComboDisplay()
	comboFrame = Instance.new("Frame")
	comboFrame.Name = "ComboDisplay"
	comboFrame.Size = UDim2.new(0, 200, 0, 60)
	comboFrame.AnchorPoint = Vector2.new(0.5, 1)
	comboFrame.Position = UDim2.new(0.5, 0, 1, -20)
	comboFrame.BackgroundColor3 = MINT
	comboFrame.BorderSizePixel = 0
	comboFrame.Visible = false
	comboFrame.Parent = screenGui
	corner(comboFrame)
	shadow(comboFrame)

	-- Pre-set UIScale to 0 so animateIn works
	local uiScale = Instance.new("UIScale")
	uiScale.Scale = 0
	uiScale.Parent = comboFrame

	comboLabel = Instance.new("TextLabel")
	comboLabel.Name = "ComboText"
	comboLabel.Size = UDim2.new(1, 0, 1, 0)
	comboLabel.BackgroundTransparency = 1
	comboLabel.Text = "2x COMBO!!"
	comboLabel.TextColor3 = Color3.fromRGB(30, 30, 30)
	comboLabel.Font = Enum.Font.GothamBold
	comboLabel.TextSize = 24
	comboLabel.Parent = comboFrame

	return comboFrame
end

---------------------------------------------------------------------------
-- Public API
---------------------------------------------------------------------------

function UIController:Init()
	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "BrainrotHUD"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.IgnoreGuiInset = true
	screenGui.Parent = player:WaitForChild("PlayerGui")

	buildCoinDisplay()
	buildLeaderboardButton()
	buildComboDisplay()
end

function UIController:Start()
	local remotesFolder = ReplicatedStorage:WaitForChild("Remotes", 15)
	if not remotesFolder then
		warn("[UIController] Remotes folder not found")
		return
	end

	-- KissReaction: pop the coin counter (coins added externally via :AddCoins)
	local kissReaction = remotesFolder:FindFirstChild("KissReaction")
	if kissReaction then
		kissReaction.OnClientEvent:Connect(function(_characterName, _reactionType, _globalCount)
			-- Coin amount is handled by :AddCoins called from Init.client.lua
		end)
	end

	-- ComboUpdate
	local comboUpdate = remotesFolder:FindFirstChild("ComboUpdate")
	if comboUpdate then
		comboUpdate.OnClientEvent:Connect(function(comboCount, _multiplier)
			self:SetCombo(comboCount)
		end)
	end

	-- SuperKissEvent
	local superKiss = remotesFolder:FindFirstChild("SuperKissEvent")
	if superKiss then
		superKiss.OnClientEvent:Connect(function(_characterName, _coinsAwarded)
			-- Super kiss visuals handled by other controllers;
			-- coin addition handled via :AddCoins
		end)
	end

	-- LeaderboardUpdate
	local lbUpdate = remotesFolder:FindFirstChild("LeaderboardUpdate")
	if lbUpdate then
		lbUpdate.OnClientEvent:Connect(function(topKissers)
			self:UpdateLeaderboard(topKissers)
		end)
	end

	-- MilestoneAnnouncement
	local milestone = remotesFolder:FindFirstChild("MilestoneAnnouncement")
	if milestone then
		milestone.OnClientEvent:Connect(function(characterName, milestoneCount)
			self:ShowMilestone(characterName, milestoneCount)
		end)
	end
end

function UIController:AddCoins(amount)
	displayedCoins = displayedCoins + amount

	if coinLabel then
		coinLabel.Text = tostring(displayedCoins)
		popScale(coinLabel)
	end
end

function UIController:SetCombo(count)
	currentCombo = count

	if count >= 2 then
		if comboLabel then
			comboLabel.Text = tostring(count) .. "x COMBO!!"
		end

		if not comboVisible then
			comboVisible = true
			UIController.animateIn(comboFrame)
		else
			comboPopScale()
		end
	elseif count <= 0 then
		if comboVisible then
			comboVisible = false
			UIController.animateOut(comboFrame)
		end
	end
end

function UIController.toggleLeaderboard()
	leaderboardOpen = not leaderboardOpen
	-- Leaderboard panel built in a later phase; this is the hook point
end

function UIController:UpdateLeaderboard(_topKissers)
	-- Leaderboard panel built in a later phase
end

function UIController:ShowMilestone(_characterName, _milestoneCount)
	-- Milestone banner built in a later phase
end

function UIController:GetScreenGui()
	return screenGui
end

return UIController
