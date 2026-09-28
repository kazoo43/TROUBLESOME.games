hg = hg or {}

local CurTime = CurTime
local IsValid = IsValid
local math_rand = math.rand
local math_sin = math.sin
local math_clamp = math.Clamp
local VectorRand = VectorRand

local fencingArmBones = {
	{"ValveBiped.Bip01_R_Hand", "ValveBiped.Bip01_R_UpperArm", 1.0},
	{"ValveBiped.Bip01_L_Hand", "ValveBiped.Bip01_L_UpperArm", 1.0},
	{"ValveBiped.Bip01_R_Forearm", "ValveBiped.Bip01_Spine2", 0.8},
	{"ValveBiped.Bip01_L_Forearm", "ValveBiped.Bip01_Spine2", 0.8},
	{"ValveBiped.Bip01_R_UpperArm", "ValveBiped.Bip01_Spine2", 0.5},
	{"ValveBiped.Bip01_L_UpperArm", "ValveBiped.Bip01_Spine2", 0.5},
}

local fencingLegBones = {
	{"ValveBiped.Bip01_R_Foot", "ValveBiped.Bip01_R_Thigh", 0.6},
	{"ValveBiped.Bip01_R_Calf", "ValveBiped.Bip01_R_Thigh", 0.4},
}

local function applyFencingToPlayer(ply, org)
	if !IsValid(ply) or !ply:Alive() then return end
	if org.fencing then return end

	local dur = math_rand(3, 8)

	org.fencing = true
	org.fencingEnd = CurTime() + dur
	org.fencingDur = dur

	if ply.FakeRagdoll and IsValid(ply.FakeRagdoll) then
		local rag = ply.FakeRagdoll

		rag.fencing = true
		rag.fencingEnd = org.fencingEnd
		rag.fencingDur = dur
	end
end

hg.applyFencingToPlayer = applyFencingToPlayer

local function applyForcePair(rag, bones, fade, vibration)
	local force = 350 * fade
	local pulse = 0.85 + math_sin(CurTime() * 4) * 0.15

	for i = 1, #bones do
		local d = bones[i]
		local bone, targetBone = rag:LookupBone(d[1]), rag:LookupBone(d[2])

		if !bone or !targetBone then continue end

		local phys = rag:GetPhysicsObjectNum(rag:TranslateBoneToPhysBone(bone))

		if !IsValid(phys) then continue end

		local bonePos, targetPos = rag:GetBonePosition(bone), rag:GetBonePosition(targetBone)
		local dir = (targetPos - bonePos):GetNormalized()

		phys:ApplyForceCenter((dir * force * d[3] * pulse) + VectorRand(-vibration, vibration) * fade)
	end
end

local function processFencing(rag, fade)
	applyForcePair(rag, fencingArmBones, fade, 15)
	applyForcePair(rag, fencingLegBones, fade, 10)
end

local function clearFencing(rag)
	rag.fencing = nil
	rag.fencingEnd = nil
	rag.fencingDur = nil
end

hg.organism.module = hg.organism.module or {}
hg.organism.module.brainfuck = hg.organism.module.brainfuck or {}
local module = hg.organism.module.brainfuck
module.fencing = module.fencing or {}

local fencing = module.fencing

fencing.clear = clearFencing
fencing.applyTo = applyFencingToPlayer

fencing.get = function(org, rag)
	if CurTime() > org.fencingEnd then
		clearFencing(rag)

		org.fencing = nil
		org.fencingEnd = nil
		org.fencingDur = nil

		return
	end

	local fade = math_clamp((org.fencingEnd - CurTime()) / (org.fencingDur or 5), 0.1, 1)

	processFencing(rag, fade)
end
