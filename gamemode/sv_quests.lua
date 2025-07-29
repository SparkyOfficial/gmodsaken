--[[
    GModsaken - Quest System (Server)
    Copyright (C) 2024 GModsaken Contributors
]]

-- Ensure GM table exists
if not _G.GM then
    _G.GM = {}
end
local GM = _G.GM
_G.GAMEMODE = GM

-- Добавляем сетевую строку для обновления статистики квестов
if SERVER then
    util.AddNetworkString("GModsaken_UpdateQuestStats")
    util.AddNetworkString("GModsaken_QuestInteraction")
end

-- Обработка взаимодействия с объектами квестов
hook.Add("PlayerUse", "GModsaken_QuestInteraction", function(player, entity)
    if not IsValid(player) or not IsValid(entity) then return end
    if not entity:GetNWBool("IsQuestObject") then return end
    
    -- Только выжившие могут взаимодействовать с квестами
    if not GM or not GM.TEAM_SURVIVOR then 
        return 
    end
    if player:Team() ~= GM.TEAM_SURVIVOR then 
        return 
    end
    
    local questType = entity:GetNWString("QuestType")
    
    if questType == "Trash" then
        -- Проверяем, находится ли игрок рядом с мусорным баком
        local dumpster = nil
        for _, ent in pairs(ents.FindByClass("prop_physics")) do
            if ent:GetNWString("QuestType") == "TrashDumpster" then
                dumpster = ent
                break
            end
        end
        
        if IsValid(dumpster) then
            local distance = player:GetPos():Distance(dumpster:GetPos())
            
            if distance <= 200 then -- Радиус взаимодействия
                GM:CollectTrash(entity, player)
            else
                player:ChatPrint("❌ Нужно быть рядом с мусорным баком для сдачи мусора!")
                player:EmitSound("buttons/button10.wav")
            end
        else
            player:ChatPrint("❌ Мусорный бак не найден!")
            player:EmitSound("buttons/button10.wav")
        end
        
    elseif questType == "CombineInterface" then
        GM:UseCombineInterface(entity, player)
    end
end)

-- Обработка физического контакта с мусором
hook.Add("PhysicsCollide", "GModsaken_TrashCollision", function(data, phys)
    if not IsValid(data.HitEntity) then return end
    
    -- Проверяем, является ли один из объектов мусором, а другой - мусорным баком
    local trash = nil
    local dumpster = nil
    
    if data.HitEntity:GetNWString("QuestType") == "Trash" then
        trash = data.HitEntity
    elseif data.HitEntity:GetNWString("QuestType") == "TrashDumpster" then
        dumpster = data.HitEntity
    end
    
    if data.HitEntity2 then
        if data.HitEntity2:GetNWString("QuestType") == "Trash" then
            trash = data.HitEntity2
        elseif data.HitEntity2:GetNWString("QuestType") == "TrashDumpster" then
            dumpster = data.HitEntity2
        end
    end
    
    -- Если мусор попал в мусорный бак, автоматически собираем его
    if IsValid(trash) and IsValid(dumpster) then
        local distance = trash:GetPos():Distance(dumpster:GetPos())
        if distance <= 100 then -- Радиус автоматического сбора
            -- Находим ближайшего игрока для уведомления
            local nearestPlayer = nil
            local minDistance = math.huge
            
            for _, ply in pairs(player.GetAll()) do
                if IsValid(ply) and ply:Team() == GM.TEAM_SURVIVOR then
                    local dist = ply:GetPos():Distance(trash:GetPos())
                    if dist < minDistance then
                        minDistance = dist
                        nearestPlayer = ply
                    end
                end
            end
            
            if IsValid(nearestPlayer) then
                GM:CollectTrash(trash, nearestPlayer)
            else
                -- Если нет игроков поблизости, просто удаляем мусор
                trash:Remove()
                GM.QuestStats.TrashCollected = GM.QuestStats.TrashCollected + 1
                GM.QuestStats.TimeAdded = GM.QuestStats.TimeAdded + 20
                
                if GM.RoundEndTime then
                    GM.RoundEndTime = GM.RoundEndTime + 20
                end
            end
        end
    end
end)

-- Команда для принудительной инициализации квестов
concommand.Add("gmodsaken_force_init_quests", function(ply, cmd, args)
    if not IsValid(ply) or not ply:IsAdmin() then return end
    
    if GM.InitializeQuests then
        GM:InitializeQuests()
        ply:ChatPrint("✓ Квесты принудительно инициализированы!")
    else
        ply:ChatPrint("❌ Функция InitializeQuests не найдена!")
    end
end)

-- Команда для очистки квестов
concommand.Add("gmodsaken_cleanup_quests", function(ply, cmd, args)
    if not IsValid(ply) or not ply:IsAdmin() then return end
    
    if GM.CleanupQuests then
        GM:CleanupQuests()
        ply:ChatPrint("✓ Квесты очищены!")
    else
        ply:ChatPrint("❌ Функция CleanupQuests не найдена!")
    end
end)

-- Команда для показа статистики квестов
concommand.Add("gmodsaken_quest_stats", function(ply, cmd, args)
    if not IsValid(ply) then return end
    
    local stats = GM:GetQuestStats()
    ply:ChatPrint("=== Статистика квестов ===")
    ply:ChatPrint("Мусор собрано: " .. stats.TrashCollected)
    ply:ChatPrint("Интерфейсов использовано: " .. stats.InterfacesUsed)
    ply:ChatPrint("Времени добавлено: " .. stats.TimeAdded .. " секунд")
end)

-- Команда для диагностики квестов
concommand.Add("gmodsaken_quest_debug", function(ply, cmd, args)
    if not IsValid(ply) then return end
    
    ply:ChatPrint("=== Диагностика квестов ===")
    ply:ChatPrint("Ваша команда: " .. ply:Team())
    ply:ChatPrint("GM.TEAM_SURVIVOR: " .. (GM and GM.TEAM_SURVIVOR or "nil"))
    
    -- Ищем объекты квестов
    local trashCount = 0
    local dumpsterCount = 0
    local interfaceCount = 0
    
    for _, ent in pairs(ents.FindByClass("prop_physics")) do
        if ent:GetNWBool("IsQuestObject") then
            local questType = ent:GetNWString("QuestType")
            if questType == "Trash" then
                trashCount = trashCount + 1
            elseif questType == "TrashDumpster" then
                dumpsterCount = dumpsterCount + 1
            elseif questType == "CombineInterface" then
                interfaceCount = interfaceCount + 1
            end
        end
    end
    
    ply:ChatPrint("Мусор: " .. trashCount)
    ply:ChatPrint("Мусорные баки: " .. dumpsterCount)
    ply:ChatPrint("Интерфейсы: " .. interfaceCount)
    
    -- Проверяем расстояние до мусорного бака
    local nearestDumpster = nil
    local minDistance = math.huge
    
    for _, ent in pairs(ents.FindByClass("prop_physics")) do
        if ent:GetNWString("QuestType") == "TrashDumpster" then
            local distance = ply:GetPos():Distance(ent:GetPos())
            if distance < minDistance then
                minDistance = distance
                nearestDumpster = ent
            end
        end
    end
    
    if IsValid(nearestDumpster) then
        ply:ChatPrint("Ближайший мусорный бак: " .. math.floor(minDistance) .. " единиц")
    else
        ply:ChatPrint("Мусорный бак не найден!")
    end
end)

-- Автоматическая инициализация квестов при начале игры
hook.Add("GModsaken_GameStarted", "GModsaken_InitQuestsOnGameStart", function()
    if GM.InitializeQuests then
        timer.Simple(2, function() -- Небольшая задержка для стабилизации
            GM:InitializeQuests()
        end)
    end
end)

-- Автоматическая очистка квестов при окончании игры
hook.Add("GModsaken_GameEnded", "GModsaken_CleanupQuestsOnGameEnd", function()
    if GM.CleanupQuests then
        GM:CleanupQuests()
    end
end)

-- Обновление статистики каждые 5 секунд
timer.Create("GModsaken_QuestStatsUpdate", 5, 0, function()
    if SERVER and GM.QuestStats then
        if util.NetworkStringToID("GModsaken_UpdateQuestStats") ~= 0 then
            net.Start("GModsaken_UpdateQuestStats")
            net.WriteInt(GM.QuestStats.TrashCollected, 32)
            net.WriteInt(GM.QuestStats.InterfacesUsed, 32)
            net.WriteInt(GM.QuestStats.TimeAdded, 32)
            net.Broadcast()
        end
    end
end) 