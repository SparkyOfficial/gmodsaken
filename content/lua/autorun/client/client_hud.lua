function TF_CustomHUDPaint()
	if(!LocalPlayer() or !LocalPlayer():IsValid()) then
		return
	end
	local scale_w = LocalPlayer():GetPanelScale()[1]
	local scale_h = LocalPlayer():GetPanelScale()[2]
	
	local team = LocalPlayer():Team()
	if team == 1 then
		team = "blue"
	else
		team = "red"
	end	
	
	local tr = util.TraceLine(util.GetPlayerTrace(LocalPlayer()))
	if(tr.HitNonWorld) then
		local objs = { "obj_sentrygun", "obj_teleporter_entrance", "obj_teleporter_exit", "obj_dispenser" }
		if(ValidEntity(tr.Entity) and table.HasValue( objs, tr.Entity:GetClass() ) and !LocalPlayer():InVehicle() and tr.Entity:GetNetworkedEntity( "owner" ) and ValidEntity(tr.Entity:GetNetworkedEntity( "owner" ))) then
			local targetname
			if tr.Entity:GetClass() == "obj_sentrygun" then
				targetname = "Sentry"
			elseif tr.Entity:GetClass() == "obj_teleporter_entrance" then
				targetname = "Teleporter Entrance"
			elseif tr.Entity:GetClass() == "obj_teleporter_exit" then
				targetname = "Teleporter Exit"
			else
				targetname = "Dispenser"
			end
			
			local Message = targetname .. " built by " .. tr.Entity:GetNetworkedEntity( "owner" ):GetName()
			
			surface.SetFont("Default")
			local Width, Height = surface.GetTextSize(Message)
			Height = Height *2
			local width_lesser = 0
			local class = tr.Entity:GetClass()
			Width = Width + 25
			if class == "obj_dispenser" then
				width_lesser = 25
			elseif class == "obj_teleporter_exit" then
				width_lesser = 63
			elseif class == "obj_teleporter_entrance" then
				width_lesser = 96
			end
			
			local tex=surface.GetTextureID("HUD/objectives_timepanel_" .. team .. "_bg")
			surface.SetTexture(tex)
			surface.SetDrawColor(255,255,255,255)
			
			local ply_name = tr.Entity:GetNetworkedEntity( "owner" ):GetName()

			local building
			if class == "obj_sentrygun" then
				building = "Sentry Gun"
			elseif class == "obj_dispenser" then
				building = "Dispenser"
			elseif class == "obj_teleporter_entrance" then
				building = "Teleporter Entrance"
			elseif class == "obj_teleporter_exit" then
				building = "Teleporter Exit"
			end

			surface.SetFont( "TF2_font2" )
			local str_w, str_h = surface.GetTextSize( building )
			str_w = str_w /2
			
			str_w = str_w +surface.GetTextSize( ply_name ) /2
			local width = 680
			if surface.GetTextSize( building .. " built by " .. ply_name ) > 480 then
				width = width +(surface.GetTextSize( building .. " built by " .. ply_name ) -480)
			end
			
			surface.DrawTexturedRect(ScrW() *0.5 -(width /scale_w) /2, ScrH() *0.51, width /scale_w, 110 /scale_h )
			
			draw.SimpleText(building .. " built by " .. ply_name, "TF2_font2", ScrW() *0.63 -(width /scale_w) /2 +str_w, ScrH() *0.54, Color(255, 255, 255, 255), 1, 1)
			if class == "obj_sentrygun" and tr.Entity:GetNetworkedInt("sentrygun_level") != 3 then
				draw.SimpleText("Upgrade Progress: " .. 200 -tr.Entity:GetNetworkedInt( "upgrade" ) .. " / 200", "TF2_font1", ScrW() *0.7 -(width /scale_w) /2, ScrH() *0.568, Color(255, 255, 255, 255), 1, 1)
			end
			
			local tex=surface.GetTextureID("HUD/health_equip_bg")
			surface.SetTexture(tex)
			surface.DrawTexturedRect(ScrW() *0.53 -(width /scale_w) /2, ScrH() *0.525, 76 /scale_w, 76 /scale_h )
			//BUILDING HEALTH DISPLAY
			local health = tr.Entity:GetNetworkedInt("health")
			local health_max = 150
			local sentry_level = tr.Entity:GetNetworkedInt("sentrygun_level")
			if class == "obj_sentrygun" and sentry_level != 1 then
				if sentry_level == 2 then
					health_max = 180
				else
					health_max = 216
				end
			end
			
			local scale_bottom
			if health <= health_max /3 then
				scale_bottom = (health /(health_max /3)) *18
			else
				scale_bottom = 18
			end
			
			local scale_top
			if health > (health_max /3) *2 and health <= health_max then
				scale_top = ((health -(health_max /3) *2) /(health_max /3)) *18
			elseif health > health_max then
				scale_top = 18
			else
				scale_top = nil
			end
			
			local scale_middle
			if health >= health_max /3 and health <= (health_max /3) *2 then
				scale_middle = ((health -(health_max /3)) /(health_max /3)) *60
			elseif health > (health_max /3) *2 then
				scale_middle = 60
			else
				scale_middle = nil
			end
			
			surface.SetTexture(surface.GetTextureID("HUD/health_bg"))
			surface.SetDrawColor(255,255,255,255)
			surface.DrawTexturedRect(ScrW() *0.539 -(width /scale_w) /2, ScrH() *0.532, 60 /scale_w, 60 /scale_h )	
			//surface.DrawTexturedRect((ScrW() -width) *0.325, ScrH() *0.532, 60 /scale_w, 60 /scale_h )	
			
			local health_bg_middle = "HUD/health_color_middle"
			local health_bg_bottom = "HUD/health_color_bottom"
			if health <= 1.5 *49 then
				health_bg_middle = health_bg_middle .. "_red"
				health_bg_bottom = health_bg_bottom .. "_red"
			end
			
			if scale_middle then
				surface.SetTexture(surface.GetTextureID(health_bg_middle))
				local w,h = surface.GetTextureSize( surface.GetTextureID("HUD/health_color_middle") )
				surface.DrawTexturedRect(ScrW() *0.541 -(width /scale_w) /2, ScrH() *0.564 -(h *((scale_middle /scale_h) /100)) /2, 54 /scale_w, scale_middle /scale_h )
			end
			
			if scale_top then
				surface.SetTexture(surface.GetTextureID("HUD/health_color_top"))
				surface.DrawTexturedRect(ScrW() *0.552 -(width /scale_w) /2, ScrH() *0.512 +((45 /scale_h) -(scale_top /scale_h)), 18 /scale_w, scale_top /scale_h )
			end
			
			surface.SetTexture(surface.GetTextureID(health_bg_bottom))
			surface.DrawTexturedRect(ScrW() *0.552 -(width /scale_w) /2, ScrH() *0.542 +((45 /scale_h) -(scale_bottom /scale_h)), 18 /scale_w, scale_bottom /scale_h )
			//HEALTH DISPLAY END
			
			//draw.RoundedBox(4, ScrW() - (Width + 1150), (ScrH()/2 - 100) - (8), Width + 8, Height + 8, Color(0, 0, 0, 150))
			//draw.SimpleText(Message, "Default", ScrW() - (Width + 1075 -width_lesser) - 7, ScrH()/2 - 100, Color(255, 255, 255, 255), 1, 1)
			//draw.SimpleText("Health: " .. tr.Entity:GetNetworkedInt( "health" ), "Default", ScrW() - (Width + 1085) - 7, ScrH()/2 - 85, Color(255, 255, 255, 255), 1, 1)
			if tr.Entity:GetClass() == "obj_teleporter_entrance" then
				if !tr.Entity:GetNetworkedBool("building") and !tr.Entity:GetNetworkedBool( "gotexit" ) then
					draw.SimpleText("No matching exit!", "TF2_font1", ScrW() *0.656 -(width /scale_w) /2, ScrH() *0.568, Color(255, 255, 255, 255), 1, 1)
				end
				local recharge = tr.Entity:GetNetworkedInt( "recharge" )
				if recharge < 100 and recharge > 0 then
					surface.SetFont( "TF2_font1" )
					local w, h = surface.GetTextSize(recharge)
					draw.SimpleText("Recharging: " .. recharge .. "%", "TF2_font1", ScrW() *0.638 +w /2 -(width /scale_w) /2, ScrH() *0.568, Color(255, 255, 255, 255), 1, 1)
				end
			elseif tr.Entity:GetClass() == "obj_teleporter_exit" and !tr.Entity:GetNetworkedBool( "gotentrance" ) and !tr.Entity:GetNetworkedBool("building") then
				draw.SimpleText("No matching entrance!", "TF2_font1", ScrW() *0.45, ScrH() *0.568, Color(255, 255, 255, 255), 1, 1)
			end
		elseif(ValidEntity(tr.Entity) and tr.Entity:GetNetworkedBool( 10 ) and !LocalPlayer():InVehicle()) then
			local message = "Possessed by " .. tr.Entity:GetNetworkedEntity( 11 ):GetName()
			surface.SetFont("Default")
			local Width, Height = surface.GetTextSize(message)
			Height = Height *2
			Width = Width + 25
			local color = Color(255,255,255,255)
			draw.SimpleText(message, "Default", ScrW( ) /2, ScrH( ) /2, color, 1, 1)
		end
	end
	surface.SetDrawColor(255,255,255,255)
	local sentry = LocalPlayer():GetNetworkedEntity("sentrygun")
	local dispenser = LocalPlayer():GetNetworkedEntity("dispenser")
	local tp_entrance = LocalPlayer():GetNetworkedEntity("tp_entrance")
	local tp_exit = LocalPlayer():GetNetworkedEntity("tp_exit")
	
	//if sentry_sapped or dispenser_sapped or tp_entrance_sapped or tp_exit_sapped or (sentry_health and sentry_health <= 75) or (dispenser_health and dispenser_health <= 75) or (tp_entrance_health and tp_entrance_health <= 75) or (tp_exit_health and tp_exit_health <= 75) then
	local function SetAlertColor()
		local color = LocalPlayer():GetNetworkedInt("sapped_building_color")
		if color >= 240 then LocalPlayer():SetNetworkedBool("sapped_building_color_goup", false) end
		if color <= 15 then LocalPlayer():SetNetworkedBool("sapped_building_color_goup", true) end
		if LocalPlayer():GetNetworkedBool("sapped_building_color_goup") then
			LocalPlayer():SetNetworkedInt("sapped_building_color", color +35)
		else
			LocalPlayer():SetNetworkedInt("sapped_building_color", color -35)
		end
	end
	
	
	if ValidEntity(sentry) then
		surface.SetDrawColor(255,255,255,255)
		local sapped = sentry:GetNetworkedBool("sapped")
		local building = sentry:GetNetworkedBool("building")
		local sentry_level = sentry:GetNetworkedInt("sentrygun_level")
		local max_health
		if sentry_level == 1 then max_health = 150 elseif sentry_level == 2 then max_health = 180 else max_health = 216 end
		if sapped or (sentry:GetNetworkedInt("health") < max_health and !building) then
			SetAlertColor()
			local color = LocalPlayer():GetNetworkedInt("sapped_building_color")
			surface.SetDrawColor(255,color,color,255)
			surface.SetTexture(surface.GetTextureID("HUD/eng_status_area_sentry_alrt_ren"))
			surface.DrawTexturedRect(ScrW() *0.19, ScrH() *0.015, 135 /scale_w, 180 /scale_h )
			
			surface.SetDrawColor(255,255,255,255)
			
			if sapped then
				surface.SetTexture(surface.GetTextureID("HUD/hud_obj_status_sapper"))
				surface.DrawTexturedRect(ScrW() *0.197, ScrH() *0.048, 60 /scale_w, 60 /scale_h )
			else
				surface.SetTexture(surface.GetTextureID("HUD/eng_status_alert_ico_wrench"))
				surface.DrawTexturedRect(ScrW() *0.197, ScrH() *0.048, 60 /scale_w, 60 /scale_h )
			end
		end
		surface.SetTexture(surface.GetTextureID("HUD/eng_status_area_sentry_" .. team))
		surface.DrawTexturedRect(ScrW() *0.01, ScrH() *0.015, 320 /scale_w, 180 /scale_h )
		
		surface.SetTexture(surface.GetTextureID("HUD/hud_obj_status_sentry_" .. sentry_level))
		surface.DrawTexturedRect(ScrW() *0.046, ScrH() *0.035, 100 /scale_w, 100 /scale_h )
		if !building then
			draw.SimpleText("Shells:", "TF2_engineer_hud_font1", ScrW( ) *0.123, ScrH( ) *0.034, Color(245,229,194,255), 1, 1)
			
			local tex=surface.GetTextureID("HUD/uber_bg")
			surface.SetTexture(tex)
			surface.SetDrawColor(255,255,255,255)
			surface.DrawTexturedRect(ScrW() *0.108, ScrH() *0.045, 125 /scale_w, 22 /scale_h )
					
			local ammo_max
			if sentry_level == 1 then
				ammo_max = 44
			elseif sentry_level == 2 then
				ammo_max = 64
			else
				ammo_max = 160
			end
			
			local shells = sentry:GetNetworkedInt( "shells" )
			local width = (shells /ammo_max) *125
			if width > 125 then width = 125 end
			
			local tex=surface.GetTextureID("HUD/building_bar_color")
			if shells <= (ammo_max /100) *20 then
				tex = surface.GetTextureID("HUD/building_bar_color_red")
			end
			
			surface.SetTexture(tex)
			surface.SetDrawColor(255,255,255,255)
			surface.DrawTexturedRect(ScrW() *0.108, ScrH() *0.045, width /scale_w, 22 /scale_h )
			
			local tex=surface.GetTextureID("HUD/uber_bg")
			surface.SetTexture(tex)
			surface.SetDrawColor(255,255,255,255)
			surface.DrawTexturedRect(ScrW() *0.108, ScrH() *0.086, 125 /scale_w, 22 /scale_h )

			if sentry_level < 3 then
				draw.SimpleText("Upgrade:", "TF2_engineer_hud_font1", ScrW( ) *0.129, ScrH( ) *0.075, Color(245,229,194,255), 1, 1)
				local width = ((200 -sentry:GetNetworkedInt( "upgrade" )) /200) *125
				
				local tex=surface.GetTextureID("HUD/building_bar_color")
				surface.SetTexture(tex)
				surface.SetDrawColor(255,255,255,255)
				surface.DrawTexturedRect(ScrW() *0.108, ScrH() *0.086, width /scale_w, 22 /scale_h )
			else
				draw.SimpleText("Rockets:", "TF2_engineer_hud_font1", ScrW( ) *0.129, ScrH( ) *0.075, Color(245,229,194,255), 1, 1)
				local rockets = sentry:GetNetworkedInt( "rockets" )
				local width = ( rockets /20) *125
				
				local tex=surface.GetTextureID("HUD/building_bar_color")
				if rockets <= 5 then
					tex = surface.GetTextureID("HUD/building_bar_color_red")
				end
				
				surface.SetTexture(tex)
				surface.SetDrawColor(255,255,255,255)
				surface.DrawTexturedRect(ScrW() *0.108, ScrH() *0.086, width /scale_w, 22 /scale_h )
			end
			
			local message = sentry:GetNetworkedInt("kills")
			surface.SetFont("TF2_engineer_hud_font1")
			local Width, Height = surface.GetTextSize(message)
			draw.SimpleText("Kills: " .. message, "TF2_engineer_hud_font1", ScrW( ) *0.122 +Width /2, ScrH( ) *0.115, Color(245,229,194,255), 1, 1)
		else
			draw.SimpleText("Building...", "TF2_engineer_hud_font1", ScrW( ) *0.128, ScrH( ) *0.065, Color(245,229,194,255), 1, 1)
			surface.SetTexture(surface.GetTextureID("HUD/uber_bg"))
			surface.SetDrawColor(255,255,255,255)
			surface.DrawTexturedRect(ScrW() *0.105, ScrH() *0.075, 125 /scale_w, 22 /scale_h )
			
			local health = sentry:GetNetworkedInt( "health" )
			local width = math.ceil((health /150) *125)
			
			surface.SetTexture(surface.GetTextureID("HUD/building_bar_color"))
			surface.DrawTexturedRect(ScrW() *0.105, ScrH() *0.075, width /scale_w, 22 /scale_h )
		end
		
		surface.SetTexture(surface.GetTextureID("HUD/building_bar_health"))
		local health = sentry:GetNetworkedInt("health")
		local max_health
		if sentry_level == 1 then max_health = 150 elseif sentry_level == 2 then max_health = 180 else max_health = 216 end

		local bars = math.ceil((health /max_health) *14)
		if bars > 14 then bars = 14 end
		if bars <= 6 then
			surface.SetTexture(surface.GetTextureID("HUD/building_bar_health_red"))
		end
		local pos_y = 0.1225
		for i = 1, bars do
			surface.DrawTexturedRect(ScrW() *0.028, ScrH() *pos_y, 20 /scale_w, 19 /scale_h )
			pos_y = pos_y -0.008
		end
		
		local pos_y = 0.023
		for i = 1, 14 -bars do
			draw.RoundedBox(0, ScrW() *0.028, ScrH() *pos_y, 20 /scale_w, 7 /scale_h, Color(255, 255, 255, 50))
			pos_y = pos_y +0.008
		end
	end
	if ValidEntity(dispenser) then
		surface.SetDrawColor(255,255,255,255)
		local sapped = dispenser:GetNetworkedBool("sapped")
		local building = dispenser:GetNetworkedBool("building")
		if sapped or (dispenser:GetNetworkedInt("health") < 150 and !building) then
			SetAlertColor()
			local color = LocalPlayer():GetNetworkedInt("sapped_building_color")
			surface.SetDrawColor(255,color,color,255)
			surface.SetTexture(surface.GetTextureID("HUD/eng_status_area_tele_alrt_ren"))
			surface.DrawTexturedRect(ScrW() *0.19, ScrH() *0.145, 135 /scale_w, 80 /scale_h )
			
			surface.SetDrawColor(255,255,255,255)
			
			if sapped then
				surface.SetTexture(surface.GetTextureID("HUD/hud_obj_status_sapper"))
				surface.DrawTexturedRect(ScrW() *0.197, ScrH() *0.15, 60 /scale_w, 60 /scale_h )
			else
				surface.SetTexture(surface.GetTextureID("HUD/eng_status_alert_ico_wrench"))
				surface.DrawTexturedRect(ScrW() *0.197, ScrH() *0.15, 60 /scale_w, 60 /scale_h )
			end
		end
	
		surface.SetTexture(surface.GetTextureID("HUD/eng_status_area_tele_" .. team))
		surface.DrawTexturedRect(ScrW() *0.01, ScrH() *0.145, 320 /scale_w, 80 /scale_h )
		
		surface.SetTexture(surface.GetTextureID("HUD/hud_obj_status_dispenser"))
		surface.DrawTexturedRect(ScrW() *0.055, ScrH() *0.1475, 72 /scale_w, 72 /scale_h )
		if !building then
			surface.SetTexture(surface.GetTextureID("HUD/ico_metal"))
			surface.DrawTexturedRect(ScrW() *0.105, ScrH() *0.154, 25 /scale_w, 25 /scale_h )
			
			local tex=surface.GetTextureID("HUD/uber_bg")
			surface.SetTexture(tex)
			surface.SetDrawColor(255,255,255,255)
			surface.DrawTexturedRect(ScrW() *0.105, ScrH() *0.18, 125 /scale_w, 22 /scale_h )
			
			local msg_sep = string.Explode( ".", dispenser:GetNetworkedInt( "resources" ) )
			local width = (msg_sep[1] /100) *125
			
			local tex=surface.GetTextureID("HUD/building_bar_color")
			surface.SetTexture(tex)
			surface.SetDrawColor(255,255,255,255)
			surface.DrawTexturedRect(ScrW() *0.105, ScrH() *0.18, width /scale_w, 22 /scale_h )
		else
			draw.SimpleText("Building...", "TF2_engineer_hud_font1", ScrW( ) *0.128, ScrH( ) *0.17, Color(245,229,194,255), 1, 1)
			surface.SetTexture(surface.GetTextureID("HUD/uber_bg"))
			surface.SetDrawColor(255,255,255,255)
			surface.DrawTexturedRect(ScrW() *0.105, ScrH() *0.18, 125 /scale_w, 22 /scale_h )
			
			local health = dispenser:GetNetworkedInt( "health" )
			local width = math.ceil((health /150) *125)
			
			surface.SetTexture(surface.GetTextureID("HUD/building_bar_color"))
			surface.DrawTexturedRect(ScrW() *0.105, ScrH() *0.18, width /scale_w, 22 /scale_h )
		end
		
		surface.SetTexture(surface.GetTextureID("HUD/building_bar_health"))
		local health = dispenser:GetNetworkedInt("health")
		local bars = math.ceil((health /150) *6)
		if bars <= 2 then
			surface.SetTexture(surface.GetTextureID("HUD/building_bar_health_red"))
		end
		local pos_y = 0.192
		for i = 1, bars do
			surface.DrawTexturedRect(ScrW() *0.028, ScrH() *pos_y, 20 /scale_w, 19 /scale_h )
			pos_y = pos_y -0.008
		end

		local pos_y = 0.152
		for i = 1, 6 -bars do
			draw.RoundedBox(0, ScrW() *0.028, ScrH() *pos_y, 20 /scale_w, 10 /scale_h, Color(255, 255, 255, 50))
			pos_y = pos_y +0.009
		end
	end
	if ValidEntity(tp_entrance) then
		surface.SetDrawColor(255,255,255,255)
		local sapped = tp_entrance:GetNetworkedBool("sapped")
		local building = tp_entrance:GetNetworkedBool("building")
		if sapped or (tp_entrance:GetNetworkedInt("health") < 150 and !building) then
			SetAlertColor()
			local color = LocalPlayer():GetNetworkedInt("sapped_building_color")
			surface.SetDrawColor(255,color,color,255)
			surface.SetTexture(surface.GetTextureID("HUD/eng_status_area_tele_alrt_ren"))
			surface.DrawTexturedRect(ScrW() *0.19, ScrH() *0.21, 135 /scale_w, 80 /scale_h )
			
			surface.SetDrawColor(255,255,255,255)
			
			if sapped then
				surface.SetTexture(surface.GetTextureID("HUD/hud_obj_status_sapper"))
				surface.DrawTexturedRect(ScrW() *0.197, ScrH() *0.216, 60 /scale_w, 60 /scale_h )
			else
				surface.SetTexture(surface.GetTextureID("HUD/eng_status_alert_ico_wrench"))
				surface.DrawTexturedRect(ScrW() *0.197, ScrH() *0.216, 60 /scale_w, 60 /scale_h )
			end
		end
		surface.SetTexture(surface.GetTextureID("HUD/eng_status_area_tele_" .. team))
		surface.DrawTexturedRect(ScrW() *0.01, ScrH() *0.21, 320 /scale_w, 80 /scale_h )
		
		surface.SetTexture(surface.GetTextureID("HUD/hud_obj_status_tele_entrance"))
		surface.DrawTexturedRect(ScrW() *0.055, ScrH() *0.21, 72 /scale_w, 72 /scale_h )
		if !building then
			local recharge = tp_entrance:GetNetworkedInt( "recharge" )
			if recharge < 100 and recharge > 0 then
				surface.SetFont( "TF2_font1" )
				local Width, Height = surface.GetTextSize(recharge)
				draw.SimpleText("Charging...", "TF2_engineer_hud_font1", ScrW( ) *0.13, ScrH( ) *0.232, Color(245,229,194,255), 1, 1)
				
				surface.SetTexture(surface.GetTextureID("HUD/uber_bg"))
				surface.DrawTexturedRect(ScrW() *0.105, ScrH() *0.242, 125 /scale_w, 22 /scale_h )
				
				local width = (recharge /100) *125
				surface.SetTexture(surface.GetTextureID("HUD/building_bar_color"))
				surface.DrawTexturedRect(ScrW() *0.105, ScrH() *0.242, width /scale_w, 22 /scale_h )
			else
				draw.SimpleText("Times Used:", "TF2_engineer_hud_font1", ScrW( ) *0.135, ScrH( ) *0.235, Color(245,229,194,255), 1, 1)
				local message = tp_entrance:GetNetworkedInt("teleportamt")
				surface.SetFont("TF2_engineer_hud_font1")
				local Width, Height = surface.GetTextSize(message)
				draw.SimpleText(tp_entrance:GetNetworkedInt("teleportamt"), "TF2_engineer_hud_font1", ScrW( ) *0.108 +Width /2, ScrH( ) *0.25, Color(245,229,194,255), 1, 1)
			end
		else
			draw.SimpleText("Building...", "TF2_engineer_hud_font1", ScrW( ) *0.128, ScrH( ) *0.232, Color(245,229,194,255), 1, 1)
			surface.SetTexture(surface.GetTextureID("HUD/uber_bg"))
			surface.SetDrawColor(255,255,255,255)
			surface.DrawTexturedRect(ScrW() *0.105, ScrH() *0.242, 125 /scale_w, 22 /scale_h )
			
			local health = tp_entrance:GetNetworkedInt( "health" )
			local width = math.ceil((health /150) *125)
			
			surface.SetTexture(surface.GetTextureID("HUD/building_bar_color"))
			surface.DrawTexturedRect(ScrW() *0.105, ScrH() *0.242, width /scale_w, 22 /scale_h )
		end
		
		surface.SetTexture(surface.GetTextureID("HUD/building_bar_health"))
		local health = tp_entrance:GetNetworkedInt("health")
		local bars = math.ceil((health /150) *6)
		if bars <= 2 then
			surface.SetTexture(surface.GetTextureID("HUD/building_bar_health_red"))
		end
		local pos_y = 0.256
		for i = 1, bars do
			surface.DrawTexturedRect(ScrW() *0.028, ScrH() *pos_y, 20 /scale_w, 19 /scale_h )
			pos_y = pos_y -0.008
		end
		
		local pos_y = 0.218
		for i = 1, 6 -bars do
			draw.RoundedBox(0, ScrW() *0.028, ScrH() *pos_y, 20 /scale_w, 8 /scale_h, Color(255, 255, 255, 50))
			pos_y = pos_y +0.0086
		end
	end
	
	if ValidEntity(tp_exit) then
		surface.SetDrawColor(255,255,255,255)
		local sapped = tp_exit:GetNetworkedBool("sapped")
		local building = tp_exit:GetNetworkedBool("building")
		if sapped or (tp_exit:GetNetworkedInt("health") < 150 and !building) then
			SetAlertColor()
			local color = LocalPlayer():GetNetworkedInt("sapped_building_color")
			surface.SetDrawColor(255,color,color,255)
			surface.SetTexture(surface.GetTextureID("HUD/eng_status_area_tele_alrt_ren"))
			surface.DrawTexturedRect(ScrW() *0.19, ScrH() *0.275, 135 /scale_w, 80 /scale_h )
			
			surface.SetDrawColor(255,255,255,255)
			
			if sapped then
				surface.SetTexture(surface.GetTextureID("HUD/hud_obj_status_sapper"))
				surface.DrawTexturedRect(ScrW() *0.197, ScrH() *0.281, 60 /scale_w, 60 /scale_h )
			else
				surface.SetTexture(surface.GetTextureID("HUD/eng_status_alert_ico_wrench"))
				surface.DrawTexturedRect(ScrW() *0.197, ScrH() *0.281, 60 /scale_w, 60 /scale_h )
			end
		end
		surface.SetTexture(surface.GetTextureID("HUD/eng_status_area_tele_" .. team))
		surface.DrawTexturedRect(ScrW() *0.01, ScrH() *0.275, 320 /scale_w, 80 /scale_h )
		
		surface.SetTexture(surface.GetTextureID("HUD/hud_obj_status_tele_exit"))
		surface.DrawTexturedRect(ScrW() *0.055, ScrH() *0.27, 72 /scale_w, 72 /scale_h )
		
		if building then
			draw.SimpleText("Building...", "TF2_engineer_hud_font1", ScrW( ) *0.128, ScrH( ) *0.295, Color(245,229,194,255), 1, 1)
			surface.SetTexture(surface.GetTextureID("HUD/uber_bg"))
			surface.SetDrawColor(255,255,255,255)
			surface.DrawTexturedRect(ScrW() *0.105, ScrH() *0.305, 125 /scale_w, 22 /scale_h )
			
			local health = tp_exit:GetNetworkedInt( "health" )
			local width = math.ceil((health /150) *125)
			
			surface.SetTexture(surface.GetTextureID("HUD/building_bar_color"))
			surface.DrawTexturedRect(ScrW() *0.105, ScrH() *0.305, width /scale_w, 22 /scale_h )
		end
		
		surface.SetTexture(surface.GetTextureID("HUD/building_bar_health"))
		local health = tp_exit:GetNetworkedInt("health")

		local bars = math.ceil((health /150) *6)
		if bars <= 2 then
			surface.SetTexture(surface.GetTextureID("HUD/building_bar_health_red"))
		end
		local pos_y = 0.321
		for i = 1, bars do
			surface.DrawTexturedRect(ScrW() *0.028, ScrH() *pos_y, 20 /scale_w, 19 /scale_h )
			pos_y = pos_y -0.008
		end
		
		local pos_y = 0.283
		for i = 1, 6 -bars do
			draw.RoundedBox(0, ScrW() *0.028, ScrH() *pos_y, 20 /scale_w, 8 /scale_h, Color(255, 255, 255, 50))
			pos_y = pos_y +0.0086
		end
	end
end
hook.Add("HUDPaint", "TF_Renaissance.DefaultHUDPaint", TF_CustomHUDPaint)
