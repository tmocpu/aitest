-- UIController: Base controller + HUD (coins, leaderboard button, combo)
-- Design: chunky cartoony, rounded corners, bold fonts, bouncy tweens

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

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

-- Extra tween infos
local POPUP_SCALE_IN = TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local POPUP_FLOAT = TweenInfo.new(1.0, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local POPUP_FADE = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local BANNER_SLIDE_IN = TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local BANNER_SLIDE_OUT = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In)
local MILESTONE_IN = TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local MILESTONE_OUT = TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In)

-- Rainbow colors for super kiss popup
local RAINBOW = {
	Color3.fromRGB(255, 60, 60),
	Color3.fromRGB(255, 160, 40),
	Color3.fromRGB(255, 230, 50),
	Color3.fromRGB(60, 220, 90),
	Color3.fromRGB(60, 170, 255),
	Color3.fromRGB(180, 80, 255),
	Color3.fromRGB(255, 60, 180),
}

-- Refs
local screenGui = nil
local coinLabel = nil
local comboFrame = nil
local comboLabel = nil
local leaderboardOpen = false
local comboBannerFrame = nil
local comboBannerLabel = nil
local comboBannerHideThread = nil
local milestoneBanner = nil
local milestoneLabel = nil
local milestoneHideThread = nil

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

---------------------------------------------------------------------------
-- 3. Kiss Popup (screen-space, floats up and fades, then self-destructs)
---------------------------------------------------------------------------

function UIController:SpawnKissPopup(characterWorldPos, coins, isSuper)
	if not screenGui then return end

	local camera = Workspace.CurrentCamera
	if not camera then return end

	local screenPos, onScreen = camera:WorldToViewportPoint(characterWorldPos + Vector3.new(0, 4, 0))
	if not onScreen then return end

	-- Container frame for both shadow and main label
	local container = Instance.new("Frame")
	container.Name = "KissPopup"
	container.Size = UDim2.new(0, 240, 0, 40)
	container.AnchorPoint = Vector2.new(0.5, 1)
	container.Position = UDim2.new(0, screenPos.X, 0, screenPos.Y)
	container.BackgroundTransparency = 1
	container.Parent = screenGui

	-- UIScale for pop-in animation
	local uiScale = Instance.new("UIScale")
	uiScale.Scale = 0
	uiScale.Parent = container

	-- Text content
	local text = "+" .. tostring(coins) .. " coins"
	local fontSize = 20
	if isSuper then
		text = "+" .. tostring(coins) .. " SUPER KISS!!"
		fontSize = 26
	end

	-- Drop shadow label (offset 2,2, black 50% transparency)
	local shadowLabel = Instance.new("TextLabel")
	shadowLabel.Name = "Shadow"
	shadowLabel.Size = UDim2.new(1, 0, 1, 0)
	shadowLabel.Position = UDim2.new(0, 2, 0, 2)
	shadowLabel.BackgroundTransparency = 1
	shadowLabel.Text = text
	shadowLabel.TextColor3 = Color3.fromRGB(0, 0, 0)
	shadowLabel.TextTransparency = 0.5
	shadowLabel.Font = Enum.Font.GothamBold
	shadowLabel.TextSize = fontSize
	shadowLabel.Parent = container

	-- Main text label
	local mainLabel = Instance.new("TextLabel")
	mainLabel.Name = "Main"
	mainLabel.Size = UDim2.new(1, 0, 1, 0)
	mainLabel.BackgroundTransparency = 1
	mainLabel.Text = text
	mainLabel.TextColor3 = YELLOW
	mainLabel.TextTransparency = 0
	mainLabel.Font = Enum.Font.GothamBold
	mainLabel.TextSize = fontSize
	mainLabel.Parent = container

	-- Phase 1: Scale pop-in 0→1 (0.2s Back easing)
	local scaleIn = TweenService:Create(uiScale, POPUP_SCALE_IN, { Scale = 1 })
	scaleIn:Play()

	-- Phase 2: Float up 80px over 1s
	local floatTarget = UDim2.new(0, screenPos.X, 0, screenPos.Y - 80)
	local floatTween = TweenService:Create(container, POPUP_FLOAT, { Position = floatTarget })

	scaleIn.Completed:Connect(function()
		floatTween:Play()
	end)

	-- Super kiss: rainbow color cycle during float
	if isSuper then
		task.spawn(function()
			local idx = 1
			local colorInfo = TweenInfo.new(0.12, Enum.EasingStyle.Linear)
			while container.Parent do
				local nextColor = RAINBOW[idx]
				TweenService:Create(mainLabel, colorInfo, { TextColor3 = nextColor }):Play()
				idx = idx % #RAINBOW + 1
				task.wait(0.12)
			end
		end)
	end

	-- Phase 3: Fade out TextTransparency 0→1 over 0.3s, then destroy
	floatTween.Completed:Connect(function()
		local fadeMain = TweenService:Create(mainLabel, POPUP_FADE, { TextTransparency = 1 })
		local fadeShadow = TweenService:Create(shadowLabel, POPUP_FADE, { TextTransparency = 1 })
		fadeMain:Play()
		fadeShadow:Play()
		fadeMain.Completed:Connect(function()
			container:Destroy()
		end)
	end)
end

---------------------------------------------------------------------------
-- 4. Combo Banner (center screen, slides in from top, auto-hides)
---------------------------------------------------------------------------

local function buildComboBanner()
	comboBannerFrame = Instance.new("Frame")
	comboBannerFrame.Name = "ComboBanner"
	comboBannerFrame.Size = UDim2.new(0, 400, 0, 70)
	comboBannerFrame.AnchorPoint = Vector2.new(0.5, 0)
	comboBannerFrame.Position = UDim2.new(0.5, 0, 0, -100) -- offscreen above
	comboBannerFrame.BackgroundColor3 = SKY_BLUE
	comboBannerFrame.BorderSizePixel = 0
	comboBannerFrame.Visible = false
	comboBannerFrame.ZIndex = 5
	comboBannerFrame.Parent = screenGui
	corner(comboBannerFrame)
	shadow(comboBannerFrame)

	comboBannerLabel = Instance.new("TextLabel")
	comboBannerLabel.Name = "BannerText"
	comboBannerLabel.Size = UDim2.new(1, 0, 1, 0)
	comboBannerLabel.BackgroundTransparency = 1
	comboBannerLabel.Text = ""
	comboBannerLabel.TextColor3 = WHITE
	comboBannerLabel.Font = Enum.Font.GothamBold
	comboBannerLabel.TextSize = 30
	comboBannerLabel.ZIndex = 6
	comboBannerLabel.TextStrokeTransparency = 1
	comboBannerLabel.Parent = comboBannerFrame
end

function UIController:ShowComboBanner(comboCount)
	if not screenGui then return end

	-- Build banner lazily on first use
	if not comboBannerFrame then
		buildComboBanner()
	end

	-- Update text
	comboBannerLabel.Text = tostring(comboCount) .. "x COMBO!!"

	-- Color shift based on count
	if comboCount >= 10 then
		comboBannerLabel.TextColor3 = Color3.fromHex("#FF3030")
		comboBannerLabel.TextStrokeColor3 = WHITE
		comboBannerLabel.TextStrokeTransparency = 0
	elseif comboCount >= 5 then
		comboBannerLabel.TextColor3 = Color3.fromHex("#FF9500")
		comboBannerLabel.TextStrokeTransparency = 1
	else
		comboBannerLabel.TextColor3 = WHITE
		comboBannerLabel.TextStrokeTransparency = 1
	end

	-- Slide in: Y=-100 → Y=15% of screen
	comboBannerFrame.Visible = true
	comboBannerFrame.Position = UDim2.new(0.5, 0, 0, -100)
	local targetY = UDim2.new(0.5, 0, 0.15, 0)
	TweenService:Create(comboBannerFrame, BANNER_SLIDE_IN, { Position = targetY }):Play()

	-- Cancel existing hide timer if visible (reset the 1.5s)
	if comboBannerHideThread then
		task.cancel(comboBannerHideThread)
		comboBannerHideThread = nil
	end

	-- Auto-hide after 1.5s
	comboBannerHideThread = task.delay(1.5, function()
		comboBannerHideThread = nil
		local slideOut = TweenService:Create(comboBannerFrame, BANNER_SLIDE_OUT, {
			Position = UDim2.new(0.5, 0, 0, -100),
		})
		slideOut:Play()
		slideOut.Completed:Connect(function()
			comboBannerFrame.Visible = false
		end)
	end)
end

---------------------------------------------------------------------------
-- 5. Milestone Banner (full width, slides down from top, holds 3s)
---------------------------------------------------------------------------

local function buildMilestoneBanner()
	milestoneBanner = Instance.new("Frame")
	milestoneBanner.Name = "MilestoneBanner"
	milestoneBanner.Size = UDim2.new(1, 0, 0, 80)
	milestoneBanner.AnchorPoint = Vector2.new(0, 0)
	milestoneBanner.Position = UDim2.new(0, 0, 0, -80) -- offscreen above
	milestoneBanner.BorderSizePixel = 0
	milestoneBanner.Visible = false
	milestoneBanner.ZIndex = 8
	milestoneBanner.Parent = screenGui

	-- Gradient background: hot pink → yellow, left to right
	milestoneBanner.BackgroundColor3 = WHITE
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new(HOT_PINK, YELLOW)
	gradient.Rotation = 0
	gradient.Parent = milestoneBanner

	shadow(milestoneBanner)

	milestoneLabel = Instance.new("TextLabel")
	milestoneLabel.Name = "MilestoneText"
	milestoneLabel.Size = UDim2.new(1, -32, 1, 0)
	milestoneLabel.Position = UDim2.new(0, 16, 0, 0)
	milestoneLabel.BackgroundTransparency = 1
	milestoneLabel.Text = ""
	milestoneLabel.TextColor3 = WHITE
	milestoneLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	milestoneLabel.TextStrokeTransparency = 0.3
	milestoneLabel.Font = Enum.Font.GothamBold
	milestoneLabel.TextSize = 22
	milestoneLabel.TextWrapped = true
	milestoneLabel.ZIndex = 9
	milestoneLabel.Parent = milestoneBanner
end

function UIController:ShowMilestone(characterName, milestoneCount)
	if not screenGui then return end

	-- Build banner lazily on first use
	if not milestoneBanner then
		buildMilestoneBanner()
	end

	milestoneLabel.Text = "\xF0\x9F\x92\x8B " .. characterName .. " was kissed " .. tostring(milestoneCount) .. " times!!"

	-- Slide down from Y=-80 to Y=0
	milestoneBanner.Visible = true
	milestoneBanner.Position = UDim2.new(0, 0, 0, -80)
	TweenService:Create(milestoneBanner, MILESTONE_IN, {
		Position = UDim2.new(0, 0, 0, 0),
	}):Play()

	-- Cancel existing hide timer
	if milestoneHideThread then
		task.cancel(milestoneHideThread)
		milestoneHideThread = nil
	end

	-- Hold 3s then slide back up
	milestoneHideThread = task.delay(3, function()
		milestoneHideThread = nil
		local slideOut = TweenService:Create(milestoneBanner, MILESTONE_OUT, {
			Position = UDim2.new(0, 0, 0, -80),
		})
		slideOut:Play()
		slideOut.Completed:Connect(function()
			milestoneBanner.Visible = false
		end)
	end)
end

function UIController:GetScreenGui()
	return screenGui
end

return UIController
