
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include( 'shared.lua' )

ENT.model = "models/weapons/w_models/w_syringe_proj.mdl"

function ENT:Initialize()
	self:SetModel( self.model )
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_CUSTOM )
	self:SetHealth(1)
	self:PhysicsInitSphere( 0.1 )
	//self:SetCollisionBounds(Vector(-1,-1,-1),Vector(1,1,1)) 
	//self:SetCollisionBounds(Vector(-12,-12,-12),Vector(12,12,12)) 
	self:SetMoveCollide( 3 )

	local phys = self.Entity:GetPhysicsObject()
	if (phys:IsValid()) then
		phys:Wake()
		phys:SetMass( 0.1 )
		phys:EnableDrag(false)
		phys:SetBuoyancyRatio( 0.1 )
	end
	
	local effect = "nailtrails_medic_red"
	if self.owner.Owner:Team() == 1 then
		effect = "nailtrails_medic_blue"
		self:SetSkin(1)
	end
	if self.critical then effect = effect .. "_crit" end
	self.particle = ents.Create("info_particle_system")
	self.particle:SetPos(self:GetPos())
	self.particle:SetAngles(self:GetAngles())
	self.particle:SetKeyValue( "effect_name", effect )
	self.particle:SetKeyValue( "start_active", "1" )
	self.particle:SetParent(self)
	self.particle:Spawn()
	self.particle:Activate()
end

function ENT:OnRemove()
	if self.particle and ValidEntity(self.particle) then self.particle:Remove() end
end

function ENT:Think()
end

function ENT:PhysicsCollide( data, physobj )
	if self.HitObject then return end
	if ValidEntity(data.HitEntity) and data.HitEntity:IsNPC() or data.HitEntity:IsPlayer() then
		if ValidEntity(self.owner) then
			local damage = math.random(self.owner.MinDamage, self.owner.MaxDamage)
			if self.critical then damage = self.owner.CritDamage; self.owner:CriticalHit(data.HitEntity:GetPosCenter()) end
			util.BlastDamage(self.owner, self.owner.Owner, data.HitPos, 1, damage )
		else
			local damage = math.random(10,15)
			util.BlastDamage(self, self, data.HitPos, 1, damage )
		end
		self:Remove()
		return true
	end
	if ValidEntity(self.owner) then self.owner:GetTextureDecal(data) end
	self:SetMoveType( MOVETYPE_NONE )
	self:PhysicsInit( SOLID_NONE )
	self:SetMoveCollide(0)
	self.HitObject = true
	self:SetPos(data.HitPos +data.HitNormal /1.2)
	if self.particle and ValidEntity(self.particle) then self.particle:Remove(); self.particle = nil end
	timer.Simple(20, function() if self and ValidEntity(self) then self:Remove() end end)
	return true
end

