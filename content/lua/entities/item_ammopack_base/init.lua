
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include( 'shared.lua' )

ENT.AmmoPercent = 20
ENT.AutomaticFrameAdvance = true 

function ENT:Initialize()
	self:SetMoveType( MOVETYPE_NONE )
	self:SetSolid( SOLID_NONE )
	self:SetModel( self.Model )

	self.initcur = CurTime() +0.1
	
	if !self.team then self.team = 0 end
end

function ENT:Think()
	local sequence = self:LookupSequence("idle")
	self:ResetSequence(sequence) 
	self:NextThink( CurTime() +0.01 )
	for k, v in pairs(ents.FindInSphere(self:GetPos(), 25)) do
		self:PlayerTouch(v)
	end
	return true
end

function ENT:CanPickup(ply)
	if self.team == 0 or self.team == ply:Team() then return true end
	return false
end

function ENT:CheckPrimaryAmmo(ply, weapon)
	local function CheckWeapon(wep)
		if type(wep.Primary) == "table" and wep.Primary.MaxClipSize and ply:GetCustomAmmo( wep.Primary.Ammo ) < wep.Primary.MaxClipSize then return true end
	end
	if !weapon then
		for k, v in pairs(ply:GetWeapons()) do
			if CheckWeapon(v) then return true end
		end
	else
		if CheckWeapon(weapon) then return true end
	end
	return false
end

function ENT:CheckSecondaryAmmo(ply, weapon)
	local function CheckWeapon(wep)
		if type(wep.Secondary) == "table" and wep.Secondary.MaxClipSize and ply:GetCustomAmmo( wep.Secondary.Ammo ) < wep.Secondary.MaxClipSize then return true end
	end
	if !weapon then
		for k, v in pairs(ply:GetWeapons()) do
			if CheckWeapon(v) then return true end
		end
	else
		if CheckWeapon(weapon) then return true end
	end
	return false
end

function ENT:AddAmmo(wep, ammo_max, ammo, ammotype)
	local maxammotoadd = (ammo_max /100) *self.AmmoPercent
	local ammotoadd
	if ammo +maxammotoadd < ammo_max then
		ammotoadd = maxammotoadd
	else
		ammotoadd = ammo_max -ammo
	end
	wep.Owner:SetCustomAmmo( ammotype, wep.Owner:GetCustomAmmo( ammotype ) +ammotoadd );
end

function ENT:PlayerTouch(ent)
	if ent:IsPlayer() and ValidEntity(ent) and ent:Health() > 0 and self:CanPickup(ent) and (self:CheckPrimaryAmmo(ent) or self:CheckSecondaryAmmo(ent)) and !self.pickedup and CurTime() > self.initcur then
		for k, v in pairs(ent:GetWeapons()) do
			if self:CheckPrimaryAmmo(ent, v) then
				self:AddAmmo(v, v.Primary.MaxClipSize, ent:GetCustomAmmo( v.Primary.Ammo ), v.Primary.Ammo)
			end
			if self:CheckSecondaryAmmo(ent, v) then
				self:AddAmmo(v, v.Secondary.MaxClipSize, ent:GetCustomAmmo( v.Secondary.Ammo ), v.Secondary.Ammo)
			end
		end
		
		self:EmitSound( "items/ammo_pickup.wav", 100, 100 )
		self:EmitSound( "items/gunpickup2.wav", 100, 100 )
		self:Remove()
	end
end

function ENT:KeyValue( key, value )
	if !self.output then
		self.output = {}
	end
	
	if key == "TeamNum" then
		self.team = tonumber(value)
	end

	if key == "OnPlayerPickup" then
		if !self.output[key] then self.output[key] = {} end
		table.insert( self.output[key], value )
	end
end

function ENT:OnTakeDamage(dmg)
end

function ENT:OnRemove()
end

