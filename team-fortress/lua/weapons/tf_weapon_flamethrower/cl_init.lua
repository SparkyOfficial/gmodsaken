
include('shared.lua')


SWEP.PrintName			= "Flamethrower"		// 'Nice' Weapon name (Shown on HUD)	
SWEP.Slot				= 0						// Slot in the weapon selection menu
SWEP.SlotPos			= 12					// Position in the slot
SWEP.DrawCrosshair		= false
SWEP.Crosshair = "sprites/tf_crosshair_01"

SWEP.RenderGroup 		= RENDERGROUP_OPAQUE

killicon.Add("tf_weapon_flamethrower","sprites/bucket_flamethrower_red",Color ( 255, 255, 255, 255 ) )

function SWEP:Initialize()
	local bucket = "red"
	if self.Owner and ValidEntity(self.Owner) and self.Owner:Team() == 1 then bucket = "blue" end
	self.WepSelectIcon		= surface.GetTextureID( "sprites/bucket_flamethrower_" .. bucket )
end


function SWEP:StartParticleEffect(particle)
	local viewmodel = self.Owner:GetViewModel()
	ParticleEffectAttach( particle, PATTACH_POINT_FOLLOW, viewmodel, viewmodel:LookupAttachment("muzzle"))
end

function SWEP:StopParticleEffects()
	//timer.Simple(0.05, function() if self and ValidEntity(self) and ValidEntity(LocalPlayer()) then
	LocalPlayer():GetViewModel():StopParticles()
	//end end)
end
