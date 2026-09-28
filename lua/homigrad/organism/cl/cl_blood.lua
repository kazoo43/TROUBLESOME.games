function hg.applyFountain(pos, ang, mul, mul2, forward, ent)
	if bit.band(util.PointContents(pos), CONTENTS_WATER) == CONTENTS_WATER then
		if math.random(2) == 1 then return end

		hg.addBloodPart2(pos, ang:Forward() * forward * 0.5 + VectorRand(-25, 25) * mul2, nil, nil, nil, nil, true, nil, ent)
		hg.addBloodPart2(pos + VectorRand(-1, 1), ang:Forward() * forward * 0.25 + VectorRand(-10, 10) * mul2, nil, nil, nil, nil, true, nil, ent)
	else
		hg.addBloodPart(pos, ang:Forward() * forward * 2 * math.abs(math.sin(CurTime() * 3) + math.cos(CurTime() * 5) + math.sin(CurTime() * 2) + 4) * 0.1 + ang:Right() * 15 * (math.sin(CurTime()) * 1) + ang:Right() * math.sin(CurTime() * 2) * 15 + VectorRand(-3, 3), nil, nil, nil, true)
		hg.addBloodPart(pos + VectorRand(-1, 1), ang:Forward() * 55 + VectorRand(-25, 25) * mul2, nil, nil, nil, nil, nil, ent)
	end
end

local min = math.min
local bit_band = bit.band
local util_PointContents = util.PointContents
local LocalToWorld = LocalToWorld
local GetNetVar = GetNetVar
local emit_sound = EmitSound

local vecTorso = Vector(1, 1, 1)

local pitchAddClasses = {
	["furry"] = 20,
	["headcrabzombie"] = -60,
}

local muffedClasses = {
	["headcrabzombie"] = true,
}

local hg_old_blood = ConVarExists("hg_old_blood") and GetConVar("hg_old_blood") or CreateClientConVar("hg_old_blood", 0, true, false, "new decals, or old", 0, 1)
local hg_blood_fps = ConVarExists("hg_blood_fps") and GetConVar("hg_blood_fps") or CreateClientConVar("hg_blood_fps", 24, true, nil, "fps to draw blood", 12, 165)
local hg_heartbeat_volume = ConVarExists("hg_heartbeat_volume") and GetConVar("hg_heartbeat_volume") or CreateClientConVar("hg_heartbeat_volume", 1, true, nil, "heartbeat loudness", 0, 4)


hook.Add("Player-Ragdoll think", "organism-think-client-blood", function(ply, ent, time)
	local organism = ply.organism
	local new_organism = ply.new_organism

	local seen = ent.shouldTransmit
	local wounds = ply.wounds
	local arterialwounds = ply.arterialwounds

	local org = ent.organism

	if !org then return end

	if org and org.pulse and org.o2 and org.o2[1] then
		org.pulsethink = org.pulsethink or 0

		local speed = math.Clamp(org.heartbeat / 60, 1, 3.3) * 0.5 * (org.o2[1] < 8 and 0 or 1)

		org.pulsethink = org.pulsethink + (org.heartbeat > 1 and 1 or 0) * (org.holdingbreath and 0 or 1) * FrameTime() * 5.6 * (speed) * (org.lungsfunction and 1 or 0) * ((org.alive and !ent.headexploded) and 1 or 0)

		local torso = ent:LookupBone("ValveBiped.Bip01_Spine2")

		if torso then
			if ent:GetPos():DistToSqr(lply:GetPos()) > 450 * 450 then return end

			local sin = (math.sin(org.pulsethink) + 1) * 0.5
			local amt = 0.05 * sin * math.max(org.pulse / 70, 0.5)
			local size = 1 + amt

			vecTorso[1] = size
			vecTorso[2] = size
			vecTorso[3] = size

			ent:ManipulateBoneScale(torso, vecTorso)

			vecTorso[1] = 0
			vecTorso[2] = amt * 2
			vecTorso[3] = 0

			if sin < 0.1 and org.analgesia <= 1.5 and !org.breathed then
				org.lastbreathed = CurTime()
				org.breathed = true

				local heartbeat = org.heartbeat or 0
				local muffed
				local pitch = math.Clamp(heartbeat / 200 * 100, 100, 100) * math.Clamp((org.stamina and org.stamina[1] and (1 + (1 - org.stamina[1] / org.stamina.max) * 0.2) or 1), 1, 1.2)
				local vol = math.Remap(heartbeat, 70, 300, 0, 0.25) + (org.stamina and org.stamina[1] and 1 - org.stamina[1] / org.stamina.max or 0)

				if ent.armors then
					muffed = ent.armors["face"] == "mask2" or ent.PlayerClassName == "Combine"
				end

				if ply.PlayerClassName and muffedClasses[ply.PlayerClassName] then
					muffed = muffedClasses[ply.PlayerClassName]
				end

				local pitchadd = 0
				if ply.PlayerClassName and pitchAddClasses[ply.PlayerClassName] then
					pitchadd = pitchAddClasses[ply.PlayerClassName]
				end


				ply:EmitSound("snds_jack_hmcd_breathing/" .. (ThatPlyIsFemale(ent) and "f" or "m") .. math.random(4) .. ".wav", min(heartbeat * 1.0 / (muffed and 2.5 or 4), 45), pitch + pitchadd + math.Rand(-2, 2), vol, CHAN_AUTO, 0, muffed and 16 or 0)
			elseif org.breathed and sin >= 0.1 then
				org.breathed = false
			end
		end
	end

	ply.pulse_breathe = ply.pulse_breathe or {}
	ent.pulse_breathe = ply.pulse_breathe

	hg.LerpVariables(FrameTime() * 10, organism, new_organism)

	local owner = ent
	local beatsPerSecond = math.max(min(30 / math.max(org.pulse or 70, 2), 4), 0.1) * (!hg_old_blood:GetBool() and 0.3 or 1)

	if org.pulse and org.heartbeat > 30 and (org.lastpulse or 0) + (1 / math.Clamp(org.heartbeat, 1, 600)) * 60 < CurTime() then
		org.lastpulse = CurTime()

		local pulse = org.heartbeat or 0
		local pain = org.pain or 0

		local dist = owner:GetPos():DistToSqr(lply:GetPos())
		local carryent = lply:GetNetVar("carryent")
		local carrybone = lply:GetNetVar("carrybone")
		local cantcheck = org.CantCheckPulse
		local checkingplayer = (IsValid(carryent) and carryent.organism == ply.organism and !cantcheck and hg.organism.pulsebones[carryent:GetBoneName(carryent:TranslateBoneToPhysBone(carrybone))])

		if dist < 64 * 64 and ((ply == lply and !checkingplayer) or checkingplayer) then
			local vol = checkingplayer and 2 or ((pain > 60 and ply == lply) and 1 or (pulse > 200 and ((200 - 95) / 50 + 0.12 - (pulse - 200) / 1000) or pulse > 95 and (pulse - 95) / 50 + 0.12 or 0.12))

			if !checkingplayer then
				vol = math.Clamp(vol, 0, 0.7) * hg_heartbeat_volume:GetFloat()
			end

			if ent:GetVelocity():LengthSqr() < 10 then
				sound.Play("heartbeat/heartbeat_single.wav", ply:EyePos(), 55, 60, vol * 1.5)
			else
				emit_sound("heartbeat/heartbeat_single.wav", ply:EyePos(), ply:EntIndex(), CHAN_AUTO, vol, 55, nil, 60)
			end
		end
	end

	if org.pulse and (ent.pulse_breathe.lastbreathe or 0) < CurTime() and org.lastbreathed and org.lastbreathed + 5 < CurTime() then
		local heartbeat = org.heartbeat or 0

		ent.pulse_breathe.lastbreathe = CurTime() + (1 / math.Clamp(org.heartbeat + (org.o2[1] - 30) * 1, 1, 120)) * 90 + (org.o2[1] < 20 and 5 or 0)

		if org.analgesia <= 1.5 and org.heartbeat > 1 then
			if (ent:WaterLevel() < 3) then
				local muffed

				if ent.armors then
					muffed = ent.armors["face"] == "mask2" or ent.PlayerClassName == "Combine"
				end

				if org.timeValue and org.o2.curregen <= org.timeValue * 0.5 and org.o2[1] < 20 then
					ply:EmitSound("zcitysnd/real_sonar/"..(ThatPlyIsFemale(ent) and "fe" or "").."male_wheeze"..math.random(5)..".mp3", 40, nil, nil, nil, nil, 1)
				end
			else
				if org.o2[1] < 15 then
					ply:EmitSound("zcitysnd/real_sonar/"..(ThatPlyIsFemale(ent) and "fe" or "").."male_drown"..math.random(5)..".mp3", 60)
				end
			end
		end
	end

	local fountains = GetNetVar("fountains")

	if fountains and fountains[ent] then
		local tbl = fountains[ent]

		if (tbl.time or 0) < CurTime() and org.pulse then
			local mul = 1 / math.max(org.pulse / 40 * 25, 2) * 0.75
			local mul2 = math.max(org.pulse, 1) / 15
			local forward = mul2 * 150

			tbl.time = CurTime() + mul * 0.5

			if seen then
				local mat = ent:GetBoneMatrix(tbl.bone)

				if mat then
					local pos, ang = LocalToWorld(tbl.lpos, tbl.lang, mat:GetTranslation(), mat:GetAngles())

					hg.applyFountain(pos, ang, mul, mul2, forward, ent)
				end
			else
				hg.applyFountain(ent:GetPos(), angle_zero, mul, mul2, forward, ent)
			end
		end
	end

	if org and org.blood and org.blood > 10 and wounds and #wounds > 0 then
		if (owner:IsPlayer() and owner:Alive()) or !owner:IsPlayer() then
			for i, wound in pairs(wounds) do
				local size = math.random(0, 1) * math.max(math.min(wound[1], 1), 0.5)

				if wound[5] + beatsPerSecond < time then
					if seen and ent:LookupBone(wound[4]) then
						local bone = wound[4]
						local should = !(hg.amputatedlimbs2[bone] and org[hg.amputatedlimbs2[bone].."amputated"])

						if !should then continue end

						local mat = ent:GetBoneMatrix(ent:LookupBone(bone))

						if !mat then return end

						local bonePos, boneAng = mat:GetTranslation(), mat:GetAngles()

						if !wound[2] or !wound[3] or !bonePos or !boneAng then return end

						local pos, ang = LocalToWorld(wound[2], wound[3], bonePos, boneAng)

						local water = bit_band(util_PointContents(pos), CONTENTS_WATER) == CONTENTS_WATER

						if water then
							if wound[5] + 1 < time then
								hg.addBloodPart2(pos, VectorRand(-5, 5), nil, nil, nil, nil, true, nil, ent)
							end
						else
							hg.addBloodPart(pos, VectorRand(-15, 15), nil, size, size, false, nil, ent)
						end

						wound[5] = time + (water and 2 or (math.Rand(0, 1) * (!hg_old_blood:GetBool() and 0.5 or 1) / wound[1] * 15))
					else
						local pos = ent:GetPos()

						local water = bit_band(util_PointContents(pos), CONTENTS_WATER) == CONTENTS_WATER

						if water then
							hg.addBloodPart2(pos, VectorRand(-5, 5), nil, nil, nil, nil, true, nil, ent)
						else
							hg.addBloodPart(pos, VectorRand(-15, 15), nil, size, size, false, nil, ent)
						end

						wound[5] = time + (water and 2 or (math.Rand(0, 1) * (!hg_old_blood:GetBool() and 0.5 or 1) / wound[1] * 15))
					end
				end
			end
		end
	end

	if org and org.blood and org.blood > 10 and arterialwounds and #arterialwounds > 0 then
		for i, wound in pairs(arterialwounds) do
			local addtime = seen and 1 / math.Clamp(org.pulse or 70, 1, 15) * 0.25 or 0.06

			if wound[5] + addtime < time and ent:LookupBone(wound[4]) then
				local pos, ang = ent:GetBonePosition(ent:LookupBone(wound[4]))

				if (owner:IsPlayer() and owner:Alive()) or !owner:IsPlayer() then
					local size = math.random(1, 2) * math.max(math.min(wound[1], 1), 0.5)

					if seen and ent:LookupBone(wound[4]) then
						local bone = wound[4]
						local should = !(hg.amputatedlimbs2[bone] and org[hg.amputatedlimbs2[bone].."amputated"])

						if !should then continue end

						local mat = ent:GetBoneMatrix(ent:LookupBone(bone))

						if !mat then return end

						local bonePos, boneAng = mat:GetTranslation(), mat:GetAngles()

						if !wound[2] or !wound[3] or !bonePos or !boneAng then return end

						local woundPos = LocalToWorld(wound[2], wound[3], bonePos, boneAng)

						local dir = wound[6]
						local len = dir:Length() * (org.pulse or 70) / 70
						local _, dir = LocalToWorld(vector_origin, dir:Angle(), vector_origin, ang)

						dir = -dir:Forward() * len

						local water = bit_band(util_PointContents(woundPos), CONTENTS_WATER) == CONTENTS_WATER

						if water then
							hg.addBloodPart2(woundPos, VectorRand(-5, 5), nil, nil, nil, nil, true, nil, ent)
						else
							hg.addBloodPart(woundPos, VectorRand(-1, 1) * (org.pulse or 70) / 70 + dir * 5 * (math.abs(math.sin(CurTime() * 2) + math.cos(CurTime() * (5 + i * 2)) + math.sin(CurTime() * (1 + i))) * 0.6 + math.sin(CurTime() * 2) + 4) * 0.1 + dir:Angle():Right() * 25 * math.sin(CurTime() * 2) * math.cos(CurTime() * 4) + ang:Up() * 25 * math.sin(CurTime() * 3) * math.cos(CurTime() * 1) + VectorRand(-1, 1) * (org.pulse or 70) / 70, nil, size, size, true, nil, ent)
						end

						wound[5] = time + (water and 2 or (0.5 * 1 / hg_blood_fps:GetInt()))
					else
						local fallbackPos = ent:GetPos()

						local water = bit_band(util_PointContents(fallbackPos), CONTENTS_WATER) == CONTENTS_WATER

						if water then
							hg.addBloodPart2(fallbackPos, VectorRand(-5, 5), nil, nil, nil, nil, true, nil, ent)
						else
							hg.addBloodPart(fallbackPos, VectorRand(-15, 15), nil, size, size, true, nil, ent)
						end

						wound[5] = time + (water and 2 or 0)
					end
				end
			end
		end
	end
end)
