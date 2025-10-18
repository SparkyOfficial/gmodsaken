--[[
    GModsaken - HUD Components
    Copyright (C) 2024 GModsaken Contributors
    
    Modular HUD components for better performance and maintainability.
    Author: Андрій Будильников
]]

-- Ensure GM table exists
local GM = _G.GM or GAMEMODE
_G.GM = GM
_G.GAMEMODE = GM

-- Cache for UI calculations that don't change every frame
local cachedScaleW, cachedScaleH = nil, nil
local lastScaleUpdate = 0
local scaleUpdateInterval = 0.1 -- Update scale every 100ms

-- Get panel scale with caching
function GM:GetCachedPanelScale()
    local currentTime = CurTime()
    if currentTime - lastScaleUpdate > scaleUpdateInterval then
        cachedScaleW, cachedScaleH = self:GetPanelScale()
        lastScaleUpdate = currentTime
    end
    return cachedScaleW, cachedScaleH
end

-- Draw player info component
function GM:DrawPlayerInfoComponent(ply, screenW, screenH)
    if not IsValid(ply) then return end
    
    -- HUD роли игрока
    local roleText = "НЕИЗВЕСТНО"
    local roleColor = Color(255, 255, 255)
    
    if ply:Team() == GM.TEAM_SPECTATOR then
        roleText = "НАБЛЮДАТЕЛЬ"
        roleColor = Color(150, 150, 150)
    elseif ply:Team() == GM.TEAM_SURVIVOR then
        roleText = "ВЫЖИВШИЙ"
        roleColor = Color(0, 255, 0)
    elseif ply:Team() == GM.TEAM_KILLER then
        roleText = "УБИЙЦА"
        roleColor = Color(255, 0, 0)
    end
    
    draw.SimpleText("Роль: " .. roleText, "DermaDefault", GM:X(20), GM:Y(60), roleColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    
    -- HUD выбранного персонажа
    if ply.SelectedCharacter and GM.GetCharacter then
        local character = GM:GetCharacter(ply.SelectedCharacter)
        if character then
            -- Имя персонажа в правом верхнем углу
            draw.SimpleText("Персонаж: " .. character.name, "DermaDefault", screenW - GM:X(20), GM:Y(20), Color(255, 255, 255), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
            
            -- Описание персонажа
            if character.description then
                draw.SimpleText(character.description, "DermaDefault", screenW - GM:X(20), GM:Y(40), Color(200, 200, 200), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
            end
        end
    else
        -- Если персонаж не выбран
        draw.SimpleText("Персонаж не выбран", "DermaDefault", screenW - GM:X(20), GM:Y(20), Color(255, 0, 0), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
        draw.SimpleText("Нажмите F4 в лобби", "DermaDefault", screenW - GM:X(20), GM:Y(40), Color(255, 255, 0), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
    end
end

-- Draw game state component
function GM:DrawGameStateComponent(screenW, screenH)
    local stateText = ""
    local stateColor = Color(255, 255, 255)
    local timerText = ""
    
    if GM.GameState == "LOBBY" then
        stateText = "ЛОББИ"
        stateColor = Color(128, 128, 128)
        timerText = "Ожидание игроков..."
    elseif GM.GameState == "PREPARING" then
        stateText = "ПОДГОТОВКА"
        stateColor = Color(255, 255, 0)
        timerText = "До начала: " .. (GM.GameTimer or 0) .. " сек"
    elseif GM.GameState == "PLAYING" then
        stateText = "ИГРА"
        stateColor = Color(0, 255, 0)
        local time = GM.GameTimer or 0
        timerText = "Время: " .. math.floor(time / 60) .. ":" .. string.format("%02d", time % 60)
    elseif GM.GameState == "ENDING" then
        stateText = "ОКОНЧАНИЕ"
        stateColor = Color(255, 0, 0)
        timerText = "До лобби: " .. (GM.GameTimer or 0) .. " сек"
    end
    
    -- Рисуем состояние игры в центре экрана
    draw.SimpleText(stateText, "DermaLarge", screenW/2, GM:Y(50), stateColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    draw.SimpleText(timerText, "DermaDefault", screenW/2, GM:Y(80), Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

-- Draw health component
function GM:DrawHealthComponent(ply, screenW, screenH)
    if not IsValid(ply) then return end
    
    -- HUD здоровья
    local healthBarW = GM:X(200)
    local healthBarH = GM:Y(20)
    local healthBarX = GM:X(20)
    local healthBarY = screenH - GM:Y(50)
    
    -- Фон здоровья
    draw.RoundedBox(4, healthBarX, healthBarY, healthBarW, healthBarH, Color(0, 0, 0, 150))
    
    -- Полоска здоровья
    local healthPercent = ply:Health() / ply:GetMaxHealth()
    local healthColor = Color(0, 255, 0)
    
    if healthPercent > 0.5 then
        healthColor = Color(0, 255, 0)
    elseif healthPercent > 0.25 then
        healthColor = Color(255, 255, 0)
    else
        healthColor = Color(255, 0, 0)
    end
    
    draw.RoundedBox(4, healthBarX + 2, healthBarY + 2, (healthBarW - 4) * healthPercent, healthBarH - 4, healthColor)
    
    -- Текст здоровья
    draw.SimpleText("Здоровье: " .. ply:Health() .. "/" .. ply:GetMaxHealth(), "DermaDefault", healthBarX + healthBarW/2, healthBarY + healthBarH/2, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

-- Draw armor component
function GM:DrawArmorComponent(ply, screenW, screenH)
    if not IsValid(ply) then return end
    
    -- HUD брони
    if ply:Armor() > 0 then
        local armorBarW = GM:X(200)
        local armorBarH = GM:Y(15)
        local armorBarX = GM:X(20)
        local armorBarY = screenH - GM:Y(110)
        
        -- Фон брони
        draw.RoundedBox(4, armorBarX, armorBarY, armorBarW, armorBarH, Color(0, 0, 0, 150))
        
        -- Полоска брони
        local armorPercent = ply:Armor() / 100
        draw.RoundedBox(4, armorBarX + 2, armorBarY + 2, (armorBarW - 4) * armorPercent, armorBarH - 4, Color(0, 100, 255))
        
        -- Текст брони
        draw.SimpleText("Броня: " .. ply:Armor(), "DermaDefault", armorBarX + armorBarW/2, armorBarY + armorBarH/2, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
end

-- Draw stamina component
function GM:DrawStaminaComponent(ply, screenW, screenH)
    if not GM.GetStaminaInfo then return end
    
    local staminaInfo = GM:GetStaminaInfo(ply)
    local stamina = staminaInfo.stamina
    local maxStamina = staminaInfo.maxStamina
    local percentage = staminaInfo.percentage
    
    if maxStamina <= 0 then return end
    
    -- Позиция индикатора стамины (справа от здоровья)
    local x = screenW - GM:X(250)
    local y = screenH - GM:Y(120)
    local width = GM:X(200)
    local height = GM:Y(20)
    
    -- Цвет стамины
    local staminaColor = Color(255, 255, 0) -- Желтый
    if percentage < 25 then
        staminaColor = Color(255, 0, 0) -- Красный при низкой стамине
    elseif percentage < 50 then
        staminaColor = Color(255, 165, 0) -- Оранжевый
    end
    
    -- Фон индикатора
    draw.RoundedBox(4, x, y, width, height, Color(0, 0, 0, 150))
    
    -- Заполнение индикатора
    local fillWidth = (stamina / maxStamina) * width
    draw.RoundedBox(4, x, y, fillWidth, height, staminaColor)
    
    -- Граница
    draw.RoundedBoxEx(4, x, y, width, height, Color(255, 255, 255, 100), false, false, false, false, true, true, true, true)
    
    -- Текст
    local text = string.format("Стамина: %d/%d (%.0f%%)", stamina, maxStamina, percentage)
    draw.SimpleText(text, "DermaDefault", x + width/2, y + height/2, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    
    -- Предупреждение при низкой стамине
    if percentage <= 10 then
        local warningText = "НЕДОСТАТОЧНО СТАМИНЫ!"
        local warningColor = Color(255, 0, 0, math.abs(math.sin(CurTime() * 3)) * 255)
        draw.SimpleText(warningText, "DermaDefault", x + width/2, y - GM:Y(15), warningColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
end

-- Draw armor info component
function GM:DrawArmorInfoComponent(ply, screenW, screenH)
    if not GM.GetArmorInfo then return end
    
    local armorInfo = GM:GetArmorInfo(ply)
    local armor = armorInfo.armor
    local maxArmor = armorInfo.maxArmor
    local multiplier = armorInfo.multiplier
    
    if maxArmor <= 0 then return end -- Не показываем если нет брони
    
    -- Позиция индикатора брони (справа от стамины)
    local x = screenW - GM:X(250)
    local y = screenH - GM:Y(90)
    local width = GM:X(200)
    local height = GM:Y(20)
    
    -- Цвет брони
    local armorColor = Color(0, 150, 255) -- Синий
    
    -- Фон индикатора
    draw.RoundedBox(4, x, y, width, height, Color(0, 0, 0, 150))
    
    -- Заполнение индикатора
    local fillWidth = (armor / maxArmor) * width
    draw.RoundedBox(4, x, y, fillWidth, height, armorColor)
    
    -- Граница
    draw.RoundedBoxEx(4, x, y, width, height, Color(255, 255, 255, 100), false, false, false, false, true, true, true, true)
    
    -- Текст
    local text = string.format("Броня: %d/%d (%.0f%% урона)", armor, maxArmor, multiplier * 100)
    draw.SimpleText(text, "DermaDefault", x + width/2, y + height/2, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

print("[GModsaken] HUD components loaded")