--[[
    GModsaken - HUD System (Client)
    Copyright (C) 2024 GModsaken Contributors
    
    Modular HUD system with improved performance and maintainability.
    Author: Андрій Будильников
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
    
    -- Update GM with the new game state
    if GM then
        GM.GameState = gameState
        GM.GameTimer = gameTimer
    end
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

-- Основной HUDPaint хук
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
    
    -- Отрисовка компонентов HUD
    if GM.DrawGameStateComponent then
        GM:DrawGameStateComponent(screenW, screenH)
    end
    
    if GM.DrawPlayerInfoComponent then
        GM:DrawPlayerInfoComponent(ply, screenW, screenH)
    end
    
    if GM.DrawHealthComponent then
        GM:DrawHealthComponent(ply, screenW, screenH)
    end
    
    if GM.DrawArmorComponent then
        GM:DrawArmorComponent(ply, screenW, screenH)
    end
    
    if GM.DrawStaminaComponent then
        GM:DrawStaminaComponent(ply, screenW, screenH)
    end
    
    if GM.DrawArmorInfoComponent then
        GM:DrawArmorInfoComponent(ply, screenW, screenH)
    end
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

-- Скрытие стандартного HUD
hook.Add("HUDShouldDraw", "GModsaken_HideDefaultHUD", function(name)
    if name == "CHudHealth" or name == "CHudBattery" or name == "CHudSecondaryAmmo" then
        return false
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

-- Команда для отладки HUD
concommand.Add("gmodsaken_hud_debug", function()
    print("Game State: " .. gameState)
    print("Game Timer: " .. gameTimer)
    print("Player Stamina: " .. playerStamina .. "/" .. playerMaxStamina)
end)
