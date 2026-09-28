local max, halfValue = math.max, util.halfValue

hg.organism.module = hg.organism.module or {}
hg.organism.module.liver = hg.organism.module.liver or {}
local module = hg.organism.module.liver

module[1] = function(org)
	org.liver = 0
end

module[2] = function(owner, org, mulTime)
	if !org.isPly then return end
	if !org.alive or org.hearstop then return end
end