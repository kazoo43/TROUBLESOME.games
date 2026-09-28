timeHuy = timeHuy or 0

local ent = NULL
local model = "models/Humans/group01/Female_03.mdl"
local pos = Vector(0, 0, 0)
local bones = {}
local tracePoses = {}
local hitBoxs = {}
local dmg = 0
local size = 0
local matpos
local matang
local traveltime = 5
local hitorgans = {}
local angle = Angle(25, 0, 0)
local ricochets = {}

local IsValid = IsValid
local LocalToWorld = LocalToWorld
local LerpVector = LerpVector

if IsValid(csmodel) then
	csmodel:Remove()
end

csmodel = ClientsideModel("models/Humans/group01/Female_03.mdl", RENDERMODE_TRANSCOLOR)
csmodel:SetNoDraw(true)

if IsValid(skeletmodel) then
	skiletmodel:Remove()
end

skiletmodel = ClientsideModel("models/player/skeleton.mdl", RENDERMODE_TRANSCOLOR)
skiletmodel:SetNoDraw(true)
skiletmodel:SetSkin(2)
skiletmodel:AddEffects(EF_BONEMERGE)
skiletmodel:SetParent(csmodel)

if IsValid(bulletmodel) then
	bulletmodel:Remove()
end

bulletmodel = ClientsideModel("models/bullets/w_pbullet1.mdl", RENDERMODE_TRANSCOLOR)
bulletmodel:SetNoDraw(true)

local organs, boxs, pos, sphere, posa
local vecFull = Vector(1, 1, 1)
local angZero = Angle(0, 0, 0)
local bone0 = Vector()

local hg_max_hitshow = ConVarExists("hg_max_hitshow") and GetConVar("hg_max_hitshow") or CreateClientConVar("hg_max_hitshow", 40, true, false, "how many hits to track on your local pc (very bad idea to put this to more than 60)", 0, 150)

hg.hits = hg.hits or {}

local iter = 1
local inf
local attacker

local function startPlayingHit(i)
	local index = iter

	tracePoses = hg.hits[index].tracePoses
	ent = hg.hits[index].ent
	hitBoxs = hg.hits[index].hitBoxs
	dmg = hg.hits[index].dmg
	size = hg.hits[index].size

	traveltime = hg.hits[index].traveltime
	attacker = hg.hits[index].att
	model = hg.hits[index].model
	bone0 = hg.hits[index].bone0
	bones = hg.hits[index].bones
	ricochets = hg.hits[index].ricochets
	local basebone = hg.hits[index].basebone
	inf = hg.hits[index].inf

	csmodel:SetPos(bone0:GetTranslation())
	csmodel:SetModel(model)
	csmodel.armors = hg.hits[index].armors or {}

	organs = hg.organism.GetHitBoxOrgans(model, csmodel)

	boxs, pos, sphere = hg.organism.ShootMatrix(csmodel, organs)

	if boxs == nil then return end

	hitorgans = {}

	for i = 1, #boxs do
		local box = boxs[i]
		local organ = box[6] and organs[box[6]][box[7]]

		if organ and hitBoxs[i] then hitorgans[i] = organ[1] end
	end

	for i, func in pairs(csmodel:GetCallbacks("BuildBonePositions")) do
		csmodel:RemoveCallback("BuildBonePositions", i)
	end

	csmodel:AddCallback("BuildBonePositions", function()
		for i = 0, csmodel:GetBoneCount() do
			if !bones[i] or !csmodel:GetBoneMatrix(i) then continue end

			bones[i]:SetScale(vecFull)
			csmodel:SetBoneMatrix(i, bones[i])
		end
	end)

	timeHuy = 0
end

hook.Add("Player_Death", "wowww", function(ply)
	if ply != LocalPlayer() or #hg.hits == 0 then return end

	iter = #hg.hits

	if iter > 0 then
		startPlayingHit(iter)
	end
end)

hook.Add("Player Spawn", "removehuys", function(ply)
	if ply != LocalPlayer() then return end

	hg.hits = {}
end)

function draw.RotatedText(text, x, y, font, color, ang)
	render.PushFilterMag(TEXFILTER.ANISOTROPIC)
	render.PushFilterMin(TEXFILTER.ANISOTROPIC)

	local m = Matrix()
	m:Translate(Vector(x, y, 0))
	m:Rotate(Angle(0, ang, 0))

	surface.SetFont(font)
	local w, h = surface.GetTextSize(text)

	m:Translate(-Vector(w / 2, h / 2, 0))

	cam.PushModelMatrix(m)
		draw.DrawText(text, font, 0, 0, color)
	cam.PopModelMatrix()

	render.PopFilterMag()
	render.PopFilterMin()
end

function hg.DeathCamAvailable(ply)
	return timeHuy and ((timeHuy + traveltime) > CurTime()) and #hg.hits > 0
end

local delta = 0

hook.Add("CreateMove", "delta-counting-hg", function(cmd)
	delta = cmd:GetMouseWheel()
end)

local len = 50

function hg.DeathCam(ply, origin, angles, fov, znear, zfar)
	if lply:Alive() then return end

	len = math.Clamp(len - delta * 10, 10, 50)

	if timeHuy == 0 then timeHuy = CurTime() end
	if lply:KeyDown(IN_RELOAD) then timeHuy = nil hg.hits = {} end

	if !timeHuy or !((timeHuy + traveltime) > CurTime()) then return end

	local tbl = tracePoses

	local part = 1 - ((timeHuy + traveltime) - CurTime()) / traveltime

	local firstpoint = tbl[math.min(math.floor(#tbl * part) + 1, #tbl)]
	local secondpoint = tbl[math.min(math.floor(#tbl * part) + 2, #tbl)]

	local nextfirstpoint = tbl[math.min(math.floor(#tbl * part) + 2, #tbl)]
	local nextsecondpoint = tbl[math.min(math.floor(#tbl * part) + 3, #tbl)]

	if !firstpoint or !secondpoint or !nextfirstpoint or !nextsecondpoint then return end

	local point1 = LerpVector((#tbl * part) - math.floor(#tbl * part), firstpoint, nextfirstpoint)
	local point2 = LerpVector((#tbl * part) - math.floor(#tbl * part), secondpoint, nextsecondpoint)

	return {
		origin = point2 + angles:Forward() * -len,
		angles = angles,
		fov = fov,
		drawviewer = true,
	}
end

local colblack = Color(0, 0, 0, 255)
local colblacka = Color(22, 22, 22, 255)
local colyellow = Color(255, 217, 0)
local white = Color(255, 255, 255)
local attpressed
local attpressed2
local mathuy = Material("color")

hook.Add("HUDPaint", "homigrad-wound-debug", function()
	if lply:Alive() then return end

	if timeHuy == 0 then timeHuy = CurTime() end

	if lply:KeyDown(IN_RELOAD) then timeHuy = nil hg.hits = {} end

	if (lply:KeyDown(IN_ATTACK2) or lply:KeyDown(IN_MOVERIGHT)) and timeHuy and #hg.hits != 0 then
		if !attpressed then
			local next_ = iter + 1
			iter = next_ > #hg.hits and 1 or next_
			startPlayingHit(i)
			attpressed = true
		end
	else
		attpressed = nil
	end

	if (lply:KeyDown(IN_ATTACK) or lply:KeyDown(IN_MOVELEFT)) and timeHuy and #hg.hits != 0 then
		if !attpressed2 then
			local next_ = iter - 1
			iter = next_ < 1 and #hg.hits or next_
			startPlayingHit(i)
			attpressed2 = true
		end
	else
		attpressed2 = nil
	end

	if !timeHuy or !((timeHuy + traveltime) > CurTime()) then return end

	local tbl = tracePoses

	local part = 1 - ((timeHuy + traveltime) - CurTime()) / traveltime
	local alpha = ((timeHuy + traveltime) - CurTime()) / 0.2

	local firstpoint = tbl[math.min(math.floor(#tbl * part) + 1, #tbl)]
	local secondpoint = tbl[math.min(math.floor(#tbl * part) + 2, #tbl)]

	local nextfirstpoint = tbl[math.min(math.floor(#tbl * part) + 2, #tbl)]
	local nextsecondpoint = tbl[math.min(math.floor(#tbl * part) + 3, #tbl)]

	if !firstpoint or !secondpoint or !nextfirstpoint or !nextsecondpoint then return end

	local point1 = LerpVector((#tbl * part) - math.floor(#tbl * part), firstpoint, nextfirstpoint)
	local point2 = LerpVector((#tbl * part) - math.floor(#tbl * part), secondpoint, nextsecondpoint)

	colblack.a = 255 * alpha

	angle = angle + Angle(0, 0.25, 0)

	cam.Start3D()

		render.SetStencilWriteMask(0xFF)
		render.SetStencilTestMask(0xFF)
		render.SetStencilReferenceValue(0)
		render.SetStencilCompareFunction(STENCIL_ALWAYS)
		render.SetStencilPassOperation(STENCIL_KEEP)
		render.SetStencilFailOperation(STENCIL_KEEP)
		render.SetStencilZFailOperation(STENCIL_KEEP)
		render.ClearStencil()

		render.SetStencilEnable(true)
		render.SetStencilReferenceValue(1)
		render.SetStencilCompareFunction(STENCIL_ALWAYS)
		render.SetStencilPassOperation(STENCIL_REPLACE)

		csmodel:DrawModel()

		render.SetStencilCompareFunction(STENCIL_EQUAL)
		render.SetStencilPassOperation(STENCIL_INCR)
		render.SetStencilZFailOperation(STENCIL_INCR)

		local huyalpha = alpha * 0.2 / traveltime
		huyalpha = huyalpha > 0.2 and 1 or huyalpha / 0.2

		render.SetMaterial(mathuy)
		render.DrawSphere(point2, 7 * huyalpha, 50, 50, colblacka)

		render.SetStencilReferenceValue(2)
		render.SetStencilPassOperation(STENCIL_KEEP)
		render.SetStencilZFailOperation(STENCIL_KEEP)
		render.SetStencilCompareFunction(STENCIL_EQUAL)
		render.ClearBuffersObeyStencil(0, 0, 0, 0, true)

	cam.Start2D()
		surface.SetDrawColor(155, 0, 0, 15)
		surface.DrawTexturedRect(0, 0, ScrW(), ScrH(), 0)
	cam.End2D()

	cam.Start2D()
		surface.SetDrawColor(155, 0, 0, 95)
		surface.DrawTexturedRect(0, 0, ScrW(), ScrH(), 0)
	cam.End2D()

	organs = hg.organism.GetHitBoxOrgans(model, csmodel)
	boxs, pos, sphere = hg.organism.ShootMatrix(csmodel, organs)

	for i = 1, #boxs do
		local box = boxs[i]
		local organ = box[6] and organs[box[6]][box[7]]

		if !hitBoxs[i] then continue end

		local col = Color((organ and organ[6] or white):Unpack())
		col.a = 50

		render.DrawWireframeBox(box[1], box[2], box[3], box[4], col, false)
	end

	render.SetStencilEnable(false)

	white.r = 255
	white.g = 255
	white.b = 255
	white.a = 255

	render.SetColorMaterial()

	render.DrawBox(nextfirstpoint, (nextsecondpoint - nextfirstpoint):Angle(), -Vector(0, size, size), Vector((nextsecondpoint - nextfirstpoint):Length(), size * 0.9, size * 0.9), colyellow)
	render.DrawWireframeBox(nextfirstpoint, (nextsecondpoint - nextfirstpoint):Angle(), -Vector(0, size * 0.9, size * 0.9), Vector((nextsecondpoint - nextfirstpoint):Length(), size * 0.9, size * 0.9), colyellow)

	for i = 1, #tbl - 1 do
		render.DrawWireframeBox(tbl[i], (tbl[i + 1] - tbl[i]):Angle(), -Vector(0, size * 0.9, size * 0.9), Vector((tbl[i + 1] - tbl[i]):Length(), size * 0.9, size * 0.9), Color(0, 0, 0, 100))
	end

	cam.End3D()

	draw.SimpleText("R to skip.", "HomigradFontBig", ScrW() / 3 * 2, ScrH() / 7, color_white)
	draw.SimpleText("Hit "..tostring(iter).." of "..tostring(#hg.hits).." by "..inf.." from "..attacker, "HomigradFontBig", ScrW() / 3 * 2, ScrH() / 10, color_white)
end)
