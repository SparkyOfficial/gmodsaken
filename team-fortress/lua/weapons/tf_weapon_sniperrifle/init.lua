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

SWEP.MinDamage = 34
SWEP.MaxDamage = 66

SWEP.MinDamageZoomed = 101
SWEP.MaxDamageZoomed = 201

SWEP.MaxDamageZoomedHeadshot = 453
SWEP.MinDamageZoomedHeadshot = 150

SWEP.CritDamage = 201
SWEP.CritChance = 5

SWEP.ReloadSingle = true
SWEP.ReloadSingleDelay = 0.5

SWEP.EffectMuzzle = "muzzle_sniperrifle"
SWEP.EffectMuzzleForward = 20
SWEP.EffectMuzzleRight = 4
SWEP.EffectMuzzleUp = -4
SWEP.EffectTracer = ""
SWEP.EffectTracerCount = 1