
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include( "shared.lua" )

SWEP.Weight				= 5			// Decides whether we should switch from/to this
SWEP.AutoSwitchTo		= true		// Auto switch to if we pick it up
SWEP.AutoSwitchFrom		= true		// Auto switch from if you pick up a better weapon
SWEP.MetalToGive = 100
SWEP.SequenceDelay = 1.25
SWEP.DrawDelay = 0.6

SWEP.MinDamage = 45
SWEP.MaxDamage = 85
SWEP.CritDamage = 195

SWEP.Swing = { Sound( "weapons/bat_draw_swoosh1.wav" ) , Sound( "weapons/bat_draw_swoosh1.wav" ) }
SWEP.SwingCrit = Sound( "weapons/fist_swing_crit.wav" )
SWEP.HitFlesh = { Sound( "weapons/cbar_hitbod1.wav" ), Sound( "weapons/cbar_hitbod2.wav" ), Sound( "weapons/cbar_hitbod3.wav" ) }
SWEP.HitWorld = { Sound( "weapons/fist_hit_world1.wav" ), Sound( "weapons/fist_hit_world2.wav" ) }

SWEP.Primary.Delay = 0.8
SWEP.NextSecondary = 0

/*---------------------------------------------------------
	PrimaryAttack
---------------------------------------------------------*/
function SWEP:PrimaryAttack( anim )
	if GetGlobalBool( "humiliation" ) and self.Owner:Team() == GetGlobalInt( "team_lost" ) then return end
	self.Weapon:SetNextPrimaryFire( CurTime() + self.Primary.Delay )
	self.Weapon.NextSecondary = CurTime() + self.Primary.Delay
	
	local crit = self:Critical()
	if !crit then
		if !anim then
			self.Weapon:SendWeaponAnim( ACT_VM_HITLEFT )
		else
			self.Weapon:SendWeaponAnim( ACT_VM_HITRIGHT )
		end
	else
		self.Weapon:SendWeaponAnim( ACT_VM_SWINGHARD )
	end
	self.Owner:SetAnimation( PLAYER_ATTACK1 )
	self.idledelay = CurTime() +self.SequenceDelay//self:SequenceDuration()
	
	if !crit then
		self.Owner:EmitSound( self.Swing[math.random(1,#self.Swing)], 100, 100 )
	else
		self.Owner:EmitSound( self.SwingCrit, 100, 100 )
	end
	
	local function Attack()
		if !self:CheckState() then return end
		local pos = self.Owner:GetShootPos()
		local ang = self.Owner:GetAimVector()
		local tracedata = {}
		tracedata.start = pos
		tracedata.endpos = pos +(self.Owner:GetAimVector( ) *80)
		tracedata.filter = self.Owner
		local tr = util.TraceLine(tracedata)
		if (tr.Entity and ValidEntity(tr.Entity)) or self:EntsInSphere( tracedata.endpos,12 ) then
			if !crit then
				util.BlastDamage(self, self.Owner, tr.HitPos, 12, math.random(self.MinDamage, self.MaxDamage) )
			else
				util.BlastDamage(self, self.Owner, tr.HitPos, 12, self.CritDamage )
				if self:GetClass() == "tf_weapon_bottle" and !self.broken then
					self.Owner:GetViewModel():Fire( "SetBodyGroup", "1", 0 )
					self.broken = true
					self.Owner:EmitSound( "weapons/bottle_break.wav", 100, 100 )
				end
			end
			if self:GetClass() != "tf_weapon_bottle" then
				self.Owner:EmitSound( self.HitFlesh[math.random(1,#self.HitFlesh)], 100, 100 )
			else
				if !self.broken then
					self.Owner:EmitSound( self.HitFleshIntact[math.random(1,#self.HitFleshIntact)], 100, 100 )
				else
					self.Owner:EmitSound( self.HitFleshBroken[math.random(1,#self.HitFleshBroken)], 100, 100 )
				end
			end
		elseif tr.HitWorld then
			local hit_decal = self:GetTextureDecal(tr)
			if self:GetClass() != "tf_weapon_bottle" then
				self.Owner:EmitSound( self.HitWorld[math.random(1,#self.HitWorld)], 100, 100 )
			else
				if !self.broken then
					self.Owner:EmitSound( self.HitWorldIntact[math.random(1,#self.HitWorldIntact)], 100, 100 )
					if crit then
						self.Owner:GetViewModel():Fire( "SetBodyGroup", "1", 0 )
						self.broken = true
						self.Owner:EmitSound( "weapons/bottle_break.wav", 100, 100 )
					end
				else
					self.Owner:EmitSound( self.HitWorldBroken[math.random(1,#self.HitWorldBroken)], 100, 100 )
				end
			end
		end
		
		// In singleplayer this function doesn't get called on the client, so we use a networked float
		// to send the last shoot time. In multiplayer this is predicted clientside so we don't need to 
		// send the float.
		if ( (SinglePlayer() && SERVER) || CLIENT ) then
			self.Weapon:SetNetworkedFloat( "LastShootTime", CurTime() )
		end
	end
	
	timer.Simple( 0.3, Attack )
end

/*---------------------------------------------------------
	SecondaryAttack
---------------------------------------------------------*/
function SWEP:SecondaryAttack( anim )
	if GetGlobalBool( "humiliation" ) and self.Owner:Team() == GetGlobalInt( "team_lost" ) then return end
	if CurTime() < self.Weapon.NextSecondary then return end
	self.Weapon.NextSecondary = CurTime() + self.Primary.Delay
	self:PrimaryAttack( true )
end

