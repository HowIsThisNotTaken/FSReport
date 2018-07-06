include("fs_sh_report.lua")

local function BanBySTEAMID( id )
	local steami = id
	Derma_StringRequest( 
		"Ban Length for " .. steami , 
		"Ban Length for " .. steami,
		"",
		function( length ) 
			if not string.match( length, "[%d]" ) then
				chat.AddText(color_white, "Ban length must be a number!")
				return 
			end
			 Derma_StringRequest( 
				"Ban Reason for " .. steami , 
				"Reason for banning " .. steami,
				"",
				function( text ) 
					RunConsoleCommand("sm_addban", tonumber(length), steami, text)
				end,
				function() end
			)
		end,
		function() end
	)
end

local function OpenAddWarningMenu( Name )
	Derma_StringRequest( 
		"Add Warning " .. Name , 
		"Comment in warning for " .. Name,
		"",
		function( text ) 
			 RunConsoleCommand("say", "/addwarning " .. Name .. " " .. tostring(text))
		end,
		function() end
	)
end

net.Receive("sendReports", function()
	local info = net.ReadTable()
	local reportsFrame = vgui.Create( "DFrame" )
	local width, height = 1000, 700
	reportsFrame:SetPos( ScrW( ) / 2 - width / 2, ScrH( ) / 2 - height / 2 )
	reportsFrame:SetSize( width, height )
	reportsFrame:SetTitle( "View Reports" )
	reportsFrame:SetVisible( true )
	reportsFrame:SetDraggable( true )
	reportsFrame:ShowCloseButton( true )
	reportsFrame:MakePopup( )	
	
	local reportList = vgui.Create( "DListView", reportsFrame )
	reportList:SetWide( 440 )
	reportList:SetTall( 680 )
	reportList:DockMargin( 10, 10, 10, 10 )
	reportList:Dock( LEFT )
	reportList:SetMultiSelect( false )
	reportList:AddColumn( "Time" ):SetWidth(110)
	reportList:AddColumn( "Player Name" ):SetWidth( 110 )
	reportList:AddColumn( "Reporter Name" ):SetWidth( 110 )
	reportList:AddColumn( "Server #" ):SetWidth( 110 )
	function reportList:reload( )
		local selectedReportId = nil
		if self:GetSelectedLine( ) then
			selectedReportId = self:GetLine( self:GetSelectedLine( ) ).report.id
		end
		local selectedItem = nil
		
		self:Clear( )
		for k, report in pairs( info ) do
			local line = reportList:AddLine( report.time, 
				report.playernick,
				report.reporternick,
				report.serverid)
			
			function line:GetColumnText( i )
				if i == 5 then --Warning Level
					if self.Columns[i] then
						return self.Columns[i].Value != "" and self.Columns[i].Value or 0
					else
						return 0
					end
				end
				return self.Columns[i] and self.Columns[i].value or ""
			end
				
			line.report = report
			if line.report.id == selectedReportId then
				selectedItem = line
			end
			function line:Paint( )
				self:SizeToContents( )
				local highlightColor 
				
				if self.report.resolved == 0 then 
					highlightColor = Color( 255, 0, 0, 180)
				else
					highlightColor = Color( 0, 255, 0, 150 )
				end
				
				//highlightColor = Color( 0, 255, 0, 150 )
				if self:IsLineSelected( ) then
					surface.SetDrawColor( 0, 0, 255, 255 )
					surface.DrawRect( 0, 0, self:GetWide( ), self:GetTall( ) )
					surface.SetDrawColor( Color( 0, 0, 255, 255 ) )
					surface.DrawRect( 2, 2, self:GetWide( ) - 4, self:GetTall( ) - 4 )
				else
					surface.SetDrawColor( highlightColor )
					surface.DrawRect( 0, 0, self:GetWide( ), self:GetTall( ) )
				end
			end
		end
		if not selectedItem then 
			self:SelectFirstItem( ) 
		else
			self:SelectItem( selectedItem )
		end
	end
	reportList:reload( )
//	LocalPlayer( ).reportList = reportList
	
	local rightPanel = vgui.Create( "DPanel", reportsFrame )
	rightPanel:DockMargin( 0, 10, 10, 10 )
	rightPanel:SetWide( 520 )
	rightPanel:SetTall( 680 )
	rightPanel:Dock( FILL )
	
	local topPanelLeft = vgui.Create( "DPanel", rightPanel )
	topPanelLeft:SetPos( 5, 5 )
	topPanelLeft:SetWide( 270 )
	topPanelLeft:SetTall( 100 )
	local infoLabelLeft = vgui.Create( "DLabel", topPanelLeft )
	infoLabelLeft:SetPos( 5, 5 )
	
	local topPanelRight = vgui.Create( "DPanel", rightPanel )
	topPanelRight:SetPos( 280, 5 )
	topPanelRight:SetWide( 270 )
	topPanelRight:SetTall( 100 )
	local infoLabelRight = vgui.Create( "DLabel", topPanelRight )
	infoLabelRight:SetPos( 5, 5 )
	
	local reasonEntry = vgui.Create( "DTextEntry", rightPanel )
	reasonEntry:SetPos( 5, 110 )
	reasonEntry:SetWide( 540 )
	reasonEntry:SetTall( 100 )
	reasonEntry:SetMultiline( true )
	reasonEntry:SetEnabled( false )

	function reportList:OnRowSelected( line ) 
		local report = self:GetLine( line ).report
		infoLabelLeft:SetText( string.format( "Report Info:\n\nTime: %s\nPlayer Nick: %s\nPlayer STEAMID: %s\nReporter Nick: %s\n", tostring(report.time), tostring(report.playernick), tostring(report.playerid), tostring(report.reporternick)))
		infoLabelLeft:SetTextColor( Color(0, 0, 0, 255) )
		infoLabelLeft:SizeToContents( )
		infoLabelRight:SetText( string.format( "Report Info:\n\nTime: %s\nPlayer Nick: %s\nPlayer STEAMID: %s\nReporter Nick: %s\n", tostring(report.time), tostring(report.playernick), tostring(report.playerid), tostring(report.reporternick)))
		infoLabelRight:SetTextColor( Color(0, 0, 0, 255) )
		infoLabelRight:SizeToContents( )
		reasonEntry:SetText( tostring(report.comment) )
		reasonEntry:SetTextColor( Color(0, 0, 0, 255) )
	end
	
	function reportList:OnRowRightClick( line )
		local menu = DermaMenu( )
		local report = self:GetLine( line ).report
		local selectedDbId = self:GetLine( line ).report.id
		menu:AddOption( "Goto Reporter", function( )
			LocalPlayer():ConCommand("fs_GoToPlayer " .. tostring(report.reporternick))
		end )
		menu:AddOption( "Goto Offender", function( ) 
			LocalPlayer():ConCommand("fs_GoToPlayer " .. tostring(report.playernick))
		end )
		menu:AddOption( "Bring Reporter", function( )
			LocalPlayer():ConCommand("fs_Bring " .. tostring(report.reporternick))
		end )
		menu:AddOption( "Bring Offender", function( ) 
			LocalPlayer():ConCommand("fs_Bring " .. tostring(report.playernick))
		end )
		menu:AddOption( "Spectate Offender", function( ) 
			LocalPlayer():ConCommand("pog_spectate " .. tostring(report.playernick))
		end )
		menu:AddOption( "Stop Spectate (Or pog_spectate_stop)", function( ) 
			LocalPlayer():ConCommand("pog_spectate_stop")
		end )
		menu:AddOption( "View Warnings (Local, must be on same Server)", function() RunConsoleCommand("say", "/warning " .. report.playernick .. " w") end)
		menu:AddOption( "Give Warning (Local, must be on same Server)", function( ) 
			OpenAddWarningMenu(report.playernick)
			self:GetLine(line).report.resolved = 1
		end )
		menu:AddOption( "Ban Offender (Global, bans by STEAMID)", function( ) 
			BanBySTEAMID(report.playerid)
			self:GetLine(line).report.resolved = 1
		end )
		menu:AddOption( "Mark as Resolved", function()
			self:GetLine(line).report.resolved = 1
			net.Start("markResolved")
				net.WriteString(selectedDbId)
			net.SendToServer()
		end)
		menu:Open( )
	end
end)