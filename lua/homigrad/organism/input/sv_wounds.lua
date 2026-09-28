hg = hg or {}
hg.organism = hg.organism or {}

local CurTime = CurTime
local timer_Create = timer.Create
local table_Insert = table.insert
local table_Sort = table.sort
local IsValid = IsValid

function hg.organism.AddWound(ent, tr, bone, dmgInfo, dmgPos, dmgBlood, inputHole, outputHole)
	local org = ent.organism

	if org.superfighter then return end

	local physBone = bone != -1 and bone or math.random(0, ent:GetPhysicsObjectCount() - 1)
	local bone = ent:TranslatePhysBoneToBone(physBone)

	dmgPos = ent:GetBonePosition(bone)

	if bone and dmgBlood > 0 then
		for i = 1, 2 do
			local bonePos, boneAng = ent:GetBonePosition(bone)

			if !bonePos then return end

			dmgPos = (i == 1 and inputHole[1] or outputHole[1]) or dmgPos

			if i == 2 and !outputHole[1] then continue end
			if i == 1 and !outputHole[1] then dmgBlood = dmgBlood * 2 end

			if dmgInfo:IsDamageType(DMG_BLAST) or dmgInfo:GetAttacker():IsNPC() or (ent:IsPlayer() and ent:InVehicle()) then dmgPos = bonePos end

			local localPos, localAng = WorldToLocal(dmgPos + ((i == 1 and 1 or -1) * tr.HitNormal), (i == 1 and -1 or 1) * tr.Normal:Angle(), bonePos, boneAng)

			if #org.wounds < 30 then
				table_Insert(org.wounds, {dmgBlood / 2, localPos, localAng, ent:GetBoneName(bone), CurTime()})
			else
				if org.wounds[1] then org.wounds[1][1] = org.wounds[1][1] + dmgBlood / 2 end
			end

			table_Sort(org.wounds, function(a, b) return a[1] > b[1] end)

			if #org.wounds <= 30 then
				local wounds = org.wounds

				timer_Create("WoundsSend"..ent:EntIndex(), 0.1, 1, function()
					local owner = org.owner

					if IsValid(owner) then
						owner:SetNetVar("wounds", wounds)
						if IsValid(owner.RagdollDeath) then owner.RagdollDeath:SetNetVar("wounds", wounds) end
					end
				end)
			end
		end
	end
end

function hg.organism.AddWoundManual(ent, dmgBlood, localPos, localAng, bone, time)
	local org = ent.organism

	if org.superfighter then return end

	if isnumber(bone) then bone = ent:GetBoneName(bone) end

	if #org.wounds < 30 then
		table_Insert(org.wounds, {dmgBlood / 2, localPos, localAng, bone, time})
	else
		if org.wounds[1] then org.wounds[1][1] = org.wounds[1][1] + dmgBlood / 2 end
	end

	table_Sort(org.wounds, function(a, b) return a[1] > b[1] end)

	if #org.wounds <= 30 then
		local wounds = org.wounds

		timer_Create("WoundsSend"..ent:EntIndex(), 0.1, 1, function()
			local owner = org.owner

			if IsValid(owner) then
				owner:SetNetVar("wounds", wounds)
				if IsValid(owner.RagdollDeath) then owner.RagdollDeath:SetNetVar("wounds", wounds) end
			end
		end)
	end
end

hook.Add("Player Spawn", "huyhuyhuy22", function(ply)
	if OverrideSpawn then return end

	ply.HitBones = {}
	ply.AddForceRag = {}

	ply.wounds = nil
	ply.arterialwounds = nil

	ply.wounds = {}
	ply.arterialwounds = {}
end)
