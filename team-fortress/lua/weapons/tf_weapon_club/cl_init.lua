
include('shared.lua')


SWEP.PrintName			= "Kukri"		// 'Nice' Weapon name (Shown on HUD)	
SWEP.Slot				= 2 					// Slot in the weapon selection menu
SWEP.SlotPos			= 17					// Position in the slot
SWEP.Crosshair = "sprites/tf_crosshair_01"

SWEP.RenderGroup 		= RENDERGROUP_OPAQUE

// Override this in your SWEP to set the icon in the weapon selection
SWEP.WepSelectIcon		= surface.GetTextureID( "sprites/bucket_machete" )

killicon.Add("tf_weapon_club","sprites/bucket_machete",Color ( 255, 255, 255, 255 ) )