--[[
    GModsaken - Spawn Menu System (Client)
    Copyright (C) 2024 GModsaken Contributors
]]

-- Ensure GM table exists
if not _G.GM then
    _G.GM = GAMEMODE or {}
    print("[GModsaken] Created GM table in cl_spawnmenu.lua")
end
local GM = _G.GM
_G.GAMEMODE = GM

print("[GModsaken] cl_spawnmenu.lua loaded")

-- Переменные меню
local spawnMenu = nil
local spawnMenuOpen = false
local lastPropSpawn = 0
local propCooldown = 60 -- 60 секунд
local qKeyPressed = false -- Отслеживание нажатия Q

-- Создание главного Q-меню
function CreateSpawnMenu()
    if spawnMenu then spawnMenu:Remove() end
    
    local ply = LocalPlayer()
    if not IsValid(ply) then 
        print("[GModsaken] CreateSpawnMenu: LocalPlayer is not valid")
        return 
    end
    
    -- ОТЛАДКА: Подробная информация
    print("=== GModsaken Q-Menu Debug ===")
    print("Player: " .. ply:Nick())
    print("Team: " .. ply:Team())
    print("Alive: " .. tostring(ply:Alive()))
    print("GM exists: " .. tostring(GM ~= nil))
    print("GM.IsSurvivor exists: " .. tostring(GM and GM.IsSurvivor ~= nil))
    print("GM.TEAM_SURVIVOR: " .. tostring(GM and GM.TEAM_SURVIVOR))
    print("GM.TEAM_KILLER: " .. tostring(GM and GM.TEAM_KILLER))
    print("GM.TEAM_SPECTATOR: " .. tostring(GM and GM.TEAM_SPECTATOR))
    print("GameState: " .. tostring(GM and GM.GameState))
    print("SpawnMenuCategories: " .. tostring(GM and GM.SpawnMenuCategories ~= nil))
    if GM and GM.SpawnMenuCategories then
        print("Categories count: " .. table.Count(GM.SpawnMenuCategories))
    end
    print("================================")
    
    -- УПРОЩЕННАЯ ПРОВЕРКА: Проверяем только команду игрока
    local isSurvivor = false
    
    -- Проверка 1: Через функцию IsSurvivor
    if GM and GM.IsSurvivor and GM:IsSurvivor(ply) then
        isSurvivor = true
        print("[GModsaken] Player is survivor (via IsSurvivor function)")
    end
    
    -- Проверка 2: Прямое сравнение команды
    if not isSurvivor and GM and GM.TEAM_SURVIVOR and ply:Team() == GM.TEAM_SURVIVOR then
        isSurvivor = true
        print("[GModsaken] Player is survivor (via team comparison)")
    end
    
    -- Проверка 3: Если TEAM_SURVIVOR не определен, используем 2
    if not isSurvivor and ply:Team() == 2 then
        isSurvivor = true
        print("[GModsaken] Player is survivor (team == 2)")
    end
    
    if not isSurvivor then
        -- Убираем спам в чат, просто не открываем меню
        print("[GModsaken] CreateSpawnMenu: Player is not survivor")
        return 
    end
    
    -- УПРОЩЕННАЯ ПРОВЕРКА СОСТОЯНИЯ: Если игрок жив и выживший, то игра идет
    if not ply:Alive() then
        -- Убираем спам в чат, просто не открываем меню
        print("[GModsaken] CreateSpawnMenu: Player is not alive")
        return
    end
    
    print("[GModsaken] CreateSpawnMenu: All checks passed, creating menu")
    
    -- Проверяем наличие категорий пропов
    if not GM.SpawnMenuCategories then
        ply:ChatPrint("ОШИБКА: Категории пропов не найдены!")
        print("[GModsaken] ERROR: SpawnMenuCategories is nil!")
        return
    end
    
    local categoriesCount = table.Count(GM.SpawnMenuCategories)
    if categoriesCount == 0 then
        ply:ChatPrint("ОШИБКА: Нет доступных категорий пропов!")
        print("[GModsaken] ERROR: SpawnMenuCategories is empty!")
        return
    end
    
    print("[GModsaken] Found " .. categoriesCount .. " categories")
    for name, props in pairs(GM.SpawnMenuCategories) do
        print("  - " .. name .. ": " .. #props .. " props")
    end
    
    spawnMenu = vgui.Create("DFrame")
    spawnMenu:SetSize(800, 600)
    spawnMenu:Center()
    spawnMenu:SetTitle("Q-Меню - Спавн Пропов")
    spawnMenu:SetDraggable(true)
    spawnMenu:ShowCloseButton(true)
    
    -- Безопасное использование makePopup
    if makePopup then
        makePopup(spawnMenu)
    end
    
    -- Закрытие меню
    function spawnMenu:OnClose()
        spawnMenuOpen = false
        qKeyPressed = false -- Сбрасываем состояние клавиши
        gui.EnableScreenClicker(false)
    end
    
    -- Создаем панель с вкладками
    local tabPanel = vgui.Create("DPropertySheet", spawnMenu)
    tabPanel:Dock(FILL)
    tabPanel:DockMargin(10, 10, 10, 10)
    
    -- Добавляем вкладки для каждой категории
    for categoryName, props in pairs(GM.SpawnMenuCategories or {}) do
        local categoryPanel = vgui.Create("DPanel")
        categoryPanel:Dock(FILL)
        
        -- Создаем скролл панель для пропов
        local propsScroll = vgui.Create("DScrollPanel", categoryPanel)
        propsScroll:Dock(FILL)
        propsScroll:DockMargin(5, 5, 5, 5)
        
        -- Создаем сетку для пропов
        local propsGrid = vgui.Create("DIconLayout", propsScroll)
        propsGrid:Dock(FILL)
        propsGrid:SetSpaceX(5)
        propsGrid:SetSpaceY(5)
        
        -- Добавляем пропы в сетку
        for _, model in ipairs(props) do
            local propButton = vgui.Create("DButton", propsGrid)
            propButton:SetSize(150, 120)
            propButton:SetText("")
            
            -- Получаем имя пропа
            local propName = model:match("[^/]+$") or model
            
            -- Создаем панель для иконки
            local iconPanel = vgui.Create("DPanel", propButton)
            iconPanel:Dock(FILL)
            iconPanel:DockMargin(5, 5, 5, 25)
            
            -- Функция отрисовки иконки
            function iconPanel:Paint(w, h)
                -- Рисуем фон
                draw.RoundedBox(4, 0, 0, w, h, Color(50, 50, 50, 200))
                
                -- Рисуем рамку
                draw.RoundedBox(4, 0, 0, w, h, Color(100, 100, 100, 100), false)
                
                -- Рисуем текст с именем пропа
                draw.SimpleText(propName, "DermaDefault", w/2, h/2, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
            
            -- Обработка клика
            function propButton:DoClick()
                local timeLeft = propCooldown - (CurTime() - lastPropSpawn)
                if timeLeft > 0 then
                    ply:ChatPrint("Подождите " .. math.ceil(timeLeft) .. " секунд перед следующим спавном!")
                    return
                end
                
                -- Отправляем запрос на сервер
                net.Start("GModsaken_SpawnProp")
                net.WriteString(model)
                net.WriteString(propName)
                net.SendToServer()
                
                lastPropSpawn = CurTime()
                spawnMenu:Close()
                ply:ChatPrint("Проп создан: " .. propName)
            end
            
            -- Подсказка при наведении
            function propButton:OnCursorEntered()
                local timeLeft = propCooldown - (CurTime() - lastPropSpawn)
                if timeLeft > 0 then
                    self:SetTooltip("Кулдаун: " .. math.ceil(timeLeft) .. " сек")
                else
                    self:SetTooltip("Нажмите для спавна: " .. propName)
                end
            end
        end
        
        -- Добавляем вкладку
        tabPanel:AddSheet(categoryName, categoryPanel, "icon16/box.png")
    end
    
    -- Информационная панель внизу
    local infoPanel = vgui.Create("DPanel", spawnMenu)
    infoPanel:Dock(BOTTOM)
    infoPanel:SetTall(80)
    infoPanel:DockMargin(10, 5, 10, 10)
    
    function infoPanel:Paint(w, h)
        draw.RoundedBox(4, 0, 0, w, h, Color(30, 30, 30, 200))
    end
    
    -- Информационный текст
    local infoLabel = vgui.Create("DLabel", infoPanel)
    infoLabel:Dock(FILL)
    infoLabel:DockMargin(10, 10, 10, 10)
    infoLabel:SetText("Информация:\n• Кулдаун: 60 секунд между спавнами\n• Пропы нельзя заморозить\n• Убийца может дезинтегрировать пропы топором\n• Пропы автоматически удаляются в конце раунда")
    infoLabel:SetWrap(true)
    infoLabel:SetAutoStretchVertical(true)
    infoLabel:SetTextColor(Color(200, 200, 200))
    
    spawnMenuOpen = true
    gui.EnableScreenClicker(true)
end

-- Обработка нажатия Q
hook.Add("Think", "GModsaken_SpawnMenuKey", function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    
    -- Проверяем нажатие Q только один раз (не спамим)
    if input.IsKeyDown(KEY_Q) then
        if not qKeyPressed and not spawnMenuOpen then
            qKeyPressed = true
            
            -- Проверяем, что игрок выживший, без спама в чат
            local isSurvivor = false
            
            -- Проверка 1: Через функцию IsSurvivor
            if GM and GM.IsSurvivor and GM:IsSurvivor(ply) then
                isSurvivor = true
            end
            
            -- Проверка 2: Прямое сравнение команды
            if not isSurvivor and GM and GM.TEAM_SURVIVOR and ply:Team() == GM.TEAM_SURVIVOR then
                isSurvivor = true
            end
            
            -- Проверка 3: Если TEAM_SURVIVOR не определен, используем 2
            if not isSurvivor and ply:Team() == 2 then
                isSurvivor = true
            end
            
            -- Если игрок не выживший, не открываем меню и не спамим в чат
            if not isSurvivor then
                return
            end
            
            -- Если игрок не жив, не открываем меню и не спамим в чат
            if not ply:Alive() then
                return
            end
            
            -- Все проверки пройдены, открываем меню
            CreateSpawnMenu()
        end
    else
        -- Сбрасываем состояние клавиши когда она отпущена
        qKeyPressed = false
    end
end)

-- Обработка ответа от сервера
net.Receive("GModsaken_PropSpawned", function()
    local success = net.ReadBool()
    local message = net.ReadString()
    
    if success then
        LocalPlayer():ChatPrint("✅ " .. message)
    else
        LocalPlayer():ChatPrint("❌ " .. message)
    end
end)

-- Обработка дезинтеграции пропа
net.Receive("GModsaken_PropDisintegrated", function()
    local prop = net.ReadEntity()
    
    if IsValid(prop) then
        -- Создаем эффект дезинтеграции
        local effectdata = EffectData()
        effectdata:SetOrigin(prop:GetPos())
        effectdata:SetScale(2)
        util.Effect("cball_explode", effectdata)
        
        -- Дополнительные эффекты
        local emitter = ParticleEmitter(prop:GetPos())
        if emitter then
            for i = 1, 20 do
                local particle = emitter:Add("sprites/light_glow02_add", prop:GetPos() + VectorRand() * 50)
                if particle then
                    particle:SetVelocity(VectorRand() * 200)
                    particle:SetDieTime(2)
                    particle:SetStartAlpha(255)
                    particle:SetEndAlpha(0)
                    particle:SetStartSize(10)
                    particle:SetEndSize(0)
                    particle:SetColor(255, 100, 100)
                end
            end
            emitter:Finish()
        end
        
        -- Звук дезинтеграции
        surface.PlaySound("physics/metal/metal_box_break1.wav")
    end
end)

-- Функция для получения оставшегося времени кулдауна
function GetPropCooldownTime()
    local timeLeft = propCooldown - (CurTime() - lastPropSpawn)
    return math.max(0, timeLeft)
end

-- Хук для отображения кулдауна на экране
hook.Add("HUDPaint", "GModsaken_PropCooldownHUD", function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    
    -- Проверяем, что игрок выживший и игра идет
    if not GM:IsSurvivor(ply) or GM.GameState ~= "PLAYING" then return end
    
    local timeLeft = GetPropCooldownTime()
    if timeLeft > 0 then
        local text = "Q-меню: " .. math.ceil(timeLeft) .. "с"
        local x = ScrW() - 200
        local y = ScrH() - 100
        
        -- Рисуем фон
        draw.RoundedBox(4, x - 5, y - 5, 200, 30, Color(0, 0, 0, 150))
        
        -- Рисуем текст
        draw.SimpleText(text, "DermaDefault", x + 95, y + 10, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    else
        local text = "Q-меню готово!"
        local x = ScrW() - 200
        local y = ScrH() - 100
        
        -- Рисуем фон
        draw.RoundedBox(4, x - 5, y - 5, 200, 30, Color(0, 100, 0, 150))
        
        -- Рисуем текст
        draw.SimpleText(text, "DermaDefault", x + 95, y + 10, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
end)

-- Команда для открытия Q-меню
concommand.Add("gmodsaken_spawn_menu", function(ply, cmd, args)
    if not IsValid(ply) then return end
    CreateSpawnMenu()
end)

-- Команда для принудительного открытия Q-меню (для тестирования)
concommand.Add("gmodsaken_force_spawn_menu", function(ply, cmd, args)
    if not IsValid(ply) then return end
    
    print("[GModsaken] Force opening spawn menu for testing")
    
    -- Создаем меню без проверок
    if spawnMenu then spawnMenu:Remove() end
    
    spawnMenu = vgui.Create("DFrame")
    spawnMenu:SetSize(800, 600)
    spawnMenu:Center()
    spawnMenu:SetTitle("Q-Меню - Спавн Пропов (ТЕСТ)")
    spawnMenu:SetDraggable(true)
    spawnMenu:ShowCloseButton(true)
    
    -- Безопасное использование makePopup
    if makePopup then
        makePopup(spawnMenu)
    end
    
    -- Закрытие меню
    function spawnMenu:OnClose()
        spawnMenuOpen = false
        qKeyPressed = false -- Сбрасываем состояние клавиши
        gui.EnableScreenClicker(false)
    end
    
    -- Создаем панель с вкладками
    local tabPanel = vgui.Create("DPropertySheet", spawnMenu)
    tabPanel:Dock(FILL)
    tabPanel:DockMargin(10, 10, 10, 10)
    
    -- Добавляем вкладки для каждой категории
    for categoryName, props in pairs(GM.SpawnMenuCategories or {}) do
        local categoryPanel = vgui.Create("DPanel")
        categoryPanel:Dock(FILL)
        
        -- Создаем скролл панель для пропов
        local propsScroll = vgui.Create("DScrollPanel", categoryPanel)
        propsScroll:Dock(FILL)
        propsScroll:DockMargin(5, 5, 5, 5)
        
        -- Создаем сетку для пропов
        local propsGrid = vgui.Create("DIconLayout", propsScroll)
        propsGrid:Dock(FILL)
        propsGrid:SetSpaceX(5)
        propsGrid:SetSpaceY(5)
        
        -- Добавляем пропы в сетку
        for _, model in ipairs(props) do
            local propButton = vgui.Create("DButton", propsGrid)
            propButton:SetSize(150, 120)
            propButton:SetText("")
            
            -- Получаем имя пропа
            local propName = model:match("[^/]+$") or model
            
            -- Создаем панель для иконки
            local iconPanel = vgui.Create("DPanel", propButton)
            iconPanel:Dock(FILL)
            iconPanel:DockMargin(5, 5, 5, 25)
            
            -- Функция отрисовки иконки
            function iconPanel:Paint(w, h)
                -- Рисуем фон
                draw.RoundedBox(4, 0, 0, w, h, Color(50, 50, 50, 200))
                
                -- Рисуем рамку
                draw.RoundedBox(4, 0, 0, w, h, Color(100, 100, 100, 100), false)
                
                -- Рисуем текст с именем пропа
                draw.SimpleText(propName, "DermaDefault", w/2, h/2, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
            
            -- Обработка клика
            function propButton:DoClick()
                local timeLeft = propCooldown - (CurTime() - lastPropSpawn)
                if timeLeft > 0 then
                    ply:ChatPrint("Подождите " .. math.ceil(timeLeft) .. " секунд перед следующим спавном!")
                    return
                end
                
                -- Отправляем запрос на сервер
                net.Start("GModsaken_SpawnProp")
                net.WriteString(model)
                net.WriteString(propName)
                net.SendToServer()
                
                lastPropSpawn = CurTime()
                spawnMenu:Close()
                ply:ChatPrint("Проп создан: " .. propName)
            end
            
            -- Подсказка при наведении
            function propButton:OnCursorEntered()
                local timeLeft = propCooldown - (CurTime() - lastPropSpawn)
                if timeLeft > 0 then
                    self:SetTooltip("Кулдаун: " .. math.ceil(timeLeft) .. " сек")
                else
                    self:SetTooltip("Нажмите для спавна: " .. propName)
                end
            end
        end
        
        -- Добавляем вкладку
        tabPanel:AddSheet(categoryName, categoryPanel, "icon16/box.png")
    end
    
    -- Информационная панель внизу
    local infoPanel = vgui.Create("DPanel", spawnMenu)
    infoPanel:Dock(BOTTOM)
    infoPanel:SetTall(80)
    infoPanel:DockMargin(10, 5, 10, 10)
    
    function infoPanel:Paint(w, h)
        draw.RoundedBox(4, 0, 0, w, h, Color(30, 30, 30, 200))
    end
    
    -- Информационный текст
    local infoLabel = vgui.Create("DLabel", infoPanel)
    infoLabel:Dock(FILL)
    infoLabel:DockMargin(10, 10, 10, 10)
    infoLabel:SetText("ТЕСТОВЫЙ РЕЖИМ:\n• Кулдаун: 60 секунд между спавнами\n• Пропы нельзя заморозить\n• Убийца может дезинтегрировать пропы топором\n• Пропы автоматически удаляются в конце раунда")
    infoLabel:SetWrap(true)
    infoLabel:SetAutoStretchVertical(true)
    infoLabel:SetTextColor(Color(255, 200, 200))
    
    spawnMenuOpen = true
    gui.EnableScreenClicker(true)
end)

-- Отладочная команда для Q-меню
concommand.Add("gmodsaken_debug_spawn_menu", function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    
    print("=== GModsaken Spawn Menu Debug ===")
    print("Player: " .. ply:Nick())
    print("Team: " .. ply:Team())
    print("Alive: " .. tostring(ply:Alive()))
    print("GM exists: " .. tostring(GM ~= nil))
    print("GM.IsSurvivor exists: " .. tostring(GM and GM.IsSurvivor ~= nil))
    print("IsSurvivor result: " .. tostring(GM and GM.IsSurvivor and GM:IsSurvivor(ply)))
    print("GameState: " .. tostring(GM and GM.GameState))
    print("SpawnMenuCategories: " .. tostring(GM and GM.SpawnMenuCategories ~= nil))
    if GM and GM.SpawnMenuCategories then
        print("Categories count: " .. table.Count(GM.SpawnMenuCategories))
        for name, props in pairs(GM.SpawnMenuCategories) do
            print("  - " .. name .. ": " .. #props .. " props")
        end
    end
    print("Menu open: " .. tostring(spawnMenuOpen))
    print("Menu valid: " .. tostring(IsValid(spawnMenu)))
    print("================================")
end)

-- Простая тестовая команда для Q-меню
concommand.Add("gmodsaken_test_qmenu", function(ply, cmd, args)
    if not IsValid(ply) then return end
    
    print("=== GModsaken Q-Menu Test ===")
    print("Player: " .. ply:Nick())
    print("Team: " .. ply:Team())
    print("Alive: " .. tostring(ply:Alive()))
    print("GM exists: " .. tostring(GM ~= nil))
    print("GM.SpawnMenuCategories exists: " .. tostring(GM and GM.SpawnMenuCategories ~= nil))
    
    if GM and GM.SpawnMenuCategories then
        print("Categories:")
        for name, props in pairs(GM.SpawnMenuCategories) do
            print("  - " .. name .. ": " .. #props .. " props")
        end
    else
        print("ERROR: SpawnMenuCategories not found!")
    end
    
    -- Попробуем создать простое меню
    if spawnMenu then spawnMenu:Remove() end
    
    spawnMenu = vgui.Create("DFrame")
    spawnMenu:SetSize(400, 300)
    spawnMenu:Center()
    spawnMenu:SetTitle("Тест Q-меню")
    spawnMenu:SetDraggable(true)
    spawnMenu:ShowCloseButton(true)
    
    -- Безопасное использование makePopup
    if makePopup then
        makePopup(spawnMenu)
    end
    
    local testLabel = vgui.Create("DLabel", spawnMenu)
    testLabel:Dock(FILL)
    testLabel:SetText("Тестовое меню работает!\nКоманда: " .. ply:Team() .. "\nЖив: " .. tostring(ply:Alive()))
    testLabel:SetWrap(true)
    testLabel:SetTextColor(Color(255, 255, 255))
    
    spawnMenuOpen = true
    gui.EnableScreenClicker(true)
    
    print("Test menu created!")
end)

-- Команда для проверки категорий пропов
concommand.Add("gmodsaken_check_props", function(ply, cmd, args)
    if not IsValid(ply) then return end
    
    print("=== GModsaken Props Check ===")
    print("GM exists: " .. tostring(GM ~= nil))
    print("GM.SpawnMenuCategories exists: " .. tostring(GM and GM.SpawnMenuCategories ~= nil))
    
    if GM and GM.SpawnMenuCategories then
        local count = table.Count(GM.SpawnMenuCategories)
        print("Categories count: " .. count)
        
        if count > 0 then
            print("Categories:")
            for name, props in pairs(GM.SpawnMenuCategories) do
                print("  - " .. name .. ": " .. #props .. " props")
                if #props > 0 then
                    print("    First prop: " .. props[1])
                end
            end
        else
            print("ERROR: Categories table is empty!")
        end
    else
        print("ERROR: SpawnMenuCategories not found!")
        
        -- Попробуем найти в глобальной области
        print("Searching in global scope...")
        for k, v in pairs(_G) do
            if type(v) == "table" and v.SpawnMenuCategories then
                print("Found SpawnMenuCategories in: " .. k)
                local count = table.Count(v.SpawnMenuCategories)
                print("Categories count: " .. count)
                break
            end
        end
    end
    print("=============================")
end) 