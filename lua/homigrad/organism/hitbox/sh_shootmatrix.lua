hg.organism = hg.organism or {}

local LocalToWorld = LocalToWorld
local table_HasValue = table.HasValue
local table_IsEmpty = table.IsEmpty
local IsValid = IsValid

local scratchHalf, scratchMins = Vector(0, 0, 0), Vector(0, 0, 0)

function hg.organism.ShootMatrix(ent, organs)
	if !organs or !istable(organs) or table_IsEmpty(organs) then return end

	local boxs = {}
	local mins, maxs, matrix
	local pos, ang, center, disOfCenter
	local sphereChunk = 0

	local obbCenter = ent:GetPos()
	obbCenter:Add(ent:OBBCenter())

	for i = 0, ent:GetHitBoxCount(0) - 1 do
		matrix = ent:GetBoneMatrix(ent:GetHitBoxBone(i, 0))

		if !matrix then continue end

		mins, maxs = ent:GetHitBoxBounds(i, 0)
		pos = matrix:GetTranslation()
		ang = matrix:GetAngles()

		center, disOfCenter = hg.organism.GetOBBTransform(pos, ang, mins, maxs, obbCenter, scratchHalf, scratchMins)

		if disOfCenter > sphereChunk then sphereChunk = disOfCenter end

		boxs[#boxs + 1] = {pos, ang, mins, maxs, center}
	end

	local armorEnt

	for nameBone, boneOrgans in pairs(organs) do
		matrix = ent:GetBoneMatrix(ent:LookupBone(nameBone))

		if !matrix then continue end

		pos = matrix:GetTranslation()
		ang = matrix:GetAngles()

		armorEnt = nil

		for key, organ in pairs(boneOrgans) do
			if organ[7] then
				if !armorEnt then
					local owner = ent:IsPlayer() and ent or
						ent:IsRagdoll() and hg.RagdollOwner(ent) or ent

					armorEnt = IsValid(owner) and owner or ent
				end

				if armorEnt.armors and !table_HasValue(armorEnt.armors, organ[1]) then
					continue
				end
			end

			mins = -organ[5]
			maxs = -mins

			center, disOfCenter = hg.organism.GetOBBTransform(pos, ang, mins, maxs, obbCenter, scratchHalf, scratchMins)

			if disOfCenter > sphereChunk then sphereChunk = disOfCenter end

			local oPos, oAng = LocalToWorld(organ[3], organ[4], pos, ang)

			boxs[#boxs + 1] = {oPos, oAng, mins, maxs, center, nameBone, key}
		end
	end

	return boxs, obbCenter, sphereChunk
end

function hg.organism.Trace_Bullet(organs)
	local organ = scratchHalf[6] and organs[scratchHalf[6]][scratchHalf[7]]

	return organ and organ[2] or 0
end
