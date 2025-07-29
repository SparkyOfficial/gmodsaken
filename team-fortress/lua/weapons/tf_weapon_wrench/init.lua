AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include('shared.lua')

SWEP.Weight				= 5			// Decides whether we should switch from/to this
SWEP.AutoSwitchTo		= true		// Auto switch to if we pick it up
SWEP.AutoSwitchFrom		= true		// Auto switch from if you pick up a better weapon
SWEP.MetalToGive = 200
SWEP.SequenceDelay = 0.85
SWEP.DrawDelay = 0.6

SWEP.MinDamage = 45
SWEP.MaxDamage = 85
SWEP.CritDamage = 195

SWEP.Swing = Sound( "weapons/wrench_swing.wav" )
SWEP.SwingCrit = Sound( "weapons/wrench_swing_crit.wav" )
SWEP.HitFlesh = { Sound( "weapons/cbar_hitbod1.wav" ), Sound( "weapons/cbar_hitbod2.wav" ), Sound( "weapons/cbar_hitbod3.wav" ) }
SWEP.HitWorld = { Sound( "weapons/wrench_hit_world.wav" ) }

SWEP.Primary.Delay = 0.8
SWEP.Primary.AmmoCount = 200
SWEP.Primary.Ammo = "metal"
SWEP.Primary.Global = true

local buildings = { "obj_dispenser", "obj_sentrygun", "obj_teleporter_entrance", "obj_teleporter_exit", "obj_sapper" }

/*---------------------------------------------------------
  Name: Equip
  Desc: A player or NPC has picked the weapon up
//-------------------------------------------------------*/
function SWEP:Equip( NewOwner )
	if !NewOwner:GetCustomAmmo( self.Primary.Ammo ) then
		NewOwner:SetCustomAmmo( self.Primary.Ammo, self.Primary.AmmoCount )
	else
		NewOwner:SetCustomAmmo( self.Primary.Ammo, NewOwner:GetCustomAmmo( self.Primary.Ammo ) +self:CalculatePrimaryPickUpAmmo( NewOwner ) )
	end
	
	if NewOwner:GetNetworkedInt( "ammo_metal" ) >= 200 then return end
	local metal_new
	if NewOwner:GetNetworkedInt( "ammo_metal" ) +self.MetalToGive <= 200 then
		metal_new = self.MetalToGive
	else
		metal_new = NewOwner:GetNetworkedInt( "ammo_metal" ) +(NewOwner:GetNetworkedInt( "ammo_metal" ) -(200 -self.MetalToGive))
	end
	NewOwner:SetNetworkedInt( "ammo_metal", metal_new )
end 

/*---------------------------------------------------------
   Name: EquipAmmo
   Desc: The player has picked up the weapon and has taken the ammo from it
		The weapon will be removed immidiately after this call.
---------------------------------------------------------*/
function SWEP:EquipAmmo( NewOwner )
	local NewPrimAmmo = self:CalculatePrimaryPickUpAmmo( NewOwner )
	NewOwner:EmitSound( "items/ammo_pickup.wav", 100, 100 )
	self:Equip( NewOwner )
	self.Primary.AmmoToGive = nil
end

/*---------------------------------------------------------
	PrimaryAttack
---------------------------------------------------------*/
function SWEP:PrimaryAttack()
	if GetGlobalBool( "humiliation" ) and self.Owner:Team() == GetGlobalInt( "team_lost" ) then return end
	self.Weapon:SetNextPrimaryFire( CurTime() + self.Primary.Delay )
	
	local crit = self:Critical()
	if !crit then
		self.Weapon:SendWeaponAnim( ACT_VM_HITCENTER )
	else
		self.Weapon:SendWeaponAnim( ACT_VM_SWINGHARD )
	end
	self.Owner:SetAnimation( PLAYER_ATTACK1 )
	self.idledelay = CurTime() +self.SequenceDelay
	
	if !crit then
		self.Owner:EmitSound( self.Swing, 100, 100 )
	else
		self.Owner:EmitSound( self.SwingCrit, 100, 100 )
	end
	
	if ( (SinglePlayer() && SERVER) || CLIENT ) then
		self.Weapon:SetNetworkedFloat( "LastShootTime", CurTime() )
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
		local ammo = self.Owner:GetNetworkedInt( "ammo_" .. self.Primary.Ammo )
		if !tr.Entity or !ValidEntity(tr.Entity) then
			for k, v in pairs(ents.FindInSphere(tracedata.endpos,12)) do
				if ValidEntity(v) and table.HasValue( buildings, v:GetClass() ) then
					tr.Entity = v
				end
			end
		end
		if (tr.Entity and ValidEntity(tr.Entity) and table.HasValue( buildings, tr.Entity:GetClass() )) then
			if !tr.Entity.sapped and tr.Entity:GetClass() != "obj_sapper" then
				if !tr.Entity.upgrading and !tr.Entity.settingup and ammo > 0 and ((tr.Entity.metalremain and tr.Entity.metalremain > 0) or !tr.Entity.metalremain) then
					self.Owner:EmitSound( "weapons/wrench_hit_build_success" .. math.random(1,2) .. ".wav", 100, 100 )
					local metal_used = 0
					// Add the health
					local health
					if tr.Entity.level == 1 then
						health = (sk_tf2_sentry_lvl1_health_value /100) *60
					elseif tr.Entity.level == 2 then
						health = (sk_tf2_sentry_lvl2_health_value /100) *55
					elseif tr.Entity.level == 3 then
						health = (sk_tf2_sentry_lvl3_health_value /100) *45
					else
						health = 90
					end
					local max_health = tr.Entity:GetMaxHealth()
					if tr.Entity:Health() < max_health then
						if tr.Entity:Health() +health <= max_health then
							if ammo >= 21 then
								metal_used = 21
							else
								metal_used = ammo
								health = math.Round((ammo /21) *health)
							end
							tr.Entity:SetHealth( tr.Entity:Health() +health )
						else
							//messy method, needs to be redone
							if ammo >= 21 then
								metal_used = math.Round(((max_health -tr.Entity:Health()) /health) *21)
								tr.Entity:SetHealth( max_health )
							else
								metal_used = math.Round(((max_health -tr.Entity:Health()) /health) *ammo)
								ammo_gv = math.Round((ammo /21) *(max_health -tr.Entity:Health()))
								tr.Entity:SetHealth(tr.Entity:Health() +health)
							end
							//
						end
						tr.Entity:SetNetworkedInt("health", tr.Entity:Health())
						tr.Entity:CheckDamageLevel()
					end
					ammo = ammo -metal_used
					if tr.Entity:GetClass() != "obj_sentrygun" or ammo <= 0 then self:TakePrimaryAmmo( metal_used ); return end
					//
					// Add sentry shells
					local ammo_gv
					local ammo_max
					local rockets_gv
					if tr.Entity.level == 1 then
						ammo_gv = 18
						ammo_max = 44
					elseif tr.Entity.level == 2 then
						ammo_gv = 22
						ammo_max = 64
					else
						ammo_gv = 45
						ammo_max = 160
						rockets_gv = 8
					end
					if tr.Entity.ammo < ammo_max then
						if tr.Entity.ammo +ammo_gv <= ammo_max then
							if ammo >= 65 then
								metal_used = 65
							else
								metal_used = ammo
								ammo_gv = math.Round((ammo /65) *ammo_gv)
								if rockets_gv then rockets_gv = math.Round((ammo /65) *rockets_gv) end
							end
							tr.Entity.ammo = tr.Entity.ammo +ammo_gv
						else
							//messy method, needs to be redone
							if ammo >= 65 then
								metal_used = math.Round(((ammo_max -tr.Entity.ammo) /ammo_gv) *65)
								tr.Entity.ammo = ammo_max
							else
								metal_used = math.Round(((ammo_max -tr.Entity.ammo) /ammo_gv) *ammo)
								ammo_gv = math.Round((ammo /65) *(ammo_max -tr.Entity.ammo))
								tr.Entity.ammo = tr.Entity.ammo +ammo_gv
							end
							//
						end
						tr.Entity:SetNetworkedInt( "shells", tr.Entity.ammo )
						local rockets = tr.Entity:GetNetworkedInt( "rockets" )
						if tr.Entity.level == 3 and rockets < 20 then
							if rockets +rockets_gv <= 20 then
								tr.Entity:SetNetworkedInt( "rockets", tr.Entity:GetNetworkedInt( "rockets" ) +rockets_gv )
							else
								tr.Entity:SetNetworkedInt( "rockets", 20 )
							end
						end
					end
					ammo = ammo -metal_used
					if !tr.Entity.level or tr.Entity.level == 3 or ammo <= 0 or (tr.Entity.mapentity and !tr.Entity.upgradeable) then self:TakePrimaryAmmo( metal_used ); return end
					//
					if ammo >= 25 and tr.Entity.metalremain -25 > 0 then
						tr.Entity.metalremain = tr.Entity.metalremain -25
						if tr.Entity.ammo +33 <= 100 then
							tr.Entity.ammo = tr.Entity.ammo +33
						else
							tr.Entity.ammo = 100
						end
						self:TakePrimaryAmmo( 25 )
					elseif ammo < 25 and tr.Entity.metalremain -25 > 0 then
						tr.Entity.metalremain = tr.Entity.metalremain -ammo
						if tr.Entity.ammo +ammo <= 100 then
							tr.Entity.ammo = tr.Entity.ammo +ammo
						else
							tr.Entity.ammo = 100
						end
						self:TakePrimaryAmmo( ammo )
					else
						self:TakePrimaryAmmo( tr.Entity.metalremain )
						tr.Entity:Upgrade()
						if tr.Entity.level != 3 then tr.Entity.metalremain = 200 end
					end
					tr.Entity:SetNetworkedInt("upgrade", tr.Entity.metalremain )
				elseif tr.Entity.settingup then
					self.Owner:EmitSound( "weapons/wrench_hit_build_success" .. math.random(1,2) .. ".wav", 100, 100 )
					if !tr.Entity.speedup then
						tr.Entity:SetPlaybackRate( 1 )
						tr.Entity:SpeedUp()
					end
				else
					self.Owner:EmitSound( "weapons/wrench_hit_build_fail.wav", 100, 100 )
				end
			else
				local targetent
				if tr.Entity:GetClass() == "obj_sapper" then
					targetent = tr.Entity
				else
					targetent = tr.Entity.sapper
				end
				targetent:TakeDamage( sk_wep_tf2_wrench_value, self.Owner, self )
				self.Owner:EmitSound( "weapons/wrench_hit_build_success" .. math.random(1,2) .. ".wav", 100, 100 )
			end
		elseif (tr.Entity and ValidEntity(tr.Entity)) or self:EntsInSphere( tracedata.endpos,12 ) then
			if !crit then
				util.BlastDamage(self, self.Owner, tr.HitPos, 12, math.random(self.MinDamage, self.MaxDamage) )
			else
				if tr.Entity and ValidEntity(tr.Entity) then
					self:CriticalHit(tr.Entity:GetPosCenter())
				else
					for k, v in pairs(ents.FindInSphere( tracedata.endpos,12 )) do
						if ValidEntity(v) then self:CriticalHit(v:GetPosCenter()) end
					end
				end
				util.BlastDamage(self, self.Owner, tr.HitPos, 12, self.CritDamage )
			end
			self.Owner:EmitSound( self.HitFlesh[math.random(1,#self.HitFlesh)], 100, 100 )
		elseif tr.HitWorld then
			local hit_decal = self:GetTextureDecal(tr)
			self.Owner:EmitSound( self.HitWorld[math.random(1,#self.HitWorld)], 100, 100 )
		end
	end
	timer.Simple( 0.3, Attack )
	
	// In singleplayer this function doesn't get called on the client, so we use a networked float
	// to send the last shoot time. In multiplayer this is predicted clientside so we don't need to 
	// send the float.
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
