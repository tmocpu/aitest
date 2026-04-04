-- KissController: Handles proximity detection and kiss input via ProximityPrompts
-- Connects ProximityPrompt triggers to the server RequestKiss remote

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProximityPromptService = game:GetService("ProximityPromptService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Modules"):WaitForChild("Config"))
local UITheme = require(Shared:WaitForChild("Modules"):WaitForChild("UITheme"))

local player = Players.LocalPlayer

local KissController = {}
KissController.__index = KissController

local RequestKiss = nil
local VFXController = nil
local SoundController = nil
local lastKissTime = 0
local nearestCharacter = nil

function KissController:Init(remotes, vfx, sound)
	RequestKiss = remotes.RequestKiss
	VFXController = vfx
	SoundController = sound

	self:SetupProximityPrompts()
	self:SetupCustomPromptUI()
end

function KissController:SetupProximityPrompts()
	-- Listen for any ProximityPrompt triggered in the workspace
	ProximityPromptService.PromptTriggered:Connect(function(prompt, triggeringPlayer)
		if triggeringPlayer ~= player then return end
		if prompt.Name ~= "KissPrompt" then return end

		-- Find character name from the model
		local model = prompt.Parent and prompt.Parent.Parent
		if not model then return end

		local nameValue = model:FindFirstChild("CharacterName")
		local characterName = nameValue and nameValue.Value or model.Name

		self:DoKiss(characterName, model)
	end)

	-- Track nearest character for UI display
	task.spawn(function()
		while true do
			self:UpdateNearest()
			task.wait(0.2)
		end
	end)
end

function KissController:SetupCustomPromptUI()
	-- Override default ProximityPrompt style with a cartoony one
	ProximityPromptService.PromptShown:Connect(function(prompt, inputType)
		if prompt.Name ~= "KissPrompt" then return end
		if prompt.Style == Enum.ProximityPromptStyle.Custom then return end
		-- We keep default style but modify colors via the prompt properties
		prompt.Style = Enum.ProximityPromptStyle.Default
	end)
end

function KissController:DoKiss(characterName, model)
	local now = tick()
	if (now - lastKissTime) < Config.KISS_COOLDOWN then
		-- On cooldown - shake feedback
		if SoundController then
			SoundController:PlayReject()
		end
		return
	end

	lastKissTime = now

	-- Fire to server
	if RequestKiss then
		RequestKiss:FireServer(characterName)
	end

	-- Local VFX feedback immediately (don't wait for server)
	if VFXController then
		local bodyPart = model:FindFirstChild("Body") or model:FindFirstChild("HumanoidRootPart")
		if bodyPart then
			VFXController:SpawnKissHearts(bodyPart.Position)
			VFXController:BumpNPC(model)
		end
	end

	if SoundController then
		SoundController:PlayKiss()
	end
end

function KissController:UpdateNearest()
	local character = player.Character
	if not character then
		nearestCharacter = nil
		return
	end

	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then
		nearestCharacter = nil
		return
	end

	local npcsFolder = Workspace:FindFirstChild("NPCs")
	if not npcsFolder then
		nearestCharacter = nil
		return
	end

	local closest = nil
	local closestDist = Config.PROXIMITY_RANGE + 5 -- slightly more than prompt range

	for _, npc in ipairs(npcsFolder:GetChildren()) do
		if npc:IsA("Model") then
			local npcRoot = npc.PrimaryPart or npc:FindFirstChild("HumanoidRootPart")
			if npcRoot then
				local dist = (hrp.Position - npcRoot.Position).Magnitude
				if dist < closestDist then
					closestDist = dist
					closest = npc
				end
			end
		end
	end

	nearestCharacter = closest
end

function KissController:GetNearestCharacter()
	return nearestCharacter
end

return KissController
