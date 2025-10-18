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

SWEP.ViewModel = "models/weapons/v_models/v_minigun_heavy.mdl"
SWEP.WorldModel = "models/weapons/w_models/w_minigun.mdl"

//SWEP.Primary.Sound			= Sound( "weapons/minigun_shoot.wav" )
//SWEP.Primary.CritSound			= Sound( "weapons/minigun_shoot_crit.wav" )
SWEP.Primary.Recoil			= 0
SWEP.Primary.Damage			= 12
SWEP.Primary.NumShots		= 1
SWEP.Primary.Cone			= 0.05
SWEP.Primary.Delay			= 0.1
SWEP.Primary.FastDelay = 0.1

SWEP.Primary.MaxClipSize		= 200
SWEP.Primary.ClipSize		= 200
SWEP.Primary.DefaultClip	= 200
SWEP.Primary.AmmoCount = 200
SWEP.Primary.Automatic		= true
SWEP.Primary.ShootInWater		= true
SWEP.Primary.Ammo			= "minigun"
SWEP.Primary.BulletType = "pistol"
SWEP.Primary.Global = true
SWEP.Primary.Reload = false
SWEP.Primary.PickUpAmmo = 200
SWEP.Primary.Limited = true

SWEP.Secondary.Ammo			= "none"
SWEP.Secondary.Global = false
SWEP.Secondary.Reload = false

SWEP.ReloadSound1			= ""
SWEP.ReloadSound2			= ""

SWEP.ReloadOnEmpty = false

function SWEP:CreateSounds()
	self.WindUpSound			= CreateSound( self.Owner, Sound( "weapons/minigun_wind_up.wav" ) )
	self.WindDownSound			= CreateSound( self.Owner, Sound( "weapons/minigun_wind_down.wav" ) )
	self.SpinSound			= CreateSound( self.Owner, Sound( "weapons/minigun_spin.wav" ) )
	self.EmptySound			= CreateSound( self.Owner, Sound( "weapons/minigun_empty.wav" ) )
	self.Primary.Sound = CreateSound( self.Owner, Sound( "weapons/minigun_shoot.wav" ) )
	self.Primary.CritSound = CreateSound( self.Owner, Sound( "weapons/minigun_shoot_crit.wav" ) )
end

/*---------------------------------------------------------
   Name: SWEP:CanPrimaryAttack( )
   Desc: Helper function for checking for no ammo
---------------------------------------------------------*/
function SWEP:CanPrimaryAttack()
	if ( ( !self.Primary.Global and self:GetPrimaryAmmo() <= 0 ) or ( self.Primary.Global and self.Owner:GetNetworkedInt( "ammo_" .. self.Primary.Ammo ) <= 0 ) or ( !self.Primary.ShootInWater and self.Owner:WaterLevel() == 3 ) ) then
		if self.Primary.playsoundonempty then
			self.Primary.Sound:Stop()
			self.Primary.CritSound:Stop()
			self.SpinSound:Stop()
			self.EmptySound:Play()
			self.Weapon:SendWeaponAnim( ACT_VM_SECONDARYATTACK )
		end
		self:SetNextPrimaryFire( CurTime() + 0.2 )
		return false
	end
	return true
end


/*---------------------------------------------------------
	PrimaryAttack
---------------------------------------------------------*/
function SWEP:PrimaryAttack()
	if GetGlobalBool( "humiliation" ) and self.Owner:Team() == GetGlobalInt( "team_lost" ) then return end
	
	if !self.spinning then
		if !self.spinup then
			self:SecondaryAttack()
		end
		return
	end
	if !self.Primary.Sound then self:CreateSounds() end
	
	if ( (CurTime() < self.AttackDelay and !self.Owner:KeyPressed( 1 )) or (self.Owner:KeyPressed( 1 ) and CurTime() < self.FastAttackDelay) or !self:CanPrimaryAttack() ) then return end
	self.AttackDelay = CurTime() +self.Primary.Delay
	self.FastAttackDelay = CurTime() +self.Primary.FastDelay
	
	self.Weapon:SendWeaponAnim( ACT_VM_PRIMARYATTACK )
	self.Owner:SetAnimation( PLAYER_ATTACK1 )
	if CLIENT then return end
	self:StopReload()
	local critical = self:Critical()
	local damage = math.random(self.MinDamage, self.MaxDamage)
	if critical and !self.critspray then
		self:StartCritSpray(math.random(3,5))
	end
	if self.critspray then
		damage = self.CritDamage
		self.Primary.Sound:Stop()
		self.Primary.CritSound:Play()
	else
		self.Primary.CritSound:Stop()
		self.Primary.Sound:Play()
	end
	self:ShootBullet( damage, self.Primary.NumShots, self.Primary.Cone, self.critspray )
	self.attacking = true
	
	if ( self.Owner:IsNPC() ) then return end
	
	// Remove 1 bullet from our clip
	self:TakePrimaryAmmo( 1 )
	
	// In singleplayer this function doesn't get called on the client, so we use a networked float
	// to send the last shoot time. In multiplayer this is predicted clientside so we don't need to 
	// send the float.
	if ( (SinglePlayer() && SERVER) || CLIENT ) then
		self.Weapon:SetNetworkedFloat( "LastShootTime", CurTime() )
	end
	if self then return end
	if !self.nextmuzzle or (self.nextmuzzle and CurTime() >= self.nextmuzzle) then
	local pos = self.Owner:GetShootPos()
	pos = pos + self.Owner:GetForward() * self.EffectMuzzleForward
	pos = pos + self.Owner:GetRight() * self.EffectMuzzleRight
	pos = pos + self.Owner:GetUp() * self.EffectMuzzleUp
	
	local muzzle = ents.Create( "info_particle_system" )
	muzzle:SetKeyValue( "effect_name", self.EffectMuzzle )
	muzzle:SetKeyValue( "start_active", "1" )
	muzzle:SetPos( pos )
	muzzle:SetAngles( self.Owner:GetAngles() )
	//muzzle:SetParent( self )
	muzzle:Spawn()
	muzzle:Activate()
	//muzzle:Fire( "SetParentAttachment", "muzzle", 0 )
	muzzle:Fire( "Kill", "", 2 )
	self.nextmuzzle = CurTime() +2
	end
end

/*---------------------------------------------------------
	SecondaryAttack
---------------------------------------------------------*/
function SWEP:SecondaryAttack()
	if self.spinup or self.spinning or (self.spindowndelay and CurTime() < self.spindowndelay) then self.EmptySound:Stop() if self.spinning then self.SpinSound:Play() end return end
	if !self.Primary.Sound then self:CreateSounds() end
	self.idledelay = nil
	self.spinup = true
	self.Weapon:SendWeaponAnim( ACT_MP_ATTACK_STAND_PREFIRE )
	self.spinupdelay = CurTime() +self:SequenceDuration()
	self.WindUpSound:Play()
end

function SWEP:StopSecondaryAttack()
end

function SWEP:StopPrimaryAttack()
	self.spinup = false
	self.spinupdelay = nil
	self.spinning = false
	self.idledelay = CurTime() +self:SequenceDuration()
	self.spindowndelay = nil
	if !self.Primary.Sound then return end
	self.Primary.Sound:Stop()
	self.Primary.CritSound:Stop()
	self.WindUpSound:Stop()
	self.SpinSound:Stop()
	self.WindDownSound:Stop()
	self.EmptySound:Stop()
end

/*---------------------------------------------------------
   Think
---------------------------------------------------------*/
function SWEP:Think()	
	if self.spinupdelay and CurTime() >= self.spinupdelay then
		self.spinup = false
		self.spinupdelay = nil
		self.spinning = true
		self.WindUpSound:Stop()
		self.SpinSound:Play()
	end
	if self.spinning then
		if !self.Owner:KeyDown( 1 ) then
			if self.attacking then
				self.attacking = false
				self.Primary.Sound:Stop()
				self.Primary.CritSound:Stop()
				self.EmptySound:Stop()
			end
			if !self.Owner:KeyDown( 2048 ) then
				self:StopPrimaryAttack()
				self:SendWeaponAnim( ACT_MP_ATTACK_STAND_POSTFIRE )
				self.spindowndelay = CurTime() +self:SequenceDuration()
				self.WindDownSound:Play()
				return
			end
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


