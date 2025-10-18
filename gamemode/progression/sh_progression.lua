--[[
    GModsaken - Progression System (Shared)
    Copyright (C) 2024 GModsaken Contributors
]]

-- Ensure GM table exists
if not _G.GM then
    _G.GM = {}
end
local GM = _G.GM
_G.GAMEMODE = GM

-- Прогрессия игроков
GM.PlayerProgression = GM.PlayerProgression or {}

-- Уровни и XP
GM.XPRequirements = {
    [1] = 0,
    [2] = 100,
    [3] = 300,
    [4] = 600,
    [5] = 1000,
    [6] = 1500,
    [7] = 2100,
    [8] = 2800,
    [9] = 3600,
    [10] = 4500
}

-- Добавляем больше уровней при необходимости
for i = 11, 50 do
    GM.XPRequirements[i] = GM.XPRequirements[i-1] + (i * 100)
end

-- Перки
GM.Perks = {
    -- Перки для выживших
    survivor = {
        {
            id = "speed_boost",
            name = "Повышенная скорость",
            description = "Бегаете на 5% быстрее",
            levelRequired = 3,
            type = "passive",
            effect = "speed",
            value = 1.05
        },
        {
            id = "repair_speed",
            name = "Быстрый ремонт",
            description = "Чините на 10% быстрее",
            levelRequired = 5,
            type = "passive",
            effect = "repair",
            value = 1.10
        },
        {
            id = "health_boost",
            name = "Укрепленное здоровье",
            description = "На 10% больше здоровья",
            levelRequired = 7,
            type = "passive",
            effect = "health",
            value = 1.10
        }
    },
    
    -- Перки для убийц
    killer = {
        {
            id = "lunge_cooldown",
            name = "Быстрый рывок",
            description = "Рывок перезаряжается на 20% быстрее",
            levelRequired = 3,
            type = "passive",
            effect = "lunge_cooldown",
            value = 0.80
        },
        {
            id = "infection_cooldown",
            name = "Быстрое заражение",
            description = "Заражение перезаряжается на 15% быстрее",
            levelRequired = 5,
            type = "passive",
            effect = "infection_cooldown",
            value = 0.85
        },
        {
            id = "laser_damage",
            name = "Мощный лазер",
            description = "Лазер наносит на 25% больше урона",
            levelRequired = 7,
            type = "passive",
            effect = "laser_damage",
            value = 1.25
        }
    }
}

-- Косметические предметы
GM.Cosmetics = {
    -- Косметика для выживших
    survivor = {
        {
            id = "gordon_skin1",
            name = "Альтернативный Гордон",
            description = "Альтернативная текстура для Гордона Фримена",
            type = "character",
            character = "gordon",
            model = "models/player/gmodsaken/gordon/bms/gordon_survivor_player_alt.mdl",
            levelRequired = 2
        },
        {
            id = "rebel_skin1",
            name = "Камуфляжный повстанец",
            description = "Камуфляжная форма для повстанца",
            type = "character",
            character = "rebel",
            model = "models/player/group03/male_07_camouflage.mdl",
            levelRequired = 4
        }
    },
    
    -- Косметика для убийц
    killer = {
        {
            id = "butcher_skin1",
            name = "Кровавый Мясной",
            description = "Кровавая текстура для Мясного",
            type = "character",
            character = "butcher",
            model = "models/zombie/poison_bloody.mdl",
            levelRequired = 2
        }
    }
}

-- Функция для получения прогрессии игрока
function GM:GetPlayerProgression(ply)
    if not IsValid(ply) then return nil end
    
    local steamID = ply:SteamID()
    if not GM.PlayerProgression[steamID] then
        GM.PlayerProgression[steamID] = {
            xp = 0,
            level = 1,
            perks = {},
            cosmetics = {},
            unlockedPerks = {},
            unlockedCosmetics = {}
        }
    end
    
    return GM.PlayerProgression[steamID]
end

-- Функция для добавления XP
function GM:AddPlayerXP(ply, amount)
    if not IsValid(ply) or amount <= 0 then return end
    
    local progression = self:GetPlayerProgression(ply)
    if not progression then return end
    
    progression.xp = progression.xp + amount
    
    -- Проверяем повышение уровня
    local oldLevel = progression.level
    local newLevel = self:CalculatePlayerLevel(progression.xp)
    
    if newLevel > oldLevel then
        progression.level = newLevel
        self:OnPlayerLevelUp(ply, oldLevel, newLevel)
    end
    
    -- Сохраняем изменения (в реальной реализации нужно сохранять в файл или базу данных)
    if SERVER then
        self:SavePlayerProgression(ply)
    end
end

-- Функция для расчета уровня на основе XP
function GM:CalculatePlayerLevel(xp)
    local level = 1
    
    for i = 1, #GM.XPRequirements do
        if xp >= GM.XPRequirements[i] then
            level = i
        else
            break
        end
    end
    
    return level
end

-- Функция, вызываемая при повышении уровня
function GM:OnPlayerLevelUp(ply, oldLevel, newLevel)
    if not IsValid(ply) then return end
    
    ply:ChatPrint("Поздравляем! Вы достигли уровня " .. newLevel .. "!")
    
    -- Уведомляем о новых доступных перках/косметике
    local role = self:IsKiller(ply) and "killer" or "survivor"
    local availablePerks = {}
    local availableCosmetics = {}
    
    -- Проверяем новые перки
    for _, perk in pairs(self.Perks[role] or {}) do
        if perk.levelRequired == newLevel then
            table.insert(availablePerks, perk)
        end
    end
    
    -- Проверяем новую косметику
    for _, cosmetic in pairs(self.Cosmetics[role] or {}) do
        if cosmetic.levelRequired == newLevel then
            table.insert(availableCosmetics, cosmetic)
        end
    end
    
    if #availablePerks > 0 or #availableCosmetics > 0 then
        ply:ChatPrint("Новые награды доступны! Откройте меню прогресса для просмотра.")
    end
    
    -- Отправляем обновление клиенту
    if SERVER then
        net.Start("GModsaken_ProgressionUpdate")
        net.WriteTable(self.PlayerProgression[ply:SteamID()] or {})
        net.Send(ply)
    end
end

-- Функция для проверки разблокированного перка
function GM:IsPerkUnlocked(ply, perkID)
    local progression = self:GetPlayerProgression(ply)
    if not progression then return false end
    
    for _, unlockedPerkID in pairs(progression.unlockedPerks or {}) do
        if unlockedPerkID == perkID then
            return true
        end
    end
    
    return false
end

-- Функция для проверки разблокированной косметики
function GM:IsCosmeticUnlocked(ply, cosmeticID)
    local progression = self:GetPlayerProgression(ply)
    if not progression then return false end
    
    for _, unlockedCosmeticID in pairs(progression.unlockedCosmetics or {}) do
        if unlockedCosmeticID == cosmeticID then
            return true
        end
    end
    
    return false
end

-- Функция для разблокировки перка
function GM:UnlockPerk(ply, perkID)
    if not IsValid(ply) then return false end
    
    local progression = self:GetPlayerProgression(ply)
    if not progression then return false end
    
    -- Проверяем, существует ли такой перк
    local role = self:IsKiller(ply) and "killer" or "survivor"
    local perk = nil
    
    for _, p in pairs(self.Perks[role] or {}) do
        if p.id == perkID then
            perk = p
            break
        end
    end
    
    if not perk then return false end
    
    -- Проверяем уровень
    if progression.level < perk.levelRequired then
        ply:ChatPrint("Вам нужен уровень " .. perk.levelRequired .. " для разблокировки этого перка!")
        return false
    end
    
    -- Проверяем, не разблокирован ли уже
    if self:IsPerkUnlocked(ply, perkID) then
        ply:ChatPrint("Этот перк уже разблокирован!")
        return false
    end
    
    -- Разблокируем перк
    table.insert(progression.unlockedPerks, perkID)
    ply:ChatPrint("Перк '" .. perk.name .. "' разблокирован!")
    
    -- Сохраняем изменения
    if SERVER then
        self:SavePlayerProgression(ply)
        
        -- Отправляем обновление клиенту
        net.Start("GModsaken_ProgressionUpdate")
        net.WriteTable(progression)
        net.Send(ply)
    end
    
    return true
end

-- Функция для разблокировки косметики
function GM:UnlockCosmetic(ply, cosmeticID)
    if not IsValid(ply) then return false end
    
    local progression = self:GetPlayerProgression(ply)
    if not progression then return false end
    
    -- Проверяем, существует ли такая косметика
    local role = self:IsKiller(ply) and "killer" or "survivor"
    local cosmetic = nil
    
    for _, c in pairs(self.Cosmetics[role] or {}) do
        if c.id == cosmeticID then
            cosmetic = c
            break
        end
    end
    
    if not cosmetic then return false end
    
    -- Проверяем уровень
    if progression.level < cosmetic.levelRequired then
        ply:ChatPrint("Вам нужен уровень " .. cosmetic.levelRequired .. " для разблокировки этой косметики!")
        return false
    end
    
    -- Проверяем, не разблокирована ли уже
    if self:IsCosmeticUnlocked(ply, cosmeticID) then
        ply:ChatPrint("Эта косметика уже разблокирована!")
        return false
    end
    
    -- Разблокируем косметику
    table.insert(progression.unlockedCosmetics, cosmeticID)
    ply:ChatPrint("Косметика '" .. cosmetic.name .. "' разблокирована!")
    
    -- Сохраняем изменения
    if SERVER then
        self:SavePlayerProgression(ply)
        
        -- Отправляем обновление клиенту
        net.Start("GModsaken_ProgressionUpdate")
        net.WriteTable(progression)
        net.Send(ply)
    end
    
    return true
end