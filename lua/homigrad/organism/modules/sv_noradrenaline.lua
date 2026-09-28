hg.organism.module = hg.organism.module or {}
hg.organism.module.noradrenaline = hg.organism.module.noradrenaline or {}
local module = hg.organism.module.noradrenaline

module[2] = function(owner, org, timeValue)
	org.noradrenaline = math.Approach(org.noradrenaline, 0, timeValue / 45)

	if org.noradrenaline > 0 and !org.noradrenalineActive then
		org.noradrenalineActive = true
	elseif org.noradrenaline <= 0 then
		org.noradrenalineActive = false
	end
end
