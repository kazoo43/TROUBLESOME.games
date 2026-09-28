hg = hg or {}
hg.organism = hg.organism or {}

local PLAYER = FindMetaTable("Player")
local IsValid = IsValid
local CurTime = CurTime
local LerpAngle = LerpAngle
local math_random = math.random
local math_Rand = math.Rand

util.AddNetworkString("hg_headcrab")

function PLAYER:AddHeadcrab(headcrab)
	if self.PlayerClassName == "headcrabzombie" then return end

	self:SetNetVar("headcrab", headcrab)

	self.organism.headcrabon = headcrab and CurTime()
	self.organism.headcrabevent = false
end

hg.organism.headcrabClasses = {
	["npc_headcrab"] = true,
	["npc_headcrab_fast"] = true,
	["npc_headcrab_black"] = true,
}

hg.organism.headcrabModels = {
	["npc_headcrab"] = "models/nova/w_headcrab.mdl",
	["npc_headcrab_fast"] = "models/headcrab.mdl",
	["npc_headcrab_black"] = "models/headcrabblack.mdl",
}

hook.Add("RagdollDeath", "headcrab", function(ply, rag)
	rag:SetNetVar("headcrab", ply:GetNetVar("headcrab"))
	ply:SetNetVar("headcrab", false)

	ply.organism.noHead = false
end)

hook.Add("CanEquipArmor", "HeadcrabArmorCD", function(ply, armor_name)
	if IsValid(ply) and ((ply.ArmorCD or 0) > CurTime() or ply:GetNetVar("headcrab")) then
		return false
	end
end)

hg.organism.module = hg.organism.module or {}
hg.organism.module.headcrab = hg.organism.module.headcrab or {}
local module = hg.organism.module.headcrab

module[3] = function(org)
	org.headcrabon = nil
	org.headcrabevent = false

	if IsValid(org.owner) then
		org.owner:SetNetVar("headcrab", false)
	end

	org.noHead = false
end

local clr_red = Color(150, 0, 0)
local lerpAng = Angle(0, 0, 0)

module[2] = function(owner, org, timeValue)
	if !IsValid(owner) then return end
	if !owner:IsPlayer() or !owner:Alive() then return end

	if org.headcrabon and (org.headcrabon + 30) < CurTime() and org.brain != 1 then
		local ent = hg.GetCurrentCharacter(owner) or owner
		local mul = ((org.headcrabon + 60) - CurTime()) / 60

		if mul > 0 then
			ent:GetPhysicsObjectNum(math_random(ent:GetPhysicsObjectCount()) - 1):ApplyForceCenter(VectorRand(-750 * mul, 750 * mul))
		end
	end

	if org.headcrabon then
		owner.noHead = true
		owner:SetNWString("PlayerName", "Body with headcrab")
		org.brain = 0.3

		if org.alive then
			lerpAng = LerpAngle(FrameTime() * 3, lerpAng, AngleRand(-90, 90))
			lerpAng.r = 0
			owner:SetEyeAngles(owner:EyeAngles() + lerpAng)
		end

		if (org.headcrabon + 60) < CurTime() and org.alive and !org.headcrabevent then
			owner:EmitSound("npc/zombie/zombie_alert"..math_random(3)..".wav", 80, math_random(60, 70))
			owner:EmitSound("neck_snap_01.wav", 80, 80, 1, CHAN_AUTO)
			owner:SetPlayerClass("headcrabzombie")

			org.painadd = org.painadd + 5

			hg.StunPlayer(owner, 5)

			if zb and zb.GiveRole then
				zb.GiveRole(owner, "Zombie", clr_red)
			end

			org.headcrabevent = true
			org.headcrabon = nil
			org.headcrabevent = false
			org.noHead = false

			hg.FakeUp(owner, true)
			owner:SetNetVar("headcrab", false)
		end
	end

	if org.alive and org.headcrabon and (org.headcrabon + 20) < CurTime() then
		if (org.headcrabon + 30) > CurTime() then
			owner:EmitSound("npc/zombie/zombie_pain"..math_random(6)..".wav", 80, math_random(80, 90))

			org.painadd = org.painadd + 15

			hg.StunPlayer(owner, 5)
		end
	end

	if org.alive and org.headcrabon and (org.headcrabon + 60) < CurTime() then
		owner:SetNWString("PlayerName", "Body with headcrab")
		org.alive = false
	end
end
