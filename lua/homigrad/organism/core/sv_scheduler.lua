hg = hg or {}

local CurTime = CurTime
local SysTime = SysTime
local hook_Run = hook.Run

local tickrate = 1 / 10
local delay = 0
local time, mulTime, start

hook.Add("Think", "homigrad-organism", function()
	time = CurTime()

	local tickrate2 = tickrate / math.max(game.GetTimeScale(), 0.01)

	if delay + tickrate2 > time then return end

	delay = time

	if !start then
		start = SysTime()
		return
	end

	mulTime = (SysTime() - start) * game.GetTimeScale()

	start = SysTime()

	for owner, org in pairs(hg.organism.list) do
		hook_Run("Org Think", owner, org, mulTime)
	end
end)

local lastcall = SysTime()

hook.Add("Org Think Call", "homigrad-organism", function(owner, org)
	if (SysTime() - lastcall) < tickrate then return end

	lastcall = SysTime()

	hook_Run("Org Think", owner, org, 0.00001)
end)
