hg = hg or {}

local istable = istable
local unpack = unpack

local npcDmg = {
	npc_combine_s = {
		["ValveBiped.Bip01_Head1"] = 0.5,
		["ValveBiped.Bip01_L_UpperArm"] = 0.5,
		["ValveBiped.Bip01_L_Forearm"] = 0.5,
		["ValveBiped.Bip01_L_Hand"] = 1,
		["ValveBiped.Bip01_R_UpperArm"] = 0.5,
		["ValveBiped.Bip01_R_Forearm"] = 0.5,
		["ValveBiped.Bip01_R_Hand"] = 1,
		["ValveBiped.Bip01_Pelvis"] = {0.1,{"MetalSpark"}},
		["ValveBiped.Bip01_Spine2"] = {0.1,{"MetalSpark"}},
		["ValveBiped.Bip01_L_Thigh"] = 0.5,
		["ValveBiped.Bip01_L_Calf"] = 1,
		["ValveBiped.Bip01_L_Foot"] = 1,
		["ValveBiped.Bip01_R_Thigh"] = 0.5,
		["ValveBiped.Bip01_R_Calf"] = 1,
		["ValveBiped.Bip01_R_Foot"] = 1,
	},
	npc_hunter = 1,
	npc_metropolice = {
		["ValveBiped.Bip01_Head1"] = 1,
		["ValveBiped.Bip01_L_UpperArm"] = 1,
		["ValveBiped.Bip01_L_Forearm"] = 1,
		["ValveBiped.Bip01_L_Hand"] = 1,
		["ValveBiped.Bip01_R_UpperArm"] = 1,
		["ValveBiped.Bip01_R_Forearm"] = 1,
		["ValveBiped.Bip01_R_Hand"] = 1,
		["ValveBiped.Bip01_Pelvis"] = {0.25,{"Impact",77}},
		["ValveBiped.Bip01_Spine2"] = {0.25,{"Impact",77}},
		["ValveBiped.Bip01_L_Thigh"] = 1,
		["ValveBiped.Bip01_L_Calf"] = 1,
		["ValveBiped.Bip01_L_Foot"] = 1,
		["ValveBiped.Bip01_R_Thigh"] = 1,
		["ValveBiped.Bip01_R_Calf"] = 1,
		["ValveBiped.Bip01_R_Foot"] = 1,
	},
	npc_zombie = 1,
	npc_zombie_torso = 1,
	npc_zombine = 1,
	npc_poisonzombie = 1,
	npc_fastzombie = 1,
}

function hg.NPCDamage(ent, dmgInfo, npcdmg)
	local tr = hg.GetTraceDamage(ent, dmgInfo:GetDamagePosition(), dmgInfo:GetDamageForce())
	local bone = ent:GetBoneName(ent:TranslatePhysBoneToBone(tr.PhysicsBone))

	if istable(npcdmg) then
		if npcdmg[bone] then
			local val = istable(npcdmg[bone]) and npcdmg[bone][1] or npcdmg[bone]

			dmgInfo:ScaleDamage(val)

			if istable(npcdmg[bone]) and npcdmg[bone][2] then
				hg.ArmorEffectEx(ent, dmgInfo, unpack(npcdmg[bone][2]))
			end
		end
	else
		dmgInfo:ScaleDamage(npcdmg)
	end
end

hg.organism.npcDmg = npcDmg
