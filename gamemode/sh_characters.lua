--[[
    GModsaken - Characters System
    Copyright (C) 2024 GModsaken Contributors
]]

-- Ensure GM table exists
if not _G.GM then
    _G.GM = {}
end
local GM = _G.GM
_G.GAMEMODE = GM

-- Список персонажей для выживших (Half-Life 2) - РЕБАЛАНС
GM.SurvivorCharacters = {
    {
        id = "gordon",
        name = "Гордон Фримен",
        model = "models/player/gmodsaken/gordon/dr freeman.mdl",
        health = 100,
        armor = 100,
        speed = 1.0,
        description = "Главный герой, физик-теоретик"
    },
    {
        id = "rebel",
        name = "Повстанец",
        model = "models/player/group03/male_07.mdl",
        health = 100,
        armor = 0,
        speed = 1.1,
        description = "Борец за свободу"
    },
    {
        id = "medic",
        name = "Медик",
        model = "models/player/group03m/male_07.mdl",
        health = 100,
        armor = 0,
        speed = 1.0,
        description = "Медицинский работник"
    },
    {
        id = "engineer",
        name = "Инженер",
        model = "models/player/group01/male_05.mdl",
        health = 100,
        armor = 10,
        speed = 1.0,
        description = "Технический специалист"
    },
    {
        id = "guard",
        name = "Охраник",
        model = "models/player/odessa.mdl",
        health = 100,
        armor = 10,
        speed = 1.0,
        description = "Служба безопасности"
    },
    {
        id = "mayor",
        name = "Мэр",
        model = "models/player/breen.mdl",
        health = 80,
        armor = 0,
        speed = 0.8,
        description = "Глава города"
    }
}

-- Список персонажей для убийц
GM.KillerCharacters = {
    {
        id = "butcher",
        name = "Мясной",
        model = "models/zombie/poison.mdl",
        health = 3000,
        armor = 0,
        speed = 0.9,
        damage = 2.0,
        description = "Жестокий мясник"
    }
}

-- Получение персонажа по имени
function GM:GetCharacter(characterName)
    -- Ищем в списке выживших
    for _, char in pairs(GM.SurvivorCharacters) do
        if char.name == characterName or char.id == characterName then
            return char
        end
    end
    
    -- Ищем в списке убийц
    for _, char in pairs(GM.KillerCharacters) do
        if char.name == characterName or char.id == characterName then
            return char
        end
    end
    
    return nil
end

-- Получение всех выживших
function GM:GetSurvivorCharacters()
    return GM.SurvivorCharacters
end

-- Получение всех убийц
function GM:GetKillerCharacters()
    return GM.KillerCharacters
end

-- Применение персонажа к игроку
function GM:ApplyCharacter(ply, characterName)
    if not IsValid(ply) then return false end
    
    local character = self:GetCharacter(characterName)
    if not character then return false end
    
    -- Сохраняем выбор
    ply.SelectedCharacter = characterName
    
    -- Применяем характеристики
    ply:SetMaxHealth(character.health)
    ply:SetHealth(character.health)
    
    -- Применяем броню
    if character.armor then
        ply:SetArmor(character.armor)
    end
    
    -- Применяем скорость
    if character.speed then
        ply:SetWalkSpeed(200 * character.speed)
        ply:SetRunSpeed(400 * character.speed)
    end
    
    -- Устанавливаем модель
    if character.model then
        ply:SetModel(character.model)
    end
    
    -- Оружие выдаем только в начале раунда, а не в лобби
    if self.GameState == "PLAYING" then
        self:GiveCharacterWeapons(ply, characterName)
    end
    
    -- Уведомляем игрока
    ply:ChatPrint("Вы выбрали персонажа: " .. character.name)
    
    return true
end

-- Функция для выдачи оружия персонажа (вызывается только в начале раунда)
function GM:GiveCharacterWeapons(ply, characterName)
    if not IsValid(ply) then return end
    
    local character = self:GetCharacter(characterName)
    if not character then return end
    
    -- Удаляем старое оружие
    ply:StripWeapons()
    
    -- Проверяем команду игрока
    if self:IsKiller(ply) then
        -- Убийца получает только топор
        if characterName == "butcher" then
            ply:Give("weapon_gmodsaken_axe")
        end
    else
        -- Выжившие получают оружие в зависимости от персонажа
        if characterName == "gordon" then
            ply:Give("weapon_gmodsaken_crowbar")
        elseif characterName == "rebel" then
            ply:Give("weapon_gmodsaken_pistol")
        elseif characterName == "medic" then
            ply:Give("weapon_gmodsaken_medkit")
        elseif characterName == "engineer" then
            ply:Give("weapon_gmodsaken_pda")
        elseif characterName == "guard" then
            ply:Give("weapon_gmodsaken_baton")
        elseif characterName == "mayor" then
            ply:Give("weapon_gmodsaken_phone")
        end
        
        -- Даем базовое оружие
        ply:Give("weapon_physcannon")
    end
end

-- Проверка, может ли игрок выбрать персонажа
function GM:CanPlayerSelectCharacter(ply, characterName)
    if not IsValid(ply) then return false end
    
    -- Проверяем, в лобби ли игрок
    if self.GameState ~= "LOBBY" and self.GameState ~= "PREPARING" then
        return false
    end
    
    local character = self:GetCharacter(characterName)
    if not character then return false end
    
    -- В лобби можно менять персонажа сколько угодно раз
    -- Проверяем соответствие роли
    if self:IsKiller(ply) then
        -- Убийца может выбрать только убийцу
        for _, char in pairs(GM.KillerCharacters) do
            if char.name == characterName or char.id == characterName then
                return true
            end
        end
    else
        -- Выживший может выбрать только выжившего
        for _, char in pairs(GM.SurvivorCharacters) do
            if char.name == characterName or char.id == characterName then
                return true
            end
        end
    end
    
    return false
end

-- Получение доступных персонажей для игрока
function GM:GetAvailableCharacters(ply)
    if not IsValid(ply) then return {} end
    
    if self:IsKiller(ply) then
        return self:GetKillerCharacters()
    else
        return self:GetSurvivorCharacters()
    end
end

-- Отладочная функция для проверки персонажей
function GM:DebugCharacters()
    print("=== DEBUG CHARACTERS ===")
    print("Survivor characters:")
    for i, char in pairs(GM.SurvivorCharacters) do
        print("  " .. i .. ": " .. char.name .. " (ID: " .. char.id .. ") - HP: " .. char.health .. " Armor: " .. (char.armor or 0))
    end
    
    print("Killer characters:")
    for i, char in pairs(GM.KillerCharacters) do
        print("  " .. i .. ": " .. char.name .. " (ID: " .. char.id .. ") - HP: " .. char.health .. " Armor: " .. (char.armor or 0))
    end
    print("========================")
end

-- Универсальная функция для обработки урона с учетом брони
function GM:ApplyDamageWithArmor(target, damage, attacker, weapon)
    if not IsValid(target) or not target:IsPlayer() then return damage end
    
    local oldHealth = target:Health()
    local oldArmor = target:Armor()
    local actualDamage = damage
    
    -- Броня уменьшает урон и сама уменьшается
    if oldArmor > 0 then
        local armorAbsorption = math.min(oldArmor, damage * 0.5) -- Броня поглощает 50% урона
        actualDamage = damage - armorAbsorption
        
        -- Уменьшаем броню
        local newArmor = math.max(0, oldArmor - armorAbsorption)
        target:SetArmor(newArmor)
        
        if IsValid(attacker) then
            print("GModsaken: " .. attacker:Nick() .. " нанес " .. damage .. " урона " .. target:Nick() .. " (броня поглотила " .. armorAbsorption .. ", итого: " .. actualDamage .. ", броня: " .. oldArmor .. " -> " .. newArmor .. ")")
        end
    end
    
    -- Применяем итоговый урон
    local newHealth = math.max(0, oldHealth - actualDamage)
    target:SetHealth(newHealth)
    
    -- Уведомляем цель
    local damageText = "Вы получили " .. actualDamage .. " урона!"
    if oldArmor > 0 then
        damageText = damageText .. " (броня поглотила " .. (damage - actualDamage) .. " урона)"
    end
    
    if IsValid(weapon) and weapon.PrintName then
        damageText = damageText .. " от " .. weapon.PrintName
    end
    
    target:ChatPrint(damageText)
    
    return actualDamage
end 