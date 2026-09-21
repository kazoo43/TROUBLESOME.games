hg = hg or {}
hg.AdminSystem = hg.AdminSystem or {}

local AS = hg.AdminSystem

AS.Version = "2.0"
AS.Modules = AS.Modules or {}
AS.PlayerData = AS.PlayerData or {}

function AS:RegisterModule(name, module)
	if !name or !module then return false end
	self.Modules[name] = module
	module.Name = name
	return true
end


function AS:InitModules()
	for name, module in pairs(self.Modules) do
		if module.Init then
			module:Init()
		end
	end
end

function AS:SetPlayerData(ply, module, data)
	if !IsValid(ply) then return end
	local steamId = ply:SteamID64() or ply:SteamID()
	
	self.PlayerData[steamId] = self.PlayerData[steamId] or {}
	self.PlayerData[steamId][module] = data
end

if SERVER then
	util.AddNetworkString("AdminSystem_Sync")
	util.AddNetworkString("AdminSystem_ModuleAction")
	util.AddNetworkString("AdminSystem_Notification")
end

function AS:Notify(ply, message, notifyType)
end

hook.Add("InitPostEntity", "AdminSystem_Init", function()
	timer.Simple(1, function()
		if hg.AdminSystem.InitModules then
			hg.AdminSystem:InitModules()
		end
		hook.Run("AdminSystem_Loaded")
	end)
end)

if CLIENT then
	net.Receive("AdminSystem_Notification", function()
		net.ReadString()
		net.ReadUInt(4)
	end)
end
