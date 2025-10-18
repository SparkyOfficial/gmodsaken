--[[
    GModsaken - Quest System (Client)
    Copyright (C) 2024 GModsaken Contributors
]]

-- Ensure GM table exists
if not _G.GM then
    _G.GM = {}
end
local GM = _G.GM
_G.GAMEMODE = GM

-- Локальные переменные для клиента
local QuestStats = {
    TrashCollected = 0,
    InterfacesUsed = 0,
    TimeAdded = 0
}

-- Получение обновлений статистики с сервера
net.Receive("GModsaken_UpdateQuestStats", function()
    QuestStats.TrashCollected = net.ReadInt(32)
    QuestStats.InterfacesUsed = net.ReadInt(32)
    QuestStats.TimeAdded = net.ReadInt(32)
end)

-- Отрисовка HUD квестов
local function DrawQuestHUD()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    
    -- Показываем HUD только выжившим во время игры
    if not GM.IsSurvivor or not GM.IsSurvivor(ply) then return end
    if GM.GameState ~= "PLAYING" then return end
    
    local screenW, screenH = ScrW(), ScrH()
    
    -- Позиция HUD (правый верхний угол)
    local hudX = screenW - 300
    local hudY = 100
    local hudW = 280
    local hudH = 150
    
    -- Фон
    surface.SetDrawColor(0, 0, 0, 200)
    surface.DrawRect(hudX, hudY, hudW, hudH)
    
    -- Рамка
    surface.SetDrawColor(0, 150, 255, 255)
    surface.DrawOutlinedRect(hudX, hudY, hudW, hudH, 2)
    
    -- Заголовок
    draw.SimpleText("КВЕСТЫ ВЫЖИВШИХ", "DermaDefault", hudX + hudW/2, hudY + 10, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
    
    -- Разделитель
    surface.SetDrawColor(0, 150, 255, 255)
    surface.DrawLine(hudX + 10, hudY + 30, hudX + hudW - 10, hudY + 30)
    
    -- Статистика мусора
    draw.SimpleText("🗑️ Мусор собрано: " .. QuestStats.TrashCollected .. "/10", "DermaDefault", hudX + 10, hudY + 45, Color(0, 255, 0), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    
    -- Статистика интерфейсов
    draw.SimpleText("💻 Интерфейсов: " .. QuestStats.InterfacesUsed, "DermaDefault", hudX + 10, hudY + 65, Color(255, 255, 0), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    
    -- Время добавлено
    draw.SimpleText("⏰ Время сокращено: " .. QuestStats.TimeAdded .. "с", "DermaDefault", hudX + 10, hudY + 85, Color(255, 150, 0), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    
    -- Прогресс-бар мусора
    local progress = math.min(QuestStats.TrashCollected / 10, 1)
    local barW = hudW - 20
    local barH = 8
    
    -- Фон прогресс-бара
    surface.SetDrawColor(50, 50, 50, 255)
    surface.DrawRect(hudX + 10, hudY + 105, barW, barH)
    
    -- Заполнение прогресс-бара
    surface.SetDrawColor(0, 255, 0, 255)
    surface.DrawRect(hudX + 10, hudY + 105, barW * progress, barH)
    
    -- Рамка прогресс-бара
    surface.SetDrawColor(255, 255, 255, 255)
    surface.DrawOutlinedRect(hudX + 10, hudY + 105, barW, barH, 1)
    
    -- Текст прогресса
    local progressText = math.floor(progress * 100) .. "%"
    draw.SimpleText(progressText, "DermaDefault", hudX + hudW/2, hudY + 120, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
    
    -- Подсказки
    if QuestStats.TrashCollected < 10 then
        draw.SimpleText("💡 Подсказка: Соберите мусор и отнесите к мусорному баку", "DermaDefault", hudX + hudW/2, hudY + 140, Color(200, 200, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
    else
        draw.SimpleText("🎉 Все мусорные квесты выполнены!", "DermaDefault", hudX + hudW/2, hudY + 140, Color(0, 255, 0), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
    end
end

-- Отрисовка подсказок для объектов квестов
local function DrawQuestHints()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    
    -- Показываем подсказки только выжившим во время игры
    if not GM.IsSurvivor or not GM.IsSurvivor(ply) then return end
    if GM.GameState ~= "PLAYING" then return end
    
    local playerPos = ply:GetPos()
    local maxDistance = 300 -- Максимальная дистанция для отображения подсказок
    
    -- Ищем объекты квестов поблизости
    for _, ent in pairs(ents.FindByClass("prop_physics")) do
        if ent:GetNWBool("IsQuestObject") then
            local distance = playerPos:Distance(ent:GetPos())
            
            if distance <= maxDistance then
                local questType = ent:GetNWString("QuestType")
                local screenPos = ent:GetPos() + Vector(0, 0, 50)
                
                -- Конвертируем 3D позицию в 2D экранные координаты
                local screenX, screenY = screenPos:ToScreen()
                
                if screenX and screenY and screenX > 0 and screenX < ScrW() and screenY > 0 and screenY < ScrH() then
                    -- Фон подсказки
                    local hintText = ""
                    local hintColor = Color(255, 255, 255)
                    
                    if questType == "Trash" then
                        hintText = "🗑️ Мусор\n[E] - Взять"
                        hintColor = Color(0, 255, 0)
                    elseif questType == "TrashDumpster" then
                        hintText = "🗑️ Мусорный бак\nСдайте мусор сюда"
                        hintColor = Color(255, 255, 0)
                    elseif questType == "CombineInterface" then
                        local canUse = ent:GetNWBool("CanUse", true)
                        local lastUseTime = ent:GetNWFloat("LastUseTime", 0)
                        local currentTime = CurTime()
                        
                        if canUse and (currentTime - lastUseTime) >= 90 then
                            hintText = "💻 Интерфейс Combine\n[E] - Активировать (-30с)"
                            hintColor = Color(0, 150, 255)
                        else
                            local remainingTime = math.ceil(90 - (currentTime - lastUseTime))
                            hintText = "💻 Интерфейс Combine\n⏰ Перезагрузка: " .. remainingTime .. "с"
                            hintColor = Color(255, 100, 100)
                        end
                    end
                    
                    -- Отрисовка подсказки
                    local textW, textH = surface.GetTextSize(hintText)
                    local padding = 10
                    local boxW = textW + padding * 2
                    local boxH = textH + padding * 2
                    
                    -- Фон
                    surface.SetDrawColor(0, 0, 0, 200)
                    surface.DrawRect(screenX - boxW/2, screenY - boxH/2, boxW, boxH)
                    
                    -- Рамка
                    surface.SetDrawColor(hintColor.r, hintColor.g, hintColor.b, 255)
                    surface.DrawOutlinedRect(screenX - boxW/2, screenY - boxH/2, boxW, boxH, 2)
                    
                    -- Текст
                    draw.SimpleText(hintText, "DermaDefault", screenX, screenY, hintColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                end
            end
        end
    end
end

-- Добавляем хуки для отрисовки
hook.Add("HUDPaint", "GModsaken_DrawQuestHUD", DrawQuestHUD)
hook.Add("HUDPaint", "GModsaken_DrawQuestHints", DrawQuestHints)

-- Команда для показа статистики квестов (клиентская)
concommand.Add("gmodsaken_quest_stats_client", function(ply, cmd, args)
    if not IsValid(ply) then return end
    
    ply:ChatPrint("=== Статистика квестов (клиент) ===")
    ply:ChatPrint("Мусор собрано: " .. QuestStats.TrashCollected)
    ply:ChatPrint("Интерфейсов использовано: " .. QuestStats.InterfacesUsed)
    ply:ChatPrint("Времени добавлено: " .. QuestStats.TimeAdded .. " секунд")
end) 