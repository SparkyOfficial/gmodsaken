
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include( "shared.lua" )

SWEP.Weight				= 6			// Decides whether we should switch from/to this
SWEP.AutoSwitchTo		= true		// Auto switch to if we pick it up
SWEP.AutoSwitchFrom		= true		// Auto switch from if you pick up a better weapon
SWEP.MetalToGive = 100
SWEP.SequenceDelay = 0.85
SWEP.DrawDelay = 1.2

SWEP.ReloadOnEmpty = true
SWEP.playsoundonempty = false
SWEP.HoldType = "pistol"

SWEP.MinDamage = 10
SWEP.MaxDamage = 15
SWEP.CritDamage = 30
SWEP.CritChance = 2

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
	self.idledelay = CurTime() +0.3
	self:TakePrimaryAmmo( 1 )	
	local crit = self:Critical()
	if crit and !self.critspray then
		self:StartCritSpray(math.random(3,5))
	end
	
	local needle = ents.Create("tf_syringe")
	needle:SetModel("models/weapons/w_models/w_syringe_proj.mdl")
	local pos = self:GetAttachment(self:LookupAttachment("muzzle"))["Pos"]
	pos.z = pos.z +self.Owner:WorldToLocal(self.Owner:GetEyeTrace( ).StartPos).z
	needle:SetPos(pos)
	needle:SetAngles(self.Owner:EyeAngles())
	needle.owner = self
	if self.critspray then needle.critical = true; self.Owner:EmitSound("weapons/syringegun_shoot_crit.wav", 100, 100) else self.Owner:EmitSound("weapons/syringegun_shoot.wav", 100, 100) end
	needle:Spawn()
	needle:Activate()
	needle:SetOwner(self.Owner)

	local phys = needle:GetPhysicsObject()
	if phys:IsValid() then
		phys:SetVelocity( (self.Owner:GetForward() +Vector(0, math.Rand(-0.009,0.009), math.Rand(-0.009,0.009))) *1900 )
	end
	
	self.Weapon:SendWeaponAnim( ACT_VM_PRIMARYATTACK )
	self.Owner:SetAnimation( PLAYER_ATTACK2 )
	
	// In singleplayer this function doesn't get called on the client, so we use a networked float
	// to send the last shoot time. In multiplayer this is predicted clientside so we don't need to 
	// send the float.
	if ( (SinglePlayer() && SERVER) || CLIENT ) then
		self.Weapon:SetNetworkedFloat( "LastShootTime", CurTime() )
	end
	
end

function SWEP:SecondaryAttack()
end
