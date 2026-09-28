hg = hg or {}
hg.organism = hg.organism or {}
hg.organism.input_list = hg.organism.input_list or {}

local CurTime = CurTime
local IsValid = IsValid
local math_random = math.random
local math_Rand = math.Rand
local ents_Create = ents.Create
local hook_Run = hook.Run
local input_list = hg.organism.input_list
local limbs = hg.amputatedlimbs

local sounds = {
	Sound("player/zombie_head_explode_01.wav"),
	Sound("player/zombie_head_explode_02.wav"),
	Sound("player/zombie_head_explode_03.wav"),
	Sound("player/zombie_head_explode_04.wav"),
	Sound("player/zombie_head_explode_05.wav"),
	Sound("player/zombie_head_explode_06.wav"),
}

function hg.organism.AmputateLimb(org, limb)
	if org[limb.."amputated"] == nil then return end

	local bone = limbs[limb]

	if !IsValid(org.owner) then return end

	local len = org.owner:BoneLength(org.owner:LookupBone(bone))
	local vec = Vector(len, 0, 0)
	local ang = Angle()
	local boneup = org.owner:GetBoneName(org.owner:LookupBone(bone) - 1)

	local wnds = {}

	for i, tbl in pairs(org.arterialwounds) do
		if tbl[7] != limb.."artery" then
			table.insert(wnds, tbl)
		end
	end

	table.insert(wnds, {10, vec, ang, boneup, CurTime(), Vector(-100, 0, 0), bone.."artery"})

	org.arterialwounds = wnds
	org.owner:SetNetVar("arterialwounds", wnds)

	org[limb.."amputated"] = true

	for i = 1, 5 do
		hg.organism.AddWoundManual(org.owner, 50, vec + VectorRand(-2, 2), ang, boneup, CurTime() + math_Rand(0, 2))
	end

	local dmgInfo = DamageInfo()
	input_list[limb.."up"](org, 0, 5, dmgInfo)

	org.owner:EmitSound(sounds[math_random(#sounds)], 70, math_random(95, 105), 2)

	local ent = hg.GetCurrentCharacter(org.owner)
	SpawnMeatGore(ent, select(1, ent:GetBonePosition(ent:LookupBone(bone))), 4)

	hook_Run("OnAmputateLimb", org, ent, limb)

	if org.owner:IsNPC() then
		org.shock = 100
	end

	net.Start("organism_send")

	local tbl = {}
	tbl[limb.."amputated"] = true
	tbl.owner = org.owner

	net.WriteTable(tbl)
	net.WriteBool(true)
	net.WriteBool(false)
	net.WriteBool(false)
	net.WriteBool(true)
	net.Broadcast()
end

hook.Add("OnAmputateLimb", "amputate_cuffs", function(org, ent, limb)
	if (limb == "larm" or limb == "rarm") and (org.handcuffed and ent:GetNetVar("handcuffed", false)) then
		if ent.handcuffs then
			if IsValid(ent.handcuffs[1]) then ent.handcuffs[1]:Remove() end
			if IsValid(ent.handcuffs[2]) then ent.handcuffs[2]:Remove() end
			ent.handcuffed = false
		end

		local ply = hg.RagdollOwner(ent)

		org.handcuffed = false
		ent:SetNetVar("handcuffed", false)

		if ply then ply:SetNetVar("handcuffed", false) end

		local cuffs = ents_Create("weapon_handcuffs")
		cuffs:SetPos(ent:GetPos())
		cuffs.IsSpawned = true
		cuffs.init = true
		cuffs:Spawn()
	end
end)

hook.Add("OnAmputateLimb", "amputate_flashlight", function(org, ent, limb)
	local inv = ent:GetNetVar("Inventory", {})

	if limb == "larm" and inv["Weapons"] and inv["Weapons"]["hg_flashlight"] and ent:GetNetVar("flashlight", false) then
		local flashlight = ents.Create("hg_flashlight")
		flashlight:SetPos(ent:EyePos())
		flashlight:SetAngles(ent:EyeAngles())
		flashlight:Spawn()
		flashlight:SetNetVar("enabled", ent:GetNetVar("flashlight", false))

		local phys = ent:GetPhysicsObject()

		if IsValid(phys) then
			phys:ApplyForceCenter(ent:GetAimVector() * 150 * phys:GetMass())
		end

		ent:SetNetVar("flashlight", false)
		inv["Weapons"]["hg_flashlight"] = nil
		ent:SetNetVar("Inventory", inv)
	end
end)
