TS_DeathAnim = TS_DeathAnim or {}

local IsValid, CurTime, FrameTime = IsValid, CurTime, FrameTime
local math_random = math.random
local VectorRand = VectorRand
local util_TraceLine = util.TraceLine
local LocalToWorld = LocalToWorld

local HEADBONE = "ValveBiped.Bip01_Head1"
local NEARSQR = 200 * 200

local active = {}
local goreCount = 0

local function clear(ent)
	if !active[ent] then return end
	active[ent] = nil
	goreCount = math.max(goreCount - 1, 0)
end

local function boneWorld(ent)
	local bone = ent:LookupBone(HEADBONE)
	if !bone then return end
	local mat = ent:GetBoneMatrix(bone)
	if !mat then return end
	return mat:GetTranslation()
end

local function evictFar(eye)
	local worst, worstD = nil, 0

	for e in pairs(active) do
		local w = IsValid(e) and boneWorld(e) or nil

		if !w then
			worst = worst or e
		else
			local d = w:DistToSqr(eye)
			if !worst or d > worstD then worst, worstD = e, d end
		end
	end

	if worst then clear(worst) end
end

net.Receive("ts_deathanim_headclub", function()
	local cfg = TS_DeathAnim.HeadClub
	if !cfg then return end

	local ent = net.ReadEntity()
	local dur = net.ReadFloat()
	local lpos = net.ReadVector()

	if !IsValid(ent) then return end
	if !lpos then return end
	if !ent:LookupBone(HEADBONE) then return end
	if goreCount >= cfg.MaxGore then
		local lp = lply
		evictFar(IsValid(lp) and lp:EyePos() or vector_origin)
		if goreCount >= cfg.MaxGore then return end
	end

	local g = active[ent]
	if !g then
		goreCount = goreCount + 1
		g = {}
		active[ent] = g
	end

	g.lpos = Vector(math.Clamp(lpos.x, -20, 20), math.Clamp(lpos.y, -20, 20), math.Clamp(lpos.z, -20, 20))
	g.life = math.Clamp(dur, 0, 30)
	g.t = 0
	g.next = 0
	g.n = 0
	g.mul = 0.12
	g.mul2 = 0.9
	g.fwd = 115
end)

hook.Add("Think", "TS_DeathAnim_HeadGore", function()
	local cfg = TS_DeathAnim.HeadClub
	if !cfg then return end
	if goreCount < 1 then return end

	local applyFountain = hg.applyFountain
	if !applyFountain then return end

	local lp = lply
	if !IsValid(lp) then lp = LocalPlayer() end
	if !IsValid(lp) then return end

	local time = CurTime()
	local dt = FrameTime()
	local eye = lp:EyePos()
	local maxsqr = cfg.DrawDist * cfg.DrawDist
	local looping = lp:Alive()

	for ent, g in pairs(active) do
		if !IsValid(ent) then clear(ent) continue end
		if g.life <= 0 then clear(ent) continue end

		g.life = g.life - dt
		g.t = g.t + dt
		g.n = g.n + 1

		if g.n < 3 then
			g.mul, g.mul2, g.fwd = 0.12, 0.9, 115
		elseif g.t < 2.5 then
			local k = math.Clamp((g.t - 0.15) / 2.35, 0, 1)
			g.mul = 0.12 + k * 0.38
			g.mul2 = 0.9 - k * 0.5
			g.fwd = 115 - k * 55
		else
			g.mul, g.mul2, g.fwd = 0.5, 0.4, 60
		end

		if g.next > time then continue end
		g.next = time + g.mul * 0.5

		local bone = ent:LookupBone(HEADBONE)
		if !bone then clear(ent) continue end

		local mat = ent:GetBoneMatrix(bone)
		if !mat then continue end

		local bpos, bang = LocalToWorld(g.lpos, angle_zero, mat:GetTranslation(), mat:GetAngles())
		local distsqr = bpos:DistToSqr(eye)
		if distsqr > maxsqr then continue end
		if !ent.shouldTransmit then continue end

		if looping and distsqr < NEARSQR then
			local tr = util_TraceLine({ start = bpos, endpos = bpos + lp:EyeAngles():Forward() * 900, filter = ent })
			if tr.Entity and (tr.Entity == ent or hg.RagdollOwner(tr.Entity) == ent) then
				g.life = 0
			end
		end

		local dir = bang:Forward() * math_random(15, 55) + VectorRand(-20, 20) + VectorRand(-20, 20)
		dir.z = -math_random(35, 85) - math.abs(dir.z) * 0.25

		applyFountain(bpos, dir:GetNormalized():Angle(), g.mul, g.mul2, g.fwd, ent)
	end
end)

hook.Add("EntityRemoved", "TS_DeathAnim_HeadGore", function(ent)
	clear(ent)
end)

hook.Add("PostCleanupMap", "TS_DeathAnim_HeadGore", function()
	active = {}
	goreCount = 0
end)
