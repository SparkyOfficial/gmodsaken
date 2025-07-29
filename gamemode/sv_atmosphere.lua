--[[
    GModsaken - Horror Atmosphere System
    Copyright (C) 2024 GModsaken Contributors
]]

-- Ensure GM table exists
if not _G.GM then
    _G.GM = {}
end
local GM = _G.GM
_G.GAMEMODE = GM

-- Настройки атмосферы
GM.AtmosphereSettings = {
    FogEnabled = true,
    FogStart = 100,
    FogEnd = 800,
    FogDensity = 0.3,
    FogColor = Color(20, 20, 30),
    
    SkyboxEnabled = true,
    SkyboxName = "sky_night02",
    
    LightingEnabled = true,
    AmbientLight = Color(10, 10, 15),
    SunLight = Color(5, 5, 10),
    
    WeatherEnabled = true,
    RainIntensity = 0.3,
    WindSpeed = 50
}

-- Функция для установки атмосферы ужаса
function GM:SetHorrorAtmosphere()
    if not self.AtmosphereSettings then return end
    
    local settings = self.AtmosphereSettings
    
    -- Устанавливаем туман
    if settings.FogEnabled then
        for _, ply in pairs(player.GetAll()) do
            net.Start("GModsaken_SetFog")
            net.WriteBool(true)
            net.WriteInt(settings.FogStart, 16)
            net.WriteInt(settings.FogEnd, 16)
            net.WriteFloat(settings.FogDensity)
            net.WriteColor(settings.FogColor)
            net.Send(ply)
        end
    end
    
    -- Устанавливаем небо
    if settings.SkyboxEnabled then
        for _, ply in pairs(player.GetAll()) do
            net.Start("GModsaken_SetSkybox")
            net.WriteString(settings.SkyboxName)
            net.Send(ply)
        end
    end
    
    -- Устанавливаем освещение
    if settings.LightingEnabled then
        for _, ply in pairs(player.GetAll()) do
            net.Start("GModsaken_SetLighting")
            net.WriteColor(settings.AmbientLight)
            net.WriteColor(settings.SunLight)
            net.Send(ply)
        end
    end
    
    -- Устанавливаем погоду
    if settings.WeatherEnabled then
        for _, ply in pairs(player.GetAll()) do
            net.Start("GModsaken_SetWeather")
            net.WriteFloat(settings.RainIntensity)
            net.WriteFloat(settings.WindSpeed)
            net.Send(ply)
        end
    end
    
    print("GModsaken: Атмосфера ужаса установлена!")
end

-- Функция для сброса атмосферы
function GM:ResetAtmosphere()
    for _, ply in pairs(player.GetAll()) do
        net.Start("GModsaken_ResetAtmosphere")
        net.Send(ply)
    end
    print("GModsaken: Атмосфера сброшена!")
end

-- Хук для установки атмосферы при начале раунда
hook.Add("GModsaken_RoundStarted", "GModsaken_SetHorrorAtmosphere", function()
    timer.Simple(2, function()
        if GM.SetHorrorAtmosphere then
            GM:SetHorrorAtmosphere()
        end
    end)
end)

-- Хук для сброса атмосферы при окончании раунда
hook.Add("GModsaken_GameEnded", "GModsaken_ResetAtmosphere", function()
    if GM.ResetAtmosphere then
        GM:ResetAtmosphere()
    end
end)

-- Хук для установки атмосферы новым игрокам
hook.Add("PlayerInitialSpawn", "GModsaken_PlayerAtmosphere", function(ply)
    timer.Simple(3, function()
        if IsValid(ply) and GM.GameState == "PLAYING" and GM.SetHorrorAtmosphere then
            GM:SetHorrorAtmosphere()
        end
    end)
end)

-- Команды для управления атмосферой
concommand.Add("gmodsaken_set_horror", function(ply, cmd, args)
    if not IsValid(ply) or not ply:IsAdmin() then return end
    
    if GM.SetHorrorAtmosphere then
        GM:SetHorrorAtmosphere()
        ply:ChatPrint("✓ Атмосфера ужаса установлена!")
    end
end)

concommand.Add("gmodsaken_reset_atmosphere", function(ply, cmd, args)
    if not IsValid(ply) or not ply:IsAdmin() then return end
    
    if GM.ResetAtmosphere then
        GM:ResetAtmosphere()
        ply:ChatPrint("✓ Атмосфера сброшена!")
    end
end)

-- Добавляем сетевые строки
if SERVER then
    util.AddNetworkString("GModsaken_SetFog")
    util.AddNetworkString("GModsaken_SetSkybox")
    util.AddNetworkString("GModsaken_SetLighting")
    util.AddNetworkString("GModsaken_SetWeather")
    util.AddNetworkString("GModsaken_ResetAtmosphere")
end

print("GModsaken: Система атмосферы ужаса загружена!") 