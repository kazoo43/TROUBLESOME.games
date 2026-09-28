hg = hg or {}

local IsValid = IsValid
local util_TraceLine = util.TraceLine
local math_Clamp = math.Clamp
local timer_Simple = timer.Simple

hook.Add("HG_OnWakeOtrub", "afterOtrub", function(owner)
	owner.organism.after_otrub = true

	local str = hg.get_status_message(owner)

	owner.organism.after_otrub = nil

	timer_Simple(0.1, function()
		if !IsValid(owner) then return end

		local shade = math_Clamp(1 / hg.likely_to_phrase(owner) * 255, 0, 255)

		owner:Notify(str, 1, "wake", 1, nil, Color(255, shade, shade))
	end)

	owner.organism.fearadd = owner.organism.fearadd + 5

	owner:SendLua("system.FlashWindow()")
end)

hook.Add("HG_OnOtrub", "fearful", function(plya)
	local ent = hg.GetCurrentCharacter(plya)

	for i, ply in ipairs(ents.FindInSphere(ent:GetPos(), 256)) do
		if !ply:IsPlayer() or !ply.organism or plya == ply then continue end

		local tr = {}
		tr.start = ply:GetPos()
		tr.endpos = ent:GetPos()
		tr.filter = {ply, ent}

		if !util_TraceLine(tr).Hit then
			ply.organism.adrenalineAdd = ply.organism.adrenalineAdd + 0.3
			ply.organism.fearadd = ply.organism.fearadd + 0.3
		end
	end
end)
