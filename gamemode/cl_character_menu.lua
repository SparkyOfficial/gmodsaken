--[[ GModsaken - Character Menu System (Client) Copyright (C) 2024 GModsaken Contributors ]]

-- Ensure GM table exists
if not _G.GM then
    _G.GM = {}
end

-- Инициализация переменных для Q-меню
local qMenuOpen = false
local lastQPress = 0
local propCooldown = 0
local propCooldownTime = 60 -- 60 секунд кулдауна

local GM = _G.GM
_G.GAMEMODE = GM

-- Переменные для меню
local characterMenuOpen = false
local lastF4Press = 0

-- Переменные для Q-меню
local qMenuOpen = false
local lastQPress = 0
local propCooldown = 0
local propCooldownTime = 60 -- секунды

-- Создание простого меню выбора персонажа
function GM:CreateCharacterMenu()
    if characterMenuOpen then return end
    
    -- Проверяем, что игрок в лобби
    if not GM.GameState or (GM.GameState ~= "LOBBY" and GM.GameState ~= "PREPARING") then
        chat.AddText(Color(255, 0, 0), "Меню персонажей доступно только в лобби!")
        return
    end
    
    characterMenuOpen = true
    gui.EnableScreenClicker(true) -- Включаем курсор мыши
    surface.PlaySound("buttons/button15.wav")
    print("GModsaken: Меню персонажей открыто")
end

-- Отрисовка простого меню
local function DrawCharacterMenu()
    if not characterMenuOpen then return end
    
    local screenW, screenH = ScrW(), ScrH()
    local menuW, menuH = 800, 600
    local menuX, menuY = (screenW - menuW) / 2, (screenH - menuH) / 2
    
    -- Затемнение фона
    draw.RoundedBox(0, 0, 0, screenW, screenH, Color(0, 0, 0, 150))
    
    -- Основной фон меню
    draw.RoundedBox(12, menuX, menuY, menuW, menuH, Color(30, 30, 40, 250))
    
    -- Рамка меню
    draw.RoundedBoxEx(12, menuX + 2, menuY + 2, menuW - 4, menuH - 4, Color(100, 150, 255, 50), false, false, false, false, true, true, true, true)
    
    -- Заголовок
    draw.SimpleText("🎭 Выбор персонажа", "DermaLarge", menuX + menuW/2, menuY + 20, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
    
    -- Получаем список персонажей-выживших
    local survivorCharacters = GM.SurvivorCharacters or {}
    
    -- Отладочная информация
    print("GModsaken: Survivor characters count: " .. #survivorCharacters)
    for i, char in pairs(survivorCharacters) do
        print("Character " .. i .. ": " .. (char.name or "UNNAMED"))
    end
    
    if #survivorCharacters == 0 then
        -- Если персонажи не загружены, показываем сообщение
        draw.SimpleText("Персонажи не загружены. Попробуйте перезайти в игру.", "DermaDefault", menuX + menuW/2, menuY + menuH/2, Color(255, 0, 0), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        return
    end
    
    -- Создаем сетку персонажей
    local cardW, cardH = 200, 150
    local cardsPerRow = 3
    local startX = menuX + 50
    local startY = menuY + 80
    local spacing = 20
    
    for i, character in pairs(survivorCharacters) do
        local row = math.floor((i - 1) / cardsPerRow)
        local col = (i - 1) % cardsPerRow
        local cardX = startX + col * (cardW + spacing)
        local cardY = startY + row * (cardH + spacing)
        
        -- Фон карточки
        draw.RoundedBox(8, cardX, cardY, cardW, cardH, Color(50, 50, 60, 200))
        draw.RoundedBoxEx(8, cardX + 2, cardY + 2, cardW - 4, cardH - 4, Color(70, 70, 80, 200), false, false, false, false, true, true, true, true)
        
        -- Имя персонажа
        draw.SimpleText(character.name, "DermaDefault", cardX + cardW/2, cardY + 15, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        
        -- Описание
        local descText = character.description or "Нет описания"
        draw.SimpleText(descText, "DermaDefault", cardX + 10, cardY + 35, Color(200, 200, 200, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        
        -- Статистика
        draw.SimpleText("❤ " .. character.health .. " HP", "DermaDefault", cardX + 10, cardY + 70, Color(255, 100, 100, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        draw.SimpleText("🛡 " .. (character.armor or 0) .. " Броня", "DermaDefault", cardX + 10, cardY + 85, Color(100, 150, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        draw.SimpleText("⚡ " .. (character.speed or 1.0) .. "x Скорость", "DermaDefault", cardX + 10, cardY + 100, Color(255, 200, 100, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        
        -- Кнопка выбора
        draw.RoundedBox(4, cardX + 10, cardY + cardH - 35, cardW - 20, 25, Color(100, 150, 255, 200))
        draw.SimpleText("ВЫБРАТЬ", "DermaDefault", cardX + cardW/2, cardY + cardH - 22, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    
    -- Информация о системе
    draw.SimpleText("Убийца выбирается случайно в начале раунда! Можно сменить персонажа в лобби.", "DermaDefault", menuX + menuW/2, menuY + menuH - 30, Color(255, 255, 0), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    
    -- Подсказка
    draw.SimpleText("Нажмите F4 для закрытия • Кликните на персонажа для выбора", "DermaDefault", menuX + menuW/2, menuY + menuH - 10, Color(150, 150, 150, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

-- Обработка кликов мыши
hook.Add("GUIMousePressed", "GModsaken_CharacterMenuClick", function(mouseCode)
    if not characterMenuOpen or mouseCode ~= MOUSE_LEFT then return end
    
    local screenW, screenH = ScrW(), ScrH()
    local menuW, menuH = 800, 600
    local menuX, menuY = (screenW - menuW) / 2, (screenH - menuH) / 2
    
    local mouseX, mouseY = gui.MousePos()
    
    -- Получаем список персонажей
    local survivorCharacters = GM.SurvivorCharacters or {}
    
    -- Создаем сетку персонажей
    local cardW, cardH = 200, 150
    local cardsPerRow = 3
    local startX = menuX + 50
    local startY = menuY + 80
    local spacing = 20
    
    for i, character in pairs(survivorCharacters) do
        local row = math.floor((i - 1) / cardsPerRow)
        local col = (i - 1) % cardsPerRow
        local cardX = startX + col * (cardW + spacing)
        local cardY = startY + row * (cardH + spacing)
        
        if mouseX >= cardX and mouseX <= cardX + cardW and mouseY >= cardY and mouseY <= cardY + cardH then
            -- Проверяем клик по кнопке выбора
            local buttonX = cardX + 10
            local buttonY = cardY + cardH - 35
            local buttonW = cardW - 20
            local buttonH = 25
            
            if mouseX >= buttonX and mouseX <= buttonX + buttonW and mouseY >= buttonY and mouseY <= buttonY + buttonH then
                GM:SelectCharacter(character.name)
            end
            
            return
        end
    end
end)

-- Выбор персонажа
function GM:SelectCharacter(characterName)
    if not GM.CanPlayerSelectCharacter then
        chat.AddText(Color(255, 0, 0), "Система персонажей не инициализирована!")
        return
    end
    
    if not GM:CanPlayerSelectCharacter(LocalPlayer(), characterName) then
        chat.AddText(Color(255, 0, 0), "Нельзя выбрать этого персонажа!")
        return
    end
    
    -- Отправляем запрос на сервер
    net.Start("GModsaken_SelectCharacter")
    net.WriteString(characterName)
    net.SendToServer()
    
    -- Закрываем меню
    characterMenuOpen = false
    gui.EnableScreenClicker(false) -- Отключаем курсор мыши
    surface.PlaySound("buttons/button15.wav")
    print("GModsaken: Персонаж выбран, меню закрыто")
end

-- Команда для открытия меню
concommand.Add("gmodsaken_character_menu", function()
    if not GM or not GM.GameState then
        chat.AddText(Color(255, 0, 0), "Геймод не инициализирован!")
        return
    end
    
    if GM.GameState == "LOBBY" or GM.GameState == "PREPARING" then
        GM:CreateCharacterMenu()
    else
        chat.AddText(Color(255, 0, 0), "Меню персонажей доступно только в лобби!")
    end
end)

-- Привязка к клавише F4
hook.Add("Think", "GModsaken_CharacterMenuKey", function()
    if input.IsKeyDown(KEY_F4) then
        local currentTime = CurTime()
        if currentTime - lastF4Press > 1.0 then -- Увеличиваем задержку до 1 секунды
            lastF4Press = currentTime
            
            if not characterMenuOpen then
                if not GM or not GM.GameState then
                    chat.AddText(Color(255, 0, 0), "Геймод не инициализирован!")
                    return
                end
                
                if GM.GameState == "LOBBY" or GM.GameState == "PREPARING" then
                    GM:CreateCharacterMenu()
                else
                    chat.AddText(Color(255, 0, 0), "Меню персонажей доступно только в лобби!")
                end
            else
                characterMenuOpen = false
                gui.EnableScreenClicker(false) -- Отключаем курсор мыши
                surface.PlaySound("buttons/button15.wav")
                print("GModsaken: Меню персонажей закрыто")
            end
        end
    end
end)

-- Обработка ответа сервера о выборе персонажа
net.Receive("GModsaken_CharacterSelected", function()
    local characterName = net.ReadString()
    local success = net.ReadBool()
    
    if success then
        chat.AddText(Color(0, 255, 0), "Персонаж успешно выбран: " .. characterName)
    else
        chat.AddText(Color(255, 0, 0), "Ошибка выбора персонажа!")
    end
end)

-- Обработка команды открытия меню от сервера
net.Receive("GModsaken_OpenCharacterMenu", function()
    if GM and GM.CreateCharacterMenu then
        GM:CreateCharacterMenu()
    end
end)

-- Отрисовка меню
hook.Add("HUDPaint", "GModsaken_CharacterMenuPaint", DrawCharacterMenu)

print("GModsaken: Простое меню персонажей загружено! Нажмите F4 для открытия.")

-- Создание Q-меню для выживших
function GM:CreateQMenu()
    if qMenuOpen then return end
    
    -- Проверяем, что игрок выживший и в игре
    if not GM.GameState or GM.GameState ~= "PLAYING" then
        chat.AddText(Color(255, 0, 0), "Q-меню доступно только во время игры!")
        return
    end
    
    local ply = LocalPlayer()
    if not IsValid(ply) or ply:Team() ~= GM.TEAM_SURVIVOR then
        chat.AddText(Color(255, 0, 0), "Q-меню доступно только выжившим!")
        return
    end
    
    qMenuOpen = true
    gui.EnableScreenClicker(true)
    surface.PlaySound("buttons/button15.wav")
    
    -- Создаем меню
    local frame = vgui.Create("DFrame")
    frame:SetSize(400, 300)
    frame:Center()
    frame:SetTitle("Q-меню - Спавн пропов")
    frame:MakePopup()
    frame:SetDraggable(false)
    
    frame.OnClose = function()
        qMenuOpen = false
        gui.EnableScreenClicker(false)
    end
    
    -- Информация о кулдауне
    local cooldownLabel = vgui.Create("DLabel", frame)
    cooldownLabel:SetPos(20, 40)
    cooldownLabel:SetSize(360, 30)
    cooldownLabel:SetText("")
    cooldownLabel:SetTextColor(Color(255, 255, 255))
    
    -- Функция обновления кулдауна
    local function UpdateCooldown()
        local remaining = math.max(0, propCooldown - CurTime())
        if remaining > 0 then
            cooldownLabel:SetText("Кулдаун: " .. math.ceil(remaining) .. " сек")
            cooldownLabel:SetTextColor(Color(255, 0, 0))
        else
            cooldownLabel:SetText("Готово к использованию!")
            cooldownLabel:SetTextColor(Color(0, 255, 0))
        end
    end
    
    -- Кнопка спавна пропа
    local spawnButton = vgui.Create("DButton", frame)
    spawnButton:SetPos(20, 80)
    spawnButton:SetSize(360, 50)
    spawnButton:SetText("Спавн пропа (60 сек кулдаун)")
    spawnButton:SetTextColor(Color(255, 255, 255))
    
    spawnButton.DoClick = function()
        if CurTime() < propCooldown then
            chat.AddText(Color(255, 0, 0), "Подождите " .. math.ceil(propCooldown - CurTime()) .. " секунд!")
            return
        end
        
        -- Отправляем команду на сервер
        net.Start("GModsaken_SpawnProp")
        net.SendToServer()
        
        -- Устанавливаем кулдаун
        propCooldown = CurTime() + propCooldownTime
        
        chat.AddText(Color(0, 255, 0), "Проп создан!")
        frame:Close()
    end
    
    -- Кнопка закрытия
    local closeButton = vgui.Create("DButton", frame)
    closeButton:SetPos(20, 150)
    closeButton:SetSize(360, 40)
    closeButton:SetText("Закрыть")
    closeButton:SetTextColor(Color(255, 255, 255))
    
    closeButton.DoClick = function()
        frame:Close()
    end
    
    -- Информация
    local infoLabel = vgui.Create("DLabel", frame)
    infoLabel:SetPos(20, 200)
    infoLabel:SetSize(360, 80)
    infoLabel:SetText("Информация:\n• Пропы нельзя заморозить\n• Убийца может разрушить пропы\n• Используйте для строительства баррикад")
    infoLabel:SetTextColor(Color(200, 200, 200))
    
    -- Обновляем кулдаун каждую секунду
    timer.Create("GModsaken_QMenuCooldown" .. LocalPlayer():SteamID64(), 1, 0, UpdateCooldown)
    UpdateCooldown()
    
    -- Удаляем старый таймер при закрытии
    frame.OnRemove = function()
        if timer.Exists("GModsaken_QMenuCooldown" .. LocalPlayer():SteamID64()) then
            timer.Remove("GModsaken_QMenuCooldown" .. LocalPlayer():SteamID64())
        end
    end
end

-- Хук для обработки нажатия Q
hook.Add("Think", "GModsaken_QMenuKey", function()
    if input.IsKeyDown(KEY_Q) then
        if CurTime() - lastQPress > 0.3 then -- Антиспам
            lastQPress = CurTime()
            
            local ply = LocalPlayer()
            if IsValid(ply) and ply:Team() == GM.TEAM_SURVIVOR then
                GM:CreateQMenu()
            end
        end
    end
end)
