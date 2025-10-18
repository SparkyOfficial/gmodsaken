
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

SWEP.MinDamage = 2.5
SWEP.MaxDamage = 3.75
SWEP.CritDamage = 10
SWEP.CritChance = 0.5

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
	
	if self:GetSkin() == 0 then
		self.criteffect = "red"
	else
		self.criteffect = "blue"
	end
end

function SWEP:StartParticleEffect(particle)
	self.activeparticle = particle
	ParticleEffectAttach( particle, PATTACH_POINT_FOLLOW, self.Weapon, 1)
	if SinglePlayer() then self:StopParticles( ) end
	timer.Simple(0.04,function() if self and self.owner and ValidEntity(self.owner) and self.owner:GetActiveWeapon() == self then self:CallOnClient( "StartParticleEffect", particle ) end end)
end

function SWEP:StopParticleEffects()
	self:StopParticles( )
	self.Owner:GetViewModel():StopParticles()
	self:CallOnClient( "StopParticleEffects", "" )
end

/*---------------------------------------------------------
   Think
---------------------------------------------------------*/
function SWEP:Think()
	if self.nextonthink and CurTime() < self.nextonthink then return end
	self.nextonthink = CurTime() +0.1
	if !self.endthink then self.endthink = CurTime() +1; self.thinking = 0 end
	self.thinking = self.thinking +1
	if CurTime() >= self.endthink then
		self.endthink = nil
		self.thinking = 0
	end

	if !self.attacking then return end
	//self:NextThink( CurTime() +0.1 )
	self.Owner:AddCustomAmmo( self.Primary.Ammo, -1.25 )
	local pos = self.Owner:GetShootPos()
	local ang = self.Owner:GetAimVector()
	local tracedata = {}
	tracedata.start = pos
	tracedata.endpos = pos +(self.Owner:GetAimVector( ) *80)
	tracedata.filter = self.Owner
	local tr = util.TraceLine(tracedata)
	
	if !self.Owner:KeyDown( 1 ) or tr.HitWorld or self.Owner:GetCustomAmmo( self.Primary.Ammo ) <= 0 or (GetGlobalBool( "humiliation" ) and self.Owner:Team() == GetGlobalInt( "team_lost" )) then
		self:StopPrimaryAttack()
		return
	end

	if !self.underwater and self.Owner:WaterLevel() == 3 then
		self:StopParticleEffects()
		self:StartParticleEffect("flamethrower_underwater")
		self.underwater = true
		return
	elseif self.underwater and self.Owner:WaterLevel() < 3 then
		self.underwater = false
		self:StopParticleEffects()
		if !self.critspray then self:StartParticleEffect("flamethrower")
		else self:StartParticleEffect("flamethrower_crit_" .. self.criteffect) end
		self.underwater = false
	end
	
	local pos = self.Owner:GetShootPos()
	local ang = self.Owner:GetAimVector()
	local tracedata = {}
	tracedata.start = pos
	tracedata.endpos = pos +(self.Owner:GetAimVector( ) *200)
	tracedata.filter = self.Owner
	local tr = util.TraceLine(tracedata)
	local blastpos = tracedata.endpos
	if tr.Entity and ValidEntity(tr.Entity) then
		blastpos = tr.HitPos
	end
	local crit = self:Critical()
	if crit and !self.critspray then
		self:StartCritSpray(math.random(3,5))
		if self.Owner:WaterLevel() < 3 then
			self:StopParticleEffects()
			self:StartParticleEffect("flamethrower_crit_" .. self.criteffect)
		end
		self.flamesound:Stop()
		self.critflamesound:Play()
	elseif !self.critspray and self.activeparticle != "flamethrower" then
		if self.Owner:WaterLevel() < 3 then
			self:StopParticleEffects()
			self:StartParticleEffect("flamethrower")
		end
		self.critflamesound:Stop()
		self.flamesound:Play()
	end
	if self.critspray then crit = true end
	
	local ents = ents.FindInSphere(blastpos, 45)
	local hit
	for k, v in pairs(ents) do
		if ValidEntity(v) and v != self.Owner then
			local dmg = self:GetDamageFalloff(self.Owner:GetPos():Distance(v:GetPos()),200,self.MaxDamage,self.MinDamage)
			hit = true
			if crit then
				dmg = self.CritDamage
				self:CriticalHit(v:GetPosCenter())
			end
			v:TakeDamage(dmg, self.Owner, self)
			if !v:IsOnFire() and (v:IsNPC() or v:IsPlayer() or ValidEntity(v:GetPhysicsObject())) and ((v:IsPlayer() and v:Team() != self.Owner:Team()) or (!v:IsPlayer() and ((v.team and v.team != self.Owner:Team()) or !v.team))) then v:Ignite(8) end
		end
	end
	if hit then self.flamehitsound:Play() else self.flamehitsound:Stop() end
	/*
	local ents = ents.FindInCone( self.Owner:GetPos(), self.Owner:GetForward(), 200, 12.5 )
	for k, v in pairs(ents) do
		if ValidEntity(v) and v != self.Owner then
			local crit = self:Critical()
			local dmg = (1-(self.Owner:GetPos():Distance(v:GetPos()) /200)) *self.MaxDamage
			if dmg < self.MinDamage then dmg = self.MinDamage end
			if crit then
				dmg = CritDamage
			end
			v:TakeDamage(dmg, self.Owner, self)
			if !v:IsOnFire() and ((v:IsPlayer() and v:Team() != self.Owner:Team()) or ((v.team and v.team != self.Owner:Team()) or !v.team)) then v:Ignite(8) end
		end
	end
	*/
end

function SWEP:StopPrimaryAttack()
	self.attacking = false
	//self.flameparticle:Fire( "Stop", "", 0 )
	//self.flameparticle_uwater:Fire( "Stop", "", 0 )
	//self.flameparticle_crit:Fire( "Stop", "", 0 )
	self:StopParticleEffects()
	if self.flamehitsound then self.flamehitsound:Stop() end
	if self.critflamesound then self.critflamesound:Stop() end
	if self.flamesound then self.flamesound:Stop() end
	if self.flamestartsound then self.flamestartsound:Stop() end
	self:SendWeaponAnim( ACT_VM_IDLE )
	//self.Owner:EmitSound( "weapons/flame_thrower_end.wav", 100, 100 )
end

function SWEP:Draw()
	if !self.pilotsound then self.pilotsound = CreateSound( self.Owner, "weapons/flame_thrower_pilot.wav" ) end
	self.pilotsound:Play()
	self.Weapon:SendWeaponAnim(ACT_VM_DRAW)
	timer.Create( "VM_Idle_anim_timer_2" .. self:EntIndex(), 0.6, 1, function() if self.Owner and (self.Owner:IsNPC() or ( self.Owner:IsPlayer() and self.Owner:GetActiveWeapon( ) == self )) then self:SendWeaponAnim( ACT_VM_IDLE ) end end )
	return true
end

/*---------------------------------------------------------
   Name: SWEP:Holster( weapon_to_swap_to )
   Desc: Weapon wants to holster
   RetV: Return true to allow the weapon to holster
---------------------------------------------------------*/
function SWEP:Holster( wep )
	if self.pilotsound then self.pilotsound:Stop() end
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
	self.idledelay = CurTime() +self:SequenceDuration()
	if self.attacking or self.Owner:GetCustomAmmo( self.Primary.Ammo ) <= 0 then return end
	if !self.flamesound then self.flamesound = CreateSound( self.Owner, "weapons/flame_thrower_loop.wav" ); self.critflamesound = CreateSound( self.Owner, "weapons/flame_thrower_loop_crit.wav" ); self.flamestartsound = CreateSound( self.Owner, "weapons/flame_thrower_start.wav" ); self.flamehitsound = CreateSound( self.Owner, "weapons/flame_thrower_fire_hit.wav" ) end
	local pos = self.Owner:GetShootPos()
	local ang = self.Owner:GetAimVector()
	local tracedata = {}
	tracedata.start = pos
	tracedata.endpos = pos +(self.Owner:GetAimVector( ) *80)
	tracedata.filter = self.Owner
	local tr = util.TraceLine(tracedata)
	if tr.HitWorld then return end
		
	self.critflamesound:Stop()
	self.flamesound:Stop()
	self.flamestartsound:Stop()
	self.flamestartsound:Play()
	self.flamestartsound:FadeOut( 2 )
	if self.Owner:WaterLevel() < 3 then
		if !self.critspray then
			self:StartParticleEffect("flamethrower")
			self.flamesound:Play()
		else
			local criteffect
			if self:GetSkin() == 0 then
				criteffect = "red"
			else
				criteffect = "blue"
			end
			self:StartParticleEffect("flamethrower_crit_" .. self.criteffect)
			self.critflamesound:Play()
		end
	else
		self:StartParticleEffect("flamethrower_underwater")
		self.flamesound:Play()
	end
	self.attacking = true

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
