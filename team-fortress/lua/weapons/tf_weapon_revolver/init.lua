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

SWEP.MinDamage = 55
SWEP.MaxDamage = 60
SWEP.CritDamage = 120
SWEP.CritChance = 5

SWEP.EffectMuzzle = "muzzle_revolver"
SWEP.EffectMuzzleForward = 20
SWEP.EffectMuzzleRight = 5
SWEP.EffectMuzzleUp = -3
SWEP.EffectTracer = "bullet_pistol_tracer01_"