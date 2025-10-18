--[[
    GModsaken - Disintegration Effects System
    Copyright (C) 2024 GModsaken Contributors
]]

-- Ensure GM table exists
if not _G.GM then
    _G.GM = GAMEMODE or {}
    print("[GModsaken] Created GM table in disintegration.lua")
end
local GM = _G.GM
_G.GAMEMODE = GM

print("[GModsaken] disintegration.lua loaded")

-- Эффекты дезинтеграции
local DisintegrationEffects = {}

-- Основной эффект дезинтеграции
function DisintegrationEffects:CreateDisintegrationEffect(pos, scale)
    if not pos then return end
    
    scale = scale or 1.0
    
    -- Создаем основной взрыв
    local effectdata = EffectData()
    effectdata:SetOrigin(pos)
    effectdata:SetScale(scale)
    effectdata:SetMagnitude(scale)
    util.Effect("cball_explode", effectdata)
    
    -- Создаем дополнительные эффекты
    self:CreateParticleEffect(pos, scale)
    self:CreateSoundEffect(pos)
    self:CreateScreenShake(pos, scale)
    self:CreateLightEffect(pos, scale)
end

-- Создание частиц
function DisintegrationEffects:CreateParticleEffect(pos, scale)
    local emitter = ParticleEmitter(pos)
    if not emitter then return end
    
    -- Основные частицы дезинтеграции
    for i = 1, 20 do
        local particle = emitter:Add("sprites/light_glow02_add", pos + VectorRand() * 50 * scale)
        if particle then
            particle:SetVelocity(VectorRand() * 200 * scale)
            particle:SetDieTime(2 + math.random() * 2)
            particle:SetStartAlpha(255)
            particle:SetEndAlpha(0)
            particle:SetStartSize(5 * scale)
            particle:SetEndSize(0)
            particle:SetColor(255, 100, 100)
            particle:SetGravity(Vector(0, 0, -100))
            particle:SetCollide(true)
            particle:SetBounce(0.3)
        end
    end
    
    -- Искры
    for i = 1, 15 do
        local particle = emitter:Add("effects/spark", pos + VectorRand() * 30 * scale)
        if particle then
            particle:SetVelocity(VectorRand() * 300 * scale)
            particle:SetDieTime(1.5 + math.random() * 1)
            particle:SetStartAlpha(255)
            particle:SetEndAlpha(0)
            particle:SetStartSize(3 * scale)
            particle:SetEndSize(0)
            particle:SetColor(255, 200, 100)
            particle:SetGravity(Vector(0, 0, -200))
            particle:SetCollide(true)
            particle:SetBounce(0.5)
        end
    end
    
    -- Дым
    for i = 1, 10 do
        local particle = emitter:Add("particle/smokesprites_0001", pos + VectorRand() * 20 * scale)
        if particle then
            particle:SetVelocity(VectorRand() * 100 * scale)
            particle:SetDieTime(3 + math.random() * 2)
            particle:SetStartAlpha(100)
            particle:SetEndAlpha(0)
            particle:SetStartSize(10 * scale)
            particle:SetEndSize(30 * scale)
            particle:SetColor(100, 100, 100)
            particle:SetGravity(Vector(0, 0, 50))
            particle:SetCollide(false)
        end
    end
    
    -- Энергетические частицы
    for i = 1, 8 do
        local particle = emitter:Add("sprites/light_glow02_add", pos + VectorRand() * 40 * scale)
        if particle then
            particle:SetVelocity(VectorRand() * 150 * scale)
            particle:SetDieTime(1 + math.random() * 1.5)
            particle:SetStartAlpha(200)
            particle:SetEndAlpha(0)
            particle:SetStartSize(8 * scale)
            particle:SetEndSize(0)
            particle:SetColor(100, 150, 255)
            particle:SetGravity(Vector(0, 0, -50))
            particle:SetCollide(false)
        end
    end
    
    emitter:Finish()
end

-- Создание звуковых эффектов
function DisintegrationEffects:CreateSoundEffect(pos)
    -- Основной звук дезинтеграции
    sound.Play("physics/glass/glass_sheet_break" .. math.random(1, 3) .. ".wav", pos, 75, 100, 1)
    
    -- Дополнительные звуки
    timer.Simple(0.1, function()
        sound.Play("physics/metal/metal_box_break" .. math.random(1, 2) .. ".wav", pos, 60, 120, 1)
    end)
    
    timer.Simple(0.2, function()
        sound.Play("physics/wood/wood_box_break" .. math.random(1, 2) .. ".wav", pos, 50, 110, 1)
    end)
    
    -- Энергетический звук
    timer.Simple(0.05, function()
        sound.Play("weapons/physcannon/energy_disintegrate" .. math.random(4, 5) .. ".wav", pos, 80, 90, 1)
    end)
end

-- Создание тряски экрана
function DisintegrationEffects:CreateScreenShake(pos, scale)
    local players = player.GetAll()
    for _, ply in pairs(players) do
        if IsValid(ply) and ply:GetPos():Distance(pos) < 500 * scale then
            local distance = ply:GetPos():Distance(pos)
            local intensity = math.max(0, 1 - (distance / (500 * scale)))
            
            util.ScreenShake(pos, intensity * 5 * scale, intensity * 3 * scale, 0.5, 200 * scale)
        end
    end
end

-- Создание светового эффекта
function DisintegrationEffects:CreateLightEffect(pos, scale)
    -- Создаем временный свет
    local light = ents.Create("light_dynamic")
    if IsValid(light) then
        light:SetPos(pos)
        light:SetKeyValue("brightness", "3")
        light:SetKeyValue("distance", tostring(200 * scale))
        light:SetKeyValue("color", "255 100 100")
        light:Spawn()
        
        -- Удаляем свет через 2 секунды
        timer.Simple(2, function()
            if IsValid(light) then
                light:Remove()
            end
        end)
    end
end

-- Эффект дезинтеграции с анимацией
function DisintegrationEffects:CreateAnimatedDisintegration(ent, duration)
    if not IsValid(ent) then return end
    
    duration = duration or 1.0
    local startTime = CurTime()
    local endTime = startTime + duration
    local originalPos = ent:GetPos()
    local originalAng = ent:GetAngles()
    
    -- Анимация исчезновения
    timer.Create("GModsaken_Disintegration_" .. ent:EntIndex(), 0.05, 0, function()
        if not IsValid(ent) then
            timer.Remove("GModsaken_Disintegration_" .. ent:EntIndex())
            return
        end
        
        local progress = (CurTime() - startTime) / duration
        if progress >= 1.0 then
            -- Финальный эффект
            self:CreateDisintegrationEffect(originalPos, 1.5)
            ent:Remove()
            timer.Remove("GModsaken_Disintegration_" .. ent:EntIndex())
            return
        end
        
        -- Анимация исчезновения
        local alpha = 255 * (1 - progress)
        ent:SetColor(Color(255, 255, 255, alpha))
        
        -- Легкая тряска
        local shake = math.sin(progress * 20) * 2
        ent:SetPos(originalPos + Vector(shake, shake, 0))
        
        -- Вращение
        ent:SetAngles(originalAng + Angle(0, progress * 180, 0))
        
        -- Уменьшение размера
        local scale = 1 - (progress * 0.3)
        ent:SetModelScale(scale, 0)
    end)
end

-- Эффект дезинтеграции с частицами
function DisintegrationEffects:CreateParticleDisintegration(ent, particleType)
    if not IsValid(ent) then return end
    
    particleType = particleType or "default"
    
    local pos = ent:GetPos()
    local emitter = ParticleEmitter(pos)
    if not emitter then return end
    
    if particleType == "glass" then
        -- Стеклянные осколки
        for i = 1, 30 do
            local particle = emitter:Add("effects/fleck_glass" .. math.random(1, 3), pos + VectorRand() * 20)
            if particle then
                particle:SetVelocity(VectorRand() * 300)
                particle:SetDieTime(3 + math.random() * 2)
                particle:SetStartAlpha(255)
                particle:SetEndAlpha(0)
                particle:SetStartSize(2)
                particle:SetEndSize(0)
                particle:SetColor(200, 220, 255)
                particle:SetGravity(Vector(0, 0, -300))
                particle:SetCollide(true)
                particle:SetBounce(0.3)
                particle:SetRoll(math.random() * 360)
                particle:SetRollDelta(math.random(-2, 2))
            end
        end
    elseif particleType == "metal" then
        -- Металлические осколки
        for i = 1, 25 do
            local particle = emitter:Add("effects/fleck_cement" .. math.random(1, 2), pos + VectorRand() * 15)
            if particle then
                particle:SetVelocity(VectorRand() * 250)
                particle:SetDieTime(2.5 + math.random() * 1.5)
                particle:SetStartAlpha(255)
                particle:SetEndAlpha(0)
                particle:SetStartSize(3)
                particle:SetEndSize(0)
                particle:SetColor(150, 150, 150)
                particle:SetGravity(Vector(0, 0, -400))
                particle:SetCollide(true)
                particle:SetBounce(0.2)
                particle:SetRoll(math.random() * 360)
                particle:SetRollDelta(math.random(-3, 3))
            end
        end
    else
        -- Стандартные частицы
        for i = 1, 20 do
            local particle = emitter:Add("sprites/light_glow02_add", pos + VectorRand() * 30)
            if particle then
                particle:SetVelocity(VectorRand() * 200)
                particle:SetDieTime(2 + math.random() * 1)
                particle:SetStartAlpha(255)
                particle:SetEndAlpha(0)
                particle:SetStartSize(5)
                particle:SetEndSize(0)
                particle:SetColor(255, 100, 100)
                particle:SetGravity(Vector(0, 0, -100))
                particle:SetCollide(true)
                particle:SetBounce(0.3)
            end
        end
    end
    
    emitter:Finish()
end

-- Глобальные функции для использования в других файлах
function GM:CreateDisintegrationEffect(pos, scale)
    DisintegrationEffects:CreateDisintegrationEffect(pos, scale)
end

function GM:CreateAnimatedDisintegration(ent, duration)
    DisintegrationEffects:CreateAnimatedDisintegration(ent, duration)
end

function GM:CreateParticleDisintegration(ent, particleType)
    DisintegrationEffects:CreateParticleDisintegration(ent, particleType)
end

-- Хук для автоматической дезинтеграции пропов
hook.Add("EntityTakeDamage", "GModsaken_PropDisintegration", function(target, dmginfo)
    if not IsValid(target) or not target.IsGModsakenProp then return end
    
    local attacker = dmginfo:GetAttacker()
    if not IsValid(attacker) or not attacker:IsPlayer() then return end
    
    -- Проверяем, что атакующий - убийца с топором
    if attacker:Team() == (GM.TEAM_KILLER or 3) then
        local weapon = attacker:GetActiveWeapon()
        if IsValid(weapon) and weapon:GetClass() == "weapon_gmodsaken_axe" then
            -- Создаем эффект дезинтеграции
            local pos = target:GetPos()
            DisintegrationEffects:CreateDisintegrationEffect(pos, 1.2)
            
            -- Анимированное исчезновение пропа
            DisintegrationEffects:CreateAnimatedDisintegration(target, 1.0)
            
            -- Уведомляем владельца пропа
            if IsValid(target.Owner) and target.Owner:IsPlayer() then
                target.Owner:ChatPrint("Ваш проп был дезинтегрирован убийцей!")
            end
            
            -- Останавливаем обработку урона
            return true
        end
    end
end)

-- Команда для тестирования эффектов
concommand.Add("gmodsaken_test_disintegration", function(ply, cmd, args)
    if not IsValid(ply) then return end
    
    local pos = ply:GetPos() + Vector(0, 0, 50)
    local effectType = args[1] or "default"
    
    if effectType == "default" then
        DisintegrationEffects:CreateDisintegrationEffect(pos, 1.0)
        ply:ChatPrint("Тест эффекта дезинтеграции создан!")
    elseif effectType == "glass" then
        DisintegrationEffects:CreateParticleDisintegration(ply, "glass")
        ply:ChatPrint("Тест стеклянного эффекта создан!")
    elseif effectType == "metal" then
        DisintegrationEffects:CreateParticleDisintegration(ply, "metal")
        ply:ChatPrint("Тест металлического эффекта создан!")
    else
        ply:ChatPrint("Использование: gmodsaken_test_disintegration [default|glass|metal]")
    end
end)

print("[GModsaken] Disintegration effects system initialized successfully!") 