AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include('shared.lua')

SWEP.Weight				= 6			// Decides whether we should switch from/to this
SWEP.AutoSwitchTo		= true		// Auto switch to if we pick it up
SWEP.AutoSwitchFrom		= true		// Auto switch from if you pick up a better weapon
SWEP.MetalToGive = 100
SWEP.SequenceDelay = 0.85
SWEP.DrawDelay = 1.2

SWEP.ReloadOnEmpty = true
SWEP.playsoundonempty = false
SWEP.HoldType = "pistol"

SWEP.MinDamage = 80
SWEP.MaxDamage = 90
SWEP.CritDamage = 180
SWEP.CritChance = 5

SWEP.ReloadSingle = true
SWEP.ReloadSingleDelay = 0.5

SWEP.EffectMuzzle = "muzzle_shotgun"
SWEP.EffectMuzzleForward = 20
SWEP.EffectMuzzleRight = 4
SWEP.EffectMuzzleUp = -4
SWEP.EffectTracer = "bullet_shotgun_tracer01_"
SWEP.EffectTracerCount = 1