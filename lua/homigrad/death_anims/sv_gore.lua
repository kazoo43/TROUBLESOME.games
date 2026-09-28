TS_DeathAnim = TS_DeathAnim or {}

local IsValid, ents_Create = IsValid, ents.Create
local math_random, math_Rand = math.random, math.Rand
local VectorRand, AngleRand = VectorRand, AngleRand
local util_PointContents, util_IsValidModel = util.PointContents, util.IsValidModel
local LocalToWorld, ThatPlyIsFemale = LocalToWorld, ThatPlyIsFemale
local SafeRemoveEntityDelayed = SafeRemoveEntityDelayed

util.AddNetworkString("ts_deathanim_headclub")

local liveTeeth = {}
local ready = false

local function release(ent)
	for i = #liveTeeth, 1, -1 do
		if liveTeeth[i] == ent then
			liveTeeth[i] = liveTeeth[#liveTeeth]
			liveTeeth[#liveTeeth] = nil
			break
		end
	end
end

local function spawnTooth(cfg, pos, ang, dir, vel, sub)
	if #liveTeeth >= cfg.TeethMaxLive then
		local old = liveTeeth[1]
		if IsValid(old) then old:Remove() end
		release(old)
	end

	local ent = ents_Create("prop_physics")
	if !IsValid(ent) then return end

	ent:SetModel(cfg.Model)
	ent:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
	ent:SetSolid(SOLID_VPHYSICS)
	ent:SetPos(pos)
	ent:SetAngles(AngleRand(-180, 180))
	ent:Spawn()
	ent:Activate()
	ent:SetModelScale(math_Rand(cfg.TeethScaleMin, cfg.TeethScaleMax), 0)

	ent:SetBodygroup(cfg.BodyGroup, sub)
	ent:DrawShadow(false)
	ent.PhysgunDisabled = true

	SafeRemoveEntityDelayed(ent, cfg.TeethLife)

	local phys = ent:GetPhysicsObject()
	if IsValid(phys) then
		phys:SetMaterial("gmod_silent")
		phys:SetMass(cfg.TeethMass)
		phys:SetVelocity(vel + dir * math_random(cfg.TeethSpeedMin, cfg.TeethSpeedMax))
		phys:AddAngleVelocity(VectorRand(-70, 70))
		phys:EnableGravity(true)
		phys:Wake()

		pcall(function()
			phys:SetDamping(0.7, 0)
			phys:SetDragCoefficient(0.02)
			phys:SetAngleDragCoefficient(0.05)
		end)
	end

	liveTeeth[#liveTeeth + 1] = ent

	ent:CallOnRemove("TS_DeathAnim_Tooth", release)
end

function TS_DeathAnim.HeadGore(rag, hitPos)
	local cfg = TS_DeathAnim.HeadClub
	if !cfg then return end

	if !ready then
		if !util_IsValidModel(cfg.Model) then return end
		ready = true
		util.PrecacheModel(cfg.Model)
		util.PrecacheSound(cfg.BluntSound)
		util.PrecacheSound(cfg.TeethSound)
	end

	if !IsValid(rag) then return end
	if rag.TS_HeadGore then return end
	if rag.noHead then return end

	local head = rag:LookupBone("ValveBiped.Bip01_Head1")
	if !head then return end

	local mat = rag:GetBoneMatrix(head)
	if !mat then return end

	rag.TS_HeadGore = true

	local lpos = ThatPlyIsFemale(rag) and cfg.MouthFemale or cfg.MouthMale
	local pos, ang = LocalToWorld(lpos, angle_zero, mat:GetTranslation(), mat:GetAngles())
	local vel = rag:GetVelocity()
	local fwd = ang:Forward()
	local up = ang:Up()

	rag:EmitSound(cfg.BluntSound, 85, math_Rand(96, 104), 1)

	timer.Simple(0.06, function()
		if !IsValid(rag) then return end
		rag:EmitSound(cfg.TeethSound, 85, math_Rand(94, 106), 1)
	end)

	net.Start("ts_deathanim_headclub")
	net.WriteEntity(rag)
	net.WriteFloat(cfg.GoreTime)
	net.WriteVector(lpos)
	net.Broadcast()

	net.Start("hg_bloodimpact")
	net.WriteVector(hitPos or pos)
	net.WriteVector(fwd * 0.6)
	net.WriteFloat(2)
	net.WriteInt(1, 8)
	net.Broadcast()

	for i = 1, math_random(cfg.TeethMin, cfg.TeethMax) do
		local sp = pos + ang:Right() * math_Rand(-2, 2) + up * math_Rand(0, 3) + fwd * math_Rand(0, 2)
		local d = (fwd * math_random(0.4, 1) + VectorRand(-0.5, 0.5) + VectorRand(-0.5, 0.5) + up * math_random(0.3, 1.1)):GetNormalized()
		local sub = math_random(0, cfg.SubModels - 1)

		timer.Simple(i * cfg.TeethStep, function()
			if util_PointContents(sp) == CONTENTS_SOLID then return end
			spawnTooth(cfg, sp, ang, d, vel, sub)
		end)
	end
end

hook.Add("PostCleanupMap", "TS_DeathAnim_HeadGore", function()
	for i = #liveTeeth, 1, -1 do
		if IsValid(liveTeeth[i]) then liveTeeth[i]:Remove() end
		liveTeeth[i] = nil
	end
end)
