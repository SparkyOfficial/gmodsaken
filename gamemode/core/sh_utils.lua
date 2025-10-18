--[[
    GModsaken - Utility Functions
    Copyright (C) 2024 GModsaken Contributors
    
    Utility functions used throughout the gamemode.
    Author: Андрій Будильников
]]

-- Ensure GM table exists
local GM = _G.GM or GAMEMODE
_G.GM = GM
_G.GAMEMODE = GM

-- Базовое разрешение для масштабирования
local BASE_WIDTH = 1920
local BASE_HEIGHT = 1080

-- Функции для адаптивного масштабирования
function GM:X(val)
    return (ScrW() / BASE_WIDTH) * val
end

function GM:Y(val)
    return (ScrH() / BASE_HEIGHT) * val
end

-- Get font scale for UI elements
function GM:GetFontScale()
    local screenW, screenH = ScrW(), ScrH()
    local scale_w = screenW / 1920
    local scale_h = screenH / 1080
    return scale_w, scale_h
end

-- Get panel scale for UI elements
function GM:GetPanelScale()
    local screenW, screenH = ScrW(), ScrH()
    local scale_w = screenW / 640
    local scale_h = screenH / 480
    return scale_w, scale_h
end

print("[GModsaken] Utility functions loaded")