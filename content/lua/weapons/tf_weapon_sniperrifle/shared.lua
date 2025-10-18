SWEP.Author = "Silverlan"
SWEP.Contact = "Silverlan@gmx.de"
SWEP.Purpose = ""
SWEP.Instructions = ""
SWEP.Base = "base_swep_tf_handgun"
SWEP.Category		= "Team Fortress 2"

SWEP.GotGlobalClip = true
SWEP.GotPrimary = true
SWEP.GotSecondary = false

SWEP.Spawnable = false
SWEP.AdminSpawnable = true

SWEP.ViewModel = "models/weapons/v_models/v_sniperrifle_sniper.mdl"
SWEP.WorldModel = "models/weapons/w_models/w_sniperrifle.mdl"

SWEP.Primary.Sound			= Sound( "weapons/sniper_shoot.wav" )
SWEP.Primary.CritSound			= Sound( "weapons/sniper_shoot_crit.wav" )
SWEP.Primary.Recoil			= 0
SWEP.Primary.Damage			= 12
SWEP.Primary.NumShots		= 1
SWEP.Primary.Cone			= 0
SWEP.Primary.Delay			= 1.6
SWEP.Primary.FastDelay = 1.6

SWEP.Primary.MaxClipSize		= 25
SWEP.Primary.ClipSize		= 25
SWEP.Primary.DefaultClip	= 25
SWEP.Primary.AmmoCount = 25
SWEP.Primary.Automatic		= true
SWEP.Primary.ShootInWater		= true
SWEP.Primary.Ammo			= "sniper"
SWEP.Primary.BulletType = "pistol"
SWEP.Primary.Global = true
SWEP.Primary.Reload = false
SWEP.Primary.PickUpAmmo = 75
SWEP.Primary.Limited = true

SWEP.Secondary.Ammo			= "none"
SWEP.Secondary.Global = false
SWEP.Secondary.Reload = false

SWEP.ReloadSound1			= ""
SWEP.ReloadSound2			= ""

SWEP.ReloadOnEmpty = false

SWEP.NextCharge = 0

/*---------------------------------------------------------
	SecondaryAttack
---------------------------------------------------------*/
function SWEP:SecondaryAttack()
	if self:GetNetworkedBool("noscope") or (self.AttackDelay and CurTime() < self.AttackDelay) then return end
	if !self.scoping then
		self:Zoom()
	else
		self:Unzoom()
	end
end

function SWEP:Zoom()
	self.scoping = true
	self.Owner:SetFOV(20)
	self:SetNetworkedBool("scoping", true)
end

function SWEP:Unzoom()
	self:SetNetworkedInt("charge", 0)
	self.scoping = false
	self.Owner:SetFOV(75)
	self:SetNetworkedBool("scoping", false)
end

function SWEP:CalculateDamage(hs)
	local mindamage
	local maxdamage
	local charge = self:GetNetworkedInt("charge")
	if !hs or (hs and !self.scoping) then
		if self.scoping then
			mindamage = ((self.MinDamageZoomed -self.MinDamage) /100) *charge +self.MinDamage
			maxdamage = ((self.MaxDamageZoomed -self.MaxDamage) /100) *charge +self.MaxDamage
		else
			mindamage = self.MinDamage
			maxdamage = self.MaxDamage
		end
	else
		mindamage = ((self.MaxDamageZoomedHeadshot -self.MinDamageZoomedHeadshot) /100) *charge +self.MinDamageZoomedHeadshot
		maxdamage = mindamage
	end
	return {mindamage,maxdamage}
end

/*---------------------------------------------------------
   Think
---------------------------------------------------------*/
function SWEP:Think()	
	if self.scoping and CurTime() >= self.NextCharge and !self:GetNetworkedBool("noscope") then
		local charge = self:GetNetworkedInt("charge")
		if charge < 100 then
			self:SetNetworkedInt("charge", charge +2.5)
			self.NextCharge = CurTime() +0.1
		end
	end

	if self.startreloaddelay and CurTime() > self.startreloaddelay then
		self.Weapon:SendWeaponAnim( ACT_VM_RELOAD ) 
		self.startreloaddelay = nil

		self.add_prim = 1

		self.reloading = true
		self.reload_cur_start = CurTime()
	end
	if self.idledelay and CurTime() > self.idledelay then
		self.idledelay = nil
		self:SendWeaponAnim( ACT_VM_IDLE )
	end
	if self.reloading then
		if (!self.ReloadSingle and self.reload_cur_start +1.4 <= CurTime()) or (self.ReloadSingle and self.reload_cur_start +self.ReloadSingleDelay <= CurTime()) then
			self.reloading = false
			self:AddPrimaryAmmo( self.add_prim );
			self.Owner:AddCustomAmmo( self.Primary.Ammo, -self.add_prim )
			self.add_prim = nil
			if self.ReloadSingle then
				local available = self.Owner:GetCustomAmmo( self.Primary.Ammo );
				if self:GetClip(self.Primary.Ammo) < self.Primary.ClipSize and available > 0 then
					self.Weapon:SendWeaponAnim( ACT_VM_RELOAD ) 
					self.reload_cur_start = CurTime()
					self.reloading = true
					self.add_prim = 1
				else self.reloaddelay = nil; self:SendWeaponAnim( ACT_RELOAD_FINISH ) end
			end
		end
		return
	elseif !self.ReloadSingle then return end
	if self.Owner:GetCustomAmmo( self.Primary.Ammo ) > 0 and self:GetClip(self.Primary.Ammo) == 0 then
		timer.Simple(0.5, function() if self and ValidEntity(self) and self.Owner and ValidEntity(self.Owner) and self.Owner:GetActiveWeapon() == self then self:Reload() end end )
	end
	if self.reloaddelay and CurTime() >= self.reloaddelay then
		self:Reload()
	end
end
