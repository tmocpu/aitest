-- Centralized remote definitions
-- This module creates or finds all remotes used by the game

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = {}

local REMOTE_EVENTS = {
	-- Client -> Server
	"RequestKiss",
	-- Server -> Client
	"KissReaction",
	"ComboUpdate",
	"SuperKissEvent",
	"LeaderboardUpdate",
	"MilestoneAnnouncement",
	"CoinsUpdate",
}

function Remotes:Init()
	local remotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
	if not remotesFolder then
		remotesFolder = Instance.new("Folder")
		remotesFolder.Name = "Remotes"
		remotesFolder.Parent = ReplicatedStorage
	end

	for _, name in ipairs(REMOTE_EVENTS) do
		local remote = remotesFolder:FindFirstChild(name)
		if not remote then
			remote = Instance.new("RemoteEvent")
			remote.Name = name
			remote.Parent = remotesFolder
		end
		self[name] = remote
	end
end

function Remotes:Get(name)
	return self[name]
end

return Remotes
