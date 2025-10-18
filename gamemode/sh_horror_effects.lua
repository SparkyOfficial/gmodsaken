--[[
    GModsaken - Horror Effects System
    Copyright (C) 2024 GModsaken Contributors
]]

if not _G.GM then _G.GM = {} end
local GM = _G.GM

-- Конфигурация эффектов
GM.HorrorConfig = {
    Enabled = true,
    Intensity = 1.0, -- 0.0 - 2.0
    
    -- Эффекты
    DynamicLights = true,
    ScreenShake = true,
    BloodEffects = true,
    SoundEffects = true,
    RandomEvents = true,
    
    -- Настройки звуков
    AmbientSounds = {
        "ambient/creatures/town_child_scream1.wav",
        "ambient/creatures/town_whisper.wav",
        "ambient/voices/crying_loop1.wav",
        "ambient/atmosphere/cave_hit.wav"
    },
    
    -- Настройки событий
    EventInterval = {
        min = 45,  -- Минимальное время между событиями (сек)
        max = 120 -- Максимальное время между событиями (сек)
    },
    
    -- Эффекты экрана
    ScreenEffects = {
        "film_grain",
        "color_modify",
        "bloom"
    }
}

-- Глобальные переменные
local nextEventTime = 0
local isEventActive = false
local currentEvent = nil
local activeEffects = {}

-- Случайные звуковые эффекты
local horrorSounds = {
    {
        sound = "npc/stalker/breathing3.wav",
        volume = 0.7,
        pitch = 80,
        radius = 1200
    },
    {
        sound = "npc/fast_zombie/fz_scream1.wav",
        volume = 1.0,
        pitch = 100,
        radius = 2000
    },
    {
        sound = "npc/zombie/zombie_pound_door1.wav",
        volume = 0.8,
        pitch = 90,
        radius = 1500
    }
}

-- Случайные визуальные эффекты
local visualEffects = {
    {
        name = "Кровавый дождь",
        duration = 10,
        startFunc = function()
            -- Эффект кровавого дождя
            if CLIENT then
                hook.Add("RenderScreenspaceEffects", "HorrorBloodRain", function()
                    DrawMaterialOverlay("effects/tp_eyefx/tpeye2", 0.1)
                    DrawColorModify({
                        ["$pp_colour_addr"] = 0.1,
                        ["$pp_colour_addg"] = 0,
                        ["$pp_colour_addb"] = 0,
                        ["$pp_colour_brightness"] = 0,
                        ["$pp_colour_contrast"] = 1.2,
                        ["$pp_colour_colour"] = 0.8,
                        ["$pp_colour_mulr"] = 0,
                        ["$pp_colour_mulg"] = 0,
                        ["$pp_colour_mulb"] = 0
                    })
                end)
            end
        end,
        endFunc = function()
            if CLIENT then
                hook.Remove("RenderScreenspaceEffects", "HorrorBloodRain")
            end
        end
    },
    {
        name = "Землетрясение",
        duration = 15,
        startFunc = function()
            if SERVER then
                for _, ply in ipairs(player.GetAll()) do
                    util.ScreenShake(ply:GetPos(), 10, 5, 15, 5000)
                end
            end
        end,
        endFunc = function() end
    },
    {
        name = "Шепот",
        duration = 20,
        startFunc = function()
            if SERVER then
                for _, ply in ipairs(player.GetAll()) do
                    ply:EmitSound("ambient/voices/crying_loop1.wav", 75, 100, 0.5)
                end
            end
        end,
        endFunc = function()
            if SERVER then
                for _, ply in ipairs(player.GetAll()) do
                    ply:StopSound("ambient/voices/crying_loop1.wav")
                end
            end
        end
    }
}

-- Функция для запуска случайного события
local function StartRandomEvent()
    if not GM.HorrorConfig.Enabled or not GM.HorrorConfig.RandomEvents then return end
    
    local event = table.Random(visualEffects)
    if not event then return end
    
    currentEvent = event
    isEventActive = true
    
    -- Логируем событие
    if SERVER then
        print("[Horror] Начинается событие: " .. event.name)
    end
    
    -- Запускаем эффект
    if event.startFunc then
        event.startFunc()
    end
    
    -- Устанавливаем таймер на завершение
    timer.Create("HorrorEvent_" .. event.name, event.duration, 1, function()
        if event.endFunc then
            event.endFunc()
        end
        isEventActive = false
        currentEvent = nil
        
        -- Устанавливаем время следующего события
        nextEventTime = CurTime() + math.Rand(
            GM.HorrorConfig.EventInterval.min,
            GM.HorrorConfig.EventInterval.max
        )
    end)
end

-- Функция для воспроизведения случайного звука
local function PlayRandomHorrorSound(pos)
    if not GM.HorrorConfig.Enabled or not GM.HorrorConfig.SoundEffects then return end
    
    local sound = table.Random(horrorSounds)
    if not sound then return end
    
    sound.PlayURL = sound.sound
    sound.Pos = pos or VectorRand() * 1000
    sound.Volume = sound.volume * GM.HorrorConfig.Intensity
    
    if SERVER then
        net.Start("HorrorPlaySound")
        net.WriteTable(sound)
        net.Broadcast()
    else
        sound.Playing = true
        sound.Emitter = Emitter(sound.Pos, true)
        sound.Sound = CreateSound(sound.Emitter, sound.PlayURL)
        sound.Sound:PlayEx(sound.Volume, sound.pitch or 100)
        
        table.insert(activeEffects, {
            sound = sound,
            startTime = CurTime(),
            duration = 5 -- Примерная длительность звука
        })
    end
end

-- Сетевые сообщения
if SERVER then
    util.AddNetworkString("HorrorPlaySound")
    
    -- Обновление интенсивности у всех игроков
    function GM:UpdateHorrorIntensity(intensity)
        self.HorrorConfig.Intensity = math.Clamp(intensity or 1.0, 0, 2.0)
        net.Start("HorrorUpdateIntensity")
        net.WriteFloat(self.HorrorConfig.Intensity)
        net.Broadcast()
    end
    
    -- Запуск события для всех игроков
    function GM:TriggerHorrorEvent(eventName)
        net.Start("HorrorTriggerEvent")
        net.WriteString(eventName)
        net.Broadcast()
    end
else
    -- Обработка сетевых сообщений на клиенте
    net.Receive("HorrorPlaySound", function()
        local sound = net.ReadTable()
        sound.Playing = true
        sound.Emitter = Emitter(sound.Pos, true)
        sound.Sound = CreateSound(sound.Emitter, sound.PlayURL)
        sound.Sound:PlayEx(sound.Volume, sound.pitch or 100)
        
        table.insert(activeEffects, {
            sound = sound,
            startTime = CurTime(),
            duration = 5
        })
    end)
    
    net.Receive("HorrorUpdateIntensity", function()
        GM.HorrorConfig.Intensity = net.ReadFloat()
    end)
    
    net.Receive("HorrorTriggerEvent", function()
        local eventName = net.ReadString()
        -- Обработка событий на клиенте
    end)
end

-- Основной хук для обновления эффектов
hook.Add("Think", "HorrorEffectsThink", function()
    if not GM.HorrorConfig.Enabled then return end
    
    -- Обновление активных звуковых эффектов
    for i = #activeEffects, 1, -1 do
        local effect = activeEffects[i]
        if CurTime() > effect.startTime + effect.duration then
            if effect.sound.Sound then
                effect.sound.Sound:Stop()
                effect.sound.Sound = nil
            end
            if effect.sound.Emitter then
                effect.sound.Emitter:Remove()
            end
            table.remove(activeEffects, i)
        end
    end
    
    -- Проверка на случайные события
    if SERVER and not isEventActive and CurTime() > nextEventTime then
        StartRandomEvent()
    end
    
    -- Динамическое изменение интенсивности (пример)
    if math.random() < 0.01 then
        local targetIntensity = math.Rand(0.5, 1.5)
        if SERVER then
            GM:UpdateHorrorIntensity(targetIntensity)
        end
    end
end)

-- Эффект при получении урона
hook.Add("EntityTakeDamage", "HorrorDamageEffects", function(ent, dmg)
    if not GM.HorrorConfig.Enabled or not GM.HorrorConfig.BloodEffects then return end
    
    if ent:IsPlayer() and dmg:GetDamage() > 0 then
        -- Эффект крови на экране
        if CLIENT and ent == LocalPlayer() then
            local intensity = math.Clamp(dmg:GetDamage() / 50, 0.1, 0.8)
            DrawBloodEffect(intensity)
        end
        
        -- Звук удара
        if SERVER and math.random() < 0.3 then
            ent:EmitSound("physics/body/body_medium_impact_hard" .. math.random(1, 6) .. ".wav", 75, math.random(90, 110))
        end
    end
end)

-- Функция для отрисовки эффекта крови на экране (клиентская)
if CLIENT then
    local bloodMaterial = Material("effects/blood_core")
    local lastBloodTime = 0
    
    function DrawBloodEffect(intensity)
        intensity = intensity or 0.5
        lastBloodTime = CurTime() + intensity * 2
        
        hook.Add("RenderScreenspaceEffects", "BloodEffect", function()
            if CurTime() > lastBloodTime then
                hook.Remove("RenderScreenspaceEffects", "BloodEffect")
                return
            end
            
            local alpha = (lastBloodTime - CurTime()) / 2 * 255 * intensity
            surface.SetDrawColor(255, 0, 0, alpha)
            surface.SetMaterial(bloodMaterial)
            surface.DrawTexturedRect(0, 0, ScrW(), ScrH())
        end)
    end
    
    -- Эффект при низком здоровье
    hook.Add("RenderScreenspaceEffects", "LowHealthEffect", function()
        local ply = LocalPlayer()
        if not IsValid(ply) or not ply:Alive() then return end
        
        local health = ply:Health()
        local maxHealth = ply:GetMaxHealth()
        
        if health < maxHealth * 0.3 then
            local effect = (1 - health / (maxHealth * 0.3)) * 0.7
            
            DrawMotionBlur(0.2, effect * 0.8, 0.01)
            
            DrawColorModify({
                ["$pp_colour_brightness"] = -effect * 0.2,
                ["$pp_colour_contrast"] = 1 + effect * 0.5,
                ["$pp_colour_colour"] = 1 - effect * 0.5,
                ["$pp_colour_mulr"] = effect * 0.5,
                ["$pp_colour_mulg"] = 0,
                ["$pp_colour_mulb"] = 0
            })
        end
    end)
end

-- Инициализация
hook.Add("Initialize", "HorrorEffectsInit", function()
    if SERVER then
        -- Устанавливаем первое случайное событие
        nextEventTime = CurTime() + math.Rand(
            GM.HorrorConfig.EventInterval.min,
            GM.HorrorConfig.EventInterval.max
        )
    end
    
    -- Загружаем материалы
    if CLIENT then
        for i = 1, 6 do
            Material("effects/blood" .. i)
        end
    end
end)

-- Консольные команды
concommand.Add("horror_intensity", function(ply, cmd, args)
    if IsValid(ply) and not ply:IsAdmin() then return end
    
    local intensity = tonumber(args[1])
    if intensity then
        GM.HorrorConfig.Intensity = math.Clamp(intensity, 0, 2)
        print("Установлена интенсивность ужасов: " .. GM.HorrorConfig.Intensity)
    else
        print("Использование: horror_intensity <0.0-2.0>")
    end
end)

concommand.Add("horror_event", function(ply, cmd, args)
    if IsValid(ply) and not ply:IsAdmin() then return end
    
    if not isEventActive then
        StartRandomEvent()
        print("Запущено случайное событие ужасов")
    else
        print("Событие уже активно: " .. (currentEvent and currentEvent.name or "Неизвестно"))
    end
end)

print("[GModsaken] Система ужасов загружена!")
