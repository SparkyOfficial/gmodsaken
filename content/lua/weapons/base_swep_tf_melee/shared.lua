

// Variables that are used on both client and server

SWEP.Author			= ""
SWEP.Contact		= ""
SWEP.Purpose		= ""
SWEP.Instructions	= ""

SWEP.ReloadOnEmpty = false
SWEP.playsoundonempty = false

SWEP.GotGlobalClip = true
SWEP.GotPrimary = true
SWEP.GotSecondary = false

SWEP.Spawnable			= false
SWEP.AdminSpawnable		= false

SWEP.Primary.ClipSize		= 8					// Size of a clip
SWEP.Primary.DefaultClip	= 32				// Default number of bullets in a clip
SWEP.Primary.ShootInWater		= true
SWEP.Primary.Automatic		= true			// Automatic/Semi Auto
SWEP.Primary.Ammo			= "none"
SWEP.Primary.Global = false
SWEP.Primary.Reload = false
SWEP.Primary.PickUpAmmo = 0

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"

SWEP.HoldType = "melee"

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

/*---------------------------------------------------------
   Name: SWEP:Deploy( )
   Desc: Whip it out
---------------------------------------------------------*/
function SWEP:Deploy( )
	if !self then return end
	if self.Owner:Team() == 1 then self.Owner:GetViewModel():SetSkin(1) end

	self.r_emit = false
	self.add_prim = nil

	self:Draw()
	return true
end

function SWEP:Draw()
	if self.Owner:GetNetworkedInt( "ammo_" .. self.Primary.Ammo ) == 0 then return false end
	self.Weapon:SendWeaponAnim(ACT_VM_DRAW)
	timer.Create( "VM_Idle_anim_timer_2" .. self:EntIndex(), 0.6, 1, function() if self.Owner and (self.Owner:IsNPC() or ( self.Owner:IsPlayer() and self.Owner:GetActiveWeapon( ) == self )) then self:SendWeaponAnim( ACT_VM_IDLE ) end end )
	return true
end

/*---------------------------------------------------------
   Name: GetCapabilities
   Desc: For NPCs, returns what they should try to do with it.
---------------------------------------------------------*/
function SWEP:GetCapabilities()
	return CAP_WEAPON_RANGE_ATTACK1 | CAP_INNATE_RANGE_ATTACK1 | CAP_WEAPON_RANGE_ATTACK2 | CAP_INNATE_RANGE_ATTACK2
end


/*---------------------------------------------------------
   Name: SWEP:Holster( weapon_to_swap_to )
   Desc: Weapon wants to holster
   RetV: Return true to allow the weapon to holster
---------------------------------------------------------*/
function SWEP:Holster( wep )
	if self.cwep and ValidEntity(self.cwep) then self.cwep:Remove() end
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


local IRONSIGHT_TIME = 0.25

/*---------------------------------------------------------
   Name: GetViewModelPosition
   Desc: Allows you to re-position the view model
---------------------------------------------------------*/
function SWEP:GetViewModelPosition( pos, ang )
	if ( !self.IronSightsPos ) then return pos, ang end
	local bIron = self.Weapon:GetNetworkedBool( "Ironsights" )
	
	if ( bIron != self.bLastIron ) then
	
		self.bLastIron = bIron 
		self.fIronTime = CurTime()
		
		if ( bIron ) then 
			self.SwayScale 	= 0.3
			self.BobScale 	= 0.1
		else 
			self.SwayScale 	= 1.0
			self.BobScale 	= 1.0
		end
	
	end
	
	local fIronTime = self.fIronTime or 0

	if ( !bIron && fIronTime < CurTime() - IRONSIGHT_TIME ) then 
		return pos, ang 
	end
	
	local Mul = 1.0
	
	if ( fIronTime > CurTime() - IRONSIGHT_TIME ) then
	
		Mul = math.Clamp( (CurTime() - fIronTime) / IRONSIGHT_TIME, 0, 1 )
		
		if (!bIron) then Mul = 1 - Mul end
	
	end

	local Offset	= self.IronSightsPos
	
	if ( self.IronSightsAng ) then
	
		ang = ang * 1
		ang:RotateAroundAxis( ang:Right(), 		self.IronSightsAng.x * Mul )
		ang:RotateAroundAxis( ang:Up(), 		self.IronSightsAng.y * Mul )
		ang:RotateAroundAxis( ang:Forward(), 	self.IronSightsAng.z * Mul )
	
	
	end
	
	local Right 	= ang:Right()
	local Up 		= ang:Up()
	local Forward 	= ang:Forward()
	
	

	pos = pos + Offset.x * Right * Mul
	pos = pos + Offset.y * Forward * Mul
	pos = pos + Offset.z * Up * Mul

	return pos, ang
	
end


/*---------------------------------------------------------
	SetIronsights
---------------------------------------------------------*/
function SWEP:SetIronsights( b )

	self.Weapon:SetNetworkedBool( "Ironsights", b )

end

