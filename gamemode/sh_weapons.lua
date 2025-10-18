--[[
    GModsaken - Weapons and Abilities System
    Copyright (C) 2024 GModsaken Contributors
]]

local GM = _G.GM or GAMEMODE
_G.GM = GM
_G.GAMEMODE = GM

-- Оружие и способности персонажей
GM.CharacterWeapons = {
    -- УБИЙЦЫ
    ["Мясной"] = {
        weapon = "weapon_gmodsaken_axe", -- Топор
        abilities = {
            ["Заражение"] = "Создает 3 временных хедкраба с задержкой",
            ["Лазер из глаз"] = "Мощный лазер (нельзя двигаться при использовании)"
        }
    },
    
    -- ВЫЖИВШИЕ
    ["Гордон Фримен"] = {
        weapon = "weapon_gmodsaken_crowbar", -- Лом
        abilities = {
            ["Замедление"] = "При ударе замедляет убийцу"
        }
    },
    
    ["Повстанец"] = {
        weapon = "weapon_gmodsaken_pistol", -- Пистолет
        abilities = {
            ["Замедление"] = "Попадание временно замедляет убийцу (не останавливает полностью)"
        }
    },
    
    ["Инженер"] = {
        weapon = "weapon_gmodsaken_pda", -- КПК
        abilities = {
            ["Турель"] = "Может строить турель",
            ["Раздатчик"] = "Может строить раздатчик"
        }
    },
    
    ["Медик"] = {
        weapon = "weapon_gmodsaken_medkit", -- Наша собственная аптечка
        abilities = {
            ["Лечение себя"] = "ЛКМ - Лечит себя на 50 HP",
            ["Лечение тиммейта"] = "ПКМ - Лечит ближайшего тиммейта на 50 HP"
        }
    },
    
    ["Охраник"] = {
        weapon = "weapon_gmodsaken_baton", -- Дубинка
        abilities = {
            ["Ослепление"] = "При ударе по убийце - белый экран на 3 секунды (тратит 35 стамины)"
        }
    },
    
    ["Мэр"] = {
        weapon = "weapon_gmodsaken_phone", -- Телефон
        abilities = {
            ["Радар"] = "Видит тиммейтов на расстоянии",
            ["Аура брони"] = "Пассивно: все рядом получают +1 брони в секунду"
        }
    }
}

-- Получение оружия персонажа
function GM:GetCharacterWeapon(characterName)
    return self.CharacterWeapons[characterName] and self.CharacterWeapons[characterName].weapon
end

-- Получение способностей персонажа
function GM:GetCharacterAbilities(characterName)
    return self.CharacterWeapons[characterName] and self.CharacterWeapons[characterName].abilities
end

-- Выдача оружия игроку
function GM:GiveCharacterWeapon(ply, characterName)
    if not IsValid(ply) then return false end
    
    -- УБИЙЦА НЕ ПОЛУЧАЕТ ОРУЖИЕ ВЫЖИВШИХ!
    if self:IsKiller(ply) then
        print("GModsaken: Убийца " .. ply:Nick() .. " не получает оружие выживших")
        return false
    end
    
    local weaponInfo = self.CharacterWeapons[characterName]
    if not weaponInfo then 
        print("GModsaken: Оружие не найдено для персонажа " .. characterName)
        return false 
    end
    
    -- Убираем старое оружие
    ply:StripWeapons()
    
    -- Выдаем новое оружие
    local weapon = weaponInfo.weapon
    if weapon then
        ply:Give(weapon)
        ply:SelectWeapon(weapon)
        print("GModsaken: Выдано оружие " .. weapon .. " игроку " .. ply:Nick() .. " (команда: " .. ply:Team() .. ")")
    end
    
    -- Даем грави пушку для манипуляций с объектами
    ply:Give("weapon_physcannon")
    
    return true
end

-- Применение способностей персонажа
function GM:ApplyCharacterAbilities(ply, characterName)
    if not IsValid(ply) then return false end
    
    local abilities = self:GetCharacterAbilities(characterName)
    if not abilities then return false end
    
    -- Сохраняем способности игрока
    ply.CharacterAbilities = abilities
    
    -- Уведомляем игрока о способностях
    ply:ChatPrint("=== СПОСОБНОСТИ " .. characterName .. " ===")
    for abilityName, abilityDesc in pairs(abilities) do
        ply:ChatPrint("• " .. abilityName .. ": " .. abilityDesc)
    end
    ply:ChatPrint("========================")
    
    return true
end

-- Проверка способности игрока
function GM:HasAbility(ply, abilityName)
    if not IsValid(ply) or not ply.CharacterAbilities then return false end
    return ply.CharacterAbilities[abilityName] ~= nil
end

-- Использование способности
function GM:UseAbility(ply, abilityName)
    if not self:HasAbility(ply, abilityName) then return false end
    
    -- Здесь будет логика использования способностей
    -- Пока просто уведомляем
    ply:ChatPrint("Использована способность: " .. abilityName)
    
    return true
end

-- Обновляем функцию ApplyCharacter для выдачи оружия
local oldApplyCharacter = GM.ApplyCharacter
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
    
    -- НЕ выдаем оружие здесь - только в начале раунда!
    -- self:GiveCharacterWeapon(ply, characterName)
    
    -- Применяем способности (без оружия)
    self:ApplyCharacterAbilities(ply, characterName)
    
    -- Уведомляем игрока
    ply:ChatPrint("Вы выбрали персонажа: " .. character.name)
    ply:ChatPrint("Оружие будет выдано в начале раунда!")
    
    return true
end

-- Команда для проверки оружия
concommand.Add("gmodsaken_weapon_info", function(ply, cmd, args)
    if not IsValid(ply) then return end
    
    if not GM then
        ply:ChatPrint("GM не инициализирован!")
        return
    end
    
    if not ply.SelectedCharacter then
        ply:ChatPrint("Вы не выбрали персонажа!")
        return
    end
    
    local weapon = GM:GetCharacterWeapon(ply.SelectedCharacter)
    local abilities = GM:GetCharacterAbilities(ply.SelectedCharacter)
    
    ply:ChatPrint("=== ОРУЖИЕ И СПОСОБНОСТИ ===")
    ply:ChatPrint("Персонаж: " .. ply.SelectedCharacter)
    ply:ChatPrint("Оружие: " .. (weapon or "Нет"))
    
    if abilities then
        for abilityName, abilityDesc in pairs(abilities) do
            ply:ChatPrint("• " .. abilityName .. ": " .. abilityDesc)
        end
    end
    ply:ChatPrint("============================")
end)

print("[GModsaken] Weapons and abilities system loaded") 