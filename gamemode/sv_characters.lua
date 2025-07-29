--[[
    GModsaken - Characters System (Server)
    Copyright (C) 2024 GModsaken Contributors
]]

-- Ensure GM table exists
if not _G.GM then
    _G.GM = GAMEMODE or {}
    print("[GModsaken] Created GM table in sv_characters.lua")
end
local GM = _G.GM
_G.GAMEMODE = GM

print("[GModsaken] sv_characters.lua loaded - GM: " .. tostring(GM))

-- Создаем сетевое сообщение
util.AddNetworkString("GModsaken_SelectCharacter")
util.AddNetworkString("GModsaken_CharacterSelected")
util.AddNetworkString("GModsaken_OpenCharacterMenu")

-- Отладочная команда для проверки персонажей на сервере
concommand.Add("gmodsaken_debug_characters_server", function(ply, cmd, args)
    if not GM then
        print("GM table is nil on server!")
        return
    end
    
    print("=== SERVER DEBUG CHARACTERS ===")
    print("GM.SurvivorCharacters: " .. tostring(GM.SurvivorCharacters))
    print("GM.KillerCharacters: " .. tostring(GM.KillerCharacters))
    
    if GM.SurvivorCharacters then
        print("Survivor count: " .. #GM.SurvivorCharacters)
        for i, char in pairs(GM.SurvivorCharacters) do
            print("Survivor " .. i .. ": " .. (char.name or "UNNAMED") .. " (ID: " .. (char.id or "NO_ID") .. ") - HP: " .. char.health .. " Armor: " .. (char.armor or 0))
        end
    end
    
    if GM.KillerCharacters then
        print("Killer count: " .. #GM.KillerCharacters)
        for i, char in pairs(GM.KillerCharacters) do
            print("Killer " .. i .. ": " .. (char.name or "UNNAMED") .. " (ID: " .. (char.id or "NO_ID") .. ") - HP: " .. char.health .. " Armor: " .. (char.armor or 0))
        end
    end
    
    print("GameState: " .. tostring(GM.GameState))
    print("================================")
end)

-- Обработка выбора персонажа
net.Receive("GModsaken_SelectCharacter", function(len, ply)
    if not IsValid(ply) then return end
    
    local characterName = net.ReadString()
    
    -- Проверяем, что игрок в лобби или подготовке
    if not GM or not GM.GameState or (GM.GameState ~= "LOBBY" and GM.GameState ~= "PREPARING") then
        net.Start("GModsaken_CharacterSelected")
        net.WriteString("")
        net.WriteBool(false)
        net.Send(ply)
        ply:ChatPrint("Меню персонажей доступно только в лобби!")
        return
    end
    
    -- Проверяем, что персонаж существует
    if not GM.GetCharacter or not GM:GetCharacter(characterName) then
        net.Start("GModsaken_CharacterSelected")
        net.WriteString("")
        net.WriteBool(false)
        net.Send(ply)
        ply:ChatPrint("Персонаж не найден!")
        return
    end
    
    -- Применяем персонажа
    if GM.ApplyCharacter and GM:ApplyCharacter(ply, characterName) then
        -- Уведомляем клиента об успешном выборе
        net.Start("GModsaken_CharacterSelected")
        net.WriteString(characterName)
        net.WriteBool(true)
        net.Send(ply)
        
        print("GModsaken: Игрок " .. ply:Nick() .. " выбрал персонажа: " .. characterName)
    else
        -- Уведомляем клиента об ошибке
        net.Start("GModsaken_CharacterSelected")
        net.WriteString("")
        net.WriteBool(false)
        net.Send(ply)
        
        ply:ChatPrint("Ошибка при выборе персонажа!")
    end
end)

-- Команда для открытия меню персонажей
concommand.Add("gmodsaken_character_menu", function(ply, cmd, args)
    if not IsValid(ply) then return end
    
    if not GM or not GM.GameState or (GM.GameState ~= "LOBBY" and GM.GameState ~= "PREPARING") then
        ply:ChatPrint("Меню персонажей доступно только в лобби!")
        return
    end
    
    -- Отправляем команду клиенту для открытия меню
    net.Start("GModsaken_OpenCharacterMenu")
    net.Send(ply)
end)

-- Применение персонажей при начале раунда
hook.Add("GModsaken_RoundStart", "GModsaken_ApplyCharacters", function()
    if not GM then return end
    
    for _, ply in pairs(player.GetAll()) do
        if ply.SelectedCharacter then
            if GM.ApplyCharacter then
                GM:ApplyCharacter(ply, ply.SelectedCharacter)
            end
            
            -- Выдаем оружие персонажа при начале раунда
            if GM.GiveCharacterWeapons then
                GM:GiveCharacterWeapons(ply, ply.SelectedCharacter)
                print("[GModsaken] Weapons given to " .. ply:Nick() .. " (character: " .. ply.SelectedCharacter .. ") at round start")
            end
        else
            -- Если не выбрал персонажа, оставляем без персонажа
            -- НЕ назначаем автоматически
            ply:ChatPrint("Вы не выбрали персонажа! Вы остаетесь без специальных способностей.")
        end
    end
end)

-- Сброс выбора персонажа при смерти
hook.Add("PlayerDeath", "GModsaken_ResetCharacter", function(ply)
    if IsValid(ply) then
        ply.SelectedCharacter = nil
    end
end)

-- Сброс выбора персонажа при возврате в лобби
hook.Add("GModsaken_LobbyReturn", "GModsaken_ResetCharacters", function(ply)
    if IsValid(ply) then
        ply.SelectedCharacter = nil
    end
end)

-- Команда для сброса выбора персонажа
concommand.Add("gmodsaken_reset_character", function(ply, cmd, args)
    if IsValid(ply) and not ply:IsSuperAdmin() then
        ply:ChatPrint("Только администраторы могут сбрасывать персонажей!")
        return
    end
    
    if #args < 1 then
        if IsValid(ply) then
            ply:ChatPrint("Использование: gmodsaken_reset_character <имя_игрока>")
        end
        return
    end
    
    local targetPly = player.GetByName(args[1])
    
    if not IsValid(targetPly) then
        if IsValid(ply) then
            ply:ChatPrint("Игрок не найден!")
        end
        return
    end
    
    targetPly.SelectedCharacter = nil
    
    if IsValid(ply) then
        ply:ChatPrint("Персонаж сброшен: " .. targetPly:Nick())
    end
    print("GModsaken: Сброс персонажа администратором: " .. targetPly:Nick())
end)

-- Команда для принудительного назначения персонажа
concommand.Add("gmodsaken_force_character", function(ply, cmd, args)
    if IsValid(ply) and not ply:IsSuperAdmin() then
        ply:ChatPrint("Только администраторы могут принудительно назначать персонажей!")
        return
    end
    
    if #args < 2 then
        if IsValid(ply) then
            ply:ChatPrint("Использование: gmodsaken_force_character <имя_игрока> <id_персонажа>")
        end
        return
    end
    
    local targetPly = player.GetByName(args[1])
    local characterID = args[2]
    
    if not IsValid(targetPly) then
        if IsValid(ply) then
            ply:ChatPrint("Игрок не найден!")
        end
        return
    end
    
    if not GM then
        if IsValid(ply) then
            ply:ChatPrint("Ошибка: GM не инициализирован!")
        end
        return
    end
    
    if not GM.GetCharacter then
        if IsValid(ply) then
            ply:ChatPrint("Ошибка: Функция GetCharacter не найдена!")
        end
        return
    end
    
    local character = GM:GetCharacter(characterID)
    if not character then
        if IsValid(ply) then
            ply:ChatPrint("Персонаж не найден!")
        end
        return
    end
    
    -- Применяем персонажа
    if GM.ApplyCharacter and GM:ApplyCharacter(targetPly, characterID) then
        if IsValid(ply) then
            ply:ChatPrint("Персонаж принудительно назначен: " .. targetPly:Nick() .. " -> " .. character.name)
        end
        print("GModsaken: Принудительное назначение персонажа администратором: " .. targetPly:Nick() .. " -> " .. characterID)
    else
        if IsValid(ply) then
            ply:ChatPrint("Ошибка назначения персонажа!")
        end
    end
end)

-- Команда для просмотра выбранного персонажа
concommand.Add("gmodsaken_my_character", function(ply, cmd, args)
    if not IsValid(ply) then return end
    
    if not GM then
        ply:ChatPrint("Ошибка: GM не инициализирован!")
        return
    end
    
    if ply.SelectedCharacter then
        if not GM.GetCharacter then
            ply:ChatPrint("Ошибка: Функция GetCharacter не найдена!")
            return
        end
        
        local character = GM:GetCharacter(ply.SelectedCharacter)
        if character then
            ply:ChatPrint("Ваш персонаж: " .. character.name)
            ply:ChatPrint("HP: " .. character.health)
        end
    else
        ply:ChatPrint("Вы не выбрали персонажа!")
    end
end)

-- Команда для списка персонажей
concommand.Add("gmodsaken_list_characters", function(ply, cmd, args)
    if not IsValid(ply) then return end
    
    if not GM then
        ply:ChatPrint("Ошибка: GM не инициализирован!")
        return
    end
    
    ply:ChatPrint("=== Доступные персонажи ===")
    
    if GM.GetAvailableCharacters then
        local availableCharacters = GM:GetAvailableCharacters(ply)
        for id, character in pairs(availableCharacters) do
            ply:ChatPrint(id .. " - " .. character.name)
        end
    else
        ply:ChatPrint("Ошибка: Функция GetAvailableCharacters не найдена!")
    end
end)

-- Команда для тестирования персонажа
concommand.Add("gmodsaken_test_character", function(ply, cmd, args)
    if not IsValid(ply) then return end
    
    if not GM then
        ply:ChatPrint("Ошибка: GM не инициализирован!")
        return
    end
    
    local characterName = args[1] or "Гордон Фримен"
    
    if not GM.GetCharacter then
        ply:ChatPrint("Ошибка: Функция GetCharacter не найдена!")
        return
    end
    
    local character = GM:GetCharacter(characterName)
    if not character then
        ply:ChatPrint("Персонаж не найден: " .. characterName)
        return
    end
    
    -- Применяем персонажа
    if GM.ApplyCharacter and GM:ApplyCharacter(ply, characterName) then
        ply:ChatPrint("=== ТЕСТ ПЕРСОНАЖА ===")
        ply:ChatPrint("Имя: " .. character.name)
        ply:ChatPrint("Здоровье: " .. character.health)
        ply:ChatPrint("Броня: " .. (character.armor or 0))
        ply:ChatPrint("Скорость: " .. (character.speed or 1.0))
        ply:ChatPrint("Текущее HP: " .. ply:Health())
        ply:ChatPrint("Текущая броня: " .. ply:Armor())
        ply:ChatPrint("=====================")
    else
        ply:ChatPrint("Ошибка применения персонажа!")
    end
end)

-- Применение персонажа к игроку
function GM:ApplyCharacterToPlayer(ply, characterName)
    if not IsValid(ply) then return end
    if not self.Characters[characterName] then return end
    
    local character = self.Characters[characterName]
    
    -- Устанавливаем модель персонажа
    if character.model then
        ply:SetModel(character.model)
    end
    
    -- Устанавливаем команду
    if character.team then
        ply:SetTeam(character.team)
    end
    
    -- Применяем характеристики
    if character.stats then
        ply:SetWalkSpeed(character.stats.walkSpeed or 200)
        ply:SetRunSpeed(character.stats.runSpeed or 400)

        if character.team == GM.TEAM_KILLER then
            ply:SetHealth(GM:GetConfig("Characters.Killer.Health", 3000))
            ply:SetMaxHealth(GM:GetConfig("Characters.Killer.Health", 3000))
            ply:SetArmor(GM:GetConfig("Characters.Killer.Armor", 150))
        else
            ply:SetHealth(GM:GetConfig("Characters.Survivor.Health", 100))
            ply:SetMaxHealth(GM:GetConfig("Characters.Survivor.Health", 100))
            ply:SetArmor(GM:GetConfig("Characters.Survivor.Armor", 0))
        end
    end
    
    -- Применяем броню
    self:ApplyArmorToPlayer(ply, characterName)
    
    -- Сохраняем выбранного персонажа
    ply.SelectedCharacter = characterName
    
    -- Выдаем оружие персонажа ТОЛЬКО во время игры
    if self.GameState == "PLAYING" then
        self:GiveCharacterWeapons(ply, characterName)
        print("[GModsaken] Weapons given to " .. ply:Nick() .. " (character: " .. characterName .. ") during gameplay")
    else
        print("[GModsaken] Character applied to " .. ply:Nick() .. " (character: " .. characterName .. ") in lobby - weapons will be given at round start")
    end
    
    print("[GModsaken] Applied character " .. characterName .. " to " .. ply:Nick())
end 