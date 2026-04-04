local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes"))

local RemoteService = {}
RemoteService.__index = RemoteService

function RemoteService:Init()
	Remotes:Init()
	if _G.Config and _G.Config.DEBUG_MODE then
		print("[RemoteService] Initialized - all remotes created")
	end
end

function RemoteService:Start()
	-- Remotes are connected by other services
end

function RemoteService:FireClient(remoteName, player, ...)
	local remote = Remotes:Get(remoteName)
	if remote then
		remote:FireClient(player, ...)
	end
end

function RemoteService:FireAllClients(remoteName, ...)
	local remote = Remotes:Get(remoteName)
	if remote then
		remote:FireAllClients(...)
	end
end

function RemoteService:FireNearbyClients(remoteName, position, radius, ...)
	local Players = game:GetService("Players")
	local remote = Remotes:Get(remoteName)
	if not remote then
		return
	end

	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		if character then
			local hrp = character:FindFirstChild("HumanoidRootPart")
			if hrp and (hrp.Position - position).Magnitude <= radius then
				remote:FireClient(player, ...)
			end
		end
	end
end

function RemoteService:OnServerEvent(remoteName, callback)
	local remote = Remotes:Get(remoteName)
	if remote then
		remote.OnServerEvent:Connect(callback)
	end
end

return RemoteService
