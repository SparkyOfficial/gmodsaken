
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include( "shared.lua" )

SWEP.Weight				= 5			// Decides whether we should switch from/to this
SWEP.AutoSwitchTo		= true		// Auto switch to if we pick it up
SWEP.AutoSwitchFrom		= true		// Auto switch from if you pick up a better weapon
SWEP.MetalToGive = 100
SWEP.SequenceDelay = 1.25
SWEP.DrawDelay = 0.6

SWEP.MinDamage = 45
SWEP.MaxDamage = 85
SWEP.CritDamage = 195

SWEP.Swing = Sound( "weapons/shovel_swing.wav" )
SWEP.SwingCrit = Sound( "weapons/shovel_swing_crit.wav" )
SWEP.HitFlesh = { Sound( "weapons/axe_hit_flesh1.wav" ), Sound( "weapons/axe_hit_flesh2.wav" ), Sound( "weapons/axe_hit_flesh3.wav" ) }
SWEP.HitWorld = { Sound( "weapons/cbar_hit1.wav" ), Sound( "weapons/cbar_hit2.wav" ) }

SWEP.Primary.Delay = 0.8

