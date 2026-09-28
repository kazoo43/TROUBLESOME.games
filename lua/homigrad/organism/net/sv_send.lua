hg = hg or {}
hg.organism = hg.organism or {}

local CurTime = CurTime
local IsValid = IsValid
local table_Insert = table.insert

local hg_unreliable_nets = ConVarExists("hg_unreliable_nets") and GetConVar("hg_unreliable_nets") or CreateConVar("hg_unreliable_nets", 0, FCVAR_ARCHIVE + FCVAR_SERVER_CAN_EXECUTE, "Toggle unreliable net messages for some of the expensive nets", 0, 1)
local hg_developer = ConVarExists("hg_developer") and GetConVar("hg_developer") or CreateConVar("hg_developer", 0, FCVAR_SERVER_CAN_EXECUTE, "Toggle developer mode (enables damage traces)", 0, 1)

util.AddNetworkString("organism_send")
util.AddNetworkString("organism_sendply")

local function send_organism(org, ply)
	if !IsValid(org.owner) then return end

	local sendtable = {}

	sendtable.alive = org.alive
	sendtable.otrub = org.otrub
	sendtable.owner = org.owner
	sendtable.stamina = org.stamina
	sendtable.immobilization = org.immobilization
	sendtable.adrenaline = org.adrenaline
	sendtable.adrenalineAdd = org.adrenalineAdd
	sendtable.analgesia = org.analgesia
	sendtable.lleg = org.lleg
	sendtable.rleg = org.rleg
	sendtable.rarm = org.rarm
	sendtable.larm = org.larm
	sendtable.pelvis = org.pelvis
	sendtable.skull = org.skull
	sendtable.chest = org.chest
	sendtable.internalBleed = org.internalBleed
	sendtable.internalBleedHeal = org.internalBleedHeal
	sendtable.disorientation = org.disorientation
	sendtable.brain = org.brain
	sendtable.o2 = org.o2
	sendtable.CO = org.CO
	sendtable.blood = org.blood
	sendtable.bloodtype = org.bloodtype
	sendtable.bleed = org.bleed
	sendtable.hurt = org.hurt
	sendtable.pain = org.pain
	sendtable.shock = org.shock
	sendtable.pulse = org.pulse
	sendtable.heartbeat = org.heartbeat
	sendtable.timeValue = org.timeValue
	sendtable.holdingbreath = org.holdingbreath
	sendtable.arteria = org.arteria
	sendtable.recoilmul = org.recoilmul
	sendtable.meleespeed = org.meleespeed
	sendtable.temperature = org.temperature
	sendtable.canmove = org.canmove
	sendtable.fear = org.fear
	sendtable.llegdislocation = org.llegdislocation
	sendtable.rlegdislocation = org.rlegdislocation
	sendtable.rarmdislocation = org.rarmdislocation
	sendtable.larmdislocation = org.larmdislocation
	sendtable.jawdislocation = org.jawdislocation
	sendtable.llegamputated = org.llegamputated
	sendtable.rlegamputated = org.rlegamputated
	sendtable.rarmamputated = org.rarmamputated
	sendtable.larmamputated = org.larmamputated
	sendtable.headamputated = org.headamputated
	sendtable.lungsfunction = org.lungsfunction
	sendtable.consciousness = org.consciousness
	sendtable.assimilated = org.assimilated
	sendtable.berserk = org.berserk
	sendtable.noradrenaline = org.noradrenaline
	sendtable.LodgedEntities = org.LodgedEntities
	sendtable.CantCheckPulse = org.CantCheckPulse
	sendtable.blindness = org.blindness
	sendtable.critical = org.critical
	sendtable.incapacitated = org.incapacitated
	sendtable.berserkActive2 = org.berserkActive2
	sendtable.noradrenalineActive = org.noradrenalineActive

	sendtable.superfighter = org.superfighter

	net.Start("organism_send", hg_unreliable_nets:GetBool())
	net.WriteTable(!hg_developer:GetBool() and sendtable or org)
	net.WriteBool(org.owner.fullsend)
	net.WriteBool(false)
	net.WriteBool(true)
	net.WriteBool(false)

	if IsValid(ply) and ply:IsPlayer() then
		net.Send(ply)
	else
		net.Broadcast()
	end

	if org.owner == ply or !IsValid(ply) or !ply:IsPlayer() then
		org.owner.fullsend = nil
	end
end

local function send_bareinfo(org)
	if !IsValid(org.owner) then return end

	local sendtable = {}

	sendtable.alive = org.alive
	sendtable.otrub = org.otrub
	sendtable.owner = org.owner
	sendtable.bloodtype = org.bloodtype
	sendtable.pulse = org.pulse
	sendtable.blood = org.blood
	sendtable.heartbeat = org.heartbeat
	sendtable.analgesia = org.analgesia
	sendtable.o2 = org.o2
	sendtable.timeValue = org.timeValue
	sendtable.superfighter = org.superfighter
	sendtable.lungsfunction = org.lungsfunction
	sendtable.lleg = org.lleg
	sendtable.rleg = org.rleg
	sendtable.rarm = org.rarm
	sendtable.larm = org.larm
	sendtable.llegdislocation = org.llegdislocation
	sendtable.rlegdislocation = org.rlegdislocation
	sendtable.rarmdislocation = org.rarmdislocation
	sendtable.larmdislocation = org.larmdislocation
	sendtable.jawdislocation = org.jawdislocation
	sendtable.llegamputated = org.llegamputated
	sendtable.rlegamputated = org.rlegamputated
	sendtable.rarmamputated = org.rarmamputated
	sendtable.larmamputated = org.larmamputated
	sendtable.headamputated = org.headamputated
	sendtable.LodgedEntities = org.LodgedEntities
	sendtable.berserkActive2 = org.berserkActive2
	sendtable.CantCheckPulse = org.CantCheckPulse
	sendtable.noradrenalineActive = org.noradrenalineActive

	local rf = RecipientFilter()
	rf:AddPVS(org.owner:GetPos())

	if org.owner:IsPlayer() then rf:RemovePlayer(org.owner) end

	net.Start("organism_send", hg_unreliable_nets:GetBool())
	net.WriteTable(!hg_developer:GetBool() and sendtable or org)
	net.WriteBool(org.owner.fullsend)
	net.WriteBool(true)
	net.WriteBool(false)
	net.WriteBool(false)
	net.Send(rf)
end

hg.send_organism = send_organism
hg.send_bareinfo = send_bareinfo
