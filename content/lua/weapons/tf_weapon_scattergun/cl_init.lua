include('shared.lua')

SWEP.PrintName = "Scattergun"
SWEP.Slot = 0
SWEP.SlotPos = 10
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = false
SWEP.Crosshair = "sprites/tf_crosshair_03"

SWEP.WepSelectIcon		= surface.GetTextureID( "sprites/bucket_scatgun" )

killicon.Add("tf_weapon_scattergun","sprites/bucket_scatgun",Color ( 255, 255, 255, 255 ) )