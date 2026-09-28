hg.organism_ents = hg.organism_ents or {}

local table_Merge = table.Merge
local IsValid = IsValid
local LocalPlayer = LocalPlayer
local hook_Run = hook.Run

net.Receive("organism_send", function()
	local org = net.ReadTable()
	local force = net.ReadBool()
	local spectatov_ne_trogaem = net.ReadBool()
	local moreinfopls = net.ReadBool()
	local add = net.ReadBool()
	local ply = org.owner

	if ply:IsNPC() then
		hg.organism_ents[ply] = true
	end

	if add and org.owner.organism and org.owner.new_organism then
		hook_Run("HG_OrganismChanged", org.owner.organism, org)

		table_Merge(org.owner.organism, org, true)
		table_Merge(org.owner.new_organism, org, true)

		return
	end

	if ply.is_lookedat and !moreinfopls then return end
	if !IsValid(ply) then return end
	if spectatov_ne_trogaem and (ply == LocalPlayer():GetNWEntity("spect", nil)) and !LocalPlayer():Alive() then return end

	local old_org = table.Copy(ply.organism)

	ply.organism = old_org
	ply.new_organism = org

	if !ply.organism or force then
		ply.organism = org
	end

	if ply:IsPlayer() and ply:Alive() then
		org.health = ply:Health()
	end

	local rag = ply:GetNWEntity("FakeRagdoll")

	if IsValid(rag) then
		rag.organism = old_org
		rag.new_organism = org
	end
end)

hook.Add("Player_Death", "removeorg", function(ply)
	ply.organism = nil
	ply.new_organism = nil

	if IsValid(ply.FakeRagdoll) then
		ply.FakeRagdoll.organism = nil
		ply.FakeRagdoll.new_organism = nil
	end
end)
