hg = hg or {}
hg.organism = hg.organism or {}
hg.organism.list = hg.organism.list or {}

local hook_Run = hook.Run
local list = hg.organism.list

function hg.organism.Add(ent)
	local org = {
		owner = ent,
	}

	ent.organism = org
	list[ent] = org

	return org
end

function hg.organism.Clear(org)
	hook_Run("Org Clear", org)

	if IsValid(org.owner) then org.owner.fullsend = true end

	hg.send_organism(org)
end

function hg.organism.Remove(ent)
	local org = list[ent]

	if org then org.owner = nil end

	list[ent] = nil
end

hook.Add("PlayerInitialSpawn", "homigrad-organism", function(ply)
	hg.organism.Add(ply)
end)

hook.Add("Player Spawn", "homigrad-organism", function(ply)
	hg.organism.Clear(ply.organism)
end)

hook.Add("PlayerDisconnected", "homigrad-organism", function(ply)
	hg.organism.Remove(ply)
end)

hook.Add("PostPlayerDeath", "homigrad-organism", function(ply)
	local ragdoll = ply:GetNWEntity("RagdollDeath")

	if !IsValid(ragdoll) then ragdoll = ply.FakeRagdoll end

	if IsValid(ragdoll) then
		local newOrg = hg.organism.Add(ragdoll)
		table.Merge(newOrg, ply.organism)

		hook_Run("RagdollDeath", ply, ragdoll)

		table.Merge(zb.net.list[ragdoll], zb.net.list[ply])

		newOrg.alive = false
		newOrg.owner = ragdoll
		ragdoll:CallOnRemove("organism", hg.organism.Remove, ragdoll)
		newOrg.owner.fullsend = true
		hg.send_bareinfo(newOrg)
	end

	hg.organism.Clear(ply.organism)

	hook_Run("PostPostPlayerDeath", ply, ragdoll)
end)

hook.Add("Fake", "organism", function(ply, ragdoll)
	ragdoll.organism = ply.organism
end)
