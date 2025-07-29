
include('shared.lua')


SWEP.PrintName			= "Fists"		// 'Nice' Weapon name (Shown on HUD)	
SWEP.Slot				= 2						// Slot in the weapon selection menu
SWEP.SlotPos			= 14					// Position in the slot
SWEP.Crosshair = "sprites/tf_crosshair_01"

SWEP.RenderGroup 		= RENDERGROUP_OPAQUE

killicon.Add("tf_weapon_fists","sprites/bucket_fists_red",Color ( 255, 255, 255, 255 ) )

function SWEP:Initialize()
	local bucket = "red"
	if self.Owner:Team() == 1 then bucket = "blue" end
	self.WepSelectIcon		= surface.GetTextureID( "sprites/bucket_fists_" .. bucket )
end
