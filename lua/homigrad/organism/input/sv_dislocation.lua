hg = hg or {}
hg.organism = hg.organism or {}

local CurTime = CurTime
local Color = Color
local input_list = hg.organism.input_list

local unlucky_dislocations = {
	"Why can't I fix this goddamn dislocation...",
	"Please... why is it so hard.",
	"Just go back in place already...",
	"This is irritating",
	"I should try again",
}

local finally_fixed = {
	"Finally.",
	"That was harder than I thought",
	"One dislocation away.",
}

local function fixlimb(org, key, fixer)
	if math.random(100) > (97 + (fixer != org.owner and (fixer.organism and fixer.organism.pain or 0) or 0) - (org.analgesia * 50 + org.painkiller * 15) - (fixer != org.owner and 30 or 0) - (fixer.tries or 0) * 10 - (fixer.Profession == "doctor" and 100 or 0) - (org.owner == fixer and (IsValid(org.owner.FakeRagdoll) or (org.owner.Crouching and org.owner:Crouching())) and 10 or 0)) then
		org[key.."dislocation"] = false
		org.painadd = org.painadd + 5 * math.random(1, 3)
		org.fearadd = org.fearadd + 0.1

		org.owner:EmitSound("physics/flesh/flesh_impact_hard6.wav", 65)

		if fixer == org.owner and (fixer.tries or 0) > 3 and math.random(3) == 1 then
			fixer:Notify(finally_fixed[math.random(#finally_fixed)], 1, "dislocations_unlucky", 1, nil, Color(255, 255, 255, 255))
		end

		fixer.tries = 0
	else
		fixer.tries = (fixer.tries or 0) + 1
		org.painadd = org.painadd + 15 * math.random(1, 3)

		org.fearadd = org.fearadd + 0.3

		org.owner:EmitSound("physics/body/body_medium_impact_soft"..math.random(7)..".wav", 65)

		if fixer.Profession != "doctor" and math.random(5) == 1 then
			local dmgInfo = DamageInfo()
			dmgInfo:SetDamage(50)
			dmgInfo:SetDamageType(DMG_CLUB)
			input_list[key.."down"](org.owner.organism, 1, 6, dmgInfo, 0, vector_up)
		end

		if fixer == org.owner and fixer.tries > 3 and math.random(3) == 1 then
			fixer:Notify(unlucky_dislocations[math.random(#unlucky_dislocations)], 1, "dislocations_unlucky", 1, nil, Color(255, 255, 255, 255))
		end
	end
end

concommand.Add("hg_fixdislocation", function(ply, cmd, args)
	local fixer = ply

	if args and args[2] and math.Round(tonumber(args[2])) == 1 then
		ply = hg.eyeTrace(fixer).Entity
	end

	if !IsValid(ply) or !ply.organism then return end

	ply = ply.organism.owner

	local org = ply.organism

	if !fixer:Alive() or !org or fixer.organism.otrub then return end
	if (fixer.tried_fixing_limb or 0) > CurTime() then return end
	if !fixer.organism.canmove or !fixer.organism.canmovehead or fixer.organism.pain > 60 then return end

	fixer.tried_fixing_limb = CurTime() + fixer.organism.pain / 30

	if math.Round(tonumber(args[1])) == 1 then
		if org.llegdislocation then
			fixlimb(org, "lleg", fixer)
		elseif org.rlegdislocation then
			fixlimb(org, "rleg", fixer)
		end
	elseif math.Round(tonumber(args[1])) == 2 then
		if org.larmdislocation then
			fixlimb(org, "larm", fixer)
		elseif org.rarmdislocation then
			fixlimb(org, "rarm", fixer)
		end
	elseif math.Round(tonumber(args[1])) == 3 then
		if org.jawdislocation then
			fixlimb(org, "jaw", fixer)
		end
	end
end)
