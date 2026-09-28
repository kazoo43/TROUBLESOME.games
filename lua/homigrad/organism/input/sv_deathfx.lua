hg = hg or {}

local IsValid = IsValid
local timer_Simple = timer.Simple

function hg.ExplodeHead(ent)
	if !IsValid(ent) then return end

	local ply = ent:IsRagdoll() and hg.RagdollOwner(ent) or ent

	if ply:IsPlayer() and ply:Alive() then ply:Kill() end
	if ent:IsNPC() and ent.organism then ent.organism.shock = 100 end

	timer_Simple(0, function()
		local target = ent:IsRagdoll() and ent or ent:GetNWEntity("RagdollDeath")

		if !IsValid(target) then return end

		Gib_Input(target, target:LookupBone("ValveBiped.Bip01_Head1"))

		target.organism.headamputated = true
		target.headexploded = true

		target.organism.owner.fullsend = true
		hg.send_bareinfo(target.organism)
	end)
end

function hg.BreakNeck(ent)
	if !IsValid(ent) then return end

	local ply = ent:IsRagdoll() and hg.RagdollOwner(ent) or ent

	if ply:Alive() then ply:Kill() end

	ent:EmitSound("neck_snap_01.wav", 60, 100, 1, CHAN_AUTO)

	timer_Simple(0.1, function()
		local target = ent:IsRagdoll() and ent or ent:GetNWEntity("RagdollDeath")

		if !IsValid(target) then return end

		target:RemoveInternalConstraint(target:TranslateBoneToPhysBone(target:LookupBone("ValveBiped.Bip01_Head1")))

		local spine = target:TranslateBoneToPhysBone(target:LookupBone("ValveBiped.Bip01_Spine2"))
		local head = target:TranslateBoneToPhysBone(target:LookupBone("ValveBiped.Bip01_Head1"))

		local pspine = target:GetPhysicsObjectNum(spine)
		local phead = target:GetPhysicsObjectNum(head)

		local lpos, lang = WorldToLocal(phead:GetPos() + phead:GetAngles():Forward() * -2 + phead:GetAngles():Up() * -1.5, angle_zero, pspine:GetPos(), pspine:GetAngles())

		phead:SetPos(pspine:GetPos() + pspine:GetAngles():Forward() * 12.9 + pspine:GetAngles():Right() * -1)

		constraint.AdvBallsocket(target, target, spine, head, lpos, nil, 0, 0, -55, -90, -50, 55, 35, 50, 0, 0, 0, 0, 0)
	end)
end
