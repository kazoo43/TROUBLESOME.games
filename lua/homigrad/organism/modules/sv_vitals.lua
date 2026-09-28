hg.organism.module = hg.organism.module or {}
hg.organism.module.vitals = hg.organism.module.vitals or {}
local module = hg.organism.module.vitals

local CurTime = CurTime
local IsValid = IsValid
local math_floor = math.floor
local math_min = math.min
local math_max = math.max
local math_Clamp = math.Clamp

module[2] = function(owner, org, timeValue)
	local isPly = org.isPly

	if org.just_went_uncon then
		org.owner.fullsend = true
	end

	if org.brain > 0.05 then
		if math.random(600) < org.brain * 20 then
			org.needfake = true
		end
	end

	org.otrub = org.needotrub
	org.fake = org.needfake

	if org.needfake and owner:IsNPC() then
		local dmgInfo = DamageInfo()
		dmgInfo:SetDamage(10000)
		dmgInfo:SetAttacker(owner)
		owner:TakeDamageInfo(dmgInfo)
	end

	if owner:IsPlayer() and (org.healthRegen or 0) < CurTime() then
		org.healthRegen = CurTime() + 30
		owner:SetHealth(math_min(owner:GetMaxHealth(), owner:Health() + math_max(1.5 - org.hurt, 0)))
	end

	if isPly and owner:Alive() and !org.godmode then
		local bloodcap = math_floor(owner:GetMaxHealth() * math_Clamp((org.blood - 2500) / 2500, 0, 1))

		if owner:Health() > bloodcap then owner:SetHealth(bloodcap) end
		if bloodcap <= 0 then owner:Kill() end
	end

	org.health = owner:Health()

	local rag = owner:IsPlayer() and owner.FakeRagdoll or owner

	if IsValid(rag) and rag:IsRagdoll() and (!owner.lastFake or owner.lastFake == 0) then
		rag:SetCollisionGroup((rag:GetVelocity():LengthSqr() > (200 * 200)) and COLLISION_GROUP_NONE or COLLISION_GROUP_WEAPON)
	end

	if isPly then
		if org.otrub or org.fake then hg.Fake(owner, nil, true) end
		if !org.alive and owner:Alive() then owner:Kill() end
	end
end
