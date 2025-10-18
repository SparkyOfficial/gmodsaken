if ( SERVER ) then
	AddCSLuaFile( "shared.lua" )
	SWEP.Weight				= 5
	SWEP.AutoSwitchTo		= false
	SWEP.AutoSwitchFrom		= false
	SWEP.HoldType			= "smg"
end

SWEP.Author = "Silverlan"
SWEP.Contact = "Silverlan@gmx.de"
SWEP.Purpose = ""
SWEP.Instructions = ""
SWEP.Base = "base_swep_tf"
SWEP.Category		= "Team Fortress 2"

SWEP.ViewModel = "models/weapons/v_models/v_medigun_medic.mdl"
SWEP.WorldModel = "models/weapons/w_models/w_medigun.mdl"

SWEP.GotGlobalClip = false
SWEP.GotPrimary = true
SWEP.GotSecondary = false

SWEP.Spawnable			= false
SWEP.AdminSpawnable		= true

SWEP.Primary.Delay			= 0.4

SWEP.Primary.ClipSize		= -1
SWEP.Primary.DefaultClip	= -1
SWEP.Primary.Automatic		= false
SWEP.Primary.ShootInWater		= true
SWEP.Primary.Ammo			= "none"