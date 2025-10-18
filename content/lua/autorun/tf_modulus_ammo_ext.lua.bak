//---------- Client Files
if( SERVER ) then

	// include
	AddCSLuaFile( "tf_modulus_ammo_ext.lua" );

end

//---------- Ammo Extension
local meta = FindMetaTable( "Entity" );
if( !meta ) then

	return;

end

/*------------------------------------
   GetCustomAmmo
------------------------------------*/
function meta:GetCustomAmmo( name )
	return self:GetNetworkedInt( "ammo_" .. name );

end

/*------------------------------------
    SetCustomAmmo
------------------------------------*/
function meta:SetCustomAmmo( name, num )
	return self:SetNetworkedInt( "ammo_" .. name, num );
end

/*------------------------------------
    AddCustomAmmo
------------------------------------*/
function meta:AddCustomAmmo( name, num )

	return self:SetCustomAmmo( name, self:GetCustomAmmo( name ) + num );

end



//---------- Ammo Extension
local meta = FindMetaTable( "Weapon" );
if( !meta ) then
	return;
end

/*------------------------------------
   GetPrimaryAmmo
------------------------------------*/
function meta:GetPrimaryAmmo( )
	return self:GetNetworkedInt( "ammo_" .. self.Primary.Ammo );

end

/*------------------------------------
    SetPrimaryAmmo
------------------------------------*/
function meta:SetPrimaryAmmo( num )
	return self:SetNetworkedInt( "ammo_" .. self.Primary.Ammo, num );

end

/*------------------------------------
    AddPrimaryAmmo
------------------------------------*/
function meta:AddPrimaryAmmo( num )
	return self:SetCustomAmmo( self.Primary.Ammo, self:GetPrimaryAmmo( self.Primary.Ammo ) + num );
end

/*------------------------------------
   GetSecondaryAmmo
------------------------------------*/
function meta:GetSecondaryAmmo( )
	return self:GetNetworkedInt( "ammo_" .. self.Secondary.Ammo );
end

/*------------------------------------
    SetSecondaryAmmo
------------------------------------*/
function meta:SetSecondaryAmmo( num )
	return self:SetNetworkedInt( "ammo_" .. self.Secondary.Ammo, num );
end

/*------------------------------------
    AddSecondaryAmmo
------------------------------------*/
function meta:AddSecondaryAmmo( num )
	return self:SetCustomAmmo( self.Secondary.Ammo, self:GetSecondaryAmmo( self.Secondary.Ammo ) + num );
end


//---------- Ammo Extension
local meta = FindMetaTable( "Player" );
if( !meta ) then
	return;
end

/*------------------------------------
   GetCustomAmmo
------------------------------------*/
function meta:GetCustomAmmo( name )
	return self:GetNetworkedInt( "ammo_" .. name );
end

/*------------------------------------
    SetCustomAmmo
------------------------------------*/
function meta:SetCustomAmmo( name, num )
	return self:SetNetworkedInt( "ammo_" .. name, num );
end

/*------------------------------------
    AddCustomAmmo
------------------------------------*/
function meta:AddCustomAmmo( name, num )
	return self:SetCustomAmmo( name, self:GetCustomAmmo( name ) + num );
end

/*------------------------------------
    DestroyStickyBombs
------------------------------------*/
function meta:DestroyStickyBombs()
	if !self.stickybombs then return end
	self:SetNetworkedInt("tf_stickies", 0)
	for k, v in pairs(self.stickybombs) do
		v:Remove()
	end
	self.stickybombs = {}
end
