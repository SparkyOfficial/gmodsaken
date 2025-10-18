include('shared.lua')

SWEP.PrintName = "Shotgun Engineer"
SWEP.Slot = 0
SWEP.SlotPos = 15
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = false
SWEP.Crosshair = "sprites/tf_crosshair_03"

SWEP.WepSelectIcon		= surface.GetTextureID( "sprites/bucket_shotgun" )

killicon.Add("tf_weapon_shotgun_primary","sprites/bucket_shotgun",Color ( 255, 255, 255, 255 ) )