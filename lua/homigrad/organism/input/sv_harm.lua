hg = hg or {}

local hg_developer = ConVarExists("hg_developer") and GetConVar("hg_developer") or CreateConVar("hg_developer", 0, FCVAR_SERVER_CAN_EXECUTE, "Toggle developer mode (enables damage traces)", 0, 1)

function hg.AddHarmToAttacker(dmgInfo, harm, reason)
	local ply = dmgInfo:GetAttacker()

	if IsValid(ply) and ply:IsPlayer() then
		hg.AddHarm(ply, harm, reason)
	end
end

function hg.AddHarm(ply, harm, reason)
	ply.harm = ply.harm + harm
end
