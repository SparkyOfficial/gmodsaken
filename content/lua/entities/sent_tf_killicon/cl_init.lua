include('shared.lua')

language.Add("sent_tf_killicon_sentry", "Sentry")

killicon.Add( "sent_tf_killicon_sentry", "vgui/killicons/obj_sentrygun",Color ( 255, 255, 255, 255 ) )

function ENT:Draw()
	self.Entity:DrawModel()
end 
