--[[
    GModsaken - Garry's Mod Gamemode (Shared)
    Copyright (C) 2024 GModsaken Contributors
]]

AddCSLuaFile()

-- Инициализация GM если не существует
if not _G.GM then
    _G.GM = {}
end
local GM = _G.GM
_G.GAMEMODE = GM

GM.Name 		= "GModsaken"
GM.Author 		= "GModsaken Contributors"
GM.Email 		= ""
GM.Website 		= ""
GM.FolderName 	= "gmodsaken"

-- Базовые настройки гейммода
GM.Base = "base"
GM.TeamBased = true
GM.AllowAutoTeam = false
GM.AllowSpectating = true
GM.SelectClass = true
GM.SecondsBetweenTeamSwitches = 10
GM.GameLength = 600 -- 10 минут
GM.RoundLimit = 5
GM.VotingDelay = 5
GM.ShowTeamName = true

-- Настройки режима
GM.GameState = "LOBBY" -- LOBBY, PREPARING, PLAYING, ENDING
GM.MinPlayers = 3
GM.LobbyTime = 30 -- секунды подготовки
GM.RoundTime = 600 -- 10 минут раунда
GM.EndTime = 10 -- секунды показа результатов

-- Команды
GM.TEAM_SPECTATOR = 1
GM.TEAM_SURVIVOR = 2
GM.TEAM_KILLER = 3

-- Координаты лобби
GM.LobbySpawns = {
    Vector(1481.364258, -1630.240356, 1200.031250),
    Vector(1473.909302, -1791.937500, 1200.031250),
    Vector(1478.233154, -1211.780518, 1200.031250),
    Vector(1317.965942, -1311.466797, 1200.031250),
    Vector(1262.208130, -1523.776245, 1200.031250),
    Vector(1193.471680, -1720.119629, 1200.031250)
}

-- Координаты спавна выживших
GM.SurvivorSpawns = {
    Vector(818.924072, 465.022003, -79.968750),
    Vector(820.428101, 414.251984, -79.968750),
    Vector(821.934143, 363.977325, -79.968750),
    Vector(823.799805, 301.708038, -79.968750),
    Vector(825.665466, 239.438751, -79.968750),
    Vector(828.160034, 156.178879, -79.968750),
    Vector(830.205383, 87.912292, -79.968750),
    Vector(831.891357, 31.640354, -79.968750),
    Vector(834.206238, -45.622147, -79.968750),
    Vector(836.161743, -110.890083, -79.968750)
}

-- Координаты спавна убийцы
GM.KillerSpawn = Vector(-3588.982422, -1517.920776, -79.586121)

-- Статистика игроков
GM.PlayerStats = {}

-- Настройки по умолчанию (будут переопределены настройками из .txt файла)
GM.DefaultMap = "gm_construct"
GM.AutoRespawn = false -- Отключаем автовозрождение для режима
GM.RespawnTime = 3

-- Добавляем файлы для клиента
AddCSLuaFile("sh_characters.lua")
AddCSLuaFile("sh_teams.lua")
AddCSLuaFile("sh_stamina.lua")
AddCSLuaFile("sh_spawnmenu.lua")
AddCSLuaFile("cl_character_menu.lua")
AddCSLuaFile("cl_hud.lua")
AddCSLuaFile("cl_spawnmenu.lua")
AddCSLuaFile("sh_content.lua")

-- Создание команд (базовая функция)
function GM:CreateTeams()
    team.SetUp(self.TEAM_SURVIVOR, "Выжившие", Color(0, 150, 255), true)
    team.SetSpawnPoint(self.TEAM_SURVIVOR, {"info_player_start", "info_player_deathmatch"})
    
    team.SetUp(self.TEAM_KILLER, "Убийца", Color(255, 0, 0), false)
    team.SetSpawnPoint(self.TEAM_KILLER, {"info_player_start", "info_player_deathmatch"})
    
    team.SetUp(self.TEAM_SPECTATOR, "Наблюдатели", Color(128, 128, 128), false)
    team.SetSpawnPoint(self.TEAM_SPECTATOR, {"info_player_start", "info_player_deathmatch"})
end

-- Helper function to check if a player is the killer
function GM:IsKiller(ply)
    return IsValid(ply) and ply:Team() == self.TEAM_KILLER
end

-- Helper function to check if a player is a survivor
function GM:IsSurvivor(ply)
    return IsValid(ply) and ply:Team() == self.TEAM_SURVIVOR
end

-- Helper function to check if a player is a spectator
function GM:IsSpectator(ply)
    return IsValid(ply) and ply:Team() == self.TEAM_SPECTATOR
end

-- Функция для рекурсивного включения файлов (отключена для ручного контроля)
-- function recursiveInclusion( scanDirectory, isGamemode )
-- 	-- Null-coalescing for optional argument
-- 	isGamemode = isGamemode or false
-- 	
-- 	local queue = { scanDirectory }
-- 	
-- 	-- Loop until queue is cleared
-- 	while #queue > 0 do
-- 		-- For each directory in the queue...
-- 		for i, directory in pairs( queue ) do
-- 			-- print( "Scanning directory: ", directory )
-- 			
-- 			local files, directories = file.Find( directory .. "/*", "LUA" )
-- 			
-- 			-- Include files within this directory
-- 			for _, fileName in pairs( files ) do
-- 				if fileName != "shared.lua" and fileName != "init.lua" and fileName != "cl_init.lua" then
-- 					-- print( "Found: ", fileName )
-- 					
-- 					-- Create a relative path for inclusion functions
-- 					-- Also handle pathing case for including gamemode folders
-- 					local relativePath = directory .. "/" .. fileName
-- 					if isGamemode then
-- 						relativePath = string.gsub( directory .. "/" .. fileName, GM.FolderName .. "/gamemode/", "" )
-- 					end
-- 					
-- 					-- Include server files
-- 					if string.match( fileName, "^sv" ) then
-- 						if SERVER then
-- 							include( relativePath )
-- 						end
-- 					end
-- 					
-- 					-- Include shared files
-- 					if string.match( fileName, "^sh" ) then
-- 						AddCSLuaFile( relativePath )
-- 						include( relativePath )
-- 					end
-- 					
-- 					-- Include client files
-- 					if string.match( fileName, "^cl" ) then
-- 						AddCSLuaFile( relativePath )
-- 						
-- 						if CLIENT then
-- 							include( relativePath )
-- 						end
-- 					end
-- 				end
-- 			end
-- 			
-- 			-- Append directories within this directory to the queue
-- 			for _, subdirectory in pairs( directories ) do
-- 				-- print( "Found directory: ", subdirectory )
-- 				table.insert( queue, directory .. "/" .. subdirectory )
-- 			end
-- 			
-- 			-- Remove this directory from the queue
-- 			break
-- 		end
-- 	end
-- end

-- Загрузка настроек из .txt файла
if SERVER then
    -- Создаем ConVars для настроек
    CreateConVar("gmodsaken_default_map", "gm_construct", FCVAR_REPLICATED, "Default map for GModsaken gamemode")
    CreateConVar("gmodsaken_auto_respawn", "0", FCVAR_REPLICATED, "Auto respawn players after death")
    CreateConVar("gmodsaken_respawn_time", "3", FCVAR_REPLICATED, "Time in seconds before respawn")
    CreateConVar("gmodsaken_min_players", "3", FCVAR_REPLICATED, "Minimum players to start round")
    CreateConVar("gmodsaken_lobby_time", "30", FCVAR_REPLICATED, "Lobby preparation time")
    CreateConVar("gmodsaken_round_time", "600", FCVAR_REPLICATED, "Round duration in seconds")
end

-- Отключаем автоматическую загрузку файлов - теперь файлы загружаются вручную в init.lua и cl_init.lua
-- recursiveInclusion( GM.FolderName .. "/gamemode", true )

-- Обновляем настройки из ConVars и инициализируем команды
hook.Add("Initialize", "GModsakenLoadSettings", function()
    if SERVER then
        GM.DefaultMap = GetConVar("gmodsaken_default_map"):GetString()
        GM.AutoRespawn = GetConVar("gmodsaken_auto_respawn"):GetBool()
        GM.RespawnTime = GetConVar("gmodsaken_respawn_time"):GetInt()
        GM.MinPlayers = GetConVar("gmodsaken_min_players"):GetInt()
        GM.LobbyTime = GetConVar("gmodsaken_lobby_time"):GetInt()
        GM.RoundTime = GetConVar("gmodsaken_round_time"):GetInt()
        
        print("GModsaken: Настройки загружены из ConVars")
    end
    
    -- Создаем команды
    if GM.CreateTeams then
        GM:CreateTeams()
    end
end)

-- Подключаем shared файлы
include("sh_spawnmenu.lua")

-- Инициализация гейммода
hook.Add("Initialize", "GModsakenInit", function()
    print("GModsaken: Initializing gamemode...")
    
    -- Проверяем, что GM существует
    if not GM then
        print("GModsaken: ERROR - GM table not found!")
        return
    end
    
    -- Инициализируем лобби на сервере
    if SERVER then
        timer.Simple(1, function()
            if GM.InitializeLobby then
                GM:InitializeLobby()
                print("GModsaken: Lobby initialized")
            else
                print("GModsaken: ERROR - InitializeLobby function not found!")
            end
        end)
    end
    
    print("GModsaken: Gamemode initialization complete")
end)

-- Команда для тестирования инициализации
concommand.Add("gmodsaken_test", function(ply, cmd, args)
    if not IsValid(ply) then return end
    
    ply:ChatPrint("=== GModsaken Test ===")
    
    if GM then
        ply:ChatPrint("✓ GM table exists")
        ply:ChatPrint("GM.Name: " .. (GM.Name or "NOT SET"))
        ply:ChatPrint("GM.GameState: " .. (GM.GameState or "NOT SET"))
        
        if GM.CreateTeams then
            ply:ChatPrint("✓ GM.CreateTeams function exists")
        else
            ply:ChatPrint("✗ GM.CreateTeams function does not exist!")
        end
        
        if GM.IsKiller then
            ply:ChatPrint("✓ GM.IsKiller function exists")
        else
            ply:ChatPrint("✗ GM.IsKiller function does not exist!")
        end
        
        if GM.IsSurvivor then
            ply:ChatPrint("✓ GM.IsSurvivor function exists")
        else
            ply:ChatPrint("✗ GM.IsSurvivor function does not exist!")
        end
        
        if GM.GetKillerCharacters then
            ply:ChatPrint("✓ GM.GetKillerCharacters function exists")
        else
            ply:ChatPrint("✗ GM.GetKillerCharacters function does not exist!")
        end
        
        if GM.GetSurvivorCharacters then
            ply:ChatPrint("✓ GM.GetSurvivorCharacters function exists")
        else
            ply:ChatPrint("✗ GM.GetSurvivorCharacters function does not exist!")
        end
    else
        ply:ChatPrint("✗ GM table does not exist!")
    end
    
    ply:ChatPrint("=== End Test ===")
end)

-- Сетевые сообщения
if SERVER then
    util.AddNetworkString("GModsaken_UpdateGameState")
    util.AddNetworkString("GModsaken_UpdateTimer")
    util.AddNetworkString("GModsaken_PlayChaseMusic")
    util.AddNetworkString("GModsaken_StopChaseMusic")
    util.AddNetworkString("GModsaken_BlindPlayer")
    util.AddNetworkString("GModsaken_KillAnimation")
    util.AddNetworkString("GModsaken_KillAnimationEnd")
    util.AddNetworkString("GModsaken_SpawnProp")
    util.AddNetworkString("GModsaken_PropDestroyed")
end

-- Команды для Q-меню
concommand.Add("gmodsaken_q_menu", function(ply, cmd, args)
    if not IsValid(ply) then return end
    if ply:Team() ~= GM.TEAM_SURVIVOR then
        ply:ChatPrint("Q-меню доступно только выжившим!")
        return
    end
    
    if CLIENT then
        GM:CreateQMenu()
    end
end)

-- Команда для очистки всех пропов (админ)
concommand.Add("gmodsaken_clear_props", function(ply, cmd, args)
    if not IsValid(ply) then return end
    if not ply:IsAdmin() then
        ply:ChatPrint("Эта команда доступна только администраторам!")
        return
    end
    
    if SERVER then
        local count = 0
        for _, ent in pairs(ents.GetAll()) do
            if ent:GetClass() == "prop_physics" and ent.IsQMenuProp then
                ent:Remove()
                count = count + 1
            end
        end
        
        ply:ChatPrint("Удалено " .. count .. " пропов из Q-меню!")
        print("GModsaken: Админ " .. ply:Nick() .. " удалил " .. count .. " пропов")
    end
end)

-- Команда для сброса кулдауна пропов (админ)
concommand.Add("gmodsaken_reset_cooldown", function(ply, cmd, args)
    if not IsValid(ply) then return end
    if not ply:IsAdmin() then
        ply:ChatPrint("Эта команда доступна только администраторам!")
        return
    end
    
    if CLIENT then
        propCooldown = 0
        ply:ChatPrint("Кулдаун пропов сброшен!")
    end
end)