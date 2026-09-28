hg.organism.module = hg.organism.module or {}
hg.organism.module.otrub = hg.organism.module.otrub or {}
local module = hg.organism.module.otrub

local CurTime = CurTime
local hook_Run = hook.Run

module[2] = function(owner, org, timeValue)
	if org.otrub then
		org.uncon_timer = org.uncon_timer or 0
		org.uncon_timer = org.uncon_timer + timeValue
	else
		org.uncon_timer = 0
	end

	local just_went_uncon = !org.otrub and org.needotrub
	local just_woke_up = !org.needotrub and org.otrub and (org.uncon_timer or 0) > 6

	if org.isPly and just_went_uncon then
		hook_Run("HG_OnOtrub", owner)
		hook_Run("PlayerDropWeapon", owner)
	end

	if org.isPly and just_woke_up then
		hook_Run("HG_OnWakeOtrub", owner)
	end

	org.canmove = !org.otrub
	org.canmovehead = !org.otrub

	if !(org.canmove and org.canmovehead and (org.stun - CurTime()) < 0) then
		org.needfake = true
	end

	org.just_went_uncon = just_went_uncon
	org.just_woke_up = just_woke_up
end
