--[[
    GModsaken - HUD System (Client)
    Copyright (C) 2024 GModsaken Contributors
]]

-- Ensure GM table exists
local GM = _G.GM or GAMEMODE
_G.GM = GM
_G.GAMEMODE = GM

-- Инициализация HUD
function GM:InitializeHUD()
    print("GModsaken: HUD инициализирован")
end

-- Переменные для HUD
local playerStamina = 100
local playerMaxStamina = 100
local gameState = "LOBBY"
local gameTimer = 0

-- Переменная для ослепления
local blindEndTime = 0
local isBlinded = false

-- Переменная для радара
local radarEndTime = 0
local isRadarActive = false

-- Переменные для музыки Мясного
local chaseMusic = nil
local isChaseMusicPlaying = false

-- Обновление стамины
net.Receive("GModsaken_UpdateStamina", function()
    playerStamina = net.ReadInt(32)
    playerMaxStamina = net.ReadInt(32)
end)

-- Обновление состояния игры
net.Receive("GModsaken_UpdateGameState", function()
    gameState = net.ReadString()
    gameTimer = net.ReadInt(32)
end)

-- Получение команды ослепления
net.Receive("GModsaken_BlindPlayer", function()
    local duration = net.ReadFloat()
    blindEndTime = CurTime() + duration
    isBlinded = true
    
    -- Звук ослепления
    surface.PlaySound("weapons/flashbang/flashbang_explode1.wav")
end)

-- Получение команды радара
net.Receive("GModsaken_ShowRadar", function()
    local duration = net.ReadFloat()
    radarEndTime = CurTime() + duration
    isRadarActive = true
    
    -- Звук радара
    surface.PlaySound("buttons/button15.wav")
end)

-- Получение команды воспроизведения музыки Мясного
net.Receive("GModsaken_PlayChaseMusic", function()
    -- Если музыка уже играет, не включаем снова
    if isChaseMusicPlaying then
        return
    end
    
    -- Создаем звук если его нет
    if not chaseMusic then
        chaseMusic = CreateSound(LocalPlayer(), "gmodsaken/myasnoi_chase.mp3")
        if chaseMusic and type(chaseMusic.SetVolume) == "function" then
            local ok = pcall(function() chaseMusic:SetVolume(0.3) end)
            if ok and type(chaseMusic.SetDSP) == "function" then
                pcall(function() chaseMusic:SetDSP(0) end)
            end
        else
            print("GModsaken: Ошибка создания звука музыки Мясного")
            return
        end
    end
    
    -- Воспроизводим музыку только если звук создан
    if chaseMusic then
        chaseMusic:Play()
        isChaseMusicPlaying = true
        print("GModsaken: Музыка Мясного включена")
    end
end)

-- Получение команды остановки музыки Мясного
net.Receive("GModsaken_StopChaseMusic", function()
    if isChaseMusicPlaying and chaseMusic then
        chaseMusic:Stop()
        isChaseMusicPlaying = false
        print("GModsaken: Музыка Мясного остановлена")
    end
end)

-- Отрисовка HUD
function GM:DrawHUD()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    
    local screenW, screenH = ScrW(), ScrH()
    
    -- Основная информация игрока
    self:DrawPlayerInfo(ply, screenW, screenH)
    
    -- Информация о стамине
    self:DrawStaminaInfo(ply, screenW, screenH)
    
    -- Информация о броне
    self:DrawArmorInfo(ply, screenW, screenH)
    
    -- Информация о квестах
    self:DrawQuestInfo(screenW, screenH)
    
    -- Информация о раунде
    self:DrawRoundInfo(screenW, screenH)
end

-- Отрисовка информации о стамине
function GM:DrawStaminaInfo(ply, screenW, screenH)
    if not GM.GetStaminaInfo then return end
    
    local staminaInfo = GM:GetStaminaInfo(ply)
    local stamina = staminaInfo.stamina
    local maxStamina = staminaInfo.maxStamina
    local percentage = staminaInfo.percentage
    
    -- Позиция индикатора стамины (справа от здоровья)
    local x = screenW - 250
    local y = screenH - 120
    local width = 200
    local height = 20
    
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
        draw.SimpleText(warningText, "DermaDefault", x + width/2, y - 15, warningColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    
    -- Отображение стамины
    local staminaInfo = GM:GetStaminaInfo(ply)
    local staminaColor = Color(0, 255, 0)
    if staminaInfo.percentage < 30 then
        staminaColor = Color(255, 255, 0)
    end
    if staminaInfo.percentage < 10 then
        staminaColor = Color(255, 0, 0)
    end
    
    draw.SimpleText("Стамина: " .. math.floor(staminaInfo.stamina) .. "/" .. staminaInfo.maxStamina, "DermaDefault", 20, screenH - 60, staminaColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    
    -- Полоса стамины
    local staminaBarWidth = 200
    local staminaBarHeight = 10
    local staminaBarX = 20
    local staminaBarY = screenH - 40
    
    -- Фон полосы
    surface.SetDrawColor(0, 0, 0, 150)
    surface.DrawRect(staminaBarX, staminaBarY, staminaBarWidth, staminaBarHeight)
    
    -- Полоса стамины
    local staminaWidth = (staminaInfo.stamina / staminaInfo.maxStamina) * staminaBarWidth
    surface.SetDrawColor(staminaColor)
    surface.DrawRect(staminaBarX, staminaBarY, staminaWidth, staminaBarHeight)
    
    -- Граница полосы
    surface.SetDrawColor(255, 255, 255, 100)
    surface.DrawOutlinedRect(staminaBarX, staminaBarY, staminaBarWidth, staminaBarHeight)
    
    -- Отображение брони
    local armor = ply:Armor()
    if armor > 0 then
        local armorColor = Color(0, 150, 255)
        draw.SimpleText("Броня: " .. armor, "DermaDefault", 20, screenH - 80, armorColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        
        -- Полоса брони
        local armorBarWidth = 200
        local armorBarHeight = 8
        local armorBarX = 20
        local armorBarY = screenH - 95
        
        -- Фон полосы брони
        surface.SetDrawColor(0, 0, 0, 150)
        surface.DrawRect(armorBarX, armorBarY, armorBarWidth, armorBarHeight)
        
        -- Полоса брони (максимум 100)
        local maxArmor = 100
        local armorWidth = (armor / maxArmor) * armorBarWidth
        surface.SetDrawColor(armorColor)
        surface.DrawRect(armorBarX, armorBarY, armorWidth, armorBarHeight)
        
        -- Граница полосы брони
        surface.SetDrawColor(255, 255, 255, 100)
        surface.DrawOutlinedRect(armorBarX, armorBarY, armorBarWidth, armorBarHeight)
    end
end

-- Отрисовка информации о броне
function GM:DrawArmorInfo(ply, screenW, screenH)
    if not GM.GetArmorInfo then return end
    
    local armorInfo = GM:GetArmorInfo(ply)
    local armor = armorInfo.armor
    local maxArmor = armorInfo.maxArmor
    local multiplier = armorInfo.multiplier
    
    if maxArmor <= 0 then return end -- Не показываем если нет брони
    
    -- Позиция индикатора брони (справа от стамины)
    local x = screenW - 250
    local y = screenH - 90
    local width = 200
    local height = 20
    
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

-- Отрисовка HUD
hook.Add("HUDPaint", "GModsaken_HUD", function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    
    -- Проверяем, инициализирован ли GM
    if not GM or not GM.IsKiller or not GM.IsSurvivor then return end
    
    local screenW, screenH = ScrW(), ScrH()
    
    -- Очистка музыки при отключении
    if not IsValid(ply) and chaseMusic then
        chaseMusic:Stop()
        chaseMusic = nil
        isChaseMusicPlaying = false
    end
    
    -- HUD состояния игры (всегда видимый)
    local stateText = ""
    local stateColor = Color(255, 255, 255)
    local timerText = ""
    
    if gameState == "LOBBY" then
        stateText = "ЛОББИ"
        stateColor = Color(128, 128, 128)
        timerText = "Ожидание игроков..."
    elseif gameState == "PREPARING" then
        stateText = "ПОДГОТОВКА"
        stateColor = Color(255, 255, 0)
        timerText = "До начала: " .. gameTimer .. " сек"
    elseif gameState == "PLAYING" then
        stateText = "ИГРА"
        stateColor = Color(0, 255, 0)
        timerText = "Время: " .. math.floor(gameTimer / 60) .. ":" .. string.format("%02d", gameTimer % 60)
    elseif gameState == "ENDING" then
        stateText = "ОКОНЧАНИЕ"
        stateColor = Color(255, 0, 0)
        timerText = "До лобби: " .. gameTimer .. " сек"
    end
    
    -- Рисуем состояние игры в центре экрана
    draw.SimpleText(stateText, "DermaLarge", screenW/2, 50, stateColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    draw.SimpleText(timerText, "DermaDefault", screenW/2, 80, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    
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
    
    draw.SimpleText("Роль: " .. roleText, "DermaDefault", 20, 60, roleColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    
    -- HUD здоровья
    local healthBarW = 200
    local healthBarH = 20
    local healthBarX = 20
    local healthBarY = screenH - 50
    
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
    
    -- HUD брони
    if ply:Armor() > 0 then
        local armorBarW = 200
        local armorBarH = 15
        local armorBarX = 20
        local armorBarY = screenH - 110
        
        -- Фон брони
        draw.RoundedBox(4, armorBarX, armorBarY, armorBarW, armorBarH, Color(0, 0, 0, 150))
        
        -- Полоска брони
        local armorPercent = ply:Armor() / 100
        draw.RoundedBox(4, armorBarX + 2, armorBarY + 2, (armorBarW - 4) * armorPercent, armorBarH - 4, Color(0, 100, 255))
        
        -- Текст брони
        draw.SimpleText("Броня: " .. ply:Armor(), "DermaDefault", armorBarX + armorBarW/2, armorBarY + armorBarH/2, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    
    -- HUD выбранного персонажа
    if ply.SelectedCharacter and GM.GetCharacter then
        local character = GM:GetCharacter(ply.SelectedCharacter)
        if character then
            -- Имя персонажа в правом верхнем углу
            draw.SimpleText("Персонаж: " .. character.name, "DermaDefault", screenW - 20, 20, Color(255, 255, 255), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
            
            -- Описание персонажа
            if character.description then
                draw.SimpleText(character.description, "DermaDefault", screenW - 20, 40, Color(200, 200, 200), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
            end
            
            -- Способности персонажа (если есть)
            if character.abilities then
                local yPos = 60
                for abilityName, abilityDesc in pairs(character.abilities) do
                    draw.SimpleText("• " .. abilityName .. ": " .. abilityDesc, "DermaDefault", screenW - 20, yPos, Color(150, 255, 150), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
                    yPos = yPos + 15
                end
            end
        end
    else
        -- Если персонаж не выбран
        draw.SimpleText("Персонаж не выбран", "DermaDefault", screenW - 20, 20, Color(255, 0, 0), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
        draw.SimpleText("Нажмите F4 в лобби", "DermaDefault", screenW - 20, 40, Color(255, 255, 0), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
    end
end)

-- Скрытие стандартного HUD
hook.Add("HUDShouldDraw", "GModsaken_HideDefaultHUD", function(name)
    if name == "CHudHealth" or name == "CHudBattery" or name == "CHudSecondaryAmmo" then
        return false
    end
end)

-- Команда для отладки HUD
concommand.Add("gmodsaken_hud_debug", function()
    print("Game State: " .. gameState)
    print("Game Timer: " .. gameTimer)
    print("Player Stamina: " .. playerStamina .. "/" .. playerMaxStamina)
end)

-- HUD ослепления
hook.Add("HUDPaint", "GModsaken_BlindEffect", function()
    if isBlinded and CurTime() < blindEndTime then
        local alpha = 255
        local timeLeft = blindEndTime - CurTime()
        
        -- Плавное ослепление
        if timeLeft > 0.5 then
            alpha = 255
        else
            alpha = (timeLeft / 0.5) * 255
        end
        
        -- Белый экран
        surface.SetDrawColor(255, 255, 255, alpha)
        surface.DrawRect(0, 0, ScrW(), ScrH())
        
        -- Убираем ослепление когда время истекло
        if CurTime() >= blindEndTime then
            isBlinded = false
        end
    end
end)

-- Очистка музыки при отключении
hook.Add("OnPlayerDisconnected", "GModsaken_CleanupMusic", function(ply)
    if ply == LocalPlayer() and chaseMusic then
        chaseMusic:Stop()
        chaseMusic = nil
        isChaseMusicPlaying = false
        print("GModsaken: Музыка очищена при отключении")
    end
end)

-- Очистка музыки при смене карты
hook.Add("ShutDown", "GModsaken_CleanupMusicOnShutdown", function()
    if chaseMusic then
        chaseMusic:Stop()
        chaseMusic = nil
        isChaseMusicPlaying = false
        print("GModsaken: Музыка очищена при выключении сервера")
    end
end) 