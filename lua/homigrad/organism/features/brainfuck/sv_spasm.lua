hg = hg or {}

local CurTime = CurTime
local IsValid = IsValid
local math_random = math.random
local math_rand = math.Rand
local math_sin = math.sin
local math_clamp = math.Clamp
local VectorRand = VectorRand

hg.organism.module = hg.organism.module or {}
hg.organism.module.brainfuck = hg.organism.module.brainfuck or {}
local module = hg.organism.module.brainfuck
module.spasm = module.spasm or {}

local FORCE, VIBRATION = 1200, 150
local extendDur, rigorDur, flexionDur = {4, 10}, {10, 20}, {6, 12}

local spasmTypes = {
	[1] = {35, "extend"},
	[2] = {25, "rigor"},
	[3] = {15, "flexion"},
}

local extendBones = {
	["ValveBiped.Bip01_R_Hand"] = true,
	["ValveBiped.Bip01_L_Hand"] = true,
	["ValveBiped.Bip01_R_Foot"] = true,
	["ValveBiped.Bip01_L_Foot"] = true,
	["ValveBiped.Bip01_R_Forearm"] = true,
	["ValveBiped.Bip01_L_Forearm"] = true,
	["ValveBiped.Bip01_R_Calf"] = true,
	["ValveBiped.Bip01_L_Calf"] = true,
	["ValveBiped.Bip01_R_UpperArm"] = true,
	["ValveBiped.Bip01_L_UpperArm"] = true,
	["ValveBiped.Bip01_R_Thigh"] = true,
	["ValveBiped.Bip01_L_Thigh"] = true,
}

local flexionBones = {
	{"ValveBiped.Bip01_R_Hand", "ValveBiped.Bip01_Spine2", 1.2},
	{"ValveBiped.Bip01_L_Hand", "ValveBiped.Bip01_Spine2", 1.2},
	{"ValveBiped.Bip01_R_Forearm", "ValveBiped.Bip01_Spine2", 1.0},
	{"ValveBiped.Bip01_L_Forearm", "ValveBiped.Bip01_Spine2", 1.0},
	{"ValveBiped.Bip01_Head1", "ValveBiped.Bip01_Spine2", 0.6},
}

local rigorBones = {
	"ValveBiped.Bip01_R_Hand", "ValveBiped.Bip01_L_Hand",
	"ValveBiped.Bip01_R_Foot", "ValveBiped.Bip01_L_Foot",
	"ValveBiped.Bip01_R_Forearm", "ValveBiped.Bip01_L_Forearm",
	"ValveBiped.Bip01_R_Calf", "ValveBiped.Bip01_L_Calf",
	"ValveBiped.Bip01_R_UpperArm", "ValveBiped.Bip01_L_UpperArm",
	"ValveBiped.Bip01_R_Thigh", "ValveBiped.Bip01_L_Thigh",
	"ValveBiped.Bip01_Head1", "ValveBiped.Bip01_Spine", "ValveBiped.Bip01_Spine1", "ValveBiped.Bip01_Spine2",
}

local function getRandomSpasm()
	local _, stype = hg.WeightedRandomSelect(spasmTypes, 1)

	return stype
end

hg.getRandomSpasm = getRandomSpasm

local function applySpasm(rag, stype)
	if !IsValid(rag) then return end

	local dur = stype == "extend" and extendDur or stype == "rigor" and rigorDur or flexionDur

	dur = math_random(dur[1], dur[2])

	rag.spasm = true
	rag.spasmType = stype
	rag.spasmDur = dur
	rag.spasmForce = FORCE
	rag.spasmEnd = CurTime() + dur
	rag.spasmStart = CurTime()

	if stype == "rigor" then
		rag.rigorActive = true
	end
end

hg.applySpasm = applySpasm

local function processExtend(rag, fade)
	local force, pulse = rag.spasmForce or FORCE, 0.7 + math_sin(CurTime() * 8) * 0.3
	local pelvis = rag:LookupBone("ValveBiped.Bip01_Pelvis")

	if !pelvis then return end

	local pelvisPos = rag:GetBonePosition(pelvis)

	for name in pairs(extendBones) do
		local bone = rag:LookupBone(name)

		if !bone then continue end

		local phys = rag:GetPhysicsObjectNum(rag:TranslateBoneToPhysBone(bone))

		if !IsValid(phys) then continue end

		local dir = (rag:GetBonePosition(bone) - pelvisPos):GetNormalized()

		phys:ApplyForceCenter((dir * force * fade * pulse) + VectorRand(-VIBRATION, VIBRATION) * fade)
	end
end

local function processRigor(rag, fade)
	if !rag.rigorActive then return end

	for i = 1, #rigorBones do
		local bone = rag:LookupBone(rigorBones[i])

		if !bone then continue end

		local phys = rag:GetPhysicsObjectNum(rag:TranslateBoneToPhysBone(bone))

		if !IsValid(phys) then continue end

		if fade > 0.3 then phys:ApplyForceCenter(VectorRand(-45, 45) * fade) end
	end
end

local function processFlexion(rag, fade)
	local force, pulse = 400, 0.8 + math_sin(CurTime() * 5) * 0.2

	for i = 1, #flexionBones do
		local d = flexionBones[i]
		local bone, targetBone = rag:LookupBone(d[1]), rag:LookupBone(d[2])

		if !bone or !targetBone then continue end

		local phys = rag:GetPhysicsObjectNum(rag:TranslateBoneToPhysBone(bone))

		if !IsValid(phys) then continue end

		local dir = (rag:GetBonePosition(targetBone) - rag:GetBonePosition(bone)):GetNormalized()

		phys:ApplyForceCenter((dir * force * d[3] * fade * pulse) + VectorRand(-30, 30) * fade)
	end
end

local function clearSpasm(rag)
	if rag.spasmType == "rigor" and rag.rigorActive then
		for i = 1, #rigorBones do
			local bone = rag:LookupBone(rigorBones[i])

			if !bone then continue end

			local phys = rag:GetPhysicsObjectNum(rag:TranslateBoneToPhysBone(bone))

			if IsValid(phys) then phys:SetDamping(0.5, 1) end
		end
	end

	rag.spasm = nil
	rag.spasmEnd = nil
	rag.spasmStart = nil
	rag.spasmDur = nil
	rag.spasmForce = nil
	rag.spasmType = nil
	rag.rigorActive = nil
end

local spasm = module.spasm

spasm.clear = clearSpasm

spasm.get = function(rag)	if !IsValid(rag) or !rag.spasm or !rag.spasmEnd then return end
	if CurTime() > rag.spasmEnd then
		clearSpasm(rag)
		return
	end

	local fade = math_clamp((rag.spasmEnd - CurTime()) / (rag.spasmDur or 5), 0.1, 1)
	local stype = rag.spasmType or "extend"

	if stype == "extend" then
		processExtend(rag, fade)
	elseif stype == "rigor" then
		processRigor(rag, fade)
	elseif stype == "flexion" then
		processFlexion(rag, fade)
	end
end
