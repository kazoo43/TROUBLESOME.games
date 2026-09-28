hook.Add("ScalePlayerDamage", "remove-effects", function(ent, hitgroup, dmgInfo)
	if dmgInfo:IsDamageType(DMG_BUCKSHOT + DMG_BULLET + DMG_SLASH) then
		return true
	end
end)

local function plyCommand(ply, cmd)
	local time = CurTime()

	ply.cmdtimer = ply.cmdtimer or time

	if cmd == "soundfade 100 99999" then
		if IsValid(hg.chat) then
			hg.chat:SetRealAlpha(0)

			timer.Create("otrubhuy", 1, 1, function()
				if lply.organism and !lply.organism.otrub then lply:ConCommand("soundfade 0 1") end
				hg.chat:AnimateRealAlpha(255)
			end)
		end
	end

	if ply.cmdtimer < time then
		ply.cmdtimer = time + 0.1

		ply:ConCommand(cmd)
	end
end

hook.Add("HUDShouldDraw", "hg.HUDShouldDraw", function(id)
	if (fakeTimer and fakeTimer - 2 > CurTime()) then
		return false
	end
end)

hook.Add("HG_OnOtrub", "adsadsadhuy!!", function(ply)
	if ply == LocalPlayer() then
		lply:SetDSP(17)
		plyCommand(lply, "soundfade 100 99999")
	end
end)

hook.Add("Player_Death", "adsadsadhuy!!", function(ply)
	if ply == LocalPlayer() then
		lply:SetDSP(17)
		plyCommand(lply, "soundfade 100 99999")
	end
end)

local alivestart = CurTime()
hg.screens = hg.screens or {}
hg.alivecntr = hg.alivecntr or 0

local screens = hg.screens
local file_Delete = file.Delete
local file_Exists = file.Exists
local file_Find = file.Find
local file_CreateDir = file.CreateDir
local file_Write = file.Write

local function remove_imgs()
	if !file_Exists("dreams", "DATA") then return end

	local files = file_Find("dreams/*", "DATA")

	for i, file in pairs(files) do
		file_Delete("dreams/"..file)
	end
end

local disorientationLerp = 0

hook.Add("Player Spawn", "screenshot_game", function(ply)
	if OverrideSpawn then return end

	if ply == lply then
		disorientationLerp = 0

		alivestart = CurTime()
		lply.tried_fixing_limb = nil

		hg.alivecntr = hg.alivecntr + 1

		for i, screen in ipairs(hg.screens) do
			hg.screens[i] = nil
		end

		remove_imgs()
	end
end)

hook.Add("InitPostEntity", "removeshits", function()
	remove_imgs()
end)

hook.Add("Player Disconnected", "removeshits", function()
	remove_imgs()
end)

local screened = 0
local curscreen = 1
local switch = false

hook.Add("PostRender", "screenshot_think", function()
	local org = lply.organism

	if !org or !org.brain or org.otrub or !lply:Alive() then return end

	local part = CurTime() - alivestart

	if part % 60 > 59 and (screened != math.Round(part / 60, 0)) then
		screened = math.Round(part / 60, 0)

		if gui.IsGameUIVisible() or gui.IsConsoleVisible() or IsValid(vgui.GetHoveredPanel()) then return end

		local data = render.Capture({
			format = "jpeg",
			x = 0,
			y = 0,
			w = ScrW(),
			h = ScrH(),
			quality = 1,
		})

		if !data then return end

		local name = "dreams/dream"..hg.alivecntr.."_"..(#screens + 1)..".jpeg"

		if !file_Exists("dreams", "DATA") then file_CreateDir("dreams") end
		file_Write(name, data)

		timer.Simple(1, function()
			screens[#screens + 1] = Material("data/"..name)
		end)
	end
end)

local braindeathstart = CurTime() + 20
local lerpedpart = 0
local lerpedbrain = 0

hook.Add("Post Post Pre Post Processing", "ShowScreens", function()
	local org = lply.organism

	if !lply:Alive() then return end
	if !org or !org.brain then return end

	local part = CurTime() - braindeathstart

	local show_multiki = org.brain > 0.1 and org.otrub

	if show_multiki then
		lerpedbrain = LerpFT(0.05, lerpedbrain, org.brain)

		local time = 40 - (lerpedbrain - 0.1) * 20

		if part % time > time / 3 and curscreen <= #screens and screens[curscreen] and !screens[curscreen]:IsError() then
			switch = true

			local part2 = math.ease.InOutSine(math.sin(((part % time) - time / 3) / (time / 3 * 2) * math.pi))

			lerpedpart = LerpFT(0.1, lerpedpart, part2)

			surface.SetDrawColor(255, 255, 255, math.Clamp(lerpedpart * 50, 0, 255))
			surface.SetMaterial(screens[curscreen])
			surface.DrawTexturedRect(0, 0, ScrW(), ScrH())

			DrawToyTown(4, ScrH())
		else
			if switch then
				curscreen = curscreen == #screens and 1 or curscreen + 1
				switch = false
			end
		end
	else
		braindeathstart = CurTime()
	end
end)

local tabblood = {
	["$pp_colour_addr"] = 0,
	["$pp_colour_addg"] = 0,
	["$pp_colour_addb"] = 0,
	["$pp_colour_brightness"] = 0,
	["$pp_colour_contrast"] = 1,
	["$pp_colour_colour"] = 1,
	["$pp_colour_mulr"] = 0,
	["$pp_colour_mulg"] = 0,
	["$pp_colour_mulb"] = 0,
}

local k1, k2, k3
local ang1 = Angle()
local ang2 = Angle()
local tinnitusSoundFactor
local old = false
local hg_potatopc

local hg_gopro = ConVarExists("hg_gopro") and GetConVar("hg_gopro") or CreateClientConVar("hg_gopro", "0", true, false, "Toggle GoPro-like first-person camera view", 0, 1)

hook.Add("Post Post Pre Post Processing", "organism-effects", function()
	local spect = IsValid(lply:GetNWEntity("spect")) and lply:GetNWEntity("spect")
	local organism = lply:Alive() and lply.organism or (viewmode == 1 and IsValid(spect) and spect.organism) or {}
	local new_organism = lply:Alive() and lply.new_organism or (viewmode == 1 and IsValid(spect) and spect.new_organism) or {}

	if organism.owner == LocalPlayer() then
		if new_organism.otrub and !old then
			hook.Run("HG_OnOtrub", new_organism.owner)
		end

		old = new_organism.otrub
	end

	if !organism then return end

	local alive = lply:Alive() or (spect and spect:Alive())
	local health = (lply:Alive() and lply:Health()) or 100

	if !alive then
		return false
	end

	local org = organism

	if !org.brain then return end

	local adrenaline = org.adrenaline or 0
	local pulse = org.pulse or 70
	local pain = org.pain or 0
	local hurt = org.hurt or 0
	local blood = org.blood or 5000
	local o2 = org.o2 and org.o2[1] or 30
	local brain = org.brain or 0
	local otrub = lply:Alive() and org.otrub or false
	local analgesia = organism.analgesia or 0
	local disorientation = org.disorientation or 0
	local immobilization = org.immobilization or 0
	local incapacitated = org.incapacitated or false
	local critical = org.critical or false

	tinnitusSoundFactor = Lerp(FrameTime() * 2.5, tinnitusSoundFactor or 0, math.min(math.max(lply.tinnitus and (lply.tinnitus - CurTime()) or 0, 0) * 7.5, 120))

	local tinnitusSoundFactor2 = tinnitusSoundFactor + (hook.Run("ModifyTinnitusFactor", tinnitusSoundFactor) or 0)

	local adrenK = math.min(math.max(1 + adrenaline, 1), 1.2)

	local normaldsp = hg_gopro:GetBool() and 55 or 0

	lply:SetDSP(normaldsp)

	if otrub or ((fakeTimer and fakeTimer - 2 > CurTime()) and GetConVar("hg_deathfadeout"):GetBool()) then
		if isnumber(zb.ROUND_STATE) and (zb.ROUND_STATE ~= 1) then
			lply:SetDSP(normaldsp)
			plyCommand(lply, "soundfade "..tinnitusSoundFactor2.." 25")
		elseif lply:Alive() then
			lply:SetDSP(17)
			plyCommand(lply, "soundfade 100 25")
		end
	else
		plyCommand(lply, "soundfade "..tinnitusSoundFactor2.." 25")

		if ((disorientation and disorientation > 3) or (brain and brain > 0.2) or lply.PlayerClassName == "headcrabzombie" or lply:GetNetVar("headcrab")) and lply:Alive() then
			lply:SetDSP(130)
		else
			lply:SetDSP((lply.suiciding and lply:Alive()) and 130 or normaldsp)
		end
	end

	k1 = Lerp(FrameTime() * 15, k1 or 0, math.min(math.min(adrenaline / 1, 2), 1.5))
	k2 = (30 - (o2 or 30)) / 30 + (1 - (consciousnessLerp or 1)) * 1
	k3 = ((5000 / math.max(blood, 1000)) - 1) * 1.5

	DrawSharpen(k1 * 2, k1 * 1)

	local lowpulse = math.max((70 - pulse) / 70, 0) + math.max(3000 * ((math.cos(CurTime() / 2) + 1) / 2 * 0.1 + 1) - (blood * adrenK - 300), 0) / 400

	if (lply.PlayerClassName == "headcrabzombie" or lply:GetNetVar("headcrab")) and lply:Alive() then
		disorientation = disorientation + 100
	end

	disorientation = disorientation + amtflashed * 5

	local amount = 1 - math.Clamp(lowpulse + disorientation / 4 + k2 * 2, 0, 1)

	disorientationLerp = LerpFT(disorientation > disorientationLerp and 1 or 0.01, disorientationLerp, math.max(lply.suiciding and 1.5 or 0, disorientation))

	if (disorientationLerp > 1) and lply:Alive() or brain > 0 then
		local add2 = disorientationLerp - 1

		if !brain_motionblur and lply.PlayerClassName ~= "headcrabzombie" then
			DrawMotionBlur(0.15 - math.Clamp(add2 / 1, 0, 0.1), add2 * 2, 0.001)
		end

		if disorientationLerp > 2 then
			local add = (disorientationLerp - 2) * 2
			local time = CurTime() * 3
			local mul = math.Clamp(add / 16, 0, 0.2)

			ang1[1] = math.cos(time) + math.sin(time * 0.5) + math.sin((time - 5) * 1.1)
			ang1[2] = math.sin(time) + math.cos(time * 0.5) + math.sin((time + 1) * 1.1)

			ViewPunch(ang1 * mul * 0.125)

			ang2[3] = math.Rand(-15, 15) * mul
		end
	end

	if (pain > 0) or (hurt > 0) or (immobilization > 0) or (brain > 0) then
		local newpain = pain - 10

		if newpain > 0 then
			local blur = math.max((newpain / 30 + brain * 10), 0) / 30

			if blur > 0 then
				DrawMaterialOverlay("sprites/mat_jack_hmcd_scope_aberration", blur)
			end
		end
	end

	hg_potatopc = hg_potatopc or hg.ConVars.potatopc

	local potato = hg_potatopc:GetBool()

	if (k1 > 0) or (k2 > 0) or (k3 > 0) or brain > 0 then
		if !potato then
			DrawToyTown(2, (k3 * 3 + k2 * 1 + brain * 10) * ScrH() / 2)
		end
	end

	if analgesia > 1 then
		DrawMaterialOverlay("particle/warp4_warp_noz", -(analgesia - 0.5) * math.sin(CurTime()) * 5 / 150)
	end

	tabblood["$pp_colour_colour"] = Lerp(FrameTime() * 30, tabblood["$pp_colour_colour"], (blood / 5000) * (potato and (blood / 5000) or 1) + (math.max(org.analgesia - 1, 0) * math.sin(CurTime()) * 5))
	tabblood["$pp_colour_brightness"] = Lerp(FrameTime() * 30, tabblood["$pp_colour_brightness"], (potato and (blood / 5000 - 1) / 2 or 0))
	tabblood["$pp_colour_addb"] = !org.otrub and ((potato and k2 / 5 or 0)) or 0

	DrawColorModify(tabblood)

	local ent = IsValid(lply.FakeRagdoll) and lply.FakeRagdoll or lply

	if IsValid(ent) and ent.Blinking and lply:Alive() then
		surface.SetDrawColor(0, 0, 0, 255)

		if amtflashed and amtflashed > 0.1 and amtflashed < 0.8 and ent.Blinking > 0.1 then
			surface.DrawRect(-1, -1, ScrW() + 1, ScrH() + 1)
		end
	end
end)
