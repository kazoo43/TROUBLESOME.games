hg.organism.module = hg.organism.module or {}
hg.organism.module.posturing = hg.organism.module.posturing or {}
local module = hg.organism.module.posturing

local IsValid = IsValid

module[2] = function(owner, org, timeValue)
	if !org.posturing then return end

	local ent = hg.GetCurrentCharacter(owner)

	local rleg = ent:GetPhysicsObjectNum(ent:TranslateBoneToPhysBone(ent:LookupBone("ValveBiped.Bip01_R_Foot")))
	local lleg = ent:GetPhysicsObjectNum(ent:TranslateBoneToPhysBone(ent:LookupBone("ValveBiped.Bip01_L_Foot")))
	local rarm = ent:GetPhysicsObjectNum(ent:TranslateBoneToPhysBone(ent:LookupBone("ValveBiped.Bip01_R_Hand")))
	local larm = ent:GetPhysicsObjectNum(ent:TranslateBoneToPhysBone(ent:LookupBone("ValveBiped.Bip01_L_Hand")))

	local down = -ent:GetBoneMatrix(ent:LookupBone("ValveBiped.Bip01_Spine")):GetAngles():Forward()

	if IsValid(rleg) and IsValid(rarm) and IsValid(larm) and IsValid(lleg) then
		rleg:ApplyForceCenter(down * 500)
		lleg:ApplyForceCenter(down * 500)
		rarm:ApplyForceCenter(down * 500)
		larm:ApplyForceCenter(down * 500)
	end
end
