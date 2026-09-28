hg.organism.module = hg.organism.module or {}
hg.organism.module.noradrenaline_regen = hg.organism.module.noradrenaline_regen or {}
local module = hg.organism.module.noradrenaline_regen

local max = math.max

module[2] = function(owner, org, timeValue)
	if !owner:IsPlayer() or !owner:Alive() then return end
	if org.noradrenaline <= 0 then return end

	local regen = timeValue / 60 * org.noradrenaline

	org.lungsR[1] = max(org.lungsR[1] - regen, 0)
	org.lungsL[1] = max(org.lungsL[1] - regen, 0)
	org.lungsR[2] = max(org.lungsR[2] - regen, 0)
	org.lungsL[2] = max(org.lungsL[2] - regen, 0)

	org.hungry = 0

	org.pain = math.Approach(org.pain, 0, regen * 10)
	org.painadd = math.Approach(org.painadd, 0, regen * 10)
	org.avgpain = math.Approach(org.avgpain, 0, regen * 10)
	org.shock = math.Approach(org.shock, 0, regen * 10)
	org.immobilization = math.Approach(org.immobilization, 0, regen * 10)
	org.disorientation = math.Approach(org.disorientation, 0, regen * 10)
	org.adrenaline = math.Approach(org.adrenaline, 5, regen * 100)
	org.analgesia = math.Approach(org.analgesia, 1, regen * 10)

	if org.noradrenaline > 2 then
		org.brain = math.Approach(org.brain, 0.3, timeValue / 60)
	end

	org.pulse = math.Approach(org.pulse, 70, regen * 10)
	org.heartbeat = math.Approach(org.heartbeat, 220, regen * 10)

	org.lungsfunction = true
	org.heartstop = false
end
