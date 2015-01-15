require("tmysql4");

include("fs_sh_report.lua")

AddCSLuaFile("fs_cl_report.lua")
AddCSLuaFile("fs_sh_report.lua")

//Insert your database information into the variables below
local fs_DBHost = "";	//Database Host IP/Domain Name/local host
local fs_DBUserName = "";	//Database Username
local fs_Password = "";	//Database Password
local fs_DBName = "";	//Database Name

local FS_Database = tmysql.initialize(fs_DBHost, fs_DBUserName, fs_Password, fs_DBName, "3306")

local serverID
timer.Simple(5, function()
	serverID = sv_identifier or 1
end)

util.AddNetworkString("sendReport")
util.AddNetworkString("sendReportNoPlayer")
net.Receive("sendReport", function()
	local title = net.ReadString()
	local reporter = net.ReadEntity()
	local ply = net.ReadEntity()
	local info = net.ReadString()
	
	local str = SQLStr
	
	FS_Database:Query( "REPLACE INTO pogreport(playerid, reporterid, comment, playernick, reporternick, serverid) VALUES(".. str(ply:SteamID()) .. "," .. str(reporter:SteamID()) .. "," .. str(info) .. "," .. str(ply:Nick()) .. "," .. str(reporter:Nick()).. "," .. str(serverID) .. ");", nil, 1)
	for k, v in pairs(player.GetAll()) do
		if v:IsAdmin() then
			v:ChatPrint("A new report has been submitted on this Server, Reporter: " .. reporter:Nick())
		end
	end
end)

net.Receive("sendReportNoPlayer", function()
	local title = net.ReadString()
	local reporter = net.ReadEntity()
	local info = net.ReadString()
	local str = SQLStr

	FS_Database:Query( "REPLACE INTO pogreport(playerid, reporterid, comment, playernick, reporternick, serverid) VALUES(".. str("No Player") .. "," .. str(reporter:SteamID()) .. "," .. str(info) .. "," .. str("No Player") .. "," .. str(reporter:Nick()).. "," .. str(serverID) .. ");", nil, 1)
	for k, v in pairs(player.GetAll()) do
		if v:IsAdmin() then
			v:ChatPrint("A new report has been submitted on this Server, Reporter: " .. reporter:Nick())
		end
	end
end)

util.AddNetworkString("sendReports")
local function requestReport(Player, results, status, error)
	if(results[1].status) then
	else
		ErrorNoHalt( error )
		return
	end
	if(results and results[1]) then
		net.Start("sendReports")
			net.WriteTable(results[1].data)
		net.Send(Player)
	end
end

function requestReportsChat(Player)
	if Player:IsAdmin() then
		FS_Database:Query( "SELECT * FROM pogreport ORDER BY time DESC LIMIT 25;", requestReport, 1, Player)
	end
end

util.AddNetworkString("requestReports")
net.Receive("requestReports", function()
	local ply = net.ReadEntity()
	if ply != nil and ply:IsPlayer() then
		FS_Database:Query( "SELECT * FROM pogreport ORDER BY time DESC LIMIT 25;", requestReport, 1, ply)
	end
end)

util.AddNetworkString("markResolved")
net.Receive("markResolved", function()
	local id = net.ReadString()
	FS_Database:Query( "UPDATE pogreport SET resolved = 1 WHERE id =" .. id .. ";", nil, 1)
end)