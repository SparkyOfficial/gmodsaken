

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
SWEP.ReloadOnEmpty = true
SWEP.playsoundonempty = true

SWEP.GotGlobalClip = true
SWEP.GotPrimary = true
SWEP.GotSecondary = false

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
SWEP.Secondary.Ammo			= "Pistol"
SWEP.Secondary.Global = true
SWEP.Secondary.Reload = true
SWEP.Secondary.PickUpAmmo = 0
SWEP.Secondary.playsoundonempty = true

SWEP.LastReload = 0

SWEP.Primary.Delay = 0.8
SWEP.Primary.FastDelay = 0.15
SWEP.AttackDelay = 0
SWEP.FastAttackDelay = 0

/*---------------------------------------------------------
	PrimaryAttack
---------------------------------------------------------*/
function SWEP:PrimaryAttack()
	if GetGlobalBool( "humiliation" ) and self.Owner:Team() == GetGlobalInt( "team_lost" ) then return end
	//self.Weapon:SetNextSecondaryFire( CurTime() + self.Primary.Delay )
	//self.Weapon:SetNextPrimaryFire( CurTime() + self.Primary.Delay )
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
		self.Owner:EmitSound( self.Primary.CritSound )
	else
		self.Owner:EmitSound( self.Primary.Sound )
	end
	self:ShootBullet( damage, self.Primary.NumShots, self.Primary.Cone, self.critspray )
	
	if ( self.Owner:IsNPC() ) then return end
	
	// Remove 1 bullet from our clip
	self:TakePrimaryAmmo( 1 )
	
	if self.scoping then
		timer.Simple(0.4, function()
			if self and ValidEntity(self) and self.Owner and ValidEntity(self.Owner) then
				self:SetNetworkedBool("noscope", true)
				self:SetNetworkedInt("charge", 0)
				self.Owner:SetFOV(75)
			end
		end)
		timer.Simple(1.5, function()
			if self and ValidEntity(self) and self.Owner and ValidEntity(self.Owner) and self.scoping then
				self.scoping = true
				self:SetNetworkedBool("noscope", false)
				self:SetNetworkedBool("scoping", true)
				self.Owner:SetFOV(20)
			end
		end)
	end
	
	// In singleplayer this function doesn't get called on the client, so we use a networked float
	// to send the last shoot time. In multiplayer this is predicted clientside so we don't need to 
	// send the float.
	if ( (SinglePlayer() && SERVER) || CLIENT ) then
		self.Weapon:SetNetworkedFloat( "LastShootTime", CurTime() )
	end
end

function SWEP:ShootBullet( damage, num_bullets, aimcone, critical )
	//self:EjectShell("models/weapons/shells/shell_shotgun.mdl", 10, 5, -6, 0.3)

	local pos = self.Owner:GetShootPos()
	pos = pos + self.Owner:GetForward() * self.EffectMuzzleForward
	pos = pos + self.Owner:GetRight() * self.EffectMuzzleRight
	pos = pos + self.Owner:GetUp() * self.EffectMuzzleUp

	local bullet = {}
	bullet.Num = num_bullets
	bullet.Src = self.Owner:GetShootPos()
	bullet.Dir = self.Owner:GetAimVector()
	bullet.Spread = Vector( aimcone, aimcone, aimcone ) 
	bullet.Tracer = self.EffectTracerCount
	bullet.TracerPos = pos
	bullet.Critical = critical
	bullet.Force = 1
	bullet.Damage = damage /num_bullets
	bullet.AmmoType = self.Primary.BulletType
	self:FireBulletsCustom( bullet )
	
	local muzzle = ents.Create( "info_particle_system" )
	muzzle:SetKeyValue( "effect_name", self.EffectMuzzle )
	muzzle:SetKeyValue( "start_active", "1" )
	muzzle:SetPos( pos )
	muzzle:SetAngles( self.Owner:GetAngles() )
	//muzzle:SetParent( self )
	muzzle:Spawn()
	muzzle:Activate()
	//muzzle:Fire( "SetParentAttachment", "muzzle", 0 )
	muzzle:Fire( "Kill", "", 0.3 )
end 

function SWEP:FireBulletsCustom(b)
    for i = 1, b.Num do
        local rand = Vector( math.Rand( -b.Spread.x, b.Spread.x ), math.Rand( -b.Spread.y, b.Spread.y ), math.Rand( -b.Spread.z, b.Spread.z ) )
        local newdir = b.Dir + rand

		local tracedata = {} 
		tracedata.start = b.Src
		tracedata.endpos = b.Src +(b.Dir +rand) *9000
		tracedata.filter = self.Owner
		local trace = util.TraceLine(tracedata)  
		if self:GetClass() == "tf_weapon_sniperrifle" then
			b.Critical = false
			if trace.HitGroup == 1 then b.Critical = true end
			local sniper_dmg = self:CalculateDamage(b.Critical)
			b.Damage = math.random(sniper_dmg[1],sniper_dmg[2])
		end
		
		util.BlastDamage( self, self.Owner, trace.HitPos, 12, b.Damage )
		local tracer = math.random(1,b.Tracer)
		self:GetTextureDecal(trace)
		
		tracedata.mask = 16432
		local trace_wt = util.TraceLine(tracedata)
		if trace_wt.Hit then
			local particle = ents.Create("info_particle_system")
			particle:SetKeyValue("effect_name", "water_bulletsplash01_minigun")
			particle:SetKeyValue( "start_active", "1" )
			particle:SetPos(trace_wt.HitPos)
			particle:Spawn()
			particle:Activate()
			particle:Fire("kill","",0.3)
			WorldSound( "ambient/water/water_splash" .. math.random(1,3) .. ".wav", trace_wt.HitPos )
		end
		
		if b.Critical then
			local particle = ents.Create("info_particle_system")
			particle:SetKeyValue("effect_name", "bullet_impact1_" .. self.team .. "_crit")
			particle:SetKeyValue( "start_active", "1" )
			particle:SetPos(trace.HitPos)
			particle:Spawn()
			particle:Activate()
			particle:Fire("kill","",0.3)
			if ValidEntity(trace.Entity) and (trace.Entity:IsNPC() or trace.Entity:IsPlayer()) then
				self:CriticalHit(trace.HitPos)
			end
		end
		
		if tracer != 1 then return end
		local target = ents.Create("sent_tf_killicon")
		target:SetPos(trace.HitPos)
		target:Spawn()
		target:Activate()
		target:SetName(tostring(self) .. "_bullettarget" .. i)
		target:Fire("kill","",0.3)

		local particle = ents.Create("info_particle_system")
		local tracer = self.EffectTracer .. self.team
		if b.Critical then tracer = tracer .. "_crit" end
		particle:SetKeyValue("effect_name", tracer)
		particle:SetKeyValue( "cpoint1", target:GetName() )
		//particle:SetEntity( "cpoint1", target )
		particle:SetKeyValue( "start_active", "1" )
		particle:SetPos(b.TracerPos)
		particle:Spawn()
		particle:Activate()
		particle:Fire("kill","",0.3)
    end
end

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
	
	if self:GetSkin() == 0 then
		self.team = "red"
	else
		self.team = "blue"
	end
end

function SWEP:CheckState()
	if self and ValidEntity( self ) and self.Owner and ValidEntity( self.Owner ) and self.Owner:GetActiveWeapon( ) == self then return true end
	return false
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

/*---------------------------------------------------------
   Name: SWEP:Precache( )
   Desc: Use this function to precache stuff
---------------------------------------------------------*/
function SWEP:Precache()
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
   Name: SWEP:Deploy( )
   Desc: Whip it out
---------------------------------------------------------*/
function SWEP:Deploy( )
	if !self then return end
	if self.Owner:Team() == 1 then self.Owner:GetViewModel():SetSkin(1) end

	self.reloading = false
	self.add_prim = nil
	
	//if self.Owner:GetNetworkedInt( "ammo_" .. self.Primary.Ammo ) == 0 then return false end
	self:Draw()
	return true
end

function SWEP:Draw()
	if self:GetClass() == "tf_weapon_sniperrifle" then self:SetNetworkedBool("noscope", false); self:SetNetworkedInt("charge", 0) end
	self.Weapon:SendWeaponAnim(ACT_VM_DRAW)
	timer.Create( "VM_Idle_anim_timer_2" .. self:EntIndex(), 0.6, 1, function() if self.Owner and (self.Owner:IsNPC() or ( self.Owner:IsPlayer() and self.Owner:GetActiveWeapon( ) == self )) then self:SendWeaponAnim( ACT_VM_IDLE ) end end )
	return true
end

/*------------------------------------
    Reload
------------------------------------*/
function SWEP:Reload( )
	if self.startreloaddelay or self.reloading or self.reloaddelay or CLIENT then return end
	local reloaded = false
	if( self.LastReload > CurTime() ) then return reloaded; end
	self.LastReload = CurTime() + 1.41;

	if( self.Primary.Reload and self.Primary && self.Primary.Ammo && self.Primary.ClipSize != -1 ) then

		local available = self.Owner:GetCustomAmmo( self.Primary.Ammo );
		local ammo = self:GetClip(self.Primary.Ammo)
		// do we have any ammo available to put into this?
		if( ammo < self.Primary.ClipSize && available > 0 ) then
			self.idledelay = nil
			if !self.ReloadSingle then
				self.Weapon:SendWeaponAnim( ACT_VM_RELOAD ) 
				self.Owner:SetAnimation( PLAYER_RELOAD )
				self.idledelay = CurTime() +self:SequenceDuration()
				
				local needs = math.min( self.Primary.ClipSize - ammo, available );
				self.add_prim = math.max( 0, needs );
				self.reloading = true
				self.reload_cur_start = CurTime()
			else
				self.Weapon:SendWeaponAnim( ACT_RELOAD_START )
				self.startreloaddelay = CurTime() +self:SequenceDuration()
				self.Owner:SetAnimation( PLAYER_RELOAD )
			end
			self:SetNextPrimaryFire( CurTime() + ( self.Primary.Delay || 0.25 ) + 1.4 )
			self:SetNextSecondaryFire( CurTime() + ( self.Primary.Delay || 0.25 ) + 1.4 )
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

/*---------------------------------------------------------
   Name: GetCapabilities
   Desc: For NPCs, returns what they should try to do with it.
---------------------------------------------------------*/
function SWEP:GetCapabilities()
	return CAP_WEAPON_RANGE_ATTACK1 | CAP_INNATE_RANGE_ATTACK1 | CAP_WEAPON_RANGE_ATTACK2 | CAP_INNATE_RANGE_ATTACK2
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
	if self.scoping then
		self:Unzoom()
	end
	
	self.reloaddelay = nil
	self:StopPrimaryAttack()
	self:StopSecondaryAttack()
	self:StopReload()
	if CLIENT then return true end
	self:StopCritSpray()
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



