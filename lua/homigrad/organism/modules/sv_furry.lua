hg.organism.module = hg.organism.module or {}
hg.organism.module.furry = hg.organism.module.furry or {}
local module = hg.organism.module.furry

module[2] = function(owner, org, timeValue)
	if owner.PlayerClassName == "furry" then
		org.assimilated = 0
		return
	end

	if org.furryinfected then
		org.assimilated = math.Approach(org.assimilated, 1, timeValue / 30 * org.pulse / 70)

		if org.assimilated == 1 then
			hg.Furrify(owner)

			org.furryinfected = false
		end
	else
		if (org.lightstun - CurTime()) <= 0 then
			org.assimilated = math.Approach(org.assimilated, 0, (timeValue / 60 * org.pulse / 70) * 6)
		end
	end

	if org.assimilated == 1 then
		org.assimilated = 0
		owner:SetPlayerClass("furry")
	end
end
