--[[
    GModsaken - News and Information Menu
    Copyright (C) 2024 GModsaken Contributors
]]

local GM = _G.GM or GAMEMODE
_G.GM = GM
_G.GAMEMODE = GM

-- Переменные меню
local newsMenuOpen = false
local currentTab = 1
local tabs = {
    {name = "📰 Новости", icon = "newspaper"},
    {name = "🎮 Геймплей", icon = "sports_esports"},
    {name = "👥 Команды", icon = "groups"},
    {name = "⚙️ Настройки", icon = "settings"}
}

-- Создание шрифтов
surface.CreateFont("GModsakenTitle", {
    font = "Roboto",
    size = 32,
    weight = 1000,
    antialias = true,
    shadow = true
})

surface.CreateFont("GModsakenTab", {
    font = "Roboto",
    size = 18,
    weight = 700,
    antialias = true
})

surface.CreateFont("GModsakenTabActive", {
    font = "Roboto",
    size = 18,
    weight = 1000,
    antialias = true
})

surface.CreateFont("GModsakenSectionTitle", {
    font = "Roboto",
    size = 22,
    weight = 800,
    antialias = true
})

surface.CreateFont("GModsakenNewsTitle", {
    font = "Roboto",
    size = 20,
    weight = 700,
    antialias = true
})

surface.CreateFont("GModsakenNewsDate", {
    font = "Roboto",
    size = 14,
    weight = 400,
    antialias = true
})

surface.CreateFont("GModsakenNewsText", {
    font = "Roboto",
    size = 16,
    weight = 400,
    antialias = true
})

surface.CreateFont("GModsakenText", {
    font = "Roboto",
    size = 16,
    weight = 400,
    antialias = true
})

surface.CreateFont("GModsakenCommand", {
    font = "Roboto",
    size = 16,
    weight = 700,
    antialias = true
})

surface.CreateFont("GModsakenHint", {
    font = "Roboto",
    size = 14,
    weight = 400,
    italic = true,
    antialias = true
})

-- Данные новостей (можно заменить на загрузку с сервера)
local newsData = {
    {
        title = "Обновление 1.2.0 - Новая система погоды",
        date = "23.06.2024",
        content = {
            "• Добавлена динамическая система погоды",
            "• Новые эффекты: дождь, гроза, туман, кислотный дождь",
            "• Погода влияет на игровой процесс"
        },
        important = true
    },
    {
        title = "Обновление 1.1.0 - Новая система скрытности",
        date = "20.06.2024",
        content = {
            "• Добавлена система скрытности для убийц",
            "• Улучшен ИИ противников",
            "• Исправлены мелкие баги"
        },
        important = true
    },
    {
        title = "Сервер открыт для тестирования",
        date = "15.06.2024",
        content = {
            "Добро пожаловать на бета-тестирование GModsaken!",
            "Сообщайте об ошибках в нашем Discord"
        },
        important = false
    }
}

-- Основная функция отрисовки меню
local function DrawNewsMenu()
    if not newsMenuOpen then return end
    
    local screenW, screenH = ScrW(), ScrH()
    local menuW, menuH = math.min(screenW * 0.8, 1000), math.min(screenH * 0.8, 700)
    local menuX, menuY = (screenW - menuW) / 2, (screenH - menuH) / 2
    
    -- Затемнение фона с анимацией
    local alpha = 150
    draw.RoundedBox(0, 0, 0, screenW, screenH, Color(0, 0, 0, alpha))
    
    -- Основной фон меню
    draw.RoundedBox(12, menuX, menuY, menuW, menuH, Color(20, 30, 50, 250))
    
    -- Заголовок
    draw.SimpleText("📰 GModsaken - Информация", "GModsakenTitle", menuX + menuW/2, menuY + 20, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
    
    -- Вкладки
    local tabW = menuW / #tabs
    for i, tab in ipairs(tabs) do
        local tabX = menuX + (i-1) * tabW
        local isActive = (i == currentTab)
        
        -- Фон вкладки
        surface.SetDrawColor(isActive and Color(65, 90, 150, 250) or Color(40, 50, 70, 220))
        surface.DrawRect(tabX, menuY + 60, tabW, 40)
        
        -- Текст вкладки
        draw.SimpleText(tab.name, isActive and "GModsakenTabActive" or "GModsakenTab", tabX + tabW/2, menuY + 80, 
            isActive and Color(255, 255, 255) or Color(180, 180, 180), 
            TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        
        -- Подсветка при наведении
        local mouseX, mouseY = gui.MousePos()
        if mouseX >= tabX and mouseX <= tabX + tabW and 
           mouseY >= menuY + 60 and mouseY <= menuY + 100 then
            surface.SetDrawColor(255, 255, 255, 30)
            surface.DrawRect(tabX, menuY + 60, tabW, 40)
            
            -- Обработка клика
            if input.IsMouseDown(MOUSE_LEFT) and not isActive then
                currentTab = i
                surface.PlaySound("ui/buttonclick.wav")
            end
        end
    end
    
    -- Контент
    local contentX = menuX + 30
    local contentY = menuY + 120
    local contentW = menuW - 60
    local contentH = menuH - 150
    
    -- Отрисовка контента в зависимости от выбранной вкладки
    if currentTab == 1 then -- Новости
        local startY = contentY
        for _, news in ipairs(newsData) do
            -- Заголовок новости
            surface.SetFont("GModsakenNewsTitle")
            local titleW, titleH = surface.GetTextSize(news.title)
            
            -- Фон новости
            surface.SetDrawColor(30, 40, 60, 200)
            surface.DrawRect(contentX, startY, contentW, titleH + 60)
            
            -- Заголовок
            draw.SimpleText(news.title, "GModsakenNewsTitle", contentX + 15, startY + 10, 
                news.important and Color(255, 100, 100) or Color(100, 170, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            
            -- Дата
            draw.SimpleText(news.date, "GModsakenNewsDate", contentX + contentW - 15, startY + 12, 
                Color(150, 150, 150), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
            
            -- Содержимое
            for j, line in ipairs(news.content) do
                draw.SimpleText(line, "GModsakenNewsText", contentX + 20, startY + 35 + (j-1) * 20, 
                    Color(220, 220, 220), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            end
            
            startY = startY + titleH + 40 + (#news.content * 20)
            
            -- Разделитель
            if _ < #newsData then
                surface.SetDrawColor(100, 100, 100, 100)
                surface.DrawRect(contentX + 10, startY + 10, contentW - 20, 1)
                startY = startY + 20
            end
            
            if startY > contentY + contentH then break end
        end
    elseif currentTab == 2 then -- Геймплей
        local info = {
            {title = "🎯 Цель игры", content = {
                "• Выжившие должны продержаться до конца раунда",
                "• Убийца должен уничтожить всех выживших",
                "• Используйте окружающую среду для выживания"
            }},
            {title = "🌦️ Погодная система", content = {
                "• Динамическая смена погоды влияет на геймплей",
                "• Разные типы погоды дают различные эффекты",
                "• Следите за изменениями в окружающей среде"
            }},
            {title = "👻 Скрытность", content = {
                "• Убийцы могут скрываться от выживших",
                "• Движение и действия влияют на вашу заметность",
                "• Используйте укрытия и тени для скрытного перемещения"
            }}
        }
        
        local startY = contentY
        for _, section in ipairs(info) do
            draw.SimpleText(section.title, "GModsakenSectionTitle", contentX, startY, Color(100, 200, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            startY = startY + 30
            
            for _, line in ipairs(section.content) do
                draw.SimpleText(line, "GModsakenText", contentX + 20, startY, Color(220, 220, 220), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                startY = startY + 22
            end
            
            startY = startY + 15
        end
    elseif currentTab == 3 then -- Команды
        local commands = {
            {cmd = "F3", desc = "Открыть это меню"},
            {cmd = "TAB", desc = "Показать список игроков"},
            {cmd = "F1", desc = "Меню помощи"},
            {cmd = "C", desc = "Голосовой чат"},
            {cmd = "Q", desc = "Быстрое меню"},
            {cmd = "F4", desc = "Меню настроек"},
            {cmd = "R", desc = "Перезарядить оружие"},
            {cmd = "E", desc = "Взаимодействие с объектами"},
            {cmd = "ПКМ", desc = "Альтернативная атака/прицеливание"},
            {cmd = "SHIFT", desc = "Бег (тратит выносливость)"}
        }
        
        draw.SimpleText("🔧 Основные команды", "GModsakenSectionTitle", contentX, contentY, Color(100, 200, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        
        local startY = contentY + 40
        local col1X = contentX + 20
        local col2X = contentX + contentW/2 + 20
        local rowHeight = 30
        
        for i, cmd in ipairs(commands) do
            local col = (i % 2 == 1) and col1X or col2X
            local row = math.ceil(i / 2) - 1
            
            -- Команда
            draw.SimpleText(cmd.cmd, "GModsakenCommand", col, startY + row * rowHeight, Color(255, 200, 100), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            
            -- Описание
            draw.SimpleText(cmd.desc, "GModsakenText", col + 60, startY + row * rowHeight, Color(220, 220, 220), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        end
    elseif currentTab == 4 then -- Настройки
        draw.SimpleText("⚙️ Настройки интерфейса", "GModsakenSectionTitle", contentX, contentY, Color(100, 200, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        
        -- Здесь можно добавить элементы управления настройками
        draw.SimpleText("Громкость музыки:", "GModsakenText", contentX + 20, contentY + 40, Color(220, 220, 220), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        draw.RoundedBox(4, contentX + 150, contentY + 40, 200, 20, Color(50, 50, 70, 200))
        draw.RoundedBox(4, contentX + 150, contentY + 40, 150, 20, Color(100, 150, 255, 200))
        
        draw.SimpleText("Громкость звуков:", "GModsakenText", contentX + 20, contentY + 80, Color(220, 220, 220), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        draw.RoundedBox(4, contentX + 150, contentY + 80, 200, 20, Color(50, 50, 70, 200))
        draw.RoundedBox(4, contentX + 150, contentY + 80, 180, 20, Color(100, 150, 255, 200))
        
        draw.SimpleText("Чувствительность мыши:", "GModsakenText", contentX + 20, contentY + 120, Color(220, 220, 220), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        draw.RoundedBox(4, contentX + 150, contentY + 120, 200, 20, Color(50, 50, 70, 200))
        draw.RoundedBox(4, contentX + 150, contentY + 120, 120, 20, Color(100, 150, 255, 200))
    end
    
    -- Подсказка внизу
    draw.SimpleText("Нажмите F3 для закрытия", "GModsakenHint", menuX + menuW/2, menuY + menuH - 30, 
        Color(150, 150, 150, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

-- Функция переключения меню
local function ToggleNewsMenu()
    newsMenuOpen = not newsMenuOpen
    gui.EnableScreenClicker(newsMenuOpen)
    surface.PlaySound("buttons/button15.wav")
    print("GModsaken: Меню новостей " .. (newsMenuOpen and "открыто" or "закрыто"))
end

-- Получаем код клавиши для меню новостей из конфига
local function GetNewsMenuKey()
    return GM:GetConfig("Keys.NEWS_MENU", KEY_F3)
end

-- Проверяем, является ли клавиша заблокированной
local function IsKeyBlocked(key)
    local blockedKeys = {
        [KEY_F2] = true,
        [KEY_F4] = true
    }
    return blockedKeys[key] or false
end

-- Обработка нажатия клавиш
hook.Add("PlayerButtonDown", "GModsaken_KeyHandler", function(_, button)
    -- Открытие/закрытие меню новостей
    if button == GetNewsMenuKey() then
        ToggleNewsMenu()
        return true
    end
    
    -- Блокировка F2 и других нежелательных клавиш
    if IsKeyBlocked(button) then
        if button == KEY_F2 then
            chat.AddText(Color(255, 100, 100), "F2 заблокирована! Используйте ", 
                input.GetKeyName(GetNewsMenuKey()) or "F3", " для меню новостей.")
        end
        return true
    end
end)

-- Дополнительная блокировка через PlayerBindPress
hook.Add("PlayerBindPress", "GModsaken_BlockBinds", function(_, bind, pressed)
    -- Блокируем стандартное меню выбора команды (F2)
    if bind == "+chooseteam" or bind == "chooseteam" then
        chat.AddText(Color(255, 100, 100), "Меню выбора команды отключено. Используйте ",
            input.GetKeyName(GetNewsMenuKey()) or "F3", " для доступа к меню.")
        return true
    end
    
    -- Блокируем другие нежелательные бинды, когда меню открыто
    if newsMenuOpen then
        local blockedBinds = {
            ["+showscores"] = true,
            ["showscores"] = true,
            ["+menu"] = true,
            ["menu"] = true
        }
        if blockedBinds[bind] then
            return true
        end
    end
end)

-- Отрисовка меню
hook.Add("HUDPaint", "GModsaken_NewsMenuPaint", DrawNewsMenu)

-- Команда для открытия меню
concommand.Add("gmodsaken_news_menu", function()
    newsMenuOpen = not newsMenuOpen
    gui.EnableScreenClicker(newsMenuOpen)
    if newsMenuOpen then
        surface.PlaySound("buttons/button15.wav")
        print("GModsaken: Меню новостей открыто через команду")
    else
        surface.PlaySound("buttons/button15.wav")
        print("GModsaken: Меню новостей закрыто через команду")
    end
end)

print("GModsaken: Меню новостей загружено! Нажмите F3 для открытия.") 