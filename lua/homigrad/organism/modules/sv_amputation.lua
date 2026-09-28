hg.organism.module = hg.organism.module or {}
hg.organism.module.amputation = hg.organism.module.amputation or {}
local module = hg.organism.module.amputation

module[2] = function(owner, org, timeValue)
	if (org.llegamputated or org.rlegamputated) and org.berserk <= 0.3 then
		org.needfake = true
	end

	if org.rarmamputated and org.larmamputated and owner:IsPlayer() then
		local hands = owner:GetWeapon("weapon_hands_sh")

		if owner:GetActiveWeapon() != hands then
			owner:SetActiveWeapon(hands)
		end
	end
end
