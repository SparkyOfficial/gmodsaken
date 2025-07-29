--[[
    GModsaken - Garry's Mod Gamemode (Client)
    Copyright (C) 2024 GModsaken Contributors
]]

-- Ensure GM table exists in global scope
if not _G.GM then
    _G.GM = {}
end
_G.GAMEMODE = _G.GM

-- Include shared code first (this will define the basic GM structure)
include("shared.lua")

-- Now get local reference to GM table
local GM = _G.GM
_G.GAMEMODE = GM

-- Debug print
print("[GModsaken] Client initialization - GM table " .. (GM and "found" or "NOT FOUND"))

-- Include shared files first
include("sh_characters.lua")  -- Characters must be loaded first
include("sh_teams.lua")
include("sh_stamina.lua")

-- Include client-side components AFTER shared files
if CLIENT then
    include("cl_character_menu.lua")
    include("cl_hud.lua")
    include("cl_spawnmenu.lua")
    -- include("cl_info_menu.lua") -- Временно отключено
end

-- Debug info
print("[GModsaken] Client initialization complete")
print("GM table: " .. tostring(GM))
print("GAMEMODE table: " .. tostring(GAMEMODE))

-- Verify GM table after includes
if not GM then
    ErrorNoHalt("[GModsaken] CRITICAL: GM table is nil after includes!")
    GM = {}
    _G.GM = GM
    _G.GAMEMODE = GM
end

-- Debug print after includes
print("[GModsaken] Client initialization - After includes")

-- Инициализация гейммода на клиенте
function GM:Initialize()
    print("GModsaken Survival Horror гейммод (клиент) загружен!")
    
    -- Инициализируем HUD
    if self.InitializeHUD then
        self:InitializeHUD()
    end
    
    print("GModsaken: Клиентская система инициализирована")
    
    -- Скрываем стандартные элементы HUD
    hook.Add("HUDShouldDraw", "GModsaken_HideDefaultHUD", function(name)
        if name == "CHudHealth" or name == "CHudBattery" or name == "CHudSecondaryAmmo" then
            return false
        end
        return true
    end)
end

-- Настройка интерфейса
function GM:CreateTeams()
    if not self.TEAM_SURVIVOR or not self.TEAM_KILLER or not self.TEAM_SPECTATOR then return end
    
    team.SetUp(self.TEAM_SURVIVOR, "Выжившие", Color(0, 150, 255), true)
    team.SetSpawnPoint(self.TEAM_SURVIVOR, {"info_player_start", "info_player_deathmatch"})
    
    team.SetUp(self.TEAM_KILLER, "Убийца", Color(255, 0, 0), false)
    team.SetSpawnPoint(self.TEAM_KILLER, {"info_player_start", "info_player_deathmatch"})
    
    team.SetUp(self.TEAM_SPECTATOR, "Наблюдатели", Color(128, 128, 128), false)
    team.SetSpawnPoint(self.TEAM_SPECTATOR, {"info_player_start", "info_player_deathmatch"})
end

-- Обработка спавна игрока
function GM:PlayerSpawn(ply)
    if ply == LocalPlayer() then
        -- Можно добавить эффекты при спавне
        surface.PlaySound("buttons/button15.wav")
        
        -- Уведомляем игрока о его роли
        timer.Simple(1, function()
            if self.IsKiller and self:IsKiller(ply) then
                chat.AddText(Color(255, 0, 0), "Вы стали УБИЙЦЕЙ! Уничтожьте всех выживших!")
            elseif self.IsSurvivor and self:IsSurvivor(ply) then
                chat.AddText(Color(0, 150, 255), "Вы ВЫЖИВШИЙ! Спасайтесь от убийцы!")
            end
        end)
    end
end

-- Обработка смерти игрока
function GM:PlayerDeath(ply, inflictor, attacker)
    if ply == LocalPlayer() then
        -- Эффекты при смерти
        surface.PlaySound("buttons/button10.wav")
        
        if self.IsSurvivor and self:IsSurvivor(ply) then
            chat.AddText(Color(255, 255, 0), "Вы погибли! Ожидайте окончания раунда.")
        elseif self.IsKiller and self:IsKiller(ply) then
            chat.AddText(Color(255, 0, 0), "Вы погибли! Выжившие победили!")
        end
    end
end

-- Обработка смены команды
function GM:PlayerTeamChanged(ply, oldTeam, newTeam)
    if ply == LocalPlayer() then
        if newTeam == self.TEAM_KILLER then
            chat.AddText(Color(255, 0, 0), "Вы стали УБИЙЦЕЙ!")
        elseif newTeam == self.TEAM_SURVIVOR then
            chat.AddText(Color(0, 150, 255), "Вы стали ВЫЖИВШИМ!")
        elseif newTeam == self.TEAM_SPECTATOR then
            chat.AddText(Color(128, 128, 128), "Вы в лобби.")
        end
    end
end

-- Команда для отладки клиента
concommand.Add("gmodsaken_client_debug", function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    
    print("=== GModsaken Client Debug ===")
    print("Player: " .. ply:Nick())
    print("Team: " .. ply:Team())
    print("Health: " .. ply:Health() .. "/" .. ply:GetMaxHealth())
    print("Armor: " .. ply:Armor())
    print("Alive: " .. tostring(ply:Alive()))
    print("Position: " .. tostring(ply:GetPos()))
end)

-- Отладочная команда для проверки персонажей
concommand.Add("gmodsaken_debug_characters", function()
    if not GM then
        print("GM table is nil!")
        return
    end
    
    print("=== DEBUG CHARACTERS ===")
    print("GM.SurvivorCharacters: " .. tostring(GM.SurvivorCharacters))
    print("GM.KillerCharacters: " .. tostring(GM.KillerCharacters))
    
    if GM.SurvivorCharacters then
        print("Survivor count: " .. #GM.SurvivorCharacters)
        for i, char in pairs(GM.SurvivorCharacters) do
            print("Survivor " .. i .. ": " .. (char.name or "UNNAMED"))
        end
    end
    
    if GM.KillerCharacters then
        print("Killer count: " .. #GM.KillerCharacters)
        for i, char in pairs(GM.KillerCharacters) do
            print("Killer " .. i .. ": " .. (char.name or "UNNAMED"))
        end
    end
    
    print("GameState: " .. tostring(GM.GameState))
    print("========================")
end)

-- Инициализация при загрузке
hook.Add("InitPostEntity", "GModsaken_ClientInit", function()
    timer.Simple(1, function()
        if GM then
            GM:Initialize()
        end
    end)
end)