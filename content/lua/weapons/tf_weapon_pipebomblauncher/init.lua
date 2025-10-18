
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

SWEP.MinDamage = 90
SWEP.MaxDamage = 140
SWEP.CritDamage = 340
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
   Name: SWEP:Holster( weapon_to_swap_to )
   Desc: Weapon wants to holster
   RetV: Return true to allow the weapon to holster
---------------------------------------------------------*/
function SWEP:Holster( wep )
	self:SetNetworkedInt( "charge", 0 )
	self.reloaddelay = nil
	self:StopPrimaryAttack()
	self:StopSecondaryAttack()
	self:StopReload()
	if CLIENT then return true end
	self:StopCritSpray()
	return true
end

/*---------------------------------------------------------
	PrimaryAttack
---------------------------------------------------------*/
function SWEP:PrimaryAttack()
	if GetGlobalBool( "humiliation" ) and self.Owner:Team() == GetGlobalInt( "team_lost" ) then return end
	self.Weapon:SetNextSecondaryFire( CurTime() + self.Primary.Delay )
	self.Weapon:SetNextPrimaryFire( CurTime() + self.Primary.Delay )
	if !self:CanPrimaryAttack( ) or self.attacking then return end
	self.Weapon:SendWeaponAnim( ACT_VM_PULLBACK )
	self.attacking = true
	// In singleplayer this function doesn't get called on the client, so we use a networked float
	// to send the last shoot time. In multiplayer this is predicted clientside so we don't need to 
	// send the float.
	if ( (SinglePlayer() && SERVER) || CLIENT ) then
		self.Weapon:SetNetworkedFloat( "LastShootTime", CurTime() )
	end
end

function SWEP:SecondaryAttack()
	if string.find(GAMEMODE.Name, "Fortress" ) or #self.Owner.stickybombs == 0 then return end
	self.Owner:EmitSound("weapons/stickybomblauncher_det.wav", 100, 100)
	timer.Simple(0.18, function()
		if !self.Owner or !ValidEntity(self.Owner) then return end
		for k, v in pairs(self.Owner.stickybombs) do
			if ValidEntity(v) then
				v:Explode()
			end
		end
		self.Owner.stickybombs = {}
		self.Owner:SetNetworkedInt("tf_stickies", 0)
	end)
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
	if self.nextonthink and CurTime() < self.nextonthink then return end
	if self.attacking then
		if !self.Owner:KeyDown( 1 ) then
			self:LaunchStickybomb(((self:GetNetworkedInt("charge") /100) *3700) +4500)
			return
		end
		self:SetNetworkedInt("charge", self:GetNetworkedInt("charge") +1.5)
		if self:GetNetworkedInt("charge") >= 100 then
			self:LaunchStickybomb(8200)
			return
		end
		self.nextonthink = CurTime() +0.05
		return true
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
		if self.reload_cur_start +0.6 <= CurTime() then
			self.reloading = false
			self:AddPrimaryAmmo( self.add_prim );
			self.Owner:AddCustomAmmo( self.Primary.Ammo, -self.add_prim )
			self.add_prim = nil
			local available = self.Owner:GetCustomAmmo( self.Primary.Ammo );
			if self:GetClip(self.Primary.Ammo) < 8 and available > 0 then
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

function SWEP:LaunchStickybomb(velocity)
	self:SetNetworkedInt("charge", 0)
	self.attacking = false
	self.idledelay = CurTime() +1.2
	self:TakePrimaryAmmo( 1 )
	self:StopReload()
	
	local crit = self:Critical()
	if !self.Owner.stickybombs then self.Owner.stickybombs = {} end
	local sticky = ents.Create("tf_stickybomb")
	local pos = self.Owner:GetShootPos()
	pos = pos + self.Owner:GetForward() * 20
	pos = pos + self.Owner:GetRight() * 6
	pos = pos + self.Owner:GetUp() * -7
	sticky:SetPos(pos)
	sticky:SetAngles(self.Owner:EyeAngles())
	sticky:SetPhysicsAttacker( self.Owner )
	sticky.owner = self
	if crit then sticky.critical = true; self.Owner:EmitSound("weapons/stickybomblauncher_shoot_crit.wav", 100, 100) else self.Owner:EmitSound("weapons/stickybomblauncher_shoot.wav", 100, 100) end
	sticky:Spawn()
	sticky:Activate()
	sticky:SetOwner(self.Owner)
	
	local phys = sticky:GetPhysicsObject()
	if (phys:IsValid()) then
		local velocity = sticky:GetForward() *velocity
		velocity.z = velocity.z +1100
		phys:ApplyForceCenter( velocity )
	end
	
	table.insert(self.Owner.stickybombs,sticky)
	if #self.Owner.stickybombs >= 9 then
		self.Owner.stickybombs[1]:Explode()
		local tbl_new  ={}
		for k, v in pairs(self.Owner.stickybombs) do
			if v != self.Owner.stickybombs[1] then
				table.insert(tbl_new, v)
			end
		end
		self.Owner.stickybombs = tbl_new
	end
	self.Owner:SetNetworkedInt("tf_stickies", #self.Owner.stickybombs)
	
	self.Weapon:SendWeaponAnim( ACT_VM_PRIMARYATTACK )
	self.Owner:SetAnimation( PLAYER_ATTACK2 )
	self.allowreloaddelay = CurTime() +0.5
	
	local pos = self.Owner:GetShootPos()
	pos = pos + self.Owner:GetForward() * 20
	pos = pos + self.Owner:GetRight() * 5
	pos = pos + self.Owner:GetUp() * -3
	
	local muzzle = ents.Create( "info_particle_system" )
	muzzle:SetKeyValue( "effect_name", "muzzle_pipelauncher" )
	muzzle:SetKeyValue( "start_active", "1" )
	muzzle:SetPos( pos )
	local angle = self.Owner:GetAngles()
	angle.p = angle.p +90
	muzzle:SetAngles( angle )
	muzzle:Spawn()
	muzzle:Activate()
	muzzle:Fire( "Kill", "", 0.3 )
end

function SWEP:StopReload()
	self.reload_cur_start = nil
	self.startreloaddelay = nil
	self.reloading = false
	self.reloaddelay = nil
end
