--[[
    GModsaken - Menu System (Shared)
    Copyright (C) 2024 GModsaken Contributors
]]

GM.Menu = GM.Menu or {}
GM.Menu.Config = {
    Key = KEY_F3,  -- Клавиша для открытия меню
    Command = "gmodsaken_menu",  -- Консольная команда
    
    -- Настройки интерфейса
    Width = 800,
    Height = 600,
    Padding = 10,
    
    -- Цвета
    Colors = {
        Background = Color(20, 20, 25, 240),
        Header = Color(40, 40, 50, 255),
        Tab = Color(50, 50, 60, 200),
        TabHover = Color(70, 70, 90, 220),
        TabActive = Color(90, 90, 120, 240),
        Text = Color(240, 240, 245, 255),
        TextMuted = Color(180, 180, 190, 200),
        Accent = Color(100, 140, 220, 255),
        Border = Color(60, 60, 70, 200)
    },
    
    -- Настройки шрифтов
    Fonts = {
        Title = "GModsakenTitle",
        Tab = "GModsakenTab",
        TabActive = "GModsakenTabActive",
        Section = "GModsakenSectionTitle",
        Button = "GModsakenText",
        Text = "GModsakenText",
        Small = "GModsakenSmall"
    },
    
    -- Настройки анимаций
    AnimSpeed = 0.2
}

-- Создаем шрифты
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

surface.CreateFont("GModsakenText", {
    font = "Roboto",
    size = 16,
    weight = 400,
    antialias = true
})

surface.CreateFont("GModsakenSmall", {
    font = "Roboto",
    size = 14,
    weight = 400,
    antialias = true
})

-- Табы меню
GM.Menu.Tabs = {
    {
        id = "news",
        name = "📰 Новости",
        icon = "newspaper",
        order = 1
    },
    {
        id = "gameplay",
        name = "🎮 Геймплей",
        icon = "sports_esports",
        order = 2
    },
    {
        id = "commands",
        name = "⌨️ Команды",
        icon = "keyboard",
        order = 3
    },
    {
        id = "settings",
        name = "⚙️ Настройки",
        icon = "settings",
        order = 4
    }
}

-- Данные новостей
GM.Menu.News = {
    {
        title = "Добро пожаловать в GModsaken!",
        date = "23.06.2025",
        content = {
            "Добро пожаловать в официальное меню GModsaken!",
            "Здесь вы найдете всю необходимую информацию о геймплее, командах и настройках.",
            "Следите за обновлениями в этом разделе!"
        },
        important = true
    },
    {
        title = "Обновление 1.0.0",
        date = "20.06.2025",
        content = {
            "- Добавлена новая система меню",
            "- Улучшена производительность",
            "- Исправлены мелкие ошибки"
        }
    }
}

-- Данные геймплея
GM.Menu.Gameplay = {
    {
        title = "Основная цель",
        content = {
            "Выжить любой ценой в этом жестоком мире.",
            "Собирайте ресурсы, находите укрытия и будьте осторожны."
        }
    },
    {
        title = "Погодная система",
        content = {
            "В игре присутствует динамическая погода, которая влияет на геймплей.",
            "Разные типы погоды могут давать различные эффекты."
        }
    },
    {
        title = "Система скрытности",
        content = {
            "Противники могут слышать ваши шаги и другие звуки.",
            "Используйте приседание для передвижения тише.",
            "Оставайтесь в тени, чтобы вас было сложнее заметить."
        }
    }
}

-- Список команд
GM.Menu.Commands = {
    {
        command = "F",
        description = "Взаимодействие с объектами"
    },
    {
        command = "R",
        description = "Перезарядка оружия"
    },
    {
        command = "ЛКМ",
        description = "Атака/Использование предмета"
    },
    {
        command = "ПКМ",
        description = "Прицеливание"
    },
    {
        command = "Shift",
        description = "Бег"
    },
    {
        command = "Ctrl",
        description = "Присесть"
    },
    {
        command = "Пробел",
        description = "Прыжок"
    },
    {
        command = "E",
        description = "Использовать предмет"
    },
    {
        command = "Tab",
        description = "Инвентарь"
    },
    {
        command = "F3",
        description = "Меню GModsaken"
    }
}

-- Настройки
GM.Menu.Settings = {
    {
        name = "Громкость звука",
        type = "slider",
        min = 0,
        max = 100,
        value = 100,
        convar = "volume",
        decimals = 0
    },
    {
        name = "Чувствительность мыши",
        type = "slider",
        min = 0.1,
        max = 10,
        value = 1,
        convar = "sensitivity",
        decimals = 1
    },
    {
        name = "Язык интерфейса",
        type = "combo",
        options = {"Русский", "English"},
        value = 1,
        convar = "gmod_language"
    },
    {
        name = "Показывать подсказки",
        type = "checkbox",
        value = true,
        convar = "cl_showhints"
    }
}

-- Функции для работы с меню
function GM.Menu:GetCurrentTab()
    return self.CurrentTab or 1
end

function GM.Menu:SetCurrentTab(tab)
    self.CurrentTab = tab
    if CLIENT then
        surface.PlaySound("ui/buttonclick.wav")
    end
end

function GM.Menu:IsOpen()
    if CLIENT then
        return self.IsMenuOpen or false
    end
    return false
end

-- Функция для открытия/закрытия меню
function GM.Menu:Toggle()
    if CLIENT then
        self.IsMenuOpen = not self.IsMenuOpen
        gui.EnableScreenClicker(self.IsMenuOpen)
        surface.PlaySound("buttons/button15.wav")
    end
end

-- Регистрация консольной команды
concommand.Add(GM.Menu.Config.Command, function()
    if CLIENT then
        GM.Menu:Toggle()
    end
end)
