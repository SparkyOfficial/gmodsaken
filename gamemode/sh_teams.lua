--[[
    GModsaken - Teams System
    Copyright (C) 2024 GModsaken Contributors
]]

-- Local reference to GM table
local GM = _G.GM or GAMEMODE
_G.GM = GM
_G.GAMEMODE = GM
if not GM then
    ErrorNoHalt("[GModsaken] CRITICAL: GM table is nil in sh_teams.lua!\n")
    return
end

-- Initialize team variables if they don't exist
GM.TEAM_SPECTATOR = GM.TEAM_SPECTATOR or 1
GM.TEAM_SURVIVOR = GM.TEAM_SURVIVOR or 2
GM.TEAM_KILLER = GM.TEAM_KILLER or 3

-- Debug print
print("[GModsaken] Team constants initialized - " .. 
    "Spectator: " .. tostring(GM.TEAM_SPECTATOR) .. ", " ..
    "Survivor: " .. tostring(GM.TEAM_SURVIVOR) .. ", " ..
    "Killer: " .. tostring(GM.TEAM_KILLER))

-- Create teams
function GM:CreateTeams()
    local gm = self or GM or GAMEMODE
    if not gm then
        ErrorNoHalt("[GModsaken] CRITICAL: GM table is nil in CreateTeams!\n")
        return
    end
    
    -- Set up survivor team
    team.SetUp(gm.TEAM_SURVIVOR or 2, "Выжившие", Color(0, 150, 255), true)
    team.SetSpawnPoint(gm.TEAM_SURVIVOR or 2, {"info_player_start", "info_player_deathmatch"})
    
    -- Set up killer team
    team.SetUp(gm.TEAM_KILLER or 3, "Убийца", Color(255, 0, 0), false)
    team.SetSpawnPoint(gm.TEAM_KILLER or 3, {"info_player_start", "info_player_deathmatch"})
    
    -- Set up spectator team
    team.SetUp(gm.TEAM_SPECTATOR or 1, "Наблюдатели", Color(128, 128, 128), false)
    team.SetSpawnPoint(gm.TEAM_SPECTATOR or 1, {"info_player_start", "info_player_deathmatch"})
    
    print("[GModsaken] Команды инициализированы")
    
    -- Debug print team info
    for _, teamID in ipairs({gm.TEAM_SPECTATOR or 1, gm.TEAM_SURVIVOR or 2, gm.TEAM_KILLER or 3}) do
        local teamData = team.GetName(teamID)
        print(string.format("[GModsaken] Team %d: %s", teamID, tostring(teamData)))
    end
end

-- Get a random spawn point for a team
function GM:GetTeamSpawnPoint(teamID)
    local gm = self or GM or GAMEMODE
    if not teamID then return Vector(0, 0, 64) end
    
    if teamID == (gm.TEAM_SURVIVOR or 2) then
        if gm.SurvivorSpawns and #gm.SurvivorSpawns > 0 then
            return table.Random(gm.SurvivorSpawns)
        end
    elseif teamID == (gm.TEAM_KILLER or 3) then
        if gm.KillerSpawn then
            return gm.KillerSpawn
        end
    end
    
    -- Fallback to info_player_start
    local spawns = ents.FindByClass("info_player_start")
    if #spawns > 0 then
        return spawns[1]:GetPos()
    end
    
    return Vector(0, 0, 64)
end

-- Get a random lobby spawn point
function GM:GetLobbySpawnPoint()
    local gm = self or GM or GAMEMODE
    if gm.LobbySpawns and #gm.LobbySpawns > 0 then
        return table.Random(gm.LobbySpawns)
    end
    
    -- Fallback to info_player_start
    local spawns = ents.FindByClass("info_player_start")
    if #spawns > 0 then
        return spawns[1]:GetPos()
    end
    
    return Vector(0, 0, 64)
end

-- Check if a player can switch teams
function GM:CanPlayerSwitchTeam(ply, newTeam)
    local gm = self or GM or GAMEMODE
    if not IsValid(ply) then return false end
    
    -- Can't switch teams during gameplay
    if gm.GameState == "PLAYING" then
        return false
    end
    
    -- Only one killer allowed
    if newTeam == (gm.TEAM_KILLER or 3) then
        local killers = team.GetPlayers(gm.TEAM_KILLER or 3)
        if #killers > 0 and killers[1] ~= ply then
            return false
        end
    end
    
    return true
end

-- Get number of players on a team
function GM:GetTeamPlayerCount(teamID)
    local count = 0
    for _, ply in ipairs(player.GetAll()) do
        if ply:Team() == teamID then
            count = count + 1
        end
    end
    return count
end

-- Получение всех игроков команды
function GM:GetTeamPlayers(teamID)
    return team.GetPlayers(teamID)
end

-- Проверка, является ли игрок выжившим
function GM:IsSurvivor(ply)
    local gm = self or GM or GAMEMODE
    
    -- Отладочная информация
    if CLIENT then
        print("[GModsaken] IsSurvivor Debug:")
        print("  - Player valid: " .. tostring(IsValid(ply)))
        print("  - Player team: " .. tostring(ply and ply.Team and ply:Team()))
        print("  - Expected team: " .. tostring(gm.TEAM_SURVIVOR or 2))
        print("  - Result: " .. tostring(IsValid(ply) and ply.Team and ply:Team() == (gm.TEAM_SURVIVOR or 2)))
    end
    
    return IsValid(ply) and ply.Team and ply:Team() == (gm.TEAM_SURVIVOR or 2)
end

-- Проверка, является ли игрок убийцей
function GM:IsKiller(ply)
    local gm = self or GM or GAMEMODE
    return IsValid(ply) and ply.Team and ply:Team() == (gm.TEAM_KILLER or 3)
end

-- Проверка, является ли игрок наблюдателем
function GM:IsSpectator(ply)
    local gm = self or GM or GAMEMODE
    return IsValid(ply) and ply.Team and ply:Team() == (gm.TEAM_SPECTATOR or 1)
end 