include('shared.lua')

language.Add("tf_stickybomb", "Stickybomb")
killicon.Add("tf_stickybomb","sprites/bucket_pipelaunch",Color ( 255, 255, 255, 255 ) )

function ENT:Initialize()
end

function ENT:Draw()
	self.Entity:DrawModel()
end
