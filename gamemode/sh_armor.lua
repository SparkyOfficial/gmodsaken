--[[
    GModsaken - Armor System
    Copyright (C) 2024 GModsaken Contributors
]]

-- Ensure GM table exists
if not _G.GM then
    _G.GM = {}
end
local GM = _G.GM
_G.GAMEMODE = GM

-- Система брони для персонажей
GM.ArmorSystem = {
    -- Базовые значения брони для персонажей
    CharacterArmor = {
        ["gordon"] = 100,      -- Гордон Фримен - полная броня
        ["engineer"] = 10,     -- Инженер - легкая броня
        ["guard"] = 10,        -- Охраник - легкая броня
        ["rebel"] = 0,         -- Повстанец - без брони
        ["medic"] = 0,         -- Медик - без брони
        ["mayor"] = 0,         -- Мэр - без брони
        ["myasnoi"] = 0        -- Мясной - без брони
    },
    
    -- Множители урона для разных уровней брони
    DamageMultipliers = {
        [0] = 1.0,    -- Без брони - полный урон
        [10] = 0.9,   -- Легкая броня - 10% снижение урона
        [50] = 0.7,   -- Средняя броня - 30% снижение урона
        [100] = 0.5   -- Полная броня - 50% снижение урона
    }
}

-- Получение множителя урона на основе брони
function GM:GetDamageMultiplier(armor)
    local multiplier = 1.0
    
    -- Находим подходящий множитель
    for armorLevel, damageMult in pairs(self.ArmorSystem.DamageMultipliers) do
        if armor >= armorLevel then
            multiplier = damageMult
        end
    end
    
    return multiplier
end

-- Применение брони к игроку
function GM:ApplyArmorToPlayer(ply, characterName)
    if not IsValid(ply) then return end
    
    local armorValue = self.ArmorSystem.CharacterArmor[characterName] or 0
    ply:SetArmor(armorValue)
    
    -- Сохраняем информацию о броне
    ply.ArmorLevel = armorValue
    ply.DamageMultiplier = self:GetDamageMultiplier(armorValue)
    
    if SERVER then
        print("[GModsaken] Applied armor " .. armorValue .. " to " .. ply:Nick() .. " (character: " .. characterName .. ")")
    end
end

-- Обработка урона с учетом брони
function GM:ProcessDamageWithArmor(target, damage, attacker, inflictor)
    if not IsValid(target) or not target:IsPlayer() then return damage end
    
    local armor = target:Armor()
    local multiplier = self:GetDamageMultiplier(armor)
    
    -- Применяем множитель урона
    local finalDamage = damage * multiplier
    
    -- Уменьшаем броню при получении урона (если есть)
    if armor > 0 and damage > 0 then
        local armorDamage = math.min(armor, damage * 0.5) -- Броня поглощает 50% урона
        target:SetArmor(armor - armorDamage)
        
        -- Обновляем множитель урона
        target.DamageMultiplier = self:GetDamageMultiplier(target:Armor())
        
        if SERVER then
            print("[GModsaken] " .. target:Nick() .. " took " .. finalDamage .. " damage (armor absorbed " .. armorDamage .. ")")
        end
    end
    
    return finalDamage
end

-- Восстановление брони (для мэра и других способностей)
function GM:RestoreArmor(ply, amount)
    if not IsValid(ply) then return end
    
    local currentArmor = ply:Armor()
    local maxArmor = ply.ArmorLevel or 0
    local newArmor = math.min(currentArmor + amount, maxArmor)
    
    ply:SetArmor(newArmor)
    ply.DamageMultiplier = self:GetDamageMultiplier(newArmor)
    
    if SERVER then
        print("[GModsaken] " .. ply:Nick() .. " armor restored: " .. currentArmor .. " -> " .. newArmor)
    end
end

-- Получение информации о броне для HUD
function GM:GetArmorInfo(ply)
    if not IsValid(ply) then return { armor = 0, maxArmor = 0, multiplier = 1.0 } end
    
    return {
        armor = ply:Armor(),
        maxArmor = ply.ArmorLevel or 0,
        multiplier = ply.DamageMultiplier or 1.0
    }
end

print("[GModsaken] Armor system loaded") 