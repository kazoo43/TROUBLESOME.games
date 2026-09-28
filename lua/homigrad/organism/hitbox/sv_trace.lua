hg.organism = hg.organism or {}

local util_IntersectRayWithOBB = util.IntersectRayWithOBB
local math_ceil = math.ceil
local math_max = math.max
local math_min = math.min
local math_clamp = math.Clamp
local stepDiv = 1
local tracePos = Vector(0, 0, 0)

function hg.organism.Trace(pos, dir, size, maxpen, boxs, center, endDis, organs, ricochetable, funcInput, ...)
	local endDisSqr = endDis * endDis

	tracePos:Set(pos)

	local hitBoxs = {}
	local tracePoses = {}
	local inputHole, outputHole = {}, {}
	local inBody, hitSomething
	local box
	local stepDis = 1 / stepDiv
	local distance = math_ceil(dir:Length())
	local dirSub = 0
	local ricocheted
	local distance = math_clamp(distance, 0, 50)

	dir:Normalize()
	dir = dir * stepDis

	local distancereal = distance

	local passing = 0
	local maxtries = 20

	while(passing < distance and maxtries > 0)do
		maxtries = maxtries - 1

		if maxpen ~= 0 and passing >= maxpen then break end

		dir:Normalize()

		local frac = 1
		local iHit
		local normal
		local hit

		for i = 1, #boxs do
			if hitBoxs[i] then continue end

			box = boxs[i]

			if not organs[box[6]] then continue end

			local startpos = tracePos - dir * 0
			local endpos = dir * 100

			local hit_, normal_, frac_ = util_IntersectRayWithOBB(startpos, endpos, box[1], box[2], box[3], box[4])

			if hit_ then
				if frac_ < frac then
					iHit = i
					frac = frac_
					normal = normal_
					hit = hit_
				end
			end
		end

		frac = math_max(frac, 0.001)

		dir = dir:GetNormalized() * frac * 100

		if iHit then
			hitBoxs[iHit] = true
			hitSomething = true

			dirSub = funcInput(box, tracePos, ricocheted, ...)

			if dirSub then
				distance = distance - dirSub * distance
			end
		end

		passing = passing + 100 * frac

		if not inBody and iHit then
			inBody = true
			inputHole[#inputHole + 1] = Vector(tracePos[1], tracePos[2], tracePos[3])
		end

		if inBody and not iHit then
			outputHole[#outputHole + 1] = Vector(tracePos[1], tracePos[2], tracePos[3])
			inBody = nil
		end

		if hit then
			tracePos = hit
		end

		tracePoses[#tracePoses + 1] = Vector(tracePos[1], tracePos[2], tracePos[3])

		if passing >= distance or (tracePos - center):LengthSqr() > endDisSqr then break end
	end

	if !hitSomething then
		inputHole[1] = Vector(pos[1], pos[2], pos[3])
		outputHole[1] = Vector(tracePos[1], tracePos[2], tracePos[3])
	end

	dir:Normalize()

	return tracePos, hitBoxs, inputHole, outputHole, dir, distance, tracePoses
end

function hg.organism.BlastTrace(pos, size, dmg, boxs, organs, funcInput, ...)
	local box
	local center

	local size = size

	for i = 1, #boxs do
		box = boxs[i]
		center = box[1]

		local dist = pos:Distance(center)
		local amt = dmg / dist * (1 - (organs[box[6]] and organs[box[6]][box[7]][2] or 0)) / size

		local dirSub = funcInput(box, amt, ...)

		size = size * (dirSub * 0.01 + 1)
	end
end
