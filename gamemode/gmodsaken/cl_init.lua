--[[
    GModsaken - Client Initialization
    Copyright (C) 2024 GModsaken Contributors
]]

-- Инициализируем глобальные переменные, если их нет
GM = GM or {}
GAMEMODE = GM

-- Подключаем общие файлы
AddCSLuaFile("gmodsaken/sh_menu.lua")
include("gmodsaken/sh_menu.lua")

-- Подключаем клиентские файлы
AddCSLuaFile("gmodsaken/cl_menu.lua")
include("gmodsaken/cl_menu.lua")

-- Обработчик открытия меню
net.Receive("GModsakenMenu_Open", function()
    GM.Menu:Open()
end)

-- Обработчик закрытия меню
net.Receive("GModsakenMenu_Close", function()
    if GM.Menu.IsOpen() then
        GM.Menu:Close()
    end
end)

-- Уведомление о загрузке
hook.Add("Initialize", "GModsakenMenuClientInit", function()
    print("[GModsaken] Клиентское меню загружено")
    
    -- Загружаем настройки
    if file.Exists("gmodsaken/menu_settings.txt", "DATA") then
        local data = file.Read("gmodsaken/menu_settings.txt", "DATA")
        if data then
            local settings = util.JSONToTable(data)
            if settings then
                table.Merge(GM.Menu.Config, settings)
                print("[GModsaken] Настройки меню загружены")
            end
        end
    end
end)

-- Сохранение настроек при выходе
hook.Add("ShutDown", "GModsakenMenuClientSave", function()
    if GM.Menu and GM.Menu.SaveSettings then
        GM.Menu:SaveSettings()
    end
end)
