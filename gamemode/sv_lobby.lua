--[[
    GModsaken - Lobby System (Server)
    Copyright (C) 2024 GModsaken Contributors
]]

-- Get GM table reference
local GM = _G.GM or GAMEMODE
_G.GM = GM
_G.GAMEMODE = GM

-- Создаем сетевые сообщения
util.AddNetworkString("GModsaken_UpdateStamina")
util.AddNetworkString("GModsaken_BlindPlayer")
util.AddNetworkString("GModsaken_ShowRadar")
util.AddNetworkString("GModsaken_PlayChaseMusic")
util.AddNetworkString("GModsaken_StopChaseMusic")

-- Game state variables (only set if not already set)
if not GM.LobbyTime then
    GM.LobbyTime = 30  -- Default lobby time
end
if not GM.RoundTime then
    GM.RoundTime = 600  -- Default round time
end
if not GM.EndTime then
    GM.EndTime = 10  -- Default end time
end
if not GM.MinPlayers then
    GM.MinPlayers = 2  -- Default minimum players
end
GM.GameState = GM.GameState or "LOBBY"

-- Local timer variables
local lobbyTimer = 0
local roundTimer = 0
local endTimer = 0
local gameStartTime = 0

-- Initialize lobby if not already done
function GM:InitializeLobby()
    print("GModsaken: Инициализация лобби")
    
    -- Устанавливаем состояние лобби
    GM.GameState = "LOBBY"
    
    -- Сбрасываем таймеры
    lobbyTimer = 0
    roundTimer = 0
    endTimer = 0
    
    -- Возвращаем всех игроков в лобби
    for _, ply in pairs(player.GetAll()) do
        if IsValid(ply) then
            -- Убираем оружие
            ply:StripWeapons()
            
            -- Делаем всех наблюдателями
            ply:SetTeam(self.TEAM_SPECTATOR)
            
            -- Сбрасываем выбор персонажа
            ply.SelectedCharacter = nil
            
            -- Настраиваем как наблюдателя
            if self.SetupSpectator then
                self:SetupSpectator(ply)
            end
            
            -- Телепортируем в лобби
            local spawnPoint = self:GetLobbySpawnPoint()
            if spawnPoint then
                ply:SetPos(spawnPoint)
            end
        end
    end
    
    -- Проверяем, можно ли начать новую игру
    timer.Simple(2, function()
        if self.CheckGameStart then
            self:CheckGameStart()
        end
    end)
    
    -- Уведомляем всех игроков
    self:BroadcastGameState()
    
    print("GModsaken: Лобби инициализировано")
end

-- Setup spectator settings for a player
function GM:SetupSpectator(ply)
    if not IsValid(ply) then return end
    
    -- Make player a spectator
    ply:SetMoveType(MOVETYPE_NOCLIP)
    ply:SetNoDraw(true)
    ply:SetNotSolid(true)
    ply:GodEnable()
    ply:SetNoTarget(true)
    
    -- Disable player's collision
    ply:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)
    
    -- Remove any weapons
    ply:StripWeapons()
    
    -- Set spectator mode
    if SERVER then
        ply:Spectate(OBS_MODE_ROAMING)
        ply:SpectateEntity(NULL)
    end
    
    print("GModsaken: Spectator mode set for " .. (IsValid(ply) and ply:Nick() or "unknown player"))
end

-- Отправка игрока в лобби
function GM:SendPlayerToLobby(ply, skipSpawn)
    if not IsValid(ply) then return end
    
    print("[GModsaken] Sending player to lobby: " .. ply:Nick())
    
    -- Set team first
    local teamId = GM.TEAM_SPECTATOR or 1
    if not isnumber(teamId) then
        teamId = 1
        print("[GModsaken] WARNING: TEAM_SPECTATOR is not a number, using 1")
    end
    
    ply:SetTeam(teamId)
    
    -- Set up as spectator
    self:SetupSpectator(ply)
    
    if not skipSpawn then
        local spawnPoint = self:GetLobbySpawnPoint()
        if spawnPoint then
            ply:SetPos(spawnPoint)
        else
            print("[GModsaken] WARNING: No lobby spawn points found!")
        end
    end
    
    -- Set player properties
    ply:SetHealth(100)
    ply:SetMaxHealth(100)
    ply:SetArmor(0)
    
    -- Clear weapons
    ply:StripWeapons()
    
    -- Reset character selection
    ply.SelectedCharacter = nil
    
    -- Notify client
    if util.NetworkStringToID("GModsaken_UpdateGameState") > 0 then
        net.Start("GModsaken_UpdateGameState")
        net.WriteString(GM.GameState or "LOBBY")
        net.WriteInt(lobbyTimer or 0, 32)
        net.Send(ply)
    else
        print("[GModsaken] WARNING: Network string 'GModsaken_UpdateGameState' not found!")
    end
    
    -- Call lobby return hook
    hook.Call("GModsaken_LobbyReturn", GM, ply)
end

-- Проверка готовности к старту
function GM:CheckGameStart()
    local gm = GAMEMODE or GM
    if not gm then 
        print("Геймод не инициализирован в CheckGameStart!")
        return 
    end
    
    local playerCount = #player.GetAll()
    local minPlayers = gm.MinPlayers or 2  -- Default to 2 players if not set
    
    if playerCount >= minPlayers then
        if gm.GameState == "LOBBY" then
            gm.GameState = "PREPARING"
            lobbyTimer = gm.LobbyTime or 30
            gameStartTime = CurTime()
            
            -- Уведомляем всех игроков
            if gm.BroadcastGameState then
                gm:BroadcastGameState()
            end
            
            print("GModsaken: Начинается подготовка к игре (" .. lobbyTimer .. " сек)")
        end
    else
        if gm.GameState == "PREPARING" then
            gm.GameState = "LOBBY"
            lobbyTimer = 0
            
            -- Уведомляем всех игроков
            if gm.BroadcastGameState then
                gm:BroadcastGameState()
            end
            
            print("GModsaken: Недостаточно игроков для старта")
        end
    end
end

-- Назначение ролей
function GM:AssignRoles()
    local players = player.GetAll()
    local playerCount = #players
    
    if playerCount < GM.MinPlayers then
        return false
    end
    
    -- Выбираем случайного убийцу
    local killerIndex = math.random(1, playerCount)
    local killer = players[killerIndex]
    
    print("GModsaken: Назначаем роли для " .. playerCount .. " игроков")
    
    -- Принудительно отключаем GodMode у всех игроков перед назначением ролей
    for _, ply in pairs(players) do
        if IsValid(ply) and ply:HasGodMode() then
            ply:GodDisable()
            print("GModsaken: Отключен GodMode у " .. ply:Nick() .. " перед назначением роли")
        end
    end
    
    -- Назначаем роли
    for i, ply in pairs(players) do
        if i == killerIndex then
            print("GModsaken: " .. ply:Nick() .. " становится убийцей")
            ply:SetTeam(GM.TEAM_KILLER)
            self:SetupKillerPlayer(ply)
        else
            print("GModsaken: " .. ply:Nick() .. " становится выжившим")
            ply:SetTeam(GM.TEAM_SURVIVOR)
            self:SetupSurvivorPlayer(ply)
        end
    end
    
    print("GModsaken: Роли назначены. Убийца: " .. killer:Nick())
    return true
end

-- Настройка убийцы
function GM:SetupKillerPlayer(ply)
    if not IsValid(ply) then return end
    
    print("GModsaken: Настройка убийцы для " .. ply:Nick())
    
    -- Устанавливаем команду
    ply:SetTeam(GM.TEAM_KILLER)
    
    -- Убираем старое оружие
    ply:StripWeapons()
    
    -- Нормальный режим игры (убираем ноклип)
    ply:SetMoveType(MOVETYPE_WALK)
    ply:SetNoDraw(false)
    ply:DrawShadow(true)
    ply:SetNotSolid(false)
    ply:SetNoTarget(false)
    ply:GodDisable()
    ply:SetCollisionGroup(COLLISION_GROUP_PLAYER)
    
    -- Отключаем режим наблюдателя
    if SERVER then
        ply:UnSpectate()
    end
    
    -- ПОЛНОСТЬЮ ПЕРЕОПРЕДЕЛЯЕМ характеристики убийцы (игнорируем выбранного персонажа)
    ply:SetHealth(3000)
    ply:SetMaxHealth(3000)
    ply:SetArmor(0)
    
    -- Устанавливаем скорость убийцы (0.9 из характеристик Мясного)
    ply:SetWalkSpeed(200 * 0.9)
    ply:SetRunSpeed(400 * 0.9)
    
    -- Инициализируем стамину для убийцы (225)
    if GM.InitializeStamina then
        GM:InitializeStamina(ply)
        -- Принудительно устанавливаем стамину убийцы
        ply.Stamina = 225
        ply.MaxStamina = 225
        if GM.UpdateStamina then
            GM:UpdateStamina(ply)
        end
    end
    
    -- Даем базовое оружие убийце
    ply:Give("weapon_physcannon")
    
    -- ВСЕГДА даем топор убийце, независимо от выбранного персонажа
    print("GModsaken: Выдаем топор убийце " .. ply:Nick())
    ply:Give("weapon_gmodsaken_axe")
    ply:SelectWeapon("weapon_gmodsaken_axe")
    
    -- ВСЕГДА применяем модель убийцы, независимо от выбранного персонажа
    ply:SetModel("models/zombie/poison.mdl")
    print("GModsaken: Применена модель убийцы для " .. ply:Nick())
    
    -- Сбрасываем выбор персонажа для убийцы (он не нужен)
    ply.SelectedCharacter = nil
    
    -- Телепортируем на точку спавна убийцы
    local spawnPoint = self:GetTeamSpawnPoint(GM.TEAM_KILLER)
    if spawnPoint then
        ply:SetPos(spawnPoint)
    else
        -- Если нет специальной точки, используем случайную
        local spawnPoints = ents.FindByClass("info_player_start")
        if #spawnPoints > 0 then
            ply:SetPos(spawnPoints[math.random(1, #spawnPoints)]:GetPos())
        end
    end
    
    -- Уведомляем игрока
    ply:ChatPrint("Вы стали УБИЙЦЕЙ! Уничтожьте всех выживших!")
    ply:ChatPrint("Здоровье: 3000, Стамина: 225, Оружие: Топор")
    
    -- F4 доступно только в лобби
    if GM.GameState == "LOBBY" then
        ply:ChatPrint("Нажмите F4 для выбора персонажа-убийцы!")
    end
end

-- Настройка выжившего
function GM:SetupSurvivorPlayer(ply)
    if not IsValid(ply) then return end
    
    print("GModsaken: Настройка выжившего для " .. ply:Nick())
    
    -- Устанавливаем команду
    ply:SetTeam(GM.TEAM_SURVIVOR)
    
    -- Убираем старое оружие
    ply:StripWeapons()
    
    -- Нормальный режим игры (убираем ноклип)
    ply:SetMoveType(MOVETYPE_WALK)
    ply:SetNoDraw(false)
    ply:DrawShadow(true)
    ply:SetNotSolid(false)
    ply:SetNoTarget(false)
    ply:GodDisable()
    ply:SetCollisionGroup(COLLISION_GROUP_PLAYER)
    
    -- Отключаем режим наблюдателя
    if SERVER then
        ply:UnSpectate()
    end
    
    -- Устанавливаем характеристики выжившего (переопределяем любые предыдущие настройки)
    ply:SetHealth(100)
    ply:SetMaxHealth(100)
    ply:SetArmor(0)
    
    -- Устанавливаем скорость выжившего (базовая)
    ply:SetWalkSpeed(200)
    ply:SetRunSpeed(400)
    
    -- Инициализируем стамину для выжившего (100)
    if GM.InitializeStamina then
        GM:InitializeStamina(ply)
        -- Принудительно устанавливаем стамину выжившего
        ply.Stamina = 100
        ply.MaxStamina = 100
        if GM.UpdateStamina then
            GM:UpdateStamina(ply)
        end
    end
    
    -- Даем базовое оружие выжившим
    ply:Give("weapon_physcannon")
    
    -- Применяем модель персонажа если выбран
    if ply.SelectedCharacter then
        local character = self:GetCharacter(ply.SelectedCharacter)
        if character and character.model then
            ply:SetModel(character.model)
            print("GModsaken: Применена модель " .. character.model .. " для " .. ply:Nick())
        end
    else
        -- Модель по умолчанию для выжившего
        ply:SetModel("models/player/group01/male_02.mdl")
        print("GModsaken: Применена модель по умолчанию для выжившего " .. ply:Nick())
    end
    
    -- Телепортируем на точку спавна выживших
    local spawnPoint = self:GetTeamSpawnPoint(GM.TEAM_SURVIVOR)
    if spawnPoint then
        ply:SetPos(spawnPoint)
    else
        -- Если нет специальной точки, используем случайную
        local spawnPoints = ents.FindByClass("info_player_start")
        if #spawnPoints > 0 then
            ply:SetPos(spawnPoints[math.random(1, #spawnPoints)]:GetPos())
        end
    end
    
    -- Уведомляем игрока
    ply:ChatPrint("Вы ВЫЖИВШИЙ! Спасайтесь от убийцы!")
    
    -- F4 доступно только в лобби
    if GM.GameState == "LOBBY" then
        ply:ChatPrint("Нажмите F4 для выбора персонажа-выжившего!")
    end
end

-- Начало раунда
function GM:StartRound()
    if not self:AssignRoles() then
        print("GModsaken: Не удалось назначить роли, раунд не начался")
        return false
    end
    
    GM.GameState = "PLAYING"
    roundTimer = GM.RoundTime
    gameStartTime = CurTime() -- Устанавливаем время начала раунда
    
    print("GModsaken: Раунд начался! Время: " .. roundTimer .. " сек, startTime: " .. gameStartTime)
    
    -- Применяем персонажей
    hook.Call("GModsaken_RoundStart", GAMEMODE)
    
    -- Выдаем оружие персонажей в начале раунда
    for _, ply in pairs(player.GetAll()) do
        if ply.SelectedCharacter and self.GiveCharacterWeapon then
            print("GModsaken: Выдаем оружие персонажа " .. ply.SelectedCharacter .. " игроку " .. ply:Nick() .. " в начале раунда")
            self:GiveCharacterWeapon(ply, ply.SelectedCharacter)
        else
            -- Если не выбрал персонажа, даем лом по умолчанию
            print("GModsaken: Выдаем лом по умолчанию игроку " .. ply:Nick() .. " в начале раунда")
            ply:Give("weapon_gmodsaken_crowbar")
            ply:SelectWeapon("weapon_gmodsaken_crowbar")
        end
        
        -- Даем грави пушку для манипуляций с объектами
        ply:Give("weapon_physcannon")
    end
    
    -- Инициализируем квесты
    if self.InitializeQuests then
        timer.Simple(2, function() -- Небольшая задержка для стабилизации
            self:InitializeQuests()
        end)
    end
    
    -- Вызываем хук для начала игры
    hook.Call("GModsaken_GameStarted", GAMEMODE)
    
    -- Уведомляем всех игроков
    self:BroadcastGameState()
    
    print("GModsaken: Раунд начался! Время: " .. roundTimer .. " сек")
    return true
end

-- Окончание раунда
function GM:EndRound(winner)
    -- Проверяем, не завершен ли уже раунд
    if GM.GameState == "ENDING" then
        print("GModsaken: Раунд уже завершается, игнорируем повторный вызов EndRound")
        return
    end
    
    GM.GameState = "ENDING"
    endTimer = GM.EndTime
    
    local winnerText = "Ничья"
    if winner == "KILLER" then
        winnerText = "Победа УБИЙЦЫ!"
    elseif winner == "SURVIVORS" then
        winnerText = "Победа ВЫЖИВШИХ!"
    elseif winner == "TIMEOUT" then
        winnerText = "Время истекло! Победа ВЫЖИВШИХ!"
    end
    
    -- Уведомляем всех игроков
    for _, ply in pairs(player.GetAll()) do
        ply:ChatPrint("=== " .. winnerText .. " ===")
    end
    
    print("GModsaken: Раунд окончен. " .. winnerText)
    
    -- Очищаем квесты
    if self.CleanupQuests then
        self:CleanupQuests()
    end
    
    -- Вызываем хук для окончания игры
    hook.Call("GModsaken_GameEnded", GAMEMODE)
    
    -- Очищаем все постройки
    for _, ent in pairs(ents.FindByClass("npc_turret_floor")) do
        if IsValid(ent) and (ent.IsGModsakenTurret or ent.IsGModsakenDispenser) then
            ent:Remove()
        end
    end
    
    for _, ent in pairs(ents.FindByClass("npc_turret_ceiling")) do
        if IsValid(ent) and (ent.IsGModsakenTurret or ent.IsGModsakenDispenser) then
            ent:Remove()
        end
    end
    
    print("GModsaken: Все постройки очищены")
    
    -- Останавливаем музыку Мясного у всех игроков
    for _, ply in pairs(player.GetAll()) do
        net.Start("GModsaken_StopChaseMusic")
        net.Send(ply)
    end
    
    -- Возвращаем всех игроков в лобби
    for _, ply in pairs(player.GetAll()) do
        if IsValid(ply) then
            -- Убираем оружие
            ply:StripWeapons()
            
            -- Делаем всех наблюдателями
            ply:SetTeam(self.TEAM_SPECTATOR)
            
            -- Сбрасываем выбор персонажа
            ply.SelectedCharacter = nil
            
            -- Настраиваем как наблюдателя
            if self.SetupSpectator then
                self:SetupSpectator(ply)
            end
            
            -- Телепортируем в лобби
            local spawnPoint = self:GetLobbySpawnPoint()
            if spawnPoint then
                ply:SetPos(spawnPoint)
            end
        end
    end
    
    -- Уведомляем всех игроков
    self:BroadcastGameState()
end

-- Проверка условий победы
function GM:CheckWinConditions()
    if GM.GameState ~= "PLAYING" then 
        return 
    end
    
    -- Добавляем задержку после начала раунда (10 секунд)
    if CurTime() - (gameStartTime or 0) < 10 then
        return
    end
    
    local survivors = self:GetTeamPlayers(GM.TEAM_SURVIVOR)
    local killers = self:GetTeamPlayers(GM.TEAM_KILLER)
    
    -- Проверяем, что есть игроки в командах
    if #survivors == 0 or #killers == 0 then
        print("GModsaken Debug: Нет игроков в командах - survivors: " .. #survivors .. ", killers: " .. #killers)
        return
    end
    
    -- Проверяем, есть ли живые выжившие
    local aliveSurvivors = 0
    for _, ply in pairs(survivors) do
        if IsValid(ply) and ply:Alive() and ply:Health() > 0 and ply:GetPos():Length() > 0 then
            aliveSurvivors = aliveSurvivors + 1
        end
    end
    
    -- Проверяем, есть ли живые убийцы
    local aliveKillers = 0
    for _, ply in pairs(killers) do
        if IsValid(ply) and ply:Alive() and ply:Health() > 0 and ply:GetPos():Length() > 0 then
            aliveKillers = aliveKillers + 1
        end
    end
    
    print("GModsaken Debug: aliveSurvivors=" .. aliveSurvivors .. ", aliveKillers=" .. aliveKillers .. ", roundTimer=" .. roundTimer)
    
    -- Дополнительная проверка: раунд должен длиться минимум 30 секунд
    if CurTime() - (gameStartTime or 0) < 30 then
        return
    end
    
    -- Условия победы (только если прошло достаточно времени и есть игроки)
    if aliveSurvivors == 0 and aliveKillers > 0 then
        print("GModsaken: Все выжившие мертвы, победа убийцы!")
        self:EndRound("KILLER")
    elseif aliveKillers == 0 and aliveSurvivors > 0 then
        print("GModsaken: Все убийцы мертвы, победа выживших!")
        self:EndRound("SURVIVORS")
    elseif roundTimer <= 0 then
        print("GModsaken: Время истекло, победа выживших!")
        self:EndRound("TIMEOUT")
    end
end

-- Проверка музыки Мясного
function GM:CheckMyasnoiMusic()
    if GM.GameState ~= "PLAYING" then 
        return 
    end
    
    local killers = self:GetTeamPlayers(GM.TEAM_KILLER)
    local survivors = self:GetTeamPlayers(GM.TEAM_SURVIVOR)
    
    -- Ищем Мясного (убийцу с топором)
    local myasnoi = nil
    for _, killer in pairs(killers) do
        if IsValid(killer) and killer:Alive() then
            local weapon = killer:GetActiveWeapon()
            if IsValid(weapon) and weapon:GetClass() == "weapon_gmodsaken_axe" then
                myasnoi = killer
                break
            end
        end
    end
    
    if not myasnoi then
        -- Если Мясного нет, останавливаем музыку у всех
        for _, ply in pairs(player.GetAll()) do
            net.Start("GModsaken_StopChaseMusic")
            net.Send(ply)
        end
        return
    end
    
    local chaseDistance = 300 -- Дистанция для воспроизведения музыки
    local playersNearMyasnoi = {}
    
    -- Проверяем только выживших на близость к Мясному
    for _, ply in pairs(survivors) do
        if IsValid(ply) and ply:Alive() then
            local distance = myasnoi:GetPos():Distance(ply:GetPos())
            if distance <= chaseDistance then
                table.insert(playersNearMyasnoi, ply)
            end
        end
    end
    
    -- Если есть выжившие рядом с Мясным, включаем музыку у всех игроков
    if #playersNearMyasnoi > 0 then
        for _, ply in pairs(player.GetAll()) do
            net.Start("GModsaken_PlayChaseMusic")
            net.Send(ply)
        end
    else
        -- Если никого нет рядом, останавливаем музыку у всех
        for _, ply in pairs(player.GetAll()) do
            net.Start("GModsaken_StopChaseMusic")
            net.Send(ply)
        end
    end
end

-- Отправка состояния игры всем игрокам
function GM:BroadcastGameState()
    for _, ply in pairs(player.GetAll()) do
        net.Start("GModsaken_UpdateGameState")
        net.WriteString(GM.GameState)
        
        if GM.GameState == "PREPARING" then
            net.WriteInt(lobbyTimer, 32)
        elseif GM.GameState == "PLAYING" then
            net.WriteInt(roundTimer, 32)
        elseif GM.GameState == "ENDING" then
            net.WriteInt(endTimer, 32)
        else
            net.WriteInt(0, 32)
        end
        
        net.Send(ply)
    end
end

-- Логика турелей и раздатчиков
hook.Add("Think", "GModsaken_TurretDispenserLogic", function()
    -- Обрабатываем турели
    for _, ent in pairs(ents.FindByClass("npc_turret_floor")) do
        if IsValid(ent) and ent.IsGModsakenTurret then
            -- Логика турели
            if CurTime() - (ent.LastDamageTime or 0) >= 1.0 then -- Каждую секунду
                local killers = {}
                for _, ply in pairs(player.GetAll()) do
                    if IsValid(ply) and ply:Team() == GAMEMODE.TEAM_KILLER and ply:Alive() then
                        local distance = ent:GetPos():Distance(ply:GetPos())
                        if distance <= 500 then
                            table.insert(killers, ply)
                        end
                    end
                end
                
                if #killers > 0 then
                    local target = killers[1]
                    target:TakeDamage(10, ent, ent)
                    
                    -- Замедление
                    if GAMEMODE.SlowPlayer then
                        GAMEMODE:SlowPlayer(target, 3.0, 0.8)
                    end
                    
                    ent:EmitSound("weapons/turret/turret_fire1.wav")
                    ent.LastDamageTime = CurTime()
                end
            end
        end
    end
    
    -- Обрабатываем раздатчики
    for _, ent in pairs(ents.FindByClass("npc_turret_ceiling")) do
        if IsValid(ent) and ent.IsGModsakenDispenser then
            -- Логика раздатчика
            if CurTime() - (ent.LastHealTime or 0) >= 2.0 then -- Каждые 2 секунды
                for _, ply in pairs(player.GetAll()) do
                    if IsValid(ply) and ply:Team() == GAMEMODE.TEAM_SURVIVOR and ply:Alive() then
                        local distance = ent:GetPos():Distance(ply:GetPos())
                        if distance <= 200 then
                            -- Медленное восстановление здоровья
                            if ply:Health() < ply:GetMaxHealth() then
                                ply:SetHealth(math.min(ply:GetMaxHealth(), ply:Health() + 5))
                            end
                            
                            -- Медленное восстановление брони
                            if ply:Armor() < 100 then
                                ply:SetArmor(math.min(100, ply:Armor() + 2))
                            end
                        end
                    end
                end
                ent.LastHealTime = CurTime()
            end
        end
    end
end)

-- Разрушение турелей и раздатчиков убийцами
hook.Add("EntityTakeDamage", "GModsaken_TurretDispenserDamage", function(target, dmginfo)
    if IsValid(target) and (target:GetClass() == "npc_turret_floor" or target:GetClass() == "npc_turret_ceiling") and 
       (target.IsGModsakenTurret or target.IsGModsakenDispenser) then
        local attacker = dmginfo:GetAttacker()
        if IsValid(attacker) and attacker:IsPlayer() and attacker:Team() == GAMEMODE.TEAM_KILLER then
            -- Убийца может разрушить постройки с двойным уроном
            dmginfo:ScaleDamage(2.0)
            attacker:ChatPrint("Постройка разрушена!")
        end
    end
end)

-- Основной таймер игры
local function GameTimer()
    local gm = GAMEMODE or GM
    if not gm then 
        print("Геймод не инициализирован!")
        return 
    end
    
    if gm.GameState == "LOBBY" then
        -- В лобби проверяем, можно ли начать игру
        if gm.CheckGameStart then
            gm:CheckGameStart()
        end
        
    elseif gm.GameState == "PREPARING" then
        lobbyTimer = lobbyTimer - 1
        
        if lobbyTimer <= 0 then
            gm:StartRound()
        else
            -- Обновляем состояние каждые 5 секунд
            if lobbyTimer % 5 == 0 then
                gm:BroadcastGameState()
            end
        end
        
    elseif gm.GameState == "PLAYING" then
        roundTimer = roundTimer - 1
        
        if roundTimer <= 0 then
            gm:EndRound("TIMEOUT")
        else
            -- Проверяем условия победы каждую секунду
            gm:CheckWinConditions()
            
            -- Проверяем музыку Мясного каждые 3 секунды (реже для оптимизации)
            if roundTimer % 3 == 0 then
                gm:CheckMyasnoiMusic()
            end
            
            -- Обновляем состояние каждые 10 секунд
            if roundTimer % 10 == 0 then
                gm:BroadcastGameState()
            end
        end
        
    elseif gm.GameState == "ENDING" then
        endTimer = endTimer - 1
        
        if endTimer <= 0 then
            gm:InitializeLobby()
        else
            -- Обновляем состояние каждые 2 секунды
            if endTimer % 2 == 0 then
                gm:BroadcastGameState()
            end
        end
    else
        print("GModsaken Debug: Неизвестное состояние игры: " .. (gm.GameState or "nil"))
    end
end

timer.Create("GModsaken_GameTimer", 1, 0, GameTimer)

-- Хуки для управления игроками
hook.Add("PlayerInitialSpawn", "GModsaken_PlayerSpawn", function(ply)
    timer.Simple(1, function()
        local gm = GAMEMODE or GM
        if not gm then 
            print("Геймод не инициализирован в PlayerInitialSpawn!")
            return 
        end
        if IsValid(ply) then
            gm:SendPlayerToLobby(ply)
            gm:CheckGameStart()
        end
    end)
end)

hook.Add("PlayerDisconnected", "GModsaken_PlayerDisconnect", function(ply)
    timer.Simple(1, function()
        local gm = GAMEMODE or GM
        if gm and gm.CheckGameStart then
            gm:CheckGameStart()
        end
    end)
end)

-- Команда для принудительного старта игры
concommand.Add("gmodsaken_force_start", function(ply, cmd, args)
    if IsValid(ply) and not ply:IsAdmin() then
        ply:ChatPrint("Только администраторы могут принудительно запускать игру!")
        return
    end
    
    if GM.GameState == "LOBBY" then
        GM.GameState = "PREPARING"
        lobbyTimer = GM.LobbyTime
        GM:BroadcastGameState()
        print("GModsaken: Принудительный старт игры администратором")
    end
end)

-- Команда для принудительного окончания раунда
concommand.Add("gmodsaken_force_end", function(ply, cmd, args)
    if IsValid(ply) and not ply:IsAdmin() then
        ply:ChatPrint("Только администраторы могут принудительно завершать раунды!")
        return
    end
    
    if GM.GameState == "PLAYING" then
        local winner = "TIMEOUT"
        if #args > 0 then
            winner = args[1] -- "KILLER", "SURVIVORS", "TIMEOUT"
        end
        
        GM:EndRound(winner)
        print("GModsaken: Принудительное завершение раунда администратором. Победитель: " .. winner)
    else
        if IsValid(ply) then
            ply:ChatPrint("Раунд не активен!")
        end
    end
end)

-- Команда для принудительного назначения убийцы
concommand.Add("gmodsaken_force_killer", function(ply, cmd, args)
    if IsValid(ply) and not ply:IsAdmin() then
        ply:ChatPrint("Только администраторы могут принудительно назначать убийцу!")
        return
    end
    
    if #args < 1 then
        if IsValid(ply) then
            ply:ChatPrint("Использование: gmodsaken_force_killer <имя_игрока>")
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
    
    -- Сбрасываем всех в наблюдатели
    for _, player in pairs(player.GetAll()) do
        player:SetTeam(GM.TEAM_SPECTATOR)
    end
    
    -- Назначаем убийцу
    targetPly:SetTeam(GM.TEAM_KILLER)
    GM:SetupKillerPlayer(targetPly)
    
    -- Остальные становятся выжившими
    for _, player in pairs(player.GetAll()) do
        if player ~= targetPly then
            player:SetTeam(GM.TEAM_SURVIVOR)
            GM:SetupSurvivorPlayer(player)
        end
    end
    
    if IsValid(ply) then
        ply:ChatPrint("Убийца принудительно назначен: " .. targetPly:Nick())
    end
    print("GModsaken: Принудительное назначение убийцы администратором: " .. targetPly:Nick())
end)

-- Команда для принудительного перезапуска лобби
concommand.Add("gmodsaken_restart_lobby", function(ply, cmd, args)
    if IsValid(ply) and not ply:IsAdmin() then
        ply:ChatPrint("Только администраторы могут перезапускать лобби!")
        return
    end
    
    GM:InitializeLobby()
    if IsValid(ply) then
        ply:ChatPrint("Лобби перезапущено!")
    end
    print("GModsaken: Лобби перезапущено администратором")
end)

-- Открыть меню выбора персонажа
function GM:OpenCharacterMenu(ply)
    if not IsValid(ply) then return end
    
    -- Отправляем игроку команду на открытие меню
    net.Start("GModsaken_OpenCharacterMenu")
    net.Send(ply)
    
    print("GModsaken: Открыто меню выбора персонажа для " .. ply:Nick())
end

-- Команда для принудительного перехода в режим игры
concommand.Add("gmodsaken_force_play", function(ply, cmd, args)
    if IsValid(ply) and not ply:IsAdmin() then
        ply:ChatPrint("Только администраторы могут принудительно запускать режим игры!")
        return
    end
    
    if GM.GameState == "PREPARING" or GM.GameState == "LOBBY" then
        GM:StartRound()
        if IsValid(ply) then
            ply:ChatPrint("Режим игры принудительно запущен!")
        end
        print("GModsaken: Принудительный запуск режима игры администратором")
    else
        if IsValid(ply) then
            ply:ChatPrint("Нельзя запустить режим игры в текущем состоянии!")
        end
    end
end)

-- Команда для отладки состояния игры
concommand.Add("gmodsaken_debug_state", function(ply, cmd, args)
    if not IsValid(ply) then return end
    
    if not GM then
        ply:ChatPrint("GM не инициализирован!")
        return
    end
    
    ply:ChatPrint("=== ОТЛАДКА СОСТОЯНИЯ ИГРЫ ===")
    ply:ChatPrint("GameState: " .. tostring(GM.GameState))
    ply:ChatPrint("TEAM_SPECTATOR: " .. tostring(GM.TEAM_SPECTATOR))
    ply:ChatPrint("TEAM_SURVIVOR: " .. tostring(GM.TEAM_SURVIVOR))
    ply:ChatPrint("TEAM_KILLER: " .. tostring(GM.TEAM_KILLER))
    
    if GM.GameState == "PREPARING" then
        ply:ChatPrint("Lobby Timer: " .. tostring(lobbyTimer))
    elseif GM.GameState == "PLAYING" then
        ply:ChatPrint("Round Timer: " .. tostring(roundTimer))
    elseif GM.GameState == "ENDING" then
        ply:ChatPrint("End Timer: " .. tostring(endTimer))
    end
    
    ply:ChatPrint("=== ИГРОКИ ===")
    for _, player in pairs(player.GetAll()) do
        if IsValid(player) then
            local teamName = "Неизвестно"
            if player:Team() == GM.TEAM_SURVIVOR then
                teamName = "Выживший"
            elseif player:Team() == GM.TEAM_KILLER then
                teamName = "Убийца"
            elseif player:Team() == GM.TEAM_SPECTATOR then
                teamName = "Наблюдатель"
            end
            
            ply:ChatPrint(player:Nick() .. " - " .. teamName .. " (Team ID: " .. player:Team() .. ")")
        end
    end
    ply:ChatPrint("========================")
end)

-- Команда для отладки ролей
concommand.Add("gmodsaken_debug_roles", function(ply, cmd, args)
    if IsValid(ply) and not ply:IsAdmin() then
        ply:ChatPrint("Только администраторы могут использовать команды отладки!")
        return
    end
    
    local gm = GAMEMODE or GM
    if not gm then
        print("GModsaken Debug: GM table is nil!")
        if IsValid(ply) then
            ply:ChatPrint("Ошибка: GM table is nil!")
        end
        return
    end
    
    local debugInfo = {
        "=== GModsaken Debug Roles ===",
        "Player Count: " .. #player.GetAll(),
        "=== Players ==="
    }
    
    for _, player in pairs(player.GetAll()) do
        if IsValid(player) then
            local teamName = "Unknown"
            if player:Team() == gm.TEAM_SURVIVOR then
                teamName = "Survivor"
            elseif player:Team() == gm.TEAM_KILLER then
                teamName = "Killer"
            elseif player:Team() == gm.TEAM_SPECTATOR then
                teamName = "Spectator"
            end
            
            local weapon = "None"
            if IsValid(player:GetActiveWeapon()) then
                weapon = player:GetActiveWeapon():GetClass()
            end
            
            table.insert(debugInfo, player:Nick() .. " - Team: " .. teamName .. " - Weapon: " .. weapon .. " - Character: " .. (player.SelectedCharacter or "none"))
        end
    end
    
    for _, line in pairs(debugInfo) do
        print("GModsaken Debug: " .. line)
        if IsValid(ply) then
            ply:ChatPrint(line)
        end
    end
end)

-- Команда для принудительного применения персонажа с оружием
concommand.Add("gmodsaken_force_apply_full", function(ply, cmd, args)
    if not IsValid(ply) then return end
    
    if not GM then
        ply:ChatPrint("GM не инициализирован!")
        return
    end
    
    if not ply.SelectedCharacter then
        ply:ChatPrint("Вы не выбрали персонажа!")
        return
    end
    
    -- Применяем персонажа полностью
    if GM.ApplyCharacter then
        GM:ApplyCharacter(ply, ply.SelectedCharacter)
        
        -- Дополнительно выдаем оружие
        if GM.GiveCharacterWeapon then
            GM:GiveCharacterWeapon(ply, ply.SelectedCharacter)
        end
        
        -- Применяем модель
        local character = GM:GetCharacter(ply.SelectedCharacter)
        if character and character.model then
            ply:SetModel(character.model)
        end
        
        ply:ChatPrint("Персонаж полностью применен!")
    else
        ply:ChatPrint("Функция ApplyCharacter не найдена!")
    end
end)

-- Команда для принудительного применения персонажа в лобби
concommand.Add("gmodsaken_force_apply_lobby", function(ply, cmd, args)
    if not IsValid(ply) then return end
    
    if not GM then
        ply:ChatPrint("GM не инициализирован!")
        return
    end
    
    if not ply.SelectedCharacter then
        ply:ChatPrint("Вы не выбрали персонажа!")
        return
    end
    
    -- Проверяем, что игрок в лобби
    if GM.GameState ~= "LOBBY" and GM.GameState ~= "PREPARING" then
        ply:ChatPrint("Эта команда доступна только в лобби!")
        return
    end
    
    -- Применяем персонажа полностью
    if GM.ApplyCharacter then
        GM:ApplyCharacter(ply, ply.SelectedCharacter)
        
        -- Дополнительно выдаем оружие
        if GM.GiveCharacterWeapon then
            GM:GiveCharacterWeapon(ply, ply.SelectedCharacter)
        end
        
        -- Применяем модель
        local character = GM:GetCharacter(ply.SelectedCharacter)
        if character and character.model then
            ply:SetModel(character.model)
        end
        
        ply:ChatPrint("Персонаж применен в лобби!")
    else
        ply:ChatPrint("Функция ApplyCharacter не найдена!")
    end
end)

-- Команда для принудительного применения характеристик убийцы
concommand.Add("gmodsaken_force_killer_stats", function(ply, cmd, args)
    if not IsValid(ply) then return end
    
    if not GM then
        ply:ChatPrint("GM не инициализирован!")
        return
    end
    
    -- Проверяем, что игрок - убийца
    if ply:Team() ~= GM.TEAM_KILLER then
        ply:ChatPrint("Эта команда только для убийц!")
        return
    end
    
    -- Принудительно применяем характеристики убийцы
    ply:SetHealth(3000)
    ply:SetMaxHealth(3000)
    ply:SetArmor(0)
    ply:SetWalkSpeed(200 * 0.9)
    ply:SetRunSpeed(400 * 0.9)
    
    -- Принудительно устанавливаем стамину убийцы
    if GM.InitializeStamina then
        GM:InitializeStamina(ply)
        ply.Stamina = 225
        ply.MaxStamina = 225
        if GM.UpdateStamina then
            GM:UpdateStamina(ply)
        end
    end
    
    -- Принудительно выдаем топор
    ply:StripWeapons()
    ply:Give("weapon_physcannon")
    ply:Give("weapon_gmodsaken_axe")
    ply:SelectWeapon("weapon_gmodsaken_axe")
    
    -- Принудительно применяем модель убийцы
    ply:SetModel("models/zombie/poison.mdl")
    
    -- Сбрасываем выбор персонажа
    ply.SelectedCharacter = nil
    
    ply:ChatPrint("Характеристики убийцы применены принудительно!")
    ply:ChatPrint("Здоровье: 3000, Стамина: 225, Оружие: Топор")
end)

-- Команда для отключения GodMode у всех игроков
concommand.Add("gmodsaken_disable_godmode", function(ply, cmd, args)
    if not IsValid(ply) then return end
    
    if not GM then
        ply:ChatPrint("GM не инициализирован!")
        return
    end
    
    -- Отключаем GodMode у всех игроков
    for _, player in pairs(player.GetAll()) do
        if IsValid(player) and player:HasGodMode() then
            player:GodDisable()
            print("GModsaken: Отключен GodMode у " .. player:Nick())
        end
    end
    
    ply:ChatPrint("GodMode отключен у всех игроков!")
end)

-- Команда для удаления всех построек игрока
concommand.Add("gmodsaken_remove_all_buildings", function(ply, cmd, args)
    if not IsValid(ply) then return end
    
    if not GM then
        ply:ChatPrint("GM не инициализирован!")
        return
    end
    
    local removedCount = 0
    
    -- Удаляем все турели игрока
    for _, ent in pairs(ents.FindByClass("npc_turret_floor")) do
        if IsValid(ent) and ent.Owner == ply and ent.IsGModsakenTurret then
            ent:Remove()
            removedCount = removedCount + 1
        end
    end
    
    -- Удаляем все раздатчики игрока
    for _, ent in pairs(ents.FindByClass("prop_physics")) do
        if IsValid(ent) and ent.Owner == ply and ent.IsDispenser then
            ent:Remove()
            removedCount = removedCount + 1
        end
    end
    
    ply:ChatPrint("Удалено построек: " .. removedCount)
end)

-- Команда для проверки здоровья всех игроков
concommand.Add("gmodsaken_check_health", function(ply, cmd, args)
    if not IsValid(ply) then return end
    
    if not GM then
        ply:ChatPrint("GM не инициализирован!")
        return
    end
    
    ply:ChatPrint("=== ЗДОРОВЬЕ ИГРОКОВ ===")
    for _, player in pairs(player.GetAll()) do
        if IsValid(player) then
            local teamName = "Неизвестно"
            if player:Team() == GM.TEAM_SURVIVOR then
                teamName = "Выживший"
            elseif player:Team() == GM.TEAM_KILLER then
                teamName = "Убийца"
            elseif player:Team() == GM.TEAM_SPECTATOR then
                teamName = "Наблюдатель"
            end
            
            local godMode = player:HasGodMode() and " (GodMode)" or ""
            ply:ChatPrint(player:Nick() .. " - " .. teamName .. " - HP: " .. player:Health() .. "/" .. player:GetMaxHealth() .. godMode)
        end
    end
    ply:ChatPrint("========================")
end)

-- Команда для тестирования музыки Мясного
concommand.Add("gmodsaken_test_music", function(ply, cmd, args)
    if IsValid(ply) and not ply:IsAdmin() then
        ply:ChatPrint("Только администраторы могут тестировать музыку!")
        return
    end
    
    if not IsValid(ply) then
        print("GModsaken: Тестирование музыки Мясного для всех игроков")
        for _, player in pairs(player.GetAll()) do
            net.Start("GModsaken_PlayChaseMusic")
            net.Send(player)
        end
        
        -- Останавливаем через 10 секунд
        timer.Simple(10, function()
            for _, player in pairs(player.GetAll()) do
                net.Start("GModsaken_StopChaseMusic")
                net.Send(player)
            end
            print("GModsaken: Тестирование музыки завершено")
        end)
    else
        ply:ChatPrint("Тестирование музыки Мясного...")
        net.Start("GModsaken_PlayChaseMusic")
        net.Send(ply)
        
        -- Останавливаем через 10 секунд
        timer.Simple(10, function()
            if IsValid(ply) then
                net.Start("GModsaken_StopChaseMusic")
                net.Send(ply)
                ply:ChatPrint("Тестирование музыки завершено")
            end
        end)
    end
end)

-- Команда для принудительной остановки музыки
concommand.Add("gmodsaken_stop_music", function(ply, cmd, args)
    if IsValid(ply) and not ply:IsAdmin() then
        ply:ChatPrint("Только администраторы могут останавливать музыку!")
        return
    end
    
    for _, player in pairs(player.GetAll()) do
        net.Start("GModsaken_StopChaseMusic")
        net.Send(player)
    end
    
    if IsValid(ply) then
        ply:ChatPrint("Музыка Мясного принудительно остановлена!")
    end
    print("GModsaken: Музыка Мясного принудительно остановлена администратором")
end)

-- Команда для тестирования аптечки медика
concommand.Add("gmodsaken_test_medkit", function(ply, cmd, args)
    if not IsValid(ply) then return end
    
    if not GM then
        ply:ChatPrint("GM не инициализирован!")
        return
    end
    
    -- Проверяем, что игрок - медик
    if ply:Team() ~= GM.TEAM_SURVIVOR then
        ply:ChatPrint("Эта команда только для выживших!")
        return
    end
    
    -- Проверяем, что у игрока есть аптечка
    local weapon = ply:GetActiveWeapon()
    if not IsValid(weapon) or weapon:GetClass() ~= "weapon_gmodsaken_medkit" then
        ply:ChatPrint("У вас нет аптечки медика!")
        return
    end
    
    -- Тестируем лечение
    local currentHealth = ply:Health()
    local maxHealth = ply:GetMaxHealth()
    
    if currentHealth >= maxHealth then
        ply:ChatPrint("Вы полностью здоровы! Текущее здоровье: " .. currentHealth .. "/" .. maxHealth)
    else
        ply:ChatPrint("Вы можете лечиться! Текущее здоровье: " .. currentHealth .. "/" .. maxHealth)
    end
    
    -- Показываем информацию об аптечке
    ply:ChatPrint("=== ТЕСТ АПТЕЧКИ ===")
    ply:ChatPrint("ЛКМ - Лечить себя (50 HP)")
    ply:ChatPrint("ПКМ - Лечить тиммейта (50 HP)")
    ply:ChatPrint("R - Информация")
    ply:ChatPrint("Кулдаун: 10 секунд")
    ply:ChatPrint("Дистанция лечения: 150 единиц")
end)

-- Команда для тестирования ауры мэра
concommand.Add("gmodsaken_test_mayor_aura", function(ply, cmd, args)
    if not IsValid(ply) then return end
    
    if not GM then
        ply:ChatPrint("GM не инициализирован!")
        return
    end
    
    -- Проверяем, что игрок - мэр
    if ply:Team() ~= GM.TEAM_SURVIVOR then
        ply:ChatPrint("Эта команда только для выживших!")
        return
    end
    
    -- Проверяем, что у игрока есть телефон
    local weapon = ply:GetActiveWeapon()
    if not IsValid(weapon) or weapon:GetClass() ~= "weapon_gmodsaken_phone" then
        ply:ChatPrint("У вас нет телефона мэра!")
        return
    end
    
    -- Тестируем ауру
    ply:ChatPrint("=== ТЕСТ АУРЫ МЭРА ===")
    ply:ChatPrint("ПКМ - Активировать ауру брони")
    ply:ChatPrint("Кулдаун: " .. (weapon.AuraCooldown or 20) .. " секунд")
    ply:ChatPrint("Длительность: " .. (weapon.AuraDuration or 15) .. " секунд")
    ply:ChatPrint("Радиус: " .. (weapon.AuraRadius or 200) .. " единиц")
    ply:ChatPrint("Эффект: +1 брони и +5 HP в секунду тиммейтам")
    
    -- Показываем статус ауры
    if weapon.AuraActive then
        local timeLeft = weapon.AuraEndTime - CurTime()
        if timeLeft > 0 then
            ply:ChatPrint("Аура активна! Осталось: " .. math.ceil(timeLeft) .. " секунд")
        else
            ply:ChatPrint("Аура неактивна")
        end
    else
        ply:ChatPrint("Аура неактивна")
    end
end)

-- Команда для принудительного переключения состояния игры
concommand.Add("gmodsaken_set_state", function(ply, cmd, args)
    if not IsValid(ply) or not ply:IsAdmin() then
        ply:ChatPrint("Только администраторы могут изменять состояние игры!")
        return
    end
    
    if not GM then
        ply:ChatPrint("GM не инициализирован!")
        return
    end
    
    local newState = args[1]
    if not newState then
        ply:ChatPrint("Использование: gmodsaken_set_state <LOBBY|PREPARING|PLAYING|ENDING>")
        return
    end
    
    if newState == "LOBBY" then
        GM.GameState = "LOBBY"
        ply:ChatPrint("Состояние игры изменено на LOBBY")
    elseif newState == "PREPARING" then
        GM.GameState = "PREPARING"
        lobbyTimer = GM.LobbyTime or 30
        ply:ChatPrint("Состояние игры изменено на PREPARING")
    elseif newState == "PLAYING" then
        GM.GameState = "PLAYING"
        roundTimer = GM.RoundTime or 300
        ply:ChatPrint("Состояние игры изменено на PLAYING")
    elseif newState == "ENDING" then
        GM.GameState = "ENDING"
        endTimer = GM.EndTime or 10
        ply:ChatPrint("Состояние игры изменено на ENDING")
    else
        ply:ChatPrint("Неверное состояние! Используйте: LOBBY, PREPARING, PLAYING, ENDING")
        return
    end
    
    GM:BroadcastGameState()
    print("GModsaken: Администратор " .. ply:Nick() .. " изменил состояние игры на " .. newState)
end)

-- Команда для принудительной выдачи грави пушки
concommand.Add("gmodsaken_give_gravgun", function(ply, cmd, args)
    if not IsValid(ply) then return end
    
    if not GM then
        ply:ChatPrint("GM не инициализирован!")
        return
    end
    
    -- Проверяем, что игра идет
    if GM.GameState ~= "PLAYING" then
        ply:ChatPrint("Грави пушка выдается только во время игры!")
        return
    end
    
    -- Проверяем, что игрок выживший
    if not GM:IsSurvivor(ply) then
        ply:ChatPrint("Грави пушка доступна только выжившим!")
        return
    end
    
    -- Выдаем грави пушку
    if not ply:HasWeapon("weapon_physcannon") then
        ply:Give("weapon_physcannon")
        ply:ChatPrint("Грави пушка выдана!")
        print("GModsaken: Грави пушка выдана игроку " .. ply:Nick())
    else
        ply:ChatPrint("У вас уже есть грави пушка!")
    end
end) 