hg = hg or {}

local IsValid = IsValid
local timer_Simple = timer.Simple

local PLAYER = FindMetaTable("Player")
local ENTITY = FindMetaTable("Entity")

function PLAYER:IsBerserk()
	if !IsValid(self) then return false end
	if self:IsPlayer() and !self:Alive() then return false end

	local org = self.organism

	return org.berserkActive2 or false
end

function PLAYER:IsStimulated()
	if !IsValid(self) then return false end
	if self:IsPlayer() and !self:Alive() then return false end

	local org = self.organism

	return org.noradrenalineActive or false
end

function ENTITY:IsBerserk()
	return false
end

function ENTITY:IsStimulated()
	return false
end

local numerical = {
	"One.",
	"Two.",
	"Three.",
	"Four.",
	"Five.",
	"Six.",
	"Seven.",
	"Eight.",
	"Nine.",
	"Ten.",
	"Eleven.",
	"Twelve.",
	"Thirteen.",
	"Fourteen.",
	"Fifteen.",
	"Sixteen.",
	"Seventeen.",
	"Eighteen.",
	"Nineteen.",
	"Twenty."
}

hook.Add("HomigradDamage", "Berserk", function(ply, dmgInfo, hitgroup, ent)
	local attacker, victim = dmgInfo:GetAttacker(), ply

	if !attacker or !IsValid(attacker) or (IsValid(attacker) and !attacker:IsPlayer()) then
		attacker = ply:GetPhysicsAttacker()
	end

	if !IsValid(attacker) or !attacker:IsPlayer() then return end
	if !IsValid(victim) or !victim:IsPlayer() then return end
	if attacker == victim then return end
	if !attacker:IsBerserk() then return end

	timer_Simple(0, function()
		if IsValid(attacker) and IsValid(victim) and !victim:Alive() then
			attacker.BerserkKills = (attacker.BerserkKills or 0) + 1
			attacker:NotifyBerserk(numerical[attacker.BerserkKills] or (attacker.BerserkKills .. "."))

			attacker.organism.berserk = attacker.organism.berserk + 0.5
		end
	end)
end)
