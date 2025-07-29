
include('shared.lua')


SWEP.PrintName			= "Pipebomb Launcher"		// 'Nice' Weapon name (Shown on HUD)	
SWEP.Slot				= 1						// Slot in the weapon selection menu
SWEP.SlotPos			= 13					// Position in the slot
SWEP.DrawCrosshair		= false
SWEP.Crosshair = "sprites/tf_crosshair_01"

SWEP.RenderGroup 		= RENDERGROUP_OPAQUE

SWEP.WepSelectIcon		= surface.GetTextureID( "sprites/bucket_pipelaunch" )

killicon.Add("tf_weapon_pipebomblauncher","sprites/bucket_pipelaunch",Color ( 255, 255, 255, 255 ) )

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

	local clip = self:GetClip( self.Primary.Ammo )
	local ammo = math.Round(LocalPlayer():GetCustomAmmo( self.Primary.Ammo ))
	
	local scale_w = LocalPlayer():GetPanelScale()[1]
	local scale_h = LocalPlayer():GetPanelScale()[2]
			
	local tex=surface.GetTextureID("HUD/ammo_" .. team .. "_bg")
	surface.SetTexture(tex)
	surface.SetDrawColor(255,255,255,255)
	surface.DrawTexturedRect(ScrW() *0.79, ScrH() *0.86, 235 /scale_w, 110 /scale_h )
	
	draw.SimpleText(clip, "TF2_font_build_dpa1", ScrW() *0.84, ScrH() *0.9, Color(236,227,203,255), 1, 1)
	draw.SimpleText(ammo, "TF2_font_ammo1", ScrW() *0.9, ScrH() *0.913, Color(236,227,203,255), 1, 1)
	
	local tex=surface.GetTextureID(self.Crosshair)
	surface.SetTexture(tex)
	surface.SetDrawColor(255,255,255,255)
	surface.DrawTexturedRect(ScrW() *0.5 -16, ScrH() *0.5 -16, 24, 24 )
	
	surface.SetTexture(surface.GetTextureID("HUD/uber_bg"))
	surface.DrawTexturedRect(ScrW() *0.819 /scale_w, ScrH() *0.932, 145 /scale_w, 16 /scale_h )	
	
	local width = (self:GetNetworkedInt("charge") /100) *145
	surface.SetTexture(surface.GetTextureID("HUD/building_bar_color"))
	surface.DrawTexturedRect(ScrW() *0.819 /scale_w, ScrH() *0.932, width /scale_w, 16 /scale_h )	
	
	if string.find(GAMEMODE.Name, "Fortress" ) then return end
	local tex=surface.GetTextureID("HUD/misc_ammo_area_" .. team)
	surface.SetTexture(tex)
	surface.SetDrawColor(255,255,255,255)
	surface.DrawTexturedRect(ScrW() *0.685, ScrH() *0.867, 235 /scale_w, 110 /scale_h )
	
	surface.SetTexture(surface.GetTextureID("HUD/ico_stickybomb_" .. team))
	surface.SetDrawColor(255,255,255,255)
	surface.DrawTexturedRect(ScrW() *0.71, ScrH() *0.888, 64 /scale_w, 64 /scale_h )
	
	draw.SimpleText(self.Owner:GetNetworkedInt("tf_stickies"), "TF2_font_ammo1", ScrW() *0.77, ScrH() *0.916, Color(236,227,203,255), 1, 1)
end
