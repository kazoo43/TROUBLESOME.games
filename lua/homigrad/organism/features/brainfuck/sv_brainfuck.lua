hg = hg or {}

local CurTime = CurTime
local IsValid = IsValid
local math_random = math.random
local timer_Simple = timer.Simple

local CHANCE = 0.95

hg.organism.module = hg.organism.module or {}
hg.organism.module.brainfuck = hg.organism.module.brainfuck or {}
local module = hg.organism.module.brainfuck
module.spasm = module.spasm or {}
module.fencing = module.fencing or {}

hook.Add("Should Fake Up", "BrainfuckFencing", function(ply)
	local org = ply.organism

	if org and org.fencing and org.fencingEnd and CurTime() < org.fencingEnd then
		return false
	end

	local rag = ply.FakeRagdoll

	if IsValid(rag) and rag.fencing and rag.fencingEnd and CurTime() < rag.fencingEnd then
		return false
	end
end)

hook.Add("RagdollDeath", "BrainfuckStart", function(ply, rag)
	timer_Simple(0.1, function()
		if !IsValid(ply) or !IsValid(rag) then return end

		local org = ply.organism

		if !org then return end
		if rag.noHead or org.noHead or ply.noHead then return end

		local hadBrainDamage = org.brain and org.brain > 0
		local hadSkullDamage = org.skull and org.skull > 0
		local hadHeadDamage = org.dmgstack and org.dmgstack[HITGROUP_HEAD] and (org.dmgstack[HITGROUP_HEAD][1] or 0) > 0
		local headshot = hadBrainDamage or hadSkullDamage or hadHeadDamage

		if headshot and math_random() < CHANCE then
			local stype = "rigor"

			hg.applySpasm(rag, stype)

			if rag.organism then
				rag.organism.spasm = true
				rag.organism.spasmType = stype
			end
		end
	end)
end)

module[2] = function(owner, org, timeValue)
	if !IsValid(owner) then return end

	if org.fencing and org.fencingEnd then
		local rag = owner.FakeRagdoll

		if IsValid(rag) then
			module.fencing.get(org, rag)
		end
	end

	module.spasm.get(owner.FakeRagdoll)
end

module[3] = function(org)
	if !org or !org.owner then return end

	if IsValid(org.owner) then
		module.spasm.clear(org.owner)
		module.fencing.clear(org.owner)
	end

	org.fencing = nil
	org.fencingEnd = nil
end
