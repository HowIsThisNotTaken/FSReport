if (SERVER) then
	include("fs_report.lua")
elseif (CLIENT) then
	include("fs_cl_report.lua")
end