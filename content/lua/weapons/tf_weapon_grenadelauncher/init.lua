
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include( "shared.lua" )

SWEP.Weight				= 6			// Decides whether we should switch from/to this
SWEP.AutoSwitchTo		= true		// Auto switch to if we pick it up
SWEP.AutoSwitchFrom		= true		// Auto switch from if you pick up a better weapon
SWEP.MetalToGive = 100
SWEP.SequenceDelay = 0.85
SWEP.DrawDelay = 1.2

SWEP.ReloadOnEmpty = false
SWEP.playsoundonempty = false
SWEP.HoldType = "pistol"

SWEP.MinDamage = 65
SWEP.MaxDamage = 125
SWEP.CritDamage = 295
SWEP.CritChance = 5

function SWEP:Initialize()
	self:SetWeaponHoldType( self.HoldType )
	self:SetNPCMinBurst( 30 )
	self:SetNPCMaxBurst( 30 )
	self:SetNPCFireRate( 0.01 )
	
	if !self.Primary.Global then
		self:SetPrimaryAmmo( self.Primary.DefaultClip )
	end
	if !self.Secondary.Global then
		self:SetSecondaryAmmo( self.Secondary.DefaultClip )
	end
end

function SWEP:StopPrimaryAttack()
	self.attacking = false
	self:SendWeaponAnim( ACT_VM_IDLE )
end

/*---------------------------------------------------------
	PrimaryAttack
---------------------------------------------------------*/
function SWEP:PrimaryAttack()
	if GetGlobalBool( "humiliation" ) and self.Owner:Team() == GetGlobalInt( "team_lost" ) then return end
	self.Weapon:SetNextSecondaryFire( CurTime() + self.Primary.Delay )
	self.Weapon:SetNextPrimaryFire( CurTime() + self.Primary.Delay )
	if !self:CanPrimaryAttack( ) then return end
	self.idledelay = CurTime() +1.2
	self:TakePrimaryAmmo( 1 )
	self:StopReload()
	
	local crit = self:Critical()
	
	local grenade = ents.Create("tf_grenade")
	local pos = self.Owner:GetShootPos()
	pos = pos + self.Owner:GetForward() * 20
	pos = pos + self.Owner:GetRight() * 6
	pos = pos + self.Owner:GetUp() * -7
	//local pos = self:GetAttachment(self:LookupAttachment("muzzle"))["Pos"]
	//pos.z = pos.z +self.Owner:WorldToLocal(self.Owner:GetEyeTrace( ).StartPos).z
	grenade:SetPos(pos)
	grenade:SetAngles(self.Owner:EyeAngles())
	grenade:SetPhysicsAttacker( self.Owner )
	grenade.owner = self
	if crit then grenade.critical = true; self.Owner:EmitSound("weapons/grenade_launcher_shoot_crit.wav", 100, 100) else self.Owner:EmitSound("weapons/grenade_launcher_shoot.wav", 100, 100) end
	grenade:Spawn()
	grenade:Activate()
	grenade:SetOwner(self.Owner)
	
	self.Weapon:SendWeaponAnim( ACT_VM_PRIMARYATTACK )
	self.Owner:SetAnimation( PLAYER_ATTACK2 )
	self.allowreloaddelay = CurTime() +0.5
	
	local pos = self.Owner:GetShootPos()
	pos = pos + self.Owner:GetForward() * 20
	pos = pos + self.Owner:GetRight() * 3
	pos = pos + self.Owner:GetUp() * -3
	
	local muzzle = ents.Create( "info_particle_system" )
	muzzle:SetKeyValue( "effect_name", "muzzle_grenadelauncher" )
	muzzle:SetKeyValue( "start_active", "1" )
	muzzle:SetPos( pos )
	local angle = self.Owner:GetAngles()
	angle.p = angle.p +90
	muzzle:SetAngles( angle )
	muzzle:Spawn()
	muzzle:Activate()
	muzzle:Fire( "Kill", "", 0.3 )

	// In singleplayer this function doesn't get called on the client, so we use a networked float
	// to send the last shoot time. In multiplayer this is predicted clientside so we don't need to 
	// send the float.
	if ( (SinglePlayer() && SERVER) || CLIENT ) then
		self.Weapon:SetNetworkedFloat( "LastShootTime", CurTime() )
	end
	
end

function SWEP:SecondaryAttack()
end

/*------------------------------------
    Reload
------------------------------------*/
function SWEP:Reload( )
	if self.allowreloaddelay and CurTime() < self.allowreloaddelay then return end
	self.reloaddelay = nil
	local reloaded = false;

	// should reload?
	if( self.LastReload > CurTime() ) then return reloaded; end
	self.LastReload = CurTime() + 1.41;

	// reload primary
	if( self.Primary.Reload and self.Primary && self.Primary.Ammo && self.Primary.ClipSize != -1 ) then

		local available = self.Owner:GetCustomAmmo( self.Primary.Ammo );
		local ammo = self:GetClip(self.Primary.Ammo)
		// do we have any ammo available to put into this?
		if( ammo < self.Primary.ClipSize && available > 0 ) then
			self.idledelay = nil
			self.Weapon:SendWeaponAnim( ACT_RELOAD_START )
			self.startreloaddelay = CurTime() +self:SequenceDuration()
			self.Owner:SetAnimation( PLAYER_RELOAD )

			// add the ammo to our clip
			//self:SetAmmo( self.Primary.Ammo, self:GetPrimaryAmmo() + add );

			// don't fire
			self:SetNextPrimaryFire( CurTime() + ( self.Primary.Delay || 0.25 ) + 1.4 );
			self:SetNextSecondaryFire( CurTime() + ( self.Primary.Delay || 0.25 ) + 1.4 );

			// flag
			reloaded = true;

		end

	end
	return reloaded;
end 

/*---------------------------------------------------------
   Think
---------------------------------------------------------*/
function SWEP:Think()	
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
		if self.reload_cur_start +0.6 <= CurTime() then
			self.reloading = false
			self:AddPrimaryAmmo( self.add_prim );
			self.Owner:AddCustomAmmo( self.Primary.Ammo, -self.add_prim )
			self.add_prim = nil
			local available = self.Owner:GetCustomAmmo( self.Primary.Ammo );
			if self:GetClip(self.Primary.Ammo) < 4 and available > 0 then
				self.Weapon:SendWeaponAnim( ACT_VM_RELOAD ) 
				self.reload_cur_start = CurTime()
				self.reloading = true
				self.add_prim = 1
			else self.reloaddelay = nil; self:SendWeaponAnim( ACT_RELOAD_FINISH ) end
		end
	elseif self.Owner:GetCustomAmmo( self.Primary.Ammo ) > 0 and self:GetClip(self.Primary.Ammo) == 0 then
		timer.Simple(0.5, function() if self and ValidEntity(self) and self.Owner and ValidEntity(self.Owner) and self.Owner:GetActiveWeapon() == self then self:Reload() end end )
	end
	if self.reloaddelay and CurTime() >= self.reloaddelay then
		self:Reload()
	end
	
	
end

function SWEP:StopReload()
	self.reload_cur_start = nil
	self.startreloaddelay = nil
	self.reloading = false
	self.reloaddelay = nil
end
