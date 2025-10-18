include('shared.lua')

language.Add("tf_grenade", "Grenade")
killicon.Add("tf_grenade","sprites/bucket_grenlaunch",Color ( 255, 255, 255, 255 ) )

function ENT:Initialize()
end

function ENT:Draw()
	self.Entity:DrawModel()
end
