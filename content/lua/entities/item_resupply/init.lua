
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include( 'shared.lua' )

ENT.model = "models/props_gameplay/resupply_locker.mdl"
ENT.AutomaticFrameAdvance = true 

function ENT:SpawnFunction( ply, tr )
	if ( !tr.Hit or ply.teleport_entrance ) then return end
	local SpawnPos = (tr.HitPos + tr.HitNormal * 16) -Vector( 0, 0, 17 )
	self.Spawn_angles = ply:GetAngles()
	self.Spawn_angles.pitch = 0
	self.Spawn_angles.roll = 0
	self.Spawn_angles.yaw = self.Spawn_angles.yaw + 180
	
	local ent = ents.Create( "item_resupply" )
	ent:SetPos( SpawnPos )
	ent:SetAngles( self.Spawn_angles )
	ent.owner = ply
	ent:Spawn()
	ent:Activate()
	
	return ent
end

function ENT:Initialize()
	self:SetModel( "models/props_junk/watermelon01_chunk02c.mdl" )
	self:SetMoveType( MOVETYPE_NONE )
	self:SetSolid( SOLID_BBOX )
	self:SetCollisionBounds( Vector(20, 28, 0), Vector(-20, -28, 112) )	
	
	self:SetColor( 255, 255, 255, 0 )
	self:DrawShadow( false )
	
	self.resupplysound = CreateSound( self, "items/regenerate.wav" )
	
	self.resupply = ents.Create( "prop_dynamic" )
	self.resupply:SetModel( self.model )
	self.resupply:SetPos( self:GetPos() )
	self.resupply:SetAngles( self:GetAngles() )
	self.resupply:SetParent( self )
	self.resupply:Spawn()
	self.resupply:Activate()
end

function ENT:Think()
	if self.idledelay and CurTime() > self.idledelay then
		self.idledelay = nil
		self.resupplied = false
		self.resupply:ResetSequence( self.resupply:LookupSequence( "idle" ) )
	end
	
	if self.closedelay and CurTime() > self.closedelay then
		self.closedelay = nil
		self.resupply:ResetSequence( self.resupply:LookupSequence( "close" ) )
		self.idledelay = CurTime() +self.resupply:SequenceDuration()
	end
	if self.resupplied then return end
	local resupply = false
	for k, v in pairs( ents.FindInBox( self:LocalToWorld( Vector(20, -28, 0) ), self:LocalToWorld( Vector(55, 28, 112) ) ) ) do
		if ValidEntity(v) and v:IsPlayer() and v:Health() > 0 then
			resupply = true
			v:RefreshAmmo()
			v:SetHealth( v:GetMaxHealth() )
			if v:HasWeapon( "tf_weapon_wrench" ) then
				v:SetNetworkedInt( "ammo_metal", 200 )
			end
		end
	end
	
	if resupply then
		self.resupplied = true
		self.resupplysound:Stop()
		self.resupplysound:Play()
		
		self.resupply:ResetSequence( self.resupply:LookupSequence( "open" ) )
		self.resupply:SetPlaybackRate( 1 )
		self.closedelay = CurTime() +self.resupply:SequenceDuration()
	end
end

function ENT:OnRemove()
	if ValidEntity( self.resupply ) then self.resupply:Remove() end
	self.resupplysound:Stop()
end

