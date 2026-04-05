-- UIController: Base controller + HUD (coins, leaderboard button, combo)
-- Design: chunky cartoony, rounded corners, bold fonts, bouncy tweens

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local MarketplaceService = game:GetService("MarketplaceService")
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

-- Leaderboard refs
local lbPanel = nil
local lbEntriesFrame = nil
local lbRows = {}

-- Character name popup refs
local charBillboards = {} -- [model] = { gui, frame, label, visible }

-- Rarity tier → star string
local RARITY_STARS = {
	Common = "\xE2\xAD\x90",
	Uncommon = "\xE2\xAD\x90\xE2\xAD\x90",
	Rare = "\xE2\xAD\x90\xE2\xAD\x90\xE2\xAD\x90",
	Epic = "\xE2\xAD\x90\xE2\xAD\x90\xE2\xAD\x90\xE2\xAD\x90",
	Legendary = "\xE2\xAD\x90\xE2\xAD\x90\xE2\xAD\x90\xE2\xAD\x90",
}

-- Extra tween infos for new components
local LB_SLIDE = TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local LB_SLIDE_OUT = TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.In)
local NAME_FADE_IN = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local NAME_FADE_OUT = TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

-- Shop refs
local shopButton = nil
local shopPanel = nil
local shopOpen = false
local activeTab = "GAMEPASSES"

-- Rank colors
local GOLD = Color3.fromHex("#FFD700")
local SILVER = Color3.fromHex("#C0C0C0")
local BRONZE = Color3.fromHex("#CD7F32")
local LIGHT_BLUE = Color3.fromRGB(220, 240, 255)

-- State
local displayedCoins = 0
local currentCombo = 0
local comboVisible = false
local heartbeatConn = nil

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
	buildShopButton()
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

---------------------------------------------------------------------------
-- 6. Leaderboard Panel (slides from right, toggle, top 10)
---------------------------------------------------------------------------

local function buildLeaderboardPanel()
	lbPanel = Instance.new("Frame")
	lbPanel.Name = "LeaderboardPanel"
	lbPanel.Size = UDim2.new(0, 300, 0, 420)
	lbPanel.AnchorPoint = Vector2.new(1, 0)
	lbPanel.Position = UDim2.new(1.05, 0, 0, 80) -- offscreen right
	lbPanel.BackgroundColor3 = SKY_BLUE
	lbPanel.BorderSizePixel = 0
	lbPanel.ZIndex = 12
	lbPanel.Parent = screenGui
	corner(lbPanel)

	-- Dark border stroke
	local darkStroke = Instance.new("UIStroke")
	darkStroke.Color = Color3.fromRGB(30, 30, 60)
	darkStroke.Thickness = 3
	darkStroke.Transparency = 0.2
	darkStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	darkStroke.Parent = lbPanel

	-- Header
	local header = Instance.new("TextLabel")
	header.Name = "Header"
	header.Size = UDim2.new(1, -50, 0, 44)
	header.Position = UDim2.new(0, 12, 0, 6)
	header.BackgroundTransparency = 1
	header.Text = "\xF0\x9F\x8F\x86 TOP KISSERS"
	header.TextColor3 = HOT_PINK
	header.Font = Enum.Font.GothamBold
	header.TextSize = 20
	header.TextXAlignment = Enum.TextXAlignment.Left
	header.ZIndex = 13
	header.Parent = lbPanel

	-- Close button: yellow circle, top right
	local closeBtn = Instance.new("TextButton")
	closeBtn.Name = "CloseBtn"
	closeBtn.Size = UDim2.new(0, 30, 0, 30)
	closeBtn.Position = UDim2.new(1, -38, 0, 10)
	closeBtn.BackgroundColor3 = YELLOW
	closeBtn.BorderSizePixel = 0
	closeBtn.Text = "\xE2\x9C\x95"
	closeBtn.TextColor3 = Color3.fromRGB(60, 60, 60)
	closeBtn.TextSize = 16
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.AutoButtonColor = false
	closeBtn.ZIndex = 14
	closeBtn.Parent = lbPanel

	local closeBtnCorner = Instance.new("UICorner")
	closeBtnCorner.CornerRadius = UDim.new(0.5, 0)
	closeBtnCorner.Parent = closeBtn

	closeBtn.MouseButton1Click:Connect(function()
		popScale(closeBtn)
		UIController.toggleLeaderboard()
	end)

	-- Entries scrolling frame
	lbEntriesFrame = Instance.new("Frame")
	lbEntriesFrame.Name = "Entries"
	lbEntriesFrame.Size = UDim2.new(1, -16, 1, -56)
	lbEntriesFrame.Position = UDim2.new(0, 8, 0, 50)
	lbEntriesFrame.BackgroundTransparency = 1
	lbEntriesFrame.ZIndex = 13
	lbEntriesFrame.Parent = lbPanel

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 2)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = lbEntriesFrame
end

function UIController.toggleLeaderboard()
	if not lbPanel then
		buildLeaderboardPanel()
	end

	leaderboardOpen = not leaderboardOpen

	if leaderboardOpen then
		-- Slide in from X=1.05 to X=0.72
		TweenService:Create(lbPanel, LB_SLIDE, {
			Position = UDim2.new(0.72, 0, 0, 80),
		}):Play()
	else
		-- Slide out to X=1.05
		TweenService:Create(lbPanel, LB_SLIDE_OUT, {
			Position = UDim2.new(1.05, 0, 0, 80),
		}):Play()
	end
end

function UIController:UpdateLeaderboard(topKissers)
	if not lbPanel then
		buildLeaderboardPanel()
	end

	-- Clear old rows
	for _, row in ipairs(lbRows) do
		if row and row.Parent then
			row:Destroy()
		end
	end
	lbRows = {}

	if not topKissers or #topKissers == 0 then
		local empty = Instance.new("TextLabel")
		empty.Name = "Empty"
		empty.Size = UDim2.new(1, 0, 0, 60)
		empty.BackgroundTransparency = 1
		empty.Text = "No kisses yet!"
		empty.TextColor3 = WHITE
		empty.Font = Enum.Font.GothamBold
		empty.TextSize = 16
		empty.LayoutOrder = 1
		empty.ZIndex = 14
		empty.Parent = lbEntriesFrame
		table.insert(lbRows, empty)
		return
	end

	for i, entry in ipairs(topKissers) do
		if i > 10 then break end

		local row = Instance.new("Frame")
		row.Name = "Row_" .. i
		row.Size = UDim2.new(1, -4, 0, 34)
		row.LayoutOrder = i
		row.BorderSizePixel = 0
		row.ZIndex = 14
		row.Parent = lbEntriesFrame
		corner(row)

		-- Alternating bg colors
		if i % 2 == 1 then
			row.BackgroundColor3 = WHITE
			row.BackgroundTransparency = 0.15
		else
			row.BackgroundColor3 = LIGHT_BLUE
			row.BackgroundTransparency = 0.15
		end

		-- Rank color
		local rankColor = WHITE
		local rankPrefix = ""
		if i == 1 then
			rankColor = GOLD
			rankPrefix = "\xF0\x9F\x91\x91 "
		elseif i == 2 then
			rankColor = SILVER
		elseif i == 3 then
			rankColor = BRONZE
		end

		-- Rank label
		local rankLabel = Instance.new("TextLabel")
		rankLabel.Name = "Rank"
		rankLabel.Size = UDim2.new(0, 44, 1, 0)
		rankLabel.Position = UDim2.new(0, 4, 0, 0)
		rankLabel.BackgroundTransparency = 1
		rankLabel.Text = rankPrefix .. "#" .. tostring(i)
		rankLabel.TextColor3 = rankColor
		rankLabel.Font = Enum.Font.GothamBold
		rankLabel.TextSize = 14
		rankLabel.TextXAlignment = Enum.TextXAlignment.Left
		rankLabel.ZIndex = 15
		rankLabel.Parent = row

		-- Player name
		local nameLabel = Instance.new("TextLabel")
		nameLabel.Name = "PlayerName"
		nameLabel.Size = UDim2.new(1, -120, 1, 0)
		nameLabel.Position = UDim2.new(0, 50, 0, 0)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = entry.Name or "???"
		nameLabel.TextColor3 = Color3.fromRGB(40, 40, 60)
		nameLabel.Font = Enum.Font.GothamBold
		nameLabel.TextSize = 13
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
		nameLabel.ZIndex = 15
		nameLabel.Parent = row

		-- Kiss count
		local countLabel = Instance.new("TextLabel")
		countLabel.Name = "KissCount"
		countLabel.Size = UDim2.new(0, 60, 1, 0)
		countLabel.Position = UDim2.new(1, -64, 0, 0)
		countLabel.BackgroundTransparency = 1
		countLabel.Text = tostring(entry.TotalKisses or 0)
		countLabel.TextColor3 = HOT_PINK
		countLabel.Font = Enum.Font.GothamBold
		countLabel.TextSize = 14
		countLabel.TextXAlignment = Enum.TextXAlignment.Right
		countLabel.ZIndex = 15
		countLabel.Parent = row

		table.insert(lbRows, row)
	end
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

---------------------------------------------------------------------------
-- 7. Character Name Popup (BillboardGui, proximity-based fade)
---------------------------------------------------------------------------

local function getRarityStars(model)
	-- Try to read rarity from a StringValue, else infer from CharacterService defs
	local rarityVal = model:FindFirstChild("RarityTier")
	if rarityVal and rarityVal:IsA("StringValue") then
		return RARITY_STARS[rarityVal.Value] or RARITY_STARS.Common
	end
	-- Fallback: look up from a hardcoded client-side table
	local name = model.Name
	local nameVal = model:FindFirstChild("CharacterName")
	if nameVal and nameVal:IsA("StringValue") then
		name = nameVal.Value
	end

	local rarityMap = {
		["Tralalero Tralala"] = "Common",
		["Bombardino Coccodrillo"] = "Common",
		["Tung Tung Tung Sahur"] = "Uncommon",
		["Brr Brr Patapim"] = "Uncommon",
		["Cappuccino Assassino"] = "Rare",
		["Ballerina Cappuccina"] = "Rare",
		["Pizzicato Pangolino"] = "Common",
		["Bombardino Bufalo"] = "Uncommon",
		["Trombettino Tartaruga"] = "Common",
		["Cappellino Capibara"] = "Common",
		["Fischietto Fenicottero"] = "Uncommon",
		["Urlando Unicorno"] = "Rare",
		["Saltellino Salamandra"] = "Uncommon",
		["Magnifico Macarone"] = "Rare",
	}
	return RARITY_STARS[rarityMap[name] or "Common"] or RARITY_STARS.Common
end

local function createCharBillboard(model)
	local head = model:FindFirstChild("Head")
	if not head then return nil end

	local nameVal = model:FindFirstChild("CharacterName")
	local charName = nameVal and nameVal:IsA("StringValue") and nameVal.Value or model.Name
	local stars = getRarityStars(model)

	local gui = Instance.new("BillboardGui")
	gui.Name = "CharNamePopup"
	gui.Adornee = head
	gui.Size = UDim2.new(0, 160, 0, 40)
	gui.StudsOffset = Vector3.new(0, 3.5, 0)
	gui.AlwaysOnTop = false
	gui.Active = false
	gui.Parent = model

	local frame = Instance.new("Frame")
	frame.Name = "Bg"
	frame.Size = UDim2.new(1, 0, 1, 0)
	frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	frame.BackgroundTransparency = 1 -- start invisible
	frame.Parent = gui
	corner(frame)

	local label = Instance.new("TextLabel")
	label.Name = "NameLabel"
	label.Size = UDim2.new(1, -8, 1, 0)
	label.Position = UDim2.new(0, 4, 0, 0)
	label.BackgroundTransparency = 1
	label.Text = charName .. " " .. stars
	label.TextColor3 = WHITE
	label.Font = Enum.Font.GothamBold
	label.TextSize = 14
	label.TextTransparency = 1 -- start invisible
	label.TextScaled = false
	label.Parent = frame

	local data = {
		gui = gui,
		frame = frame,
		label = label,
		visible = false,
		head = head,
	}
	charBillboards[model] = data
	return data
end

local function setupCharNamePopups()
	local npcsFolder = Workspace:FindFirstChild("NPCs")
	if not npcsFolder then return end

	-- Create billboards for all existing NPCs
	for _, model in ipairs(npcsFolder:GetChildren()) do
		if model:IsA("Model") and model:FindFirstChild("Head") then
			-- Skip if billboard already exists (e.g. the ModelService nametag)
			local existing = model:FindFirstChild("CharNamePopup")
			if not existing then
				createCharBillboard(model)
			end
		end
	end

	-- Listen for new NPCs
	npcsFolder.ChildAdded:Connect(function(model)
		if model:IsA("Model") then
			task.wait(0.1) -- let parts replicate
			if model:FindFirstChild("Head") and not model:FindFirstChild("CharNamePopup") then
				createCharBillboard(model)
			end
		end
	end)
end

local function runProximityCheck()
	heartbeatConn = RunService.Heartbeat:Connect(function()
		local character = player.Character
		if not character then return end
		local hrp = character:FindFirstChild("HumanoidRootPart")
		if not hrp then return end
		local playerPos = hrp.Position

		for model, data in pairs(charBillboards) do
			if not model.Parent then
				-- Model was removed; clean up
				charBillboards[model] = nil
				continue
			end

			local head = data.head
			if not head or not head.Parent then continue end

			local dist = (playerPos - head.Position).Magnitude

			if dist < 12 and not data.visible then
				-- Fade in
				data.visible = true
				TweenService:Create(data.frame, NAME_FADE_IN, { BackgroundTransparency = 0.4 }):Play()
				TweenService:Create(data.label, NAME_FADE_IN, { TextTransparency = 0 }):Play()
			elseif dist > 14 and data.visible then
				-- Fade out
				data.visible = false
				TweenService:Create(data.frame, NAME_FADE_OUT, { BackgroundTransparency = 1 }):Play()
				TweenService:Create(data.label, NAME_FADE_OUT, { TextTransparency = 1 }):Play()
			end
		end
	end)
end

---------------------------------------------------------------------------
-- 8. Final :Start() — wire all remotes with pcall
---------------------------------------------------------------------------

function UIController:Start()
	local remotesFolder = ReplicatedStorage:WaitForChild("Remotes", 15)
	if not remotesFolder then
		warn("[UIController] Remotes folder not found")
		return
	end

	-- KissReaction → spawnKissPopup (normal) + trigger combo check
	local kissReaction = remotesFolder:FindFirstChild("KissReaction")
	if kissReaction then
		kissReaction.OnClientEvent:Connect(function(characterName, _reactionType, _globalCount)
			pcall(function()
				local npcsFolder = Workspace:FindFirstChild("NPCs")
				if not npcsFolder then return end
				local npcModel = npcsFolder:FindFirstChild(characterName)
				if not npcModel then return end
				local body = npcModel:FindFirstChild("Body") or npcModel.PrimaryPart
				if not body then return end
				self:SpawnKissPopup(body.Position, 10, false)
			end)
		end)
	end

	-- ComboUpdate → showComboBanner + updateComboDisplay
	local comboUpdate = remotesFolder:FindFirstChild("ComboUpdate")
	if comboUpdate then
		comboUpdate.OnClientEvent:Connect(function(comboCount, _multiplier)
			pcall(function()
				self:SetCombo(comboCount)
				self:ShowComboBanner(comboCount)
			end)
		end)
	end

	-- SuperKissEvent → spawnKissPopup(isSuper=true)
	local superKiss = remotesFolder:FindFirstChild("SuperKissEvent")
	if superKiss then
		superKiss.OnClientEvent:Connect(function(characterName, coinsAwarded)
			pcall(function()
				local npcsFolder = Workspace:FindFirstChild("NPCs")
				if not npcsFolder then return end
				local npcModel = npcsFolder:FindFirstChild(characterName)
				if not npcModel then return end
				local body = npcModel:FindFirstChild("Body") or npcModel.PrimaryPart
				if not body then return end
				self:SpawnKissPopup(body.Position, coinsAwarded, true)
			end)
		end)
	end

	-- LeaderboardUpdate → updateLeaderboard
	local lbUpdate = remotesFolder:FindFirstChild("LeaderboardUpdate")
	if lbUpdate then
		lbUpdate.OnClientEvent:Connect(function(topKissers)
			pcall(function()
				self:UpdateLeaderboard(topKissers)
			end)
		end)
	end

	-- MilestoneAnnouncement → showMilestoneBanner
	local milestone = remotesFolder:FindFirstChild("MilestoneAnnouncement")
	if milestone then
		milestone.OnClientEvent:Connect(function(characterName, milestoneCount)
			pcall(function()
				self:ShowMilestone(characterName, milestoneCount)
			end)
		end)
	end

	-- Setup character name popups and start proximity heartbeat
	pcall(setupCharNamePopups)
	pcall(runProximityCheck)

	-- Debug: P key runs UI smoke test
	self:SetupSmokeTestKeybind()

	print("[UIController] loaded \xE2\x9C\x93")
end

---------------------------------------------------------------------------
-- 8b. UI Smoke Test (P key debug trigger)
---------------------------------------------------------------------------

function UIController:RunSmokeTest()
	print("[UIController] Starting UI smoke test...")

	local mockTop10 = {}
	for i = 1, 10 do
		table.insert(mockTop10, {
			Rank = i,
			Name = "Player" .. i,
			TotalKisses = 600 - i * 50,
		})
	end

	local steps = {
		function() self:AddCoins(999); print("  [smoke] AddCoins(999)") end,
		function()
			local pos = Vector3.new(0, 5, 0)
			self:SpawnKissPopup(pos, 10, false)
			print("  [smoke] SpawnKissPopup normal")
		end,
		function()
			local pos = Vector3.new(0, 5, 0)
			self:SpawnKissPopup(pos, 100, true)
			print("  [smoke] SpawnKissPopup super")
		end,
		function() self:ShowComboBanner(3); print("  [smoke] ComboBanner 3x") end,
		function() self:ShowComboBanner(7); print("  [smoke] ComboBanner 7x") end,
		function() self:ShowComboBanner(12); print("  [smoke] ComboBanner 12x") end,
		function() self:UpdateLeaderboard(mockTop10); print("  [smoke] UpdateLeaderboard") end,
		function() UIController.toggleLeaderboard(); print("  [smoke] Leaderboard open") end,
		function() task.wait(1.5) end, -- hold open
		function() UIController.toggleLeaderboard(); print("  [smoke] Leaderboard close") end,
		function()
			self:ShowMilestone("Pizzicato Pangolino", 100)
			print("  [smoke] MilestoneBanner")
		end,
		function() self:AddCoins(0); print("  [smoke] AddCoins(0) reset display") end,
	}

	task.spawn(function()
		for _, fn in ipairs(steps) do
			pcall(fn)
			task.wait(0.5)
		end
		print("[UIController] UI SMOKE TEST COMPLETE")
	end)
end

function UIController:SetupSmokeTestKeybind()
	local UserInputService = game:GetService("UserInputService")
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		if input.KeyCode == Enum.KeyCode.P then
			self:RunSmokeTest()
		end
	end)
end

---------------------------------------------------------------------------
-- 9. Shop System (gamepasses + boosts tabs)
---------------------------------------------------------------------------

local SHOP_SLIDE_IN = TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local SHOP_SLIDE_OUT = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In)

local GAMEPASS_CARDS = {
	{ icon = "\xF0\x9F\xAA\x99", name = "Double Coins", desc = "2x coins on every kiss", configKey = "GAMEPASS_DOUBLE_COINS" },
	{ icon = "\xE2\x9C\xA8", name = "VIP Aura", desc = "Glow like the legend you are", configKey = "GAMEPASS_VIP_AURA" },
	{ icon = "\xF0\x9F\x92\x8B", name = "Auto Kiss", desc = "Kisses happen automatically", configKey = "GAMEPASS_AUTO_KISS" },
	{ icon = "\xF0\x9F\x8D\x80", name = "Lucky Lips", desc = "4x better Super Kiss chance", configKey = "GAMEPASS_LUCKY_LIPS" },
}

local BOOST_CARDS = {
	{ icon = "\xF0\x9F\xAA\x99", name = "100 Coins", desc = "Small coin pack", configKey = "PRODUCT_COIN_SMALL" },
	{ icon = "\xF0\x9F\xAA\x99\xF0\x9F\xAA\x99", name = "500 Coins", desc = "Medium coin pack", configKey = "PRODUCT_COIN_MEDIUM" },
	{ icon = "\xF0\x9F\x92\xB0", name = "2500 Coins", desc = "Large coin pack", configKey = "PRODUCT_COIN_LARGE" },
	{ icon = "\xE2\x9A\xA1", name = "Combo Boost", desc = "10x multiplier for 30 seconds", configKey = "PRODUCT_COMBO_BOOST" },
	{ icon = "\xF0\x9F\x8C\xAA\xEF\xB8\x8F", name = "Kiss Storm", desc = "Kiss every character at once", configKey = "PRODUCT_KISS_STORM" },
}

local function buildShopButton()
	shopButton = Instance.new("TextButton")
	shopButton.Name = "ShopButton"
	shopButton.Size = UDim2.new(0, 50, 0, 50)
	shopButton.AnchorPoint = Vector2.new(1, 1)
	shopButton.Position = UDim2.new(1, -16, 1, -16)
	shopButton.BackgroundColor3 = HOT_PINK
	shopButton.BorderSizePixel = 0
	shopButton.Text = "\xF0\x9F\x9B\x8D\xEF\xB8\x8F"
	shopButton.TextSize = 26
	shopButton.Font = Enum.Font.GothamBold
	shopButton.AutoButtonColor = false
	shopButton.ZIndex = 2
	shopButton.Parent = screenGui
	corner(shopButton)
	shadow(shopButton)

	-- Bounce in on start
	local uiScale = Instance.new("UIScale")
	uiScale.Scale = 0
	uiScale.Parent = shopButton
	task.delay(0.5, function()
		TweenService:Create(uiScale, ANIM_IN, { Scale = 1 }):Play()
	end)

	shopButton.MouseButton1Click:Connect(function()
		popScale(shopButton)
		UIController:ToggleShop()
	end)
end

local function createCard(parent, index, icon, name, desc, onClick, isOwned)
	local card = Instance.new("Frame")
	card.Name = "Card_" .. index
	card.Size = UDim2.new(1, -16, 0, 80)
	card.BackgroundColor3 = WHITE
	card.BackgroundTransparency = 0.05
	card.BorderSizePixel = 0
	card.LayoutOrder = index
	card.ZIndex = 16
	card.Parent = parent
	corner(card)

	local cardStroke = Instance.new("UIStroke")
	cardStroke.Color = SKY_BLUE
	cardStroke.Thickness = 2
	cardStroke.Transparency = 0.4
	cardStroke.Parent = card

	-- Icon
	local iconLabel = Instance.new("TextLabel")
	iconLabel.Size = UDim2.new(0, 40, 0, 40)
	iconLabel.Position = UDim2.new(0, 10, 0.5, -20)
	iconLabel.BackgroundTransparency = 1
	iconLabel.Text = icon
	iconLabel.TextSize = 28
	iconLabel.Font = Enum.Font.SourceSans
	iconLabel.ZIndex = 17
	iconLabel.Parent = card

	-- Name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, -130, 0, 24)
	nameLabel.Position = UDim2.new(0, 55, 0, 10)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = name
	nameLabel.TextColor3 = Color3.fromRGB(40, 40, 60)
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextSize = 16
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.ZIndex = 17
	nameLabel.Parent = card

	-- Description
	local descLabel = Instance.new("TextLabel")
	descLabel.Size = UDim2.new(1, -130, 0, 20)
	descLabel.Position = UDim2.new(0, 55, 0, 36)
	descLabel.BackgroundTransparency = 1
	descLabel.Text = desc
	descLabel.TextColor3 = Color3.fromRGB(120, 120, 140)
	descLabel.Font = Enum.Font.GothamBold
	descLabel.TextSize = 12
	descLabel.TextXAlignment = Enum.TextXAlignment.Left
	descLabel.ZIndex = 17
	descLabel.Parent = card

	-- Buy button
	local buyBtn = Instance.new("TextButton")
	buyBtn.Name = "BuyBtn"
	buyBtn.Size = UDim2.new(0, 65, 0, 32)
	buyBtn.Position = UDim2.new(1, -75, 0.5, -16)
	buyBtn.BorderSizePixel = 0
	buyBtn.Font = Enum.Font.GothamBold
	buyBtn.TextSize = 14
	buyBtn.AutoButtonColor = false
	buyBtn.ZIndex = 18
	buyBtn.Parent = card

	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0.12, 0)
	btnCorner.Parent = buyBtn

	if isOwned then
		buyBtn.BackgroundColor3 = MINT
		buyBtn.TextColor3 = Color3.fromRGB(30, 100, 50)
		buyBtn.Text = "\xE2\x9C\x93 OWNED"
	else
		buyBtn.BackgroundColor3 = YELLOW
		buyBtn.TextColor3 = Color3.fromRGB(60, 60, 60)
		buyBtn.Text = "BUY"

		buyBtn.MouseButton1Click:Connect(function()
			popScale(buyBtn)
			pcall(onClick)
		end)
	end

	return card
end

local function buildShopPanel()
	shopPanel = Instance.new("Frame")
	shopPanel.Name = "ShopPanel"
	shopPanel.Size = UDim2.new(0, 380, 0, 520)
	shopPanel.AnchorPoint = Vector2.new(0.5, 1)
	shopPanel.Position = UDim2.new(0.5, 0, 1, 600) -- offscreen below
	shopPanel.BorderSizePixel = 0
	shopPanel.ZIndex = 14
	shopPanel.Parent = screenGui

	-- Pastel gradient background
	shopPanel.BackgroundColor3 = WHITE
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new(
		Color3.fromRGB(255, 230, 245),
		Color3.fromRGB(230, 240, 255)
	)
	gradient.Rotation = 90
	gradient.Parent = shopPanel
	corner(shopPanel)
	shadow(shopPanel)

	-- Title
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, -50, 0, 40)
	title.Position = UDim2.new(0, 16, 0, 8)
	title.BackgroundTransparency = 1
	title.Text = "\xF0\x9F\x9B\x8D\xEF\xB8\x8F SHOP"
	title.TextColor3 = HOT_PINK
	title.Font = Enum.Font.GothamBold
	title.TextSize = 24
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.ZIndex = 15
	title.Parent = shopPanel

	-- Close button
	local closeBtn = Instance.new("TextButton")
	closeBtn.Name = "CloseBtn"
	closeBtn.Size = UDim2.new(0, 30, 0, 30)
	closeBtn.Position = UDim2.new(1, -38, 0, 12)
	closeBtn.BackgroundColor3 = HOT_PINK
	closeBtn.BorderSizePixel = 0
	closeBtn.Text = "\xE2\x9C\x95"
	closeBtn.TextColor3 = WHITE
	closeBtn.TextSize = 16
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.AutoButtonColor = false
	closeBtn.ZIndex = 16
	closeBtn.Parent = shopPanel

	local closeBtnCorner = Instance.new("UICorner")
	closeBtnCorner.CornerRadius = UDim.new(0.5, 0)
	closeBtnCorner.Parent = closeBtn

	closeBtn.MouseButton1Click:Connect(function()
		popScale(closeBtn)
		UIController:ToggleShop()
	end)

	-- Tab buttons
	local tabFrame = Instance.new("Frame")
	tabFrame.Name = "Tabs"
	tabFrame.Size = UDim2.new(1, -16, 0, 36)
	tabFrame.Position = UDim2.new(0, 8, 0, 50)
	tabFrame.BackgroundTransparency = 1
	tabFrame.ZIndex = 15
	tabFrame.Parent = shopPanel

	local gamepassTab = Instance.new("TextButton")
	gamepassTab.Name = "GamepassTab"
	gamepassTab.Size = UDim2.new(0.5, -4, 1, 0)
	gamepassTab.Position = UDim2.new(0, 0, 0, 0)
	gamepassTab.BackgroundColor3 = HOT_PINK
	gamepassTab.BorderSizePixel = 0
	gamepassTab.Text = "GAMEPASSES"
	gamepassTab.TextColor3 = WHITE
	gamepassTab.Font = Enum.Font.GothamBold
	gamepassTab.TextSize = 14
	gamepassTab.AutoButtonColor = false
	gamepassTab.ZIndex = 16
	gamepassTab.Parent = tabFrame
	corner(gamepassTab)

	local boostTab = Instance.new("TextButton")
	boostTab.Name = "BoostTab"
	boostTab.Size = UDim2.new(0.5, -4, 1, 0)
	boostTab.Position = UDim2.new(0.5, 4, 0, 0)
	boostTab.BackgroundColor3 = Color3.fromRGB(180, 180, 200)
	boostTab.BorderSizePixel = 0
	boostTab.Text = "BOOSTS"
	boostTab.TextColor3 = WHITE
	boostTab.Font = Enum.Font.GothamBold
	boostTab.TextSize = 14
	boostTab.AutoButtonColor = false
	boostTab.ZIndex = 16
	boostTab.Parent = tabFrame
	corner(boostTab)

	-- Content scroll frame
	local contentFrame = Instance.new("ScrollingFrame")
	contentFrame.Name = "Content"
	contentFrame.Size = UDim2.new(1, -8, 1, -96)
	contentFrame.Position = UDim2.new(0, 4, 0, 92)
	contentFrame.BackgroundTransparency = 1
	contentFrame.ScrollBarThickness = 4
	contentFrame.ScrollBarImageColor3 = HOT_PINK
	contentFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	contentFrame.BorderSizePixel = 0
	contentFrame.ZIndex = 15
	contentFrame.Parent = shopPanel

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 8)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.Parent = contentFrame

	-- Tab switching
	local function showTab(tabName)
		activeTab = tabName

		-- Update tab visuals
		if tabName == "GAMEPASSES" then
			gamepassTab.BackgroundColor3 = HOT_PINK
			boostTab.BackgroundColor3 = Color3.fromRGB(180, 180, 200)
		else
			gamepassTab.BackgroundColor3 = Color3.fromRGB(180, 180, 200)
			boostTab.BackgroundColor3 = HOT_PINK
		end

		-- Clear content
		for _, child in ipairs(contentFrame:GetChildren()) do
			if child:IsA("Frame") then child:Destroy() end
		end

		local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Modules"):WaitForChild("Config"))

		if tabName == "GAMEPASSES" then
			for i, card in ipairs(GAMEPASS_CARDS) do
				local gamepassId = Config[card.configKey]
				local owned = false
				if gamepassId and gamepassId ~= 0 then
					local ok, result = pcall(function()
						return MarketplaceService:UserOwnsGamePassAsync(player.UserId, gamepassId)
					end)
					if ok then owned = result end
				end

				createCard(contentFrame, i, card.icon, card.name, card.desc, function()
					if gamepassId and gamepassId ~= 0 then
						MarketplaceService:PromptGamePassPurchase(player, gamepassId)
					end
				end, owned)
			end
			contentFrame.CanvasSize = UDim2.new(0, 0, 0, #GAMEPASS_CARDS * 88)
		else
			for i, card in ipairs(BOOST_CARDS) do
				local productId = Config[card.configKey]
				createCard(contentFrame, i, card.icon, card.name, card.desc, function()
					if productId and productId ~= 0 then
						MarketplaceService:PromptProductPurchase(player, productId)
					end
				end, false)
			end
			contentFrame.CanvasSize = UDim2.new(0, 0, 0, #BOOST_CARDS * 88)
		end
	end

	gamepassTab.MouseButton1Click:Connect(function()
		showTab("GAMEPASSES")
	end)

	boostTab.MouseButton1Click:Connect(function()
		showTab("BOOSTS")
	end)

	-- Show default tab
	showTab("GAMEPASSES")
end

function UIController:ToggleShop()
	if not shopPanel then
		buildShopPanel()
	end

	shopOpen = not shopOpen

	if shopOpen then
		shopPanel.Visible = true
		TweenService:Create(shopPanel, SHOP_SLIDE_IN, {
			Position = UDim2.new(0.5, 0, 1, -16),
		}):Play()
	else
		local tween = TweenService:Create(shopPanel, SHOP_SLIDE_OUT, {
			Position = UDim2.new(0.5, 0, 1, 600),
		})
		tween:Play()
		tween.Completed:Connect(function()
			shopPanel.Visible = false
		end)
	end
end

function UIController:GetScreenGui()
	return screenGui
end

return UIController
