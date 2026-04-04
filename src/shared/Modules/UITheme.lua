-- Centralized UI theme for the cartoony kiss game look
-- All UI elements reference these for consistent styling

local UITheme = {
	-- Main palette
	Colors = {
		Background = Color3.fromRGB(30, 20, 50),
		BackgroundTransparent = 0.3,
		Panel = Color3.fromRGB(255, 255, 255),
		PanelAlt = Color3.fromRGB(245, 235, 255),
		Accent = Color3.fromRGB(255, 90, 150),
		AccentGlow = Color3.fromRGB(255, 140, 190),
		AccentDark = Color3.fromRGB(200, 50, 110),
		Gold = Color3.fromRGB(255, 210, 50),
		GoldDark = Color3.fromRGB(200, 160, 20),
		Coin = Color3.fromRGB(255, 220, 60),
		Combo = Color3.fromRGB(100, 220, 255),
		ComboBright = Color3.fromRGB(140, 240, 255),
		Super = Color3.fromRGB(255, 60, 200),
		SuperGlow = Color3.fromRGB(255, 120, 230),
		Success = Color3.fromRGB(80, 220, 120),
		Text = Color3.fromRGB(60, 40, 80),
		TextLight = Color3.fromRGB(255, 255, 255),
		TextMuted = Color3.fromRGB(160, 140, 180),
		Shadow = Color3.fromRGB(0, 0, 0),
		LeaderboardBg = Color3.fromRGB(40, 25, 65),
		LeaderboardEntry = Color3.fromRGB(60, 40, 90),
		Rank1 = Color3.fromRGB(255, 215, 0),
		Rank2 = Color3.fromRGB(200, 200, 210),
		Rank3 = Color3.fromRGB(205, 135, 60),
		MilestoneBg = Color3.fromRGB(255, 240, 200),
		ReactionBubble = Color3.fromRGB(255, 255, 255),
		HealthBar = Color3.fromRGB(255, 80, 100),
	},

	-- Typography
	Fonts = {
		Title = Enum.Font.FredokaOne,
		Body = Enum.Font.GothamBold,
		Accent = Enum.Font.Bangers,
		Number = Enum.Font.FredokaOne,
		Reaction = Enum.Font.Bangers,
		Combo = Enum.Font.FredokaOne,
	},

	-- Font sizes
	FontSizes = {
		Tiny = 14,
		Small = 18,
		Medium = 24,
		Large = 36,
		XLarge = 48,
		XXLarge = 64,
		Giant = 96,
	},

	-- Corner rounding
	CornerRadius = {
		Small = UDim.new(0, 8),
		Medium = UDim.new(0, 14),
		Large = UDim.new(0, 22),
		XLarge = UDim.new(0, 32),
		Full = UDim.new(0.5, 0),
	},

	-- Standard paddings
	Padding = {
		Small = UDim.new(0, 6),
		Medium = UDim.new(0, 12),
		Large = UDim.new(0, 20),
	},

	-- Stroke thickness
	Stroke = {
		Thin = 1,
		Medium = 2,
		Thick = 3,
		Bold = 4,
	},

	-- Gradient presets (start, end colors)
	Gradients = {
		Kiss = { Color3.fromRGB(255, 90, 150), Color3.fromRGB(255, 50, 120) },
		Gold = { Color3.fromRGB(255, 230, 100), Color3.fromRGB(255, 190, 30) },
		Combo = { Color3.fromRGB(80, 200, 255), Color3.fromRGB(40, 140, 220) },
		Super = { Color3.fromRGB(255, 80, 220), Color3.fromRGB(200, 40, 160) },
		Panel = { Color3.fromRGB(255, 255, 255), Color3.fromRGB(240, 230, 250) },
		Dark = { Color3.fromRGB(50, 30, 70), Color3.fromRGB(30, 15, 45) },
	},
}

-- Helper: create a UICorner
function UITheme.Corner(parent, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = radius or UITheme.CornerRadius.Medium
	corner.Parent = parent
	return corner
end

-- Helper: create a UIStroke
function UITheme.AddStroke(parent, color, thickness, transparency)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color or UITheme.Colors.Shadow
	stroke.Thickness = thickness or UITheme.Stroke.Medium
	stroke.Transparency = transparency or 0.5
	stroke.Parent = parent
	return stroke
end

-- Helper: create a UIGradient from preset name
function UITheme.AddGradient(parent, presetName, rotation)
	local preset = UITheme.Gradients[presetName]
	if not preset then return nil end

	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new(preset[1], preset[2])
	gradient.Rotation = rotation or 90
	gradient.Parent = parent
	return gradient
end

-- Helper: create a drop shadow (using ImageLabel trick)
function UITheme.AddShadow(parent, offset, size)
	local shadow = Instance.new("ImageLabel")
	shadow.Name = "Shadow"
	shadow.BackgroundTransparency = 1
	shadow.Image = "rbxassetid://5554236805"
	shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
	shadow.ImageTransparency = 0.6
	shadow.ScaleType = Enum.ScaleType.Slice
	shadow.SliceCenter = Rect.new(23, 23, 277, 277)
	shadow.Size = UDim2.new(1, size or 30, 1, size or 30)
	shadow.Position = UDim2.new(0, -(size or 30) / 2 + (offset or 4), 0, -(size or 30) / 2 + (offset or 4))
	shadow.ZIndex = parent.ZIndex - 1
	shadow.Parent = parent
	return shadow
end

-- Helper: create a UIPadding
function UITheme.AddPadding(parent, top, right, bottom, left)
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = top or UITheme.Padding.Medium
	padding.PaddingRight = right or top or UITheme.Padding.Medium
	padding.PaddingBottom = bottom or top or UITheme.Padding.Medium
	padding.PaddingLeft = left or right or top or UITheme.Padding.Medium
	padding.Parent = parent
	return padding
end

return UITheme
