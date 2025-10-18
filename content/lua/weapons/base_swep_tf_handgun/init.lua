
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include( "shared.lua" )
include( "ai_translations.lua" )

SWEP.Weight				= 5			// Decides whether we should switch from/to this
SWEP.AutoSwitchTo		= true		// Auto switch to if we pick it up
SWEP.AutoSwitchFrom		= true		// Auto switch from if you pick up a better weapon
SWEP.MetalToGive = 100

SWEP.MinDamage = 4
SWEP.MaxDamage = 8
SWEP.CritDamage = 12

SWEP.Swing = {Sound( "" )}
SWEP.HitFlesh = {Sound( "" )}
SWEP.HitWorld = {Sound( "" )}

SWEP.EffectTracerCount = 2

local ActIndex = {}
	ActIndex[ "pistol" ] 		= ACT_HL2MP_IDLE_PISTOL
	ActIndex[ "smg" ] 			= ACT_HL2MP_IDLE_SMG1
	ActIndex[ "grenade" ] 		= ACT_HL2MP_IDLE_GRENADE
	ActIndex[ "ar2" ] 			= ACT_HL2MP_IDLE_AR2
	ActIndex[ "shotgun" ] 		= ACT_HL2MP_IDLE_SHOTGUN
	ActIndex[ "rpg" ]	 		= ACT_HL2MP_IDLE_RPG
	ActIndex[ "physgun" ] 		= ACT_HL2MP_IDLE_PHYSGUN
	ActIndex[ "crossbow" ] 		= ACT_HL2MP_IDLE_CROSSBOW
	ActIndex[ "melee" ] 		= ACT_HL2MP_IDLE_MELEE
	ActIndex[ "slam" ] 			= ACT_HL2MP_IDLE_SLAM
	ActIndex[ "normal" ]		= ACT_HL2MP_IDLE
	
function SWEP:StopReload()
	self.reload_cur_start = nil
	self.startreloaddelay = nil
	self.reloading = false
	self.reloaddelay = nil
end

/*---------------------------------------------------------
	SecondaryAttack
---------------------------------------------------------*/
function SWEP:SecondaryAttack()
end

function SWEP:EjectShell(mdl, forward, right, up, delay)
	timer.Simple(delay, function() if self and ValidEntity(self) and self.Owner and ValidEntity(self.Owner) and self.Owner:GetActiveWeapon() == self then
	local pos = self.Owner:GetShootPos()
	pos = pos + self.Owner:GetForward() * forward
	pos = pos + self.Owner:GetRight() * right
	pos = pos + self.Owner:GetUp() * up

	local shell = ents.Create("tf_shell")
	shell:SetModel(mdl)
	shell:SetPos(pos)
	shell:SetAngles(self.Owner:GetAngles())
	shell:Spawn()
	shell:Activate()
	
	local phys = shell:GetPhysicsObject()
	local velocity = self.Owner:GetRight() *1000 +self.Owner:GetUp() *1500
	phys:ApplyForceCenter( velocity )
	end end)
end

/*---------------------------------------------------------
   Name: SetWeaponHoldType
   Desc: Sets up the translation table, to translate from normal 
			standing idle pose, to holding weapon pose.
---------------------------------------------------------*/
function SWEP:SetWeaponHoldType( t )
	if self then return end
	local index = ActIndex[ t ]
	
	/*if (index == nil) then
		Msg( "SWEP:SetWeaponHoldType - ActIndex[ \""..t.."\" ] isn't set!\n" )
		return
	end*/

	self.ActivityTranslate = {}
	self.ActivityTranslate [ ACT_HL2MP_IDLE ] 					= index
	self.ActivityTranslate [ ACT_HL2MP_WALK ] 					= index+1
	self.ActivityTranslate [ ACT_HL2MP_RUN ] 					= index+2
	self.ActivityTranslate [ ACT_HL2MP_IDLE_CROUCH ] 			= index+3
	self.ActivityTranslate [ ACT_HL2MP_WALK_CROUCH ] 			= index+4
	self.ActivityTranslate [ ACT_HL2MP_GESTURE_RANGE_ATTACK ] 	= index+5
	self.ActivityTranslate [ ACT_HL2MP_GESTURE_RELOAD ] 		= index+6
	self.ActivityTranslate [ ACT_HL2MP_JUMP ] 					= index+7
	self.ActivityTranslate [ ACT_RANGE_ATTACK1 ] 				= index+8
	
	self:SetupWeaponHoldTypeForAI( t )

end

SWEP:SetWeaponHoldType( "melee" )

/*---------------------------------------------------------
   Name: weapon:TranslateActivity( )
   Desc: Translate a player's Activity into a weapon's activity
		 So for example, ACT_HL2MP_RUN becomes ACT_HL2MP_RUN_PISTOL
		 Depending on how you want the player to be holding the weapon
---------------------------------------------------------*/
function SWEP:TranslateActivity( act )

	if ( self.Owner:IsNPC() ) then
		if ( self.ActivityTranslateAI[ act ] ) then
			return self.ActivityTranslateAI[ act ]
		end
		return -1
	end

	if ( self.ActivityTranslate[ act ] != nil ) then
		return self.ActivityTranslate[ act ]
	end
	
	return -1

end

function SWEP:GetTextureDecal(trace)
	local texture
	local impacteffect
	if trace.MatType == 77 then
		texture = "decals/metal/shot" .. math.random(1,5)
		WorldSound( "physics/metal/metal_solid_impact_bullet" .. math.random(1,4) .. ".wav", trace.HitPos )
		impacteffect = "impact_metal"
	elseif trace.MatType == 89 then
		texture = "decals/glass/shot" .. math.random(1,5)
		WorldSound( "physics/glass/glass_impact_bullet" .. math.random(1,4) .. ".wav", trace.HitPos )
		impacteffect = "impact_glass"
	elseif trace.MatType == 87 then
		texture = "decals/wood/shot" .. math.random(1,5)
		WorldSound( "physics/wood/wood_solid_impact_bullet" .. math.random(1,5) .. ".wav", trace.HitPos )
		impacteffect = "impact_wood"
	elseif trace.MatType == 67 then
		texture = "decals/concrete/tf_shot" .. math.random(1,5)
		//impacteffect = "impact_concrete"
		impacteffect = "impact_dirt"
	elseif trace.MatType == 68 then
		texture = "decals/dirtshot" .. math.random(1,4)
		impacteffect = "impact_dirt"
	else
		texture = "decals/concrete/shot" .. math.random(1,4)
		impacteffect = "impact_dirt"
	end
	local decal = ents.Create( "infodecal" )
	decal:SetPos(trace.HitPos)
	decal:SetKeyValue("texture", texture)
	decal:Spawn()
	decal:Activate()
	
	/*local impact = ents.Create( "info_particle_system" )
	impact:SetKeyValue( "effect_name", impacteffect )
	impact:SetKeyValue( "start_active", "1" )
	impact:SetPos( trace.HitPos )
	local angle = trace.HitNormal:Angle()
	angle.p = angle.p +90
	impact:SetAngles( angle )
	impact:Spawn()
	impact:Activate()
	impact:Fire( "Kill", "", 0.3 )*/
end


/*---------------------------------------------------------
   Name: AcceptInput
   Desc: Accepts input, return true to override/accept input
---------------------------------------------------------*/
function SWEP:AcceptInput( name, activator, caller, data )
	return false
end


/*---------------------------------------------------------
   Name: KeyValue
   Desc: Called when a keyvalue is added to us
---------------------------------------------------------*/
function SWEP:KeyValue( key, value )
end

function SWEP:CalculatePrimaryPickUpAmmo( NewOwner )
	if !self.Primary.Limited then return self.Primary.PickUpAmmo end
	local ammo = 0
	for i = 1, self.Primary.PickUpAmmo do
		if NewOwner:GetCustomAmmo( self.Primary.Ammo ) +ammo < self.Primary.MaxClipSize then
			ammo = ammo +1
		end
	end
	return ammo
end

function SWEP:CalculateSecondaryPickUpAmmo( NewOwner )
	if !self.Secondary.Limited then return self.Secondary.PickUpAmmo end
	local ammo = 0
	for i = 1, self.Secondary.PickUpAmmo do
		if NewOwner:GetCustomAmmo( self.Secondary.Ammo ) +ammo < self.Secondary.MaxClipSize then
			ammo = ammo +1
		end
	end
	return ammo
end

/*---------------------------------------------------------
  Name: Equip
  Desc: A player or NPC has picked the weapon up
//-------------------------------------------------------*/
function SWEP:Equip( NewOwner )
	if !NewOwner:GetCustomAmmo( self.Primary.Ammo ) then
		NewOwner:SetCustomAmmo( self.Primary.Ammo, self.Primary.AmmoCount )
	else
		NewOwner:SetCustomAmmo( self.Primary.Ammo, NewOwner:GetCustomAmmo( self.Primary.Ammo ) +self:CalculatePrimaryPickUpAmmo( NewOwner ) )
	end
	
	
	if !NewOwner:GetCustomAmmo( self.Secondary.Ammo ) then
		NewOwner:SetCustomAmmo( self.Secondary.Ammo, self.Secondary.AmmoCount )
	else
		NewOwner:SetCustomAmmo( self.Secondary.Ammo, NewOwner:GetCustomAmmo( self.Secondary.Ammo ) +self:CalculateSecondaryPickUpAmmo( NewOwner ) )
	end
	
	if NewOwner:GetNetworkedInt( "ammo_metal" ) >= 200 then return end
	local metal_new
	if NewOwner:GetNetworkedInt( "ammo_metal" ) +self.MetalToGive <= 200 then
		metal_new = self.MetalToGive
	else
		metal_new = 200 -self.MetalToGive
	end
	
	NewOwner:SetNetworkedInt( "ammo_metal", metal_new )
end 

/*---------------------------------------------------------
   Name: EquipAmmo
   Desc: The player has picked up the weapon and has taken the ammo from it
		The weapon will be removed immidiately after this call.
---------------------------------------------------------*/
function SWEP:EquipAmmo( NewOwner )
	local NewPrimAmmo = self:CalculatePrimaryPickUpAmmo( NewOwner )
	local NewSecAmmo = self:CalculateSecondaryPickUpAmmo( NewOwner )
	NewOwner:EmitSound( "items/ammo_pickup.wav", 100, 100 )
	self:Equip( NewOwner )
	self.Primary.AmmoToGive = nil
	self.Secondary.AmmoToGive = nil
end


/*---------------------------------------------------------
   Name: OnDrop
   Desc: Weapon was dropped
---------------------------------------------------------*/
function SWEP:OnDrop()

end

/*---------------------------------------------------------
   Name: ShouldDropOnDie
   Desc: Should this weapon be dropped when its owner dies?
---------------------------------------------------------*/
function SWEP:ShouldDropOnDie()
	return true
end

function SWEP:StopCritSpray()
	self.critspray = false
end

function SWEP:StartCritSpray(duration)
	self.critspray = true
	timer.Simple(duration, function() if self and ValidEntity(self) and self.Owner and ValidEntity(self.Owner) and self.Owner:GetActiveWeapon() == self then self:StopCritSpray() end end )
end

/*---------------------------------------------------------
   Name: NPCShoot_Secondary
   Desc: NPC tried to fire secondary attack
---------------------------------------------------------*/
function SWEP:NPCShoot_Secondary( ShootPos, ShootDir )
	self:SecondaryAttack()
end

/*---------------------------------------------------------
   Name: NPCShoot_Secondary
   Desc: NPC tried to fire primary attack
---------------------------------------------------------*/
function SWEP:NPCShoot_Primary( ShootPos, ShootDir )
	self:PrimaryAttack()
end

// These tell the NPC how to use the weapon
AccessorFunc( SWEP, "fNPCMinBurst", 		"NPCMinBurst" )
AccessorFunc( SWEP, "fNPCMaxBurst", 		"NPCMaxBurst" )
AccessorFunc( SWEP, "fNPCFireRate", 		"NPCFireRate" )
AccessorFunc( SWEP, "fNPCMinRestTime", 	"NPCMinRest" )
AccessorFunc( SWEP, "fNPCMaxRestTime", 	"NPCMaxRest" )


