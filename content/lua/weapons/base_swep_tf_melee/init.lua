
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

SWEP.Primary.Delay = 0.8

SWEP.CritChance = 10

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
	
/*---------------------------------------------------------
---------------------------------------------------------*/
function SWEP:Initialize()

	if ( SERVER ) then
		self:SetWeaponHoldType( self.HoldType )
		self:SetNPCMinBurst( 30 )
		self:SetNPCMaxBurst( 30 )
		self:SetNPCFireRate( 0.01 )
	end
end

/*---------------------------------------------------------
   Name: SetWeaponHoldType
   Desc: Sets up the translation table, to translate from normal 
			standing idle pose, to holding weapon pose.
---------------------------------------------------------*/
function SWEP:SetWeaponHoldType( t )
	if self then return end
	local index = ActIndex[ t ]
	
	//if (index == nil) then
	//	Msg( "SWEP:SetWeaponHoldType - ActIndex[ \""..t.."\" ] isn't set!\n" )
	//	return
	//end

	self.ActivityTranslate = {}
	self.ActivityTranslate [ ACT_HL2MP_IDLE ] 					= ACT_MP_STAND_MELEE
	self.ActivityTranslate [ ACT_HL2MP_WALK ] 					= ACT_MP_RUN_MELEE
	self.ActivityTranslate [ ACT_HL2MP_RUN ] 					= ACT_MP_RUN_MELEE
	self.ActivityTranslate [ ACT_HL2MP_IDLE_CROUCH ] 			= ACT_MP_CROUCH_MELEE
	self.ActivityTranslate [ ACT_HL2MP_WALK_CROUCH ] 			= ACT_MP_CROUCHWALK_MELEE
	self.ActivityTranslate [ ACT_HL2MP_GESTURE_RANGE_ATTACK ] 	= ACT_MP_ATTACK_STAND_PRIMARY
	self.ActivityTranslate [ ACT_HL2MP_GESTURE_RELOAD ] 		= ACT_MP_RELOAD_STAND_PRIMARY
	self.ActivityTranslate [ ACT_HL2MP_JUMP ] 					= ACT_MP_JUMP_FLOAT_melee
	self.ActivityTranslate [ ACT_RANGE_ATTACK1 ] 				= ACT_MP_ATTACK_STAND_MELEE
	
	self:SetupWeaponHoldTypeForAI( t )

end

SWEP:SetWeaponHoldType( "melee" )

function SWEP:Think()
	if self.idledelay and CurTime() > self.idledelay then
		self.idledelay = nil
		self:SendWeaponAnim( ACT_VM_IDLE )
	end
end

/*---------------------------------------------------------
	PrimaryAttack
---------------------------------------------------------*/
function SWEP:PrimaryAttack()
	if GetGlobalBool( "humiliation" ) and self.Owner:Team() == GetGlobalInt( "team_lost" ) then return end
	self.Weapon:SetNextPrimaryFire( CurTime() + self.Primary.Delay )
	
	local crit = self:Critical()
	if !crit then
		self.Weapon:SendWeaponAnim( ACT_VM_HITCENTER )
	else
		self.Weapon:SendWeaponAnim( ACT_VM_SWINGHARD )
	end
	self.Owner:SetAnimation( PLAYER_ATTACK1 )
	self.idledelay = CurTime() +self.SequenceDelay//self:SequenceDuration()
	
	if !crit then
		self.Owner:EmitSound( self.Swing, 100, 100 )
	else
		self.Owner:EmitSound( self.SwingCrit, 100, 100 )
	end
	
	local function Attack()
		if !self:CheckState() then return end
		local pos = self.Owner:GetShootPos()
		local ang = self.Owner:GetAimVector()
		local tracedata = {}
		tracedata.start = pos
		tracedata.endpos = pos +(self.Owner:GetAimVector( ) *80)
		tracedata.filter = self.Owner
		local tr = util.TraceLine(tracedata)
		if (tr.Entity and ValidEntity(tr.Entity)) or self:EntsInSphere( tracedata.endpos,12 ) then
			if !crit then
				util.BlastDamage(self, self.Owner, tr.HitPos, 12, math.random(self.MinDamage, self.MaxDamage) )
			else
				if tr.Entity and ValidEntity(tr.Entity) then
					self:CriticalHit(tr.Entity:GetPosCenter())
				else
					for k, v in pairs(ents.FindInSphere( tracedata.endpos,12 )) do
						if ValidEntity(v) then self:CriticalHit(v:GetPosCenter()) end
					end
				end
				util.BlastDamage(self, self.Owner, tr.HitPos, 12, self.CritDamage )
				if self:GetClass() == "tf_weapon_bottle" and !self.broken then
					self.Owner:GetViewModel():Fire( "SetBodyGroup", "1", 0 )
					self.broken = true
					self.Owner:EmitSound( "weapons/bottle_break.wav", 100, 100 )
				end
			end
			if self:GetClass() != "tf_weapon_bottle" then
				self.Owner:EmitSound( self.HitFlesh[math.random(1,#self.HitFlesh)], 100, 100 )
			else
				if !self.broken then
					self.Owner:EmitSound( self.HitFleshIntact[math.random(1,#self.HitFleshIntact)], 100, 100 )
				else
					self.Owner:EmitSound( self.HitFleshBroken[math.random(1,#self.HitFleshBroken)], 100, 100 )
				end
			end
		elseif tr.HitWorld then
			local hit_decal = self:GetTextureDecal(tr)
			if self:GetClass() != "tf_weapon_bottle" then
				self.Owner:EmitSound( self.HitWorld[math.random(1,#self.HitWorld)], 100, 100 )
			else
				if !self.broken then
					self.Owner:EmitSound( self.HitWorldIntact[math.random(1,#self.HitWorldIntact)], 100, 100 )
					if crit then
						self.Owner:GetViewModel():Fire( "SetBodyGroup", "1", 0 )
						self.broken = true
						self.Owner:EmitSound( "weapons/bottle_break.wav", 100, 100 )
					end
				else
					self.Owner:EmitSound( self.HitWorldBroken[math.random(1,#self.HitWorldBroken)], 100, 100 )
				end
			end
		end
		
		// In singleplayer this function doesn't get called on the client, so we use a networked float
		// to send the last shoot time. In multiplayer this is predicted clientside so we don't need to 
		// send the float.
		if ( (SinglePlayer() && SERVER) || CLIENT ) then
			self.Weapon:SetNetworkedFloat( "LastShootTime", CurTime() )
		end
	end
	
	timer.Simple( 0.3, Attack )
end

function lolwut(player, command, args)
	attachmentlol = args[1]
end
concommand.Add("setattachment",lolwut) 

function SWEP:Draw()
	if self.CModel then
		self.cwep = ents.Create("prop_dynamic")
		self.cwep:SetModel(self.CModel)
		self.cwep:SetParent(self.Owner:GetViewModel())
		self.cwep:Spawn()
		self.cwep:Activate()
		self.cwep:Fire("SetParentAttachment", attachmentlol, 0)
	end
	self.Weapon:SendWeaponAnim(ACT_VM_DRAW)
	timer.Create( "VM_Idle_anim_timer_2" .. self:EntIndex(), self.DrawDelay, 1, function() if self and ValidEntity(self) and self:CheckState() then self:SendWeaponAnim( ACT_VM_IDLE ) end end )
	return true
end


function SWEP:EntsInSphere( pos, range )
	local ents = ents.FindInSphere(pos,range)
	for k, v in pairs(ents) do
		if v != self and v != self.Owner and (v:IsNPC() or v:IsPlayer() or ValidEntity(v:GetPhysicsObject())) and ValidEntity(v) then
			return true
		end
	end
	return false
end

SWEP.NextSecondaryAttack = 0
/*---------------------------------------------------------
	SecondaryAttack
---------------------------------------------------------*/
function SWEP:SecondaryAttack()
end

// Default hold pos is the pistol

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
	if trace.MatType == 77 then
		texture = "decals/metal/shot" .. math.random(1,5)
		WorldSound( "physics/metal/metal_solid_impact_bullet" .. math.random(1,4) .. ".wav", trace.HitPos )
	elseif trace.MatType == 89 then
		texture = "decals/glass/shot" .. math.random(1,5)
		WorldSound( "physics/glass/glass_impact_bullet" .. math.random(1,4) .. ".wav", trace.HitPos )
	elseif trace.MatType == 87 then
		texture = "decals/wood/shot" .. math.random(1,5)
		WorldSound( "physics/wood/wood_solid_impact_bullet" .. math.random(1,5) .. ".wav", trace.HitPos )
	elseif trace.MatType == 67 then
		texture = "decals/concrete/tf_shot" .. math.random(1,5)
	elseif trace.MatType == 68 then
		texture = "decals/dirtshot" .. math.random(1,4)
	else
		texture = "decals/concrete/shot" .. math.random(1,4)
	end
	local decal = ents.Create( "infodecal" )
	decal:SetPos(trace.HitPos)
	decal:SetKeyValue("texture", texture)
	decal:Spawn()
	decal:Activate()
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
	if NewOwner:GetNetworkedInt( "ammo_metal" ) >= 200 then return end
	local metal_new
	if NewOwner:GetNetworkedInt( "ammo_metal" ) +self.MetalToGive <= 200 then
		metal_new = self.MetalToGive
	else
		metal_new = NewOwner:GetNetworkedInt( "ammo_metal" ) +(NewOwner:GetNetworkedInt( "ammo_metal" ) -(200 -self.MetalToGive))
	end
	
	NewOwner:SetNetworkedInt( "ammo_metal", metal_new )
end 

/*---------------------------------------------------------
   Name: EquipAmmo
   Desc: The player has picked up the weapon and has taken the ammo from it
		The weapon will be removed immidiately after this call.
---------------------------------------------------------*/
function SWEP:EquipAmmo( NewOwner )
	NewOwner:EmitSound( "items/ammo_pickup.wav", 100, 100 )
	self:Equip( NewOwner )
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


