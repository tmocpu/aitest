-- WorldSetup: Builds the map environment (platform, lighting, atmosphere)
-- No external assets required - purely procedural

local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")

local WorldSetup = {}
WorldSetup.__index = WorldSetup

function WorldSetup:Init()
	self:BuildMap()
	self:SetupLighting()
	self:SetupAtmosphere()
	print("[WorldSetup] World environment built")
end

function WorldSetup:Start()
	-- Nothing to start
end

function WorldSetup:BuildMap()
	-- Main platform
	local platform = Instance.new("Part")
	platform.Name = "MainPlatform"
	platform.Size = Vector3.new(200, 4, 200)
	platform.Position = Vector3.new(0, -2, 0)
	platform.Anchored = true
	platform.Material = Enum.Material.SmoothPlastic
	platform.Color = Color3.fromRGB(180, 220, 160)
	platform.TopSurface = Enum.SurfaceType.Smooth
	platform.BottomSurface = Enum.SurfaceType.Smooth
	platform.Parent = Workspace

	-- Decorative border ring
	local borderColors = {
		Color3.fromRGB(255, 130, 170),
		Color3.fromRGB(130, 200, 255),
		Color3.fromRGB(255, 220, 100),
		Color3.fromRGB(170, 130, 255),
	}
	for i = 1, 4 do
		local border = Instance.new("Part")
		border.Name = "Border_" .. i
		border.Anchored = true
		border.Material = Enum.Material.SmoothPlastic
		border.Color = borderColors[i]
		border.TopSurface = Enum.SurfaceType.Smooth
		border.BottomSurface = Enum.SurfaceType.Smooth

		if i == 1 then
			border.Size = Vector3.new(200, 2, 4)
			border.Position = Vector3.new(0, 0.5, -100)
		elseif i == 2 then
			border.Size = Vector3.new(200, 2, 4)
			border.Position = Vector3.new(0, 0.5, 100)
		elseif i == 3 then
			border.Size = Vector3.new(4, 2, 200)
			border.Position = Vector3.new(-100, 0.5, 0)
		else
			border.Size = Vector3.new(4, 2, 200)
			border.Position = Vector3.new(100, 0.5, 0)
		end

		border.Parent = Workspace
	end

	-- Spawn platform (raised, center)
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "SpawnPlatform"
	spawn.Size = Vector3.new(16, 1, 16)
	spawn.Position = Vector3.new(0, 0.5, 40)
	spawn.Anchored = true
	spawn.Material = Enum.Material.SmoothPlastic
	spawn.Color = Color3.fromRGB(255, 255, 255)
	spawn.TopSurface = Enum.SurfaceType.Smooth
	spawn.BottomSurface = Enum.SurfaceType.Smooth
	spawn.Parent = Workspace

	-- Decorative trees / bushes (simple sphere+cylinder combos)
	local treePositions = {
		Vector3.new(-70, 0, -60),
		Vector3.new(70, 0, -50),
		Vector3.new(-50, 0, 60),
		Vector3.new(60, 0, 70),
		Vector3.new(-80, 0, 10),
		Vector3.new(80, 0, -10),
	}
	for i, pos in ipairs(treePositions) do
		local trunk = Instance.new("Part")
		trunk.Name = "TreeTrunk_" .. i
		trunk.Size = Vector3.new(2, 6, 2)
		trunk.Position = pos + Vector3.new(0, 3, 0)
		trunk.Anchored = true
		trunk.Material = Enum.Material.SmoothPlastic
		trunk.Color = Color3.fromRGB(140, 100, 60)
		trunk.CanCollide = true
		trunk.Parent = Workspace

		local canopy = Instance.new("Part")
		canopy.Name = "TreeCanopy_" .. i
		canopy.Size = Vector3.new(8, 7, 8)
		canopy.Position = pos + Vector3.new(0, 8, 0)
		canopy.Anchored = true
		canopy.Material = Enum.Material.SmoothPlastic
		canopy.CanCollide = false
		canopy.Shape = Enum.PartType.Ball
		-- Alternate green shades
		local greens = {
			Color3.fromRGB(80, 180, 90),
			Color3.fromRGB(100, 200, 80),
			Color3.fromRGB(60, 160, 100),
		}
		canopy.Color = greens[(i % 3) + 1]
		canopy.Parent = Workspace
	end

	-- Decorative flowers / mushrooms near NPC areas
	local decoPositions = {
		Vector3.new(-25, 0, -15),
		Vector3.new(5, 0, -35),
		Vector3.new(30, 0, -15),
		Vector3.new(55, 0, -30),
		Vector3.new(-35, 0, 25),
		Vector3.new(10, 0, 30),
	}
	for i, pos in ipairs(decoPositions) do
		local stem = Instance.new("Part")
		stem.Name = "FlowerStem_" .. i
		stem.Size = Vector3.new(0.3, 2, 0.3)
		stem.Position = pos + Vector3.new(0, 1, 0)
		stem.Anchored = true
		stem.Material = Enum.Material.SmoothPlastic
		stem.Color = Color3.fromRGB(80, 180, 60)
		stem.CanCollide = false
		stem.Parent = Workspace

		local petal = Instance.new("Part")
		petal.Name = "FlowerPetal_" .. i
		petal.Shape = Enum.PartType.Ball
		petal.Size = Vector3.new(1.6, 1.2, 1.6)
		petal.Position = pos + Vector3.new(0, 2.4, 0)
		petal.Anchored = true
		petal.Material = Enum.Material.SmoothPlastic
		petal.CanCollide = false
		local flowerColors = {
			Color3.fromRGB(255, 120, 150),
			Color3.fromRGB(255, 200, 80),
			Color3.fromRGB(180, 130, 255),
			Color3.fromRGB(100, 200, 255),
			Color3.fromRGB(255, 160, 100),
			Color3.fromRGB(255, 100, 100),
		}
		petal.Color = flowerColors[i]
		petal.Parent = Workspace
	end
end

function WorldSetup:SetupLighting()
	Lighting.Ambient = Color3.fromRGB(140, 130, 160)
	Lighting.OutdoorAmbient = Color3.fromRGB(150, 150, 170)
	Lighting.Brightness = 2
	Lighting.ClockTime = 14
	Lighting.GeographicLatitude = 40
	Lighting.GlobalShadows = true
	Lighting.EnvironmentDiffuseScale = 1
	Lighting.EnvironmentSpecularScale = 0.5

	-- Colorful sky
	local sky = Lighting:FindFirstChildOfClass("Sky")
	if not sky then
		sky = Instance.new("Sky")
		sky.Parent = Lighting
	end
	sky.CelestialBodiesShown = true
	sky.StarCount = 1000

	-- Bloom for dreamy cartoony look
	local bloom = Lighting:FindFirstChildOfClass("BloomEffect")
	if not bloom then
		bloom = Instance.new("BloomEffect")
		bloom.Parent = Lighting
	end
	bloom.Intensity = 0.4
	bloom.Size = 30
	bloom.Threshold = 1.5

	-- Color correction for saturation boost
	local cc = Lighting:FindFirstChildOfClass("ColorCorrectionEffect")
	if not cc then
		cc = Instance.new("ColorCorrectionEffect")
		cc.Parent = Lighting
	end
	cc.Brightness = 0.05
	cc.Contrast = 0.1
	cc.Saturation = 0.3
	cc.TintColor = Color3.fromRGB(255, 250, 245)

	-- Sunrays
	local rays = Lighting:FindFirstChildOfClass("SunRaysEffect")
	if not rays then
		rays = Instance.new("SunRaysEffect")
		rays.Parent = Lighting
	end
	rays.Intensity = 0.08
	rays.Spread = 0.6
end

function WorldSetup:SetupAtmosphere()
	local atmo = Lighting:FindFirstChildOfClass("Atmosphere")
	if not atmo then
		atmo = Instance.new("Atmosphere")
		atmo.Parent = Lighting
	end
	atmo.Density = 0.3
	atmo.Offset = 0.25
	atmo.Color = Color3.fromRGB(200, 190, 230)
	atmo.Decay = Color3.fromRGB(120, 100, 160)
	atmo.Glare = 0.2
	atmo.Haze = 2
end

return WorldSetup
