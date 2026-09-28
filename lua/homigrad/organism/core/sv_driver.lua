hg = hg or {}
hg.organism = hg.organism or {}

local IsValid = IsValid

hook.Add("Org Clear", "Main", function(org)
	hg.organism.RunPhase("teardown", org)

	org.alive = true
	org.otrub = false
	org.entindex = IsValid(org.owner) and org.owner:EntIndex() or hg.organism.lastindex + 1

	hg.organism.RunPhase("reset", org)

	org.brain = 0
	org.consciousness = 1
	org.disorientation = 0
	org.jaw = 0
	org.spine1 = 0
	org.spine2 = 0
	org.spine3 = 0
	org.chest = 0
	org.pelvis = 0
	org.skull = 0
	org.stomach = 0
	org.intestines = 0

	org.thiamine = 0

	org.lleg = 0
	org.rleg = 0
	org.larm = 0
	org.rarm = 0
	org.llegdislocation = false
	org.rlegdislocation = false
	org.rarmdislocation = false
	org.larmdislocation = false
	org.jawdislocation = false

	org.llegamputated = false
	org.rlegamputated = false
	org.rarmamputated = false
	org.larmamputated = false
	org.headamputated = false

	org.furryinfected = false

	org.health = 100
	org.canmove = true
	org.recoilmul = 1
	org.legstrength = 1
	org.meleespeed = 1
	org.temperature = 36.7
	org.superfighter = false
	org.CantCheckPulse = nil
	org.HEV = nil
	org.bleedingmul = 1

	org.last_heartbeat = CurTime()
	org.bulletwounds = 0
	org.stabwounds = 0
	org.slashwounds = 0
	org.bruises = 0
	org.burns = 0
	org.explosionwounds = 0

	org.fear = 0
	org.fearadd = 0

	org.assimilated = 0
	org.berserk = 0
	org.noradrenaline = 0

	org.blindness = nil

	if IsValid(org.owner) then
		if org.owner:IsPlayer() and org.owner:Alive() then
			org.owner:SetHealth(100)
			org.owner:SetNetVar("wounds",{})
			org.owner:SetNetVar("arterialwounds",{})
		end

		org.owner:SetNetVar("zableval_masku", false)
	end

	org.allowholster = false

	org.just_damaged_bone = nil
	org.LodgedEntities = nil

	org.dmgstack = {}

	org.SpawnedBrainChunks = nil
end)

hook.Add("Should Fake Up", "organism", function(ply)
	local org = ply.organism

	if org.otrub or org.fake or (org.lleg == 1 and org.rleg == 1) and org.berserk <= 0.3 or org.consciousness <= 0.4 then
		return false
	end
end)

hook.Add("Org Think", "Main", function(owner, org, timeValue)
	if !IsValid(owner) then
		hg.organism.list[owner] = nil
		return
	end

	if owner:IsPlayer() and !owner:Alive() then return end

	local isPly = owner:IsPlayer()

	org.isPly = isPly

	if isPly or org.fakePlayer then
		if !org.fakePlayer then
			org.alive = owner:Alive()
		end
	else
		org.alive = false
	end

	org.needotrub = false
	org.needfake = false
	org.ownerFake = isPly and (org.FakeRagdoll and true) or false

	org.timeValue = timeValue
	org.incapacitated = false
	org.critical = false

	hg.organism.RunPhase("early", owner, org, timeValue)
	hg.organism.RunPhase("think", owner, org, timeValue)
end)
