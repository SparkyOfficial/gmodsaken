function sk_wep_tf2_wrench_dmg( player, command, arguments )
	if player:IsAdmin() then
		for k,v in pairs( arguments ) do
			sk_wep_tf2_wrench_value = v
		end
	end
end 
concommand.Add( "sk_plr_dmg_wrench", sk_wep_tf2_wrench_dmg )

sk_wep_tf2_wrench_value = 20

// SENTRY
function sk_tf2_sentry_lvl1_health( player, command, arguments )
	if player:IsAdmin() then
		for k,v in pairs( arguments ) do
			sk_tf2_sentry_lvl1_health_value = v
		end
	end
end 
concommand.Add( "sk_tf2_sentry_lvl1_health", sk_tf2_sentry_lvl1_health )

sk_tf2_sentry_lvl1_health_value = 150

function sk_tf2_sentry_lvl2_health( player, command, arguments )
	if player:IsAdmin() then
		for k,v in pairs( arguments ) do
			sk_tf2_sentry_lvl2_health_value = v
		end
	end
end 
concommand.Add( "sk_tf2_sentry_lvl2_health", sk_tf2_sentry_lvl2_health )

sk_tf2_sentry_lvl2_health_value = 180

function sk_tf2_sentry_lvl3_health( player, command, arguments )
	if player:IsAdmin() then
		for k,v in pairs( arguments ) do
			sk_tf2_sentry_lvl3_health_value = v
		end
	end
end 
concommand.Add( "sk_tf2_sentry_lvl3_health", sk_tf2_sentry_lvl3_health )

sk_tf2_sentry_lvl3_health_value = 216


// OTHER
function TF_BuildPDA_SelectItem( ply, cmd, args )
	if !ply:HasWeapon("tf_weapon_pda_engineer_build") then return end
	local item = tonumber(args[1])
	//if item == 0 then item = 2 elseif item == 1 then item = 3 elseif item == 2 then item = 4 elseif item == 3 then item = 1 else return end
	ply:SelectWeapon("tf_weapon_pda_engineer_build")
	if (item == 0 and ply:GetNetworkedInt( "ammo_metal" ) < 130) or (item == 1 and ply:GetNetworkedInt( "ammo_metal" ) < 100) or ((item == 3 or item == 4) and ply:GetNetworkedInt( "ammo_metal" ) < 125) then return end
	ply:GetActiveWeapon().targetitem = item
end 
concommand.Add( "build", TF_BuildPDA_SelectItem )