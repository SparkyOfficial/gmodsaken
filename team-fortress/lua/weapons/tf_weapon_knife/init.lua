
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include( "shared.lua" )

SWEP.Weight				= 5			// Decides whether we should switch from/to this
SWEP.AutoSwitchTo		= true		// Auto switch to if we pick it up
SWEP.AutoSwitchFrom		= true		// Auto switch from if you pick up a better weapon
SWEP.MetalToGive = 100
SWEP.SequenceDelay = 1.25
SWEP.DrawDelay = 0.6

SWEP.MinDamage = 30
SWEP.MaxDamage = 50
SWEP.CritDamage = 105

SWEP.Swing = Sound( "weapons/knife_swing.wav" )
SWEP.SwingCrit = Sound( "weapons/knife_swing_crit.wav" )
SWEP.HitFlesh = { Sound( "weapons/blade_hit1.wav" ), Sound( "weapons/blade_hit2.wav" ), Sound( "weapons/blade_hit3.wav" ) }
SWEP.HitWorld = { Sound( "weapons/blade_hitworld.wav" ) }

SWEP.Primary.Delay = 0.8

function SWEP:KnifeCritical()
	if GetGlobalBool( "humiliation" ) then return true end
	return false
end

function SWEP:EntsInSphereBack( pos, range )
	local ents = ents.FindInSphere(pos,range)
	for k, v in pairs(ents) do
		if v != self and v != self.Owner and (v:IsNPC() or v:IsPlayer()) and ValidEntity(v) and self:EntityFaceBack(v) then
			return true
		end
	end
	return false
end

function SWEP:EntityFaceBack(ent)
	local angle = self.Owner:GetAngles().y -ent:GetAngles().y
	if angle < -180 then angle = 360 +angle end
	if angle <= 90 and angle >= -90 then return true end
	return false
end

/*---------------------------------------------------------
	PrimaryAttack
---------------------------------------------------------*/
function SWEP:PrimaryAttack()
	if GetGlobalBool( "humiliation" ) and self.Owner:Team() == GetGlobalInt( "team_lost" ) then return end
	self.Weapon:SetNextPrimaryFire( CurTime() + self.Primary.Delay )
	
	local pos = self.Owner:GetShootPos()
	local ang = self.Owner:GetAimVector()
	local tracedata = {}
	tracedata.start = pos
	tracedata.endpos = pos +(self.Owner:GetAimVector( ) *80)
	tracedata.filter = self.Owner
	local tr = util.TraceLine(tracedata)
	local crit = self:KnifeCritical()
	local backstab
	if (tr.Entity and ValidEntity(tr.Entity) and (tr.Entity:IsNPC() or tr.Entity:IsPlayer()) and self:EntityFaceBack(tr.Entity)) or self:EntsInSphereBack( tracedata.endpos,12 ) then
		self.Weapon:SendWeaponAnim( ACT_VM_SWINGHARD )
		backstab = true
	else
		self.Weapon:SendWeaponAnim( ACT_VM_HITCENTER )
	end
	self.Owner:SetAnimation( PLAYER_ATTACK1 )
	self.idledelay = CurTime() +self.SequenceDelay//self:SequenceDuration()
	
	if !crit then
		self.Owner:EmitSound( self.Swing, 100, 100 )
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
			if ((tr.Entity and ValidEntity(tr.Entity) and self:EntityFaceBack(tr.Entity)) or self:EntsInSphereBack( tracedata.endpos,12 )) and backstab then
				if tr.Entity and ValidEntity(tr.Entity) then
					self:CriticalHit(tr.Entity:GetPosCenter())
					tr.Entity:TakeDamage(tr.Entity:Health(),self.Owner,self)
				else
					for k, v in pairs(ents.FindInSphere( tracedata.endpos,12 )) do
						if ValidEntity(v) and v:Health() > 0 and (v:IsNPC() or v:IsPlayer()) then
							self:CriticalHit(v:GetPosCenter())
							v:TakeDamage(v:Health(),self.Owner,self)
						end
					end
				end
			else
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
			end
			self.Owner:EmitSound( self.HitFlesh[math.random(1,#self.HitFlesh)], 100, 100 )
		elseif tr.HitWorld then
			local hit_decal = self:GetTextureDecal(tr)
			self.Owner:EmitSound( self.HitWorld[math.random(1,#self.HitWorld)], 100, 100 )
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
