-- SoundController: Manages all game sound effects
-- Uses Roblox built-in sound IDs (public library sounds)

local SoundService = game:GetService("SoundService")
local Players = game:GetService("Players")

local SoundController = {}
SoundController.__index = SoundController

local sounds = {}
local soundGroup = nil

-- Public Roblox audio library IDs (cartoony/comedy sounds)
local SOUND_IDS = {
	Kiss       = "rbxassetid://3744370687",  -- smooch pop
	KissAlt    = "rbxassetid://3744370452",  -- alternate kiss
	ComboTick  = "rbxassetid://6895079853",  -- upbeat tick
	ComboBreak = "rbxassetid://6895079761",  -- descending tone
	SuperKiss  = "rbxassetid://5982028856",  -- fanfare/celebration
	Milestone  = "rbxassetid://5982028856",  -- trumpet/achievement
	Reject     = "rbxassetid://6895079761",  -- error buzz
	UIClick    = "rbxassetid://6895079853",  -- click
	CoinPickup = "rbxassetid://6895079853",  -- coin ding
}

function SoundController:Init()
	-- Create a SoundGroup for volume control
	soundGroup = Instance.new("SoundGroup")
	soundGroup.Name = "BrainrotSounds"
	soundGroup.Volume = 0.8
	soundGroup.Parent = SoundService

	-- Pre-create all sounds
	for name, id in pairs(SOUND_IDS) do
		local sound = Instance.new("Sound")
		sound.Name = name
		sound.SoundId = id
		sound.SoundGroup = soundGroup
		sound.Volume = 0.6
		sound.Parent = soundGroup
		sounds[name] = sound
	end

	-- Customize individual volumes
	if sounds.Kiss then sounds.Kiss.Volume = 0.7 end
	if sounds.SuperKiss then sounds.SuperKiss.Volume = 0.9 end
	if sounds.Reject then sounds.Reject.Volume = 0.3 end
	if sounds.ComboTick then sounds.ComboTick.Volume = 0.5 end
	if sounds.CoinPickup then sounds.CoinPickup.Volume = 0.4 end
end

local function playSound(name, pitchVariation)
	local sound = sounds[name]
	if not sound then return end

	-- Clone for overlapping plays
	local clone = sound:Clone()
	if pitchVariation then
		clone.PlaybackSpeed = 0.9 + math.random() * 0.2
	end
	clone.Parent = soundGroup
	clone:Play()
	clone.Ended:Connect(function()
		clone:Destroy()
	end)
end

function SoundController:PlayKiss()
	-- Alternate between kiss sounds randomly
	if math.random() > 0.5 then
		playSound("Kiss", true)
	else
		playSound("KissAlt", true)
	end
end

function SoundController:PlayComboTick(comboCount)
	local sound = sounds.ComboTick
	if sound then
		local clone = sound:Clone()
		-- Higher pitch for higher combos
		clone.PlaybackSpeed = 0.8 + math.min(comboCount * 0.05, 0.6)
		clone.Parent = soundGroup
		clone:Play()
		clone.Ended:Connect(function() clone:Destroy() end)
	end
end

function SoundController:PlayComboBreak()
	playSound("ComboBreak", false)
end

function SoundController:PlaySuperKiss()
	playSound("SuperKiss", false)
end

function SoundController:PlayMilestone()
	playSound("Milestone", false)
end

function SoundController:PlayReject()
	playSound("Reject", false)
end

function SoundController:PlayUIClick()
	playSound("UIClick", true)
end

function SoundController:PlayCoinPickup()
	playSound("CoinPickup", true)
end

function SoundController:SetVolume(volume)
	if soundGroup then
		soundGroup.Volume = math.clamp(volume, 0, 1)
	end
end

return SoundController
