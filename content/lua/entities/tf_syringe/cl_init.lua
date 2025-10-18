include('shared.lua')

language.Add("tf_syringe", "Syringe")
killicon.Add("tf_syringe","sprites/bucket_syrgun_red",Color ( 255, 255, 255, 255 ) )

function ENT:Initialize()
end

function ENT:Draw()
	self.Entity:DrawModel()
end
