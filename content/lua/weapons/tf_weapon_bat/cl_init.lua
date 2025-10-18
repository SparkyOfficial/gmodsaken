
include('shared.lua')


SWEP.PrintName			= "Baseball bat"		// 'Nice' Weapon name (Shown on HUD)	
SWEP.Slot				= 2						// Slot in the weapon selection menu
SWEP.SlotPos			= 10					// Position in the slot
SWEP.Crosshair = "sprites/tf_crosshair_01"

SWEP.RenderGroup 		= RENDERGROUP_OPAQUE

killicon.Add("tf_weapon_bat","sprites/bucket_bat_red",Color ( 255, 255, 255, 255 ) )

function SWEP:Initialize()
	local bucket = "red"
	if self.Owner and ValidEntity(self.Owner) and self.Owner:Team() == 1 then bucket = "blue" end
	self.WepSelectIcon		= surface.GetTextureID( "sprites/bucket_bat_" .. bucket )
end
