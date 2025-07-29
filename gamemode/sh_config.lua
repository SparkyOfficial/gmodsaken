--[[
    GModsaken - Configuration
    Copyright (C) 2024 GModsaken Contributors
]]

GM.Config = GM.Config or {}

-- Настройки клавиш
GM.Config.Keys = {
    NEWS_MENU = KEY_F3,  -- Клавиша для открытия меню новостей
    TEAM_MENU = KEY_F4,  -- Клавиша для выбора команды/персонажа
    VOICE_CHAT = KEY_C,  -- Клавиша голосового чата
    SPRINT = KEY_LSHIFT  -- Клавиша бега
}

-- Настройки интерфейса
GM.Config.Interface = {
    EnableAnimations = true,  -- Включить анимации интерфейса
    ShowHints = true,         -- Показывать подсказки
    Language = "russian"      -- Язык интерфейса
}

-- Настройки геймплея
GM.Config.Gameplay = {
    MaxPlayers = 24,          -- Максимальное количество игроков
    MinPlayers = 3,           -- Минимальное количество игроков для начала
    RoundTime = 600,          -- Время раунда в секундах
    LobbyTime = 30,           -- Время в лобби перед началом раунда
    RespawnTime = 10          -- Время возрождения после смерти
}

-- Функция для получения настройки
function GM:GetConfig(key, default)
    local keys = {}
    for k in string.gmatch(key, "([^.]+)") do
        table.insert(keys, k)
    end
    
    local value = self.Config
    for _, k in ipairs(keys) do
        value = value and value[k]
        if not value then return default end
    end
    
    return value ~= nil and value or default
end

-- Функция для установки настройки
function GM:SetConfig(key, value)
    local keys = {}
    for k in string.gmatch(key, "([^.]+)") do
        table.insert(keys, k)
    end
    
    local config = self.Config
    for i = 1, #keys - 1 do
        local k = keys[i]
        if config[k] == nil then
            config[k] = {}
        end
        config = config[k]
    end
    
    config[keys[#keys]] = value
end

-- Функция для загрузки конфигурации
function GM:LoadConfig()
    if file.Exists("gmodsaken/config.txt", "DATA") then
        local config = util.JSONToTable(file.Read("gmodsaken/config.txt", "DATA"))
        if config then
            table.Merge(self.Config, config)
        end
    end
end

-- Функция для сохранения конфигурации
function GM:SaveConfig()
    file.CreateDir("gmodsaken")
    file.Write("gmodsaken/config.txt", util.TableToJSON(self.Config, true))
end

-- Загружаем конфигурацию при инициализации
hook.Add("Initialize", "GModsaken_LoadConfig", function()
    if GM and GM.LoadConfig then
        GM:LoadConfig()
    end
end)

-- Сохраняем конфигурацию при выключении
hook.Add("ShutDown", "GModsaken_SaveConfig", function()
    if GM and GM.SaveConfig then
        GM:SaveConfig()
    end
end)
