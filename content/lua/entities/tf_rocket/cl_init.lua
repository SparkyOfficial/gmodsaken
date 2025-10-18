include('shared.lua')

language.Add("tf_rocket", "Rocket")
killicon.Add("tf_rocket","sprites/bucket_rl",Color ( 255, 255, 255, 255 ) )

function ENT:Initialize()
	ParticleEffectAttach( "rockettrail", PATTACH_ABSORIGIN_FOLLOW, self, self:LookupAttachment("trail") )
	if self.critical then
		local effect
		if self.owner.Owner:Team() == 1 then
			effect = "critical_rocket_blue"
		else
			effect = "critical_rocket_red"
		end
		ParticleEffectAttach( effect, PATTACH_ABSORIGIN_FOLLOW, self, self:LookupAttachment("trail") )
	end
end

function ENT:Draw()
	self.Entity:DrawModel()
end
