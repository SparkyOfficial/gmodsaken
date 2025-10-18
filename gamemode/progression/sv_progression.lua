--[[
    GModsaken - Progression System (Server)
    Copyright (C) 2024 GModsaken Contributors
]]

-- AddCSLuaFile for shared and client files
AddCSLuaFile("sh_progression.lua")
include("sh_progression.lua")

-- Create network strings
util.AddNetworkString("GModsaken_ProgressionUpdate")
util.AddNetworkString("GModsaken_RequestProgression")
util.AddNetworkString("GModsaken_UnlockPerk")
util.AddNetworkString("GModsaken_UnlockCosmetic")

-- Функция для сохранения прогрессии игрока (заглушка для реальной реализации)
function GM:SavePlayerProgression(ply)
    if not IsValid(ply) then return end
    
    -- В реальной реализации здесь будет код для сохранения в файл или базу данных
    -- Например, можно использовать file.Write или подключение к базе данных
    print("GModsaken: Прогрессия игрока " .. ply:Nick() .. " сохранена (заглушка)")
end

-- Функция для загрузки прогрессии игрока (заглушка для реальной реализации)
function GM:LoadPlayerProgression(ply)
    if not IsValid(ply) then return end
    
    -- В реальной реализации здесь будет код для загрузки из файла или базы данных
    -- Пока что просто инициализируем новую прогрессию
    local progression = self:GetPlayerProgression(ply)
    
    -- Отправляем текущую прогрессию клиенту
    net.Start("GModsaken_ProgressionUpdate")
    net.WriteTable(progression or {})
    net.Send(ply)
    
    print("GModsaken: Прогрессия игрока " .. ply:Nick() .. " загружена (заглушка)")
end

-- Награды за выживание
function GM:AwardSurvivalXP(ply, timeSurvived)
    if not IsValid(ply) or not self:IsSurvivor(ply) then return end
    
    -- 1 XP за каждые 10 секунд выживания
    local xp = math.floor(timeSurvived / 10)
    if xp > 0 then
        self:AddPlayerXP(ply, xp)
        ply:ChatPrint("Получено " .. xp .. " XP за выживание!")
    end
end

-- Награды за помощь товарищам
function GM:AwardAssistXP(ply, assistType)
    if not IsValid(ply) or not self:IsSurvivor(ply) then return end
    
    local xp = 0
    
    if assistType == "heal" then
        xp = 15  -- Лечение товарища
    elseif assistType == "repair" then
        xp = 10  -- Ремонт турели/диспенсера
    elseif assistType == "rescue" then
        xp = 25  -- Спасение товарища из ловушки
    end
    
    if xp > 0 then
        self:AddPlayerXP(ply, xp)
        ply:ChatPrint("Получено " .. xp .. " XP за помощь товарищу!")
    end
end

-- Награды за убийства (для убийцы)
function GM:AwardKillXP(ply, victim)
    if not IsValid(ply) or not self:IsKiller(ply) then return end
    if not IsValid(victim) or not self:IsSurvivor(victim) then return end
    
    -- Базовые 50 XP за убийство
    local xp = 50
    
    -- Бонус за быстрое убийство
    if self.RoundStartTime then
        local timePassed = CurTime() - self.RoundStartTime
        if timePassed < 120 then  -- Первые 2 минуты
            xp = xp + 20  -- Бонус 20 XP
        end
    end
    
    self:AddPlayerXP(ply, xp)
    ply:ChatPrint("Получено " .. xp .. " XP за убийство!")
end

-- Награды за завершение квестов
function GM:AwardQuestXP(ply, questType)
    if not IsValid(ply) then return end
    
    local xp = 0
    
    if questType == "trash" then
        xp = 30  -- Сбор мусора
    elseif questType == "interfaces" then
        xp = 50  -- Использование интерфейсов
    end
    
    if xp > 0 then
        self:AddPlayerXP(ply, xp)
        ply:ChatPrint("Получено " .. xp .. " XP за выполнение квеста!")
    end
end

-- Награды за победу в раунде
function GM:AwardWinXP(ply, isKillerWin)
    if not IsValid(ply) then return end
    
    local xp = 0
    
    if isKillerWin and self:IsKiller(ply) then
        xp = 100  -- Победа убийцы
    elseif not isKillerWin and self:IsSurvivor(ply) then
        xp = 80   -- Победа выживших
    end
    
    if xp > 0 then
        self:AddPlayerXP(ply, xp)
        ply:ChatPrint("Получено " .. xp .. " XP за победу в раунде!")
    end
end

-- Обработчики сетевых сообщений
net.Receive("GModsaken_RequestProgression", function(len, ply)
    if IsValid(ply) then
        GAMEMODE:LoadPlayerProgression(ply)
    end
end)

net.Receive("GModsaken_UnlockPerk", function(len, ply)
    local perkID = net.ReadString()
    if IsValid(ply) and perkID then
        GAMEMODE:UnlockPerk(ply, perkID)
    end
end)

net.Receive("GModsaken_UnlockCosmetic", function(len, ply)
    local cosmeticID = net.ReadString()
    if IsValid(ply) and cosmeticID then
        GAMEMODE:UnlockCosmetic(ply, cosmeticID)
    end
end)

-- Хуки для игровых событий
hook.Add("PlayerInitialSpawn", "GModsaken_LoadProgression", function(ply)
    -- Загружаем прогрессию игрока при подключении
    timer.Simple(5, function()  -- Небольшая задержка для загрузки всего
        if IsValid(ply) then
            GAMEMODE:LoadPlayerProgression(ply)
        end
    end)
end)

hook.Add("PlayerDeath", "GModsaken_AwardKillXP", function(victim, inflictor, attacker)
    -- Награждаем убийцу XP
    if IsValid(attacker) and attacker:IsPlayer() and 
       IsValid(victim) and victim:IsPlayer() and
       attacker ~= victim then
        
        GAMEMODE:AwardKillXP(attacker, victim)
    end
end)

-- Консольные команды для тестирования
concommand.Add("gmodsaken_addxp", function(ply, cmd, args)
    if not IsValid(ply) then return end
    
    local amount = tonumber(args[1]) or 100
    GAMEMODE:AddPlayerXP(ply, amount)
    ply:ChatPrint("Добавлено " .. amount .. " XP!")
end)

concommand.Add("gmodsaken_setlevel", function(ply, cmd, args)
    if not IsValid(ply) then return end
    
    local level = tonumber(args[1]) or 1
    if level < 1 then level = 1 end
    if level > 50 then level = 50 end
    
    local progression = GAMEMODE:GetPlayerProgression(ply)
    if progression then
        local xpRequired = GAMEMODE.XPRequirements[level] or 0
        progression.xp = xpRequired
        progression.level = level
        
        GAMEMODE:OnPlayerLevelUp(ply, level - 1, level)
        ply:ChatPrint("Уровень установлен на " .. level)
    end
end)

concommand.Add("gmodsaken_resetprogression", function(ply, cmd, args)
    if not IsValid(ply) or not ply:IsSuperAdmin() then
        if IsValid(ply) then
            ply:ChatPrint("Только суперадмин может сбросить прогрессию!")
        end
        return
    end
    
    -- Сброс прогрессии всех игроков (только для тестирования)
    GAMEMODE.PlayerProgression = {}
    ply:ChatPrint("Прогрессия всех игроков сброшена!")
end)