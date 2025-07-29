include('shared.lua')


SWEP.PrintName			= "Medigun"		// 'Nice' Weapon name (Shown on HUD)	
SWEP.Slot				= 1						// Slot in the weapon selection menu
SWEP.SlotPos			= 16					// Position in the slot
SWEP.DrawCrosshair		= false
SWEP.Crosshair = "sprites/tf_crosshair_01"

SWEP.RenderGroup 		= RENDERGROUP_OPAQUE

killicon.Add("tf_weapon_medigun","sprites/bucket_medigun_red",Color ( 255, 255, 255, 255 ) )

function SWEP:Initialize()
	local bucket = "red"
	if self.Owner and ValidEntity(self.Owner) and self.Owner:Team() == 1 then bucket = "blue" end
	self.WepSelectIcon		= surface.GetTextureID( "sprites/bucket_medigun_" .. bucket )
end

/*---------------------------------------------------------
	You can draw to the HUD here - it will only draw when
	the client has the weapon deployed..
---------------------------------------------------------*/
function SWEP:DrawHUD()
	local team = LocalPlayer():Team()
	if team == 1 then
		team = "blue"
	else
		team = "red"
	end

	local scale_w = LocalPlayer():GetPanelScale()[1]
	local scale_h = LocalPlayer():GetPanelScale()[2]
			
	local msg_sep = string.Explode( ".", LocalPlayer():GetNetworkedInt( "medic_uber" ) )
	local message = "UBERCHARGE"
	surface.SetFont("Default")
	local Width, Height = surface.GetTextSize(message)
	Height = Height *2
	Width = Width + 25
	local pos_x = ScrW()
	local pos_y = ScrH()
			
	if LocalPlayer():GetActiveWeapon():GetNetworkedBool( "healing" ) then
		local target = LocalPlayer():GetNetworkedEntity( "healtarget" )
		surface.SetFont( "TF2_font2" )
		local message = "Healing: " .. target:GetName()
		local str_w, str_h = surface.GetTextSize( message )
		str_w = str_w /2
		
		local width = 680
		if surface.GetTextSize( message ) > 480 then
			width = width +(surface.GetTextSize( message ) -480)
		end
		
		surface.SetTexture(surface.GetTextureID("HUD/objectives_timepanel_" .. team .. "_bg"))
		surface.SetDrawColor(255,255,255,255)
		surface.DrawTexturedRect(ScrW() *0.5 -(width /scale_w) /2, ScrH() *0.55, width /scale_w, 102 )
		draw.SimpleText(message, "TF2_font2", ScrW() *0.59 -(width /scale_w) /2 +str_w, ScrH() *0.585, Color(255, 255, 255, 255), 1, 1)
				
		// HEAL DISPLAY
		local width = 680
		if surface.GetTextSize( message ) > 480 then
			width = width +(surface.GetTextSize( message ) -480)
		end
		
		local health = target:Health()
		local health_max = 100
		
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
		surface.DrawTexturedRect(ScrW() *0.538 -(width /scale_w) /2, ScrH() *0.566, 60 /scale_w, 60 /scale_h )	
		
		local health_bg_middle = "HUD/health_color_middle"
		local health_bg_bottom = "HUD/health_color_bottom"
		if health <= 1.5 *49 then
			health_bg_middle = health_bg_middle .. "_red"
			health_bg_bottom = health_bg_bottom .. "_red"
		end
		
		if scale_middle then
			surface.SetTexture(surface.GetTextureID(health_bg_middle))
			local w,h = surface.GetTextureSize( surface.GetTextureID("HUD/health_color_middle") )
			surface.DrawTexturedRect(ScrW() *0.540 -(width /scale_w) /2, ScrH() *0.598 -(h *((scale_middle /scale_h) /100)) /2, 54 /scale_w, scale_middle /scale_h )
		end
		
		if scale_top then
			surface.SetTexture(surface.GetTextureID("HUD/health_color_top"))
			surface.DrawTexturedRect(ScrW() *0.551 -(width /scale_w) /2, ScrH() *0.548 +((45 /scale_h) -(scale_top /scale_h)), 18 /scale_w, scale_top /scale_h )
		end
		
		surface.SetTexture(surface.GetTextureID(health_bg_bottom))
		surface.DrawTexturedRect(ScrW() *0.551 -(width /scale_w) /2, ScrH() *0.575 +((45 /scale_h) -(scale_bottom /scale_h)), 18 /scale_w, scale_bottom /scale_h )
		// HEAL DISPLAY END
	end
	local tex=surface.GetTextureID("HUD/medic_charge_" .. team .. "_bg")//Gets the txture id for the brick texture
	surface.SetTexture(tex)
	surface.SetDrawColor(255,255,255,255)
	surface.DrawTexturedRect(ScrW() *0.79, ScrH() *0.86, 324, 160 )//Width + 128, Height + 128) 
			
	draw.SimpleText(message, "TF2_font1", ScrW() *0.89, ScrH() *0.92, Color(239,228,195,255), 1, 1)
	local tex=surface.GetTextureID("HUD/ico_health_cluster")//Gets the txture id for the brick texture
	surface.SetTexture(tex)
	surface.SetDrawColor(255,255,255,255)//Makes sure the image draws correctly
	surface.DrawTexturedRect(ScrW() *0.79, ScrH() *0.89, 100, 100 ) //Width + 64, Height + 64) 
			
	local tex=surface.GetTextureID("HUD/uber_bg")
	surface.SetTexture(tex)
	surface.SetDrawColor(255,255,255,255)
	surface.DrawTexturedRect(ScrW() *0.836, ScrH() *0.940, 220, 22 ) //Width + 64, Height + 64) 
			
	local msg_sep = string.Explode( ".", LocalPlayer():GetNetworkedInt( "medic_uber" ) )
	local width = (msg_sep[1] /100) *220
	
	local tex=surface.GetTextureID("HUD/uber_color")
	surface.SetTexture(tex)
	surface.SetDrawColor(255,255,255,255)
	surface.DrawTexturedRect(ScrW() *0.836, ScrH() *0.940, width, 22 )
end
