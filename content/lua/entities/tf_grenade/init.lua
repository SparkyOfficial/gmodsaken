
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include( 'shared.lua' )

ENT.model = "models/weapons/w_models/w_grenade_grenadelauncher.mdl"

function ENT:Initialize()
	self:SetModel( self.model )
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_CUSTOM )
	self:SetHealth(1)
	self:PhysicsInit( 6 )
	//self:PhysicsInitSphere( 12 )
	//self:SetCollisionBounds(Vector(-12,-12,-12),Vector(12,12,12)) 
	self:SetMoveCollide( 3 )
	if self.owner.Owner:Team() == 1 then
		self:SetSkin(1)
	end

	local phys = self.Entity:GetPhysicsObject()
	if (phys:IsValid()) then
		phys:Wake()
		phys:SetMass(10)
		//phys:EnableGravity( false )
		//phys:EnableDrag( false )
		local velocity = self:GetForward() *11000
		velocity.z = velocity.z +1100
		phys:ApplyForceCenter( velocity )
		//phys:SetBuoyancyRatio( 0 )
	end
	
	self.ai_sound = ents.Create( "ai_sound" )
	self.ai_sound:SetPos( self:GetPos() )
	self.ai_sound:SetKeyValue( "volume", "80" )
	self.ai_sound:SetKeyValue( "duration", "8" )
	self.ai_sound:SetKeyValue( "soundtype", "8" )
	self.ai_sound:SetParent( self )
	self.ai_sound:Spawn()
	self.ai_sound:Activate()
	self.ai_sound:Fire( "EmitAISound", "", 0 )
	
	timer.Simple(2, function() if self and ValidEntity(self) then self:Explode() end end)
	
	local effect = "red"
	if self.owner.Owner:Team() == 1 then effect = "blue" end
	
	self.particle_timer = ents.Create("info_particle_system")
	self.particle_timer:SetPos(self:GetPos())
	self.particle_timer:SetParent(self)
	self.particle_timer:SetKeyValue("effect_name","pipebomb_timer_" .. effect)
	self.particle_timer:SetKeyValue("start_active", "1")
	self.particle_timer:Spawn()
	self.particle_timer:Activate()
	
	self.particle_trail = ents.Create("info_particle_system")
	self.particle_trail:SetPos(self:GetPos())
	self.particle_trail:SetParent(self)
	self.particle_trail:SetKeyValue("effect_name","pipebombtrail_" .. effect)
	self.particle_trail:SetKeyValue("start_active", "1")
	self.particle_trail:Spawn()
	self.particle_trail:Activate()
	
	if !self.critical then return end
	self.particle_crit = ents.Create("info_particle_system")
	self.particle_crit:SetPos(self:GetPos())
	self.particle_crit:SetParent(self)
	self.particle_crit:SetKeyValue("effect_name","critical_pipe_" .. effect)
	self.particle_crit:SetKeyValue("start_active", "1")
	self.particle_crit:Spawn()
	self.particle_crit:Activate()
end

function ENT:OnRemove()
	self.ai_sound:Remove()
	if self.particle_timer and ValidEntity(self.particle_timer) then self.particle_timer:Remove() end
	if self.particle_trail and ValidEntity(self.particle_trail) then self.particle_trail:Remove() end
	if self.particle_crit and ValidEntity(self.particle_crit) then self.particle_crit:Remove() end
end

function ENT:Think()
end

function ENT:Explode()
	local vPoint = self:GetPos()
	local effectdata = EffectData()
	effectdata:SetStart( vPoint )
	effectdata:SetOrigin( vPoint )
	effectdata:SetScale( 1 )
	self:EmitSound( "weapons/explode" .. math.random(1,3) .. ".wav", 100, 100 )
	local explosion = ents.Create( "info_particle_system" )
	explosion:SetKeyValue( "effect_name", "ExplosionCore_MidAir" )
	explosion:SetPos( self:GetPos()	) 
	explosion:SetAngles( self:GetAngles() )
	explosion:Spawn()
	explosion:Activate() 
	explosion:Fire( "Start", "", 0 )
	explosion:Fire( "Kill", "", 0.1 )
	
	if self.owner and ValidEntity(self.owner) then
		if !self.critical then
			util.BlastDamage( self.owner, self.owner.Owner, self:GetPos(), 180, math.random(self.owner.MinDamage,self.owner.MaxDamage) )
		else
			util.BlastDamage( self.owner, self.owner.Owner, self:GetPos(), 180, self.owner.CritDamage )
		end
	else
		util.BlastDamage( self, self, self:GetPos(), 180, math.random(105,115) )
	end
	
	self:Remove()
end

function ENT:PhysicsCollide( data, physobj )
	//self:CreateDecal(data.HitPos)
	if ValidEntity(data.HitEntity) and (data.HitEntity:IsNPC() or data.HitEntity:IsPlayer()) and data.HitEntity:Health() > 0 then
		self:Explode()
	end
	return true
end

function ENT:CreateDecal(pos)
	local trace_down = util.QuickTrace( pos, Vector(0,0,-60), self )
	local trace_up = util.QuickTrace( pos, Vector(0,0,60), self )
	local trace_left = util.QuickTrace( pos, Vector(0,60,0), self )
	local trace_right = util.QuickTrace( pos, Vector(0,0,-60), self )
	local trace_front = util.QuickTrace( pos, Vector(60,0,0), self )
	local trace_back = util.QuickTrace( pos, Vector(-60,0,0), self )
	local traces = {trace_down,trace_up,trace_left,trace_right,trace_front,trace_back}
	for k, v in pairs(traces) do
		if v.HitWorld then
			local decal = ents.Create( "infodecal" )
			decal:SetPos(v.HitPos)
			decal:SetKeyValue("texture", "decals/TF_scorch1")
			decal:Spawn()
			decal:Activate()
		end
	end
end

