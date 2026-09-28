TS_DeathAnim = TS_DeathAnim or {}
TS_DeathAnim.CycleEnd = 0.9
TS_DeathAnim.GroundCheck = 60
TS_DeathAnim.InfoTimeout = 5
TS_DeathAnim.HeadRate = 1.15
TS_DeathAnim.ClubEndMul = 0.5
TS_DeathAnim.CustomEndPos = {
    ["bd_death_head_short_03"] = 15,
    ["bd_death_head_single_02"] = 25,
    ["bd_death_head_single_03"] = 25,
    ["bd_death_head_short_01"] = 35,
    ["ex_mix_headshot_2"] = 35,
    ["ex_mix_headshot_5"] = 35,
    ["bd_death_head_multi_01"] = 15,
    ["bd_death_head_multi_02"] = 15,
    ["bd_death_head_multi_03"] = 15
}
TS_DeathAnim.EnableConvar = CreateConVar("ts_deathanim_enable", 1, FCVAR_ARCHIVE, "Enable standing death animations")
TS_DeathAnim.ChanceConvar = CreateConVar("ts_deathanim_chance", 1, FCVAR_ARCHIVE, "Chance a standing death plays an animation")
TS_DeathAnim.DebugConvar = CreateConVar("ts_deathanim_debug", 0, FCVAR_ARCHIVE, "Log death animation selection and driver events")
if not TS_DeathAnim.AnimTableLoaded then
    include("homigrad/death_anims/sv_animtable.lua")
end
function TS_DeathAnim.GetHitFlags(ply, hit, dmgInfo)
    local flags = {neck = false, shotgun = false, back = false, pelvis = false}
    if not IsValid(ply) then return flags end
    if not dmgInfo or not dmgInfo.GetDamageType then return flags end
    if dmgInfo.IsDamageType and dmgInfo:IsDamageType(DMG_BUCKSHOT) then flags.shotgun = true end
    if dmgInfo.GetAmmoType and dmgInfo:GetAmmoType() == 7 then flags.shotgun = true end
    if not dmgInfo.GetDamagePosition then return flags end
    local dmgpos = dmgInfo:GetDamagePosition()
    if not dmgpos or dmgpos:LengthSqr() < 1 then return flags end
    local headBone = ply:LookupBone("ValveBiped.Bip01_Head1")
    if headBone and hit == HITGROUP_HEAD then
        local headPos = ply:GetBonePosition(headBone)
        if headPos and dmgpos.z < headPos.z then flags.neck = true end
    end
    local pelvisBone = ply:LookupBone("ValveBiped.Bip01_Pelvis")
    if pelvisBone then
        local pelvisPos = ply:GetBonePosition(pelvisBone)
        if pelvisPos and dmgpos.z < pelvisPos.z + 2 then flags.pelvis = true end
    end
    local toDmg = dmgpos - ply:GetPos()
    if toDmg:LengthSqr() > 1 and ply:GetForward():Dot(toDmg:GetNormalized()) < 0 then flags.back = true end
    return flags
end
function TS_DeathAnim.CaptureStanding(ply)
    if not IsValid(ply) then return false end
    if not ply:IsPlayer() then return false end
    if not ply:Alive() then return false end
    if IsValid(ply.FakeRagdoll) then return false end
    if ply:InVehicle() then return false end
    if ply:WaterLevel() >= 2 then return false end
    if not ply:IsOnGround() then return false end
    local org = ply.organism
    if org and (org.otrub == true or org.fake == true) then return false end
    return true
end
function TS_DeathAnim.ClassifyType(dmgInfo, ply)
    local raw = 0
    if dmgInfo and dmgInfo.GetDamageType then
        raw = dmgInfo:GetDamageType()
    end
    if bit.band(raw, DMG_BURN) ~= 0 then return "fire", raw end
    if IsValid(ply) and ply:IsPlayer() and ply:IsOnFire() then return "fire", raw end
    if dmgInfo and dmgInfo.IsExplosionDamage and dmgInfo:IsExplosionDamage() then return "explosion", raw end
    if bit.band(raw, DMG_BLAST) ~= 0 then return "explosion", raw end
    if bit.band(raw, bit.bor(DMG_CLUB, DMG_CRUSH)) ~= 0 then return "club", raw end
    if IsValid(ply) and ply:IsPlayer() and ply:IsOnGround() then
        local speed = ply:GetVelocity():Length()
        local walk = 200
        pcall(function() walk = ply:GetWalkSpeed() end)
        if speed > walk then return "moving", raw end
    end
    return "bullet", raw
end
function TS_DeathAnim.Select(hit, kind, flags)
    local tb = TS_DeathAnim.AnimTb
    if not tb then return nil end
    flags = flags or {}
    local dbg = TS_DeathAnim.DebugConvar and TS_DeathAnim.DebugConvar:GetBool()
    local cat = "dying"
    if kind == "fire" then
        cat = "fire"
    elseif kind == "explosion" then
        cat = "exp"
    elseif kind == "moving" then
        cat = "moving"
    elseif kind == "club" then
        if hit == HITGROUP_HEAD then
            if flags.neck then cat = "bd_neck" else cat = "bd_head" end
        elseif flags.back then cat = "bd_back" else cat = "club" end
    else
        if hit == HITGROUP_HEAD then
            if flags.neck then cat = "bd_neck" else cat = "bd_head" end
        elseif flags.shotgun then
            cat = "bd_shotgun"
        elseif hit == HITGROUP_CHEST or hit == HITGROUP_STOMACH then
            if flags.pelvis then cat = "bd_pelvis"
            elseif flags.back then cat = "bd_back"
            else cat = "bd_torso" end
        elseif hit == HITGROUP_LEFTARM then
            cat = "bd_larm"
        elseif hit == HITGROUP_RIGHTARM then
            cat = "bd_rarm"
        elseif hit == HITGROUP_LEFTLEG then
            cat = "bd_lleg"
        elseif hit == HITGROUP_RIGHTLEG then
            cat = "bd_rleg"
        else
            cat = "dying"
        end
    end
    local list = tb[cat]
    if not list or #list == 0 then return nil end
    local pick = list[math.random(#list)]
    local pct = 100
    if TS_DeathAnim.CustomEndPos and TS_DeathAnim.CustomEndPos[pick] then
        pct = TS_DeathAnim.CustomEndPos[pick]
    elseif TS_DeathAnim.EndPos and TS_DeathAnim.EndPos[pick] then
        pct = TS_DeathAnim.EndPos[pick]
    end
    if pct < 1 then pct = 1 end
    if pct > 100 then pct = 100 end
    if cat == "club" then pct = pct * (TS_DeathAnim.ClubEndMul or 0.5) end
    if pct < 1 then pct = 1 end
    local headClub = kind == "club" and hit == HITGROUP_HEAD
    local rate = 1
    if headClub then
        rate = (TS_DeathAnim.HeadClub and TS_DeathAnim.HeadClub.Rate) or 0.95
    elseif cat == "bd_head" then
        rate = TS_DeathAnim.HeadRate or 1
    end
    if dbg then print("[TS-DeathAnim] pick=" .. pick .. " cat=" .. cat .. " kind=" .. kind .. " hit=" .. hit .. " frac=" .. (pct / 100) .. " rate=" .. rate .. " gore=" .. tostring(headClub)) end
    return pick, pct / 100, rate, headClub
end
function TS_DeathAnim.HasGround(rag)
    if not IsValid(rag) then return false end
    local start = rag:GetPos() + Vector(0, 0, 10)
    local tr = util.TraceLine({
        start = start,
        endpos = start - Vector(0, 0, TS_DeathAnim.GroundCheck + 10),
        mask = MASK_SOLID,
        filter = rag
    })
    return tr.Hit
end
TS_DeathAnim.ConfigLoaded = true
