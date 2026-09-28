hg = hg or {}
hg.organism = hg.organism or {}

concommand.Add("hg_organism_setvalue", function(ply, cmd, args)
	if !ply:IsAdmin() then return end

	if !args[3] then
		if isbool(ply.organism[args[1]]) then
			ply.organism[args[1]] = tonumber(args[2]) != 0
		else
			ply.organism[args[1]] = tonumber(args[2])
		end
	end

	if args[3] then
		for i, pl in pairs(player.GetListByName(args[3])) do
			if isbool(pl.organism[args[1]]) then
				pl.organism[args[1]] = tonumber(args[2]) != 0
			else
				pl.organism[args[1]] = tonumber(args[2])
			end
		end
	end
end)

concommand.Add("hg_organism_setvalue2", function(ply, cmd, args)
	if !ply:IsAdmin() then return end

	ply.organism[args[1]][tonumber(args[2])] = tonumber(args[3])
end)

concommand.Add("hg_organism_clear", function(ply, cmd, args)
	if !ply:IsAdmin() then return end

	if !args[1] then
		hg.organism.Clear(ply.organism)
	end

	if args[1] then
		for i, pl in pairs(player.GetListByName(args[1])) do
			hg.organism.Clear(pl.organism)
		end
	end
end)
