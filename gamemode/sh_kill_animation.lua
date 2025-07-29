--[[
    GModsaken - Kill Animation System
    Copyright (C) 2024 GModsaken Contributors
]]

-- Ensure GM table exists
if not _G.GM then
    _G.GM = {}
end
local GM = _G.GM
_G.GAMEMODE = GM

-- Система анимации убийства
GM.KillAnimationSystem = {
    AnimationDuration = 3.0, -- Длительность анимации в секундах
    ThirdPersonDistance = 150, -- Расстояние камеры в третьем лице
    KillAnimationSequence = "gesture_wave", -- Анимация убийства
    VictimAnimationSequence = "gesture_me" -- Анимация жертвы
}

-- Начало анимации убийства
function GM:StartKillAnimation(killer, victim)
    if not IsValid(killer) or not IsValid(victim) then return end
    if not self:IsKiller(killer) then return end
    
    -- Сохраняем состояние
    killer.KillAnimationActive = true
    killer.KillAnimationStartTime = CurTime()
    killer.KillAnimationVictim = victim
    
    -- Сохраняем позиции
    killer.KillAnimationKillerPos = killer:GetPos()
    killer.KillAnimationVictimPos = victim:GetPos()
    
    -- Останавливаем движение
    killer:SetMoveType(MOVETYPE_NONE)
    victim:SetMoveType(MOVETYPE_NONE)
    
    -- Устанавливаем анимации
    killer:SetSequence(self.KillAnimationSystem.KillAnimationSequence)
    victim:SetSequence(self.KillAnimationSystem.KillAnimationSystem.VictimAnimationSequence)
    
    -- Переключаем в третье лицо для убийцы
    if SERVER then
        net.Start("GModsaken_KillAnimation")
        net.WriteEntity(killer)
        net.WriteEntity(victim)
        net.WriteVector(killer:GetPos())
        net.WriteVector(victim:GetPos())
        net.Broadcast()
    end
    
    -- Запускаем таймер завершения анимации
    timer.Create("GModsaken_KillAnimation_" .. killer:EntIndex(), self.KillAnimationSystem.AnimationDuration, 1, function()
        if IsValid(killer) and IsValid(victim) then
            self:EndKillAnimation(killer, victim)
        end
    end)
    
    print("[GModsaken] Kill animation started for " .. killer:Nick() .. " killing " .. victim:Nick())
end

-- Завершение анимации убийства
function GM:EndKillAnimation(killer, victim)
    if not IsValid(killer) then return end
    
    -- Восстанавливаем движение
    killer:SetMoveType(MOVETYPE_WALK)
    if IsValid(victim) then
        victim:SetMoveType(MOVETYPE_WALK)
    end
    
    -- Сбрасываем анимации
    killer:SetSequence(ACT_HL2MP_IDLE)
    if IsValid(victim) then
        victim:SetSequence(ACT_HL2MP_IDLE)
    end
    
    -- Убиваем жертву
    if IsValid(victim) and victim:Alive() then
        victim:Kill()
    end
    
    -- Сбрасываем состояние
    killer.KillAnimationActive = false
    killer.KillAnimationStartTime = nil
    killer.KillAnimationVictim = nil
    
    -- Возвращаем в первое лицо
    if SERVER then
        net.Start("GModsaken_KillAnimationEnd")
        net.WriteEntity(killer)
        net.Broadcast()
    end
    
    print("[GModsaken] Kill animation ended for " .. killer:Nick())
end

-- Проверка активности анимации убийства
function GM:IsKillAnimationActive(ply)
    if not IsValid(ply) then return false end
    return ply.KillAnimationActive or false
end

-- Получение информации об анимации убийства
function GM:GetKillAnimationInfo(ply)
    if not IsValid(ply) then return nil end
    if not ply.KillAnimationActive then return nil end
    
    local elapsed = CurTime() - (ply.KillAnimationStartTime or CurTime())
    local progress = math.Clamp(elapsed / self.KillAnimationSystem.AnimationDuration, 0, 1)
    
    return {
        active = true,
        elapsed = elapsed,
        progress = progress,
        victim = ply.KillAnimationVictim,
        killerPos = ply.KillAnimationKillerPos,
        victimPos = ply.KillAnimationVictimPos
    }
end

-- Хук для обработки убийств
hook.Add("PlayerDeath", "GModsaken_KillAnimationDeath", function(victim, inflictor, attacker)
    if not IsValid(attacker) or not attacker:IsPlayer() then return end
    if not GM:IsKiller(attacker) then return end
    if GM:IsKillAnimationActive(attacker) then return end -- Уже в анимации
    
    -- Запускаем анимацию убийства
    GM:StartKillAnimation(attacker, victim)
end)

-- Хук для блокировки движения во время анимации
hook.Add("Move", "GModsaken_KillAnimationMove", function(ply, moveData)
    if not IsValid(ply) then return end
    if not GM:IsKillAnimationActive(ply) then return end
    
    -- Блокируем движение
    moveData:SetForwardSpeed(0)
    moveData:SetSideSpeed(0)
    moveData:SetUpSpeed(0)
end)

print("[GModsaken] Kill animation system loaded") 