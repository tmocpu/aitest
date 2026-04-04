-- LeaderboardController: Animated leaderboard sidebar UI
-- Shows top 10 kissers with smooth entry animations

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local UITheme = require(Shared:WaitForChild("Modules"):WaitForChild("UITheme"))
local TweenPresets = require(Shared:WaitForChild("Modules"):WaitForChild("TweenPresets"))

local player = Players.LocalPlayer

local LeaderboardController = {}
LeaderboardController.__index = LeaderboardController

local screenGui = nil
local leaderboardFrame = nil
local entriesFrame = nil
local toggleBtn = nil
local isOpen = true
local entryItems = {}

function LeaderboardController:Init(parentGui)
	screenGui = parentGui or player:WaitForChild("PlayerGui"):FindFirstChild("BrainrotHUD")
	if not screenGui then
		screenGui = Instance.new("ScreenGui")
		screenGui.Name = "LeaderboardGui"
		screenGui.ResetOnSpawn = false
		screenGui.IgnoreGuiInset = true
		screenGui.Parent = player:WaitForChild("PlayerGui")
	end

	self:BuildLeaderboard()
end

function LeaderboardController:BuildLeaderboard()
	-- Main container (right side)
	leaderboardFrame = Instance.new("Frame")
	leaderboardFrame.Name = "Leaderboard"
	leaderboardFrame.Size = UDim2.new(0, 240, 0, 460)
	leaderboardFrame.Position = UDim2.new(1, -260, 0, 60)
	leaderboardFrame.BackgroundColor3 = UITheme.Colors.LeaderboardBg
	leaderboardFrame.BackgroundTransparency = 0.1
	leaderboardFrame.Parent = screenGui

	UITheme.Corner(leaderboardFrame, UITheme.CornerRadius.Large)
	UITheme.AddStroke(leaderboardFrame, UITheme.Colors.AccentGlow, 2, 0.3)

	-- Title bar
	local titleBar = Instance.new("Frame")
	titleBar.Name = "TitleBar"
	titleBar.Size = UDim2.new(1, 0, 0, 50)
	titleBar.BackgroundColor3 = UITheme.Colors.Accent
	titleBar.BackgroundTransparency = 0.15
	titleBar.Parent = leaderboardFrame
	UITheme.Corner(titleBar, UITheme.CornerRadius.Large)

	-- Fix bottom corners of title
	local titleFix = Instance.new("Frame")
	titleFix.Size = UDim2.new(1, 0, 0, 20)
	titleFix.Position = UDim2.new(0, 0, 1, -20)
	titleFix.BackgroundColor3 = UITheme.Colors.Accent
	titleFix.BackgroundTransparency = 0.15
	titleFix.BorderSizePixel = 0
	titleFix.Parent = titleBar

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "Title"
	titleLabel.Size = UDim2.new(1, -10, 1, 0)
	titleLabel.Position = UDim2.new(0, 5, 0, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = "\xF0\x9F\x8F\x86 TOP KISSERS"
	titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	titleLabel.Font = UITheme.Fonts.Title
	titleLabel.TextSize = 22
	titleLabel.Parent = titleBar

	-- Scrolling entries container
	entriesFrame = Instance.new("ScrollingFrame")
	entriesFrame.Name = "Entries"
	entriesFrame.Size = UDim2.new(1, -16, 1, -60)
	entriesFrame.Position = UDim2.new(0, 8, 0, 54)
	entriesFrame.BackgroundTransparency = 1
	entriesFrame.ScrollBarThickness = 4
	entriesFrame.ScrollBarImageColor3 = UITheme.Colors.AccentGlow
	entriesFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	entriesFrame.BorderSizePixel = 0
	entriesFrame.Parent = leaderboardFrame

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 6)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = entriesFrame

	-- Toggle button
	toggleBtn = Instance.new("TextButton")
	toggleBtn.Name = "ToggleLB"
	toggleBtn.Size = UDim2.new(0, 40, 0, 40)
	toggleBtn.Position = UDim2.new(1, -305, 0, 65)
	toggleBtn.BackgroundColor3 = UITheme.Colors.LeaderboardBg
	toggleBtn.BackgroundTransparency = 0.2
	toggleBtn.Text = "\xE2\x96\xB6"
	toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	toggleBtn.Font = Enum.Font.SourceSansBold
	toggleBtn.TextSize = 22
	toggleBtn.Parent = screenGui

	UITheme.Corner(toggleBtn, UITheme.CornerRadius.Medium)

	toggleBtn.MouseButton1Click:Connect(function()
		self:ToggleLeaderboard()
	end)

	-- Start with placeholder entries
	self:UpdateEntries({})
end

function LeaderboardController:ToggleLeaderboard()
	isOpen = not isOpen
	if isOpen then
		toggleBtn.Text = "\xE2\x96\xB6"
		TweenPresets.Play(leaderboardFrame, "Slide", {
			Position = UDim2.new(1, -260, 0, 60),
		})
		TweenPresets.Play(toggleBtn, "SlideFast", {
			Position = UDim2.new(1, -305, 0, 65),
		})
	else
		toggleBtn.Text = "\xE2\x97\x80"
		TweenPresets.Play(leaderboardFrame, "Slide", {
			Position = UDim2.new(1, 10, 0, 60),
		})
		TweenPresets.Play(toggleBtn, "SlideFast", {
			Position = UDim2.new(1, -50, 0, 65),
		})
	end
end

function LeaderboardController:UpdateEntries(topKissers)
	-- Clear existing entries
	for _, item in ipairs(entryItems) do
		if item and item.Parent then
			item:Destroy()
		end
	end
	entryItems = {}

	if #topKissers == 0 then
		-- Show "no data" placeholder
		local placeholder = Instance.new("TextLabel")
		placeholder.Name = "Placeholder"
		placeholder.Size = UDim2.new(1, 0, 0, 60)
		placeholder.BackgroundTransparency = 1
		placeholder.Text = "No kisses yet!\nBe the first!"
		placeholder.TextColor3 = UITheme.Colors.TextMuted
		placeholder.Font = UITheme.Fonts.Body
		placeholder.TextSize = 16
		placeholder.TextWrapped = true
		placeholder.LayoutOrder = 1
		placeholder.Parent = entriesFrame
		table.insert(entryItems, placeholder)
		entriesFrame.CanvasSize = UDim2.new(0, 0, 0, 70)
		return
	end

	for i, entry in ipairs(topKissers) do
		local entryFrame = Instance.new("Frame")
		entryFrame.Name = "Entry_" .. i
		entryFrame.Size = UDim2.new(1, -4, 0, 36)
		entryFrame.LayoutOrder = i
		entryFrame.BackgroundTransparency = 0.3
		entryFrame.Parent = entriesFrame

		-- Rank-based coloring
		if i == 1 then
			entryFrame.BackgroundColor3 = UITheme.Colors.Rank1
			entryFrame.BackgroundTransparency = 0.6
		elseif i == 2 then
			entryFrame.BackgroundColor3 = UITheme.Colors.Rank2
			entryFrame.BackgroundTransparency = 0.65
		elseif i == 3 then
			entryFrame.BackgroundColor3 = UITheme.Colors.Rank3
			entryFrame.BackgroundTransparency = 0.65
		else
			entryFrame.BackgroundColor3 = UITheme.Colors.LeaderboardEntry
			entryFrame.BackgroundTransparency = 0.4
		end

		UITheme.Corner(entryFrame, UITheme.CornerRadius.Small)

		-- Rank number
		local rankLabel = Instance.new("TextLabel")
		rankLabel.Name = "Rank"
		rankLabel.Size = UDim2.new(0, 30, 1, 0)
		rankLabel.Position = UDim2.new(0, 4, 0, 0)
		rankLabel.BackgroundTransparency = 1
		rankLabel.Text = "#" .. tostring(entry.Rank or i)
		rankLabel.Font = UITheme.Fonts.Number
		rankLabel.TextSize = 16
		rankLabel.TextXAlignment = Enum.TextXAlignment.Center
		rankLabel.Parent = entryFrame

		if i <= 3 then
			rankLabel.TextColor3 = UITheme.Colors.Gold
		else
			rankLabel.TextColor3 = UITheme.Colors.TextMuted
		end

		-- Player name
		local nameLabel = Instance.new("TextLabel")
		nameLabel.Name = "PlayerName"
		nameLabel.Size = UDim2.new(1, -90, 1, 0)
		nameLabel.Position = UDim2.new(0, 36, 0, 0)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = entry.Name or "???"
		nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		nameLabel.Font = UITheme.Fonts.Body
		nameLabel.TextSize = 14
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
		nameLabel.Parent = entryFrame

		-- Kiss count
		local countLabel = Instance.new("TextLabel")
		countLabel.Name = "KissCount"
		countLabel.Size = UDim2.new(0, 50, 1, 0)
		countLabel.Position = UDim2.new(1, -54, 0, 0)
		countLabel.BackgroundTransparency = 1
		countLabel.Text = tostring(entry.TotalKisses or 0)
		countLabel.TextColor3 = UITheme.Colors.AccentGlow
		countLabel.Font = UITheme.Fonts.Number
		countLabel.TextSize = 15
		countLabel.TextXAlignment = Enum.TextXAlignment.Right
		countLabel.Parent = entryFrame

		-- Animate entry sliding in
		entryFrame.Position = UDim2.new(1, 50, 0, 0)
		task.delay(i * 0.05, function()
			if entryFrame.Parent then
				TweenPresets.Play(entryFrame, "SlideFast", {
					Position = UDim2.new(0, 0, 0, 0),
				})
			end
		end)

		table.insert(entryItems, entryFrame)
	end

	-- Update canvas size
	entriesFrame.CanvasSize = UDim2.new(0, 0, 0, #topKissers * 42)
end

return LeaderboardController
