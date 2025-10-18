
include('shared.lua')


SWEP.PrintName			= "Bonesaw"		// 'Nice' Weapon name (Shown on HUD)	
SWEP.Slot				= 2						// Slot in the weapon selection menu
SWEP.SlotPos			= 16					// Position in the slot
SWEP.Crosshair = "sprites/tf_crosshair_04"

SWEP.RenderGroup 		= RENDERGROUP_OPAQUE

// Override this in your SWEP to set the icon in the weapon selection
SWEP.WepSelectIcon		= surface.GetTextureID( "sprites/bucket_bonesaw" )

killicon.Add("tf_weapon_bonesaw","sprites/bucket_bonesaw",Color ( 255, 255, 255, 255 ) )