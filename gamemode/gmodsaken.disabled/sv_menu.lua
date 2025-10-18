--[[
    GModsaken - Menu System (Server)
    Copyright (C) 2024 GModsaken Contributors
]]

-- Регистрируем сетевые сообщения
util.AddNetworkString("GModsakenMenu_Open")
util.AddNetworkString("GModsakenMenu_Close")

-- Функция для открытия меню у игрока
function GM.Menu:OpenForPlayer(ply)
    if not IsValid(ply) then return end
    
    net.Start("GModsakenMenu_Open")
    net.Send(ply)
    
    -- Записываем, что меню открыто
    ply.GModsakenMenuOpen = true
end

-- Функция для закрытия меню у игрока
function GM.Menu:CloseForPlayer(ply)
    if not IsValid(ply) then return end
    
    net.Start("GModsakenMenu_Close")
    net.Send(ply)
    
    -- Записываем, что меню закрыто
    ply.GModsakenMenuOpen = false
end

-- Обработка сетевого сообщения о закрытии меню
net.Receive("GModsakenMenu_Close", function(len, ply)
    ply.GModsakenMenuOpen = false
end)

-- Проверка, открыто ли у игрока меню
function GM.Menu:IsPlayerMenuOpen(ply)
    return IsValid(ply) and ply.GModsakenMenuOpen == true
end

-- Консольная команда для открытия/закрытия меню
concommand.Add("gmodsaken_menu", function(ply)
    if not IsValid(ply) then return end
    
    if GM.Menu:IsPlayerMenuOpen(ply) then
        GM.Menu:CloseForPlayer(ply)
    else
        GM.Menu:OpenForPlayer(ply)
    end
end)

-- Блокируем F2 (меню выбора команды)
hook.Add("PlayerBindPress", "GModsakenBlockTeamMenu", function(ply, bind, pressed)
    if string.find(bind:lower(), "+showscores") or string.find(bind:lower(), "showscores") then
        return true
    end
end)

-- Уведомление при подключении игрока
hook.Add("PlayerInitialSpawn", "GModsakenMenuWelcome", function(ply)
    timer.Simple(5, function()
        if IsValid(ply) then
            ply:ChatPrint("Нажмите F3, чтобы открыть меню GModsaken")
        end
    end)
end)

-- Инициализация меню при загрузке гейммода
hook.Add("Initialize", "GModsakenMenuInit", function()
    print("[GModsaken] Меню инициализировано")
    
    -- Создаем папку для сохранения настроек, если её нет
    if not file.Exists("gmodsaken", "DATA") then
        file.CreateDir("gmodsaken")
    end
    
    -- Загружаем настройки
    GM.Menu:LoadSettings()
end)

-- Сохранение настроек при выключении сервера
hook.Add("ShutDown", "GModsakenMenuSaveSettings", function()
    GM.Menu:SaveSettings()
end)

-- Функция загрузки настроек
function GM.Menu:LoadSettings()
    if file.Exists("gmodsaken/menu_settings.txt", "DATA") then
        local data = file.Read("gmodsaken/menu_settings.txt", "DATA")
        if data then
            local settings = util.JSONToTable(data)
            if settings then
                table.Merge(self.Config, settings)
                print("[GModsaken] Настройки меню загружены")
                return true
            end
        end
    end
    return false
end

-- Функция сохранения настроек
function GM.Menu:SaveSettings()
    local data = util.TableToJSON(self.Config, true)
    if data then
        file.Write("gmodsaken/menu_settings.txt", data)
        print("[GModsaken] Настройки меню сохранены")
        return true
    end
    return false
end
