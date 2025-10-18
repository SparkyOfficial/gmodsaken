--[[
    GModsaken - TF2 Ammo System
    Copyright (C) 2024 GModsaken Contributors
    
    Consolidated TF2 ammo system for Player, Entity, and Weapon metatables.
    Author: Андрій Будильников
]]

-- Ensure GM table exists
local GM = _G.GM or GAMEMODE
_G.GM = GM
_G.GAMEMODE = GM

-- Custom ammo system for Player, Entity, and Weapon metatables
local metatables = {
    "Player",
    "Entity", 
    "Weapon"
}

-- Add custom ammo functions to all metatables
for _, metatableName in ipairs(metatables) do
    local meta = FindMetaTable(metatableName)
    if meta then
        -- Get custom ammo
        function meta:GetCustomAmmo(name)
            return self:GetNetworkedInt("ammo_" .. name)
        end
        
        -- Set custom ammo
        function meta:SetCustomAmmo(name, num)
            return self:SetNetworkedInt("ammo_" .. name, num or 0)
        end
        
        -- Add custom ammo
        function meta:AddCustomAmmo(name, num)
            return self:SetCustomAmmo(name, self:GetCustomAmmo(name) + (num or 0))
        end
    end
end

-- Weapon-specific ammo functions
local weaponMeta = FindMetaTable("Weapon")
if weaponMeta then
    -- Get primary ammo
    function weaponMeta:GetPrimaryAmmo()
        if not self.Primary or not self.Primary.Ammo then return 0 end
        return self:GetNetworkedInt("ammo_" .. self.Primary.Ammo)
    end
    
    -- Set primary ammo
    function weaponMeta:SetPrimaryAmmo(num)
        if not self.Primary or not self.Primary.Ammo then return end
        return self:SetNetworkedInt("ammo_" .. self.Primary.Ammo, num or 0)
    end
    
    -- Add primary ammo
    function weaponMeta:AddPrimaryAmmo(num)
        if not self.Primary or not self.Primary.Ammo then return end
        return self:SetCustomAmmo(self.Primary.Ammo, self:GetPrimaryAmmo() + (num or 0))
    end
    
    -- Get secondary ammo
    function weaponMeta:GetSecondaryAmmo()
        if not self.Secondary or not self.Secondary.Ammo then return 0 end
        return self:GetNetworkedInt("ammo_" .. self.Secondary.Ammo)
    end
    
    -- Set secondary ammo
    function weaponMeta:SetSecondaryAmmo(num)
        if not self.Secondary or not self.Secondary.Ammo then return end
        return self:SetNetworkedInt("ammo_" .. self.Secondary.Ammo, num or 0)
    end
    
    -- Add secondary ammo
    function weaponMeta:AddSecondaryAmmo(num)
        if not self.Secondary or not self.Secondary.Ammo then return end
        return self:SetCustomAmmo(self.Secondary.Ammo, self:GetSecondaryAmmo() + (num or 0))
    end
end

-- Player-specific functions
local playerMeta = FindMetaTable("Player")
if playerMeta then
    -- Destroy sticky bombs
    function playerMeta:DestroyStickyBombs()
        if not self.stickybombs then return end
        self:SetNetworkedInt("tf_stickies", 0)
        for k, v in pairs(self.stickybombs) do
            if IsValid(v) then
                v:Remove()
            end
        end
        self.stickybombs = {}
    end
end

print("[GModsaken] TF2 ammo system loaded")