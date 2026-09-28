local CurTime = CurTime
local RunConsoleCommand = RunConsoleCommand

local function canFixLimb()
	if !lply:Alive() or !lply.organism or lply.organism.otrub then return end
	if (lply.tried_fixing_limb or 0) > CurTime() then return end
	if lply.organism.pain > 60 then return end
end

local function addOption(fn, text)
	hg.radialOptions[#hg.radialOptions + 1] = {fn, text}
end

hook.Add("radialOptions", "DislocatedJoint", function()
	canFixLimb()

	local org = lply.organism

	if org.llegdislocation or org.rlegdislocation then
		addOption(function()
			lply.tried_fixing_limb = CurTime() + 0.5
			RunConsoleCommand("hg_fixdislocation", 1, 0)
		end, "Fix dislocation (leg)")
	else
		local ent = hg.eyeTrace(lply).Entity

		if ent.organism and (ent.organism.llegdislocation or ent.organism.rlegdislocation) then
			addOption(function()
				lply.tried_fixing_limb = CurTime() + 0.5
				RunConsoleCommand("hg_fixdislocation", 1, 1)
			end, "Fix "..ent:GetPlayerName().."'s dislocation (leg)")
		end
	end
end)

hook.Add("radialOptions", "DislocatedJoint2", function()
	canFixLimb()

	local org = lply.organism

	if org.larmdislocation or org.rarmdislocation then
		addOption(function()
			lply.tried_fixing_limb = CurTime() + 0.5
			RunConsoleCommand("hg_fixdislocation", 2, 0)
		end, "Fix dislocation (arm)")
	else
		local ent = hg.eyeTrace(lply).Entity

		if ent.organism and (ent.organism.larmdislocation or ent.organism.rarmdislocation) then
			addOption(function()
				lply.tried_fixing_limb = CurTime() + 0.5
				RunConsoleCommand("hg_fixdislocation", 2, 1)
			end, "Fix "..ent:GetPlayerName().."'s dislocation (arm)")
		end
	end
end)

hook.Add("radialOptions", "DislocatedJaw", function()
	canFixLimb()

	local org = lply.organism

	if org.jawdislocation then
		addOption(function()
			lply.tried_fixing_limb = CurTime() + 0.5
			RunConsoleCommand("hg_fixdislocation", 3, 0)
		end, "Fix dislocation (jaw)")
	else
		local ent = hg.eyeTrace(lply).Entity

		if ent.organism and ent.organism.jawdislocation then
			addOption(function()
				lply.tried_fixing_limb = CurTime() + 0.5
				RunConsoleCommand("hg_fixdislocation", 3, 1)
			end, "Fix "..ent:GetPlayerName().."'s dislocation (jaw)")
		end
	end
end)
