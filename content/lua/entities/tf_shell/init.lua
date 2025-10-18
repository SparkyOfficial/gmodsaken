
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include( 'shared.lua' )

function ENT:Initialize()
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_CUSTOM )
	self:SetHealth(1)
	self:PhysicsInit( 6 )
	self:SetMoveCollide( 3 )
	self:SetCollisionGroup(11)

	local phys = self.Entity:GetPhysicsObject()
	if (phys:IsValid()) then
		phys:Wake()
		phys:SetMass(10)
	end

	timer.Simple(8, function() if self and ValidEntity(self) then self:Remove() end end)
end

function ENT:OnRemove()
end

function ENT:Think()
end
