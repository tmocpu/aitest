-- ModelService: Procedurally builds all brainrot NPC characters from BaseParts
-- No external assets required - everything is built from primitives

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local ModelService = {}
ModelService.__index = ModelService

local CHARACTER_SPECS = {
	{
		Name = "Pizzicato Pangolino",
		Position = Vector3.new(50, 4, 0),
		BodyColor = Color3.fromRGB(160, 120, 70),
		AccentColor = Color3.fromRGB(190, 150, 90),
		HeadColor = Color3.fromRGB(175, 135, 80),
		LegColor = Color3.fromRGB(140, 100, 55),
		HeadSize = Vector3.new(3.6, 3.2, 3.6),
		BodySize = Vector3.new(5.0, 4.0, 4.6),
		ArmSize = Vector3.new(1.4, 3.4, 1.4),
		LegSize = Vector3.new(1.5, 2.4, 1.5),
		HeadOffset = Vector3.new(0, 5.6, 0),
		ArmOffsetL = Vector3.new(-3.4, 2.6, 0),
		ArmOffsetR = Vector3.new(3.4, 2.6, 0),
		LegOffsetL = Vector3.new(-1.4, -0.8, 0),
		LegOffsetR = Vector3.new(1.4, -0.8, 0),
		HeadShape = "Sphere",
		UniqueFeature = "ScalePlates",
	},
	{
		Name = "Bombardino Bufalo",
		Position = Vector3.new(35.4, 4, 35.4),
		BodyColor = Color3.fromRGB(100, 100, 110),
		AccentColor = Color3.fromRGB(70, 70, 80),
		HeadColor = Color3.fromRGB(90, 90, 100),
		LegColor = Color3.fromRGB(80, 80, 90),
		HeadSize = Vector3.new(5.0, 4.2, 4.6),
		BodySize = Vector3.new(8.0, 5.8, 5.6),
		ArmSize = Vector3.new(2.0, 4.2, 2.0),
		LegSize = Vector3.new(1.8, 1.6, 1.8),
		HeadOffset = Vector3.new(0, 7.8, 0),
		ArmOffsetL = Vector3.new(-5.2, 3.2, 0),
		ArmOffsetR = Vector3.new(5.2, 3.2, 0),
		LegOffsetL = Vector3.new(-2.2, -1.0, 0),
		LegOffsetR = Vector3.new(2.2, -1.0, 0),
		HeadShape = "Block",
		UniqueFeature = "Horns",
	},
	{
		Name = "Trombettino Tartaruga",
		Position = Vector3.new(0, 4, 50),
		BodyColor = Color3.fromRGB(60, 140, 70),
		AccentColor = Color3.fromRGB(80, 110, 50),
		HeadColor = Color3.fromRGB(70, 160, 80),
		LegColor = Color3.fromRGB(50, 120, 55),
		HeadSize = Vector3.new(3.4, 3.0, 3.4),
		BodySize = Vector3.new(6.2, 3.6, 5.6),
		ArmSize = Vector3.new(1.4, 2.6, 1.4),
		LegSize = Vector3.new(1.5, 2.0, 1.5),
		HeadOffset = Vector3.new(0, 5.2, 0),
		ArmOffsetL = Vector3.new(-4.0, 2.2, 0),
		ArmOffsetR = Vector3.new(4.0, 2.2, 0),
		LegOffsetL = Vector3.new(-1.6, -0.6, 0),
		LegOffsetR = Vector3.new(1.6, -0.6, 0),
		HeadShape = "Sphere",
		UniqueFeature = "Shell",
	},
	{
		Name = "Cappellino Capibara",
		Position = Vector3.new(-35.4, 4, 35.4),
		BodyColor = Color3.fromRGB(180, 150, 100),
		AccentColor = Color3.fromRGB(200, 170, 120),
		HeadColor = Color3.fromRGB(190, 160, 110),
		LegColor = Color3.fromRGB(160, 130, 85),
		HeadSize = Vector3.new(5.6, 3.2, 4.2),
		BodySize = Vector3.new(7.0, 5.0, 5.0),
		ArmSize = Vector3.new(1.6, 3.4, 1.6),
		LegSize = Vector3.new(1.6, 2.4, 1.6),
		HeadOffset = Vector3.new(0, 6.6, 0),
		ArmOffsetL = Vector3.new(-4.6, 3.0, 0),
		ArmOffsetR = Vector3.new(4.6, 3.0, 0),
		LegOffsetL = Vector3.new(-2.0, -0.6, 0),
		LegOffsetR = Vector3.new(2.0, -0.6, 0),
		HeadShape = "Block",
		UniqueFeature = "FlatCap",
	},
	{
		Name = "Fischietto Fenicottero",
		Position = Vector3.new(-50, 4, 0),
		BodyColor = Color3.fromRGB(255, 130, 150),
		AccentColor = Color3.fromRGB(255, 100, 120),
		HeadColor = Color3.fromRGB(255, 160, 170),
		LegColor = Color3.fromRGB(255, 110, 130),
		HeadSize = Vector3.new(2.6, 2.6, 2.6),
		BodySize = Vector3.new(3.6, 4.2, 3.4),
		ArmSize = Vector3.new(1.0, 4.0, 1.0),
		LegSize = Vector3.new(0.8, 5.2, 0.8),
		HeadOffset = Vector3.new(0, 7.8, 0),
		ArmOffsetL = Vector3.new(-2.6, 3.2, 0),
		ArmOffsetR = Vector3.new(2.6, 3.2, 0),
		LegOffsetL = Vector3.new(-0.6, -1.0, 0),
		LegOffsetR = Vector3.new(0.6, -1.0, 0),
		HeadShape = "Sphere",
		UniqueFeature = "Beak",
	},
	{
		Name = "Urlando Unicorno",
		Position = Vector3.new(-35.4, 4, -35.4),
		BodyColor = Color3.fromRGB(245, 245, 255),
		AccentColor = Color3.fromRGB(200, 150, 255),
		HeadColor = Color3.fromRGB(250, 250, 255),
		LegColor = Color3.fromRGB(230, 230, 245),
		HeadSize = Vector3.new(4.6, 4.2, 4.2),
		BodySize = Vector3.new(7.0, 5.6, 5.0),
		ArmSize = Vector3.new(1.6, 4.2, 1.6),
		LegSize = Vector3.new(1.8, 3.0, 1.8),
		HeadOffset = Vector3.new(0, 7.4, 0),
		ArmOffsetL = Vector3.new(-4.6, 3.4, 0),
		ArmOffsetR = Vector3.new(4.6, 3.4, 0),
		LegOffsetL = Vector3.new(-2.0, -1.0, 0),
		LegOffsetR = Vector3.new(2.0, -1.0, 0),
		HeadShape = "Sphere",
		UniqueFeature = "Horn",
	},
	{
		Name = "Saltellino Salamandra",
		Position = Vector3.new(0, 4, -50),
		BodyColor = Color3.fromRGB(230, 130, 30),
		AccentColor = Color3.fromRGB(40, 40, 40),
		HeadColor = Color3.fromRGB(240, 140, 40),
		LegColor = Color3.fromRGB(220, 120, 25),
		HeadSize = Vector3.new(3.4, 2.4, 3.0),
		BodySize = Vector3.new(6.0, 2.6, 4.0),
		ArmSize = Vector3.new(1.2, 2.4, 1.2),
		LegSize = Vector3.new(1.4, 1.6, 1.4),
		HeadOffset = Vector3.new(0, 3.8, 0),
		ArmOffsetL = Vector3.new(-4.0, 1.6, 0),
		ArmOffsetR = Vector3.new(4.0, 1.6, 0),
		LegOffsetL = Vector3.new(-2.2, 0.0, 0),
		LegOffsetR = Vector3.new(2.2, 0.0, 0),
		HeadShape = "Block",
		UniqueFeature = "Spots",
	},
	{
		Name = "Magnifico Macarone",
		Position = Vector3.new(35.4, 4, -35.4),
		BodyColor = Color3.fromRGB(245, 220, 100),
		AccentColor = Color3.fromRGB(255, 240, 140),
		HeadColor = Color3.fromRGB(250, 230, 120),
		LegColor = Color3.fromRGB(235, 210, 90),
		HeadSize = Vector3.new(3.0, 2.6, 3.0),
		BodySize = Vector3.new(4.6, 6.6, 4.6),
		ArmSize = Vector3.new(1.2, 3.6, 1.2),
		LegSize = Vector3.new(1.4, 2.4, 1.4),
		HeadOffset = Vector3.new(0, 7.6, 0),
		ArmOffsetL = Vector3.new(-3.2, 3.6, 0),
		ArmOffsetR = Vector3.new(3.2, 3.6, 0),
		LegOffsetL = Vector3.new(-1.4, -0.6, 0),
		LegOffsetR = Vector3.new(1.4, -0.6, 0),
		HeadShape = "Cylinder",
		UniqueFeature = "PastaCurls",
	},
}

-- Helpers --

local function makePart(name, size, color, parent, position, shape, anchored)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Color = color
	part.Position = position
	part.Anchored = anchored ~= false
	part.CanCollide = false
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Material = Enum.Material.SmoothPlastic

	if shape == "Sphere" then
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.Sphere
		mesh.Parent = part
	elseif shape == "Cylinder" then
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.Cylinder
		mesh.Parent = part
	end

	part.Parent = parent
	return part
end

local function makeWeld(part0, part1)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = part0
	weld.Part1 = part1
	weld.Parent = part0
end

local function addBillboard(model, charName, headPart)
	local bbGui = Instance.new("BillboardGui")
	bbGui.Name = "NameTag"
	bbGui.Adornee = headPart
	bbGui.Size = UDim2.new(0, 280, 0, 50)
	bbGui.StudsOffset = Vector3.new(0, 4, 0)
	bbGui.AlwaysOnTop = false
	bbGui.MaxDistance = 60
	bbGui.Parent = model

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLabel"
	nameLabel.Size = UDim2.new(1, 0, 1, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = charName
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextStrokeColor3 = Color3.fromRGB(30, 20, 50)
	nameLabel.TextStrokeTransparency = 0
	nameLabel.Font = Enum.Font.FredokaOne
	nameLabel.TextScaled = true
	nameLabel.Parent = bbGui

	return bbGui
end

local function addProximityPrompt(bodyPart)
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "KissPrompt"
	prompt.ActionText = "\xF0\x9F\x92\x8B Kiss!"
	prompt.ObjectText = ""
	prompt.MaxActivationDistance = 10
	prompt.HoldDuration = 0
	prompt.RequiresLineOfSight = false
	prompt.Enabled = false -- enabled in :Start()
	prompt.Parent = bodyPart
	return prompt
end

local function addStringValue(model, charName)
	local sv = Instance.new("StringValue")
	sv.Name = "CharacterName"
	sv.Value = charName
	sv.Parent = model
end

-- Unique feature builders --

local function buildScalePlates(spec, model, rootPos)
	-- Wedge parts running down the back like pangolin scales
	local plateColor = Color3.fromRGB(
		math.min(255, spec.AccentColor.R * 255 + 20),
		math.min(255, spec.AccentColor.G * 255 + 10),
		spec.AccentColor.B * 255
	)
	for i = 1, 5 do
		local plate = Instance.new("WedgePart")
		plate.Name = "Scale_" .. i
		plate.Size = Vector3.new(1.8 - i * 0.2, 0.6, 0.8)
		plate.Color = spec.AccentColor
		plate.Material = Enum.Material.SmoothPlastic
		plate.Anchored = true
		plate.CanCollide = false
		local yOff = 1.2 + (i - 1) * 0.5
		plate.Position = rootPos + Vector3.new(0, yOff, -1.4 - i * 0.15)
		plate.Orientation = Vector3.new(-30, 0, 0)
		plate.Parent = model
		makeWeld(model.PrimaryPart, plate)
	end
end

local function buildHorns(spec, model, headPart)
	for _, side in ipairs({-1, 1}) do
		local horn = Instance.new("Part")
		horn.Name = side == -1 and "HornLeft" or "HornRight"
		horn.Size = Vector3.new(0.6, 1.8, 0.6)
		horn.Color = spec.AccentColor
		horn.Material = Enum.Material.SmoothPlastic
		horn.Anchored = true
		horn.CanCollide = false
		horn.Position = headPart.Position + Vector3.new(side * 1.0, 1.0, -0.3)
		horn.Orientation = Vector3.new(0, 0, side * -25)

		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.Cylinder
		mesh.Scale = Vector3.new(1, 1, 1)
		mesh.Parent = horn

		horn.Parent = model
		makeWeld(headPart, horn)
	end
end

local function buildShell(spec, model, rootPos)
	local shell = Instance.new("Part")
	shell.Name = "Shell"
	shell.Size = Vector3.new(4.2, 2.6, 3.8)
	shell.Color = spec.AccentColor
	shell.Material = Enum.Material.SmoothPlastic
	shell.Anchored = true
	shell.CanCollide = false
	shell.Position = rootPos + Vector3.new(0, 2.4, -0.6)

	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Scale = Vector3.new(1, 0.65, 1)
	mesh.Parent = shell

	shell.Parent = model
	makeWeld(model.PrimaryPart, shell)

	-- Shell pattern lines
	for i = 1, 3 do
		local line = Instance.new("Part")
		line.Name = "ShellLine_" .. i
		line.Size = Vector3.new(3.4 - i * 0.4, 0.15, 0.15)
		line.Color = Color3.fromRGB(60, 90, 40)
		line.Material = Enum.Material.SmoothPlastic
		line.Anchored = true
		line.CanCollide = false
		line.Position = rootPos + Vector3.new(0, 2.4 + 0.4 * i - 0.6, -0.6 - 1.4)
		line.Parent = model
		makeWeld(shell, line)
	end
end

local function buildFlatCap(spec, model, headPart)
	local cap = Instance.new("Part")
	cap.Name = "FlatCap"
	cap.Size = Vector3.new(3.8, 0.5, 3.0)
	cap.Color = Color3.fromRGB(100, 80, 50)
	cap.Material = Enum.Material.SmoothPlastic
	cap.Anchored = true
	cap.CanCollide = false
	cap.Position = headPart.Position + Vector3.new(0, 1.0, 0)

	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Scale = Vector3.new(1, 0.3, 1)
	mesh.Parent = cap

	cap.Parent = model
	makeWeld(headPart, cap)

	-- Cap brim
	local brim = Instance.new("Part")
	brim.Name = "CapBrim"
	brim.Size = Vector3.new(4.0, 0.2, 1.6)
	brim.Color = Color3.fromRGB(90, 70, 40)
	brim.Material = Enum.Material.SmoothPlastic
	brim.Anchored = true
	brim.CanCollide = false
	brim.Position = headPart.Position + Vector3.new(0, 0.8, 1.4)
	brim.Parent = model
	makeWeld(headPart, brim)
end

local function buildBeak(spec, model, headPart)
	-- Long flamingo beak
	local beak = Instance.new("WedgePart")
	beak.Name = "Beak"
	beak.Size = Vector3.new(0.6, 0.5, 1.8)
	beak.Color = Color3.fromRGB(255, 180, 60)
	beak.Material = Enum.Material.SmoothPlastic
	beak.Anchored = true
	beak.CanCollide = false
	beak.Position = headPart.Position + Vector3.new(0, -0.2, 1.6)
	beak.Orientation = Vector3.new(10, 0, 0)
	beak.Parent = model
	makeWeld(headPart, beak)

	-- Beak tip (black)
	local tip = Instance.new("Part")
	tip.Name = "BeakTip"
	tip.Size = Vector3.new(0.5, 0.4, 0.5)
	tip.Color = Color3.fromRGB(30, 30, 30)
	tip.Material = Enum.Material.SmoothPlastic
	tip.Anchored = true
	tip.CanCollide = false
	tip.Position = headPart.Position + Vector3.new(0, -0.4, 2.4)
	tip.Parent = model
	makeWeld(beak, tip)
end

local function buildUnicornHorn(spec, model, headPart)
	-- Spiraling rainbow horn
	local horn = Instance.new("Part")
	horn.Name = "UnicornHorn"
	horn.Size = Vector3.new(0.5, 2.8, 0.5)
	horn.Color = Color3.fromRGB(255, 215, 0)
	horn.Material = Enum.Material.Neon
	horn.Anchored = true
	horn.CanCollide = false
	horn.Position = headPart.Position + Vector3.new(0, 2.2, 0.2)
	horn.Orientation = Vector3.new(10, 0, 0)

	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Cylinder
	mesh.Scale = Vector3.new(0.5, 1, 0.5)
	mesh.Parent = horn

	horn.Parent = model
	makeWeld(headPart, horn)

	-- Rainbow mane parts
	local maneColors = {
		Color3.fromRGB(255, 80, 80),
		Color3.fromRGB(255, 180, 50),
		Color3.fromRGB(255, 255, 80),
		Color3.fromRGB(80, 220, 100),
		Color3.fromRGB(80, 150, 255),
		Color3.fromRGB(180, 80, 255),
	}
	for i, col in ipairs(maneColors) do
		local strand = Instance.new("Part")
		strand.Name = "Mane_" .. i
		strand.Size = Vector3.new(0.4, 0.6, 1.2 + i * 0.2)
		strand.Color = col
		strand.Material = Enum.Material.SmoothPlastic
		strand.Anchored = true
		strand.CanCollide = false
		strand.Position = headPart.Position + Vector3.new(0, 1.4 - i * 0.3, -1.0 - i * 0.15)
		strand.Parent = model
		makeWeld(headPart, strand)
	end
end

local function buildSpots(spec, model, bodyPart)
	-- Black spots scattered on the orange body
	local spotPositions = {
		Vector3.new(0.8, 0.4, 1.0),
		Vector3.new(-0.6, 0.6, 0.8),
		Vector3.new(0.3, -0.3, 1.1),
		Vector3.new(-0.9, -0.1, -0.8),
		Vector3.new(0.5, 0.5, -0.9),
		Vector3.new(-0.4, -0.4, -0.6),
		Vector3.new(1.0, 0.0, 0.0),
		Vector3.new(-1.0, 0.2, 0.3),
	}
	for i, offset in ipairs(spotPositions) do
		local spot = Instance.new("Part")
		spot.Name = "Spot_" .. i
		spot.Size = Vector3.new(0.6 + math.random() * 0.4, 0.15, 0.6 + math.random() * 0.4)
		spot.Color = spec.AccentColor
		spot.Material = Enum.Material.SmoothPlastic
		spot.Anchored = true
		spot.CanCollide = false
		spot.Position = bodyPart.Position + offset
		spot.Transparency = 0

		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.Sphere
		mesh.Scale = Vector3.new(1, 0.3, 1)
		mesh.Parent = spot

		spot.Parent = model
		makeWeld(bodyPart, spot)
	end
end

local function buildPastaCurls(spec, model, bodyPart, rootPos)
	-- Curved pasta ridges around the cylindrical body
	for i = 1, 6 do
		local ridge = Instance.new("Part")
		ridge.Name = "PastaRidge_" .. i
		ridge.Size = Vector3.new(3.2, 0.3, 3.2)
		ridge.Color = Color3.fromRGB(235, 200, 80)
		ridge.Material = Enum.Material.SmoothPlastic
		ridge.Anchored = true
		ridge.CanCollide = false
		local yOff = -0.8 + (i - 1) * 0.7
		ridge.Position = rootPos + Vector3.new(0, 1.2 + yOff, 0)

		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.Sphere
		mesh.Scale = Vector3.new(1, 0.15, 1)
		mesh.Parent = ridge

		ridge.Parent = model
		makeWeld(bodyPart, ridge)
	end

	-- Crown/regal topper
	local crown = Instance.new("Part")
	crown.Name = "Crown"
	crown.Size = Vector3.new(2.2, 0.8, 2.2)
	crown.Color = Color3.fromRGB(255, 200, 50)
	crown.Material = Enum.Material.Neon
	crown.Anchored = true
	crown.CanCollide = false
	crown.Position = rootPos + Vector3.new(0, spec.HeadOffset.Y + 1.2, 0)

	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Scale = Vector3.new(1, 0.5, 1)
	mesh.Parent = crown

	crown.Parent = model
	makeWeld(model.PrimaryPart, crown)

	-- Crown points
	for j = 1, 5 do
		local point = Instance.new("WedgePart")
		point.Name = "CrownPoint_" .. j
		point.Size = Vector3.new(0.3, 0.6, 0.3)
		point.Color = Color3.fromRGB(255, 180, 20)
		point.Material = Enum.Material.Neon
		point.Anchored = true
		point.CanCollide = false
		local angle = (j / 5) * math.pi * 2
		local radius = 0.9
		point.Position = crown.Position + Vector3.new(
			math.cos(angle) * radius, 0.5, math.sin(angle) * radius
		)
		point.Parent = model
		makeWeld(crown, point)
	end
end

-- Eyes builder (used for all characters) --
local function buildEyes(spec, model, headPart)
	local eyeColor = Color3.fromRGB(255, 255, 255)
	local pupilColor = Color3.fromRGB(20, 20, 30)
	local headPos = headPart.Position
	local headSz = spec.HeadSize

	local eyeSpacing = headSz.X * 0.25
	local eyeForward = headSz.Z * 0.45
	local eyeUp = headSz.Y * 0.1
	local eyeSize = math.min(headSz.X, headSz.Y) * 0.3

	for _, side in ipairs({-1, 1}) do
		-- White of eye
		local eye = Instance.new("Part")
		eye.Name = side == -1 and "EyeLeft" or "EyeRight"
		eye.Size = Vector3.new(eyeSize, eyeSize, eyeSize * 0.3)
		eye.Color = eyeColor
		eye.Material = Enum.Material.SmoothPlastic
		eye.Anchored = true
		eye.CanCollide = false
		eye.Position = headPos + Vector3.new(side * eyeSpacing, eyeUp, eyeForward)

		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.Sphere
		mesh.Parent = eye

		eye.Parent = model
		makeWeld(headPart, eye)

		-- Pupil
		local pupil = Instance.new("Part")
		pupil.Name = side == -1 and "PupilLeft" or "PupilRight"
		pupil.Size = Vector3.new(eyeSize * 0.5, eyeSize * 0.55, eyeSize * 0.15)
		pupil.Color = pupilColor
		pupil.Material = Enum.Material.SmoothPlastic
		pupil.Anchored = true
		pupil.CanCollide = false
		pupil.Position = eye.Position + Vector3.new(0, 0, eyeSize * 0.12)

		local pMesh = Instance.new("SpecialMesh")
		pMesh.MeshType = Enum.MeshType.Sphere
		pMesh.Parent = pupil

		pupil.Parent = model
		makeWeld(eye, pupil)

		-- Eye shine
		local shine = Instance.new("Part")
		shine.Name = side == -1 and "ShineLeft" or "ShineRight"
		shine.Size = Vector3.new(eyeSize * 0.18, eyeSize * 0.18, eyeSize * 0.05)
		shine.Color = Color3.fromRGB(255, 255, 255)
		shine.Material = Enum.Material.Neon
		shine.Anchored = true
		shine.CanCollide = false
		shine.Position = eye.Position + Vector3.new(eyeSize * 0.12, eyeSize * 0.12, eyeSize * 0.15)

		local sMesh = Instance.new("SpecialMesh")
		sMesh.MeshType = Enum.MeshType.Sphere
		sMesh.Parent = shine

		shine.Parent = model
		makeWeld(eye, shine)
	end
end

-- Mouth builder --
local function buildMouth(spec, model, headPart)
	local headPos = headPart.Position
	local headSz = spec.HeadSize
	local mouthY = -headSz.Y * 0.22
	local mouthZ = headSz.Z * 0.46

	local mouth = Instance.new("Part")
	mouth.Name = "Mouth"
	mouth.Size = Vector3.new(headSz.X * 0.35, 0.15, 0.15)
	mouth.Color = Color3.fromRGB(200, 60, 80)
	mouth.Material = Enum.Material.SmoothPlastic
	mouth.Anchored = true
	mouth.CanCollide = false
	mouth.Position = headPos + Vector3.new(0, mouthY, mouthZ)

	mouth.Parent = model
	makeWeld(headPart, mouth)

	-- Smile curves
	for _, side in ipairs({-1, 1}) do
		local curve = Instance.new("Part")
		curve.Name = side == -1 and "SmileLeft" or "SmileRight"
		curve.Size = Vector3.new(0.12, 0.12, 0.12)
		curve.Color = Color3.fromRGB(200, 60, 80)
		curve.Material = Enum.Material.SmoothPlastic
		curve.Anchored = true
		curve.CanCollide = false
		curve.Position = headPos + Vector3.new(side * headSz.X * 0.18, mouthY + 0.1, mouthZ)
		curve.Parent = model
		makeWeld(mouth, curve)
	end
end

-- Build one character model --
local function buildCharacterModel(spec)
	local model = Instance.new("Model")
	model.Name = spec.Name

	local rootPos = spec.Position

	-- HumanoidRootPart (invisible, anchored, PrimaryPart)
	local hrp = Instance.new("Part")
	hrp.Name = "HumanoidRootPart"
	hrp.Size = Vector3.new(2, 2, 1)
	hrp.Transparency = 1
	hrp.Anchored = true
	hrp.CanCollide = false
	hrp.Position = rootPos
	hrp.Parent = model
	model.PrimaryPart = hrp

	-- Body
	local body = makePart("Body", spec.BodySize, spec.BodyColor, model,
		rootPos + Vector3.new(0, spec.BodySize.Y / 2 + 0.2, 0), nil, true)
	makeWeld(hrp, body)

	-- Head
	local head = makePart("Head", spec.HeadSize, spec.HeadColor, model,
		rootPos + spec.HeadOffset, spec.HeadShape, true)
	makeWeld(hrp, head)

	-- Left Arm
	local armL = makePart("LeftArm", spec.ArmSize, spec.BodyColor, model,
		rootPos + spec.ArmOffsetL, "Cylinder", true)
	makeWeld(hrp, armL)

	-- Right Arm
	local armR = makePart("RightArm", spec.ArmSize, spec.BodyColor, model,
		rootPos + spec.ArmOffsetR, "Cylinder", true)
	makeWeld(hrp, armR)

	-- Left Leg
	local legL = makePart("LeftLeg", spec.LegSize, spec.LegColor, model,
		rootPos + spec.LegOffsetL, nil, true)
	makeWeld(hrp, legL)

	-- Right Leg
	local legR = makePart("RightLeg", spec.LegSize, spec.LegColor, model,
		rootPos + spec.LegOffsetR, nil, true)
	makeWeld(hrp, legR)

	-- Eyes and mouth
	buildEyes(spec, model, head)
	buildMouth(spec, model, head)

	-- Unique feature
	if spec.UniqueFeature == "ScalePlates" then
		buildScalePlates(spec, model, rootPos)
	elseif spec.UniqueFeature == "Horns" then
		buildHorns(spec, model, head)
	elseif spec.UniqueFeature == "Shell" then
		buildShell(spec, model, rootPos)
	elseif spec.UniqueFeature == "FlatCap" then
		buildFlatCap(spec, model, head)
	elseif spec.UniqueFeature == "Beak" then
		buildBeak(spec, model, head)
	elseif spec.UniqueFeature == "Horn" then
		buildUnicornHorn(spec, model, head)
	elseif spec.UniqueFeature == "Spots" then
		buildSpots(spec, model, body)
	elseif spec.UniqueFeature == "PastaCurls" then
		buildPastaCurls(spec, model, body, rootPos)
	end

	-- Billboard name tag
	addBillboard(model, spec.Name, head)

	-- ProximityPrompt on body
	addProximityPrompt(body)

	-- CharacterName StringValue
	addStringValue(model, spec.Name)

	return model
end

-- Service interface --

local npcFolder = nil
local builtModels = {}

function ModelService:Init()
	-- Create NPCs folder in workspace
	npcFolder = Workspace:FindFirstChild("NPCs")
	if not npcFolder then
		npcFolder = Instance.new("Folder")
		npcFolder.Name = "NPCs"
		npcFolder.Parent = Workspace
	end

	-- Build all character models
	for _, spec in ipairs(CHARACTER_SPECS) do
		local model = buildCharacterModel(spec)
		model.Parent = npcFolder
		builtModels[spec.Name] = model
		print("[ModelService] Built: " .. spec.Name)
	end

	print("[ModelService] All " .. #CHARACTER_SPECS .. " characters built")
end

function ModelService:Start()
	-- Enable all ProximityPrompts
	for _, model in pairs(builtModels) do
		local body = model:FindFirstChild("Body")
		if body then
			local prompt = body:FindFirstChild("KissPrompt")
			if prompt then
				prompt.Enabled = true
			end
		end
	end
	print("[ModelService] All ProximityPrompts activated")
end

function ModelService:GetModel(characterName)
	return builtModels[characterName]
end

function ModelService:GetAllModels()
	return builtModels
end

function ModelService:GetCharacterNames()
	local names = {}
	for _, spec in ipairs(CHARACTER_SPECS) do
		table.insert(names, spec.Name)
	end
	return names
end

return ModelService
