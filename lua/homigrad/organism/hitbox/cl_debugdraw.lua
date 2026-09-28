hg.organism = hg.organism or {}

local LocalPlayer = LocalPlayer
local GetViewEntity = GetViewEntity
local GetConVar = GetConVar
local CreateClientConVar = CreateClientConVar
local ConVarExists = ConVarExists
local Vector = Vector
local render_DrawWireframeBox = render.DrawWireframeBox
local math_ceil = math.ceil

local white, red, blue, black = Color(255, 255, 255), Color(255, 0, 0), Color(0, 0, 255), Color(0, 0, 0)

local hg_show_hitbox = ConVarExists("hg_show_hitbox") and GetConVar("hg_show_hitbox") or CreateClientConVar("hg_show_hitbox", "0", false, false, "shows custom players hitboxes, work only for admins or with sv_cheats 1 enabled")
local hg_show_hitbox_dir = ConVarExists("hg_show_hitbox_dir") and GetConVar("hg_show_hitbox_dir") or CreateClientConVar("hg_show_hitbox_dir", "0", false, false, "work only for admins or with sv_cheats 1 enabled")

hook.Add("PostDrawTranslucentRenderables", "homigrad-organism", function()
	if !hg_show_hitbox:GetBool() then return end
	if !LocalPlayer():IsAdmin() then return end

	local lply = LocalPlayer()
	local eyeAngles = lply:EyeAngles()

	for _, ply in player.Iterator() do
		if GetViewEntity() == ply then continue end

		ply = hg.GetCurrentCharacter(ply)

		local organs = hg.organism.GetHitBoxOrgans(ply:GetModel(), ply)

		if !organs then return end

		local boxs, pos, sphere = hg.organism.ShootMatrix(ply, organs)

		if hg_show_hitbox_dir:GetFloat() > 0 and hg.organism.Trace then
			local dir = Vector(hg_show_hitbox_dir:GetFloat(), 0, 0)
			dir:Rotate(eyeAngles)

			local distance = math_ceil(dir:Length())
			local start = hg.eyeTrace(lply).HitPos

			local endPos, hitBoxs, inputHole, outputHole = hg.organism.Trace(start, dir, 1, 0, boxs, pos, sphere, organs, false, hg.organism.Trace_Bullet, organs)

			render_DrawWireframeBox(start, eyeAngles, -Vector(0, distance / 50, distance / 50), Vector(distance, distance / 50, distance / 50))

			for i = 1, #boxs do
				local box = boxs[i]
				local organ = box[6] and organs[box[6]][box[7]]

				render_DrawWireframeBox(box[1], box[2], box[3], box[4], (hitBoxs[i] and white) or (organ and organ[6]) or black)
			end

			for i = 1, #inputHole do
				render.DrawWireframeSphere(inputHole[i], 1, 16, 16, red)
			end

			for i = 1, #outputHole do
				render.DrawWireframeSphere(outputHole[i], 0.5, 16, 16, blue)
			end
		else
			for i = 1, #boxs do
				local box = boxs[i]
				local organ = box[6] and organs[box[6]][box[7]]

				render_DrawWireframeBox(box[1], box[2], box[3], box[4], (organ and organ[6]) or black)
			end
		end
	end
end)
