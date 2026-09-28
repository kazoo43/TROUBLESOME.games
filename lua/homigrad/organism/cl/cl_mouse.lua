local RunConsoleCommand = RunConsoleCommand
local CurTime = CurTime
local Lerp = Lerp
local time_troll = 100

local prank = {}

hook.Add("HG.InputMouseApply", "zzzzzzzzzzzzbrain_death", function(tbl)
	if !lply:Alive() or !lply.organism or (lply.organism.brain or 0) <= 0.1 then return end

	if #prank < time_troll then table.insert(prank, 1, {tbl.x, tbl.y}) end
	if #prank >= time_troll then table.remove(prank, #prank) end

	local amt = lply.organism.brain / 0.3

	local xa = Lerp(1 * amt, tbl.x, prank[#prank][1])
	local ya = Lerp(1 * amt, tbl.y, prank[#prank][2])

	tbl.angle.pitch = math.Clamp(tbl.angle.pitch + tbl.y / 100 + ya / 100, -89, 89)
	tbl.angle.yaw = tbl.angle.yaw - tbl.x / 100 - xa / 100
	tbl.override_angle = true
end)
