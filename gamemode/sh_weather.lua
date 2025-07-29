--[[
    GModsaken - Dynamic Weather System
    Copyright (C) 2024 GModsaken Contributors
]]

-- Ensure GM table exists
if not _G.GM then
    _G.GM = {}
end
local GM = _G.GM

-- Weather states
GM.WeatherStates = {
    CLEAR = {
        name = "Ясно",
        light = "pigeon",
        fog_start = 0,
        fog_end = 30000,
        fog_density = 0.0001,
        wind_speed = 0,
        effect = nil,
        damage = 0,
        speed_mod = 1.0,
        stamina_drain = 1.0,
        sound = nil
    },
    RAIN = {
        name = "Дождь",
        light = "stormy",
        fog_start = 1000,
        fog_end = 5000,
        fog_density = 0.01,
        wind_speed = 50,
        effect = "env_rain",
        damage = 0,
        speed_mod = 0.95,
        stamina_drain = 1.2,
        sound = "ambient/weather/rain_loop1.wav"
    },
    STORM = {
        name = "Гроза",
        light = "stormy",
        fog_start = 500,
        fog_end = 3000,
        fog_density = 0.05,
        wind_speed = 150,
        effect = "env_rain_heavy",
        damage = 1,
        speed_mod = 0.9,
        stamina_drain = 1.5,
        sound = "ambient/weather/thunderstorm_light_loop.wav"
    },
    FOG = {
        name = "Туман",
        light = "dawn",
        fog_start = 10,
        fog_end = 1000,
        fog_density = 0.1,
        wind_speed = 10,
        effect = "fog",
        damage = 0,
        speed_mod = 0.9,
        stamina_drain = 1.1,
        sound = "ambient/fog/fog_loop.wav"
    },
    ACID_RAIN = {
        name = "Кислотный дождь",
        light = "toxic",
        fog_start = 500,
        fog_end = 3000,
        fog_density = 0.1,
        wind_speed = 30,
        effect = "acid_rain",
        damage = 2,
        speed_mod = 0.85,
        stamina_drain = 1.8,
        sound = "ambient/weather/acid_rain_loop.wav"
    }
}

-- Current weather state
GM.CurrentWeather = GM.WeatherStates.CLEAR
GM.NextWeatherChange = 0
GM.WeatherDuration = 300 -- 5 minutes default

-- Initialize weather system
function GM:InitializeWeather()
    self:SetRandomWeather()
    self.NextWeatherChange = CurTime() + self.WeatherDuration
    
    -- Sync with clients
    if SERVER then
        net.Start("GModsaken_WeatherSync")
        net.WriteString(self.CurrentWeather.name)
        net.Broadcast()
    end
end

-- Set random weather
function GM:SetRandomWeather()
    local weathers = {}
    for k, v in pairs(self.WeatherStates) do
        table.insert(weathers, v)
    end
    
    self.CurrentWeather = table.Random(weathers)
    self:ApplyWeatherEffects()
    
    print("[GModsaken] Погода изменилась на: " .. self.CurrentWeather.name)
end

-- Apply weather effects
function GM:ApplyWeatherEffects()
    if CLIENT then return end
    
    -- Apply to all players
    for _, ply in ipairs(player.GetAll()) do
        self:ApplyWeatherToPlayer(ply)
    end
    
    -- Play ambient sound
    if self.CurrentWeather.sound then
        for _, ply in ipairs(player.GetAll()) do
            ply:EmitSound(self.CurrentWeather.sound, 50, 100, 0.5)
        end
    end
    
    -- Sync with clients
    net.Start("GModsaken_WeatherSync")
    net.WriteString(self.CurrentWeather.name)
    net.Broadcast()
end

-- Apply weather effects to a player
function GM:ApplyWeatherToPlayer(ply)
    if not IsValid(ply) then return end
    
    -- Apply speed modifier
    if self.CurrentWeather.speed_mod then
        local char = self:GetCharacter(ply:GetNWString("Character", "rebel"))
        if char then
            ply:SetWalkSpeed(200 * char.speed * self.CurrentWeather.speed_mod)
            ply:SetRunSpeed(400 * char.speed * self.CurrentWeather.speed_mod)
        end
    end
    
    -- Apply damage if needed
    if self.CurrentWeather.damage > 0 and not ply:IsKiller() then
        timer.Create("WeatherDamage_" .. ply:EntIndex(), 1, 0, function()
            if IsValid(ply) then
                local dmg = DamageInfo()
                dmg:SetDamage(self.CurrentWeather.damage)
                dmg:SetAttacker(game.GetWorld())
                dmg:SetDamageType(DMG_ACID)
                ply:TakeDamageInfo(dmg)
            end
        end)
    else
        timer.Remove("WeatherDamage_" .. ply:EntIndex())
    end
end

-- Clean up weather effects
function GM:CleanupWeather()
    for _, ply in ipairs(player.GetAll()) do
        timer.Remove("WeatherDamage_" .. ply:EntIndex())
    end
end

-- Hook into player spawn
hook.Add("PlayerSpawn", "GModsaken_WeatherPlayerSpawn", function(ply)
    if not GM then return end
    timer.Simple(1, function()
        if IsValid(ply) and GM.ApplyWeatherToPlayer then
            GM:ApplyWeatherToPlayer(ply)
        end
    end)
end)

-- Network messages
if SERVER then
    util.AddNetworkString("GModsaken_WeatherSync")
else
    net.Receive("GModsaken_WeatherSync", function()
        local weatherName = net.ReadString()
        for k, v in pairs(GM.WeatherStates) do
            if v.name == weatherName then
                GM.CurrentWeather = v
                break
            end
        end
        
        -- Show notification
        notification.AddLegacy("Погода изменилась: " .. GM.CurrentWeather.name, NOTIFY_GENERIC, 5)
        surface.PlaySound("ambient/weather/rain_drip" .. math.random(1, 4) .. ".wav")
    end)
end

-- Update weather periodically
timer.Create("GModsaken_WeatherUpdate", 1, 0, function()
    if not GM then return end
    
    if CurTime() >= GM.NextWeatherChange then
        GM:SetRandomWeather()
        GM.NextWeatherChange = CurTime() + GM.WeatherDuration
    end
end)

-- Clean up on gamemode cleanup
hook.Add("ShutDown", "GModsaken_WeatherShutdown", function()
    if GM and GM.CleanupWeather then
        GM:CleanupWeather()
    end
end)

-- Add to initialization
hook.Add("Initialize", "GModsaken_WeatherInit", function()
    timer.Simple(1, function()
        if GM and GM.InitializeWeather then
            GM:InitializeWeather()
        end
    end)
end)

-- Add console command to change weather
concommand.Add("gmodsaken_setweather", function(ply, cmd, args)
    if IsValid(ply) and not ply:IsAdmin() then
        ply:ChatPrint("У вас нет прав на использование этой команды!")
        return
    end
    
    local weatherName = args[1]
    if not weatherName then return end
    
    weatherName = string.upper(weatherName)
    if GM.WeatherStates[weatherName] then
        GM.CurrentWeather = GM.WeatherStates[weatherName]
        GM:ApplyWeatherEffects()
        
        local msg = "Погода изменена на: " .. GM.CurrentWeather.name
        if IsValid(ply) then
            ply:ChatPrint(msg)
        else
            print("[GModsaken] " .. msg)
        end
    else
        local msg = "Неизвестный тип погоды. Доступно: " .. table.concat(table.GetKeys(GM.WeatherStates), ", ")
        if IsValid(ply) then
            ply:ChatPrint(msg)
        else
            print("[GModsaken] " .. msg)
        end
    end
end, nil, "Изменить погоду. Использование: gmodsaken_setweather <тип>\nДоступные типы: " .. table.concat(table.GetKeys(GM.WeatherStates), ", "), FCVAR_SERVER_CAN_EXECUTE)
