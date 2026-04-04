-- AnimationController: Pure TweenService part-manipulation animations for NPC reactions
-- No Animator keyframes — all reactions driven by tweening CFrame/Size/Color

local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local TweenPresets = require(Shared:WaitForChild("Modules"):WaitForChild("TweenPresets"))

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

local AnimationController = {}
AnimationController.__index = AnimationController

-- Track active tweens per part so we can cancel before starting new ones
local activeTweens = {} -- [part] = {tween1, tween2, ...}

-- Track original state per part for restoration
local originalStates = {} -- [part] = { CFrame, Size, Color }

---------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------

local function findModelByName(characterName)
	local npcsFolder = Workspace:FindFirstChild("NPCs")
	if not npcsFolder then
		warn("[AnimationController] NPCs folder not found")
		return nil
	end

	-- Search by CharacterName StringValue first, then by model name
	for _, model in ipairs(npcsFolder:GetChildren()) do
		if model:IsA("Model") then
			local nameVal = model:FindFirstChild("CharacterName")
			if nameVal and nameVal:IsA("StringValue") and nameVal.Value == characterName then
				return model
			end
		end
	end

	-- Fallback to direct name match
	local model = npcsFolder:FindFirstChild(characterName)
	if model and model:IsA("Model") then
		return model
	end

	warn("[AnimationController] Model not found: " .. tostring(characterName))
	return nil
end

local function cancelTweens(part)
	local tweens = activeTweens[part]
	if tweens then
		for _, tween in ipairs(tweens) do
			tween:Cancel()
		end
	end
	activeTweens[part] = {}
end

local function registerTween(part, tween)
	if not activeTweens[part] then
		activeTweens[part] = {}
	end
	table.insert(activeTweens[part], tween)
end

local function saveOriginal(part)
	if not originalStates[part] then
		originalStates[part] = {
			CFrame = part.CFrame,
			Size = part.Size,
			Color = part.Color,
		}
	end
end

local function restoreOriginal(part, duration)
	local state = originalStates[part]
	if not state then return end

	duration = duration or 0.3
	local info = TweenInfo.new(duration, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	local tween = TweenService:Create(part, info, {
		CFrame = state.CFrame,
		Size = state.Size,
		Color = state.Color,
	})
	registerTween(part, tween)
	tween:Play()
	tween.Completed:Connect(function()
		originalStates[part] = nil
	end)
end

local function getVisibleParts(model)
	local parts = {}
	for _, child in ipairs(model:GetDescendants()) do
		if child:IsA("BasePart") and child.Transparency < 1 then
			table.insert(parts, child)
		end
	end
	return parts
end

---------------------------------------------------------------------------
-- Reaction Animations
---------------------------------------------------------------------------

local function playNormalReaction(model)
	local head = model:FindFirstChild("Head")
	if not head then return end

	cancelTweens(head)
	saveOriginal(head)

	-- Bounce head up 0.5 studs and back, Elastic easing, 0.4s
	local upCFrame = head.CFrame + Vector3.new(0, 0.5, 0)
	local upInfo = TweenInfo.new(0.2, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out)
	local upTween = TweenService:Create(head, upInfo, { CFrame = upCFrame })
	registerTween(head, upTween)
	upTween:Play()

	upTween.Completed:Connect(function()
		restoreOriginal(head, 0.2)
	end)
end

local function playComboReaction(model)
	local body = model:FindFirstChild("Body")
	local head = model:FindFirstChild("Head")

	-- Spin body 360 degrees over 0.6s
	if body then
		cancelTweens(body)
		saveOriginal(body)

		local startCF = body.CFrame
		-- We tween via CFrame rotation — apply a full 360 Y spin
		-- TweenService can't tween CFrame rotation directly past 180,
		-- so we split into two 180-degree rotations
		local halfCF = startCF * CFrame.Angles(0, math.rad(180), 0)
		local fullCF = startCF * CFrame.Angles(0, math.rad(360), 0)

		local spinInfo1 = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		local spin1 = TweenService:Create(body, spinInfo1, { CFrame = halfCF })
		registerTween(body, spin1)
		spin1:Play()

		spin1.Completed:Connect(function()
			local spinInfo2 = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			local spin2 = TweenService:Create(body, spinInfo2, { CFrame = fullCF })
			registerTween(body, spin2)
			spin2:Play()

			spin2.Completed:Connect(function()
				restoreOriginal(body, 0.2)
			end)
		end)
	end

	-- Bounce head 3 times over 0.6s
	if head then
		cancelTweens(head)
		saveOriginal(head)

		local baseCF = head.CFrame
		local bounceCount = 0

		local function doBounce()
			bounceCount = bounceCount + 1
			if bounceCount > 3 then
				restoreOriginal(head, 0.15)
				return
			end

			local upCF = baseCF + Vector3.new(0, 0.4, 0)
			local upInfo = TweenInfo.new(0.1, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
			local upTween = TweenService:Create(head, upInfo, { CFrame = upCF })
			registerTween(head, upTween)
			upTween:Play()

			upTween.Completed:Connect(function()
				local downInfo = TweenInfo.new(0.1, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out)
				local downTween = TweenService:Create(head, downInfo, { CFrame = baseCF })
				registerTween(head, downTween)
				downTween:Play()
				downTween.Completed:Connect(doBounce)
			end)
		end

		doBounce()
	end
end

local function playSuperReaction(model)
	local parts = getVisibleParts(model)
	local head = model:FindFirstChild("Head")
	local rootPart = model.PrimaryPart or model:FindFirstChild("HumanoidRootPart")

	-- Save all original states
	for _, part in ipairs(parts) do
		cancelTweens(part)
		saveOriginal(part)
	end

	-- Phase 1 (0–0.4s): Scale entire model up 1.5x
	for _, part in ipairs(parts) do
		local scaleInfo = TweenInfo.new(0.4, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out)
		local scaledSize = part.Size * 1.5
		-- Offset position outward from root to maintain relative layout
		local scaledCFrame = part.CFrame
		if rootPart then
			local offset = part.CFrame.Position - rootPart.CFrame.Position
			scaledCFrame = CFrame.new(rootPart.CFrame.Position + offset * 1.5) *
				(part.CFrame - part.CFrame.Position)
		end
		local scaleTween = TweenService:Create(part, scaleInfo, {
			Size = scaledSize,
			CFrame = scaledCFrame,
		})
		registerTween(part, scaleTween)
		scaleTween:Play()
	end

	-- Phase 2 (0.2–0.8s): Rainbow color shift on head
	if head then
		local rainbowColors = {
			Color3.fromRGB(255, 80, 80),
			Color3.fromRGB(255, 200, 50),
			Color3.fromRGB(80, 255, 80),
			Color3.fromRGB(80, 180, 255),
			Color3.fromRGB(200, 80, 255),
			Color3.fromRGB(255, 80, 200),
		}

		task.delay(0.2, function()
			for i, color in ipairs(rainbowColors) do
				local colorInfo = TweenInfo.new(0.1, Enum.EasingStyle.Linear)
				local colorTween = TweenService:Create(head, colorInfo, { Color = color })
				registerTween(head, colorTween)
				colorTween:Play()
				colorTween.Completed:Wait()
			end
		end)
	end

	-- Phase 3 (0.4–0.9s): Violent shake
	task.delay(0.4, function()
		local shakeStart = tick()
		local shakeDuration = 0.5

		while tick() - shakeStart < shakeDuration do
			for _, part in ipairs(parts) do
				local state = originalStates[part]
				if state then
					local shakeX = (math.random() - 0.5) * 1.0
					local shakeY = (math.random() - 0.5) * 0.6
					local shakeZ = (math.random() - 0.5) * 1.0
					-- Scale is still 1.5x, so apply shake to scaled position
					local scaledOffset = Vector3.new(0, 0, 0)
					if rootPart then
						local baseOffset = state.CFrame.Position - (originalStates[rootPart] and originalStates[rootPart].CFrame.Position or rootPart.CFrame.Position)
						scaledOffset = baseOffset * 1.5
					end
					local basePos = (originalStates[rootPart] and originalStates[rootPart].CFrame.Position or rootPart and rootPart.CFrame.Position or state.CFrame.Position)
					part.CFrame = CFrame.new(
						basePos + scaledOffset + Vector3.new(shakeX, shakeY, shakeZ)
					) * (state.CFrame - state.CFrame.Position)
				end
			end
			task.wait()
		end
	end)

	-- Phase 4 (0.9–1.2s): Restore everything smoothly
	task.delay(0.9, function()
		for _, part in ipairs(parts) do
			restoreOriginal(part, 0.3)
		end
	end)
end

---------------------------------------------------------------------------
-- Camera Effects
---------------------------------------------------------------------------

local function shakeCamera(intensity, duration)
	task.spawn(function()
		local startTime = tick()
		local origCF = camera.CFrame

		while tick() - startTime < duration do
			local elapsed = tick() - startTime
			-- Decay intensity over time
			local decay = 1 - (elapsed / duration)
			local shakeX = (math.random() - 0.5) * intensity * decay
			local shakeY = (math.random() - 0.5) * intensity * decay
			camera.CFrame = camera.CFrame * CFrame.new(shakeX, shakeY, 0)
			task.wait()
		end
		-- Camera auto-corrects via Roblox camera system, no explicit restore needed
	end)
end

---------------------------------------------------------------------------
-- Screen Flash
---------------------------------------------------------------------------

local flashFrame = nil

local function getFlashFrame()
	if flashFrame and flashFrame.Parent then
		return flashFrame
	end

	local playerGui = player:FindFirstChild("PlayerGui")
	if not playerGui then return nil end

	-- Find or create ScreenGui for flash
	local flashGui = playerGui:FindFirstChild("AnimFlashGui")
	if not flashGui then
		flashGui = Instance.new("ScreenGui")
		flashGui.Name = "AnimFlashGui"
		flashGui.ResetOnSpawn = false
		flashGui.IgnoreGuiInset = true
		flashGui.DisplayOrder = 100
		flashGui.Parent = playerGui
	end

	flashFrame = Instance.new("Frame")
	flashFrame.Name = "FlashFrame"
	flashFrame.Size = UDim2.new(1, 0, 1, 0)
	flashFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	flashFrame.BackgroundTransparency = 1
	flashFrame.ZIndex = 100
	flashFrame.BorderSizePixel = 0
	flashFrame.Parent = flashGui

	return flashFrame
end

local function flashScreen(color, peakTransparency, duration)
	local frame = getFlashFrame()
	if not frame then return end

	frame.BackgroundColor3 = color or Color3.fromRGB(255, 255, 255)
	frame.BackgroundTransparency = 1

	-- Flash in
	local inInfo = TweenInfo.new(duration * 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local inTween = TweenService:Create(frame, inInfo, {
		BackgroundTransparency = peakTransparency or 0.3,
	})
	inTween:Play()

	-- Flash out
	inTween.Completed:Connect(function()
		local outInfo = TweenInfo.new(duration * 0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		local outTween = TweenService:Create(frame, outInfo, {
			BackgroundTransparency = 1,
		})
		outTween:Play()
	end)
end

---------------------------------------------------------------------------
-- Milestone Animation
---------------------------------------------------------------------------

local function playMilestoneAnimation(model)
	local parts = getVisibleParts(model)
	local rootPart = model.PrimaryPart or model:FindFirstChild("HumanoidRootPart")

	if not rootPart then
		warn("[AnimationController] No root part for milestone anim: " .. model.Name)
		return
	end

	-- Save all originals
	for _, part in ipairs(parts) do
		cancelTweens(part)
		saveOriginal(part)
	end

	-- Full 720 spin (split into four 180-degree segments to avoid shortest-path)
	local rootOrigin = originalStates[rootPart] and originalStates[rootPart].CFrame or rootPart.CFrame

	local segmentCount = 4
	local segmentAngle = math.rad(180)
	local segmentDuration = 0.3

	task.spawn(function()
		for seg = 1, segmentCount do
			local targetAngle = segmentAngle * seg
			local segInfo = TweenInfo.new(segmentDuration, Enum.EasingStyle.Quad,
				seg <= 2 and Enum.EasingDirection.In or Enum.EasingDirection.Out)

			for _, part in ipairs(parts) do
				local state = originalStates[part]
				if state then
					-- Calculate rotated position relative to root
					local relPos = state.CFrame.Position - rootOrigin.Position
					local rotCF = CFrame.Angles(0, targetAngle, 0)
					local rotatedPos = rootOrigin.Position + rotCF:VectorToWorldSpace(relPos)
					local rotatedCFrame = CFrame.new(rotatedPos) *
						(state.CFrame - state.CFrame.Position) *
						CFrame.Angles(0, targetAngle, 0)

					local tween = TweenService:Create(part, segInfo, { CFrame = rotatedCFrame })
					registerTween(part, tween)
					tween:Play()
				end
			end

			task.wait(segmentDuration)
		end

		-- Pulse all parts to gold and back
		local goldColor = Color3.fromRGB(255, 215, 0)

		-- Flash to gold
		for _, part in ipairs(parts) do
			local goldInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			local goldTween = TweenService:Create(part, goldInfo, { Color = goldColor })
			registerTween(part, goldTween)
			goldTween:Play()
		end

		task.wait(0.3)

		-- Restore all
		for _, part in ipairs(parts) do
			restoreOriginal(part, 0.4)
		end
	end)
end

---------------------------------------------------------------------------
-- Public API
---------------------------------------------------------------------------

function AnimationController:Init()
	-- Pre-create flash frame
	getFlashFrame()
end

function AnimationController:OnKissReaction(characterName, reactionType, globalCount)
	local model = findModelByName(characterName)
	if not model then return end

	-- Determine reaction tier from the text
	-- The server sends the reaction string, but we also need the tier.
	-- We detect tier by checking if the reaction contains uppercase (combo/super indicators)
	-- or we can just pick based on a simple heuristic. The KissService sends the tier
	-- as the reactionType string. We detect tier from the reaction data patterns.
	-- For simplicity: if all-caps words exist => combo or super, otherwise normal.
	-- Better approach: the caller in Init.client.lua can pass tier info,
	-- but since we only get the reaction string, we use pattern matching.

	local tier = "normal"
	-- Check if it matches known super patterns (very dramatic text)
	if string.find(reactionType, "transcend") or string.find(reactionType, "launches") or
		string.find(reactionType, "sonic boom") or string.find(reactionType, "freezes time") or
		string.find(reactionType, "legendary") or string.find(reactionType, "forbidden") or
		string.find(reactionType, "unfurls") or string.find(reactionType, "charges through") or
		string.find(reactionType, "galaxy") or string.find(reactionType, "inner peace") or
		string.find(reactionType, "spiral of pink") or string.find(reactionType, "beam of pure") or
		string.find(reactionType, "fire-breathing") or string.find(reactionType, "golden pasta") then
		tier = "super"
	elseif string.find(reactionType, "INTENSIFIES") or string.find(reactionType, "ACTIVATED") or
		string.find(reactionType, "OVERLOAD") or string.find(reactionType, "OVERDRIVE") or
		string.find(reactionType, "EXPLOSION") or string.find(reactionType, "THOUSAND") or
		string.find(reactionType, "FRENZY") or string.find(reactionType, "STAMPEDE") or
		string.find(reactionType, "TORNADO") or string.find(reactionType, "CHILL OVERLOAD") or
		string.find(reactionType, "DANCE EXPLOSION") or string.find(reactionType, "SUPERNOVA") or
		string.find(reactionType, "SPOT STORM") or string.find(reactionType, "AL DENTE") then
		tier = "combo"
	end

	if tier == "super" then
		playSuperReaction(model)
	elseif tier == "combo" then
		playComboReaction(model)
	else
		playNormalReaction(model)
	end
end

function AnimationController:OnComboUpdate(comboCount, multiplier)
	if comboCount >= 5 then
		-- Camera shake scales with combo: base 0.15 at combo 5, up to 0.5 at combo 20+
		local intensity = math.clamp(0.05 + comboCount * 0.03, 0.15, 0.5)
		local duration = math.clamp(0.1 + comboCount * 0.02, 0.15, 0.4)
		shakeCamera(intensity, duration)
	end
end

function AnimationController:OnSuperKissEvent(characterName, coinsAwarded)
	-- White flash, 0.1s peak
	flashScreen(Color3.fromRGB(255, 255, 255), 0.15, 0.1)

	-- Hard camera shake for 0.5s
	shakeCamera(0.8, 0.5)
end

function AnimationController:OnMilestoneAnnouncement(characterName, milestone)
	local model = findModelByName(characterName)
	if not model then return end

	playMilestoneAnimation(model)
end

return AnimationController
