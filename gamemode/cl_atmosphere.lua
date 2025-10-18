--[[
    GModsaken - Horror Atmosphere System (Client)
    Copyright (C) 2024 GModsaken Contributors
]]

-- Ensure GM table exists
if not _G.GM then
    _G.GM = {}
end
local GM = _G.GM
_G.GAMEMODE = GM

-- Переменные для атмосферы
local fogEnabled = false
local fogStart = 100
local fogEnd = 800
local fogDensity = 0.3
local fogColor = Color(20, 20, 30)

local skyboxEnabled = false
local skyboxName = "sky_night02"

local lightingEnabled = false
local ambientLight = Color(10, 10, 15)
local sunLight = Color(5, 5, 10)

local weatherEnabled = false
local rainIntensity = 0.3
local windSpeed = 50

-- Функция для установки тумана
local function SetFog(enabled, start, end_dist, density, color)
    fogEnabled = enabled
    fogStart = start or 100
    fogEnd = end_dist or 800
    fogDensity = density or 0.3
    fogColor = color or Color(20, 20, 30)
end

-- Функция для установки неба
local function SetSkybox(skybox)
    skyboxEnabled = true
    skyboxName = skybox or "sky_night02"
    
    -- Устанавливаем небо
    if skyboxName then
        RunConsoleCommand("sv_skyname", skyboxName)
    end
end

-- Функция для установки освещения
local function SetLighting(ambient, sun)
    lightingEnabled = true
    ambientLight = ambient or Color(10, 10, 15)
    sunLight = sun or Color(5, 5, 10)
end

-- Функция для установки погоды
local function SetWeather(rain, wind)
    weatherEnabled = true
    rainIntensity = rain or 0.3
    windSpeed = wind or 50
end

-- Функция для сброса атмосферы
local function ResetAtmosphere()
    fogEnabled = false
    skyboxEnabled = false
    lightingEnabled = false
    weatherEnabled = false
    
    -- Сбрасываем небо
    RunConsoleCommand("sv_skyname", "sky_day01_01")
    
    print("GModsaken: Атмосфера сброшена!")
end

-- Отрисовка тумана
hook.Add("RenderScreenspaceEffects", "GModsaken_FogEffect", function()
    if not fogEnabled then return end
    
    local tab = {
        ["$pp_colour_addr"] = 0,
        ["$pp_colour_addg"] = 0,
        ["$pp_colour_addb"] = 0,
        ["$pp_colour_brightness"] = -0.1,
        ["$pp_colour_contrast"] = 1.1,
        ["$pp_colour_colour"] = 0.8,
        ["$pp_colour_mulr"] = 0,
        ["$pp_colour_mulg"] = 0,
        ["$pp_colour_mulb"] = 0
    }
    
    DrawColorModify(tab)
    DrawBloom(0.3, 1, 8, 8, 1, 1, 1, 1, 1)
end)

-- Отрисовка тумана в мире
hook.Add("PreDrawSkyBox", "GModsaken_WorldFog", function()
    if not fogEnabled then return end
    
    render.FogMode(MATERIAL_FOG_LINEAR)
    render.FogStart(fogStart)
    render.FogEnd(fogEnd)
    render.FogMaxDensity(fogDensity)
    render.FogColor(fogColor.r, fogColor.g, fogColor.b)
end)

-- Отрисовка дождя
hook.Add("RenderScreenspaceEffects", "GModsaken_RainEffect", function()
    if not weatherEnabled or rainIntensity <= 0 then return end
    
    local screenW, screenH = ScrW(), ScrH()
    local time = CurTime()
    
    -- Простой эффект дождя
    for i = 1, math.floor(rainIntensity * 50) do
        local x = (time * 100 + i * 123) % screenW
        local y = (time * 200 + i * 456) % screenH
        
        surface.SetDrawColor(100, 150, 255, 100)
        surface.DrawLine(x, y, x + 2, y + 10)
    end
end)

-- Отрисовка ветра (движение объектов)
hook.Add("Think", "GModsaken_WindEffect", function()
    if not weatherEnabled or windSpeed <= 0 then return end
    
    local windForce = Vector(math.sin(CurTime() * 0.5) * windSpeed * 0.1, 
                           math.cos(CurTime() * 0.3) * windSpeed * 0.1, 0)
    
    -- Применяем ветер к физическим объектам
    for _, ent in pairs(ents.FindByClass("prop_physics")) do
        if IsValid(ent) and ent:GetPhysicsObject():IsValid() then
            local phys = ent:GetPhysicsObject()
            phys:ApplyForceCenter(windForce * phys:GetMass())
        end
    end
end)

-- Сетевые сообщения
net.Receive("GModsaken_SetFog", function()
    local enabled = net.ReadBool()
    local start = net.ReadInt(16)
    local end_dist = net.ReadInt(16)
    local density = net.ReadFloat()
    local color = net.ReadColor()
    
    SetFog(enabled, start, end_dist, density, color)
end)

net.Receive("GModsaken_SetSkybox", function()
    local skybox = net.ReadString()
    SetSkybox(skybox)
end)

net.Receive("GModsaken_SetLighting", function()
    local ambient = net.ReadColor()
    local sun = net.ReadColor()
    SetLighting(ambient, sun)
end)

net.Receive("GModsaken_SetWeather", function()
    local rain = net.ReadFloat()
    local wind = net.ReadFloat()
    SetWeather(rain, wind)
end)

net.Receive("GModsaken_ResetAtmosphere", function()
    ResetAtmosphere()
end)

print("GModsaken: Клиентская система атмосферы ужаса загружена!") 