TS_Stagger = TS_Stagger or {}
TS_Stagger.AnimModel = "models/bms/cit_zom.mdl"
TS_Stagger.Seq = "stun05"
TS_Stagger.CycleEnd = 0.5
TS_Stagger.Rate = 1
TS_Stagger.Buffer = 0.3
TS_Stagger.Cooldown = 1.5
TS_Stagger.DurationCache = TS_Stagger.DurationCache or nil
function TS_Stagger.IsStaggered(ply)
    if not IsValid(ply) then return false end
    if ply.tsStagger then return true end
    return ply:GetNWBool("TS_Staggered", false)
end
if SERVER then
    util.PrecacheModel(TS_Stagger.AnimModel)
    function TS_Stagger.GetAnimDuration()
        if TS_Stagger.DurationCache then return TS_Stagger.DurationCache end
        local dur = 1.2
        local ent = ents.Create("prop_dynamic")
        if IsValid(ent) then
            ent:SetModel(TS_Stagger.AnimModel)
            ent:SetPos(Vector(0, 0, -2000))
            ent:Spawn()
            local seqId = ent:LookupSequence(TS_Stagger.Seq)
            if seqId and seqId >= 0 then
                local d = ent:SequenceDuration(seqId)
                if d and d > 0 then dur = d end
            end
            ent:Remove()
        end
        TS_Stagger.DurationCache = dur
        return dur
    end
    function TS_Stagger.AnimateRagdoll(rag, yaw, onFinish)
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
        anim:Setup(rag, TS_Stagger.Seq, {
            pos = rag:GetPos(),
            angles = Angle(0, yaw or rag:GetAngles().yaw, 0),
            cycleEnd = TS_Stagger.CycleEnd,
            rate = TS_Stagger.Rate,
            animModel = TS_Stagger.AnimModel,
            scale = scale,
            onFinish = onFinish
        })
        if not IsValid(anim) then return nil end
        rag.TS_DeathAnim = anim
        return anim
    end
    function TS_Stagger.Stagger(ply, attacker, opts)
        if not IsValid(ply) then return false end
        if not ply:IsPlayer() then return false end
        if not ply:Alive() then return false end
        if ply.tsStagger then return false end
        if ply:InVehicle() then return false end
        if ply:WaterLevel() >= 2 then return false end
        if not ply.organism then return false end
        if ply.organism.otrub then return false end
        if (ply.tsStaggerCD or 0) > CurTime() then return false end
        opts = opts or {}
        local duration = opts.duration
        if not duration then
            duration = TS_Stagger.GetAnimDuration() * TS_Stagger.CycleEnd / TS_Stagger.Rate
        end
        duration = math.Clamp(duration, 0.3, 3)
        if not IsValid(ply.FakeRagdoll) then
            hg.Fake(ply, nil, true)
        end
        local rag = ply.FakeRagdoll
        if not IsValid(rag) then return false end
        if IsValid(rag.TS_DeathAnim) then return false end
        local yaw = rag:GetAngles().yaw
        if IsValid(attacker) and attacker ~= ply then
            local d = attacker:GetPos() - ply:GetPos()
            if d:LengthSqr() > 1 then yaw = d:Angle().yaw end
        end
        ply.organism.lightstun = math.max(ply.organism.lightstun or 0, CurTime() + duration + TS_Stagger.Buffer)
        ply:SetLocalVar("stun", ply.organism.lightstun)
        ply.tsStagger = true
        ply.tsStaggerEnd = CurTime() + duration + TS_Stagger.Buffer
        ply.tsStaggerCD = CurTime() + duration + TS_Stagger.Cooldown
        ply:SetNWBool("TS_Staggered", true)
        local anim = TS_Stagger.AnimateRagdoll(rag, yaw, function()
            TS_Stagger.EndStagger(ply)
        end)
        if not IsValid(anim) then
            TS_Stagger.EndStagger(ply)
            return false
        end
        ply.tsStaggerAnim = anim
        timer.Create("TS_Stagger_" .. ply:EntIndex(), duration + TS_Stagger.Buffer + 0.5, 1, function()
            if IsValid(ply) then TS_Stagger.EndStagger(ply) end
        end)
        return true
    end
    function TS_Stagger.EndStagger(ply)
        if not IsValid(ply) then return end
        if not ply.tsStagger then return end
        timer.Remove("TS_Stagger_" .. ply:EntIndex())
        ply.tsStagger = nil
        ply.tsStaggerEnd = nil
        local anim = ply.tsStaggerAnim
        ply.tsStaggerAnim = nil
        ply:SetNWBool("TS_Staggered", false)
        local rag = ply.FakeRagdoll
        if IsValid(rag) and IsValid(rag.TS_DeathAnim) and rag.TS_DeathAnim == anim then
            rag.TS_DeathAnim:Remove()
        end
        if IsValid(anim) then
            anim:Remove()
        end
        if ply.organism then
            if (ply.organism.lightstun or 0) <= CurTime() + TS_Stagger.Buffer + 0.6 then
                ply.organism.lightstun = 0
                ply:SetLocalVar("stun", 0)
            end
        end
        if not ply:Alive() then return end
        if IsValid(ply.FakeRagdoll) then
            hg.FakeUp(ply, true)
        end
    end
    hg.StaggerPlayer = hg.StaggerPlayer or function(ply, attacker, opts)
        return TS_Stagger.Stagger(ply, attacker, opts)
    end
    hook.Add("CanControlFake", "TS_Stagger_NoControl", function(ply, rag)
        if ply.tsStagger then return false end
    end)
    hook.Add("Should Fake Up", "TS_Stagger_NoGetUp", function(ply)
        if ply.tsStagger then return false end
    end)
    local function ClearStagger(ply)
        timer.Remove("TS_Stagger_" .. ply:EntIndex())
        ply.tsStagger = nil
        ply.tsStaggerEnd = nil
        ply:SetNWBool("TS_Staggered", false)
        local anim = ply.tsStaggerAnim
        ply.tsStaggerAnim = nil
        if IsValid(anim) then anim:Remove() end
    end
    hook.Add("PlayerDeath", "TS_Stagger_Clear", function(ply)
        if not IsValid(ply) then return end
        ClearStagger(ply)
    end)
    hook.Add("PlayerDisconnected", "TS_Stagger_Disconnect", function(ply)
        if not IsValid(ply) then return end
        timer.Remove("TS_Stagger_" .. ply:EntIndex())
    end)
    hook.Add("PlayerSpawn", "TS_Stagger_SpawnClear", function(ply)
        if not IsValid(ply) then return end
        ClearStagger(ply)
    end)
    concommand.Add("ts_stagger", function(ply, cmd, args)
        if not IsValid(ply) then return end
        if not ply:Alive() then return end
        local target = ply
        if args and args[1] and args[1] ~= "" then
            if not ply:IsAdmin() then return end
            local needle = string.lower(args[1])
            for _, v in ipairs(player.GetAll()) do
                if tostring(v:EntIndex()) == args[1] then
                    target = v
                    break
                end
                if string.find(string.lower(v:Nick()), needle, 1, true) then
                    target = v
                    break
                end
            end
        end
        if not IsValid(target) then return end
        target.tsStaggerCD = 0
        TS_Stagger.Stagger(target, ply)
    end)
end
