local white = Color(255, 255, 255)
local black = Color(0, 0, 0, 200)
local red, green = Color(255, 0, 0), Color(0, 255, 0)
local Round = math.Round
local Lerp = Lerp
local isnumber = isnumber

local list = {
	"owner",
	"superfighter",
	"berserkActive2",
	"temperature",
	"tempchanging",
	"heatbuff",
	"blindness",
	"fear",
	"assimilated",
	"berserk",
	"noradrenaline",
	"fearadd",
	{"blood", 5000},
	{"bleed", 100, true},
	"bloodtype",
	"hemotransfusionshock",
	{"internalBleed", 10, true},
	"internalBleedHeal",
	{"arteria", 1, true},
	{"rarmartery", 1, true},
	{"larmartery", 1, true},
	{"rlegartery", 1, true},
	{"llegartery", 1, true},
	{"spineartery", 1, true},
	{"llegdislocation", true, true},
	{"rlegdislocation", true, true},
	{"larmdislocation", true, true},
	{"rarmdislocation", true, true},
	{"jawdislocation", true, true},
	{"llegamputated", true, true},
	{"rlegamputated", true, true},
	{"larmamputated", true, true},
	{"rarmamputated", true, true},
	0,
	"likely_phrase",
	{"alive", true},
	{"otrub", true, true},
	{"health", 100, false},
	{"incapacitated", true, true},
	{"critical", true, true}, false,
	{"pain", 90, true},
	{"painadd", 90, true},
	{"avgpain", 90, true},
	{"immobilization", true},
	{"painkiller", 3, true},
	{"analgesia", 0, true},
	{"naloxone", 0, true},
	{"shock", 10, true},
	{"hurt", 1, true},
	{"tranquilizer", 1, true},
	"wantToVomit",
	"satiety",
	0,
	{"adrenaline", 5, true},
	{"adrenalineStorage", 5, false},
	{"adrenalineAdd", 5, true},
	0,
	{"stamina", {"stamina", "range"}},
	{{"stamina.max", "stamina", "max"},
	{"stamina", "range"}},
	{{"stamina.regen", "stamina", "regen"}, 1},
	{{"stamina.sub", "stamina", "sub"}, 1, true},
	0,
	{"brain", 1, true},
	{"consciousness", 1, false},
	{"skull", 1, true},
	{"disorientation", 1, true},
	{"jaw", 1, true}, false,
	{"spine1", 1, true},
	{"spine2", 1, true},
	{"spine3", 1, true},
	{"chest", 1, true},
	{"pelvis", 1, true},
	0,
	{"heart", 1, true},
	{"heartstop", true, true},
	{"pulse", 70},
	{"heartbeat", 70}, false,
	{"stomach", 1, true},
	{"liver", 1, true},
	{"intestines", 1, true},
	"thiamine",
	"vomitInThroat",
	0,
	{"lungsL", 1, true},
	{"lungsR", 1, true},
	{{"lungsL.penetrated", "lungsL", 2}, 1, true},
	{{"lungsR.penetrated", "lungsR", 2}, 1, true},
	{"trachea", 1, true},
	{"pneumothorax", 1, true},
	{"needle", 1, true},
	0,
	{"o2", {"o2", "range"}},
	"CO",
	{"lungsfunction", true, false},
	"COregen",
	"LodgedEntities",
	"holdingbreath",
	{{"o2.regen", "o2", "regen"}, 2},
	{{"o2.curregen", "o2", "curregen"}, 0.4},
	0,
	{"lleg", 1, true},
	{"rleg", 1, true},
	{"larm", 1, true},
	{"rarm", 1, true},
}

local function lerpColor(lerp, source, set)
	return Lerp(lerp, source.r, set.r), Lerp(lerp, source.g, set.g), Lerp(lerp, source.b, set.b)
end

local function setColor(set)
	return set.r, set.g, set.b
end

local function getTextTable(org)
	local textList = {}

	for i, v in pairs(list) do
		local text1, text2 = "", ""
		local value
		local r, g, b

		if type(v) == "table" then
			if type(v[1]) == "table" then
				if org[v[1][2]] == nil then continue end

				text1 = v[1][1]
				value = org[v[1][2]][v[1][3]]
			else
				if org[v[1]] == nil then continue end

				text1 = v[1]
				value = org[text1]

				if type(value) == "table" then value = value[1] end
			end

			if type(v[2]) == "boolean" then
				if value then
					r, g, b = setColor(v[3] and red or green)
				else
					r, g, b = setColor(v[3] and green or red)
				end
			elseif value then
				local max = v[2]

				if type(v[2]) == "string" then max = org[v[2]] end
				if type(v[2]) == "table" then max = org[v[2][1]][v[2][2]] end

				if !max then continue end

				local k = value ~= 0 and max ~= 0 and value / max or 0

				if v[3] then
					r, g, b = lerpColor(1 - k, red, green)
				else
					r, g, b = lerpColor(k, red, green)
				end
			end

			text2 = isnumber(value) and string.sub(string.format("%f", value), 1, -5) or value
		elseif v == 0 then
		else
			if !org[v] then continue end

			text1 = tostring(v)
			text2 = isnumber(org[v]) and string.sub(string.format("%f", org[v]), 1, -5) or org[v]
		end

		textList[#textList + 1] = {text1, text2, r, g, b}
	end

	return textList
end

local function LerpVariables(lerp, org_source, org_target)
	if !org_source or !org_target then return end

	for i, v in ipairs(list) do
		if type(v) == "table" then
			if type(v[1]) == "table" then
				if !org_source[v[1][2]] then continue end

				org_source[v[1][2]][v[1][3]] = org_target[v[1][2]] and org_target[v[1][2]][v[1][3]] and Lerp(lerp, org_source[v[1][2]][v[1][3]] or org_target[v[1][2]][v[1][3]], org_target[v[1][2]][v[1][3]]) or nil
			else
				if !org_source[v[1]] then org_source[v[1]] = org_target[v[1]] continue end

				if type(org_source[v[1]]) == "table" then
					org_source[v[1]][1] = org_target[v[1]] and org_target[v[1]][1] and Lerp(lerp, org_source[v[1]][1] or org_target[v[1]][1], org_target[v[1]][1]) or nil
				else
					org_source[v[1]] = isnumber(org_source[v[1]]) and isnumber(org_target[v[1]]) and Lerp(lerp, org_source[v[1]], org_target[v[1]]) or org_target[v[1]] or nil
				end
			end
		elseif type(org_target[v]) == "number" and type(org_source[v]) == "number" then
			org_source[v] = Lerp(lerp, org_source[v], org_target[v])
		else
			org_source[v] = org_target[v]
		end
	end
end

hg.LerpVariables = LerpVariables

local littleblack = Color(75, 75, 75, 255)
local trahalgmod = Color(0, 0, 0, 75)
local weight = 200
local developer = GetConVar("developer")
local hg_stats = GetConVar("hg_stats") or CreateClientConVar("hg_stats", 1, true, false, "show stats", 0, 1)

hook.Add("HUDPaint", "homigrad-organism-debug", function()
	local spect = IsValid(lply:GetNWEntity("spect")) and lply:GetNWEntity("spect")
	local organism = lply:Alive() and lply.organism or (viewmode == 1 and IsValid(spect) and spect.organism) or {}

	if !organism then return end
	if !developer:GetBool() then return end
	if !LocalPlayer():IsAdmin() then return end
	if !hg_stats:GetBool() then return end

	local textList = getTextTable(organism)
	local h = Round(ScreenScaleH(5.5))
	local cutoff = math.floor((ScrH() - 150 - 50) / h)

	draw.RoundedBox(0, 15, 150, weight, cutoff * h, black)

	if cutoff < #textList then
		draw.RoundedBox(0, 15 + weight + 15, 150, weight, (#textList - cutoff) * h, black)
	end

	for i, text in ipairs(textList) do
		local y = i > cutoff and 150 + (i - 1 - cutoff) * h or 150 + (i - 1) * h
		local x = i > cutoff and 15 + weight + 15 or 15

		if i % 2 == 0 then draw.RoundedBox(0, x, y, weight, h, littleblack) end

		if text[3] then
			trahalgmod.r = text[3]
			trahalgmod.g = text[4]
			trahalgmod.b = text[5]
			trahalgmod.a = 75

			draw.RoundedBox(0, x, y, weight, h, trahalgmod)
		end

		draw.SimpleText(text[1], "DefaultFixedDropShadow", x, y, white)
		draw.SimpleText(text[2], "DefaultFixedDropShadow", x + weight, y, white, TEXT_ALIGN_RIGHT)
	end

	if !hg.eyeTrace or !IsValid(LocalPlayer()) then return end

	local tr = hg.eyeTrace(LocalPlayer(), 10000)

	if !tr then return end

	local trent = tr.Entity
	local organism_otherply = trent.organism or {}

	if !organism_otherply or table.IsEmpty(organism_otherply) then return end

	local textList = getTextTable(organism_otherply)
	local w = ScrW()
	local x = w - 15 - weight

	draw.RoundedBox(0, x, 15, weight, #textList * h, black)

	for i, text in ipairs(textList) do
		local y = 15 + (i - 1) * h

		if i % 2 == 0 then draw.RoundedBox(0, x, y, weight, h, littleblack) end

		if text[3] then
			trahalgmod.r = text[3]
			trahalgmod.g = text[4]
			trahalgmod.b = text[5]
			trahalgmod.a = 75

			draw.RoundedBox(0, x, y, weight, h, trahalgmod)
		end

		draw.SimpleText(text[1], "DefaultFixedDropShadow", w - 15, y, white, TEXT_ALIGN_RIGHT)
		draw.SimpleText(text[2], "DefaultFixedDropShadow", w - 15 - weight, y, white)
	end
end)
