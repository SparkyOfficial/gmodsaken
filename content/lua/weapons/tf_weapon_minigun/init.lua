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

SWEP.MinDamage = 50
SWEP.MaxDamage = 55
SWEP.CritDamage = 105
SWEP.CritChance = 0.4

SWEP.EffectMuzzle = "muzzle_minigun_constant"
SWEP.EffectMuzzleForward = 20
SWEP.EffectMuzzleRight = 3
SWEP.EffectMuzzleUp = -10
SWEP.EffectTracer = "bullet_tracer01_"

SWEP.EffectTracerCount = 1