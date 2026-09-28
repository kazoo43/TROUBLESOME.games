local grub = Model("models/grub_nugget_small.mdl")
local vecalmostzero = Vector(0.01, 0.01, 0.01)
local vecFull = Vector(1, 1, 1)
local LocalToWorld = LocalToWorld
local IsValid = IsValid

local modelPlacements = {
	[1] = {
		["ValveBiped.Bip01_L_Calf"] = {Vector(15.5, 0, 0), Angle(0, 90, 0)},
		["ValveBiped.Bip01_R_Calf"] = {Vector(15.5, 0, 0), Angle(0, 90, 0)},
		["ValveBiped.Bip01_R_Forearm"] = {Vector(11, 0.5, 0.5), Angle(0, 90, 0)},
		["ValveBiped.Bip01_L_Forearm"] = {Vector(11, 0.5, -0.5), Angle(0, 90, 0)},
	},
	[0] = {
		["ValveBiped.Bip01_L_Calf"] = {Vector(17.5, 0, 0), Angle(0, 90, 0)},
		["ValveBiped.Bip01_R_Calf"] = {Vector(17.5, 0, 0), Angle(0, 90, 0)},
		["ValveBiped.Bip01_R_Forearm"] = {Vector(11, 0.5, 0.5), Angle(0, 90, 0)},
		["ValveBiped.Bip01_L_Forearm"] = {Vector(11, 0, -1), Angle(0, 90, 0)},
	},
}


function hg.GoreCalc(ent, ply)
	local org = ent.new_organism or ent.organism

	if !org then return end

	for bone, nam in pairs(hg.amputatedlimbs) do
		if !org[bone.."amputated"] then
			local bon = ent:LookupBone(nam)

			if !ent:GetManipulateBoneScale(bon):IsEqualTol(vecFull, 0.01) then
				ent:ManipulateBoneScale(bon, vecFull)
			end

			continue
		end

		local bon = ent:LookupBone(nam)
		local mat = ent:GetBoneMatrix(bon)
		local mat2 = ent:GetBoneMatrix(bon - 1)

		mat:SetScale(vecalmostzero)

		hg.bone_apply_matrix(ent, bon, mat)

		if IsValid(ply.OldFakeRagdoll) then
			hg.bone_apply_matrix(ply, bon, mat)
		end

		local fem = ThatPlyIsFemale(ent) and 1 or 0

		if !modelPlacements[fem][nam] then continue end

		local pos, ang = LocalToWorld(modelPlacements[fem][nam][1], modelPlacements[fem][nam][2], mat2:GetTranslation(), mat2:GetAngles())

		if !IsValid(headboom_mdl) then
			headboom_mdl = ClientsideModel(grub)
			headboom_mdl:SetNoDraw(true)
			headboom_mdl:SetSubMaterial(0, "models/flesh")
			headboom_mdl:SetModelScale(0.8)
		end

		headboom_mdl:SetRenderOrigin(pos)
		headboom_mdl:SetRenderAngles(ang)
		headboom_mdl:SetupBones()
		headboom_mdl:DrawModel()
	end
end
