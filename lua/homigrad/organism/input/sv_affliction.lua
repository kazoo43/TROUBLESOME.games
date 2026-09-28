hg = hg or {}
hg.organism = hg.organism or {}
hg.organism.input_list = hg.organism.input_list or {}

local input_list = hg.organism.input_list
local math_random = math.random

local paintable = {
	[HITGROUP_STOMACH] = function(ply, ent)
		local snd = (ply.painCD and CurTime() < ply.painCD + 10) and "vo/npc/"..(ThatPlyIsFemale(ply) and "female" or "male").."01/pain0"..math_random(1,9)..".wav" or "vo/npc/"..(ThatPlyIsFemale(ply) and "female" or "male").."01/mygut02.wav"
		ent:EmitSound(snd, 75, ply.VoicePitch)
		ply.painCD = CurTime() + SoundDuration(snd)
		ply.lastPhr = snd
	end,
	[HITGROUP_CHEST] = function(ply, ent)
		local snd = "vo/npc/"..(ThatPlyIsFemale(ply) and "female" or "male").."01/pain0"..math_random(1,9)..".wav"
		ent:EmitSound(snd, 75, ply.VoicePitch)
		ply.painCD = CurTime() + SoundDuration(snd)
		ply.lastPhr = snd
	end,
	[HITGROUP_LEFTARM] = function(ply, ent)
		local snd = (ply.painCD and CurTime() < ply.painCD + 10) and "vo/npc/"..(ThatPlyIsFemale(ply) and "female" or "male").."01/pain0"..math_random(1,9)..".wav" or "vo/npc/"..(ThatPlyIsFemale(ply) and "female" or "male").."01/myarm0"..math_random(1,2)..".wav"
		ent:EmitSound(snd, 75, ply.VoicePitch)
		ply.painCD = CurTime() + SoundDuration(snd)
		ply.lastPhr = snd
	end,
	[HITGROUP_RIGHTARM] = function(ply, ent)
		local snd = (ply.painCD and CurTime() < ply.painCD + 10) and "vo/npc/"..(ThatPlyIsFemale(ply) and "female" or "male").."01/pain0"..math_random(1,9)..".wav" or "vo/npc/"..(ThatPlyIsFemale(ply) and "female" or "male").."01/myarm0"..math_random(1,2)..".wav"
		ent:EmitSound(snd, 75, ply.VoicePitch)
		ply.painCD = CurTime() + SoundDuration(snd)
		ply.lastPhr = snd
	end,
	[HITGROUP_RIGHTLEG] = function(ply, ent)
		local snd = (ply.painCD and CurTime() < ply.painCD + 10) and "vo/npc/"..(ThatPlyIsFemale(ply) and "female" or "male").."01/pain0"..math_random(1,9)..".wav" or "vo/npc/"..(ThatPlyIsFemale(ply) and "female" or "male").."01/myleg0"..math_random(1,2)..".wav"
		ent:EmitSound(snd, 75, ply.VoicePitch)
		ply.painCD = CurTime() + SoundDuration(snd)
		ply.lastPhr = snd
	end,
	[HITGROUP_LEFTLEG] = function(ply, ent)
		local snd = (ply.painCD and CurTime() < ply.painCD + 10) and "vo/npc/"..(ThatPlyIsFemale(ply) and "female" or "male").."01/pain0"..math_random(1,9)..".wav" or "vo/npc/"..(ThatPlyIsFemale(ply) and "female" or "male").."01/myleg0"..math_random(1,2)..".wav"
		ent:EmitSound(snd, 75, ply.VoicePitch)
		ply.painCD = CurTime() + SoundDuration(snd)
		ply.lastPhr = snd
	end,
}

hg.organism.paintable = paintable

function hg.organism.GasDamage(org, dmg, dmgInfo)
	input_list.lungsR(org, 1, dmg / 10, dmgInfo)
	input_list.lungsL(org, 1, dmg / 10, dmgInfo)
	input_list.trachea(org, 1, dmg / 10, dmgInfo)
end

function hg.organism.RadDamage(org, dmg, dmgInfo)
	hg.organism.GasDamage(org, dmg, dmgInfo)

	input_list.liver(org, nil, dmg / 20, dmgInfo)
	input_list.stomach(org, nil, dmg / 20, dmgInfo)
	input_list.intestines(org, nil, dmg / 20, dmgInfo)
end

function hg.organism.DamageTypeAffliction(dmg, dmgInfo, ply, org)
	local dmgBlood, dmgHurt, instaPain, immobilization = dmg, dmg, dmg, 0

	if dmgInfo:IsDamageType(DMG_VEHICLE + DMG_SHOCK) then
		dmgBlood = (math.random(15) == 1) and dmg / 4 or 0
		dmgHurt = dmg * 1
		instaPain = dmg * 1
	end

	if dmgInfo:IsDamageType(DMG_CRUSH + DMG_FALL) then
		dmgBlood = 0
		dmgHurt = 0
		instaPain = 0
	end

	if dmgInfo:IsDamageType(DMG_GENERIC+DMG_SHOCK+DMG_CRUSH) then
		if dmgInfo:GetInflictor():GetClass() == "trigger_hurt" then
			input_list.brain(org, 1, dmg / 50, dmgInfo)
		end
	end

	if dmgInfo:IsDamageType(DMG_GENERIC+DMG_CLUB) then
		dmgBlood = (math.random(15) == 1) and dmg / 4 or 0
		dmgHurt = dmg * 10
		instaPain = dmg * 6
		immobilization = dmg * 5
	end

	if dmgInfo:IsDamageType(DMG_BURN) then
		dmgBlood = 0
		dmgHurt = dmg * 3
		instaPain = dmg * 3
	end

	if dmgInfo:IsDamageType(DMG_BULLET) then
		dmgBlood = dmg * 8
		dmgHurt = dmg * 5
		instaPain = dmg * 5
		immobilization = dmg * 5
	end

	if dmgInfo:IsDamageType(DMG_SLASH) then
		dmgBlood = dmg * 12
		dmgHurt = dmg * 8
		instaPain = dmg * 9
		immobilization = dmg * 6
	end

	if dmgInfo:IsDamageType(DMG_BUCKSHOT) then
		dmgBlood = dmg * 3
		dmgHurt = dmg * 5
		instaPain = dmg * 3
		immobilization = dmg * 5
	end

	if dmgInfo:IsDamageType(DMG_BLAST) then
		dmgBlood = dmg * 5
		dmgHurt = dmg * 4
		instaPain = dmg * 3
	end

	if dmgInfo:IsDamageType(DMG_NERVEGAS) then
		if ply.armors.face == "mask2" or ply.PlayerClassName == "Combine" then
			dmgInfo:ScaleDamage(0)
			dmgBlood = 0
			dmgHurt = 0
			instaPain = 0
		else
			hg.organism.GasDamage(org, dmg, dmgInfo)
			dmgBlood = 0
			dmgHurt = dmg * 5
			instaPain = 0
		end
	end

	if dmgInfo:IsDamageType(DMG_ACID + DMG_POISON) then
		if !(ply.armors.face == "mask2" or ply.PlayerClassName == "Combine") then
			hg.organism.GasDamage(org, dmg, dmgInfo)
		end
		dmgBlood = dmg * 2
		dmgHurt = dmg * 5
		instaPain = dmg * 5
		immobilization = dmg * 5
	end

	if dmgInfo:IsDamageType(DMG_RADIATION) then
		dmg = dmg * 2
		hg.organism.RadDamage(org, dmg, dmgInfo)
	end

	return dmgBlood * 2, dmgHurt, instaPain / 20, immobilization
end
