-- VFXController: Particle effects, floating hearts, sparkles, super kiss VFX, NPC reactions
-- All effects built from code using ParticleEmitters and tweened parts

local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local TweenPresets = require(Shared:WaitForChild("Modules"):WaitForChild("TweenPresets"))
local UITheme = require(Shared:WaitForChild("Modules"):WaitForChild("UITheme"))

local VFXController = {}
VFXController.__index = VFXController

local vfxFolder = nil

function VFXController:Init()
	vfxFolder = Workspace:FindFirstChild("VFXFolder")
	if not vfxFolder then
		vfxFolder = Instance.new("Folder")
		vfxFolder.Name = "VFXFolder"
		vfxFolder.Parent = Workspace
	end
end

-- Spawn floating heart particles at a world position --
function VFXController:SpawnKissHearts(position)
	for i = 1, 6 do
		task.spawn(function()
			local heart = Instance.new("Part")
			heart.Name = "KissHeart"
			heart.Size = Vector3.new(0.8, 0.8, 0.2)
			heart.Shape = Enum.PartType.Ball
			heart.Material = Enum.Material.Neon
			heart.Anchored = true
			heart.CanCollide = false
			heart.CastShadow = false

			-- Random pink/red shades
			local colors = {
				Color3.fromRGB(255, 80, 130),
				Color3.fromRGB(255, 120, 160),
				Color3.fromRGB(255, 60, 100),
				Color3.fromRGB(255, 150, 180),
				Color3.fromRGB(255, 100, 140),
				Color3.fromRGB(255, 180, 200),
			}
			heart.Color = colors[i]

			-- Random spread
			local offsetX = (math.random() - 0.5) * 4
			local offsetZ = (math.random() - 0.5) * 4
			heart.Position = position + Vector3.new(offsetX, 1 + math.random() * 2, offsetZ)
			heart.Parent = vfxFolder

			-- Billboard so it faces camera
			local bb = Instance.new("BillboardGui")
			bb.Size = UDim2.new(0, 40, 0, 40)
			bb.Adornee = heart
			bb.AlwaysOnTop = false
			bb.Parent = heart

			local heartLabel = Instance.new("TextLabel")
			heartLabel.Size = UDim2.new(1, 0, 1, 0)
			heartLabel.BackgroundTransparency = 1
			heartLabel.Text = "\xE2\x9D\xA4"
			heartLabel.TextColor3 = heart.Color
			heartLabel.TextSize = 28
			heartLabel.Font = Enum.Font.SourceSans
			heartLabel.TextTransparency = 0
			heartLabel.Parent = bb

			-- Float up and fade
			local targetPos = heart.Position + Vector3.new(
				(math.random() - 0.5) * 2,
				4 + math.random() * 3,
				(math.random() - 0.5) * 2
			)

			local floatInfo = TweenInfo.new(
				1.0 + math.random() * 0.5,
				Enum.EasingStyle.Quad,
				Enum.EasingDirection.Out
			)
			local floatTween = TweenService:Create(heart, floatInfo, { Position = targetPos })
			local fadeTween = TweenService:Create(heartLabel, floatInfo, { TextTransparency = 1 })

			floatTween:Play()
			fadeTween:Play()

			-- Scale up slightly
			local scaleInfo = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
			local scaleTween = TweenService:Create(heart, scaleInfo, {
				Size = Vector3.new(1.2, 1.2, 0.3)
			})
			scaleTween:Play()

			floatTween.Completed:Wait()
			heart:Destroy()
		end)
	end
end

-- Sparkle burst (for combo milestones) --
function VFXController:SpawnSparkles(position)
	for i = 1, 12 do
		task.spawn(function()
			local spark = Instance.new("Part")
			spark.Name = "Sparkle"
			spark.Size = Vector3.new(0.3, 0.3, 0.3)
			spark.Shape = Enum.PartType.Ball
			spark.Material = Enum.Material.Neon
			spark.Anchored = true
			spark.CanCollide = false
			spark.CastShadow = false
			spark.Color = Color3.fromRGB(
				200 + math.random(55),
				200 + math.random(55),
				100 + math.random(155)
			)
			spark.Position = position + Vector3.new(0, 2, 0)
			spark.Parent = vfxFolder

			-- Explode outward
			local angle = (i / 12) * math.pi * 2
			local radius = 3 + math.random() * 2
			local targetPos = position + Vector3.new(
				math.cos(angle) * radius,
				2 + math.random() * 4,
				math.sin(angle) * radius
			)

			local info = TweenInfo.new(0.6 + math.random() * 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			local moveTween = TweenService:Create(spark, info, { Position = targetPos, Size = Vector3.new(0.05, 0.05, 0.05), Transparency = 1 })
			moveTween:Play()
			moveTween.Completed:Wait()
			spark:Destroy()
		end)
	end
end

-- Super Kiss mega effect --
function VFXController:SpawnSuperKissVFX(position)
	-- Big expanding ring
	task.spawn(function()
		local ring = Instance.new("Part")
		ring.Name = "SuperRing"
		ring.Size = Vector3.new(1, 0.2, 1)
		ring.Shape = Enum.PartType.Cylinder
		ring.Material = Enum.Material.Neon
		ring.Anchored = true
		ring.CanCollide = false
		ring.CastShadow = false
		ring.Color = Color3.fromRGB(255, 60, 200)
		ring.Position = position + Vector3.new(0, 2, 0)
		ring.Orientation = Vector3.new(0, 0, 90)
		ring.Parent = vfxFolder

		local info = TweenInfo.new(1.0, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		local expand = TweenService:Create(ring, info, {
			Size = Vector3.new(30, 0.3, 30),
			Transparency = 1,
		})
		expand:Play()
		expand.Completed:Wait()
		ring:Destroy()
	end)

	-- Lots of hearts
	self:SpawnKissHearts(position)
	task.delay(0.2, function() self:SpawnKissHearts(position) end)
	task.delay(0.4, function() self:SpawnKissHearts(position) end)

	-- Sparkle explosion
	self:SpawnSparkles(position)

	-- Vertical beam
	task.spawn(function()
		local beam = Instance.new("Part")
		beam.Name = "SuperBeam"
		beam.Size = Vector3.new(2, 0, 2)
		beam.Material = Enum.Material.Neon
		beam.Anchored = true
		beam.CanCollide = false
		beam.CastShadow = false
		beam.Color = Color3.fromRGB(255, 200, 255)
		beam.Position = position + Vector3.new(0, 2, 0)
		beam.Transparency = 0.3
		beam.Parent = vfxFolder

		local info = TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		local grow = TweenService:Create(beam, info, {
			Size = Vector3.new(3, 60, 3),
			Position = position + Vector3.new(0, 32, 0),
		})
		grow:Play()
		grow.Completed:Wait()

		local fadeInfo = TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		local fade = TweenService:Create(beam, fadeInfo, { Transparency = 1, Size = Vector3.new(6, 60, 6) })
		fade:Play()
		fade.Completed:Wait()
		beam:Destroy()
	end)
end

-- NPC bump reaction (scale bounce) --
function VFXController:BumpNPC(model)
	task.spawn(function()
		-- Find all visible parts and tween them
		local parts = {}
		for _, part in ipairs(model:GetDescendants()) do
			if part:IsA("BasePart") and part.Transparency < 1 then
				table.insert(parts, { part = part, origSize = part.Size, origPos = part.Position })
			end
		end

		-- Quick jump up
		local rootPart = model.PrimaryPart or model:FindFirstChild("HumanoidRootPart")
		if not rootPart then return end

		local origPos = rootPart.Position
		local jumpInfo = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		local jumpTween = TweenService:Create(rootPart, jumpInfo, {
			Position = origPos + Vector3.new(0, 1.5, 0),
		})

		-- Move all welded parts with root
		for _, data in ipairs(parts) do
			if data.part ~= rootPart then
				TweenService:Create(data.part, jumpInfo, {
					Position = data.origPos + Vector3.new(0, 1.5, 0),
				}):Play()
			end
		end

		jumpTween:Play()
		jumpTween.Completed:Wait()

		-- Bounce back down
		local settleInfo = TweenInfo.new(0.3, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out)
		local settleTween = TweenService:Create(rootPart, settleInfo, {
			Position = origPos,
		})

		for _, data in ipairs(parts) do
			if data.part ~= rootPart then
				TweenService:Create(data.part, settleInfo, {
					Position = data.origPos,
				}):Play()
			end
		end

		settleTween:Play()
	end)
end

-- Floating +coins text at world position --
function VFXController:SpawnCoinPopup(position, amount)
	task.spawn(function()
		local anchor = Instance.new("Part")
		anchor.Name = "CoinPopup"
		anchor.Size = Vector3.new(0.1, 0.1, 0.1)
		anchor.Transparency = 1
		anchor.Anchored = true
		anchor.CanCollide = false
		anchor.Position = position + Vector3.new(0, 4, 0)
		anchor.Parent = vfxFolder

		local bb = Instance.new("BillboardGui")
		bb.Size = UDim2.new(0, 120, 0, 40)
		bb.Adornee = anchor
		bb.AlwaysOnTop = true
		bb.Parent = anchor

		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, 0, 1, 0)
		label.BackgroundTransparency = 1
		label.Text = "+" .. tostring(amount)
		label.TextColor3 = Color3.fromRGB(255, 220, 50)
		label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
		label.TextStrokeTransparency = 0.2
		label.Font = Enum.Font.FredokaOne
		label.TextSize = 32
		label.Parent = bb

		-- Float up and fade
		local floatInfo = TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		local floatTween = TweenService:Create(anchor, floatInfo, {
			Position = anchor.Position + Vector3.new(0, 5, 0),
		})
		local fadeTween = TweenService:Create(label, floatInfo, {
			TextTransparency = 1,
			TextStrokeTransparency = 1,
		})

		floatTween:Play()
		fadeTween:Play()
		floatTween.Completed:Wait()
		anchor:Destroy()
	end)
end

return VFXController
