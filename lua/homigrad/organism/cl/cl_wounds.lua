local IsValid = IsValid
local table_Merge = table.Merge

hook.Add("OnNetVarSet", "wounds_netvar", function(index, key, var)
	if key ~= "wounds" then return end

	local ent = Entity(index)

	if !IsValid(ent) then return end

	if ent.wounds then
		for i = 1, #ent.wounds do
			if !var or !var[i] then continue end
			var[i][5] = ent.wounds[i][5]
		end
	end

	ent.wounds = var

	local rag = IsValid(ent:GetNWEntity("FakeRagdoll")) and ent:GetNWEntity("FakeRagdoll")

	if IsValid(rag) then
		rag.wounds = rag:GetNetVar("wounds") or var
	end
end)

hook.Add("OnNetVarSet", "wounds_netvar2", function(index, key, var)
	if key ~= "arterialwounds" then return end

	local ent = Entity(index)

	if !IsValid(ent) then return end

	if ent.arterialwounds then
		for i = 1, #ent.arterialwounds do
			if !var[i] then continue end
			var[i][5] = ent.arterialwounds[i][5]
		end
	end

	ent.arterialwounds = var

	local rag = IsValid(ent:GetNWEntity("FakeRagdoll")) and ent:GetNWEntity("FakeRagdoll")

	if IsValid(rag) then
		rag.arterialwounds = rag:GetNetVar("arterialwounds") or var
	end
end)

hook.Add("Player Spawn", "removewounds", function(ply)
	if OverrideSpawn then return end

	ply.wounds = {}
	ply.arterialwounds = {}
end)

hook.Add("Fake", "huyhuyhuy235", function(ply, ragdoll)
	if !IsValid(ragdoll) then return end

	ragdoll.wounds = ply.wounds
	ragdoll.arterialwounds = ply.arterialwounds
end)
