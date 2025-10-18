--[[
    GModsaken - Character Menu System (Client)
    Copyright (C) 2024 GModsaken Contributors
    
    Improved character menu with tabbed interface.
    Author: Андрій Будильников
]]

-- Ensure GM table exists
if not _G.GM then
    _G.GM = {}
end

-- Инициализация переменных для меню
local characterMenuOpen = false
local lastF4Press = 0

local GM = _G.GM
_G.GAMEMODE = GM

-- Переменные для меню
local characterMenuOpen = false
local lastF4Press = 0

-- Создание улучшенного меню выбора персонажа
function GM:CreateCharacterMenu()
    if characterMenuOpen then return end
    
    -- Проверяем, что игрок в лобби
    if not GM.GameState or (GM.GameState ~= "LOBBY" and GM.GameState ~= "PREPARING") then
        chat.AddText(Color(255, 0, 0), "Меню персонажей доступно только в лобби!")
        return
    end
    
    -- Создаем основное окно
    local frame = vgui.Create("DFrame")
    frame:SetSize(800, 600)
    frame:Center()
    frame:SetTitle("🎭 Выбор персонажа")
    frame:MakePopup()
    frame:SetDraggable(true)
    frame:ShowCloseButton(true)
    
    -- Создаем панель с вкладками
    local sheet = vgui.Create("DPropertySheet", frame)
    sheet:Dock(FILL)
    sheet:DockMargin(10, 10, 10, 10)
    
    -- Создаем вкладку для выживших
    local survivorPanel = self:CreateSurvivorPanel()
    sheet:AddSheet("Выжившие", survivorPanel, "icon16/user.png")
    
    -- Создаем вкладку для убийц
    local killerPanel = self:CreateKillerPanel()
    sheet:AddSheet("Убийцы", killerPanel, "icon16/user_red.png")
    
    -- Создаем вкладку с новостями
    local newsPanel = self:CreateNewsPanel()
    sheet:AddSheet("Новости", newsPanel, "icon16/newspaper.png")
    
    -- Создаем вкладку с магазином
    local shopPanel = self:CreateShopPanel()
    sheet:AddSheet("Магазин", shopPanel, "icon16/money_dollar.png")
    
    characterMenuOpen = true
    surface.PlaySound("buttons/button15.wav")
    print("GModsaken: Меню персонажей открыто")
    
    -- Обработчик закрытия
    frame.OnClose = function()
        characterMenuOpen = false
        print("GModsaken: Меню персонажей закрыто")
    end
end

-- Создание панели выживших
function GM:CreateSurvivorPanel()
    local panel = vgui.Create("DPanel")
    panel:Dock(FILL)
    
    local scroll = vgui.Create("DScrollPanel", panel)
    scroll:Dock(FILL)
    scroll:DockMargin(10, 10, 10, 10)
    
    local grid = vgui.Create("DGrid", scroll)
    grid:Dock(FILL)
    grid:SetCols(3)
    grid:SetColWide(250)
    grid:SetRowHeight(200)
    
    -- Получаем список персонажей-выживших
    local survivorCharacters = GM.SurvivorCharacters or {}
    
    for i, character in pairs(survivorCharacters) do
        local card = vgui.Create("DPanel")
        card:SetSize(240, 190)
        
        function card:Paint(w, h)
            -- Фон карточки
            draw.RoundedBox(8, 0, 0, w, h, Color(50, 50, 60, 200))
            draw.RoundedBoxEx(8, 2, 2, w - 4, h - 4, Color(70, 70, 80, 200), false, false, false, false, true, true, true, true)
        end
        
        -- Имя персонажа
        local nameLabel = vgui.Create("DLabel", card)
        nameLabel:SetPos(10, 10)
        nameLabel:SetSize(220, 20)
        nameLabel:SetText(character.name)
        nameLabel:SetFont("DermaDefaultBold")
        nameLabel:SetTextColor(Color(255, 255, 255))
        
        -- Описание
        local descLabel = vgui.Create("DLabel", card)
        descLabel:SetPos(10, 35)
        descLabel:SetSize(220, 40)
        descLabel:SetText(character.description or "Нет описания")
        descLabel:SetFont("DermaDefault")
        descLabel:SetTextColor(Color(200, 200, 200))
        descLabel:SetWrap(true)
        
        -- Статистика
        local statsLabel = vgui.Create("DLabel", card)
        statsLabel:SetPos(10, 80)
        statsLabel:SetSize(220, 60)
        statsLabel:SetText(
            "❤ " .. (character.health or 100) .. " HP\n" ..
            "🛡 " .. (character.armor or 0) .. " Броня\n" ..
            "⚡ " .. (character.speed or 1.0) .. "x Скорость"
        )
        statsLabel:SetFont("DermaDefault")
        statsLabel:SetTextColor(Color(255, 255, 255))
        
        -- Кнопка выбора
        local selectButton = vgui.Create("DButton", card)
        selectButton:SetPos(10, 150)
        selectButton:SetSize(220, 30)
        selectButton:SetText("ВЫБРАТЬ")
        selectButton:SetTextColor(Color(255, 255, 255))
        
        selectButton.DoClick = function()
            GM:SelectCharacter(character.name)
        end
        
        grid:AddItem(card)
    end
    
    return panel
end

-- Создание панели убийц
function GM:CreateKillerPanel()
    local panel = vgui.Create("DPanel")
    panel:Dock(FILL)
    
    local scroll = vgui.Create("DScrollPanel", panel)
    scroll:Dock(FILL)
    scroll:DockMargin(10, 10, 10, 10)
    
    local grid = vgui.Create("DGrid", scroll)
    grid:Dock(FILL)
    grid:SetCols(3)
    grid:SetColWide(250)
    grid:SetRowHeight(200)
    
    -- Получаем список персонажей-убийц
    local killerCharacters = GM.KillerCharacters or {}
    
    for i, character in pairs(killerCharacters) do
        local card = vgui.Create("DPanel")
        card:SetSize(240, 190)
        
        function card:Paint(w, h)
            -- Фон карточки
            draw.RoundedBox(8, 0, 0, w, h, Color(60, 40, 40, 200))
            draw.RoundedBoxEx(8, 2, 2, w - 4, h - 4, Color(80, 50, 50, 200), false, false, false, false, true, true, true, true)
        end
        
        -- Имя персонажа
        local nameLabel = vgui.Create("DLabel", card)
        nameLabel:SetPos(10, 10)
        nameLabel:SetSize(220, 20)
        nameLabel:SetText(character.name)
        nameLabel:SetFont("DermaDefaultBold")
        nameLabel:SetTextColor(Color(255, 255, 255))
        
        -- Описание
        local descLabel = vgui.Create("DLabel", card)
        descLabel:SetPos(10, 35)
        descLabel:SetSize(220, 40)
        descLabel:SetText(character.description or "Нет описания")
        descLabel:SetFont("DermaDefault")
        descLabel:SetTextColor(Color(200, 200, 200))
        descLabel:SetWrap(true)
        
        -- Статистика
        local statsLabel = vgui.Create("DLabel", card)
        statsLabel:SetPos(10, 80)
        statsLabel:SetSize(220, 60)
        statsLabel:SetText(
            "❤ " .. (character.health or 100) .. " HP\n" ..
            "🛡 " .. (character.armor or 0) .. " Броня\n" ..
            "⚔ " .. (character.damage or 1.0) .. "x Урон"
        )
        statsLabel:SetFont("DermaDefault")
        statsLabel:SetTextColor(Color(255, 255, 255))
        
        -- Кнопка выбора
        local selectButton = vgui.Create("DButton", card)
        selectButton:SetPos(10, 150)
        selectButton:SetSize(220, 30)
        selectButton:SetText("ВЫБРАТЬ")
        selectButton:SetTextColor(Color(255, 255, 255))
        
        selectButton.DoClick = function()
            GM:SelectCharacter(character.name)
        end
        
        grid:AddItem(card)
    end
    
    return panel
end

-- Создание панели новостей
function GM:CreateNewsPanel()
    local panel = vgui.Create("DPanel")
    panel:Dock(FILL)
    
    local scroll = vgui.Create("DScrollPanel", panel)
    scroll:Dock(FILL)
    scroll:DockMargin(10, 10, 10, 10)
    
    -- Здесь можно добавить последние новости игры
    local header = vgui.Create("DLabel", scroll)
    header:Dock(TOP)
    header:SetTall(40)
    header:SetText("📰 Последние обновления")
    header:SetFont("DermaLarge")
    header:SetTextColor(Color(255, 255, 255))
    header:DockMargin(0, 0, 0, 20)
    
    local newsText = vgui.Create("DLabel", scroll)
    newsText:Dock(TOP)
    newsText:SetTall(200)
    newsText:SetText(
        "🎉 Добро пожаловать в GModsaken!\n\n" ..
        "🎮 Новости:\n" ..
        "• Добавлена новая система персонажей\n" ..
        "• Улучшена система стамины\n" ..
        "• Добавлены эффекты дезинтеграции\n" ..
        "• Исправлены ошибки в меню\n\n" ..
        "💡 Советы:\n" ..
        "• Используйте Q-меню для создания баррикад\n" ..
        "• Работайте в команде с другими выжившими\n" ..
        "• Каждый персонаж имеет уникальные способности"
    )
    newsText:SetFont("DermaDefault")
    newsText:SetTextColor(Color(200, 200, 200))
    newsText:SetWrap(true)
    
    return panel
end

-- Создание панели магазина
function GM:CreateShopPanel()
    local panel = vgui.Create("DPanel")
    panel:Dock(FILL)
    
    local scroll = vgui.Create("DScrollPanel", panel)
    scroll:Dock(FILL)
    scroll:DockMargin(10, 10, 10, 10)
    
    local header = vgui.Create("DLabel", scroll)
    header:Dock(TOP)
    header:SetTall(40)
    header:SetText("🛒 Магазин (в разработке)")
    header:SetFont("DermaLarge")
    header:SetTextColor(Color(255, 255, 255))
    header:DockMargin(0, 0, 0, 20)
    
    local shopText = vgui.Create("DLabel", scroll)
    shopText:Dock(TOP)
    shopText:SetTall(100)
    shopText:SetText(
        "Здесь будет магазин персонажей и предметов.\n" ..
        "Пока что выбор персонажей бесплатный!"
    )
    shopText:SetFont("DermaDefault")
    shopText:SetTextColor(Color(200, 200, 200))
    shopText:SetWrap(true)
    
    return panel
end

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
                -- Закрываем все открытые меню
                for _, v in pairs(vgui.GetWorldPanel():GetChildren()) do
                    if v:GetName() == "DFrame" then
                        v:Close()
                    end
                end
                characterMenuOpen = false
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

print("GModsaken: Улучшенное меню персонажей загружено! Нажмите F4 для открытия.")