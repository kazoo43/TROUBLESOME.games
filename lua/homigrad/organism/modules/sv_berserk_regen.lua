hg.organism.module = hg.organism.module or {}
hg.organism.module.berserk_regen = hg.organism.module.berserk_regen or {}
local module = hg.organism.module.berserk_regen

local max = math.max

module[2] = function(owner, org, timeValue)
	if !owner:IsPlayer() or !owner:Alive() then return end
	if !owner:IsBerserk() then return end

	org.blood = math.Approach(org.blood, 5000, timeValue * 60)

	for i, wound in pairs(org.wounds) do
		wound[1] = max(wound[1] - timeValue * 10, 0)
	end

	for i, wound in pairs(org.arterialwounds) do
		wound[1] = max(wound[1] - timeValue * 10, 0)
	end

	org.internalBleed = max(org.internalBleed - timeValue * 10, 0)

	local regen = timeValue / 120 * org.berserk

	org.lleg = max(org.lleg - regen, 0)
	org.rleg = max(org.rleg - regen, 0)
	org.rarm = max(org.rarm - regen, 0)
	org.larm = max(org.larm - regen, 0)
	org.chest = max(org.chest - regen, 0)
	org.pelvis = max(org.pelvis - regen, 0)
	org.skull = max(org.skull - regen, 0)

	org.liver = max(org.liver - regen, 0)
	org.intestines = max(org.intestines - regen, 0)
	org.heart = max(org.heart - regen, 0)
	org.stomach = max(org.stomach - regen, 0)
	org.lungsR[1] = max(org.lungsR[1] - regen, 0)
	org.lungsL[1] = max(org.lungsL[1] - regen, 0)
	org.lungsR[2] = max(org.lungsR[2] - regen, 0)
	org.lungsL[2] = max(org.lungsL[2] - regen, 0)
	org.brain = max(org.brain - regen, 0)

	org.hungry = 0

	org.pain = math.Approach(org.pain, 0, timeValue * 10)
	org.painadd = math.Approach(org.painadd, 0, timeValue * 10)
	org.avgpain = math.Approach(org.avgpain, 0, timeValue * 10)
	org.shock = math.Approach(org.shock, 0, timeValue * 10)
	org.immobilization = math.Approach(org.immobilization, 0, timeValue * 10)
	org.disorientation = math.Approach(org.disorientation, 0, timeValue * 10)

	org.lungsfunction = true
	org.heartstop = false

	owner:SetRunSpeed(math.min(500, 400 + (25 * org.berserk)))
end
