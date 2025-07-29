

// Variables that are used on both client and server

SWEP.Author = "Silverlan"
SWEP.Contact = "Silverlan@gmx.de"
SWEP.Purpose = ""
SWEP.Instructions = ""
SWEP.Base = "base_swep_tf"
SWEP.Category		= "Team Fortress 2"

SWEP.ViewModelFOV	= 62
SWEP.ViewModelFlip	= false
SWEP.ViewModel		= "models/weapons/v_models/v_flamethrower_pyro.mdl"
SWEP.WorldModel		= "models/weapons/w_models/w_flamethrower.mdl"
SWEP.AnimPrefix		= "python"

SWEP.GotGlobalClip = true
SWEP.GotPrimary = true
SWEP.GotSecondary = false

SWEP.Spawnable			= false
SWEP.AdminSpawnable		= true

SWEP.Primary.MaxClipSize		= 200
SWEP.Primary.DefaultClip	= 200
SWEP.Primary.AmmoCount = 200
SWEP.Primary.ShootInWater		= true
SWEP.Primary.Automatic		= true				// Automatic/Semi Auto
SWEP.Primary.Ammo			= "flamethrower"
SWEP.Primary.Global = true
SWEP.Primary.Reload = false
SWEP.Primary.PickUpAmmo = 200
SWEP.Primary.playsoundonempty = false
SWEP.Primary.Limited = true

SWEP.Secondary.Ammo			= "none"
SWEP.Secondary.Global = false
SWEP.Secondary.Reload = false

SWEP.Primary.Delay = 0.1

/*---------------------------------------------------------
   Think
---------------------------------------------------------*/
function SWEP:Think()
	if !self.endthink then self.endthink = CurTime() +1; self.thinking = 0 end
	self.thinking = self.thinking +1
	if CurTime() >= self.endthink then
		self.endthink = nil
		self.thinking = 0
	end

	if !self.attacking then return end
	//self:NextThink( CurTime() +0.1 )
	//self:AddPrimaryAmmo( -1.25 )
	self.Owner:AddCustomAmmo( self.Primary.Ammo, -0.1838 )
	if CLIENT then return end
	local pos = self.Owner:GetShootPos()
	local ang = self.Owner:GetAimVector()
	local tracedata = {}
	tracedata.start = pos
	tracedata.endpos = pos +(self.Owner:GetAimVector( ) *80)
	tracedata.filter = self.Owner
	local tr = util.TraceLine(tracedata)
	
	if !self.Owner:KeyDown( 1 ) or tr.HitWorld or self.Owner:GetCustomAmmo( self.Primary.Ammo ) <= 0 then
		self:StopPrimaryAttack()
		return
	end
	//return true
end
