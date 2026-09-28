hg.organism.module = hg.organism.module or {}
hg.organism.module.net = hg.organism.module.net or {}
local module = hg.organism.module.net

local CurTime = CurTime
local IsValid = IsValid

module[2] = function(owner, org, timeValue)
	if !IsValid(owner) then return end

	local isPly = org.isPly

	org.sendPlyTime = org.sendPlyTime or CurTime()

	if (org.sendPlyTime > CurTime()) and !org.just_went_uncon then return end

	org.sendPlyTime = CurTime() + 1 + (!isPly and 2 or 0)

	hg.send_bareinfo(org)

	org.owner:SetNetVar("wounds", org.wounds)
	org.owner:SetNetVar("arterialwounds", org.arterialwounds)

	if isPly and owner:Alive() then
		hg.send_organism(org, owner)
	end
end
