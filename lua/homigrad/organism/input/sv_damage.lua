hg = hg or {}
hg.organism = hg.organism or {}

hg.organism.fake_spine1 = 1
hg.organism.fake_spine2 = 1
hg.organism.fake_spine3 = 0.5
hg.organism.fake_legs = 1
hg.organism.input_list = hg.organism.input_list or {}

hg.DeathCam = false

util.AddNetworkString("hg_bloodimpact")
util.AddNetworkString("bloodsquirt")

local hook_Run = hook.Run
local timer_Create = timer.Create
local timer_Simple = timer.Simple
local math_min = math.min
local math_max = math.max
local math_floor = math.floor
local math_abs = math.abs
local math_Clamp = math.Clamp
local math_Round = math.Round
local IsValid = IsValid
local input_list = hg.organism.input_list

local dir = Vector(0, 0, 0)

local function Trace_Bullet(box, hit, ricochet, org, organs, dmg, dmgInfo, dir)
	dmg = dmgInfo:GetDamage() / 25

	local organ = box[6] and organs[box[6]][box[7]]

	if !organ then return 0 end

	local name = organ[1]

	if !name then return 0 end
	if org.superfighter and !(string.find(name, "vest") or string.find(name, "helmet")) then return 0 end

	local bone = organ[2] or 0
	local func = input_list[name]
	local hook_info = {
		restricted = false,
		dmg = dmg,
	}

	hook_Run("PreTraceOrganBulletDamage", org, bone, dmg, dmgInfo, box, dir, hit, ricochet, organ, hook_info)

	dmg = hook_info.dmg

	if func and !hook_info.restricted then
		return func(org, bone, dmg, dmgInfo, box[6], dir, hit, ricochet)
	end

	return 0
end

local function Trace_Blast(box, amt, org, organs, dmg, dmgInfo)
	dmg = dmgInfo:GetDamage() / 25

	local organ = box[6] and organs[box[6]][box[7]]

	if !organ then return 0 end

	local name = organ[1]

	if !name then return 0 end
	if org.superfighter and !(string.find(name, "vest") or string.find(name, "helmet")) then return 0 end

	local bone = organ[2] or 0
	local func = input_list[name]

	local amount = amt * dmg

	if func then return func(org, 1, amount, dmgInfo, box[6], vector_origin, true, false) end
end

hook.Add("EntityTakeDamage", "homigrad-damage", function(ent, dmgInfo)
	if dmgInfo:IsDamageType(DMG_DISSOLVE) then return end

	local attacker = dmgInfo:GetAttacker()

	local org = ent.organism

	if ent:GetClass() == "npc_bullseye" then
		local rag = IsValid(ent.rag) and ent.rag or IsValid(ent.ply) and ent.ply

		if IsValid(rag) then
			rag:TakeDamageInfo(dmgInfo)
		end

		return true
	end

	if !org then return end

	if dmgInfo:GetAttacker():GetClass() == "npc_zombie" then
		dmgInfo:SetDamageType(org and org.immobilization > 50 and DMG_BLAST or DMG_SLASH)
		attacker.ImmobilizationMul = 2
		attacker.PainMultiplier = 0.5
		attacker.BleedMultiplier = 5
		attacker.Penetration = 5
		dmgInfo:ScaleDamage(1.2)
	end

	if ent:IsPlayer() and IsValid(ent.FakeRagdoll) then
		ent.FakeRagdoll:TakeDamageInfo(dmgInfo)
		return true
	end

	if dmgInfo:IsDamageType(DMG_CRUSH) then
		return true
	end

	local dmgtype = dmgInfo:GetDamageType()

	if org.godmode then return true end

	local ply = (ent:IsPlayer() and ent) or hg.RagdollOwner(ent)

	org.isPly = IsValid(ply)

	if ent == ply and IsValid(ply.FakeRagdoll) and dmgInfo:IsDamageType(DMG_BURN) then
		return true
	end

	local time = CurTime()

	local inf = IsValid(dmgInfo:GetInflictor()) and !dmgInfo:GetInflictor():IsPlayer() and dmgInfo:GetInflictor() or (dmgInfo:GetAttacker():IsPlayer() and dmgInfo:GetAttacker():GetActiveWeapon()) or dmgInfo:GetAttacker()
	inf = IsValid(inf.weapon) and inf.weapon or inf
	if IsValid(inf) then dmgInfo:SetInflictor(inf) end

	local dmg = dmgInfo:GetDamage()

	local bullet = inf.bullet

	local pen = (bullet ~= nil and bullet.Penetration) or
		(IsValid(inf) and inf.Penetration) or dmg / 2

	pen = pen * (dmgInfo:IsDamageType(DMG_CLUB+DMG_GENERIC) and 1 or 1)

	local size = (bullet ~= nil and bullet.Diameter) or
		(IsValid(inf) and inf.PenetrationSize) or pen / 50

	local maxpen = (bullet ~= nil and bullet.MaxPenLen) or
		(IsValid(inf) and inf.MaxPenLen) or 0

	if PenetrationGlobal then
		pen = PenetrationGlobal

		PenetrationGlobal = nil
	end

	if MaxPenLenGlobal then
		maxpen = MaxPenLenGlobal

		MaxPenLenGlobal = nil
	end

	local shockMul = (bullet ~= nil and bullet.ShockMultiplier) or
		(IsValid(inf) and inf.ShockMultiplier) or 1

	local bleedMul = (bullet ~= nil and bullet.BleedMultiplier) or
		(IsValid(inf) and inf.BleedMultiplier) or 1

	local painMul = (bullet ~= nil and bullet.PainMultiplier) or
		(IsValid(inf) and inf.PainMultiplier) or 1

	local immobilizationMul = (bullet ~= nil and bullet.ImmobilizationMul) or
		(IsValid(inf) and inf.ImmobilizationMul) or 1

	local hurtMul = (bullet ~= nil and bullet.HurtMultiplier) or
		(IsValid(inf) and inf.HurtMultiplier) or 1

	if bullet and bullet.dmgtype then
		dmgInfo:SetDamageType(bullet.dmgtype)
	end

	if org.superfighter then
		dmgInfo:ScaleDamage(1)
	end

	if dmgInfo:IsDamageType(DMG_BURN) then
		painMul = 0.1
		shockMul = 0.1
	end

	if !dmgInfo:IsDamageType(DMG_BURN) then
		timer_Create("send_info_org"..org.owner:EntIndex(), 0.01, 1, function()
			if !IsValid(org.owner) then return end

			org.owner.fullsend = true
			hg.send_bareinfo(org)

			if IsValid(org.owner) and org.owner.Alive and org.owner:Alive() then
				hg.send_organism(org, org.owner)
			end
		end)
	end

	dir:Set(dmgInfo:GetDamageForce())
	dir:Normalize()
	dir:Mul(pen)

	ent.armors = ent.armors or {}

	if dmgInfo:GetInflictor().poisoned2 and dmgInfo:IsDamageType(DMG_SLASH) then
		org.poison4 = CurTime()

		dmgInfo:GetInflictor().poisoned2 = nil
	end

	local organs = hg.organism.GetHitBoxOrgans(ent:GetModel(), ent)
	local boxs, pos, sphere = hg.organism.ShootMatrix(ent, organs)
	local dmgPos = dmgInfo:GetDamagePosition()
	local tr = util.QuickTrace(dmgPos, dir:GetNormalized() * 100)

	if tr.Hit and tr.Entity == ent then
		dmgPos = tr.HitPos
	else
		tr = util.QuickTrace(dmgPos, -(dmgPos - (ent:GetPos() + ent:OBBCenter())))

		if tr.Hit and tr.Entity == ent then
			dir = tr.Normal * pen
			dmgPos = tr.HitPos
		end
	end

	attacker.harm = dmgInfo:GetDamage() / 100

	if ply or org.fakePlayer then
		hook_Run("PreHomigradDamage", org.fakePlayer and ent or ply, dmgInfo, hitgroup, ent, attacker.harm, hitBoxs, inputHole)
	end

	local dmg_before = dmgInfo:GetDamage()

	local lastPos, hitBoxs, inputHole, outputHole, outputDir, distance, tracePoses = nil, {}, {}, {}, {}, nil, nil

	if dmgInfo:IsDamageType(DMG_BULLET+DMG_BUCKSHOT+DMG_SLASH+DMG_CLUB+DMG_GENERIC) then
		lastPos, hitBoxs, inputHole, outputHole, outputDir, distance, tracePoses = hg.organism.Trace(dmgPos, dir, size, maxpen, boxs, pos, sphere, organs, dmgInfo:IsDamageType(DMG_BULLET+DMG_BUCKSHOT), Trace_Bullet, ent.organism, organs, dmg / 25, dmgInfo, dir)
	elseif dmgInfo:IsDamageType(DMG_BLAST) then
		local blastOrgans = hg.organism.GetHitBoxOrgans(ent:GetModel(), ent)
		local blastBoxs, blastPos, blastSphere = hg.organism.ShootMatrix(ent, blastOrgans)

		hg.organism.BlastTrace(dmgInfo:GetDamagePosition(), (ent:GetPos() - dmgInfo:GetDamagePosition()):Length() / 200, dmg * 2, blastBoxs, blastOrgans, Trace_Blast, ent.organism, blastOrgans, dmg / 300, dmgInfo)
		hg.organism.AddWoundManual(ent, dmg, vector_origin, angle_zero, math.random(0, ent:GetBoneCount()), CurTime())
	end

	if attacker:IsPlayer() then
		ent:SetPhysicsAttacker(attacker, 15)
	end

	if !inf.ShouldAttackOnce or !inf.attackedOnce then
		if dmgInfo:IsDamageType(DMG_BULLET+DMG_BUCKSHOT) then
			org.bulletwounds = org.bulletwounds + 1
		end

		if dmgInfo:IsDamageType(DMG_SLASH) then
			if dmgInfo:GetInflictor().slash then
				org.slashwounds = org.slashwounds + 1
			else
				org.stabwounds = org.stabwounds + 1
			end
		end

		if dmgInfo:IsDamageType(DMG_CLUB+DMG_GENERIC) then
			org.bruises = org.bruises + 1
		end

		if dmgInfo:IsDamageType(DMG_BURN) then
			org.burns = org.burns + 1
		end

		if dmgInfo:IsDamageType(DMG_BLAST) then
			org.explosionwounds = org.explosionwounds + 1
		end
	end

	local att = dmgInfo:GetAttacker()

	if outputHole and #outputHole > 0 and dmgInfo:IsDamageType(DMG_BULLET+DMG_BUCKSHOT) then
		local bullet = inf.bullet

		ent.bloodamt = ent.bloodamt or 0
		ent.bloodamt = ent.bloodamt + 1

		timer_Simple(0, function()
			if !IsValid(ent) then return end

			if bullet and true then
				local mul = distance / pen

				bullet.Src = outputHole[#outputHole]
				bullet.Dir = dir:GetNormalized()
				bullet.Force = bullet.Force * mul
				bullet.Damage = bullet.Damage * mul
				bullet.Num = 1
				bullet.Attacker = att
				bullet.Tracer = 0
				bullet.TracerName = "nil"
				bullet.IgnoreEntity = ent
				bullet.Filter = {ent, ply and ply:InVehicle() and ply:GetVehicle() or nil}
				bullet.penetrated = bullet.penetrated or 0
				bullet.limit_ricochet = bullet.limit_ricochet or 0
				bullet.penetrated = bullet.penetrated + 1
				bullet.limit_ricochet = bullet.limit_ricochet + 1
				bullet.Penetration = distance

				inf:FireLuaBullets(bullet, true)

				local exitTrace = util.QuickTrace(outputHole[#outputHole], -outputDir:GetNormalized() * 10, ent)
				local effectdata1 = EffectData()
				effectdata1:SetOrigin(outputHole[#outputHole])
				effectdata1:SetStart(exitTrace.HitPos)
				effectdata1:SetEntity(inf)
				effectdata1:SetMagnitude(2)
				util.Effect("eff_tracer", effectdata1)
			end
		end)
	end

	local bone = tr.Entity == ent and tr.PhysicsBone

	if !bone then
		local inwardDir = -(dmgPos - (ent:GetPos() + ent:OBBCenter())):GetNormalized()
		local inwardTrace = util.QuickTrace(dmgPos, inwardDir * 100)
		bone = inwardTrace.PhysicsBone
	end

	local woundPos = dmgInfo:GetDamagePosition()
	local dirCool = dmgInfo:GetDamageForce():GetNormalized()
	local woundTrace = util.QuickTrace(woundPos, dirCool * 100)
	local len = math_abs(dmgInfo:GetDamageForce():Length())

	local bonename = ent:GetBoneName(ent:TranslatePhysBoneToBone(bone))
	local hitgroup = hg.bonetohitgroup[bonename] or 0

	if hg.organism.RagdollForceBoneMul[hitgroup] then len = len * hg.organism.RagdollForceBoneMul[hitgroup] end

	if dmgInfo:IsDamageType(DMG_BULLET) and hg.organism.RagdollDamageBoneMul[hitgroup] then
		dmgInfo:ScaleDamage(hg.organism.RagdollDamageBoneMul[hitgroup])
		dmg_before = dmg_before * hg.organism.RagdollDamageBoneMul[hitgroup]
	end

	if inputHole and #inputHole > 0 and dmgInfo:IsDamageType(DMG_BULLET+DMG_BUCKSHOT) then
		ent.bloodamt2 = ent.bloodamt2 or 0
		ent.bloodamt2 = ent.bloodamt2 + 1

		timer_Simple(0, function()
			timer_Create("Blood_burst_input"..ent:EntIndex(), 0.02, 1, function()
				if !IsValid(ent) then return end

				net.Start("hg_bloodimpact")
				net.WriteVector(inputHole[1])
				net.WriteVector(dir / 2)
				net.WriteFloat(dmg)
				net.WriteInt(ent.bloodamt2, 8)
				net.Broadcast()
				ent.bloodamt2 = 0
			end)
		end)
	end

	local dmgBlood, dmgHurt, instaPain, immobilization = hg.organism.DamageTypeAffliction(dmg_before / 12, dmgInfo, ent, org)

	local hitbody = #inputHole > 0 or !dmgInfo:IsDamageType(DMG_BULLET+DMG_BUCKSHOT)

	if !org.superfighter then
		dmgBlood = dmgBlood * 1.5

		local bleed_add = dmgBlood * bleedMul

		attacker.harm = attacker.harm + bleed_add / 50

		local hurt_add = dmgHurt * 0.5 * hurtMul
		local painadd = dmgHurt * painMul * 1.5
		local instantPainMul = 0.2
		local instant_pain = instantPainMul * painadd
		local slow_pain = (1 - instantPainMul) * painadd

		org.painadd = org.painadd + slow_pain
		org.shock = math_min(org.shock + instaPain * shockMul * 4.5 * math_Clamp(pen / 5, 1, 2), 70)
		org.immobilization = math_min(org.immobilization + immobilization * immobilizationMul, 30)
		org.lasthit = CurTime()

		local adrenaline = org.adrenaline
		local analgesiaMul = (org.analgesia * 4 + 1)
		local painkillerMul = (org.painkiller * 0.5 + 1)

		org.shock_turn = 10 * (!org.otrub and 1 or 0.1)

		if dmgInfo:IsDamageType(DMG_BLAST + DMG_FALL) and org.shock > org.shock_turn * 1.5 * analgesiaMul * painkillerMul then
			timer_Simple(0, function() if IsValid(org.owner) then hg.Fake(org.owner) end end)
		end

		if bullet and hg.ammotypes_reverted[bullet.AmmoType] and hg.ammotypes_reverted[bullet.AmmoType].BulletSettings.tranquilizer then
			org.tranquilizer = org.tranquilizer + dmgInfo:GetDamage()
		end

		if dmgInfo:IsDamageType(DMG_BULLET+DMG_BUCKSHOT+DMG_SLASH+DMG_BURN) then
			org.fearadd = org.fearadd + 0.3
		end

		org.fearadd = org.fearadd + hurt_add * 0.5

		if dmgInfo:IsDamageType(DMG_BURN) then
			local bigRand = math.Rand(0.0005, 0.0008)
			local smallRand = math.Rand(0.0001, 0.0002)

			org.lungsL[1] = math_min(org.lungsL[1] + bigRand, 1)
			org.lungsR[1] = math_min(org.lungsR[1] + bigRand, 1)

			input_list.liver(org, nil, smallRand, dmgInfo)
			input_list.stomach(org, nil, smallRand, dmgInfo)
			input_list.intestines(org, nil, smallRand, dmgInfo)

			hg.AddHarmToAttacker(dmgInfo, bigRand, "Burns harm")
		end
	else
		local sfd = org.fakePlayer and ent or ply

		if !IsValid(sfd) then return true end

		if sfd:Health() < 0 then
			sfd:Kill()
			return true
		else
			sfd:SetHealth(sfd:Health() - dmg_before * .15)
		end
	end

	if !org.otrub and org.adrenalineAdd >= 0 then
		org.owner:AddNaturalAdrenaline(instaPain * 0.75 * (dmgInfo:IsDamageType(DMG_BLAST) and 4 or 1) * (dmgInfo:IsDamageType(DMG_BULLET+DMG_BUCKSHOT) and 4 or 1))
	end

	if dmgInfo:IsDamageType(DMG_BULLET + DMG_BUCKSHOT + DMG_BLAST + DMG_SLASH) or (dmgInfo:IsDamageType(DMG_GENERIC + DMG_VEHICLE + DMG_FALL + DMG_CLUB)) then
		local hook_info = {
			bleed = dmgBlood,
			input_hole = inputHole,
			output_hole = outputHole,
			bone = bone,
			restricted = false,
		}

		hook_Run("PreHomigradDamageBulletBleedAdd", org.fakePlayer and ent or ply, org, dmgInfo, hitgroup, attacker.harm, hitBoxs, inputHole, hook_info)

		if !hook_info.restricted then
			hg.organism.AddWound(ent, woundTrace, bone, dmgInfo, woundPos, hook_info.bleed, inputHole, outputHole)
		end
	end

	if ply or org.fakePlayer then
		hook_Run("HomigradDamage", org.fakePlayer and ent or ply, dmgInfo, hg.bonetohitgroup[bonename], ent, attacker.harm, hitBoxs, inputHole)
	end

	attacker.harm = 0

	if dmgInfo:IsDamageType(DMG_BULLET + DMG_BUCKSHOT + DMG_BLAST + DMG_SLASH + DMG_CLUB + DMG_GENERIC) then
		local force = dirCool * len

		if ply then
			ply.HitBones = ply.HitBones or {}

			if hg.organism.hitgrouptobone[hitgroup] then
				for i, bon in ipairs(hg.organism.hitgrouptobone[hitgroup]) do
					if hitgroup == HITGROUP_STOMACH or hitgroup == HITGROUP_CHEST then dmg = dmg / 2 end
					ply.HitBones[bon] = CurTime() + dmg
				end
			end

			hg.AddForceRag(ply, bone, force * 0.5, 0.5)

			if dmgInfo:IsDamageType(DMG_BLAST + DMG_FALL) and ply.AddForceRag[bone][2] and ply.AddForceRag[bone][2]:Length() > 4500 then
				if ply.AddForceRag[bone][2]:Length() > 7000 then
					hg.StunPlayer(ply, 0.5)
					hg.LightStunPlayer(ply, 2)
				else
					hg.LightStunPlayer(ply, 2)
				end
			end
		end

		if ent:IsRagdoll() then
			ent:GetPhysicsObjectNum(bone or 0):ApplyForceCenter(force * 1)
		end
	end

	if dmgInfo:IsDamageType(DMG_BLAST) then
		hitgroup = table.Random({
			HITGROUP_LEFTARM,
			HITGROUP_RIGHTARM,
			HITGROUP_RIGHTLEG,
			HITGROUP_LEFTLEG,
			HITGROUP_HEAD
		})
	end

	local lend = math_max(0.1, (ent:GetPos() - dmgInfo:GetDamagePosition()):Length())
	local damageStack = dmg_before / (dmgInfo:IsDamageType(DMG_BULLET) and hg.organism.RagdollDamageBoneMul[hitgroup] or 1)

	damageStack = damageStack * (dmgInfo:IsDamageType(DMG_BLAST) and 200 / lend or 1) * (!dmgInfo:IsDamageType(DMG_CLUB+DMG_SLASH+DMG_BULLET+DMG_BLAST+DMG_SNIPER) and 0 or 1) * (ent:IsNPC() and 3 or 1)

	org.dmgstack = org.dmgstack or {}
	org.dmgstack[hitgroup] = org.dmgstack[hitgroup] or {}

	local mul = (org.dmgstack[hitgroup][3] or 0) + 1

	org.dmgstack[hitgroup][1] = ((org.dmgstack[hitgroup][2] and (ent.organism.dmgstack[hitgroup][2] + 0.05 * mul) > CurTime()) and ent.organism.dmgstack[hitgroup][1] * ((ent.organism.dmgstack[hitgroup][2] + 0.05 * mul) - CurTime()) / (0.05 * mul) or 0) + damageStack * mul
	org.dmgstack[hitgroup][2] = CurTime()
	org.dmgstack[hitgroup][3] = (org.dmgstack[hitgroup][3] or 0) + damageStack / 500

	local mat = ent:GetBoneMatrix(ent:TranslatePhysBoneToBone(bone))
	local hitgroup_max = 100
	local instant = org.dmgstack[hitgroup][1] > hitgroup_max

	local blast = dmgInfo:IsDamageType(DMG_BLAST)

	timer_Create("dmgstack"..org.entindex, !instant and 1 or 0, 1, function()
		local rag = IsValid(ply) and (IsValid(ply:GetNWEntity("RagdollDeath", ply.FakeRagdoll)) and ply:GetNWEntity("RagdollDeath", ply.FakeRagdoll)) or ent:IsRagdoll() and ent or ent:IsNPC() and ent
		local stackOrg = rag and rag.organism or ent.organism

		timer_Simple(0.01, function()
			if !stackOrg or !stackOrg.dmgstack or !stackOrg.dmgstack[hitgroup] or !stackOrg.dmgstack[hitgroup][1] then return end

			local should = stackOrg.dmgstack[hitgroup][1] > hitgroup_max

			local limbs = {
				"lleg",
				"rleg",
				"larm",
				"rarm",
			}

			if should and hg.organism.hitgrouptolimb[hitgroup] then
				if blast then
					for i, limb in ipairs(limbs) do
						if !stackOrg[limb.."amputated"] and math.random(5) < 200 / lend then
							hg.organism.AmputateLimb(stackOrg, limb)
						end
					end
				else
					if !stackOrg[hg.organism.hitgrouptolimb[hitgroup].."amputated"] then
						hg.organism.AmputateLimb(stackOrg, hg.organism.hitgrouptolimb[hitgroup])
					end
				end
			end

			if !IsValid(rag) then
				stackOrg.dmgstack[hitgroup][1] = nil
				stackOrg.dmgstack[hitgroup][2] = nil

				return
			end

			if IsValid(ply) and ply:Alive() then
				stackOrg.dmgstack[hitgroup][1] = nil
				stackOrg.dmgstack[hitgroup][2] = nil

				return
			end

			should = stackOrg.dmgstack[hitgroup][1] > hitgroup_max

			if should and hitgroup == HITGROUP_HEAD then
				hg.ExplodeHead(ent)

				stackOrg.dmgstack[hitgroup][1] = nil
				stackOrg.dmgstack[hitgroup][2] = nil
			end

			if IsValid(rag) then
				if !rag.bloodsquirted and !rag.headexploded and (hitgroup == HITGROUP_HEAD) and (bit.band(dmgtype, DMG_BULLET + DMG_BUCKSHOT) > 0) and math.random(4) == 1 and stackOrg.pulse > 30 then
					rag.bloodsquirted = true

					net.Start("bloodsquirt")
					net.WriteEntity(rag)
					net.WriteString(bonename)
					net.WriteMatrix(mat)
					net.WriteVector(woundPos + dirCool * 2)
					net.WriteVector(-dirCool * 2)
					net.Broadcast()

					if outputHole and #outputHole > 0 then
						net.Start("bloodsquirt")
						net.WriteEntity(rag)
						net.WriteString(bonename)
						net.WriteMatrix(mat)
						net.WriteVector(outputHole[1] - dirCool * 2)
						net.WriteVector(dirCool * 2)
						net.Broadcast()
					end
				end
			end

			stackOrg.dmgstack[hitgroup][1] = nil
			stackOrg.dmgstack[hitgroup][2] = nil

			stackOrg.owner.fullsend = true
			hg.send_bareinfo(stackOrg)
		end)
	end)

	dmgInfo:ScaleDamage(dmgInfo:IsDamageType(DMG_BURN) and 0.015 or 0.15)

	hg.takeRagdollDamage(ent, dmgInfo)

	if !org.superfighter and !dmgInfo:IsDamageType(DMG_CRUSH) then
		local healthTarget = ent:IsPlayer() and ent or (IsValid(ply) and ply or nil)

		if IsValid(healthTarget) and healthTarget:Alive() then
			local healthDmg = dmg_before

			if dmgInfo:IsDamageType(DMG_BULLET + DMG_BUCKSHOT) then
				healthDmg = healthDmg * 0.65
			end

			healthTarget:SetHealth(math_max(healthTarget:Health() - healthDmg, 0))

			if healthTarget:Health() <= 0 then
				local killEnt = healthTarget

				timer_Simple(0, function() if IsValid(killEnt) and killEnt:Alive() then killEnt:Kill() end end)
			end
		end
	end

	if org.isPly then
		hook_Run("Org Think Call", ply, org)

		if (!ply:Alive() or !org.alive) and (math_Round(ply:GetInfoNum("hg_deathfadeout", 1)) == 1) then
			ply:ScreenFade(0, color_black, 1, 1)
			ply:ConCommand("soundfade 100 99999")
		end
	end

	if dmgInfo:IsDamageType(DMG_BULLET + DMG_BUCKSHOT) then
		if dmgBlood > 1 and #inputHole > 0 then
			net.Start("hg_bloodimpact")
			net.WriteVector(woundPos)
			net.WriteVector(dirCool / 15)
			net.WriteFloat(dmg / 10)
			net.WriteInt(1, 8)
			net.Broadcast()
		end
	end

	if ply and !ply:GetNetVar("headcrab") and (ply.PlayerClassName != "Gordon" or ply.armors.head != "gordon_helmet") and ply.PlayerClassName ~= "headcrabzombie" then
		local class = dmgInfo:GetAttacker():GetClass()

		if dmgInfo:GetAttacker():IsNPC() and hg.organism.headcrabClasses[class] then
			local armors = ply:GetNetVar("Armor", {})
			local isHelm = armors["head"] and !hg.armor["head"][armors["head"]].nodrop
			local isMask = armors["face"] and !hg.armor["face"][armors["face"]].nodrop

			if isHelm or isMask then
				hg.DropArmorForce(ply, isHelm and armors["head"] or armors["face"])
				ply.ArmorCD = CurTime() + 5

				return
			end

			ply.PreZombClass = ply.PlayerClassName

			ply:AddHeadcrab(hg.organism.headcrabModels[class])

			dmgInfo:GetAttacker():Remove()
		end
	end

	return !ent:IsNPC()
end)
