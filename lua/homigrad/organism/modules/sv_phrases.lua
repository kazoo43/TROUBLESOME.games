hg.organism.module = hg.organism.module or {}
hg.organism.module.phrases = hg.organism.module.phrases or {}
local module = hg.organism.module.phrases

local math_Clamp = math.Clamp

module[2] = function(owner, org, timeValue)
	if org.otrub then return end
	if !org.isPly then return end

	local mul = hg.likely_to_phrase(owner)

	if !org.likely_phrase then org.likely_phrase = 0 end

	org.likely_phrase = math.max(org.likely_phrase + math.Rand(0, mul) / 100, 0)

	if org.likely_phrase >= 1 and !hg.GetCurrentCharacter(owner):IsOnFire() then
		org.likely_phrase = 0

		local str = hg.get_status_message(owner)
		local shade = math_Clamp(1 / hg.likely_to_phrase(owner) * 255, 0, 255)

		owner:Notify(str, 1, "phrase", 1, nil, Color(255, shade, shade, 255))
	end
end
