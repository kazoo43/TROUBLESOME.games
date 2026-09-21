local MODE = MODE

--\\Neck Break
net.Receive("HMCD_BeingVictimOfNeckBreak", function(len, ply)
	LocalPlayer().BeingVictimOfNeckBreak = net.ReadBool()
	
	if(LocalPlayer().BeingVictimOfNeckBreak)then
		BeingVictimOfNeckBreakResetTime = CurTime() + 5
	else
		BeingVictimOfNeckBreakResetTime = nil
	end
end)

net.Receive("HMCD_BreakingOtherNeck", function(len, ply)
	local status = net.ReadBool()
	local attacker_ply = net.ReadEntity()
	
	if(status)then
		local other_ply = net.ReadEntity()
		
		if(IsValid(attacker_ply))then
			MODE.StartBreakingOtherNeck(LocalPlayer(), other_ply)
		end
	else
		if(IsValid(attacker_ply))then
			MODE.StopBreakingOtherNeck(LocalPlayer())
		end
	end
end)
--//

--\\
net.Receive("HMCD_BeingVictimOfDisarmament", function(len, ply)
	LocalPlayer().BeingVictimOfDisarmament = net.ReadBool()
	
	if(LocalPlayer().BeingVictimOfDisarmament)then
		BeingVictimOfDisarmamentResetTime = CurTime() + 5
	else
		BeingVictimOfDisarmamentResetTime = nil
	end
end)

net.Receive("HMCD_DisarmingOther", function(len, ply)
	local status = net.ReadBool()
	
	if(status)then
		local other_ply = net.ReadEntity()
		
		MODE.StartDisarmingOther(LocalPlayer(), other_ply)
	else
		MODE.StopDisarmingOther(LocalPlayer())
	end
end)
--//

--\\Chemical resistance
net.Receive("HMCD_UpdateChemicalResistance", function(len, ply)
	local chemical_name = net.ReadString()
	
	if(chemical_name == "")then
		LocalPlayer().PassiveAbility_ChemicalAccumulation = {}
		LocalPlayer().PassiveAbility_VGUI_ChemicalAccumulation = {}
	end
	
	while chemical_name != "" do
		local amt = net.ReadUInt(MODE.NetSize_ChemicalResistanceBits)
		
		SetChemicalToPlayer(LocalPlayer(), chemical_name, amt)
		
		chemical_name = net.ReadString()
	end
end)
--//

hook.Add("Think", "HMCD_SubRole_Abilities", function()
	if(BeingVictimOfNeckBreakResetTime and BeingVictimOfNeckBreakResetTime <= CurTime())then
		BeingVictimOfNeckBreakResetTime = nil
		LocalPlayer().BeingVictimOfNeckBreak = false
	end
	
	if(LocalPlayer().Ability_NeckBreak)then
		MODE.ContinueBreakingOtherNeck(LocalPlayer())
	end
	
	if(BeingVictimOfDisarmamentResetTime and BeingVictimOfDisarmamentResetTime <= CurTime())then
		BeingVictimOfDisarmamentResetTime = nil
		LocalPlayer().BeingVictimOfDisarmament = false
	end
	
	if(LocalPlayer().Ability_Disarm)then
		MODE.ContinueDisarmingOther(LocalPlayer())
	end
end)

hook.Add("hg_AdjustMouseSensitivity", "HMCD_SubRole_Abilities", function(sensitivity)
	if(LocalPlayer().BeingVictimOfNeckBreak)then
		return 0.1
	end
end)
