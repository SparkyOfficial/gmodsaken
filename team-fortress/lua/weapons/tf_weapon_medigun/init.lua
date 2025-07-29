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

/*---------------------------------------------------------
---------------------------------------------------------*/
function SWEP:Initialize()
	if ( SERVER ) then
		self:SetWeaponHoldType( self.HoldType )
		self:SetNPCMinBurst( 30 )
		self:SetNPCMaxBurst( 30 )
		self:SetNPCFireRate( 0.01 )
	end
	
	local healeffect
	if self:GetSkin() == 0 then
		healeffect = "red"
	else
		healeffect = "blue"
	end
	
	self.healparticle = ents.Create( "info_particle_system" )
	self.healparticle:SetKeyValue( "effect_name", "medicgun_beam_" .. healeffect )
	self.healparticle:SetPos( self:GetPos() )
	//self.healparticle:SetParent( self )
	self.healparticle:Spawn()
	self.healparticle:Activate()
	//self.healparticle:Fire( "SetParentAttachment", "muzzle", 0 )
	
	self.chargedparticle = ents.Create( "info_particle_system" )
	self.chargedparticle:SetKeyValue( "effect_name", "medicgun_invulnstatus_fullcharge_" .. healeffect )
	self.chargedparticle:SetPos( self:GetPos() )
	//self.chargedparticle:SetParent( self )
	self.chargedparticle:Spawn()
	self.chargedparticle:Activate()
	//self.chargedparticle:Fire( "SetParentAttachment", "muzzle", 0 )
	
	self.uber = 0
end

function SWEP:StopHealing()
	if self.ubering and self.healtarget and ValidEntity( self.healtarget ) and self.healtarget:Health() > 0 then self.healtarget:GodDisable( ); self.healtarget:ConCommand( "pp_mat_overlay 0" ) end
	self:SetNetworkedBool( "healing", false )
	self.healing = false
	if self.Owner:Team() == 1 then
		self.healtarget:SetSkin(1)
		self:SetSkin(1)
	elseif self.Owner:Team() == 2 then
		self.healtarget:SetSkin(0)
		self:SetSkin(0)
	end
	self.healtarget = NULL
	if self.healsound then self.healsound:Stop() end
	self.healparticle:Fire( "Stop", "", 0 )
end

function SWEP:Heal( target )
	if !self.healsound then self.healsound = CreateSound( self.Owner, "weapons/medigun_heal.wav" ) end
	
	self:SetNetworkedBool( "healing", true )
	self.healing = true
	self.healtarget = target
	
	target:SetName( target:GetName() )
	
	self.healparticle:SetParent( self.Owner:GetViewModel() )
	self.healparticle:Fire( "SetParentAttachment", "muzzle", 0 )
	
	self.healparticle:SetKeyValue( "cpoint1", target:GetName() )
	self.healparticle:Fire( "Start", "", 0 )
	
	self.healsound:Stop()
	self.healsound:Play()
	
	if self.ubering then
		self.healtarget:GodEnable( )
		self.healtarget:ConCommand( "pp_mat_overlay 1" )
		if self.Owner:Team() == 1 then
			self:SetSkin(3)
			self.healtarget:SetSkin(3)
		elseif self.Owner:Team() == 2 then
			self:SetSkin(2)
			self.healtarget:SetSkin(2)
		end
	end
end

function SWEP:Think()
	if self.nextthink and CurTime() < self.nextthink then return end
	if self.healing then
		if !self.Owner:KeyDown( 1 ) then
			self:StopHealing()
			return
		end
		if self.healtarget:Health() < self.healtarget:GetMaxHealth() *1.5 then
			local healpoints
			if !self.healtarget.lastdamaged then self.healtarget.lastdamaged = CurTime() -10 end
			local lastdmg = CurTime() -self.healtarget.lastdamaged
			//self.Owner:PrintMessage( HUD_PRINTTALK, "Player " .. self.healtarget:GetName() .. " was last damaged " .. lastdmg .. " seconds ago!!" )
			if lastdmg < 10 then
				healpoints = 2.4
			elseif lastdmg < 15 then
				healpoints = 4.8
			else
				healpoints = 7.2
			end
			if self.healtarget:Health() +healpoints < self.healtarget:GetMaxHealth() *1.5 then
				self.healtarget:SetHealth( self.healtarget:Health() +healpoints )
			else
				self.healtarget:SetHealth( self.healtarget:GetMaxHealth() *1.5 )
			end
			if self.uber < 100 then self.uber = self.uber +0.25 end
			self.nextthink = CurTime() +0.1
			self.Owner:SetNetworkedInt( "medic_uber", self.uber )
		elseif self.uber < 100 then
			self.uber = self.uber +0.125
			self.nextthink = CurTime() +0.1
			self.Owner:SetNetworkedInt( "medic_uber", self.uber )
		end
		
		self.healtarget:SetNetworkedInt( "health", self.healtarget:Health() )
		self.Owner:SetNetworkedEntity( "healtarget", self.healtarget )
		
		if self:GetPos():Distance(self.healtarget:GetPos()) > 420 then	//or trace?
			self:StopHealing()
		end
	end
	
	if self.uber == 100 and !self.charged and !self.ubering then
		if !self.chargedsound then self.chargedsound = CreateSound( self.Owner, "weapons/medigun_charged.wav" ) end
		self.charged = true
		
		self.chargedparticle:SetParent( self.Owner:GetViewModel() )
		self.chargedparticle:Fire( "SetParentAttachment", "muzzle", 0 )
		self.chargedparticle:Fire( "Start", "", 0 )
		self.chargedsound:Play()
	elseif self.ubering and self.uber > 0 then
		self.uber = self.uber -1.25
		self.nextthink = CurTime() +0.1
		self.Owner:SetNetworkedInt( "medic_uber", self.uber )
	elseif self.ubering and self.uber <= 0 then
		self:StopUber(true)
	end

	if self.idledelay and CurTime() > self.idledelay then
		self.idledelay = nil
		self:SendWeaponAnim( ACT_VM_IDLE )
	end
end

function SWEP:StopPrimaryAttack()
	self:StopUber(false)
	self:StopHealing()
	self:SendWeaponAnim( ACT_VM_IDLE )
end

function SWEP:StopUber(uberoff)
	if uberoff then
		if !self.ubersound_off then self.ubersound_off = CreateSound( self.Owner, "player/invulnerable_off.wav" ) end
		self.ubersound_off:Stop()
		self.ubersound_off:Play()
	end
	if self.chargedsound then self.chargedsound:Stop() end
	if self.ubersound_on then self.ubersound_on:Stop() end
	self.chargedparticle:Fire( "Stop", "", 0 )
	self.ubering = false
	self.uber = 0
	if self.healtarget and ValidEntity( self.healtarget ) and self.healtarget:Health() > 0 then
		self.healtarget:GodDisable( )
		self.healtarget:ConCommand( "pp_mat_overlay 0" )
		if self.Owner:Team() == 1 then
			self.healtarget:SetSkin(1)
		elseif self.Owner:Team() == 2 then
			self.healtarget:SetSkin(0)
		end
	end
	self.Owner:GodDisable( )
	self.Owner:ConCommand( "pp_mat_overlay 0" )
	if self.Owner:Team() == 1 then
		self:SetSkin(1)
	elseif self.Owner:Team() == 2 then
		self:SetSkin(0)
	end
end

/*---------------------------------------------------------
	PrimaryAttack
---------------------------------------------------------*/
function SWEP:PrimaryAttack()
	self.Weapon:SetNextSecondaryFire( CurTime() + self.Primary.Delay )
	self.Weapon:SetNextPrimaryFire( CurTime() + self.Primary.Delay )
	
	self.idledelay = CurTime() +self:SequenceDuration()
	
	if CLIENT or self.healing then return end
	
	local pos = self.Owner:GetShootPos()
	local ang = self.Owner:GetAimVector()
	local tracedata = {}
	tracedata.start = pos
	tracedata.endpos = pos +(self.Owner:GetAimVector( ) *400)
	tracedata.filter = self.Owner
	local tr = util.TraceLine(tracedata)
	if tr.Entity and ValidEntity(tr.Entity) and tr.Entity:IsPlayer() and tr.Entity:Health() > 0 then
		self:Heal( tr.Entity )
		self.Weapon:SendWeaponAnim( ACT_MP_ATTACK_STAND_PREFIRE )
		self.Owner:SetAnimation( PLAYER_ATTACK1 )
		self.Weapon:SendWeaponAnim( ACT_VM_PRIMARYATTACK )
		self.Owner:SetAnimation( PLAYER_ATTACK1 )
	else
		self.Owner:EmitSound( "weapons/medigun_no_target.wav", 100, 100 )
		self.Weapon:SendWeaponAnim( ACT_MP_ATTACK_STAND_POSTFIRE )
		self.Owner:SetAnimation( PLAYER_ATTACK1 )
		timer.Simple( self.Weapon:SequenceDuration(), function() self:PlayIdle() end )
	end
	
	// In singleplayer this function doesn't get called on the client, so we use a networked float
	// to send the last shoot time. In multiplayer this is predicted clientside so we don't need to 
	// send the float.
	if ( (SinglePlayer() && SERVER) || CLIENT ) then
		self.Weapon:SetNetworkedFloat( "LastShootTime", CurTime() )
	end
	
end

SWEP.NextSecondaryAttack = 0
/*---------------------------------------------------------
	SecondaryAttack
---------------------------------------------------------*/
function SWEP:SecondaryAttack()
	self.Weapon:SetNextSecondaryFire( CurTime() + self.Primary.Delay )
	self.Weapon:SetNextPrimaryFire( CurTime() + self.Primary.Delay )

	if !self.charged then return end
	if !self.ubersound_on then self.ubersound_on = CreateSound( self.Owner, "player/invulnerable_on.wav" ) end
	self.charged = false
	self.ubersound_on:Play()
	self.ubering = true
	self.Owner:GodEnable( )
	local team = self.Owner:Team()
	if team == 1 then
		team = "blue"
	else
		team = "red"
	end

	self.Owner:ConCommand( "pp_mat_overlay_texture Effects/invuln_overlay_" .. team )
	if self.healtarget and ValidEntity( self.healtarget ) and self.healtarget:Health() > 0 then
		self.healtarget:ConCommand( "pp_mat_overlay_texture Effects/invuln_overlay_" .. team )
		self.healtarget:GodEnable( )
		self.healtarget:ConCommand( "pp_mat_overlay 1" )
		if self.Owner:Team() == 1 then
			self:SetSkin(3)
			self.healtarget:SetSkin(3)
		elseif self.Owner:Team() == 2 then
			self.healtarget:SetSkin(2)
			self:SetSkin(2)
		end
	end
	self.Owner:ConCommand( "pp_mat_overlay 1" )
	
	if string.find(GAMEMODE.Name, "Fortress" ) then
		self.Owner:AddInvulns(1)
	end
end

function SWEP:OnRemove()
end
