--[[
    GModsaken - Quest System (Shared)
    Copyright (C) 2024 GModsaken Contributors
    
    Quest system with proper resource loading.
    Author: Андрій Будильников
]]

-- Ensure GM table exists
if not _G.GM then
    _G.GM = {}
end
local GM = _G.GM
_G.GAMEMODE = GM

-- Система квестов
GM.QuestSystem = {
    -- Квест "Мусор"
    TrashQuest = {
        name = "Собрать мусор",
        description = "Найдите и соберите 5 предметов мусора",
        rewardTime = -20, -- Уменьшает время на 20 секунд
        requiredItems = 5,
        models = {
            "models/props_junk/garbage_plasticbottle001a.mdl",
            "models/props_junk/garbage_milkcarton001a.mdl",
            "models/props_junk/garbage_metalcan001a.mdl",
            "models/props_junk/garbage_takeoutcarton001a.mdl",
            "models/props_junk/garbage_glassbottle001a.mdl",
            "models/props_junk/garbage_plasticbottle002a.mdl",
            "models/props_junk/garbage_metalcan002a.mdl"
        }
    },
    
    -- Квест "Интерфейсы"
    InterfacesQuest = {
        name = "Найти интерфейсы",
        description = "Найдите 3 компьютерных интерфейса",
        rewardTime = -30, -- Уменьшает время на 30 секунд
        cooldown = 90, -- Кулдаун 90 секунд
        requiredItems = 3,
        models = {
            "models/props_lab/monitor01a.mdl",
            "models/props_lab/monitor02.mdl",
            "models/props_c17/consolebox01a.mdl",
            "models/props_lab/harddrive02.mdl"
        }
    }
}

-- Загружаем ресурсы для квестов
if SERVER then
    -- Загружаем модели для квеста "Мусор"
    for _, model in ipairs(GM.QuestSystem.TrashQuest.models) do
        resource.AddFile(model)
        
        -- Загружаем связанные материалы
        local modelName = string.gsub(model, "%.mdl$", "")
        resource.AddFile(modelName .. ".vmt")
        resource.AddFile(modelName .. ".vtf")
    end
    
    -- Загружаем модели для квеста "Интерфейсы"
    for _, model in ipairs(GM.QuestSystem.InterfacesQuest.models) do
        resource.AddFile(model)
        
        -- Загружаем связанные материалы
        local modelName = string.gsub(model, "%.mdl$", "")
        resource.AddFile(modelName .. ".vmt")
        resource.AddFile(modelName .. ".vtf")
    end
    
    print("[GModsaken] Quest resources loaded")
end

-- Получение квеста по имени
function GM:GetQuest(questName)
    if questName == "trash" then
        return self.QuestSystem.TrashQuest
    elseif questName == "interfaces" then
        return self.QuestSystem.InterfacesQuest
    end
    return nil
end

-- Получение всех квестов
function GM:GetAllQuests()
    return {
        trash = self.QuestSystem.TrashQuest,
        interfaces = self.QuestSystem.InterfacesQuest
    }
end

-- Проверка, может ли игрок выполнить квест
function GM:CanPlayerCompleteQuest(ply, questName)
    if not IsValid(ply) then return false end
    
    local quest = self:GetQuest(questName)
    if not quest then return false end
    
    -- Проверяем кулдаун для квеста "Интерфейсы"
    if questName == "interfaces" then
        local lastCompletion = ply.LastInterfaceQuest or 0
        local currentTime = CurTime()
        local cooldown = quest.cooldown or 90
        
        if currentTime - lastCompletion < cooldown then
            return false, "Квест недоступен. Подождите " .. math.ceil(cooldown - (currentTime - lastCompletion)) .. " секунд."
        end
    end
    
    return true
end

-- Начисление награды за квест
function GM:AwardQuestReward(ply, questName)
    if not IsValid(ply) then return end
    
    local quest = self:GetQuest(questName)
    if not quest then return end
    
    -- Награждаем XP за выполнение квеста
    if SERVER and self.AwardQuestXP then
        self:AwardQuestXP(ply, questName)
    end
    
    -- Уменьшаем время раунда
    if SERVER and self.GameState == "PLAYING" then
        self.RoundTime = math.max(60, (self.RoundTime or 600) + quest.rewardTime)
        
        -- Уведомляем всех игроков
        for _, player in pairs(player.GetAll()) do
            player:ChatPrint("[КВЕСТ] " .. ply:Nick() .. " выполнил квест '" .. quest.name .. "'! Время раунда изменено на " .. math.abs(quest.rewardTime) .. " секунд.")
        end
        
        print("GModsaken: Quest '" .. questName .. "' completed by " .. ply:Nick() .. ", time adjusted by " .. quest.rewardTime .. " seconds")
    end
    
    -- Обновляем время последнего выполнения для квеста "Интерфейсы"
    if questName == "interfaces" then
        ply.LastInterfaceQuest = CurTime()
    end
end

-- Получение прогресса квеста игрока
function GM:GetPlayerQuestProgress(ply, questName)
    if not IsValid(ply) then return 0 end
    
    if not ply.QuestProgress then
        ply.QuestProgress = {}
    end
    
    return ply.QuestProgress[questName] or 0
end

-- Установка прогресса квеста игрока
function GM:SetPlayerQuestProgress(ply, questName, progress)
    if not IsValid(ply) then return end
    
    if not ply.QuestProgress then
        ply.QuestProgress = {}
    end
    
    ply.QuestProgress[questName] = progress
    
    -- Отправляем обновление клиенту
    if SERVER then
        net.Start("GModsaken_UpdateQuestProgress")
        net.WriteString(questName)
        net.WriteInt(progress, 32)
        net.Send(ply)
    end
end

-- Проверка завершения квеста
function GM:IsQuestCompleted(ply, questName)
    if not IsValid(ply) then return false end
    
    local quest = self:GetQuest(questName)
    if not quest then return false end
    
    local progress = self:GetPlayerQuestProgress(ply, questName)
    return progress >= quest.requiredItems
end

-- Получение статистики квестов игрока
function GM:GetPlayerQuestStats(ply)
    if not IsValid(ply) then return {} end
    
    local stats = {}
    
    for questName, quest in pairs(self:GetAllQuests()) do
        stats[questName] = {
            progress = self:GetPlayerQuestProgress(ply, questName),
            completed = self:IsQuestCompleted(ply, questName),
            required = quest.requiredItems
        }
    end
    
    return stats
end

print("[GModsaken] Quest system loaded")