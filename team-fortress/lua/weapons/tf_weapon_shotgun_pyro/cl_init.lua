include('shared.lua')

SWEP.PrintName = "Shotgun Pyro"
SWEP.Slot = 1
SWEP.SlotPos = 12
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = false
SWEP.Crosshair = "sprites/tf_crosshair_03"

SWEP.WepSelectIcon		= surface.GetTextureID( "sprites/bucket_shotgun" )

killicon.Add("tf_weapon_shotgun_pyro","sprites/bucket_shotgun",Color ( 255, 255, 255, 255 ) )