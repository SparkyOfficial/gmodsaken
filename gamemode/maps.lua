--[[
    GModsaken - Maps System
    Copyright (C) 2024 GModsaken Contributors
]]

-- Список поддерживаемых карт
GM.SupportedMaps = {
    "gm_construct",
    "gm_flatgrass", 
    "gm_bigcity",
    "gm_fork",
    "gm_excess_construct_13",
    "gm_black"
}

-- Получение случайной карты
function GM:GetRandomMap()
    return self.Maps[math.random(1, #self.Maps)]
end

-- Получение следующей карты в цикле
function GM:GetNextMap()
    local currentMap = game.GetMap()
    local currentIndex = 1
    
    for i, map in pairs(self.Maps) do
        if map == currentMap then
            currentIndex = i
            break
        end
    end
    
    local nextIndex = currentIndex + 1
    if nextIndex > #self.Maps then
        nextIndex = 1
    end
    
    return self.Maps[nextIndex]
end

-- Проверка, поддерживается ли карта
function GM:IsMapSupported(mapName)
    for _, map in pairs(self.Maps) do
        if map == mapName then
            return true
        end
    end
    return false
end

-- Смена карты
function GM:ChangeMap(mapName)
    if not self:IsMapSupported(mapName) then
        print("GModsaken: Карта " .. mapName .. " не поддерживается!")
        return false
    end
    
    print("GModsaken: Смена карты на " .. mapName)
    RunConsoleCommand("changelevel", mapName)
    return true
end

-- Команда для смены карты
concommand.Add("gmodsaken_change_map", function(ply, cmd, args)
    if IsValid(ply) and not ply:IsAdmin() then
        ply:ChatPrint("Только администраторы могут менять карты!")
        return
    end
    
    if #args < 1 then
        if IsValid(ply) then
            ply:ChatPrint("Использование: gmodsaken_change_map <название_карты>")
            ply:ChatPrint("Доступные карты:")
            for _, map in pairs(GM.Maps) do
                ply:ChatPrint("- " .. map)
            end
        end
        return
    end
    
    local mapName = args[1]
    if GM:ChangeMap(mapName) then
        if IsValid(ply) then
            ply:ChatPrint("Карта будет изменена на " .. mapName)
        end
    else
        if IsValid(ply) then
            ply:ChatPrint("Ошибка смены карты!")
        end
    end
end)

-- Команда для получения случайной карты
concommand.Add("gmodsaken_random_map", function(ply, cmd, args)
    if IsValid(ply) and not ply:IsAdmin() then
        ply:ChatPrint("Только администраторы могут менять карты!")
        return
    end
    
    local randomMap = GM:GetRandomMap()
    if GM:ChangeMap(randomMap) then
        if IsValid(ply) then
            ply:ChatPrint("Карта будет изменена на случайную: " .. randomMap)
        end
    end
end)

-- Команда для списка карт
concommand.Add("gmodsaken_list_maps", function(ply, cmd, args)
    if not IsValid(ply) then return end
    
    ply:ChatPrint("=== Доступные карты ===")
    for _, map in pairs(GM.Maps) do
        local currentText = ""
        if map == game.GetMap() then
            currentText = " (текущая)"
        end
        ply:ChatPrint("- " .. map .. currentText)
    end
end) 