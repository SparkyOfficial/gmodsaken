include('shared.lua')

SWEP.PrintName = "Wrench"
SWEP.Slot = 2
SWEP.SlotPos = 15
SWEP.DrawCrosshair = false

// Override this in your SWEP to set the icon in the weapon selection
SWEP.WepSelectIcon		= surface.GetTextureID( "sprites/bucket_wrench" )

killicon.Add("tf_weapon_wrench","sprites/bucket_wrench",Color ( 255, 255, 255, 255 ) )

function SWEP:DrawHUD()
	local team = "red"
	if LocalPlayer():Team() == 1 then
		team = "blue"
	end
	local ammo = LocalPlayer():GetNetworkedInt( "ammo_metal" )
	
	local scale_w = LocalPlayer():GetPanelScale()[1]
	local scale_h = LocalPlayer():GetPanelScale()[2]
			
	local tex=surface.GetTextureID("HUD/misc_ammo_area_" .. team)
	surface.SetTexture(tex)
	surface.SetDrawColor(255,255,255,255)
	surface.DrawTexturedRect(ScrW() *0.79, ScrH() *0.86, 235 /scale_w, 110 /scale_h )
			
	draw.SimpleText(ammo, "TF2_font_eng_metal", ScrW() *0.866, ScrH() *0.91, Color(239,228,195,255), 1, 1)
	local tex=surface.GetTextureID("HUD/ico_metal")
	surface.SetTexture(tex)
	surface.DrawTexturedRect(ScrW() *0.814, ScrH() *0.884, 32 /scale_w, 32 /scale_h )
	
	local tex=surface.GetTextureID("sprites/tf_crosshair_01")
	surface.SetTexture(tex)
	surface.SetDrawColor(255,255,255,255)
	surface.DrawTexturedRect(ScrW() *0.5 -16, ScrH() *0.5 -16, 24, 24 )
end
