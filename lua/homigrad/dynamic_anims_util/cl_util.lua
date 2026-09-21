--

local hook = hook

local PLAYER = FindMetaTable("Player")
function PLAYER:PlayCustomAnims(anim, autoStop, speed, autostopAdjust)
	self:SetNWString("hg_CustomAnim", anim)
	self:SetNWFloat("hg_CustomAnimDelay", speed or select(2, self:LookupSequence(anim)))
	self:SetNWFloat("hg_CustomAnimStartTime", CurTime())
	self:SetNWBool("hg_NeedAutoStop", autoStop)
	self:SetNWFloat("hg_AutoStopAdjust", autostopAdjust or 0)
	self:SetCycle(0)
	self:DoAnimationEvent(0)

	return select(2, self:LookupSequence(anim))
end

hook.Add("CalcMainActivity", "SLCAnim_Activity", function(ply, vel)
	local str = ply:GetNWString("hg_CustomAnim", "")
	local num = ply:GetNWFloat("hg_CustomAnimDelay")
	local st = ply:GetNWFloat("hg_CustomAnimStartTime")
	local needAutoStop = ply:GetNWBool("hg_NeedAutoStop", false)
	local autostopAdjust = ply:GetNWFloat("hg_AutoStopAdjust", 0)

	if str ~= nil and str ~= "" then
		ply:SetCycle((CurTime() - st) / num)

		return -1, ply:LookupSequence(str)
	end
end)

net.Receive("DynamicAnims_SendGesture", function()
	local ent = net.ReadEntity()
	local AnimID = net.ReadInt(16)
	local weight = net.ReadFloat()
	local sv_start_time = net.ReadFloat()
	local start_time = net.ReadFloat()
	local anim_time = net.ReadFloat()
	local AnimDuration = net.ReadFloat()
	local autokill = net.ReadBool()
	--print(ent, AnimID, weight, sv_start_time, start_time, anim_time, AnimDuration, autokill)
	if !IsValid(ent) then return end

	ent:PlayCustomAnimAsGesture(AnimID, weight, anim_time, sv_start_time, start_time, AnimDuration, autokill)
end)

function PLAYER:PlayCustomAnimAsGesture(AnimID, weight, anim_time, sv_start_time, start_time, AnimDuration, autokill)
	local ping_adjust = CurTime() - sv_start_time
	self:AnimResetGestureSlot(GESTURE_SLOT_CUSTOM)
	self:AddVCDSequenceToGestureSlot(GESTURE_SLOT_CUSTOM, AnimID,(start_time or 0) + ping_adjust, autokill)
	self:AnimSetGestureWeight(GESTURE_SLOT_CUSTOM, weight or 1)
end