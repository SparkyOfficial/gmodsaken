--[[
    GModsaken - Custom Ammo System
    Copyright (C) 2024 GModsaken Contributors
    
    Custom ammo system for TF2 weapons.
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
            if not self.CustomAmmo then
                self.CustomAmmo = {}
            end
            
            return self.CustomAmmo[name] or 0
        end
        
        -- Set custom ammo
        function meta:SetCustomAmmo(name, num)
            if not self.CustomAmmo then
                self.CustomAmmo = {}
            end
            
            self.CustomAmmo[name] = num or 0
        end
    end
end

print("[GModsaken] Custom ammo system loaded")