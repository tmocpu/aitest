local Config = require(script.Parent.Config)

local RateLimiter = {}
RateLimiter.__index = RateLimiter

function RateLimiter.new()
	local self = setmetatable({}, RateLimiter)
	self._requests = {} -- [player] = {timestamps}
	return self
end

function RateLimiter:RecordRequest(player)
	local now = tick()
	if not self._requests[player] then
		self._requests[player] = {}
	end

	table.insert(self._requests[player], now)
end

function RateLimiter:IsRateLimited(player)
	local now = tick()
	local timestamps = self._requests[player]
	if not timestamps then
		return false
	end

	-- Prune old timestamps outside the window
	local cutoff = now - Config.RATE_LIMIT_WINDOW
	local pruned = {}
	for _, t in ipairs(timestamps) do
		if t > cutoff then
			table.insert(pruned, t)
		end
	end
	self._requests[player] = pruned

	return #pruned >= Config.RATE_LIMIT_MAX
end

function RateLimiter:CleanupPlayer(player)
	self._requests[player] = nil
end

return RateLimiter
