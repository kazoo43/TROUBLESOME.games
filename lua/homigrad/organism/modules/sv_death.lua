hg.organism.module = hg.organism.module or {}
hg.organism.module.death = hg.organism.module.death or {}
local module = hg.organism.module.death

module[2] = function(owner, org, timeValue)
	if org.alive then return end

	org.otrub = true
	org.lungsfunction = false
	org.heartstop = true
end
