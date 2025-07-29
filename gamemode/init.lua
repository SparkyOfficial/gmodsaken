--[[
    GModsaken - Garry's Mod Gamemode (Server)
    Copyright (C) 2024 GModsaken Contributors
    
    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.
    
    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.
    
    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
]]

print("[GModsaken] Server init.lua starting...")

-- Ensure GM table exists in global scope
if not _G.GM then
    _G.GM = {}
    print("[GModsaken] Created new GM table")
end
_G.GAMEMODE = _G.GM

-- Include shared code first (this will define the basic GM structure)
print("[GModsaken] Including shared.lua...")
include("shared.lua")

-- Now get local reference to GM table
local GM = _G.GM
_G.GAMEMODE = GM

-- Debug print
print("[GModsaken] Server initialization - GM table " .. (GM and "found" or "NOT FOUND"))

-- Include shared files first
print("[GModsaken] Including shared files...")
include("sh_characters.lua")  -- Characters must be loaded first
include("sh_teams.lua")
include("sh_stamina.lua")
include("sh_weapons.lua")  -- Weapons and abilities system
include("sh_content.lua")  -- Custom content loading
include("sh_quests.lua")   -- Quest system
include("sh_spawnmenu.lua") -- Spawn menu system
include("sh_music.lua")    -- Music system

-- Include effects
include("spawnmenu/effects/disintegration.lua") -- Disintegration effects
print("[GModsaken] Disintegration effects loaded")

-- Include server-side components AFTER shared files
if SERVER then
    print("[GModsaken] Including server files...")
    include("sv_lobby.lua")
    include("sv_characters.lua")
    include("sv_admin.lua")
    include("sv_quests.lua")  -- Quest system (server)
    include("sv_spawnmenu.lua") -- Spawn menu system (server)
end

-- Include client-side components
if CLIENT then
    print("[GModsaken] Including client files...")
    include("cl_character_menu.lua")
    include("cl_hud.lua")
    include("cl_quests.lua")  -- Quest system (client)
    include("cl_spawnmenu.lua") -- Spawn menu system (client)
    include("cl_music.lua")   -- Music system (client)
end

-- Debug info
print("[GModsaken] Server initialization complete")
print("GM table: " .. tostring(GM))
print("GAMEMODE table: " .. tostring(GAMEMODE))

-- Set up team constants
GM.TEAM_SPECTATOR = 1
GM.TEAM_SURVIVOR = 2
GM.TEAM_KILLER = 3

-- Verify GM table after includes
if not GM then
    ErrorNoHalt("[GModsaken] CRITICAL: GM table is nil after includes!")
    GM = {}
    _G.GM = GM
    _G.GAMEMODE = GM
end

-- Debug print after includes
print("[GModsaken] Server initialization - After includes")

-- Настройка игрока-наблюдателя
function GM:SetupSpectator(ply)
    if not IsValid(ply) then return end
    
    -- Set up spectator properties
    ply:SetMoveType(MOVETYPE_NOCLIP)
    ply:SetNoDraw(true)
    ply:DrawShadow(false)
    ply:StripWeapons()
    
    -- Disable collisions and targeting
    ply:SetNotSolid(true)
    ply:SetNoTarget(true)
    ply:GodEnable()
    
    -- Set up spectator mode
    if SERVER then
        ply:Spectate(OBS_MODE_ROAMING)
        ply:SpectateEntity(NULL)
    end
    
    -- Set collision group
    ply:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)
    
    print("[GModsaken] Set up spectator mode for " .. (IsValid(ply) and ply:Nick() or "unknown player"))
    
    -- Устанавливаем здоровье и броню
    ply:SetHealth(100)
    ply:SetMaxHealth(100)
    ply:SetArmor(0)
    
    -- Отключаем урон
    ply:GodEnable()
    
    -- Телепортируем на точку спавна лобби
    local spawnPoint = self:GetLobbySpawnPoint()
    if spawnPoint then
        ply:SetPos(spawnPoint)
    end
    
    print("GModsaken: Настроен наблюдатель для " .. ply:Nick())
end

-- Настройка выжившего
function GM:SetupSurvivor(ply)
    if not IsValid(ply) then return end
    
    -- Нормальный режим игры
    ply:SetMoveType(MOVETYPE_WALK)
    ply:SetNoDraw(false)
    ply:DrawShadow(true)
    
    -- Включаем коллизии
    ply:SetNotSolid(false)
    ply:SetNoTarget(false)
    ply:GodDisable()
    
    -- Отключаем режим наблюдателя
    if SERVER then
        ply:UnSpectate()
    end
    
    -- Нормальная группа коллизий
    ply:SetCollisionGroup(COLLISION_GROUP_PLAYER)
    
    print("[GModsaken] Set up survivor mode for " .. (IsValid(ply) and ply:Nick() or "unknown player"))
end

-- Настройка убийцы
function GM:SetupKiller(ply)
    if not IsValid(ply) then return end
    
    -- Нормальный режим игры
    ply:SetMoveType(MOVETYPE_WALK)
    ply:SetNoDraw(false)
    ply:DrawShadow(true)
    
    -- Включаем коллизии
    ply:SetNotSolid(false)
    ply:SetNoTarget(false)
    ply:GodDisable()
    
    -- Отключаем режим наблюдателя
    if SERVER then
        ply:UnSpectate()
    end
    
    -- Нормальная группа коллизий
    ply:SetCollisionGroup(COLLISION_GROUP_PLAYER)
    
    print("[GModsaken] Set up killer mode for " .. (IsValid(ply) and ply:Nick() or "unknown player"))
end

-- Отправка игрока в лобби
function GM:SendPlayerToLobby(ply, skipSpawn)
    if not IsValid(ply) then return end
    print("GModsaken: Отправка игрока " .. ply:Nick() .. " в лобби")
    
    -- Устанавливаем команду наблюдателя
    self.TEAM_SPECTATOR = self.TEAM_SPECTATOR or 1
    ply:SetTeam(self.TEAM_SPECTATOR)
    
    -- Сбрасываем выбор персонажа
    ply.SelectedCharacter = nil
    
    -- Устанавливаем состояние игры
    self.GameState = self.GameState or "LOBBY"
    
    -- Отправляем обновление состояния
    if util.NetworkStringToID("GModsaken_UpdateGameState") ~= 0 then
        net.Start("GModsaken_UpdateGameState")
        net.WriteString(self.GameState)
        net.WriteInt(0, 32)
        net.Send(ply)
    else
        print("[GModsaken] WARNING: Network string 'GModsaken_UpdateGameState' not found!")
    end
    
    -- Настраиваем как наблюдателя
    if self.SetupSpectator then
        self:SetupSpectator(ply)
    else
        print("[GModsaken] WARNING: SetupSpectator function not found!")
    end
end

-- Открыть меню выбора персонажа для игрока
function GM:OpenCharacterMenu(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    
    -- Проверяем, зарегистрировано ли сетевое сообщение
    if not util.NetworkStringToID("GModsaken_OpenCharacterMenu") or 
       util.NetworkStringToID("GModsaken_OpenCharacterMenu") == 0 then
        print("[GModsaken] WARNING: Network string 'GModsaken_OpenCharacterMenu' not found!")
        return
    end
    
    -- Отправляем команду на открытие меню
    net.Start("GModsaken_OpenCharacterMenu")
    net.Send(ply)
    
    print("GModsaken: Отправлен запрос на открытие меню персонажа для " .. ply:Nick())
end

-- Инициализация гейммода на сервере
function GM:Initialize()
    print("GModsaken Survival Horror гейммод загружен!")
    
    -- Инициализируем команды
    self:CreateTeams()
    
    -- Инициализируем лобби
    if self.InitializeLobby then
        self:InitializeLobby()
    end
    
    -- Создаем сетевые сообщения
    if SERVER then
        util.AddNetworkString("GModsaken_UpdateGameState")
        util.AddNetworkString("GModsaken_UpdateStamina")
        util.AddNetworkString("GModsaken_SelectCharacter")
        util.AddNetworkString("GModsaken_CharacterSelected")
        util.AddNetworkString("GModsaken_OpenCharacterMenu")
        util.AddNetworkString("GModsaken_BlindPlayer")
        util.AddNetworkString("GModsaken_ShowRadar")
        util.AddNetworkString("GModsaken_PlayChaseMusic")
        util.AddNetworkString("GModsaken_StopChaseMusic")
    end
    
    print("GModsaken: Система инициализирована")
end

-- Настройка команд
function GM:PlayerInitialSpawn(ply)
    print("GModsaken: Игрок " .. ply:Nick() .. " присоединился")
    
    -- Игрок автоматически попадает в лобби
    timer.Simple(1, function()
        if IsValid(ply) and self.SendPlayerToLobby then
            self:SendPlayerToLobby(ply)
        end
    end)
end

function GM:PlayerSpawn(ply)
    if not IsValid(ply) then return end
    print("GModsaken: Игрок " .. ply:Nick() .. " заспавнился")
    
    -- Проверяем команду игрока и настраиваем соответственно
    if ply:Team() == self.TEAM_SPECTATOR then
        -- Наблюдатель
        if self.SetupSpectator then
            self:SetupSpectator(ply)
        end
    elseif ply:Team() == self.TEAM_SURVIVOR then
        -- Выживший
        if self.SetupSurvivor then
            self:SetupSurvivor(ply)
        end
        -- Применяем персонажа если выбран
        if ply.SelectedCharacter and self.ApplyCharacter then
            self:ApplyCharacter(ply, ply.SelectedCharacter)
        end
    elseif ply:Team() == self.TEAM_KILLER then
        -- Убийца
        if self.SetupKiller then
            self:SetupKiller(ply)
        end
        -- Применяем персонажа если выбран
        if ply.SelectedCharacter and self.ApplyCharacter then
            self:ApplyCharacter(ply, ply.SelectedCharacter)
        end
    else
        -- По умолчанию отправляем в лобби
        if self.SendPlayerToLobby then
            self:SendPlayerToLobby(ply)
        end
    end
end

-- Обработка смерти игрока
function GM:PlayerDeath(ply, inflictor, attacker)
    if not IsValid(ply) then return end
    
    -- В режиме survival horror нет автовозрождения
    -- Игрок остается мертвым до конца раунда
    
    if self.IsSurvivor and self:IsSurvivor(ply) then
        ply:ChatPrint("Вы погибли! Ожидайте окончания раунда.")
    elseif self.IsKiller and self:IsKiller(ply) then
        ply:ChatPrint("Вы погибли! Выжившие победили!")
        
        -- Если умер Мясной, останавливаем музыку
        local weapon = ply:GetActiveWeapon()
        if IsValid(weapon) and weapon:GetClass() == "weapon_gmodsaken_axe" then
            for _, player in pairs(player.GetAll()) do
                net.Start("GModsaken_StopChaseMusic")
                net.Send(player)
            end
            print("GModsaken: Мясной умер, музыка остановлена")
        end
    end
    
    -- Проверяем условия победы
    timer.Simple(1, function()
        if self.CheckWinConditions then
            self:CheckWinConditions()
        end
    end)
end

-- Обработка смены команды
function GM:PlayerCanJoinTeam(ply, teamID)
    if self.CanPlayerSwitchTeam then
        return self:CanPlayerSwitchTeam(ply, teamID)
    end
    return true
end

-- Обработка урона
function GM:EntityTakeDamage(target, dmginfo)
    local attacker = dmginfo:GetAttacker()
    
    -- Проверяем, является ли атакующим игроком
    if IsValid(attacker) and attacker:IsPlayer() then
        -- Выжившие не могут наносить урон друг другу
        if self.IsSurvivor and self:IsSurvivor(attacker) and self:IsSurvivor(target) then
            dmginfo:SetDamage(0)
            attacker:ChatPrint("Вы не можете атаковать других выживших!")
            return
        end
        
        -- Убийца может атаковать всех
        if self.IsKiller and self:IsKiller(attacker) then
            -- Убийца наносит больше урона
            dmginfo:SetDamage(dmginfo:GetDamage() * 2)
        end
    end
end

-- Команда для перезапуска лобби
concommand.Add("gmodsaken_restart_lobby", function(ply, cmd, args)
    if IsValid(ply) and not ply:IsAdmin() then
        ply:ChatPrint("Только администраторы могут перезапускать лобби!")
        return
    end
    
    if GM and GM.InitializeLobby then
        GM:InitializeLobby()
        print("GModsaken: Лобби перезапущено администратором")
    end
end)

-- Команда для проверки состояния игры
concommand.Add("gmodsaken_status", function(ply, cmd, args)
    if not IsValid(ply) then return end
    
    if GM then
        local status = "Состояние игры: " .. (GM.GameState or "UNKNOWN")
        local playerCount = #player.GetAll()
        local survivors = GM.GetTeamPlayerCount and GM:GetTeamPlayerCount(GM.TEAM_SURVIVOR) or 0
        local killers = GM.GetTeamPlayerCount and GM:GetTeamPlayerCount(GM.TEAM_KILLER) or 0
        
        ply:ChatPrint(status)
        ply:ChatPrint("Игроков: " .. playerCount .. " | Выживших: " .. survivors .. " | Убийц: " .. killers)
    else
        ply:ChatPrint("Геймод не инициализирован!")
    end
end)

-- Команда для открытия меню персонажей
concommand.Add("gmodsaken_open_menu", function(ply, cmd, args)
    if not IsValid(ply) then return end
    
    if GM and GM.GameState and (GM.GameState == "LOBBY" or GM.GameState == "PREPARING") then
        if not ply.SelectedCharacter then
            -- Отправляем команду клиенту для открытия меню
            net.Start("GModsaken_OpenCharacterMenu")
            net.Send(ply)
        else
            ply:ChatPrint("Вы уже выбрали персонажа!")
        end
    else
        ply:ChatPrint("Меню персонажей доступно только в лобби!")
    end
end)

-- Инициализация при загрузке
hook.Add("Initialize", "GModsaken_ServerInit", function()
    timer.Simple(1, function()
        if GM then
            GM:Initialize()
        end
    end)
end)

-- Хук для остановки музыки при смене оружия Мясного
hook.Add("PlayerSwitchWeapon", "GModsaken_MyasnoiWeaponSwitch", function(ply, oldWeapon, newWeapon)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    
    -- Если Мясной сменил оружие с топора на другое, останавливаем музыку
    if IsValid(oldWeapon) and oldWeapon:GetClass() == "weapon_gmodsaken_axe" then
        if IsValid(newWeapon) and newWeapon:GetClass() ~= "weapon_gmodsaken_axe" then
            for _, player in pairs(player.GetAll()) do
                net.Start("GModsaken_StopChaseMusic")
                net.Send(player)
            end
            print("GModsaken: Мясной сменил оружие, музыка остановлена")
        end
    end
end)

-- Обработчик спавна пропов через Q-меню
net.Receive("GModsaken_SpawnProp", function(len, ply)
    if not IsValid(ply) then return end
    if ply:Team() ~= GM.TEAM_SURVIVOR then return end
    if GM.GameState ~= "PLAYING" then return end
    
    -- Создаем проп
    local prop = ents.Create("prop_physics")
    if IsValid(prop) then
        local tr = ply:GetEyeTrace()
        local pos = tr.HitPos + tr.HitNormal * 10
        
        prop:SetModel("models/props_junk/wooden_box01a.mdl")
        prop:SetPos(pos)
        prop:SetAngles(Angle(0, 0, 0))
        prop:Spawn()
        
        -- Делаем проп неуязвимым для заморозки
        prop:SetKeyValue("spawnflags", "256")
        
        -- Помечаем как проп из Q-меню
        prop.IsQMenuProp = true
        prop.Creator = ply
        
        -- Уведомляем игрока
        ply:ChatPrint("Проп создан! Убийца может его разрушить.")
        
        print("GModsaken: " .. ply:Nick() .. " создал проп через Q-меню")
    end
end) 