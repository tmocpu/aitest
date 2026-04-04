-- Reusable TweenInfo presets for smooth cartoony animations

local TweenService = game:GetService("TweenService")

local TweenPresets = {}

-- Standard easing curves
TweenPresets.Info = {
	-- Snappy UI pop-in (buttons, panels appearing)
	PopIn = TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
	-- Smooth UI pop-out (dismissing)
	PopOut = TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.In),
	-- Gentle fade
	Fade = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
	-- Quick fade
	FadeFast = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
	-- Slow fade (milestone banners)
	FadeSlow = TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
	-- Bounce effect (combo counter, coin counter)
	Bounce = TweenInfo.new(0.4, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out),
	-- Elastic (super kiss, big events)
	Elastic = TweenInfo.new(0.6, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out),
	-- Smooth slide (leaderboard, panels)
	Slide = TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
	-- Quick slide
	SlideFast = TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
	-- Continuous float (idle NPC bob)
	Float = TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
	-- Heart float up
	FloatUp = TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
	-- Spin (reactions)
	Spin = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
	-- Pulse (glow effects)
	Pulse = TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
	-- Scale bump (kiss feedback)
	Bump = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
	-- Scale bump return
	BumpReturn = TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
	-- Number counter roll
	Counter = TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
	-- Shake (reject/error)
	Shake = TweenInfo.new(0.08, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, 3, true),
	-- NPC idle sway
	IdleSway = TweenInfo.new(2.0, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
	-- NPC reaction jump
	ReactionJump = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
	-- NPC reaction settle
	ReactionSettle = TweenInfo.new(0.4, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out),
}

-- Play a tween and return it (so caller can :Wait() or :Cancel())
function TweenPresets.Play(instance, presetName, properties)
	local info = TweenPresets.Info[presetName]
	if not info then
		info = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	end
	local tween = TweenService:Create(instance, info, properties)
	tween:Play()
	return tween
end

-- Play a custom tween
function TweenPresets.PlayCustom(instance, tweenInfo, properties)
	local tween = TweenService:Create(instance, tweenInfo, properties)
	tween:Play()
	return tween
end

-- Sequential: scale bump then return (for button presses, kiss feedback)
function TweenPresets.BumpScale(instance, bumpScale, originalScale)
	originalScale = originalScale or Vector3.new(1, 1, 1)
	bumpScale = bumpScale or Vector3.new(1.2, 1.2, 1.2)

	local t1 = TweenPresets.Play(instance, "Bump", { Size = bumpScale })
	t1.Completed:Connect(function()
		TweenPresets.Play(instance, "BumpReturn", { Size = originalScale })
	end)
end

-- Scale bump for UDim2 (UI elements)
function TweenPresets.BumpUI(instance, bumpSize, originalSize)
	local t1 = TweenPresets.Play(instance, "Bump", { Size = bumpSize })
	t1.Completed:Connect(function()
		TweenPresets.Play(instance, "BumpReturn", { Size = originalSize })
	end)
end

-- Shake an element (for errors/rejects)
function TweenPresets.ShakeUI(instance)
	local originalPos = instance.Position
	local shakeOffset = UDim2.new(0, 6, 0, 0)
	local shakePos = UDim2.new(
		originalPos.X.Scale, originalPos.X.Offset + 6,
		originalPos.Y.Scale, originalPos.Y.Offset
	)
	local tween = TweenPresets.Play(instance, "Shake", { Position = shakePos })
	tween.Completed:Connect(function()
		instance.Position = originalPos
	end)
end

return TweenPresets
