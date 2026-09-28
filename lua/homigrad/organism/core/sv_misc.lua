hg = hg or {}

local hg_norespawn = ConVarExists("hg_norespawn") and GetConVar("hg_norespawn") or CreateConVar("hg_norespawn", 0, FCVAR_SERVER_CAN_EXECUTE, "Disable respawns in any gamemode (useful for hg_sync)", 0, 1)

hook.Add("PlayerDeathThink", "stoprespawning", function()
	if hg_norespawn:GetBool() then return true end
end)

hook.Add("StartCommand", "hg-otrub-movement", function(ply, cmd)
	if ply.organism.otrub and ply:Alive() then
		cmd:ClearMovement()
	end
end)

hook.Add("PlayerDeath", "next-respawn-full", function(ply)
	ply.fullsend = true
end)

hook.Add("OnEntityWaterLevelChanged", "ClearBlood", function(ent, old, new)
	if new >= 2 then
		if ent:IsOnFire() then ent:Extinguish() end
		ent:RemoveAllDecals()
	end
end)
