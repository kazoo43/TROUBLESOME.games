if not TS_DeathAnim or not TS_DeathAnim.ConfigLoaded then
    include("homigrad/death_anims/sv_config.lua")
end
local function RecordInfo(ply, hit, dmgInfo)
    if not IsValid(ply) then return end
    if not ply:IsPlayer() then return end
    if not ply:Alive() then return end
    local kind, raw = TS_DeathAnim.ClassifyType(dmgInfo, ply)
    local faceYaw = nil
    local hitPos = nil
    if dmgInfo then
        if dmgInfo.GetDamagePosition then
            local p = dmgInfo:GetDamagePosition()
            if p and p:LengthSqr() > 1 then hitPos = Vector(p) end
        end
        if dmgInfo.GetAttacker then
            local attacker = dmgInfo:GetAttacker()
            if IsValid(attacker) and attacker ~= ply then
                local d = attacker:GetPos() - ply:GetPos()
                if d:LengthSqr() > 1 then faceYaw = d:Angle().yaw end
            end
        end
        if not faceYaw and dmgInfo.GetDamageForce then
            local f = dmgInfo:GetDamageForce()
            if f and f:LengthSqr() > 1 then faceYaw = (f * -1):Angle().yaw end
        end
    end
    ply.tsDeathInfo = {
        hit = hit or HITGROUP_GENERIC,
        kind = kind,
        raw = raw,
        hitPos = hitPos,
        flags = TS_DeathAnim.GetHitFlags(ply, hit, dmgInfo),
        faceYaw = faceYaw,
        time = CurTime(),
        standing = TS_DeathAnim.CaptureStanding(ply)
    }
end
function TS_DeathAnim.Animate(rag, seq, cycleEnd, rate, yaw)
    if not IsValid(rag) then return nil end
    if rag:GetClass() ~= "prop_ragdoll" then return nil end
    local anim = ents.Create("ts_death_anim")
    if not IsValid(anim) then return nil end
    anim:Spawn()
    local scale = 1
    local eyes = rag:LookupAttachment("eyes")
    if eyes and eyes > 0 then
        local att = rag:GetAttachment(eyes)
        if att and att.Pos then
            local h = math.abs(att.Pos.z - rag:GetPos().z)
            if h > 1 then scale = h / 67.01953125 end
        end
    end
    if scale < 0.8 or scale > 1.25 then scale = 1 end
    anim:Setup(rag, seq, {
        pos = rag:GetPos(),
        angles = Angle(0, yaw or rag:GetAngles().yaw, 0),
        cycleEnd = cycleEnd or TS_DeathAnim.CycleEnd,
        rate = rate or 1,
        animModel = TS_DeathAnim.AnimModel,
        scale = scale
    })
    if not IsValid(anim) then return nil end
    rag.TS_DeathAnim = anim
    return anim
end
function TS_DeathAnim.TryAnimate(ply)
    if TS_DeathAnim.EnableConvar:GetBool() == false then return end
    if math.random() > TS_DeathAnim.ChanceConvar:GetFloat() then return end
    if not IsValid(ply) then return end
    if not ply:IsPlayer() then return end
    if ply:Alive() then return end
    local dbg = TS_DeathAnim.DebugConvar and TS_DeathAnim.DebugConvar:GetBool()
    local info = ply.tsDeathInfo
    if not info then if dbg then print("[TS-DeathAnim] skip noinfo") end return end
    if CurTime() - info.time > TS_DeathAnim.InfoTimeout then if dbg then print("[TS-DeathAnim] skip stale") end return end
    if not info.standing then if dbg then print("[TS-DeathAnim] skip notstanding") end return end
    if ply:InVehicle() then if dbg then print("[TS-DeathAnim] skip vehicle") end return end
    if ply:WaterLevel() >= 2 then if dbg then print("[TS-DeathAnim] skip water") end return end
    if info.raw and bit.band(info.raw, bit.bor(DMG_DISSOLVE, DMG_REMOVENORAGDOLL)) ~= 0 then if dbg then print("[TS-DeathAnim] skip dissolve") end return end
    local rag = ply.RagdollDeath
    if not IsValid(rag) then rag = ply:GetNWEntity("RagdollDeath") end
    if not IsValid(rag) then rag = ply:GetRagdollEntity() end
    if not IsValid(rag) then if dbg then print("[TS-DeathAnim] skip norag") end return end
    if rag:GetClass() ~= "prop_ragdoll" then if dbg then print("[TS-DeathAnim] skip notragdoll") end return end
    if rag:GetPhysicsObjectCount() <= 0 then if dbg then print("[TS-DeathAnim] skip nophys") end return end
    local pelvisBone = rag:LookupBone("ValveBiped.Bip01_Pelvis")
    if not pelvisBone then if dbg then print("[TS-DeathAnim] skip nopelvis") end return end
    local pelvisPhys = rag:GetPhysicsObjectNum(rag:TranslateBoneToPhysBone(pelvisBone))
    if IsValid(pelvisPhys) and pelvisPhys:GetVelocity():Length() > 600 then if dbg then print("[TS-DeathAnim] skip fast") end return end
    if IsValid(rag.TS_DeathAnim) then return end
    if not TS_DeathAnim.HasGround(rag) then if dbg then print("[TS-DeathAnim] skip noground") end return end
    local seq, frac, rate, headClub = TS_DeathAnim.Select(info.hit, info.kind, info.flags)
    if not seq then if dbg then print("[TS-DeathAnim] skip noseq") end return end
    local yaw = nil
    if info.faceYaw then
        yaw = info.faceYaw
        if info.flags and info.flags.back then yaw = yaw + 180 end
    end
    local anim = TS_DeathAnim.Animate(rag, seq, frac, rate, yaw)
    if headClub and IsValid(anim) and TS_DeathAnim.HeadGore then
        if math.random() < ((TS_DeathAnim.HeadClub and TS_DeathAnim.HeadClub.FaceHoldChance) or 0) then
            anim:SetFaceHold(true)
        end
        TS_DeathAnim.HeadGore(rag, info.hitPos)
    end
end
hook.Add("HomigradDamage", "TS_DeathAnim_Track", function(ply, dmgInfo, hitgroup)
    RecordInfo(ply, hitgroup, dmgInfo)
end)
hook.Add("ScalePlayerDamage", "TS_DeathAnim_Track", function(ply, hitgroup, dmgInfo)
    RecordInfo(ply, hitgroup, dmgInfo)
end)
hook.Add("EntityTakeDamage", "TS_DeathAnim_Track", function(ent, dmgInfo)
    if not ent:IsPlayer() then return end
    local hit = HITGROUP_GENERIC
    local old = ent.tsDeathInfo
    if old and old.hit and CurTime() - old.time < 3 then hit = old.hit end
    RecordInfo(ent, hit, dmgInfo)
end)
hook.Add("DoPlayerDeath", "TS_DeathAnim", function(ply)
    if not IsValid(ply) then return end
    if not ply:IsPlayer() then return end
    timer.Simple(0.05, function()
        TS_DeathAnim.TryAnimate(ply)
    end)
end)
hook.Add("PlayerSpawn", "TS_DeathAnim_Clear", function(ply)
    if not IsValid(ply) then return end
    ply.tsDeathInfo = nil
end)
hook.Add("PostCleanupMap", "TS_DeathAnim_Cleanup", function()
    for _, e in ipairs(ents.FindByClass("ts_death_anim")) do
        if IsValid(e) then e:Remove() end
    end
    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) then ply.tsDeathInfo = nil end
    end
end)
