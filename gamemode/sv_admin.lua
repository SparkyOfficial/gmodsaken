--[[
    GModsaken - Admin Commands
    Copyright (C) 2024 GModsaken Contributors
]]

-- Ensure GM table exists
if not _G.GM then
    _G.GM = GAMEMODE or {}
    print("[GModsaken] Created GM table in sv_admin.lua")
end
local GM = _G.GM
_G.GAMEMODE = GM

print("[GModsaken] sv_admin.lua loaded - GM: " .. tostring(GM))

-- Check if player is superadmin
local function IsSuperAdmin(ply)
    return IsValid(ply) and (ply:IsSuperAdmin() or game.SinglePlayer())
end

-- Check if player is admin
local function IsAdmin(ply)
    return IsValid(ply) and (ply:IsAdmin() or ply:IsSuperAdmin() or game.SinglePlayer())
end

-- Force start the round
local function ForceStartRound(ply, cmd, args)
    if not IsAdmin(ply) then 
        if IsValid(ply) then
            ply:ChatPrint("[ОШИБКА] У вас нет прав для использования этой команды!")
        end
        return 
    end
    
    if not GM then
        if IsValid(ply) then
            ply:ChatPrint("[ОШИБКА] GM не инициализирован!")
        end
        return
    end
    
    if GM.GameState ~= "LOBBY" then
        if IsValid(ply) then
            ply:ChatPrint("[ОШИБКА] Игра уже началась!")
        end
        return
    end
    
    local players = player.GetAll()
    if #players < 2 and not game.SinglePlayer() then
        if IsValid(ply) then
            ply:ChatPrint("[ОШИБКА] Недостаточно игроков для начала раунда!")
        end
        return
    end
    
    -- Start the round
    if GM.StartRound then
        GM:StartRound()
    else
        if IsValid(ply) then
            ply:ChatPrint("[ОШИБКА] Функция StartRound не найдена!")
        end
        return
    end
    
    -- Notify all players
    for _, v in ipairs(players) do
        v:ChatPrint("[АДМИН] Раунд принудительно начат!")
    end
    
    print(string.format("[GModsaken] Round force started by %s", IsValid(ply) and ply:Nick() or "CONSOLE"))
end

-- Force end the round
local function ForceEndRound(ply, cmd, args)
    if not IsAdmin(ply) then 
        if IsValid(ply) then
            ply:ChatPrint("[ОШИБКА] У вас нет прав для использования этой команды!")
        end
        return 
    end
    
    if not GM then
        if IsValid(ply) then
            ply:ChatPrint("[ОШИБКА] GM не инициализирован!")
        end
        return
    end
    
    if GM.GameState == "LOBBY" then
        if IsValid(ply) then
            ply:ChatPrint("[ОШИБКА] Игра еще не началась!")
        end
        return
    end
    
    -- End the round
    if GM.EndRound then
        GM:EndRound(IsValid(ply) and ply or nil)
    else
        if IsValid(ply) then
            ply:ChatPrint("[ОШИБКА] Функция EndRound не найдена!")
        end
        return
    end
    
    -- Notify all players
    for _, v in ipairs(player.GetAll()) do
        v:ChatPrint("[АДМИН] Раунд принудительно завершен!")
    end
    
    print(string.format("[GModsaken] Round force ended by %s", IsValid(ply) and ply:Nick() or "CONSOLE"))
end

-- Set round time
local function SetRoundTime(ply, cmd, args)
    if not IsAdmin(ply) then 
        if IsValid(ply) then
            ply:ChatPrint("[ОШИБКА] У вас нет прав для использования этой команды!")
        end
        return 
    end
    
    if not GM then
        if IsValid(ply) then
            ply:ChatPrint("[ОШИБКА] GM не инициализирован!")
        end
        return
    end
    
    local time = tonumber(args[1])
    if not time or time < 60 or time > 1800 then
        if IsValid(ply) then
            ply:ChatPrint("[ИСПОЛЬЗОВАНИЕ] sm_settime <секунды> (60-1800)")
        end
        return
    end
    
    GM.RoundTime = time
    
    -- Update remaining time if round is in progress
    if GM.GameState == "PLAYING" and GM.RoundEndTime then
        GM.RoundEndTime = CurTime() + time
    end
    
    -- Notify all players
    for _, v in ipairs(player.GetAll()) do
        v:ChatPrint(string.format("[АДМИН] Время раунда установлено на %d минут", math.Round(time / 60)))
    end
    
    print(string.format("[GModsaken] Round time set to %d seconds by %s", time, IsValid(ply) and ply:Nick() or "CONSOLE"))
end

-- Add bot
local function AddBot(ply, cmd, args)
    if not IsAdmin(ply) then 
        if IsValid(ply) then
            ply:ChatPrint("[ОШИБКА] У вас нет прав для использования этой команды!")
        end
        return 
    end
    
    -- В Garry's Mod нет встроенной поддержки ботов
    -- Рекомендуем использовать аддон "Player Bots" из Workshop
    -- https://steamcommunity.com/sharedfiles/filedetails/?id=2848862522
    
    if IsValid(ply) then
        ply:ChatPrint("[ИНФОРМАЦИЯ] Для добавления ботов используйте:")
        ply:ChatPrint("1. Установите аддон 'Player Bots' из Workshop")
        ply:ChatPrint("2. Или используйте команду 'bot' в консоли сервера")
        ply:ChatPrint("3. Или пригласите друзей для тестирования")
    end
    
    print("[GModsaken] Bot command called - Garry's Mod doesn't have native bot support")
    print("[GModsaken] Recommend using 'Player Bots' addon from Workshop")
end

-- Remove all bots
local function RemoveBots(ply, cmd, args)
    if not IsAdmin(ply) then 
        if IsValid(ply) then
            ply:ChatPrint("[ОШИБКА] У вас нет прав для использования этой команды!")
        end
        return 
    end
    
    local count = 0
    for _, bot in ipairs(player.GetBots()) do
        if IsValid(bot) then
            bot:Kick("Удален администратором")
            count = count + 1
        end
    end
    
    if IsValid(ply) then
        ply:ChatPrint("[АДМИН] Удалено ботов: " .. count)
    end
    
    print(string.format("[GModsaken] %d bots removed by %s", count, IsValid(ply) and ply:Nick() or "CONSOLE"))
end

-- Register console commands
concommand.Add("sm_forcestart", ForceStartRound, nil, "Принудительно начать раунд")
concommand.Add("sm_forceend", ForceEndRound, nil, "Принудительно завершить раунд")
concommand.Add("sm_settime", SetRoundTime, nil, "Установить время раунда в секундах (60-1800)")
concommand.Add("bot", AddBot, nil, "Добавить бота для тестирования")
concommand.Add("gmodsaken_addbot", AddBot, nil, "Добавить бота для тестирования")
concommand.Add("gmodsaken_removebot", RemoveBots, nil, "Удалить всех ботов")

-- Add chat commands
hook.Add("PlayerSay", "GModsaken_AdminChatCommands", function(ply, text)
    if text:lower() == "!forcestart" then
        ForceStartRound(ply)
        return ""
    elseif text:lower() == "!forceend" then
        ForceEndRound(ply)
        return ""
    elseif text:lower():StartWith("!settime ") then
        local args = string.Explode(" ", text)
        SetRoundTime(ply, nil, {args[2]})
        return ""
    elseif text:lower() == "!bot" or text:lower() == "!addbot" then
        AddBot(ply)
        return ""
    elseif text:lower() == "!removebot" or text:lower() == "!removebots" then
        RemoveBots(ply)
        return ""
    end
end)

print("[GModsaken] Admin commands loaded")
