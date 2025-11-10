--[[
    GModsaken - Bot System for Testing
    Copyright (C) 2024 GModsaken Contributors
    
    Простая система ботов для тестирования геймплея
]]

if not SERVER then return end

-- Ensure GM table exists
if not _G.GM then
    _G.GM = GAMEMODE or {}
end
local GM = _G.GM
_G.GAMEMODE = GM

-- Таблица для хранения ботов
GM.TestBots = GM.TestBots or {}

-- Функция для получения всех игроков + ботов
function GM:GetAllPlayersAndBots()
    local all = {}
    
    -- Добавляем реальных игроков
    for _, ply in ipairs(player.GetAll()) do
        table.insert(all, ply)
    end
    
    -- Добавляем ботов
    for _, bot in ipairs(self.TestBots) do
        if IsValid(bot) then
            table.insert(all, bot)
        end
    end
    
    return all
end

-- Функция для получения количества игроков + ботов
function GM:GetPlayerAndBotCount()
    local count = #player.GetAll()
    
    for _, bot in ipairs(self.TestBots) do
        if IsValid(bot) then
            count = count + 1
        end
    end
    
    return count
end

-- Имена для ботов
local botNames = {
    "Тестовый Бот",
    "Бот Иван",
    "Бот Петр",
    "Бот Мария",
    "Бот Анна",
    "Бот Сергей",
    "Бот Дмитрий",
    "Бот Ольга",
    "Бот Елена",
    "Бот Александр"
}

-- Создание тестового бота (NPC который ведет себя как игрок)
function GM:CreateTestBot()
    -- Находим случайную точку спавна
    local spawnPoints = ents.FindByClass("info_player_start")
    if #spawnPoints == 0 then
        spawnPoints = ents.FindByClass("info_player_deathmatch")
    end
    if #spawnPoints == 0 then
        print("[GModsaken] Нет точек спавна для бота!")
        return nil
    end
    
    local spawnPoint = spawnPoints[math.random(#spawnPoints)]
    local spawnPos = spawnPoint:GetPos()
    
    -- Создаем NPC
    local bot = ents.Create("npc_citizen")
    if not IsValid(bot) then
        print("[GModsaken] Не удалось создать NPC бота!")
        return nil
    end
    
    bot:SetPos(spawnPos + Vector(0, 0, 10))
    bot:SetAngles(Angle(0, math.random(0, 360), 0))
    
    -- Выбираем случайное имя
    local botName = botNames[math.random(#botNames)] .. " #" .. math.random(100, 999)
    bot:SetNWString("BotName", botName)
    
    -- Настраиваем бота
    bot:SetHealth(100)
    bot:SetMaxHealth(100)
    bot:Spawn()
    bot:Activate()
    
    -- Помечаем как бота
    bot.IsTestBot = true
    bot.BotName = botName
    bot.BotTeam = TEAM_UNASSIGNED
    
    -- Добавляем в таблицу ботов
    table.insert(self.TestBots, bot)
    
    print("[GModsaken] Создан тестовый бот: " .. botName)
    
    return bot
end

-- Удаление всех тестовых ботов
function GM:RemoveAllTestBots()
    local count = 0
    for _, bot in ipairs(self.TestBots) do
        if IsValid(bot) then
            bot:Remove()
            count = count + 1
        end
    end
    
    self.TestBots = {}
    
    print("[GModsaken] Удалено тестовых ботов: " .. count)
    return count
end

-- Получение количества ботов
function GM:GetTestBotCount()
    local count = 0
    for _, bot in ipairs(self.TestBots) do
        if IsValid(bot) then
            count = count + 1
        end
    end
    return count
end

-- Команда для добавления тестового бота
concommand.Add("gmodsaken_addbot", function(ply, cmd, args)
    if IsValid(ply) and not ply:IsAdmin() then
        ply:ChatPrint("[ОШИБКА] У вас нет прав для использования этой команды!")
        return
    end
    
    local bot = GM:CreateTestBot()
    if IsValid(bot) then
        if IsValid(ply) then
            ply:ChatPrint("[АДМИН] Тестовый бот добавлен: " .. bot.BotName)
        end
        
        -- Уведомляем всех игроков
        for _, p in ipairs(player.GetAll()) do
            p:ChatPrint("[СИСТЕМА] Добавлен тестовый бот для отладки")
        end
    else
        if IsValid(ply) then
            ply:ChatPrint("[ОШИБКА] Не удалось создать тестового бота!")
        end
    end
end)

-- Команда для удаления всех тестовых ботов
concommand.Add("gmodsaken_removebot", function(ply, cmd, args)
    if IsValid(ply) and not ply:IsAdmin() then
        ply:ChatPrint("[ОШИБКА] У вас нет прав для использования этой команды!")
        return
    end
    
    local count = GM:RemoveAllTestBots()
    
    if IsValid(ply) then
        ply:ChatPrint("[АДМИН] Удалено тестовых ботов: " .. count)
    end
    
    -- Уведомляем всех игроков
    for _, p in ipairs(player.GetAll()) do
        p:ChatPrint("[СИСТЕМА] Все тестовые боты удалены")
    end
end)

-- Команда для получения информации о ботах
concommand.Add("gmodsaken_botinfo", function(ply, cmd, args)
    if not IsValid(ply) then return end
    
    local count = GM:GetTestBotCount()
    ply:ChatPrint("[ИНФОРМАЦИЯ] Активных тестовых ботов: " .. count)
    
    for i, bot in ipairs(GM.TestBots) do
        if IsValid(bot) then
            ply:ChatPrint("  " .. i .. ". " .. bot.BotName .. " (HP: " .. bot:Health() .. ")")
        end
    end
end)

-- Очистка ботов при смене карты
hook.Add("ShutDown", "GModsaken_CleanupBots", function()
    if GM and GM.RemoveAllTestBots then
        GM:RemoveAllTestBots()
    end
end)

print("[GModsaken] Bot system loaded")
