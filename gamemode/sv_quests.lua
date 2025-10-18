--[[
    GModsaken - Quest System (Server)
    Copyright (C) 2024 GModsaken Contributors
    
    Server-side quest handling with proper resource management.
    Author: Андрій Будильников
]]

-- Ensure GM table exists
if not _G.GM then
    _G.GM = GAMEMODE or {}
    print("[GModsaken] Created GM table in sv_quests.lua")
end
local GM = _G.GM
_G.GAMEMODE = GM

print("[GModsaken] sv_quests.lua loaded - GM: " .. tostring(GM))

-- Создаем сетевые сообщения
util.AddNetworkString("GModsaken_UpdateQuestProgress")
util.AddNetworkString("GModsaken_UpdateQuestStats")

-- Отладочная команда для проверки квестов на сервере
concommand.Add("gmodsaken_debug_quests_server", function(ply, cmd, args)
    if not GM then
        print("GM table is nil on server!")
        return
    end
    
    print("=== SERVER DEBUG QUESTS ===")
    print("GM.QuestSystem: " .. tostring(GM.QuestSystem))
    
    if GM.QuestSystem then
        print("Trash quest models: " .. #GM.QuestSystem.TrashQuest.models)
        for i, model in ipairs(GM.QuestSystem.TrashQuest.models) do
            print("  " .. i .. ": " .. model)
        end
        
        print("Interfaces quest models: " .. #GM.QuestSystem.InterfacesQuest.models)
        for i, model in ipairs(GM.QuestSystem.InterfacesQuest.models) do
            print("  " .. i .. ": " .. model)
        end
    end
    
    print("GameState: " .. tostring(GM.GameState))
    print("================================")
end)

-- Проверка объектов для квестов
hook.Add("PlayerUse", "GModsaken_QuestItemCheck", function(ply, ent)
    if not IsValid(ply) or not IsValid(ent) then return end
    if not GM or not GM.QuestSystem then return end
    
    local entModel = ent:GetModel()
    if not entModel then return end
    
    -- Проверяем квест "Мусор"
    for _, model in ipairs(GM.QuestSystem.TrashQuest.models) do
        if entModel == model then
            local progress = GM:GetPlayerQuestProgress(ply, "trash")
            local quest = GM:GetQuest("trash")
            
            if progress < quest.requiredItems then
                progress = progress + 1
                GM:SetPlayerQuestProgress(ply, "trash", progress)
                
                ply:ChatPrint("Вы собрали предмет мусора! (" .. progress .. "/" .. quest.requiredItems .. ")")
                
                -- Проверяем завершение квеста
                if progress >= quest.requiredItems then
                    local canComplete, errorMsg = GM:CanPlayerCompleteQuest(ply, "trash")
                    if canComplete then
                        GM:AwardQuestReward(ply, "trash")
                        ply:ChatPrint("Квест '" .. quest.name .. "' выполнен! Время раунда уменьшено.")
                    else
                        ply:ChatPrint(errorMsg)
                    end
                end
            else
                ply:ChatPrint("Вы уже собрали достаточно предметов мусора!")
            end
            
            -- Удаляем объект
            ent:Remove()
            return false
        end
    end
    
    -- Проверяем квест "Интерфейсы"
    for _, model in ipairs(GM.QuestSystem.InterfacesQuest.models) do
        if entModel == model then
            local progress = GM:GetPlayerQuestProgress(ply, "interfaces")
            local quest = GM:GetQuest("interfaces")
            
            if progress < quest.requiredItems then
                progress = progress + 1
                GM:SetPlayerQuestProgress(ply, "interfaces", progress)
                
                ply:ChatPrint("Вы нашли интерфейс! (" .. progress .. "/" .. quest.requiredItems .. ")")
                
                -- Проверяем завершение квеста
                if progress >= quest.requiredItems then
                    local canComplete, errorMsg = GM:CanPlayerCompleteQuest(ply, "interfaces")
                    if canComplete then
                        GM:AwardQuestReward(ply, "interfaces")
                        ply:ChatPrint("Квест '" .. quest.name .. "' выполнен! Время раунда уменьшено.")
                    else
                        ply:ChatPrint(errorMsg)
                    end
                end
            else
                ply:ChatPrint("Вы уже нашли достаточно интерфейсов!")
            end
            
            -- Удаляем объект
            ent:Remove()
            return false
        end
    end
end)

-- Команда для сброса прогресса квестов
concommand.Add("gmodsaken_reset_quests", function(ply, cmd, args)
    if IsValid(ply) and not ply:IsSuperAdmin() then
        ply:ChatPrint("Только суперадмины могут сбрасывать прогресс квестов!")
        return
    end
    
    for _, player in pairs(player.GetAll()) do
        player.QuestProgress = {}
        player.LastInterfaceQuest = nil
        
        -- Отправляем обновление клиенту
        net.Start("GModsaken_UpdateQuestStats")
        net.WriteTable({})
        net.Send(player)
        
        if IsValid(ply) then
            ply:ChatPrint("Прогресс квестов сброшен для " .. player:Nick())
        end
        print("GModsaken: Quest progress reset for " .. player:Nick())
    end
end)

-- Команда для принудительного завершения квеста
concommand.Add("gmodsaken_complete_quest", function(ply, cmd, args)
    if IsValid(ply) and not ply:IsSuperAdmin() then
        ply:ChatPrint("Только суперадмины могут завершать квесты!")
        return
    end
    
    if #args < 2 then
        if IsValid(ply) then
            ply:ChatPrint("Использование: gmodsaken_complete_quest <имя_игрока> <название_квеста>")
        end
        return
    end
    
    local targetPly = player.GetByName(args[1])
    local questName = args[2]
    
    if not IsValid(targetPly) then
        if IsValid(ply) then
            ply:ChatPrint("Игрок не найден!")
        end
        return
    end
    
    if not GM or not GM.GetQuest or not GM:GetQuest(questName) then
        if IsValid(ply) then
            ply:ChatPrint("Квест не найден!")
        end
        return
    end
    
    local quest = GM:GetQuest(questName)
    GM:SetPlayerQuestProgress(targetPly, questName, quest.requiredItems)
    
    local canComplete, errorMsg = GM:CanPlayerCompleteQuest(targetPly, questName)
    if canComplete then
        GM:AwardQuestReward(targetPly, questName)
        if IsValid(ply) then
            ply:ChatPrint("Квест '" .. quest.name .. "' завершен для " .. targetPly:Nick())
        end
        targetPly:ChatPrint("Администратор завершил квест '" .. quest.name .. "' для вас!")
        print("GModsaken: Quest '" .. questName .. "' completed for " .. targetPly:Nick() .. " by admin")
    else
        if IsValid(ply) then
            ply:ChatPrint("Невозможно завершить квест: " .. errorMsg)
        end
    end
end)

-- Команда для просмотра прогресса квестов игрока
concommand.Add("gmodsaken_my_quests", function(ply, cmd, args)
    if not IsValid(ply) then return end
    
    if not GM or not GM.GetPlayerQuestStats then
        ply:ChatPrint("Система квестов не инициализирована!")
        return
    end
    
    local stats = GM:GetPlayerQuestStats(ply)
    
    ply:ChatPrint("=== Ваш прогресс по квестам ===")
    for questName, questData in pairs(stats) do
        local quest = GM:GetQuest(questName)
        if quest then
            ply:ChatPrint(quest.name .. ": " .. questData.progress .. "/" .. questData.required)
        end
    end
    ply:ChatPrint("===============================")
end)

-- Команда для тестирования квестов
concommand.Add("gmodsaken_test_quest", function(ply, cmd, args)
    if not IsValid(ply) then return end
    
    if not GM then
        ply:ChatPrint("GM не инициализирован!")
        return
    end
    
    local questName = args[1] or "trash"
    local quest = GM:GetQuest(questName)
    
    if not quest then
        ply:ChatPrint("Квест не найден: " .. questName)
        return
    end
    
    ply:ChatPrint("=== ТЕСТ КВЕСТА ===")
    ply:ChatPrint("Название: " .. quest.name)
    ply:ChatPrint("Описание: " .. quest.description)
    ply:ChatPrint("Награда: " .. quest.rewardTime .. " секунд")
    ply:ChatPrint("Необходимо предметов: " .. quest.requiredItems)
    ply:ChatPrint("Моделей: " .. #quest.models)
    ply:ChatPrint("==================")
    
    -- Показываем модели
    for i, model in ipairs(quest.models) do
        ply:ChatPrint(i .. ". " .. model)
    end
end)

print("[GModsaken] Quest system (server) loaded")