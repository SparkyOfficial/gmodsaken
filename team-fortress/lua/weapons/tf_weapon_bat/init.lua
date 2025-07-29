
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include( "shared.lua" )

SWEP.Weight				= 5			// Decides whether we should switch from/to this
SWEP.AutoSwitchTo		= true		// Auto switch to if we pick it up
SWEP.AutoSwitchFrom		= true		// Auto switch from if you pick up a better weapon
SWEP.MetalToGive = 100
SWEP.SequenceDelay = 0.85
SWEP.DrawDelay = 1.2

SWEP.MinDamage = 30
SWEP.MaxDamage = 45
SWEP.CritDamage = 105

SWEP.Swing = Sound( "weapons/cbar_miss1.wav" )
SWEP.SwingCrit = Sound( "weapons/cbar_miss1_crit.wav" )
SWEP.HitFlesh = { Sound( "weapons/bat_hit.wav" ) }
SWEP.HitWorld = { Sound( "weapons/cbar_hit1.wav" ), Sound( "weapons/cbar_hit2.wav" ) }

SWEP.Primary.Delay = 0.55

