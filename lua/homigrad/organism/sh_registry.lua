hg.organism = hg.organism or {}
hg.organism.module = hg.organism.module or {}

local module = hg.organism.module
local isfunction = isfunction

hg.organism.ORDER = {
	teardown = {
		"brainfuck",
		"headcrab",
		"virus",
	},
	reset = {
		"pulse",
		"blood",
		"pain",
		"stamina",
		"lungs",
		"liver",
		"metabolism",
		"random_events",
	},
	early = {
		"brainfuck",
		"headcrab",
		"random_events",
		"virus",
	},
	think = {
		"stamina",
		"lungs",
		"liver",
		"blood",
		"pain",
		"metabolism",
		"random_events",
		"pulse",
		"furry",
		"berserk",
		"noradrenaline",
		"amputation",
		"otrub",
		"posturing",
		"healing",
		"vitals",
		"phrases",
		"death",
		"net",
		"berserk_regen",
		"noradrenaline_regen",
	},
}

local SLOT = {
	teardown = 3,
	reset = 1,
	early = "early",
	think = 2,
}

local cache

local function build(phase)
	local list = {}

	for i = 1, #hg.organism.ORDER[phase] do
		local mod = module[hg.organism.ORDER[phase][i]]
		local fn = mod and mod[SLOT[phase]]

		if isfunction(fn) then
			list[#list + 1] = fn
		end
	end

	return list
end

function hg.organism.RunPhase(phase, ...)
	if !cache then
		cache = {
			teardown = build("teardown"),
			reset = build("reset"),
			early = build("early"),
			think = build("think"),
		}
	end

	local list = cache[phase]

	if !list then error("hg.organism.RunPhase: unknown phase " .. tostring(phase), 2) end

	for i = 1, #list do
		list[i](...)
	end
end
