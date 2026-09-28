hg.organism.module = hg.organism.module or {}
hg.organism.module.berserk = hg.organism.module.berserk or {}
local module = hg.organism.module.berserk

module[2] = function(owner, org, timeValue)
	org.berserk = math.Approach(org.berserk, 0, timeValue / 60)

	if org.berserk > 0 and !org.berserkActive then
		org.berserkActive = true

		owner.lastBerserkLaughSoundCD = CurTime() + 5

		timer.Simple(3.95, function()
			org.berserkActive2 = true
		end)
	elseif org.berserk <= 0 then
		org.berserkActive = false
		org.berserkActive2 = false
		owner.BerserkKills = nil
	end
end
