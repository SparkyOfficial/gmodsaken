
include('shared.lua')


SWEP.PrintName			= "Rocket Launcher"		// 'Nice' Weapon name (Shown on HUD)	
SWEP.Slot				= 0						// Slot in the weapon selection menu
SWEP.SlotPos			= 11					// Position in the slot
SWEP.DrawCrosshair		= false
SWEP.Crosshair = "sprites/tf_crosshair_01"

SWEP.RenderGroup 		= RENDERGROUP_OPAQUE

SWEP.WepSelectIcon		= surface.GetTextureID( "sprites/bucket_rl" )

killicon.Add("tf_weapon_rocketlauncher","sprites/bucket_rl",Color ( 255, 255, 255, 255 ) )

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
end
