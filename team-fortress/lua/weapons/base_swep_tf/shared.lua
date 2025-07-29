

// Variables that are used on both client and server

SWEP.Author			= ""
SWEP.Contact		= ""
SWEP.Purpose		= ""
SWEP.Instructions	= ""

SWEP.ViewModelFOV	= 62
SWEP.ViewModelFlip	= false
SWEP.ViewModel		= "models/weapons/v_pistol.mdl"
SWEP.WorldModel		= "models/weapons/w_357.mdl"
SWEP.AnimPrefix		= "python"
SWEP.ReloadOnEmpty = false
SWEP.playsoundonempty = true

SWEP.GotGlobalClip = true
SWEP.GotPrimary = true
SWEP.GotSecondary = true

SWEP.Spawnable			= false
SWEP.AdminSpawnable		= false

SWEP.Primary.MaxClipSize		= 250
SWEP.Primary.ClipSize		= 8					// Size of a clip
SWEP.Primary.DefaultClip	= 32				// Default number of bullets in a clip
SWEP.Primary.AmmoCount = 306
SWEP.Primary.ShootInWater		= false
SWEP.Primary.Automatic		= false				// Automatic/Semi Auto
SWEP.Primary.Ammo			= "none"
SWEP.Primary.Global = false
SWEP.Primary.Reload = true
SWEP.Primary.PickUpAmmo = 0
SWEP.Primary.playsoundonempty = true

SWEP.Secondary.MaxClipSize		= 250
SWEP.Secondary.ClipSize		= 8					// Size of a clip
SWEP.Secondary.DefaultClip	= 32				// Default number of bullets in a clip
SWEP.Secondary.AmmoCount = 2
SWEP.Secondary.ShootInWater		= false
SWEP.Secondary.Automatic	= false				// Automatic/Semi Auto
SWEP.Secondary.Ammo			= "none"
SWEP.Secondary.Global = true
SWEP.Secondary.Reload = true
SWEP.Secondary.PickUpAmmo = 0
SWEP.Secondary.playsoundonempty = true

SWEP.LastReload = 0

/*---------------------------------------------------------
---------------------------------------------------------*/
function SWEP:Initialize()
	if ( SERVER ) then
		self:SetWeaponHoldType( self.HoldType )
		self:SetNPCMinBurst( 30 )
		self:SetNPCMaxBurst( 30 )
		self:SetNPCFireRate( 0.01 )
	end
	
	if !self.Primary.Global then
		self:SetPrimaryAmmo( self.Primary.DefaultClip )
	end
	if !self.Secondary.Global then
		self:SetSecondaryAmmo( self.Secondary.DefaultClip )
	end
end

function SWEP:CheckState()
	if self and ValidEntity( self ) and self.Owner and ValidEntity( self.Owner ) and self.Owner:GetActiveWeapon( ) == self then return true else return false end
end

function SWEP:PlayIdle()
	if self:CheckState() then
		self.Weapon:SendWeaponAnim( ACT_VM_IDLE )
		self.Owner:SetAnimation( PLAYER_ATTACK1 )
		return true
	else
		return false
	end
end

/*------------------------------------
   SetAmmo
------------------------------------*/
function SWEP:SetClip( ammo, amt )
	self.Weapon:SetNetworkedInt( "ammo_" .. ammo, amt );
end

/*------------------------------------
    GetAmmo
------------------------------------*/
function SWEP:GetClip( ammo )
	return self.Weapon:GetNetworkedInt( "ammo_" .. ammo );
end

/*---------------------------------------------------------
   Name: SWEP:Precache( )
   Desc: Use this function to precache stuff
---------------------------------------------------------*/
function SWEP:Precache()
end

/*---------------------------------------------------------
   Name: SWEP:CheckReload( )
   Desc: CheckReload
---------------------------------------------------------*/
function SWEP:CheckReload()
	
end

/*------------------------------------
    Reload
------------------------------------*/
function SWEP:Reload( )
	if self.reloading or CLIENT then return end
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
		
			self.Weapon:SendWeaponAnim( ACT_VM_RELOAD ) 
			self.Owner:SetAnimation( PLAYER_RELOAD )
			self.idledelay = CurTime() +self:SequenceDuration()
			
			// how much ammo do we need
			local needs = math.min( self.Primary.ClipSize - ammo, available );
			self.add_prim = math.max( 0, needs );
			if self.ReloadSound1 then self:EmitSound( self.ReloadSound1 ) end
			// remove the ammo from the players bag.
			self.reloading = true
			self.reload_cur_start = CurTime()

			// add the ammo to our clip
			//self:SetAmmo( self.Primary.Ammo, self:GetPrimaryAmmo() + add );

			// don't fire
			self:SetNextPrimaryFire( CurTime() + ( self.Primary.Delay || 0.25 ) + 1.4 );
			self:SetNextSecondaryFire( CurTime() + ( self.Primary.Delay || 0.25 ) + 1.4 );

			// flag
			reloaded = true;

		end

	end

	// reload secondary
	if( self.Secondary.Reload and self.Secondary && self.Secondary.Ammo && self.Secondary.ClipSize != -1 ) then
		local available = self.Owner:GetCustomAmmo( self.Secondary.Ammo );
		local ammo = self:GetSecondaryAmmo();
		// do we have any ammo available to put into this?
		if( ammo < self.Secondary.ClipSize && available > 0 ) then
			// figure out how much ammo to add
			local needs = math.min( self.Secondary.ClipSize - ammo, available );
			local add = math.max( 0, needs );

			// remove the ammo from the players bag.
			self.Owner:AddCustomAmmo( self.Secondary.Ammo, -add );

			// add the ammo to our clip
			self:AddSecondaryAmmo( add );

			// don't fire
			self:SetNextSecondaryFire( CurTime() + ( self.Secondary.Delay || 0.25 ) + 0.5 );

			// flag
			reloaded = true;

		end

	end

	return reloaded;

end 

/*---------------------------------------------------------
   Name: SWEP:Deploy( )
   Desc: Whip it out
---------------------------------------------------------*/
function SWEP:Deploy( )
	if !self then return end
	if self.Owner:Team() == 1 then self.Owner:GetViewModel():SetSkin(1) end
	
	ironsight_ply = nil

	self.reloading = false
	self.add_prim = nil
	
	//if self.Owner:GetNetworkedInt( "ammo_" .. self.Primary.Ammo ) == 0 then return false end
	self:Draw()
	return true
end

function SWEP:Draw()
	self.Weapon:SendWeaponAnim(ACT_VM_DRAW)
	timer.Create( "VM_Idle_anim_timer_2" .. self:EntIndex(), 0.6, 1, function() if self.Owner and (self.Owner:IsNPC() or ( self.Owner:IsPlayer() and self.Owner:GetActiveWeapon( ) == self )) then self:SendWeaponAnim( ACT_VM_IDLE ) end end )
	return true
end

/*---------------------------------------------------------
   Think
---------------------------------------------------------*/
function SWEP:Think()	
	if self.idledelay and CurTime() > self.idledelay then
		self.idledelay = nil
		self:SendWeaponAnim( ACT_VM_IDLE )
	end
	if self.reloading then
		if self.reload_cur_start +1.4 <= CurTime() then
			self.reloading = false
			self:AddPrimaryAmmo( self.add_prim );
			self.Owner:AddCustomAmmo( self.Primary.Ammo, -self.add_prim )
			self.add_prim = nil
		end
	end
end

/*---------------------------------------------------------
   Name: GetCapabilities
   Desc: For NPCs, returns what they should try to do with it.
---------------------------------------------------------*/
function SWEP:GetCapabilities()
	return CAP_WEAPON_RANGE_ATTACK1 | CAP_INNATE_RANGE_ATTACK1 | CAP_WEAPON_RANGE_ATTACK2 | CAP_INNATE_RANGE_ATTACK2
end

function SWEP:StopPrimaryAttack()
end

function SWEP:StopSecondaryAttack()
end

function SWEP:StopReload()
end

/*---------------------------------------------------------
   Name: SWEP:Holster( weapon_to_swap_to )
   Desc: Weapon wants to holster
   RetV: Return true to allow the weapon to holster
---------------------------------------------------------*/
function SWEP:Holster( wep )
	self.reloaddelay = nil
	self:StopPrimaryAttack()
	self:StopSecondaryAttack()
	self:StopReload()
	if CLIENT then return true end
	self:StopCritSpray()
	return true
end



/*---------------------------------------------------------
   Name: SWEP:ShootBullet( )
   Desc: A convenience function to shoot bullets
---------------------------------------------------------*/
function SWEP:ShootEffects()
	self.Weapon:SendWeaponAnim( ACT_VM_PRIMARYATTACK ) 		// View model animation
	self:MuzzleFlash()								// Crappy muzzle light
	self.Owner:SetAnimation( PLAYER_ATTACK1 )				// 3rd Person Animation
end


/*---------------------------------------------------------
   Name: SWEP:ShootBullet( )
   Desc: A convenience function to shoot bullets
---------------------------------------------------------*/
function SWEP:ShootBullet( damage, num_bullets, aimcone )
	
	local bullet = {}
	bullet.Num 		= num_bullets
	bullet.Src 		= self.Owner:GetShootPos()			// Source
	bullet.Dir 		= self.Owner:GetAimVector()			// Dir of bullet
	bullet.Spread 	= Vector( aimcone, aimcone, 0 )		// Aim Cone
	bullet.Tracer	= 5									// Show a tracer on every x bullets 
	bullet.Force	= 1									// Amount of force to give to phys objects
	bullet.Damage	= damage
	bullet.AmmoType = "Pistol"
	
	self.Owner:FireBullets( bullet )
	
	self:ShootEffects()
	
end


/*---------------------------------------------------------
   Name: SWEP:TakePrimaryAmmo(   )
   Desc: A convenience function to remove ammo
---------------------------------------------------------*/
function SWEP:TakePrimaryAmmo( num )
	// Doesn't use clips
	if ( ( !self.Primary.Global and self:GetPrimaryAmmo() <= 0 ) or ( self.Primary.Global and self.Owner:GetNetworkedInt( "ammo_" .. self.Primary.Ammo ) <= 0 ) ) then 
	
		//if ( self:Ammo1() <= 0 ) then return end
		
		//self.Owner:RemoveAmmo( num, self.Weapon:GetPrimaryAmmoType() )
	
	return end
	
	if self.Primary.Global then
		self.Owner:SetNetworkedInt( "ammo_" .. self.Primary.Ammo, self.Owner:GetNetworkedInt( "ammo_" .. self.Primary.Ammo ) -num );
	else
		self:AddPrimaryAmmo( -num )
	end
	
end


/*---------------------------------------------------------
   Name: SWEP:TakeSecondaryAmmo(   )
   Desc: A convenience function to remove ammo
---------------------------------------------------------*/
function SWEP:TakeSecondaryAmmo( num )
	
	// Doesn't use clips
	if ( ( !self.Secondary.Global and self:GetSecondaryAmmo() <= 0 ) or ( self.Secondary.Global and self.Owner:GetNetworkedInt( "ammo_" .. self.Secondary.Ammo ) <= 0 ) ) then 
	
		//if ( self:Ammo2() <= 0 ) then return end
		
		//self.Owner:RemoveAmmo( num, self.Weapon:GetSecondaryAmmoType() )
	return end

	if self.Secondary.Global then
		self.Owner:SetNetworkedInt( "ammo_" .. self.Secondary.Ammo, self.Owner:GetCustomAmmo( self.Secondary.Ammo ) -num );
	else
		self:SetAmmo( self.Secondary.Ammo, self:GetSecondaryAmmo() -num )
	end
	
end


/*---------------------------------------------------------
   Name: SWEP:CanPrimaryAttack( )
   Desc: Helper function for checking for no ammo
---------------------------------------------------------*/
function SWEP:CanPrimaryAttack()
	if ( ( !self.Primary.Global and self:GetPrimaryAmmo() <= 0 ) or ( self.Primary.Global and self.Owner:GetNetworkedInt( "ammo_" .. self.Primary.Ammo ) <= 0 ) or ( !self.Primary.ShootInWater and self.Owner:WaterLevel() == 3 ) ) then
		if self.Primary.playsoundonempty then
			self:EmitSound( "Weapon_Pistol.Empty" )
		end
		self:SetNextPrimaryFire( CurTime() + 0.2 )
		if self.ReloadOnEmpty and self:GetPrimaryAmmo() <= 0 then self:Reload() end
		return false
		
	end

	return true

end


/*---------------------------------------------------------
   Name: SWEP:CanSecondaryAttack( )
   Desc: Helper function for checking for no ammo
---------------------------------------------------------*/
function SWEP:CanSecondaryAttack()
	if ( ( !self.Secondary.Global and self:GetSecondaryAmmo() <= 0 ) or ( self.Secondary.Global and self.Owner:GetNetworkedInt( "ammo_" .. self.Secondary.Ammo ) <= 0 ) or ( !self.Secondary.ShootInWater and self.Owner:WaterLevel() == 3 ) ) then
		if self.Secondary.playsoundonempty then
			self.Weapon:EmitSound( "Weapon_Pistol.Empty" )
		end
		self.Weapon:SetNextSecondaryFire( CurTime() + 0.2 )
		return false
		
	end

	return true

end


/*---------------------------------------------------------
   Name: ContextScreenClick(  aimvec, mousecode, pressed, ply )
---------------------------------------------------------*/
function SWEP:ContextScreenClick( aimvec, mousecode, pressed, ply )
end

/*---------------------------------------------------------
	onRestore
	Loaded a saved game (or changelevel)
---------------------------------------------------------*/
function SWEP:OnRestore()

	self.NextIronChs = 0
	self:SetIronsights( false )
	
end

/*---------------------------------------------------------
   Name: OnRemove
   Desc: Called just before entity is deleted
---------------------------------------------------------*/
function SWEP:OnRemove()
end


/*---------------------------------------------------------
   Name: OwnerChanged
   Desc: When weapon is dropped or picked up by a new player
---------------------------------------------------------*/
function SWEP:OwnerChanged()
end
