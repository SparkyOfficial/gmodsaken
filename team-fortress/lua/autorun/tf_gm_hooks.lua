function GetEntKeyValues( ent, key, value )
	if !ents_kvtable then ents_kvtable = {} end

	if !ents_kvtable["ent_" .. tostring(ent) .. "_kvtable"] then ents_kvtable["ent_" .. tostring(ent) .. "_kvtable"] = {} end//ent_kvtable end
	if !ents_kvtable["ent_" .. tostring(ent) .. "_kvtable"][key] then
		ents_kvtable["ent_" .. tostring(ent) .. "_kvtable"][key] = value
	else
		if type(ents_kvtable["ent_" .. tostring(ent) .. "_kvtable"][key]) != "table" then
			local f_out = ents_kvtable["ent_" .. tostring(ent) .. "_kvtable"][key]
			ents_kvtable["ent_" .. tostring(ent) .. "_kvtable"][key] = { f_out }
		end
		table.insert( ents_kvtable["ent_" .. tostring(ent) .. "_kvtable"][key], value )
	end
end
hook.Add( "EntityKeyValue", "GetKeyVal", GetEntKeyValues ); 

function LastDamaged( victim )
	victim.lastdamaged = CurTime()
end
hook.Add("PlayerHurt", "LastDamaged", LastDamaged)

function ResetInfo( Player )
	Player.lastdamaged = 0
	Player:SetNetworkedInt( 14, 0 )
end
hook.Add("PlayerSpawn", "TF2_ResetInfo", ResetInfo)

function TF_SentryKillNPC(victim,attacker,weapon)
	local class = weapon:GetClass()
	if !weapon or (class != "obj_sentrygun" and class != "sentry_rocket") then return end
	if class == "sentry_rocket" then
		if !weapon.owner or !ValidEntity(weapon.owner) then return end
		weapon = weapon.owner
	end
	weapon:SetNetworkedInt("kills", weapon:GetNetworkedInt("kills") +1)
end

function TF_SentryKillPlayer(victim,weapon,attacker)
	local class = weapon:GetClass()
	if !attacker:IsPlayer() or !weapon or (class != "obj_sentrygun" and class != "sentry_rocket") or attacker:Team() == victim:Team() then return end
	if class == "sentry_rocket" then
		if !weapon.owner or !ValidEntity(weapon.owner) then return end
		weapon = weapon.owner
	end
	weapon:SetNetworkedInt("kills", weapon:GetNetworkedInt("kills") +1)
end
hook.Add( "PlayerDeath", "SentryKilledPlayer", TF_SentryKillPlayer )
hook.Add( "OnNPCKilled", "SentryKilledNPC", TF_SentryKillNPC )

local meta = FindMetaTable( "Entity" );
if( !meta ) then

	return;

end

function meta:GetPosCenter( )
	local pos = self:OBBCenter()
	local ang = self:GetAngles()
	local pos_center = self:GetPos() + ang:Up() * pos.z + ang:Forward() * pos.x + ang:Right() * pos.y
	return pos_center
end

function meta:FireOutput( output_name )
	if !self.output[output_name] then return end
	for k, v in pairs( self.output[output_name] ) do
		local output_exp = string.Explode( ",", v )
		local output_ents = ents.FindByName( output_exp[1] )
		local output = output_exp[2]
		local output_params = output_exp[3]
		local output_delay = output_exp[4]
		local output_once = output_exp[5]
		for k, v in pairs( output_ents ) do
			v:Fire( output, output_params, tonumber(output_delay) )
			//Msg( "Fired output to " .. v:GetName() .. ": Output: " .. output .. "; params: " .. output_params .. "; delay: " .. output_delay .. "\n" )
		end
		if output_once == "-1" then
			self.newoutputs = {}
			for k, v in pairs( self.output ) do
				if v != output_exp[1] then
					self.newoutputs[k] = v
				end
			end
			self.output = self.newoutputs
			self.newoutputs = nil
		end
	end
end

local meta = FindMetaTable( "Player" );
if( !meta ) then
	return;
end

/*------------------------------------
   SetCritChance
------------------------------------*/
function meta:SetCritChance(value)
	self:SetNetworkedInt("CritChance", value)
end

/*------------------------------------
   AddCritChance
------------------------------------*/
function meta:AddCritChance(value)
	self:SetNetworkedInt("CritChance", self:GetCritChance() +value)
end

/*------------------------------------
   GetCritChance
------------------------------------*/
function meta:GetCritChance()
	return self:GetNetworkedInt("CritChance")
end

/*------------------------------------
   RefreshAmmo
------------------------------------*/
function meta:RefreshAmmo()
	for k, v in pairs(self:GetWeapons()) do
		if type(v.Primary) == "table" and v.Primary.MaxClipSize then
			self:SetCustomAmmo( v.Primary.Ammo, v.Primary.MaxClipSize )
		end
		if type(v.Secondary) == "table" and v.Secondary.MaxClipSize then
			self:SetCustomAmmo( v.Secondary.Ammo, v.Secondary.MaxClipSize )
		end
	end
end

local meta = FindMetaTable( "Weapon" );
if( !meta ) then
	return;
end

/*------------------------------------
   GetWeaponType
------------------------------------*/
function meta:GetWeaponType()
	local weapons_melee = { "tf_weapon_bat", "tf_weapon_shovel", "tf_weapon_fireaxe", "tf_weapon_bottle", "tf_weapon_fists", "tf_weapon_wrench", "tf_weapon_bonesaw", "tf_weapon_club", "tf_weapon_knife" }
	local weapons_primary = { "tf_weapon_scattergun", "tf_weapon_rocketlauncher", "tf_weapon_flamethrower", "tf_weapon_grenadelauncher", "tf_weapon_minigun", "tf_weapon_shotgun_primary", "tf_weapon_syringegun_medic", "tf_weapon_sniperrifle", "tf_weapon_revolver" }
	if table.HasValue( weapons_melee, self:GetClass() ) then return "MELEE"
	elseif table.HasValue( weapons_primary, self:GetClass() ) then return "PRIMARY"
	else return "SECONDARY" end
end

/*------------------------------------
   Critical
------------------------------------*/
function meta:Critical()
	if GetGlobalBool( "humiliation" ) then return true end
	local critchance_wep = self.CritChance
	local critchance = self.Owner:GetCritChance() +critchance_wep
	if critchance <= 0 then return false end
	local rand = math.random(1,100 /critchance)
	if rand == 100 /critchance then return true end
	return false
end

/*------------------------------------
   CriticalHit
------------------------------------*/
function meta:CriticalHit(pos)
	local critsound = "player/crit_hit" .. math.random(1,5) .. ".wav"
	if string.find(critsound, "1") then critsound = "player/crit_hit.wav" end
	WorldSound( critsound, pos, 115 )
	ParticleEffect( "crit_text", pos, Angle(0,0,0) )
end

/*------------------------------------
   GetDamageFalloff
------------------------------------*/
function meta:GetDamageFalloff(dist,maxdist,maxdmg,mindmg)
	local dmg = (1-(dist /maxdist)) *maxdmg
	if !mindmg or dmg >= mindmg then return dmg end
	if dmg < mindmg then return mindmg end
end
