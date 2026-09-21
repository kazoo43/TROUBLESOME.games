
local hg_no_camera_in_cars = ConVarExists("hg_no_camera_in_cars") and GetConVar("hg_no_camera_in_cars") or CreateConVar("hg_no_camera_in_cars", "0", FCVAR_ARCHIVE + FCVAR_REPLICATED, "disables camera in cars", 0, 1)
local hg_no_fake_in_cars = ConVarExists("hg_no_fake_in_cars") and GetConVar("hg_no_fake_in_cars") or CreateConVar("hg_no_fake_in_cars", "0", FCVAR_ARCHIVE + FCVAR_REPLICATED, "disables fake in cars", 0, 1)

hg.vehicleragblacklist = hg.vehicleragblacklist or {}
hg.vehiclecamblacklist = hg.vehiclecamblacklist or {}

function hg.NoFakeInCar(veh)
    if hg_no_fake_in_cars:GetBool() then return true end
    if !IsValid(veh) then return end
	if veh:GetClass() == "prop_vehicle_crane" then return true end

    if hg.vehicleragblacklist[veh:GetClass()] then return true end

    if IsValid(veh:GetParent()) then
        if hg.vehicleragblacklist[veh:GetParent():GetClass()] then return true end
    end

    for i, veh2 in pairs(veh:GetChildren()) do
        if hg.vehicleragblacklist[veh2:GetClass()] then return true end
    end
end

function hg.NoCameraInCar(veh)
    if hg_no_camera_in_cars:GetBool() then return true end
    if !IsValid(veh) then return end
	if veh:GetClass() == "prop_vehicle_crane" then return true end

    if hg.vehiclecamblacklist[veh:GetClass()] then return true end

    if IsValid(veh:GetParent()) then
        if hg.vehiclecamblacklist[veh:GetParent():GetClass()] then return true end
    end

    for i, veh2 in pairs(veh:GetChildren()) do
        if hg.vehiclecamblacklist[veh2:GetClass()] then return true end
    end

    return false
end

if SERVER then
    local function send(ply)
        file.Write("zcity/vehicles_ragblacklist.json", util.TableToJSON(hg.vehicleragblacklist))
        file.Write("zcity/vehicles_camblacklist.json", util.TableToJSON(hg.vehiclecamblacklist))

        net.Start("SendVehicleRagBlacklist")
        net.WriteTable(hg.vehicleragblacklist)
        net.WriteTable(hg.vehiclecamblacklist)
        
        local rf = RecipientFilter()
        if IsValid(ply) and ply:IsPlayer() then
            rf:AddPlayer(ply)
        else
            rf:AddAllPlayers()
        end

        net.Send(rf)
    end

    hook.Add("InitPostEntity", "loadshitsssssssss4234234", function()
        file.CreateDir("zcity")

        local json = file.Read("zcity/vehicles_ragblacklist.json")
        if json then
            hg.vehicleragblacklist = util.JSONToTable(json) or {}
        end

        local json = file.Read("zcity/vehicles_camblacklist.json")
        if json then
            hg.vehiclecamblacklist = util.JSONToTable(json) or {}
        end
    end)

    util.AddNetworkString("SendVehicleRagBlacklist")

    concommand.Add("hg_addvehicletoragblacklist", function(ply, cmd, args)
        if ply:IsSuperAdmin() then
            hg.vehicleragblacklist[args[1]] = true

            send()
        end
    end)

    concommand.Add("hg_removevehiclefromragblacklist", function(ply, cmd, args)
        if ply:IsSuperAdmin() then            
            hg.vehicleragblacklist[args[1]] = nil

            send()
        end
    end)

    concommand.Add("hg_addvehicletocamblacklist", function(ply, cmd, args)
        if ply:IsSuperAdmin() then
            hg.vehiclecamblacklist[args[1]] = true

            send()
        end
    end)

    concommand.Add("hg_removevehiclefromcamblacklist", function(ply, cmd, args)
        if ply:IsSuperAdmin() then
            hg.vehiclecamblacklist[args[1]] = nil

            send()
        end
    end)

    net.Receive("SendVehicleRagBlacklist", function(len, ply)
        send(ply)
    end)
else
    net.Receive("SendVehicleRagBlacklist", function(len)
        hg.vehicleragblacklist = net.ReadTable()
        hg.vehiclecamblacklist = net.ReadTable()
    end)

    hook.Add("AddToolMenuCategories", "zcityvehicles", function()
        spawnmenu.AddToolCategory("Utilities", "zvehicles", "ZCity vehicle settings")
    end)

    hook.Add("PopulateToolMenu", "zcityvehicles", function()
        net.Start("SendVehicleRagBlacklist")
        net.SendToServer()

        spawnmenu.AddToolMenuOption("Utilities", "zvehicles", "zvehiclesmenu", "Vehicle ragdoll blacklist", "", "", function(panel)
            local dTextEntry, dLabel = panel:TextEntry("Type a vehicle class", "")

            local AppList = vgui.Create("DListView", panel)
            AppList:Dock(TOP)
            AppList:SetSize(panel:GetWide(), 200)
            AppList:SetMultiSelect(false)
            AppList:AddColumn("Blacklist")

            for veh, _ in pairs(hg.vehicleragblacklist) do
                AppList:AddLine(veh)
            end

            local button = panel:Button("Add", "")

            button.DoClick = function(self)
                if !lply:IsSuperAdmin() then return end

                local value = string.lower(dTextEntry:GetValue())
                
                if !hg.vehicleragblacklist[value] then
                    AppList:AddLine(value)

                    RunConsoleCommand("hg_addvehicletoragblacklist", value)
                end
            end

            local button2 = panel:Button("Remove", "")

            button2.DoClick = function(self)
                if !lply:IsSuperAdmin() then return end
                local index, pnl = AppList:GetSelectedLine()
                
                if pnl then
                    local value = pnl:GetValue(1)
                    
                    if hg.vehicleragblacklist[value] then
                        AppList:RemoveLine(index)

                        RunConsoleCommand("hg_removevehiclefromragblacklist", value)
                    end
                end
            end
        end)

        spawnmenu.AddToolMenuOption("Utilities", "zvehicles", "zvehiclesmenu2", "Vehicle camera blacklist", "", "", function(panel)
            local dTextEntry, dLabel = panel:TextEntry("Type a vehicle class", "" )

            local AppList = vgui.Create("DListView", panel)
            AppList:Dock(TOP)
            AppList:SetSize(panel:GetWide(), 200)
            AppList:SetMultiSelect(false)
            AppList:AddColumn("Blacklist")

            for veh, _ in pairs(hg.vehiclecamblacklist) do
                AppList:AddLine(veh)
            end

            local button = panel:Button("Add", "")

            button.DoClick = function(self)
                if !lply:IsSuperAdmin() then return end

                local value = string.lower(dTextEntry:GetValue())
                
                if !hg.vehiclecamblacklist[value] then
                    AppList:AddLine(value)

                    RunConsoleCommand("hg_addvehicletocamblacklist", value)
                end
            end

            local button2 = panel:Button("Remove", "")

            button2.DoClick = function(self)
                if !lply:IsSuperAdmin() then return end
                
                local index, pnl = AppList:GetSelectedLine()
                
                if pnl then
                    local value = pnl:GetValue(1)

                    if hg.vehiclecamblacklist[value] then
                        AppList:RemoveLine(index)

                        RunConsoleCommand("hg_removevehiclefromcamblacklist", value)
                    end
                end
            end
        end)
    end)

    -- totally not shamelessly copypasted from gmodwiki
end