local MODE = MODE
MODE.name = "criresp"

local bgMat = Material("criresp/backgrnd.png")
local flagMat = Material("criresp/flaguus.png")
local gradientL = Material("vgui/gradient-l")

surface.CreateFont("CRI_Huge", {font = "Ethnocentric", size = ScreenScale(30), weight = 500, antialias = true})
surface.CreateFont("CRI_Title", {font = "Ethnocentric", size = ScreenScale(20), weight = 500, antialias = true})
surface.CreateFont("CRI_MenuItem", {font = "Ethnocentric", size = ScreenScale(16), weight = 500, antialias = true})
surface.CreateFont("CRI_Btn", {font = "Ethnocentric", size = ScreenScale(10), weight = 500, antialias = true})
surface.CreateFont("CRI_Med", {font = "Ethnocentric", size = ScreenScale(8), weight = 400, antialias = true})
surface.CreateFont("CRI_Small", {font = "Ethnocentric", size = ScreenScale(6), weight = 400, antialias = true})
surface.CreateFont("CRI_Tiny", {font = "Ethnocentric", size = ScreenScale(4.5), weight = 400, antialias = true})

local criRed = Color(200, 25, 25)
local criRedDark = Color(120, 15, 15)
local criShadow = Color(60, 20, 120, 180)
local criPanel = Color(18, 4, 4, 215)
local criPanelLight = Color(55, 12, 12, 230)
local criWhite = Color(240, 240, 240)
local criDim = Color(190, 150, 150, 200)

local sndClick, sndHover = "shitty/tap_depress.wav", "shitty/tap-resonant.wav"

--;; если кому то в заебень ждать пока кто то включит режим чтоб вы могли все настроить
local cv_music = CreateClientConVar("criresp_menumusic", "1", true, false, "Crisis Response menu music", 0, 1)
local cv_musicvol = CreateClientConVar("criresp_menumusic_vol", "60", true, false, "Crisis Response menu music volume", 0, 100)
local cv_loadout = CreateClientConVar("criresp_loadout", "0", true, false, "Crisis Response SWAT primary (0 = random)")
local cv_gear = CreateClientConVar("criresp_gear", "1 2 3 5", true, false, "Crisis Response SWAT equipment")
local cv_groups = CreateClientConVar("criresp_bodygroups", "", true, false, "Crisis Response SWAT bodygroups")


local menuMusic

local function StopMenuMusic()
	if IsValid(menuMusic) then menuMusic:Stop() end
	menuMusic = nil
end

local function PlayMenuMusic()
	StopMenuMusic()
	if not cv_music:GetBool() then return end

	sound.PlayFile("sound/criresps/cri_mainmenu.mp3", "noblock", function(station)
		if not IsValid(station) then return end
		station:EnableLooping(true)
		station:SetVolume(cv_musicvol:GetInt() / 100)
		station:Play()
		menuMusic = station
	end)
end

local function SendCustomization()
	local gear = {}
	for _, s in ipairs(string.Explode(" ", cv_gear:GetString())) do
		local n = tonumber(s)
		if n then table.insert(gear, n) end
	end

	net.Start("criresp_custom")
		net.WriteUInt(math.Clamp(cv_loadout:GetInt(), 0, 255), 8)
		net.WriteString(cv_groups:GetString())
		net.WriteUInt(math.min(#gear, 15), 4)
		for i = 1, math.min(#gear, 15) do
			net.WriteUInt(gear[i], 8)
		end
	net.SendToServer()
end


local iconCache = {}

local function ItemIcon(class, override)
	if iconCache[class] ~= nil then
		return iconCache[class][1], iconCache[class][2]
	end

	local wep = weapons.GetStored(class)
	local ent = scripted_ents.GetStored(class)

	local path, boxed

	if override then
		path, boxed = override, true
	elseif wep and wep.WepSelectIcon2 and not isnumber(wep.WepSelectIcon2) and wep.WepSelectIcon2.GetName then
		path = wep.WepSelectIcon2:GetName() .. ".png"
		boxed = tobool(wep.WepSelectIcon2box)
	elseif wep and isstring(wep.IconOverride) then
		path = wep.IconOverride
		boxed = tobool(wep.WepSelectIcon2box)
	elseif ent and ent.t and isstring(ent.t.IconOverride) then
		path, boxed = ent.t.IconOverride, true
	end

	local mat
	if path then
		mat = Material(path, "smooth mips")
		if mat:IsError() then mat = nil end
	end

	if not mat then
		local p = "vgui/entities/" .. class
		if file.Exists("materials/" .. p .. ".png", "GAME") then
			mat, boxed = Material(p .. ".png", "smooth mips"), true
		elseif file.Exists("materials/" .. p .. ".vmt", "GAME") then
			mat, boxed = Material(p), true
		end
	end

	iconCache[class] = {mat or false, boxed or false}
	return mat or false, boxed or false
end

local function WepModel(class)
	local wep = weapons.Get(class)
	local mdl = wep and wep.WorldModel
	return (mdl and mdl ~= "") and mdl or "models/weapons/w_pistol.mdl"
end


local function BoxButton(parent, text, onClick)
	local b = vgui.Create("DButton", parent)
	b:SetText("")
	b.hover = 0
	b.OnCursorEntered = function() surface.PlaySound(sndHover) end
	b.Paint = function(self, w, h)
		self.hover = Lerp(FrameTime() * 8, self.hover, self:IsHovered() and 1 or 0)
		local hv = self.hover

		surface.SetDrawColor(Lerp(hv, 43, 115), Lerp(hv, 43, 20), Lerp(hv, 43, 20), 215)
		surface.DrawRect(0, 0, w, h)
		surface.SetDrawColor(0, 0, 0, 60)
		surface.DrawRect(0, h - 3, w, 3)
		surface.SetDrawColor(criRed)
		surface.DrawRect(0, 0, 4 + hv * 6, h)

		draw.SimpleText(string.upper(text), "CRI_Btn", 22 + hv * 12, h / 2, criWhite, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
	end
	b.DoClick = function()
		surface.PlaySound(sndClick)
		onClick()
	end
	return b
end

local function SmallButton(parent, text, onClick)
	local b = vgui.Create("DButton", parent)
	b:SetText("")
	b.hover = 0
	b.OnCursorEntered = function() surface.PlaySound(sndHover) end
	b.Paint = function(self, w, h)
		self.hover = Lerp(FrameTime() * 8, self.hover, self:IsHovered() and 1 or 0)
		local hv = self.hover

		surface.SetDrawColor(Lerp(hv, 43, 115), Lerp(hv, 43, 20), Lerp(hv, 43, 20), 215)
		surface.DrawRect(0, 0, w, h)
		surface.SetDrawColor(0, 0, 0, 60)
		surface.DrawRect(0, h - 3, w, 3)

		draw.SimpleText(string.upper(text), "CRI_Small", w / 2, h / 2, criWhite, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
	b.DoClick = function()
		surface.PlaySound(sndClick)
		onClick()
	end
	return b
end

local function CriBar(parent, text)
	local bar = vgui.Create("DPanel", parent)
	bar:Dock(TOP)
	bar:SetTall(ScreenScale(15))
	bar:DockMargin(0, 0, 0, 8)
	bar.Paint = function(self, w, h)
		surface.SetDrawColor(60, 12, 12, 220)
		surface.DrawRect(0, 0, w, h)
		surface.SetDrawColor(criRed)
		surface.DrawRect(0, h - 3, w, 3)
		draw.SimpleText(string.upper(text), "CRI_Small", w / 2, h / 2 - 1, criWhite, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
	return bar
end

local function CriRow(parent, label)
	local row = vgui.Create("DPanel", parent)
	row:Dock(TOP)
	row:SetTall(ScreenScale(22))
	row:DockMargin(0, 0, 0, 8)
	row.Paint = function(self, w, h)
		surface.SetDrawColor(43, 43, 43, 180)
		surface.DrawRect(0, 0, w, h)
		surface.SetDrawColor(47, 47, 47, 160)
		surface.DrawRect(0, h - 3, w, 3)
		draw.SimpleText(label, "CRI_Small", 12, h / 2, criWhite, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
	end
	return row
end


local function CriToggle(parent, getState, onClick)
	local toggle = vgui.Create("DButton", parent)
	toggle:SetText("")
	toggle:SetWide(60)
	toggle:Dock(RIGHT)
	toggle:DockMargin(0, 15, 10, 15)
	local anim = getState() and 1 or 0
	toggle.Paint = function(self, w, h)
		anim = Lerp(FrameTime() * 8, anim, getState() and 1 or 0)

		local bgColor = Color(
			Lerp(anim, 180, 80),
			Lerp(anim, 30, 120),
			Lerp(anim, 30, 50)
		)

		draw.RoundedBox(0, 0, 0, w, h, Color(28, 28, 28))
		draw.RoundedBox(0, 2, 2, w - 4, h - 4, Color(0, 0, 0, 30))

		local slsize = h - 10
		local slPos = Lerp(anim, 5, w - slsize - 5)
		draw.RoundedBox(0, slPos, 5, slsize, slsize, bgColor)
		surface.SetDrawColor(0, 0, 0, Lerp(anim, 150, 40))
		surface.DrawRect(slPos, slsize + 3, slsize, 2)
	end
	toggle.OnCursorEntered = function() surface.PlaySound(sndHover) end
	toggle.DoClick = function()
		surface.PlaySound(sndClick)
		onClick()
	end
	return toggle
end

local function CriArrows(row, getMax, getVal, setVal, getLabel)
	local function arrow(txt, dir)
		local b = vgui.Create("DButton", row)
		b:SetText("")
		b:SetWide(ScreenScale(14))
		b:Dock(RIGHT)
		b:DockMargin(3, 6, txt == ">" and 10 or 3, 6)
		b.Paint = function(self, w, h)
			surface.SetDrawColor(self:IsHovered() and 90 or 15, self:IsHovered() and 20 or 2, self:IsHovered() and 20 or 2, 245)
			surface.DrawRect(0, 0, w, h)
			draw.SimpleText(txt, "CRI_Small", w / 2, h / 2, criWhite, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end
		b.OnCursorEntered = function() surface.PlaySound(sndHover) end
		b.DoClick = function()
			surface.PlaySound(sndClick)
			setVal((getVal() + dir + getMax()) % getMax())
		end
		return b
	end

	arrow(">", 1)

	local val = vgui.Create("DPanel", row)
	val:SetWide(ScreenScale(52))
	val:Dock(RIGHT)
	val:DockMargin(3, 6, 0, 6)
	val.Paint = function(self, w, h)
		surface.SetDrawColor(15, 2, 2, 245)
		surface.DrawRect(0, 0, w, h)
		draw.SimpleText(getLabel(), "CRI_Small", w / 2, h / 2, criWhite, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end

	arrow("<", -1)
end

local function FitLabel(label, maxw)
	surface.SetFont("CRI_Small")
	if surface.GetTextSize(label) <= maxw then
		return {{label, "CRI_Small"}}
	end

	local words = string.Explode(" ", label)
	if #words >= 2 then
		local best, bestw
		for i = 1, #words - 1 do
			local l1 = table.concat(words, " ", 1, i)
			local l2 = table.concat(words, " ", i + 1)
			local m = math.max(surface.GetTextSize(l1), surface.GetTextSize(l2))
			if not bestw or m < bestw then
				bestw, best = m, {l1, l2}
			end
		end

		local font = bestw <= maxw and "CRI_Small" or "CRI_Tiny"
		return {{best[1], font}, {best[2], font}}
	end

	return {{label, "CRI_Tiny"}}
end

local function Tile(parent, class, iconOverride, label, isSel, onClick)
	local t = vgui.Create("DButton", parent)
	t:SetText("")
	t.hover = 0

	local labelH = ScreenScale(13)

	local mat, boxed
	if class then mat, boxed = ItemIcon(class, iconOverride) end

	if class and not mat then
		local ico = vgui.Create("SpawnIcon", t)
		ico:SetMouseInputEnabled(false)
		ico:SetModel(WepModel(class))
		t.PerformLayout = function(self, w, h)
			ico:SetPos(4, 4)
			ico:SetSize(w - 8, h - labelH - 6)
		end
	end

	t.Paint = function(self, w, h)
		self.hover = Lerp(FrameTime() * 8, self.hover, self:IsHovered() and 1 or 0)
		draw.RoundedBox(4, 0, 0, w, h, isSel() and Color(90, 15, 15, 235) or Color(20, 5, 5, 205))

		if mat then
			surface.SetDrawColor(255, 255, 255)
			surface.SetMaterial(mat)
			local ih = h - labelH - 8

			if boxed then
				local side = math.min(w - 8, ih)
				surface.DrawTexturedRect(w / 2 - side / 2, 4 + (ih - side) / 2, side, side)
			else
				local iw = math.min(w - 8, ih * 1.7)
				local realh = iw / 1.7
				surface.DrawTexturedRect(w / 2 - iw / 2, 4 + (ih - realh) / 2, iw, realh)
			end
		end
	end

	t.PaintOver = function(self, w, h)
		if not class then
			draw.SimpleText("?", "CRI_Title", w / 2, (h - labelH) / 2, criDim, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end

		surface.SetDrawColor(isSel() and criRed or Color(255, 255, 255, 50 + self.hover * 150))
		surface.DrawOutlinedRect(1, 1, w - 2, h - 2, 2)

		self.labelLines = self.labelLines or FitLabel(label, w - 6)

		if #self.labelLines == 1 then
			draw.SimpleText(self.labelLines[1][1], self.labelLines[1][2], w / 2, h - labelH / 2 - 2, criWhite, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		else
			draw.SimpleText(self.labelLines[1][1], self.labelLines[1][2], w / 2, h - labelH + ScreenScale(3) - 2, criWhite, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			draw.SimpleText(self.labelLines[2][1], self.labelLines[2][2], w / 2, h - ScreenScale(4) - 2, criWhite, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end
	end

	t.OnCursorEntered = function() surface.PlaySound(sndHover) end
	t.DoClick = function()
		surface.PlaySound(sndClick)
		onClick()
	end
	return t
end


local menuPanel
local readyN, readyT = 0, 0

local function OpenMenu()
	if IsValid(menuPanel) then menuPanel:Remove() end

	local scrw, scrh = ScrW(), ScrH()
	local headerH = scrh * 0.15

	local pnl = vgui.Create("EditablePanel")
	pnl:SetSize(scrw, scrh)
	pnl:MakePopup()
	pnl:SetKeyboardInputEnabled(false)
	pnl.state = "main"
	pnl.px, pnl.py = 0, 0
	pnl:SetAlpha(0)
	pnl:AlphaTo(255, 0.7, 0)
	menuPanel = pnl

	PlayMenuMusic()

	pnl.Paint = function(self, w, h)
		local mx, my = input.GetCursorPos()
		self.px = Lerp(FrameTime() * 3, self.px, ((mx / w) - 0.5) * -22)
		self.py = Lerp(FrameTime() * 3, self.py, ((my / h) - 0.5) * -14)

		surface.SetDrawColor(255, 255, 255)
		surface.SetMaterial(bgMat)
		surface.DrawTexturedRect(-28 + self.px, -28 + self.py, w + 56, h + 56)

		surface.SetDrawColor(0, 0, 0, 110)
		surface.DrawRect(0, 0, w, h)

		surface.SetMaterial(gradientL)
		surface.SetDrawColor(12, 2, 2, 235)
		surface.DrawTexturedRect(0, 0, w * 0.8, h)
		surface.SetDrawColor(140, 10, 10, 55)
		surface.DrawTexturedRect(0, 0, w * 0.45, h)

		surface.SetDrawColor(10, 0, 0, 165)
		surface.DrawRect(0, 0, w, headerH)
		surface.SetDrawColor(criRed)
		surface.DrawRect(0, headerH - 3, w, 3)

		draw.SimpleText("CRISIS RESPONSE", "CRI_Huge", w * 0.5 + 4, headerH * 0.5 + 4, criShadow, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		draw.SimpleText("CRISIS RESPONSE", "CRI_Huge", w * 0.5, headerH * 0.5, criRed, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		draw.SimpleText("Z-CITY", "CRI_Med", w * 0.99, headerH - ScreenScale(8), criRedDark, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)

		if self.state == "waiting" then
			local wa = math.ease.OutCubic(math.Clamp((CurTime() - (self.waitingAt or 0) - 0.3) / 0.7, 0, 1))
			local yoff = (1 - wa) * h * 0.03

			draw.SimpleText("WAITING FOR PLAYERS", "CRI_Title", w / 2, h * 0.42 + yoff, ColorAlpha(criWhite, 255 * wa), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			draw.SimpleText(readyN .. " / " .. readyT, "CRI_Huge", w / 2, h * 0.54 + yoff, ColorAlpha(criRed, 255 * wa), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

			local left = math.max(0, (zb.ROUND_BEGIN or 0) - CurTime())
			draw.SimpleText("THE ROUND WILL START IN " .. string.FormattedTime(left, "%02i:%02i"), "CRI_Med", w / 2, h * 0.66 + yoff, ColorAlpha(criDim, 200 * wa), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end
	end


	local builders = {}
	local current, currentName

	local function Switch(name)
		if currentName == name then return end

		local old = current
		if IsValid(old) then
			old:AlphaTo(0, 0.2, 0, function() if IsValid(old) then old:Remove() end end)
		end

		currentName = name
		pnl.state = name
		current = nil

		if name == "waiting" then
			pnl.waitingAt = CurTime()
		end

		if not builders[name] then return end

		current = builders[name]()
		current:SetAlpha(0)
		current:AlphaTo(255, 0.25, 0.1)
	end

	local function ScreenBase()
		local scr = vgui.Create("DPanel", pnl)
		scr:SetPos(scrw * 0.03, headerH + scrh * 0.03)
		scr:SetSize(scrw * 0.94, scrh * 0.93 - headerH)
		scr.Paint = nil
		return scr
	end

	local function TopBar(scr, title)
		local top = vgui.Create("DPanel", scr)
		top:Dock(TOP)
		top:SetTall(ScreenScale(16))
		top:DockMargin(0, 0, 0, 10)
		top.Paint = function(self, w, h)
			draw.SimpleText(string.upper(title), "CRI_Med", w / 2, h / 2, criWhite, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end

		local back = SmallButton(top, "< Back", function() Switch("main") end)
		back:SetWide(ScreenScale(50))
		back:Dock(LEFT)
		return top
	end


	builders.main = function()
		local scr = vgui.Create("DPanel", pnl)
		scr:SetPos(scrw * 0.06, headerH + scrh * 0.2)
		scr:SetSize(scrw * 0.42, scrh * 0.6)
		scr.Paint = nil

		local btns = {}
		local flyingOut = false

		local firstIntro = not pnl.introPlayed
		pnl.introPlayed = true

		local function StartGame()
			if flyingOut then return end
			flyingOut = true

			net.Start("criresp_ready")
			net.SendToServer()

			for i, b in ipairs(btns) do
				b.outStart = CurTime() + (#btns - i) * 0.09
			end

			timer.Simple(0.75, function()
				if IsValid(scr) and currentName == "main" then Switch("waiting") end
			end)
		end

		for i, data in ipairs({
			{"Start Game", StartGame},
			{"Settings", function() Switch("settings") end},
			{"Customization", function() Switch("custom") end},
			{"How to Play", function() Switch("howto") end},
		}) do
			local b = vgui.Create("DButton", scr)
			b:SetText("")
			b:Dock(TOP)
			b:SetTall(scrh * 0.08)
			b:DockMargin(0, 0, 0, scrh * 0.015)
			b.hover = 0
			b.introStart = firstIntro and (CurTime() + 0.3 + i * 0.12) or 0
			b.OnCursorEntered = function()
				if flyingOut then return end
				surface.PlaySound(sndHover)
			end
			b.Paint = function(self, w, h)
				self.hover = Lerp(FrameTime() * 8, self.hover, self:IsHovered() and not flyingOut and 1 or 0)
				local hv = self.hover

				local ip = math.Clamp((CurTime() - self.introStart) / 0.4, 0, 1)
				ip = math.ease.OutCubic(ip)

				local xoff = (ip - 1) * w * 0.7
				local yoff = 0
				local alpha = 255 * ip

				if self.outStart then
					local op = math.Clamp((CurTime() - self.outStart) / 0.35, 0, 1)
					op = math.ease.InCubic(op)
					xoff = xoff - op * w
					yoff = -op * h * 0.6
					alpha = alpha * (1 - op)
				end

				local col = Color(Lerp(hv, 225, criRed.r), Lerp(hv, 225, criRed.g), Lerp(hv, 225, criRed.b), alpha)
				draw.SimpleText(string.upper(data[1]), "CRI_MenuItem", 12 + hv * ScreenScale(14) + xoff, h / 2 + yoff, col, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

				surface.SetDrawColor(criRed.r, criRed.g, criRed.b, math.min(255 * hv, alpha))
				surface.DrawRect(12 + xoff, h - 5 + yoff, w * 0.45 * hv, 3)
			end
			b.DoClick = function()
				if flyingOut then return end
				surface.PlaySound(sndClick)
				data[2]()
			end

			table.insert(btns, b)
		end

		return scr
	end


	builders.settings = function()
		local scr = ScreenBase()
		TopBar(scr, "Settings")

		local box = vgui.Create("DPanel", scr)
		box:Dock(FILL)
		box:DockPadding(scr:GetWide() * 0.28, 20, scr:GetWide() * 0.28, 20)
		box.Paint = function(self, w, h)
			local bw = w * 0.48
			draw.RoundedBox(8, w / 2 - bw / 2 - 16, 0, bw + 32, h, criPanel)
		end

		local musicRow = CriRow(box, "MENU MUSIC")
		CriToggle(musicRow, function() return cv_music:GetBool() end, function()
			RunConsoleCommand("criresp_menumusic", cv_music:GetBool() and "0" or "1")
			timer.Simple(0, function()
				if cv_music:GetBool() then PlayMenuMusic() else StopMenuMusic() end
			end)
		end)

		local volRow = CriRow(box, "MUSIC VOLUME")
		CriArrows(volRow,
			function() return 11 end,
			function() return math.Round(cv_musicvol:GetInt() / 10) end,
			function(v)
				RunConsoleCommand("criresp_menumusic_vol", v * 10)
				timer.Simple(0, function()
					if IsValid(menuMusic) then menuMusic:SetVolume(cv_musicvol:GetInt() / 100) end
				end)
			end,
			function() return cv_musicvol:GetInt() .. "%" end)

		if LocalPlayer():IsAdmin() then
			local capRow = CriRow(box, "ALLOW MORE THAN 20 PLAYERS")
			CriToggle(capRow, function()
				return GetConVar("criresp_over20"):GetBool()
			end, function()
				net.Start("criresp_over20")
					net.WriteBool(not GetConVar("criresp_over20"):GetBool())
				net.SendToServer()
			end)

			local note = vgui.Create("DLabel", box)
			note:Dock(TOP)
			note:DockMargin(4, 0, 4, 0)
			note:SetFont("CRI_Small")
			note:SetTextColor(criDim)
			note:SetText("When disabled only 20 players can join the round, the rest become spectators.")
			note:SetWrap(true)
			note:SetAutoStretchVertical(true)
		end

		return scr
	end


	builders.custom = function()
		local scr = ScreenBase()
		TopBar(scr, "Customization")

		local primaries = MODE.SWATPrimaries or {}
		local gearlist = MODE.SWATGear or {}
		local slots = MODE.SWATGearSlots or 4

		local selPrimary = cv_loadout:GetInt()
		local selGear = {}
		for _, s in ipairs(string.Explode(" ", cv_gear:GetString())) do
			local n = tonumber(s)
			if n and gearlist[n] then selGear[n] = true end
		end

		local groups = {}
		for i, v in ipairs(string.Explode(" ", cv_groups:GetString())) do
			groups[i - 1] = tonumber(v) or 0
		end

		local body = vgui.Create("DPanel", scr)
		body:Dock(FILL)
		body.Paint = nil

		local units = vgui.Create("DPanel", body)
		units:Dock(LEFT)
		units:SetWide(scr:GetWide() * 0.15)
		units:DockMargin(0, 0, 10, 0)
		units.Paint = nil

		CriBar(units, "Special Units")

		local swatCard = vgui.Create("DButton", units)
		swatCard:Dock(TOP)
		swatCard:SetTall(units:GetWide() * 0.85)
		swatCard:SetText("")
		swatCard.Selected = true
		swatCard.OnCursorEntered = function() surface.PlaySound(sndHover) end
		swatCard.Paint = function(self, w, h)
			draw.RoundedBox(6, 0, 0, w, h, self.Selected and criPanelLight or criPanel)
			surface.SetDrawColor(self.Selected and criRed or criWhite)
			surface.DrawOutlinedRect(1, 1, w - 2, h - 2, 2)

			local fw = w * 0.66
			surface.SetDrawColor(255, 255, 255)
			surface.SetMaterial(flagMat)
			surface.DrawTexturedRect(w / 2 - fw / 2, h * 0.18, fw, fw * 0.55)

			draw.SimpleText("SWAT", "CRI_Med", w / 2, h * 0.82, criWhite, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end
		swatCard.DoClick = function() surface.PlaySound(sndClick) end

		local mid = vgui.Create("DPanel", body)
		mid:Dock(LEFT)
		mid:SetWide(scr:GetWide() * 0.3)
		mid:DockMargin(0, 0, 10, 0)
		mid.Paint = nil

		CriBar(mid, "Operator")

		local groupScroll = vgui.Create("DScrollPanel", mid)
		groupScroll:Dock(BOTTOM)
		groupScroll:SetTall(scr:GetTall() * 0.26)
		groupScroll:GetVBar():SetWide(4)

		local previewBG = vgui.Create("DPanel", mid)
		previewBG:Dock(FILL)
		previewBG:DockMargin(0, 0, 0, 8)
		previewBG.Paint = function(self, w, h)
			draw.RoundedBox(6, 0, 0, w, h, Color(8, 2, 2, 190))
			surface.SetDrawColor(criRedDark)
			surface.DrawOutlinedRect(0, 0, w, h, 1)
		end

		local preview = vgui.Create("DModelPanel", previewBG)
		preview:Dock(FILL)
		preview:DockMargin(2, 2, 2, 2)
		preview:SetModel(MODE.SWATModel or "models/css_seb_swat/css_swat.mdl")
		preview:SetFOV(54)
		preview:SetCamPos(Vector(95, 0, 52))
		preview:SetLookAt(Vector(0, 0, 40))
		preview:SetCursor("sizeall")
		preview.RotY = 35

		if IsValid(preview.Entity) then
			local seq = preview.Entity:LookupSequence("idle_suitcase")
			if seq > 0 then preview.Entity:ResetSequence(seq) end
		end

		preview.LayoutEntity = function(pv, ent)
			if not IsValid(ent) then return end

			if pv.Dragging then
				local mx = gui.MouseX()
				pv.RotY = pv.RotY + (mx - (pv.LastX or mx)) * 0.6
				pv.LastX = mx
			end

			pv:SetColor(Color(255, 255, 255, math.min(scr:GetAlpha(), pnl:GetAlpha())))

			ent:SetAngles(Angle(0, pv.RotY, 0))
			for k, v in pairs(groups) do ent:SetBodygroup(k, v) end
			pv:RunAnimation()
		end

		preview.OnMousePressed = function(pv, code)
			if code ~= MOUSE_LEFT then return end
			pv.Dragging = true
			pv.LastX = gui.MouseX()
			pv:MouseCapture(true)
		end

		preview.OnMouseReleased = function(pv)
			pv.Dragging = false
			pv:MouseCapture(false)
		end

		preview.PaintOver = function(self, w, h)
			draw.SimpleText("HOLD LMB TO ROTATE", "CRI_Small", w / 2, h - 8, criDim, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
		end

		local pent = preview.Entity
		if IsValid(pent) then
			for _, bg in ipairs(pent:GetBodyGroups() or {}) do
				local id, count = bg.id, pent:GetBodygroupCount(bg.id)
				if count < 2 then continue end

				CriArrows(CriRow(groupScroll, string.upper(bg.name or ("BODYGROUP " .. id))),
					function() return count end,
					function() return groups[id] or 0 end,
					function(v) groups[id] = v end,
					function() return (groups[id] or 0) + 1 .. " / " .. count end)
			end
		end

		local rightC = vgui.Create("DPanel", body)
		rightC:Dock(FILL)
		rightC.Paint = nil

		local tileSize = ScreenScale(52)

		CriBar(rightC, "Primary Weapon")

		local pgrid = vgui.Create("DIconLayout", rightC)
		pgrid:Dock(TOP)
		pgrid:SetTall(tileSize + ScreenScale(16))
		pgrid:DockMargin(0, 0, 0, 12)
		pgrid:SetSpaceX(6)
		pgrid:SetSpaceY(6)

		local randomTile = Tile(pgrid, nil, nil, "RANDOM", function() return selPrimary == 0 end, function()
			selPrimary = 0
		end)
		randomTile:SetSize(tileSize, tileSize + ScreenScale(14))

		for i, p in ipairs(primaries) do
			local tile = Tile(pgrid, p.wep, p.icon, p.name, function() return selPrimary == i end, function()
				selPrimary = i
			end)
			tile:SetSize(tileSize, tileSize + ScreenScale(14))
		end

		CriBar(rightC, "Equipment - " .. slots .. " slots")

		local ggrid = vgui.Create("DIconLayout", rightC)
		ggrid:Dock(TOP)
		ggrid:SetTall((tileSize + ScreenScale(16)) * 2)
		ggrid:SetSpaceX(6)
		ggrid:SetSpaceY(6)

		local function GearCount()
			local n = 0
			for _ in pairs(selGear) do n = n + 1 end
			return n
		end

		for i, g in ipairs(gearlist) do
			local tile = Tile(ggrid, g.item, g.icon, g.name, function() return selGear[i] end, function()
				if selGear[i] then
					selGear[i] = nil
				elseif GearCount() < slots then
					selGear[i] = true
				else
					surface.PlaySound("shitty/tap_release.wav")
				end
			end)
			tile:SetSize(tileSize, tileSize + ScreenScale(14))
		end

		local slotsInfo = vgui.Create("DPanel", rightC)
		slotsInfo:Dock(TOP)
		slotsInfo:SetTall(ScreenScale(10))
		slotsInfo:DockMargin(0, 4, 0, 0)
		slotsInfo.Paint = function(self, w, h)
			--draw.SimpleText("SELECTED: " .. GearCount() .. " / " .. slots .. "  (HANDCUFFS AND SIDEARM ARE ALWAYS ISSUED)", "CRI_Small", 0, h / 2, criDim, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		end

		local applyBtn = BoxButton(rightC, "Apply", function()
			local num = IsValid(preview.Entity) and preview.Entity:GetNumBodyGroups() or 0
			local t = {}
			for k = 0, num - 1 do t[k + 1] = groups[k] or 0 end

			local gear = {}
			for i in SortedPairs(selGear) do table.insert(gear, i) end

			RunConsoleCommand("criresp_loadout", selPrimary)
			RunConsoleCommand("criresp_bodygroups", table.concat(t, " "))
			RunConsoleCommand("criresp_gear", table.concat(gear, " "))
			timer.Simple(0.1, SendCustomization)

		end)
		applyBtn:Dock(BOTTOM)
		applyBtn:SetTall(ScreenScale(18))

		return scr
	end


	builders.howto = function()
		local scr = vgui.Create("DPanel", pnl)
		scr:SetPos(scrw * 0.05, headerH + scrh * 0.04)
		scr:SetSize(scrw * 0.34, scrh * 0.68)
		scr.Paint = function(self, w, h)
			draw.RoundedBox(8, 0, 0, w, h, criPanel)
			surface.SetDrawColor(criRed)
			surface.DrawRect(0, 0, w, 3)
		end

		local top = vgui.Create("DPanel", scr)
		top:Dock(TOP)
		top:SetTall(ScreenScale(16))
		top:DockMargin(10, 10, 10, 6)
		top.Paint = function(self, w, h)
			draw.SimpleText("HOW TO PLAY", "CRI_Med", 0, h / 2, criRed, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		end

		local back = SmallButton(top, "< Back", function() Switch("main") end)
		back:SetWide(ScreenScale(44))
		back:Dock(RIGHT)

		local scroll = vgui.Create("DScrollPanel", scr)
		scroll:Dock(FILL)
		scroll:DockMargin(10, 0, 10, 10)
		scroll:GetVBar():SetWide(4)

		local white = "<colour=240,240,240,255>"
		local red = "<colour=228,49,49,255>"
		local blue = "<colour=110,150,255,255>"
		local dim = "<colour=170,140,140,255>"

		local text1 = "<font=CRI_Med>" .. white .. "THE BASICS YOU WILL NEED TO PLAY</colour></font>\n\n"
			.. "<font=CRI_Small>" .. white .. "1. PLAYING AS A </colour>" .. red .. "SUSPECT</colour>\n\n"
			.. white .. "If you become a </colour>" .. red .. "suspect</colour>" .. white
			.. ", you cannot waste a single minute. First of all, scan the area around you: barricade the doors with props, board up the windows, do everything you can so the </colour>"
			.. blue .. "entry team</colour>" .. white
			.. " has as much trouble as possible trying to breach the building. Understand one thing - only teamwork decides whether you win this round or not. Unlike the entry team you don't have serious firepower: your weapons are fairly weak and hitting an operator in the chest won't do you much good. Avoid direct contact with the </colour>"
			.. blue .. "operators</colour>" .. white
			.. " and set up ambushes, attacking them from behind. If you are an accurate shooter, the best body part to hit an operator in is the face. If you are not so sure you can hit the face - shoot the legs and arms, those are the most vulnerable spots of an operator.</colour></font>"

		local textImp = "<font=CRI_Small>" .. red
			.. "IMPORTANT!!! Do not leave the building under any circumstances, otherwise your skull will be shattered by a .338 caliber round. You have been warned.</colour></font>"

		local text2 = "<font=CRI_Small>" .. white .. "2. PLAYING AS THE </colour>" .. blue .. "ENTRY TEAM</colour>\n\n" .. white
			.. "While you are in spectators you have the opportunity to analyze the situation with your team and prepare in advance. You have the advantage of good equipment and powerful weapons. Your key to victory is teamwork: hold the formation together to clear every corner of the building. Don't forget about your six o'clock - the operator at the back of the stack should watch the team's rear to avoid ambushes.\n\nIf there are 20 players, a sixth operator will join your team - the sniper. His task is to watch the windows of the building and report all the activity he observes to you.</colour>\n\n"
			.. dim .. "More content may be added later.</colour></font>"

		local body = vgui.Create("DPanel", scroll)
		body:Dock(TOP)
		body.Paint = function(self, w, h)
			if not self.m1 or self.mw ~= w then
				self.mw = w
				self.m1 = markup.Parse(text1, w - 12)
				self.mImp = markup.Parse(textImp, w - 28)
				self.m2 = markup.Parse(text2, w - 12)
				self:SetTall(self.m1:GetHeight() + self.mImp:GetHeight() + self.m2:GetHeight() + 44)
			end

			local y = 4
			self.m1:Draw(4, y)
			y = y + self.m1:GetHeight() + 14

			local sway = math.sin(RealTime() * 2.3) * 6
			self.mImp:Draw(10 + sway, y)
			y = y + self.mImp:GetHeight() + 14

			self.m2:Draw(4, y)
		end

		return scr
	end

	Switch("main")

	pnl.OnRemove = function()
		StopMenuMusic()
	end
end


local beginAt, endStats, menuShownAt

net.Receive("criresp_start", function()
	readyN, readyT = 0, 0
	menuShownAt = CurTime()
	beginAt = nil

	OpenMenu()
	SendCustomization()

	timer.Simple(1, function()
		endStats = nil
	end)
end)

net.Receive("criresp_readycount", function()
	readyN = net.ReadUInt(8)
	readyT = net.ReadUInt(8)
end)

net.Receive("criresp_begin", function()
	beginAt = CurTime()

	if IsValid(menuPanel) then
		local pnl = menuPanel
		pnl:AlphaTo(0, 1.2, 0.4, function() if IsValid(pnl) then pnl:Remove() end end)
	end

	timer.Simple(3, function()
		sound.PlayFile("sound/zbattle/criresp/criepmission.mp3", "mono noblock", function(station)
			if IsValid(station) then
				station:Play()
				song = station
				songfade = 1
			end
		end)
	end)
end)

local teams = {
	[0] = {
		name = "A SWAT OPERATOR",
		objective = "Negotiations failed. You will deploy when SWAT arrives, stand by...",
		color = Color(70, 70, 255)
	},
	[1] = {
		name = "A SUSPECT",
		objective = "This is my fucking house, bitches, I can do what I want.",
		color = Color(228, 49, 49)
	},
}

local spectatorInfo = {
	name = "A SPECTATOR",
	objective = "The lobby is full, you are spectating this round.",
	color = Color(160, 160, 160)
}

song = song or nil
songfade = songfade or 0

function MODE:RenderScreenspaceEffects()
	if (menuShownAt or 0) + 1 < CurTime() then
		
	end

	if zb.ROUND_BEGIN + 85 < CurTime() then
		if songfade <= 0.01 and IsValid(song) then
			song:Stop()
			song = nil
			surface.PlaySound(lply:Team() == 0 and "zbattle/criresp/barricadedsuspectstart.mp3" or "snd_jack_hmcd_policesiren.wav")
		elseif IsValid(song) then
			songfade = Lerp(0.01, songfade, 0)
			song:SetVolume(songfade)
		end
	end
end

function MODE:HUDPaint()
	if endStats then
		local t = CurTime() - endStats.start

		if t < 14 then
			if IsValid(Q_MENU) then Q_MENU:Remove() end

			local alpha = 255 * math.Clamp(t / 2, 0, 1)

			surface.SetDrawColor(0, 0, 0, alpha)
			surface.DrawRect(-1, -1, sw + 2, sh + 2)

			if t > 2 then
				local textAlpha = math.min(alpha, 255 * math.Clamp((t - 2) / 0.7, 0, 1))
				if t > 6.5 then
					textAlpha = textAlpha * math.Clamp(1 - (t - 6.5) / 1.5, 0, 1)
				end

				local title, titleCol
				if endStats.winner == 1 then
					local clean = endStats.arrested + endStats.incap
					local ratio = endStats.total > 0 and clean / endStats.total or 0

					if ratio >= 0.7 then
						title, titleCol = "MISSION ACCOMPLISHED", Color(90, 200, 90)
					elseif ratio >= 0.35 then
						title, titleCol = "SLOPPY MISSION", Color(230, 190, 60)
					else
						title, titleCol = "DISASTROUS MISSION", Color(235, 120, 45)
					end
				elseif endStats.winner == 2 then
					title, titleCol = "MISSION FAILED", criRed
				else
					title, titleCol = "OPERATION OVER", criDim
				end

				draw.SimpleText("CRISIS RESPONSE", "CRI_Med", sw * 0.5, sh * 0.14, ColorAlpha(criRedDark, textAlpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
				draw.SimpleText(title, "CRI_Title", sw * 0.5, sh * 0.32, ColorAlpha(titleCol, textAlpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

				draw.SimpleText("SUSPECTS KILLED: " .. endStats.killed .. " / " .. endStats.total, "CRI_Med", sw * 0.5, sh * 0.48, ColorAlpha(criWhite, textAlpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
				draw.SimpleText("INCAPACITATED: " .. endStats.incap, "CRI_Med", sw * 0.5, sh * 0.55, ColorAlpha(criWhite, textAlpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
				draw.SimpleText("ARRESTED: " .. endStats.arrested, "CRI_Med", sw * 0.5, sh * 0.62, ColorAlpha(criWhite, textAlpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			end
		else
			endStats = nil
		end

		return
	end

	if beginAt then
		local t = CurTime() - beginAt

		if t < 9.5 then
			local alpha = 255 * math.Clamp(t / 0.35, 0, 1)
			if t > 6.5 then
				alpha = 255 * math.Clamp(1 - (t - 6.5) / 2.5, 0, 1)
			end

			surface.SetDrawColor(0, 0, 0, alpha)
			surface.DrawRect(-1, -1, sw + 2, sh + 2)

			if t > 1.5 then
				local info = teams[lply:Team()] or spectatorInfo
				local textAlpha = math.min(alpha, 255 * math.Clamp((t - 1.5) / 0.7, 0, 1))

				draw.SimpleText("CRISIS RESPONSE", "CRI_Title", sw * 0.5, sh * 0.12, ColorAlpha(criRed, textAlpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
				draw.SimpleText("YOU ARE " .. info.name, "CRI_Title", sw * 0.5, sh * 0.5, ColorAlpha(info.color, textAlpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
				draw.SimpleText(info.objective, "CRI_Med", sw * 0.5, sh * 0.6, ColorAlpha(criWhite, textAlpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			end
		else
			beginAt = nil
		end

		return
	end

	if zb.ROUND_BEGIN + 90 > CurTime() and zb.ROUND_BEGIN < CurTime() then
		local color = Color(255 * -math.sin(CurTime() * 3), 25, 255 * math.sin(CurTime() * 3))
		local text = "SWAT will arrive in: " .. string.FormattedTime(zb.ROUND_BEGIN + 90 - CurTime(), "%02i:%02i")
		draw.SimpleText(text, "CRI_Med", sw * 0.02, sh * 0.95, Color(0, 0, 0), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		draw.SimpleText(text, "CRI_Med", sw * 0.02 - 2, sh * 0.95 - 2, color, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
	end
end


net.Receive("cri_roundend", function()
	beginAt = nil
	StopMenuMusic()
	if IsValid(menuPanel) then menuPanel:Remove() end
	if IsValid(song) then song:Stop() song = nil end

	endStats = {
		start = CurTime(),
		winner = net.ReadUInt(4),
		killed = net.ReadUInt(8),
		incap = net.ReadUInt(8),
		arrested = net.ReadUInt(8),
		total = net.ReadUInt(8),
	}

	surface.PlaySound(endStats.winner == 2 and "zbattle/criresp/failedSWAT.mp3" or "ambient/alarms/warningbell1.wav")
end)

local function EndLockActive()
	if not endStats then return false end

	if CurTime() - endStats.start > 8.5 then
		endStats = nil
		return false
	end

	return true
end

hook.Add("StartCommand", "criresp_endlock", function(ply, mv)
	if not EndLockActive() then return end

	mv:RemoveKey(IN_ATTACK)
	mv:RemoveKey(IN_ATTACK2)
	mv:RemoveKey(IN_FORWARD)
	mv:RemoveKey(IN_BACK)
	mv:RemoveKey(IN_MOVELEFT)
	mv:RemoveKey(IN_MOVERIGHT)
	mv:RemoveKey(IN_JUMP)
	mv:RemoveKey(IN_DUCK)
	mv:RemoveKey(IN_USE)
	mv:RemoveKey(IN_RELOAD)
end)

hook.Add("PlayerBindPress", "criresp_endlock_binds", function(ply, bind, pressed)
	if not EndLockActive() then return end
	if string.find(bind, "+menu") or string.find(bind, "+use") or string.find(bind, "+attack") then
		return true
	end
end)
