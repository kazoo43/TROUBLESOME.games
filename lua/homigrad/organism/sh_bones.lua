hg.organism = hg.organism or {}

hg.bonetohitgroup = {
	["ValveBiped.Bip01_Head1"] = HITGROUP_HEAD,
	["ValveBiped.Bip01_L_UpperArm"] = HITGROUP_LEFTARM,
	["ValveBiped.Bip01_L_Forearm"] = HITGROUP_LEFTARM,
	["ValveBiped.Bip01_L_Hand"] = HITGROUP_LEFTARM,
	["ValveBiped.Bip01_R_UpperArm"] = HITGROUP_RIGHTARM,
	["ValveBiped.Bip01_R_Forearm"] = HITGROUP_RIGHTARM,
	["ValveBiped.Bip01_R_Hand"] = HITGROUP_RIGHTARM,
	["ValveBiped.Bip01_Pelvis"] = HITGROUP_CHEST,
	["ValveBiped.Bip01_Spine2"] = HITGROUP_CHEST,
	["ValveBiped.Bip01_Spine1"] = HITGROUP_STOMACH,
	["ValveBiped.Bip01_Spine4"] = HITGROUP_CHEST,
	["ValveBiped.Bip01_Spine"] = HITGROUP_STOMACH,
	["ValveBiped.Bip01_L_Thigh"] = HITGROUP_LEFTLEG,
	["ValveBiped.Bip01_L_Calf"] = HITGROUP_LEFTLEG,
	["ValveBiped.Bip01_L_Foot"] = HITGROUP_LEFTLEG,
	["ValveBiped.Bip01_R_Thigh"] = HITGROUP_RIGHTLEG,
	["ValveBiped.Bip01_R_Calf"] = HITGROUP_RIGHTLEG,
	["ValveBiped.Bip01_R_Foot"] = HITGROUP_RIGHTLEG,
}

hg.amputeetable = {
	["ValveBiped.Bip01_L_Forearm"] = "larm",
	["ValveBiped.Bip01_L_Hand"] = "larm",
	["ValveBiped.Bip01_R_Forearm"] = "rarm",
	["ValveBiped.Bip01_R_Hand"] = "rarm",
	["ValveBiped.Bip01_L_Calf"] = "lleg",
	["ValveBiped.Bip01_L_Foot"] = "lleg",
	["ValveBiped.Bip01_R_Calf"] = "rleg",
	["ValveBiped.Bip01_R_Foot"] = "rleg",
}

hg.amputatedlimbs = {
	["lleg"] = "ValveBiped.Bip01_L_Calf",
	["rleg"] = "ValveBiped.Bip01_R_Calf",
	["larm"] = "ValveBiped.Bip01_L_Forearm",
	["rarm"] = "ValveBiped.Bip01_R_Forearm",
	["head"] = "ValveBiped.Bip01_Head1",
}

hg.amputatedlimbs2 = {}
for k, v in pairs(hg.amputatedlimbs) do
	hg.amputatedlimbs2[v] = k
end

hg.organism.hitgrouptolimb = {
	[HITGROUP_LEFTLEG] = "lleg",
	[HITGROUP_RIGHTLEG] = "rleg",
	[HITGROUP_LEFTARM] = "larm",
	[HITGROUP_RIGHTARM] = "rarm",
}

hg.organism.hitgrouptobone = {}
for bon, hitgroup in pairs(hg.bonetohitgroup) do
	local group = hg.organism.hitgrouptobone[hitgroup]

	if !group then
		group = {}
		hg.organism.hitgrouptobone[hitgroup] = group
	end

	group[#group + 1] = bon
end

hg.organism.RagdollDamageBoneMul = {
	[HITGROUP_LEFTLEG] = 0.25,
	[HITGROUP_RIGHTLEG] = 0.25,
	[HITGROUP_GENERIC] = 1,
	[HITGROUP_LEFTARM] = 0.25,
	[HITGROUP_RIGHTARM] = 0.25,
	[HITGROUP_CHEST] = 1,
	[HITGROUP_STOMACH] = 1,
	[HITGROUP_HEAD] = 2,
}

hg.organism.RagdollForceBoneMul = {
	[HITGROUP_LEFTLEG] = 0.5,
	[HITGROUP_RIGHTLEG] = 0.5,
	[HITGROUP_GENERIC] = 1,
	[HITGROUP_LEFTARM] = 0.5,
	[HITGROUP_RIGHTARM] = 0.5,
	[HITGROUP_CHEST] = 1,
	[HITGROUP_STOMACH] = 1,
	[HITGROUP_HEAD] = 0.5,
}

hg.organism.pulsebones = {
	["ValveBiped.Bip01_Head1"] = true,
	["ValveBiped.Bip01_R_Hand"] = true,
	["ValveBiped.Bip01_L_Hand"] = true,
}
