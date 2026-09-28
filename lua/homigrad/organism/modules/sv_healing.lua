hg.organism.module = hg.organism.module or {}
hg.organism.module.healing = hg.organism.module.healing or {}
local module = hg.organism.module.healing

module[2] = function(owner, org, timeValue)
	if org.brain >= 0.4 then return end

	local naturalHeal = org.thiamine > 0 and timeValue / 480 or timeValue / 1800

	org.thiamine = math.Approach(org.thiamine, 0, timeValue / 240)

	if org.liver < 1 then org.liver = math.Approach(org.liver, 0, naturalHeal) end
	if org.heart < 1 then org.heart = math.Approach(org.heart, 0, naturalHeal) end
	if org.stomach < 1 then org.stomach = math.Approach(org.stomach, 0, naturalHeal) end
	if org.intestines < 1 then org.intestines = math.Approach(org.intestines, 0, naturalHeal) end
	if org.lungsR[1] < 1 then org.lungsR[1] = math.Approach(org.lungsR[1], 0, naturalHeal) end
	if org.lungsL[1] < 1 then org.lungsL[1] = math.Approach(org.lungsL[1], 0, naturalHeal) end
end
