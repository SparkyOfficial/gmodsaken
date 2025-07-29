
include('shared.lua')


SWEP.PrintName			= "Butterfly"		// 'Nice' Weapon name (Shown on HUD)	
SWEP.Slot				= 2						// Slot in the weapon selection menu
SWEP.SlotPos			= 18					// Position in the slot
SWEP.Crosshair = "sprites/tf_crosshair_04"

SWEP.RenderGroup 		= RENDERGROUP_OPAQUE

// Override this in your SWEP to set the icon in the weapon selection
SWEP.WepSelectIcon		= surface.GetTextureID( "sprites/bucket_knife" )

killicon.Add("tf_weapon_knife","sprites/bucket_knife",Color ( 255, 255, 255, 255 ) )