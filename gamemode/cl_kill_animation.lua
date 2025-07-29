--[[
    GModsaken - Kill Animation System (Client)
    Copyright (C) 2024 GModsaken Contributors
]]

-- Ensure GM table exists
if not _G.GM then
    _G.GM = {}
end
local GM = _G.GM
_G.GAMEMODE = GM

-- Клиентские переменные для анимации убийства
local killAnimationActive = false
local killAnimationKiller = nil
local killAnimationVictim = nil
local killAnimationStartTime = 0
local killAnimationKillerPos = Vector(0, 0, 0)
local killAnimationVictimPos = Vector(0, 0, 0)

-- Обработка начала анимации убийства
net.Receive("GModsaken_KillAnimation", function()
    local killer = net.ReadEntity()
    local victim = net.ReadEntity()
    local killerPos = net.ReadVector()
    local victimPos = net.ReadVector()
    
    if not IsValid(killer) or not IsValid(victim) then return end
    
    -- Сохраняем данные анимации
    killAnimationActive = true
    killAnimationKiller = killer
    killAnimationVictim = victim
    killAnimationStartTime = CurTime()
    killAnimationKillerPos = killerPos
    killAnimationVictimPos = victimPos
    
    print("[GModsaken] Kill animation started on client")
end)

-- Обработка завершения анимации убийства
net.Receive("GModsaken_KillAnimationEnd", function()
    local killer = net.ReadEntity()
    
    if not IsValid(killer) then return end
    
    -- Сбрасываем анимацию
    killAnimationActive = false
    killAnimationKiller = nil
    killAnimationVictim = nil
    killAnimationStartTime = 0
    
    print("[GModsaken] Kill animation ended on client")
end)

print("[GModsaken] Kill animation client system loaded")
