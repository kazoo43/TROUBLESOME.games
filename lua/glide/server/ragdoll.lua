local IsValid = IsValid

--- Stores necessary data to respawn a player later,
--- and to restore the health, armor and inventory.
function Glide.StoreSpawnInfo( ply )
    return
end

do
    function Glide.RestoreSpawnInfo( ply, restoreCallback )
        return
    end
end

--- Returns a list of all bone positions/rotations from a player,
--- while making sure those are relative to the world even while inside a vehicle.
local function GetAllBones( ply )
    local veh = ply:GetVehicle()
    local rotation, upAxis

    if IsValid( veh ) then
        rotation = Angle( 0, 270, 0 )
        upAxis = veh:GetUp()
    end

    local max = ply:GetBoneCount() - 1
    local bones = {}
    local pos, ang

    for i = 0, max do
        pos, ang = ply:GetBonePosition( i )

        if pos then
            if rotation then
                pos = veh:WorldToLocal( pos )
                ang = veh:WorldToLocalAngles( ang )

                pos:Rotate( rotation )
                ang:RotateAroundAxis( upAxis, rotation[2] )

                pos = veh:LocalToWorld( pos )
                ang = veh:LocalToWorldAngles( ang )
            end

            bones[i] = { pos, ang }
        end
    end

    return bones
end

--- Apply bone positions obtained from the function above to a ragdoll.
local function PoseRagdollBones( ragdoll, bones, velocity )
    local max = ragdoll:GetPhysicsObjectCount() - 1
    local boneId, bone

    for i = 0, max do
        local phys = ragdoll:GetPhysicsObjectNum( i )

        if IsValid( phys ) then
            phys:SetDamping( 0.3, 10 )
            phys:Wake()

            boneId = ragdoll:TranslatePhysBoneToBone( i )

            if boneId and bones[boneId] then
                bone = bones[boneId]

                phys:SetPos( bone[1], true )
                phys:SetAngles( bone[2] )
            end

            phys:SetVelocity( velocity )
        end
    end
end

function Glide.RagdollPlayer( ply, velocity, unragdollTime )
    return
end

local traceData = {
    mins = Vector( -16, -16, 0 ),
    maxs = Vector( 16, 16, 64 )
}

local function GetFreeSpace( origin )
    local offset = Vector( 0, 0, 20 )
    local rad, tr

    for ang = 0, 360, 30 do
        rad = math.rad( ang )

        offset[1] = math.cos( rad ) * 20
        offset[2] = math.sin( rad ) * 20

        traceData.start = origin + offset
        traceData.endpos = origin

        tr = util.TraceHull( traceData )

        if tr.Hit and not tr.StartSolid then
            return tr.HitPos
        end
    end

    return origin
end

function Glide.UnRagdollPlayer( ply, restoreCallback )
    return
end

hook.Add( "CanTool", "Glide.BlockPlayerRagdolls", function( _, tr )
    if IsValid( tr.Entity ) and tr.Entity.IsGlideRagdoll then
        return false
    end
end )

hook.Add( "CanProperty", "Glide.BlockPlayerRagdolls", function( _, _, ent )
    if ent.IsGlideRagdoll then
        return false
    end
end )

hook.Add( "PlayerDeath", "Glide.CleanupPlayerRagdolls", function( victim )
    if victim.GlideRagdoll then
        Glide.UnRagdollPlayer( victim )
    end
end )

hook.Add( "PlayerDisconnected", "Glide.CleanupPlayerRagdolls", function( ply )
    if ply.GlideRagdoll then
        Glide.UnRagdollPlayer( ply )
    end
end )

hook.Add( "PreCleanupMap", "Glide.CleanupPlayerRagdolls", function()
    for _, ply in player.Iterator() do
        Glide.UnRagdollPlayer( ply )
    end
end )

hook.Add( "EntityTakeDamage", "Glide.RagdollDamage", function( ent, dmginfo )
    if not ent.IsGlideRagdoll then return end

    local ply = ent.GlideRagdollPlayer
    if not IsValid( ply ) then return end

    local spawnData = ply.GlideSpawnData
    if not spawnData then return end

    if spawnData.god then return end
    if spawnData.health < 1 then return end

    if dmginfo:IsDamageType( 1 ) then
        dmginfo:SetDamage( math.ceil( dmginfo:GetDamage() * 0.1 ) )
    end

    local ignore = hook.Run( "EntityTakeDamage", ply, dmginfo )
    if ignore then return end

    local damage = dmginfo:GetDamage()
    if damage < 1 then return end

    spawnData.health = spawnData.health - damage

    if spawnData.health < 1 then
        local attacker = dmginfo:GetAttacker()
        local inflictor = dmginfo:GetInflictor()

        Glide.UnRagdollPlayer( ply, function( restoredPly )
            attacker = IsValid( attacker ) and attacker or restoredPly
            inflictor = IsValid( inflictor ) and inflictor or restoredPly

            restoredPly:SetHealth( 1 )
            restoredPly:TakeDamage( 999, attacker, inflictor )
        end )
    end
end )

hook.Add( "CLoadoutCanGiveWeapons", "Glide.BlockRagdollLoadout", function( ply )
    if ply.GlideBlockLoadout then return false end
end )

hook.Add( "KeyPress", "Glide.LeaveRagdoll", function( ply, key )
    if ply.GlideRagdoll and CurTime() > ply.GlideRagdollTimeout and key ~= IN_USE then
        Glide.UnRagdollPlayer( ply )
    end
end )
