-- UIController: Full cartoony HUD with coins, combo, reactions, super kiss overlay, milestones
-- All UI is built from code - no external assets

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local UITheme = require(Shared:WaitForChild("Modules"):WaitForChild("UITheme"))
local TweenPresets = require(Shared:WaitForChild("Modules"):WaitForChild("TweenPresets"))
local Config = require(Shared:WaitForChild("Modules"):WaitForChild("Config"))

local player = Players.LocalPlayer

local UIController = {}
UIController.__index = UIController

local screenGui = nil
local coinLabel = nil
local comboFrame = nil
local comboLabel = nil
local comboMultLabel = nil
local reactionFrame = nil
local superOverlay = nil
local milestoneBar = nil
local totalKissLabel = nil
local coinCount = 0
local displayedCoinCount = 0

function UIController:Init()
	self:BuildScreenGui()
	self:BuildCoinDisplay()
	self:BuildComboDisplay()
	self:BuildReactionPopup()
	self:BuildSuperKissOverlay()
	self:BuildMilestoneBanner()
	self:BuildKissCounter()
end

function UIController:BuildScreenGui()
	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "BrainrotHUD"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.IgnoreGuiInset = true
	screenGui.Parent = player:WaitForChild("PlayerGui")
end

-- COIN DISPLAY (top-left) --
function UIController:BuildCoinDisplay()
	local frame = Instance.new("Frame")
	frame.Name = "CoinDisplay"
	frame.Size = UDim2.new(0, 220, 0, 60)
	frame.Position = UDim2.new(0, 20, 0, 60)
	frame.BackgroundColor3 = Color3.fromRGB(40, 25, 60)
	frame.BackgroundTransparency = 0.15
	frame.Parent = screenGui

	UITheme.Corner(frame, UITheme.CornerRadius.Large)
	UITheme.AddStroke(frame, Color3.fromRGB(255, 210, 50), 3, 0.2)
	UITheme.AddGradient(frame, "Dark", 90)

	-- Coin icon (circle)
	local coinIcon = Instance.new("Frame")
	coinIcon.Name = "CoinIcon"
	coinIcon.Size = UDim2.new(0, 40, 0, 40)
	coinIcon.Position = UDim2.new(0, 12, 0.5, -20)
	coinIcon.BackgroundColor3 = UITheme.Colors.Gold
	coinIcon.Parent = frame
	UITheme.Corner(coinIcon, UITheme.CornerRadius.Full)

	local coinSymbol = Instance.new("TextLabel")
	coinSymbol.Size = UDim2.new(1, 0, 1, 0)
	coinSymbol.BackgroundTransparency = 1
	coinSymbol.Text = "$"
	coinSymbol.TextColor3 = UITheme.Colors.GoldDark
	coinSymbol.Font = UITheme.Fonts.Title
	coinSymbol.TextSize = 26
	coinSymbol.Parent = coinIcon

	-- Coin count label
	coinLabel = Instance.new("TextLabel")
	coinLabel.Name = "CoinCount"
	coinLabel.Size = UDim2.new(1, -65, 1, 0)
	coinLabel.Position = UDim2.new(0, 60, 0, 0)
	coinLabel.BackgroundTransparency = 1
	coinLabel.Text = "0"
	coinLabel.TextColor3 = UITheme.Colors.Gold
	coinLabel.Font = UITheme.Fonts.Number
	coinLabel.TextSize = 32
	coinLabel.TextXAlignment = Enum.TextXAlignment.Left
	coinLabel.Parent = frame
end

-- COMBO DISPLAY (top-center) --
function UIController:BuildComboDisplay()
	comboFrame = Instance.new("Frame")
	comboFrame.Name = "ComboDisplay"
	comboFrame.Size = UDim2.new(0, 180, 0, 80)
	comboFrame.Position = UDim2.new(0.5, -90, 0, 55)
	comboFrame.BackgroundColor3 = Color3.fromRGB(30, 50, 80)
	comboFrame.BackgroundTransparency = 0.2
	comboFrame.Visible = false
	comboFrame.Parent = screenGui

	UITheme.Corner(comboFrame, UITheme.CornerRadius.Large)
	UITheme.AddStroke(comboFrame, UITheme.Colors.Combo, 3, 0.1)

	local comboTitle = Instance.new("TextLabel")
	comboTitle.Name = "ComboTitle"
	comboTitle.Size = UDim2.new(1, 0, 0, 22)
	comboTitle.Position = UDim2.new(0, 0, 0, 6)
	comboTitle.BackgroundTransparency = 1
	comboTitle.Text = "COMBO"
	comboTitle.TextColor3 = UITheme.Colors.ComboBright
	comboTitle.Font = UITheme.Fonts.Body
	comboTitle.TextSize = 16
	comboTitle.Parent = comboFrame

	comboLabel = Instance.new("TextLabel")
	comboLabel.Name = "ComboCount"
	comboLabel.Size = UDim2.new(0.5, 0, 0, 40)
	comboLabel.Position = UDim2.new(0, 10, 0, 28)
	comboLabel.BackgroundTransparency = 1
	comboLabel.Text = "1"
	comboLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	comboLabel.Font = UITheme.Fonts.Combo
	comboLabel.TextSize = 42
	comboLabel.TextXAlignment = Enum.TextXAlignment.Center
	comboLabel.Parent = comboFrame

	comboMultLabel = Instance.new("TextLabel")
	comboMultLabel.Name = "ComboMult"
	comboMultLabel.Size = UDim2.new(0.5, 0, 0, 30)
	comboMultLabel.Position = UDim2.new(0.5, 0, 0, 34)
	comboMultLabel.BackgroundTransparency = 1
	comboMultLabel.Text = "x1"
	comboMultLabel.TextColor3 = UITheme.Colors.Gold
	comboMultLabel.Font = UITheme.Fonts.Accent
	comboMultLabel.TextSize = 28
	comboMultLabel.TextXAlignment = Enum.TextXAlignment.Center
	comboMultLabel.Parent = comboFrame
end

-- REACTION POPUP (center screen, floats up and fades) --
function UIController:BuildReactionPopup()
	reactionFrame = Instance.new("Frame")
	reactionFrame.Name = "ReactionPopup"
	reactionFrame.Size = UDim2.new(0, 400, 0, 70)
	reactionFrame.Position = UDim2.new(0.5, -200, 0.55, 0)
	reactionFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	reactionFrame.BackgroundTransparency = 0.1
	reactionFrame.Visible = false
	reactionFrame.Parent = screenGui

	UITheme.Corner(reactionFrame, UITheme.CornerRadius.XLarge)
	UITheme.AddStroke(reactionFrame, UITheme.Colors.Accent, 3, 0.1)

	local charLabel = Instance.new("TextLabel")
	charLabel.Name = "CharName"
	charLabel.Size = UDim2.new(1, -20, 0, 24)
	charLabel.Position = UDim2.new(0, 10, 0, 6)
	charLabel.BackgroundTransparency = 1
	charLabel.Text = ""
	charLabel.TextColor3 = UITheme.Colors.Accent
	charLabel.Font = UITheme.Fonts.Title
	charLabel.TextSize = 20
	charLabel.TextXAlignment = Enum.TextXAlignment.Center
	charLabel.Parent = reactionFrame

	local reactionLabel = Instance.new("TextLabel")
	reactionLabel.Name = "ReactionText"
	reactionLabel.Size = UDim2.new(1, -20, 0, 30)
	reactionLabel.Position = UDim2.new(0, 10, 0, 32)
	reactionLabel.BackgroundTransparency = 1
	reactionLabel.Text = ""
	reactionLabel.TextColor3 = UITheme.Colors.Text
	reactionLabel.Font = UITheme.Fonts.Reaction
	reactionLabel.TextSize = 24
	reactionLabel.TextXAlignment = Enum.TextXAlignment.Center
	reactionLabel.Parent = reactionFrame
end

-- SUPER KISS OVERLAY (fullscreen flash) --
function UIController:BuildSuperKissOverlay()
	superOverlay = Instance.new("Frame")
	superOverlay.Name = "SuperKissOverlay"
	superOverlay.Size = UDim2.new(1, 0, 1, 0)
	superOverlay.BackgroundColor3 = UITheme.Colors.Super
	superOverlay.BackgroundTransparency = 1
	superOverlay.Visible = false
	superOverlay.ZIndex = 10
	superOverlay.Parent = screenGui

	local superLabel = Instance.new("TextLabel")
	superLabel.Name = "SuperLabel"
	superLabel.Size = UDim2.new(1, 0, 0, 120)
	superLabel.Position = UDim2.new(0, 0, 0.3, 0)
	superLabel.BackgroundTransparency = 1
	superLabel.Text = "SUPER KISS!"
	superLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	superLabel.TextStrokeColor3 = UITheme.Colors.Super
	superLabel.TextStrokeTransparency = 0
	superLabel.Font = UITheme.Fonts.Title
	superLabel.TextSize = 96
	superLabel.TextTransparency = 1
	superLabel.ZIndex = 11
	superLabel.Parent = superOverlay

	local coinsAwardedLabel = Instance.new("TextLabel")
	coinsAwardedLabel.Name = "CoinsAwarded"
	coinsAwardedLabel.Size = UDim2.new(1, 0, 0, 60)
	coinsAwardedLabel.Position = UDim2.new(0, 0, 0.45, 0)
	coinsAwardedLabel.BackgroundTransparency = 1
	coinsAwardedLabel.Text = ""
	coinsAwardedLabel.TextColor3 = UITheme.Colors.Gold
	coinsAwardedLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	coinsAwardedLabel.TextStrokeTransparency = 0.3
	coinsAwardedLabel.Font = UITheme.Fonts.Accent
	coinsAwardedLabel.TextSize = 48
	coinsAwardedLabel.TextTransparency = 1
	coinsAwardedLabel.ZIndex = 11
	coinsAwardedLabel.Parent = superOverlay
end

-- MILESTONE BANNER (slides in from top) --
function UIController:BuildMilestoneBanner()
	milestoneBar = Instance.new("Frame")
	milestoneBar.Name = "MilestoneBanner"
	milestoneBar.Size = UDim2.new(0, 500, 0, 70)
	milestoneBar.Position = UDim2.new(0.5, -250, 0, -80) -- starts offscreen
	milestoneBar.BackgroundColor3 = UITheme.Colors.MilestoneBg
	milestoneBar.Visible = false
	milestoneBar.ZIndex = 8
	milestoneBar.Parent = screenGui

	UITheme.Corner(milestoneBar, UITheme.CornerRadius.Large)
	UITheme.AddStroke(milestoneBar, UITheme.Colors.Gold, 3, 0)

	local icon = Instance.new("TextLabel")
	icon.Name = "Icon"
	icon.Size = UDim2.new(0, 50, 0, 50)
	icon.Position = UDim2.new(0, 10, 0.5, -25)
	icon.BackgroundTransparency = 1
	icon.Text = "\xE2\xAD\x90"
	icon.TextSize = 36
	icon.Font = Enum.Font.SourceSans
	icon.ZIndex = 9
	icon.Parent = milestoneBar

	local milestoneLabel = Instance.new("TextLabel")
	milestoneLabel.Name = "MilestoneText"
	milestoneLabel.Size = UDim2.new(1, -70, 1, 0)
	milestoneLabel.Position = UDim2.new(0, 65, 0, 0)
	milestoneLabel.BackgroundTransparency = 1
	milestoneLabel.Text = ""
	milestoneLabel.TextColor3 = UITheme.Colors.Text
	milestoneLabel.Font = UITheme.Fonts.Title
	milestoneLabel.TextSize = 22
	milestoneLabel.TextWrapped = true
	milestoneLabel.ZIndex = 9
	milestoneLabel.Parent = milestoneBar
end

-- KISS COUNTER (top-left below coins) --
function UIController:BuildKissCounter()
	local frame = Instance.new("Frame")
	frame.Name = "KissCounter"
	frame.Size = UDim2.new(0, 180, 0, 45)
	frame.Position = UDim2.new(0, 20, 0, 128)
	frame.BackgroundColor3 = Color3.fromRGB(50, 30, 70)
	frame.BackgroundTransparency = 0.2
	frame.Parent = screenGui

	UITheme.Corner(frame, UITheme.CornerRadius.Medium)
	UITheme.AddStroke(frame, UITheme.Colors.Accent, 2, 0.3)

	local kissIcon = Instance.new("TextLabel")
	kissIcon.Size = UDim2.new(0, 35, 0, 35)
	kissIcon.Position = UDim2.new(0, 8, 0.5, -17)
	kissIcon.BackgroundTransparency = 1
	kissIcon.Text = "\xF0\x9F\x92\x8B"
	kissIcon.TextSize = 24
	kissIcon.Font = Enum.Font.SourceSans
	kissIcon.Parent = frame

	totalKissLabel = Instance.new("TextLabel")
	totalKissLabel.Name = "TotalKisses"
	totalKissLabel.Size = UDim2.new(1, -50, 1, 0)
	totalKissLabel.Position = UDim2.new(0, 45, 0, 0)
	totalKissLabel.BackgroundTransparency = 1
	totalKissLabel.Text = "0 kisses"
	totalKissLabel.TextColor3 = UITheme.Colors.AccentGlow
	totalKissLabel.Font = UITheme.Fonts.Number
	totalKissLabel.TextSize = 22
	totalKissLabel.TextXAlignment = Enum.TextXAlignment.Left
	totalKissLabel.Parent = frame
end

-- PUBLIC API --

function UIController:AddCoins(amount)
	coinCount = coinCount + amount
	-- Animated count-up
	task.spawn(function()
		local startVal = displayedCoinCount
		local endVal = coinCount
		local duration = 0.4
		local startTime = tick()
		while true do
			local elapsed = tick() - startTime
			local alpha = math.min(elapsed / duration, 1)
			-- Ease out quad
			alpha = 1 - (1 - alpha) * (1 - alpha)
			local current = math.floor(startVal + (endVal - startVal) * alpha)
			coinLabel.Text = tostring(current)
			if alpha >= 1 then break end
			task.wait()
		end
		displayedCoinCount = endVal
		coinLabel.Text = tostring(endVal)
	end)

	-- Bump animation on coin display
	local parent = coinLabel.Parent
	local orig = parent.Size
	local bump = UDim2.new(orig.X.Scale, orig.X.Offset + 8, orig.Y.Scale, orig.Y.Offset + 4)
	TweenPresets.BumpUI(parent, bump, orig)
end

function UIController:UpdateCombo(count, multiplier)
	comboFrame.Visible = true
	comboLabel.Text = tostring(count)
	comboMultLabel.Text = "x" .. tostring(multiplier)

	-- Bounce animation
	local orig = comboFrame.Size
	local bump = UDim2.new(0, 200, 0, 90)
	TweenPresets.BumpUI(comboFrame, bump, orig)

	-- Change color based on combo level
	if count >= 10 then
		comboLabel.TextColor3 = UITheme.Colors.Super
		UITheme.AddStroke(comboFrame, UITheme.Colors.Super, 3, 0)
	elseif count >= 5 then
		comboLabel.TextColor3 = UITheme.Colors.Gold
	else
		comboLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	end

	-- Auto-hide after combo window
	task.delay(Config.COMBO_WINDOW + 0.5, function()
		if comboFrame.Visible then
			TweenPresets.Play(comboFrame, "Fade", { BackgroundTransparency = 1 })
			task.wait(0.3)
			comboFrame.Visible = false
			comboFrame.BackgroundTransparency = 0.2
		end
	end)
end

function UIController:ShowReaction(characterName, reactionText, globalCount)
	local charLabel = reactionFrame:FindFirstChild("CharName")
	local reactionLabel = reactionFrame:FindFirstChild("ReactionText")

	charLabel.Text = characterName
	reactionLabel.Text = "..." .. reactionText .. "..."

	-- Animate in
	reactionFrame.Visible = true
	reactionFrame.BackgroundTransparency = 0.1
	reactionFrame.Position = UDim2.new(0.5, -200, 0.55, 0)

	TweenPresets.Play(reactionFrame, "PopIn", {
		Position = UDim2.new(0.5, -200, 0.5, 0),
	})

	-- Float up and fade out
	task.delay(1.5, function()
		TweenPresets.Play(reactionFrame, "FadeSlow", {
			Position = UDim2.new(0.5, -200, 0.4, 0),
			BackgroundTransparency = 1,
		})
		task.delay(0.6, function()
			reactionFrame.Visible = false
			reactionFrame.BackgroundTransparency = 0.1
		end)
	end)
end

function UIController:ShowSuperKiss(characterName, coinsAwarded)
	superOverlay.Visible = true
	local superLabel = superOverlay:FindFirstChild("SuperLabel")
	local coinsLabel = superOverlay:FindFirstChild("CoinsAwarded")

	coinsLabel.Text = "+" .. tostring(coinsAwarded) .. " COINS!"

	-- Flash background
	TweenPresets.Play(superOverlay, "FadeFast", { BackgroundTransparency = 0.5 })
	-- Pop in text
	superLabel.TextTransparency = 0
	superLabel.TextSize = 20
	TweenPresets.Play(superLabel, "Elastic", { TextSize = 96 })
	task.delay(0.2, function()
		coinsLabel.TextTransparency = 0
		TweenPresets.Play(coinsLabel, "PopIn", { TextSize = 48 })
	end)

	-- Fade all out
	task.delay(2.5, function()
		TweenPresets.Play(superOverlay, "FadeSlow", { BackgroundTransparency = 1 })
		TweenPresets.Play(superLabel, "Fade", { TextTransparency = 1 })
		TweenPresets.Play(coinsLabel, "Fade", { TextTransparency = 1 })
		task.delay(0.7, function()
			superOverlay.Visible = false
		end)
	end)
end

function UIController:ShowMilestone(characterName, milestone)
	local label = milestoneBar:FindFirstChild("MilestoneText")
	label.Text = characterName .. " has been kissed " .. tostring(milestone) .. " times!"

	milestoneBar.Visible = true
	milestoneBar.Position = UDim2.new(0.5, -250, 0, -80)

	-- Slide in
	TweenPresets.Play(milestoneBar, "Slide", {
		Position = UDim2.new(0.5, -250, 0, 20),
	})

	-- Slide out after 4 seconds
	task.delay(4, function()
		TweenPresets.Play(milestoneBar, "Slide", {
			Position = UDim2.new(0.5, -250, 0, -80),
		})
		task.delay(0.5, function()
			milestoneBar.Visible = false
		end)
	end)
end

function UIController:UpdateKissCount(count)
	if totalKissLabel then
		totalKissLabel.Text = tostring(count) .. " kisses"
	end
end

return UIController
