--[[
    GModsaken - Flash on Ready System
    Copyright (C) 2024 GModsaken Contributors
]]

-- Функция для мигания иконки в панели задач
local function FlashTaskbarIcon()
    if system.IsWindows() then
        system.FlashWindow()
    end
end

-- Эффект вспышки при готовности к игре
local flashAlpha = 0
local flashDuration = 2
local flashStartTime = 0

-- Обработка начала подготовки
net.Receive("GModsaken_UpdateGameState", function()
    local gameState = net.ReadString()
    local gameTimer = net.ReadInt(32)
    
    if gameState == "PREPARING" and gameTimer == GM.LobbyTime then
        -- Запускаем эффект вспышки
        flashStartTime = CurTime()
        flashAlpha = 255
    end
end)

-- Отрисовка эффекта вспышки
hook.Add("HUDPaint", "GModsaken_FlashEffect", function()
    if flashAlpha > 0 then
        local elapsed = CurTime() - flashStartTime
        local progress = elapsed / flashDuration
        
        if progress >= 1 then
            flashAlpha = 0
        else
            flashAlpha = 255 * (1 - progress)
        end
        
        -- Рисуем белый экран
        surface.SetDrawColor(255, 255, 255, flashAlpha)
        surface.DrawRect(0, 0, ScrW(), ScrH())
        
        -- Текст "ПОДГОТОВКА К ИГРЕ"
        if flashAlpha > 100 then
            local text = "ПОДГОТОВКА К ИГРЕ"
            local fontSize = 48
            local textW, textH = surface.GetTextSize(text)
            
            draw.SimpleText(text, "DermaLarge", ScrW()/2, ScrH()/2, Color(0, 0, 0, flashAlpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    end
end)
