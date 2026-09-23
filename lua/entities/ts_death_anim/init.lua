AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
include("shared.lua")
local SHADOW = {
    secondstoarrive = 0.01,
    maxangular = 400,
    maxangulardamp = 200,
    maxspeed = 400,
    maxspeeddamp = 300,
    teleportdistance = 0
}
local REACH_SQR = 2304
local BLEND_TIME = 0.3
local ABORT_FRACTION = 0.5
local function Dbg(msg)
    local cv = GetConVar("ts_deathanim_debug")
    if cv and cv:GetBool() then print(msg) end
end
local FALL_DROP = 24
local FALL_GRACE = 0.15
function ENT:Initialize()
    self:SetModel("models/error.mdl")
    self:SetNoDraw(true)
    self:DrawShadow(false)
    self:SetSolid(SOLID_NONE)
    self:SetMoveType(MOVETYPE_NONE)
    self.Delta = CurTime()
    self.CycleEnd = 0.9
end
function ENT:Setup(rag, seq, opts)
    opts = opts or {}
    if not IsValid(rag) then self:Remove() return end
    self.Ragdoll = rag
    self.CycleEnd = opts.cycleEnd or 0.9
    self.FinishFunc = opts.onFinish
    self:SetModel(opts.animModel or rag:GetModel())
    if opts.scale then
        pcall(function() self:SetModelScale(opts.scale, 0) end)
    else
        pcall(function() self:SetModelScale(rag:GetModelScale(), 0) end)
    end
    self:SetPos(opts.pos or rag:GetPos())
    self:SetAngles(opts.angles or rag:GetAngles())
    self.GroundZ = self:GetPos().z
    local seqId = self:LookupSequence(seq)
    if not seqId or seqId < 0 then self:Remove() return end
    self:ResetSequence(seqId)
    self:SetCycle(0)
    self:SetPlaybackRate(opts.rate or 1)
    local dur = 2
    pcall(function() dur = self:SequenceDuration(seqId) end)
    if not dur or dur <= 0 then dur = 2 end
    self.DieAt = CurTime() + dur + 1
    local pelvisAnim = self:LookupBone("ValveBiped.Bip01_Pelvis")
    local pelvisRag = rag:LookupBone("ValveBiped.Bip01_Pelvis")
    if pelvisAnim and pelvisRag then
        local animPos = self:GetBonePosition(pelvisAnim)
        local physPelvis = rag:GetPhysicsObjectNum(rag:TranslateBoneToPhysBone(pelvisRag))
        if animPos and IsValid(physPelvis) then
            self:SetPos(self:GetPos() + (physPelvis:GetPos() - animPos))
            self.GroundZ = self:GetPos().z
        end
    end
    Dbg("[TS-DeathAnim] start model=" .. rag:GetModel() .. " seq=" .. seq)
    self.Birth = CurTime()
    self.Locked = true
    for i = 0, rag:GetPhysicsObjectCount() - 1 do
        local phys = rag:GetPhysicsObjectNum(i)
        if IsValid(phys) then
            phys:SetVelocity(Vector(0, 0, 0))
            local av = phys:GetAngleVelocity()
            phys:AddAngleVelocity(Vector(0 - av.x, 0 - av.y, 0 - av.z))
            phys:EnableMotion(false)
        end
    end
    timer.Simple(FrameTime() + 0.01, function()
        if not IsValid(self) then return end
        local target = self.Ragdoll
        if IsValid(target) then
            for i = 0, target:GetPhysicsObjectCount() - 1 do
                local phys = target:GetPhysicsObjectNum(i)
                if IsValid(phys) then
                    phys:EnableMotion(true)
                    phys:Wake()
                end
            end
        end
        self.Locked = false
    end)
end
function ENT:DriveRagdoll(rag, dt)
    local k = 1
    if self.Birth then
        k = math.min(1, (CurTime() - self.Birth) / BLEND_TIME)
        if k < 0.05 then k = 0.05 end
    end
    local speed = SHADOW.maxspeed * k
    local damp = SHADOW.maxspeeddamp * k
    local far = 0
    local total = 0
    for i = 0, rag:GetPhysicsObjectCount() - 1 do
        local phys = rag:GetPhysicsObjectNum(i)
        if not IsValid(phys) then continue end
        local bone = self:LookupBone(rag:GetBoneName(rag:TranslatePhysBoneToBone(i)))
        if not bone then continue end
        local pos, ang = self:GetBonePosition(bone)
        if not pos then continue end
        total = total + 1
        if phys:GetPos():DistToSqr(pos) > REACH_SQR then far = far + 1 continue end
        local tr = util.TraceLine({
            start = phys:GetPos(),
            endpos = pos,
            filter = {self, rag},
            mask = MASK_SOLID
        })
        if tr.Hit then continue end
        phys:Wake()
        phys:ComputeShadowControl({
            secondstoarrive = SHADOW.secondstoarrive,
            pos = pos,
            angle = ang,
            maxangular = SHADOW.maxangular,
            maxangulardamp = SHADOW.maxangulardamp,
            maxspeed = speed,
            maxspeeddamp = damp,
            teleportdistance = SHADOW.teleportdistance,
            deltatime = dt
        })
    end
    return far, total
end
function ENT:OverVoid()
    local bone = self:LookupBone("ValveBiped.Bip01_Pelvis") or 0
    local bp = self:GetBonePosition(bone)
    if not bp then return false end
    local tr = util.TraceLine({
        start = Vector(bp.x, bp.y, self.GroundZ + 24),
        endpos = Vector(bp.x, bp.y, self.GroundZ - FALL_DROP),
        mask = MASK_SOLID,
        filter = function(e)
            return not e:IsPlayer() and e:GetClass() ~= "prop_ragdoll"
        end
    })
    return not tr.Hit
end
function ENT:ClearRef()
    local rag = self.Ragdoll
    if IsValid(rag) and rag.TS_DeathAnim == self then
        rag.TS_DeathAnim = nil
    end
end
function ENT:OnRemove()
    self:ClearRef()
end
function ENT:Think()
    local rag = self.Ragdoll
    if not IsValid(rag) then self:Remove() return end
    if self.DieAt and CurTime() > self.DieAt then
        Dbg("[TS-DeathAnim] lifetime guard")
        self:ClearRef()
        self:Remove()
        return
    end
    if self:OverVoid() then
        self.VoidSince = self.VoidSince or CurTime()
        if CurTime() - self.VoidSince > FALL_GRACE then
            self:ClearRef()
            self:Remove()
            return
        end
    else
        self.VoidSince = nil
    end
    local dt = CurTime() - self.Delta
    if dt <= 0 then dt = FrameTime() end
    if not self.Locked then
        local far, total = self:DriveRagdoll(rag, dt)
        if total > 0 and far > total * ABORT_FRACTION then
            Dbg("[TS-DeathAnim] abort far=" .. far .. " total=" .. total)
            self:ClearRef()
            self:Remove()
            return
        end
    end
    if self:GetCycle() >= self.CycleEnd then
        local fn = self.FinishFunc
        local target = rag
        Dbg("[TS-DeathAnim] finish cycle=" .. self:GetCycle())
        self:ClearRef()
        self:Remove()
        if isfunction(fn) then fn(self, target) end
        return
    end
    self.Delta = CurTime()
    self:NextThink(CurTime())
    return true
end
