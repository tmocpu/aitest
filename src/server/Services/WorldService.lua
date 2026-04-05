-- WorldService: Builds Italian-themed game world procedurally
-- Circular plaza, pedestals, Italian food props, sunset lighting, heart particles

local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local ServerStorage = game:GetService("ServerStorage")

local WorldService = {}
WorldService.__index = WorldService

local NUM_PEDESTALS = 8
local PLAZA_RADIUS = 55
local PEDESTAL_RING_RADIUS = 50
local PEDESTAL_HEIGHT = 3
local PEDESTAL_WIDTH = 8

-- Precompute pedestal positions (evenly spaced around circle)
local pedestalPositions = {}
for i = 1, NUM_PEDESTALS do
	local angle = (i - 1) * (math.pi * 2 / NUM_PEDESTALS)
	local x = math.cos(angle) * PEDESTAL_RING_RADIUS
	local z = math.sin(angle) * PEDESTAL_RING_RADIUS
	table.insert(pedestalPositions, Vector3.new(x, PEDESTAL_HEIGHT / 2, z))
end

-- Refs
local pedestals = {}
local heartEmitters = {} -- [characterName] = ParticleEmitter
local kissBindable = nil

---------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------

local function makePart(name, size, color, position, parent, props)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Color = color
	part.Position = position
	part.Anchored = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Material = Enum.Material.SmoothPlastic
	if props then
		for k, v in pairs(props) do
			part[k] = v
		end
	end
	part.Parent = parent
	return part
end

---------------------------------------------------------------------------
-- Build Functions
---------------------------------------------------------------------------

function WorldService:BuildBaseplate()
	local base = makePart("Baseplate", Vector3.new(200, 4, 200),
		Color3.fromRGB(120, 180, 90), Vector3.new(0, -2, 0), Workspace, {
			Material = Enum.Material.Grass,
			CanCollide = true,
		})
	return base
end

function WorldService:BuildPlaza()
	-- Circular plaza: large cylinder, light stone
	local plaza = Instance.new("Part")
	plaza.Name = "CentralPlaza"
	plaza.Shape = Enum.PartType.Cylinder
	plaza.Size = Vector3.new(2, PLAZA_RADIUS * 2, PLAZA_RADIUS * 2)
	plaza.CFrame = CFrame.new(0, 0.5, 0) * CFrame.Angles(0, 0, math.rad(90))
	plaza.Color = Color3.fromRGB(220, 210, 195)
	plaza.Material = Enum.Material.Cobblestone
	plaza.Anchored = true
	plaza.CanCollide = true
	plaza.TopSurface = Enum.SurfaceType.Smooth
	plaza.BottomSurface = Enum.SurfaceType.Smooth
	plaza.Parent = Workspace
	return plaza
end

function WorldService:BuildPedestals()
	local folder = Instance.new("Folder")
	folder.Name = "Pedestals"
	folder.Parent = Workspace

	for i, pos in ipairs(pedestalPositions) do
		local pedestal = Instance.new("Part")
		pedestal.Name = "Pedestal_" .. i
		pedestal.Shape = Enum.PartType.Cylinder
		pedestal.Size = Vector3.new(PEDESTAL_HEIGHT, PEDESTAL_WIDTH, PEDESTAL_WIDTH)
		pedestal.CFrame = CFrame.new(pos) * CFrame.Angles(0, 0, math.rad(90))
		pedestal.Color = Color3.fromRGB(240, 240, 245)
		pedestal.Material = Enum.Material.Marble
		pedestal.Anchored = true
		pedestal.CanCollide = true
		pedestal.TopSurface = Enum.SurfaceType.Smooth
		pedestal.BottomSurface = Enum.SurfaceType.Smooth
		pedestal.Parent = folder

		-- Decorative base ring
		local ring = Instance.new("Part")
		ring.Name = "PedestalRing_" .. i
		ring.Shape = Enum.PartType.Cylinder
		ring.Size = Vector3.new(0.4, PEDESTAL_WIDTH + 1.5, PEDESTAL_WIDTH + 1.5)
		ring.CFrame = CFrame.new(pos.X, 0.2, pos.Z) * CFrame.Angles(0, 0, math.rad(90))
		ring.Color = Color3.fromRGB(200, 180, 140)
		ring.Material = Enum.Material.Marble
		ring.Anchored = true
		ring.CanCollide = false
		ring.TopSurface = Enum.SurfaceType.Smooth
		ring.BottomSurface = Enum.SurfaceType.Smooth
		ring.Parent = folder

		pedestals[i] = pedestal
	end

	return folder
end

function WorldService:BuildItalianProps()
	local folder = Instance.new("Folder")
	folder.Name = "ItalianProps"
	folder.Parent = Workspace

	-- 4 pizza slice wedge parts scattered around
	local pizzaPositions = {
		Vector3.new(-50, 0.5, 30),
		Vector3.new(45, 0.5, -40),
		Vector3.new(-35, 0.5, -50),
		Vector3.new(55, 0.5, 45),
	}
	for i, pos in ipairs(pizzaPositions) do
		-- Pizza base (wedge = triangle slice shape)
		local slice = Instance.new("WedgePart")
		slice.Name = "PizzaSlice_" .. i
		slice.Size = Vector3.new(3, 0.4, 5)
		slice.Color = Color3.fromRGB(255, 200, 80) -- cheese color
		slice.Material = Enum.Material.SmoothPlastic
		slice.Position = pos
		slice.Orientation = Vector3.new(0, math.random(0, 360), 0)
		slice.Anchored = true
		slice.CanCollide = false
		slice.Parent = folder

		-- Sauce topping
		local sauce = Instance.new("WedgePart")
		sauce.Name = "PizzaSauce_" .. i
		sauce.Size = Vector3.new(2.4, 0.15, 4)
		sauce.Color = Color3.fromRGB(200, 60, 40) -- red sauce
		sauce.Material = Enum.Material.SmoothPlastic
		sauce.Position = pos + Vector3.new(0, 0.25, 0)
		sauce.Orientation = slice.Orientation
		sauce.Anchored = true
		sauce.CanCollide = false
		sauce.Parent = folder

		-- Pepperoni dots
		for j = 1, 3 do
			local pep = Instance.new("Part")
			pep.Name = "Pepperoni_" .. i .. "_" .. j
			pep.Shape = Enum.PartType.Cylinder
			pep.Size = Vector3.new(0.15, 0.6, 0.6)
			pep.Color = Color3.fromRGB(160, 40, 30)
			pep.Material = Enum.Material.SmoothPlastic
			pep.CFrame = CFrame.new(
				pos + Vector3.new((math.random() - 0.5) * 1.5, 0.4, (math.random() - 0.5) * 2)
			) * CFrame.Angles(math.rad(90), 0, 0)
			pep.Anchored = true
			pep.CanCollide = false
			pep.Parent = folder
		end
	end

	-- 6 pasta arch shapes (yellow cylinders with CFrame rotation)
	local pastaPositions = {
		Vector3.new(-55, 0, -15),
		Vector3.new(60, 0, 10),
		Vector3.new(-20, 0, 55),
		Vector3.new(30, 0, -55),
		Vector3.new(-60, 0, 50),
		Vector3.new(50, 0, 55),
	}
	for i, pos in ipairs(pastaPositions) do
		-- Pasta arch: curved by rotating a cylinder into an arch shape
		local arch = Instance.new("Part")
		arch.Name = "PastaArch_" .. i
		arch.Shape = Enum.PartType.Cylinder
		arch.Size = Vector3.new(1.2, 6, 6)
		arch.Color = Color3.fromRGB(245, 220, 100)
		arch.Material = Enum.Material.SmoothPlastic
		arch.Anchored = true
		arch.CanCollide = false

		-- Rotate to stand as an arch (half-circle visible above ground)
		local yRot = math.rad(math.random(0, 360))
		arch.CFrame = CFrame.new(pos.X, 3, pos.Z) *
			CFrame.Angles(0, yRot, math.rad(90))
		arch.Parent = folder

		-- Second smaller arch layered inside (ridged pasta look)
		local inner = Instance.new("Part")
		inner.Name = "PastaInner_" .. i
		inner.Shape = Enum.PartType.Cylinder
		inner.Size = Vector3.new(1.4, 4.5, 4.5)
		inner.Color = Color3.fromRGB(255, 235, 130)
		inner.Material = Enum.Material.SmoothPlastic
		inner.Anchored = true
		inner.CanCollide = false
		inner.CFrame = arch.CFrame
		inner.Parent = folder
	end

	return folder
end

function WorldService:BuildBoundaryWalls()
	local folder = Instance.new("Folder")
	folder.Name = "BoundaryWalls"
	folder.Parent = Workspace

	-- Low decorative walls in segments around the plaza edge
	local wallSegments = 16
	local wallRadius = PLAZA_RADIUS + 2
	local wallHeight = 2.5
	local wallLength = (2 * math.pi * wallRadius) / wallSegments * 0.85

	for i = 1, wallSegments do
		-- Leave gaps at 4 cardinal directions for entry
		local angle = (i - 1) * (math.pi * 2 / wallSegments)
		local cardinalGap = false
		for _, ca in ipairs({ 0, math.pi / 2, math.pi, math.pi * 3 / 2 }) do
			if math.abs(angle - ca) < 0.25 then
				cardinalGap = true
				break
			end
		end
		if cardinalGap then continue end

		local x = math.cos(angle) * wallRadius
		local z = math.sin(angle) * wallRadius

		local wall = Instance.new("Part")
		wall.Name = "Wall_" .. i
		wall.Size = Vector3.new(wallLength, wallHeight, 1.2)
		wall.CFrame = CFrame.new(x, wallHeight / 2, z) *
			CFrame.Angles(0, -angle + math.rad(90), 0)
		wall.Color = Color3.fromRGB(210, 195, 170)
		wall.Material = Enum.Material.Cobblestone
		wall.Anchored = true
		wall.CanCollide = true
		wall.TopSurface = Enum.SurfaceType.Smooth
		wall.BottomSurface = Enum.SurfaceType.Smooth
		wall.Parent = folder

		-- Wall cap
		local cap = Instance.new("Part")
		cap.Name = "WallCap_" .. i
		cap.Size = Vector3.new(wallLength + 0.4, 0.4, 1.6)
		cap.CFrame = CFrame.new(x, wallHeight + 0.2, z) *
			CFrame.Angles(0, -angle + math.rad(90), 0)
		cap.Color = Color3.fromRGB(230, 215, 190)
		cap.Material = Enum.Material.Marble
		cap.Anchored = true
		cap.CanCollide = false
		cap.Parent = folder
	end

	return folder
end

function WorldService:BuildSpawnArea()
	-- 20x20 platform offset from plaza
	local spawnPlatform = makePart("SpawnPlatform", Vector3.new(20, 1, 20),
		Color3.fromRGB(240, 235, 225), Vector3.new(0, 0.5, PLAZA_RADIUS + 30), Workspace, {
			Material = Enum.Material.Marble,
			CanCollide = true,
		})

	local spawnLoc = Instance.new("SpawnLocation")
	spawnLoc.Name = "MainSpawn"
	spawnLoc.Size = Vector3.new(8, 1, 8)
	spawnLoc.Position = Vector3.new(0, 1.5, PLAZA_RADIUS + 30)
	spawnLoc.Anchored = true
	spawnLoc.Material = Enum.Material.SmoothPlastic
	spawnLoc.Color = Color3.fromRGB(255, 110, 180) -- hot pink
	spawnLoc.CanCollide = true
	spawnLoc.TopSurface = Enum.SurfaceType.Smooth
	spawnLoc.BottomSurface = Enum.SurfaceType.Smooth
	spawnLoc.Parent = Workspace

	-- Path connecting spawn to plaza
	local path = makePart("SpawnPath", Vector3.new(6, 0.5, 28),
		Color3.fromRGB(210, 200, 185), Vector3.new(0, 0.25, PLAZA_RADIUS + 14), Workspace, {
			Material = Enum.Material.Cobblestone,
			CanCollide = true,
		})

	return spawnPlatform
end

---------------------------------------------------------------------------
-- Lighting & Atmosphere
---------------------------------------------------------------------------

function WorldService:SetupLighting()
	-- Warm afternoon with color
	Lighting.ClockTime = 15
	Lighting.Brightness = 3
	Lighting.Ambient = Color3.fromRGB(160, 150, 180)
	Lighting.OutdoorAmbient = Color3.fromRGB(180, 170, 160)
	Lighting.ColorShift_Top = Color3.fromRGB(255, 220, 180)
	Lighting.ColorShift_Bottom = Color3.fromRGB(160, 130, 150)
	Lighting.GlobalShadows = true
	Lighting.EnvironmentDiffuseScale = 1
	Lighting.EnvironmentSpecularScale = 0.5

	-- Sky
	local sky = Lighting:FindFirstChildOfClass("Sky")
	if not sky then
		sky = Instance.new("Sky")
		sky.Parent = Lighting
	end
	sky.CelestialBodiesShown = true
	sky.StarCount = 3000

	-- Bloom for warm dreamy look
	local bloom = Lighting:FindFirstChildOfClass("BloomEffect")
	if not bloom then
		bloom = Instance.new("BloomEffect")
		bloom.Parent = Lighting
	end
	bloom.Intensity = 0.3
	bloom.Size = 24
	bloom.Threshold = 1.8

	-- Color correction: warm saturation
	local cc = Lighting:FindFirstChildOfClass("ColorCorrectionEffect")
	if not cc then
		cc = Instance.new("ColorCorrectionEffect")
		cc.Parent = Lighting
	end
	cc.Brightness = 0.03
	cc.Contrast = 0.08
	cc.Saturation = 0.25
	cc.TintColor = Color3.fromRGB(255, 245, 235) -- warm tint

	-- Sun rays
	local rays = Lighting:FindFirstChildOfClass("SunRaysEffect")
	if not rays then
		rays = Instance.new("SunRaysEffect")
		rays.Parent = Lighting
	end
	rays.Intensity = 0.12
	rays.Spread = 0.7

	-- Atmosphere: warm haze
	local atmo = Lighting:FindFirstChildOfClass("Atmosphere")
	if not atmo then
		atmo = Instance.new("Atmosphere")
		atmo.Parent = Lighting
	end
	atmo.Density = 0.15
	atmo.Offset = 0
	atmo.Color = Color3.fromRGB(200, 210, 255) -- soft blue sky
	atmo.Decay = Color3.fromRGB(220, 200, 180)
	atmo.Glare = 0.1
	atmo.Haze = 1
end

function WorldService:SetupPedestalLights()
	for i, pedestal in ipairs(pedestals) do
		local light = Instance.new("PointLight")
		light.Name = "PedestalLight"
		light.Color = Color3.fromRGB(255, 220, 170) -- soft warm glow
		light.Brightness = 1.2
		light.Range = 16
		light.Shadows = false
		light.Parent = pedestal
	end
end

function WorldService:SetupPlazaSpotlight()
	-- Anchor part at center for the spotlight
	local anchor = Instance.new("Part")
	anchor.Name = "PlazaSpotlightAnchor"
	anchor.Size = Vector3.new(1, 1, 1)
	anchor.Position = Vector3.new(0, 0.5, 0)
	anchor.Transparency = 1
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.Parent = Workspace

	local spot = Instance.new("SpotLight")
	spot.Name = "PlazaBeam"
	spot.Face = Enum.NormalId.Top
	spot.Brightness = 3
	spot.Range = 60
	spot.Angle = 45
	spot.Color = Color3.fromRGB(255, 240, 200)
	spot.Shadows = true
	spot.Parent = anchor
end

---------------------------------------------------------------------------
-- Heart Particle Emitters
---------------------------------------------------------------------------

local function createHeartEmitter(parent)
	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "HeartEmitter"

	-- Heart-like appearance using default particle
	emitter.Color = ColorSequence.new(
		Color3.fromRGB(255, 100, 150),
		Color3.fromRGB(255, 60, 120)
	)
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(0.5, 0.6),
		NumberSequenceKeypoint.new(1, 0),
	})
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(0.8, 0.4),
		NumberSequenceKeypoint.new(1, 1),
	})
	emitter.Lifetime = NumberRange.new(1.5, 2.5)
	emitter.Rate = 0.5 -- slow idle hearts
	emitter.Speed = NumberRange.new(1, 2)
	emitter.SpreadAngle = Vector2.new(30, 30)
	emitter.Rotation = NumberRange.new(0, 360)
	emitter.RotSpeed = NumberRange.new(-30, 30)
	emitter.EmissionDirection = Enum.NormalId.Top
	emitter.LightEmission = 0.4
	emitter.Enabled = false -- activated in :Start()
	emitter.Parent = parent

	return emitter
end

function WorldService:SetupHeartEmitters()
	local npcsFolder = Workspace:FindFirstChild("NPCs")
	if not npcsFolder then return end

	for _, model in ipairs(npcsFolder:GetChildren()) do
		if model:IsA("Model") then
			local head = model:FindFirstChild("Head")
			local nameVal = model:FindFirstChild("CharacterName")
			local charName = nameVal and nameVal:IsA("StringValue") and nameVal.Value or model.Name

			if head then
				local emitter = createHeartEmitter(head)
				heartEmitters[charName] = emitter
			end
		end
	end
end

local function burstHearts(characterName)
	local emitter = heartEmitters[characterName]
	if emitter then
		emitter:Emit(20)
	end
end

---------------------------------------------------------------------------
-- BindableEvent for cross-service kiss notification
---------------------------------------------------------------------------

function WorldService:CreateKissBindable()
	kissBindable = ServerStorage:FindFirstChild("KissHappened")
	if not kissBindable then
		kissBindable = Instance.new("BindableEvent")
		kissBindable.Name = "KissHappened"
		kissBindable.Parent = ServerStorage
	end
	return kissBindable
end

---------------------------------------------------------------------------
-- Service Interface
---------------------------------------------------------------------------

function WorldService:Init()
	self:BuildBaseplate()
	self:BuildPlaza()
	self:BuildPedestals()
	self:BuildItalianProps()
	self:BuildBoundaryWalls()
	self:BuildSpawnArea()
	self:SetupLighting()
	self:SetupPedestalLights()
	self:SetupPlazaSpotlight()
	self:CreateKissBindable()
	print("[WorldService] World built")
end

function WorldService:Start()
	-- Setup heart emitters (NPCs should exist by now from ModelService)
	self:SetupHeartEmitters()

	-- Activate all idle emitters
	for _, emitter in pairs(heartEmitters) do
		emitter.Enabled = true
	end

	-- Listen for kiss events to burst hearts
	if kissBindable then
		kissBindable.Event:Connect(function(characterName)
			burstHearts(characterName)
		end)
	end

	print("[WorldService] Particles active, kiss listener connected")
end

-- Expose pedestal positions for ModelService
function WorldService.GetPedestalPositions()
	local positions = {}
	for i, pos in ipairs(pedestalPositions) do
		-- Character spawns on top of pedestal
		positions[i] = Vector3.new(pos.X, PEDESTAL_HEIGHT + 1, pos.Z)
	end
	return positions
end

return WorldService
