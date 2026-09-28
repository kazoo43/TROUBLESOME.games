hg = hg or {}
hg.organism = hg.organism or {}
hg.organism.input_list = hg.organism.input_list or {}

local IsValid = IsValid
local CurTime = CurTime
local math_min = math.min
local math_abs = math.abs
local math_max = math.max
local util_TraceLine = util.TraceLine
local util_TraceHull = util.TraceHull
local hook_Run = hook.Run
local input_list = hg.organism.input_list

local endpos = Vector(0, 0, 0)
local tr = {
	ignoreworld = true,
	mins = Vector(-3, -3, -3),
	maxs = Vector(3, 3, 3),
}

local function GetTraceDamage(ent, start, dir)
	dir = -(-dir)
	dir:Normalize()
	dir:Mul(512)

	start = -(-start)

	tr.start = start

	endpos:Set(start)
	endpos:Add(dir)
	tr.endpos = endpos

	local traceResult = util_TraceLine(tr)

	if !traceResult.Hit then
		endpos:Set(start)
		endpos:Sub(dir)
		traceResult = util_TraceHull(tr)
	end

	return traceResult
end

hg.GetTraceDamage = GetTraceDamage

local takeRagdollDamage

takeRagdollDamage = function(ent, dmgInfo)
	if !ent:IsRagdoll() then return end

	local ply = hg.RagdollOwner(ent)

	if !IsValid(ply) then return end
	if ply.organism and ply.organism.godmode then return end

	local traceResult = GetTraceDamage(ent, dmgInfo:GetDamagePosition(), dmgInfo:GetDamageForce())

	if !IsValid(ply) or !ply:Alive() then return end

	if traceResult.Hit then
		local bone = traceResult.PhysicsBone
		local hitgroup
		local bonename = ent:GetBoneName(ent:TranslatePhysBoneToBone(bone))

		if hg.bonetohitgroup[bonename] ~= nil then hitgroup = hg.bonetohitgroup[bonename] end

		if hg.organism.RagdollForceBoneMul[hitgroup] then
			dmgInfo:SetDamageForce(dmgInfo:GetDamageForce() * hg.organism.RagdollForceBoneMul[hitgroup])
		end

		if dmgInfo:GetInflictor():IsWeapon() and !dmgInfo:IsDamageType(DMG_CRUSH) then
			if hitgroup == HITGROUP_LEFTARM then
				if IsValid(ent.ConsLH) then
					ent.ConsLH:Remove()
					ent.ConsLH = nil
				end
			end

			if hitgroup == HITGROUP_RIGHTARM then
				if IsValid(ent.ConsRH) then
					ent.ConsRH:Remove()
					ent.ConsRH = nil
				end
			end
		end
	end
end

hg.takeRagdollDamage = takeRagdollDamage

local bleedSurfaces = {
	["boulder"] = true,
	["gravel"] = true,
	["rock"] = true,
	["concrete"] = true,
	["chain"] = true,
	["chainlink"] = true,
	["metalgrate"] = true,
	["glass"] = true,
	["glassbottle"] = true,
	["pottery"] = true,
	["combine_Metal"] = true,
	["cavern_rock"] = true,
	["glassfloor"] = true,
	["asphalt"] = true,
	["clay"] = true,
	["brokenglass"] = true,
	["boncretegrit"] = true,
	["glass_breakable"] = true,
}

local function velocityDamage(ent, data)
	local speed = (data.OurOldVelocity - data.TheirOldVelocity):Length()

	if speed < 350 then return end
	if data.HitEntity.Throwable then return end

	if !data.HitEntity:IsWorld() and data.HitEntity.lasttouched and data.HitEntity.lasttouched[ent] then
		if data.HitEntity.lasttouched[ent] + 0.5 > CurTime() then
			return
		end
	end

	data.HitEntity.lasttouched = data.HitEntity.lasttouched or {}
	data.HitEntity.lasttouched[ent] = CurTime()

	local dmg = speed / 5350 * data.DeltaTime * ((IsValid(data.HitObject) && !data.HitObject:GetEntity():IsWorld()) && math_min(data.HitObject:GetMass() / 20, 1) || 1)
	dmg = dmg * math_abs(data.OurOldVelocity:GetNormalized():Dot(data.HitNormal))

	if !ent.organism then return end
	if dmg * 20 < 0.1 then return end

	dmg = dmg * 1.5
	dmg = math_min(dmg, 5)

	local bone
	for i = 0, ent:GetPhysicsObjectCount() do
		local phys = ent:GetPhysicsObjectNum(i)

		if phys == data.PhysObject then
			bone = i
		end
	end

	local dmgInfo = DamageInfo()
	dmgInfo:SetDamage(dmg * 20)

	local surfaceType = util.GetSurfacePropName(data["TheirSurfaceProps"])

	dmgInfo:SetDamageType(DMG_CRUSH)

	local att = data.HitObject:GetEntity():GetPhysicsAttacker(15)
	att = IsValid(att) and att or ent:GetPhysicsAttacker(15)
	dmgInfo:SetAttacker(IsValid(att) and att or IsValid(dmgInfo:GetAttacker()) and dmgInfo:GetAttacker() or game.GetWorld())

	att.harm = dmgInfo:GetDamage() / 15

	local ply = hg.RagdollOwner(ent)

	GetTraceDamage(ent, data.HitPos, -(data.OurOldVelocity - data.TheirOldVelocity))

	if !bone then
		bone = tr.PhysicsBone
	end

	if IsValid(att) and att:IsPlayer() and att.organism and att.organism.fear and att.organism.fear < 0 then
		att.organism.fear = 0
	end

	local hitgroup
	local bonename = ent:GetBoneName(ent:TranslatePhysBoneToBone(bone or 0))

	if hg.bonetohitgroup[bonename] ~= nil then hitgroup = hg.bonetohitgroup[bonename] end

	if hg.organism.RagdollDamageBoneMul[hitgroup] then dmgInfo:ScaleDamage(hg.organism.RagdollDamageBoneMul[hitgroup]) end

	local org = ent.organism
	if org.godmode then return end

	org.fearadd = org.fearadd + dmg * 0.5

	if !org.superfighter then
		if hitgroup == HITGROUP_LEFTLEG and (dmg * 3 > 0.25) then input_list.llegup(org, bone, dmg * 1 * math.Rand(1, 2), dmgInfo) end
		if hitgroup == HITGROUP_RIGHTLEG and (dmg * 3 > 0.25) then input_list.rlegup(org, bone, dmg * 1 * math.Rand(1, 2), dmgInfo) end
		if hitgroup == HITGROUP_LEFTARM and (dmg * 2 > 0.2) then input_list.larmup(org, bone, dmg * 1 * math.Rand(1, 2), dmgInfo) end
		if hitgroup == HITGROUP_RIGHTARM and (dmg * 2 > 0.2) then input_list.rarmup(org, bone, dmg * 1 * math.Rand(1, 2), dmgInfo) end
		if hitgroup == HITGROUP_CHEST and (dmg * 3 > 0.25) then input_list.chest(org, bone, dmg * 3, dmgInfo) end
		if hitgroup == HITGROUP_STOMACH and (dmg * 3 > 0.25) then input_list.pelvis(org, bone, dmg * 3, dmgInfo) end

		if surfaceType and surfaceType ~= nil and bleedSurfaces[surfaceType] and (dmg * 3 > 0.17) and math.random(2) == 2 then
			hg.organism.AddWoundManual(ent, dmg * 5, vector_origin, angle_zero, bone, CurTime() + (dmg * 250))
		end

		if dmg > 0.2 then
			org.internalBleed = org.internalBleed + (dmg * 2.5)
		end

		org.owner:AddNaturalAdrenaline(math_min(dmg * 0.5, 4))

		if hitgroup == HITGROUP_HEAD then
			local hadhelmet = org.owner.armors and org.owner.armors["head"] != nil

			input_list.skull(org, bone, dmg * 6 * (hadhelmet and 0.2 or 1), dmgInfo)

			org.consciousness = math.Approach(org.consciousness, 0, dmg * 20 * (hadhelmet and 0.2 or 1))

			if dmg * 10 > 0.5 and !hadhelmet then
				org.otrub = true
				org.shock = org.shock + 10
			end
		end
	else
		local sfd = org.fakePlayer and ent or ply

		if !IsValid(sfd) then return end

		if sfd:Health() > 0 then
			sfd:SetHealth(sfd:Health() - dmg * 1)
		else
			sfd:Kill()
			return
		end
	end

	hook_Run("HomigradDamage", ent, dmgInfo, hitgroup, ent, att.harm, {}, {})

	if org.isPly and ply then
		hook.Run("Org Think Call", ply, org)

		if (!ply:Alive() or !org.alive) and (math.Round(ply:GetInfoNum("hg_deathfadeout", 1)) == 1) then
			ply:ScreenFade(0, color_black, 1, 1)
			ply:ConCommand("soundfade 100 99999")
		end
	end

	timer.Create("send_info_org"..ent:EntIndex(), 0.01, 1, function()
		if !IsValid(ent) then return end

		hg.send_bareinfo(org)

		if IsValid(ply) and ply.Alive and ply:Alive() then
			ply.fullsend = true
			hg.send_organism(org, ply)
		end
	end)

	att.harm = 0

	local dmghuy = dmg * 20

	if !org.superfighter then
		org.painadd = org.painadd + dmghuy
		org.shock = org.shock + dmghuy
	else
		dmghuy = dmghuy * 0.5
	end

	local healthOwner = IsValid(ply) and ply or (ent:IsPlayer() and ent:Alive() and ent or nil)

	if healthOwner and dmghuy >= 1 then
		healthOwner:SetHealth(math_max(healthOwner:Health() - dmghuy, 0))
		if healthOwner:Health() <= 0 and healthOwner:Alive() then healthOwner:Kill() end
	end
end

hg.velocityDamage = velocityDamage

hook.Add("Ragdoll Collide", "organism", function(ragdoll, data)
	if ragdoll == data.HitEntity then return end
	if data.DeltaTime < 0.25 then return end
	if !ragdoll:IsRagdoll() then return end
	if data.HitEntity:IsPlayerHolding() then return end

	velocityDamage(ragdoll, data)
end)

hook.Add("Player Getup", "huyhhgss", function(ply)
	if ply.callback_physics then
		ply:RemoveCallback("PhysicsCollide", ply.callback_physics)
		ply.callback_physics = nil
	end

	ply.callback_physics = ply:AddCallback("PhysicsCollide", function(ply, data)
		if data.HitEntity:IsPlayerHolding() then return end
		if ply:GetGroundEntity() == data.HitEntity then return end
		if data.TheirOldVelocity:Length() < 50 then return end

		local vel = data.TheirOldVelocity

		local needed = (data.HitEntity:IsRagdoll() and 200 or 4000)
		local force = vel:Length() * (data.HitObject:GetEntity():GetPhysicsObject():GetMass() / 24)

		if (force) > needed then
			if ply:IsBerserk() then
				return
			end

			local ent = data.HitObject:GetEntity()

			if ent:IsRagdoll() and hg.RagdollOwner(ent) then
				hook_Run("ZC_SomeoneGetFallBy", hg.RagdollOwner(ent), ply)
			end

			timer.Simple(0, function()
				hg.LightStunPlayer(ply, math_min(force / needed, 4))
			end)
		end
	end)
end)
