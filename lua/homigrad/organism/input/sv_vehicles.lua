hg = hg or {}

local LocalToWorld = LocalToWorld
local WorldToLocal = WorldToLocal
local util_IntersectRayWithOBB = util.IntersectRayWithOBB
local debugoverlay_BoxAngles = debugoverlay.BoxAngles
local debugoverlay_Line = debugoverlay.Line
local ents_GetAll = ents.GetAll

local hg_developer = ConVarExists("hg_developer") and GetConVar("hg_developer") or CreateConVar("hg_developer", 0, FCVAR_SERVER_CAN_EXECUTE, "Toggle developer mode (enables damage traces)", 0, 1)

function hg.VehicleHitFunc(ent, tr, bullet, details)
	local maxdmg = 0
	local penetration = true

	for i, detail in pairs(details) do
		local lpos, lang, mins, maxs = detail.lpos, detail.lang, detail.mins, detail.maxs

		if detail.boxcalc then
			lpos, lang, mins, maxs = detail.boxcalc(ent)
		end

		if !lpos then continue end

		local pos, ang = LocalToWorld(lpos, lang, ent:GetPos(), ent:GetAngles())

		local hitpos, hitnormal, frac = util_IntersectRayWithOBB(tr.HitPos, tr.Normal * 1000, pos, ang, mins, maxs)

		debugoverlay_BoxAngles(pos, mins, maxs, ang, 1, color_white)
		debugoverlay_Line(tr.HitPos, tr.HitPos + tr.Normal * 1000, 1, color_white, true)

		if hitpos then
			maxdmg = math.max(maxdmg, detail.dmgmul)
			penetration = penetration and detail.penetration < bullet.Penetration
		end
	end

	return penetration, maxdmg
end

local defaultEngineMins = Vector(-25, -35, -8)
local defaultEngineMaxs = Vector(35, 35, 35)
local defaultEngineOffset = Vector(65, 0, 0)
local angZero = Angle(0, 0, 0)

hg.vehicledetails = {
	["prop_vehicle_prisoner_pod"] = {},
	["default"] = {
		{
			name = "engine",
			dmgmul = 1,
			penetration = 20,
			boxcalc = function(ent)
				local engineoffset = lpos

				if ent.IsGlideVehicle then
					if ent.wheelCount >= 2 then
						local w1 = ent.wheels[1]
						local w2 = ent.wheels[2]

						local middle = (w2:GetPos() - w1:GetPos()) * 0.5 + w1:GetPos()

						local lpos, _ = WorldToLocal(middle, angle_zero, ent:GetPos(), ent:GetAngles())

						engineoffset = lpos
					end
				end

				return engineoffset, angZero, defaultEngineMins, defaultEngineMaxs
			end,
		},
	},
	["gtav_infernus"] = {
		{
			name = "engine",
			dmgmul = 1,
			penetration = 20,
			lpos = Vector(-65, 0, 5),
			lang = Angle(0, 0, 0),
			mins = Vector(-25, -35, -12),
			maxs = Vector(35, 35, 10),
		},
	},
	["gtav_dukes"] = {
		{
			name = "engine",
			dmgmul = 1,
			penetration = 20,
			lpos = Vector(65, 0, 0),
			lang = Angle(0, 0, 0),
			mins = Vector(-25, -35, -12),
			maxs = Vector(35, 35, 10),
		},
	},
}

function hg.GetVehicleDetails(ent)
	return hg.vehicledetails[ent:GetClass()] or hg.vehicledetails["default"]
end

function hg.VehiclePenetration(ent, tr, bullet)
	local details = hg.GetVehicleDetails(ent)

	return hg.VehicleHitFunc(ent, tr, bullet, details)
end

hook.Add("Think", "jajaja", function()
	if !hg_developer:GetBool() then return end

	for i, ent in pairs(ents_GetAll()) do
		if !ent:IsVehicle() then continue end

		local details = hg.GetVehicleDetails(ent)

		if !details then continue end

		for i, detail in pairs(details) do
			local lpos, lang, mins, maxs = detail.lpos, detail.lang, detail.mins, detail.maxs

			if detail.boxcalc then
				lpos, lang, mins, maxs = detail.boxcalc(ent)
			end

			if !lpos then continue end

			local pos, ang = LocalToWorld(lpos, lang, ent:GetPos(), ent:GetAngles())

			debugoverlay_BoxAngles(pos, mins, maxs, ang, 0.1, color_white)
		end
	end
end)
