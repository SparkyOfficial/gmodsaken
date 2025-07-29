--[[
    GModsaken - Information Menu System (Client)
    Copyright (C) 2024 GModsaken Contributors
]]

-- Ensure GM table exists
if not _G.GM then
    _G.GM = GAMEMODE or {}
    print("[GModsaken] Created GM table in cl_info_menu.lua")
end
local GM = _G.GM
_G.GAMEMODE = GM

print("[GModsaken] cl_info_menu.lua loaded")

-- Переменные меню
local infoMenu = nil
local infoMenuOpen = false

-- Новости и обновления
local GameNews = {
    {
        date = "2024-12-22",
        title = "🎉 Система эффектов дезинтеграции",
        content = "Добавлены красивые эффекты дезинтеграции пропов! Теперь когда убийца атакует пропы топором, они красиво исчезают с частицами и звуками.",
        type = "feature"
    },
    {
        date = "2024-12-22",
        title = "🎵 Система музыки",
        content = "Реализована полноценная система музыки с 4 категориями: Ambient, Action, Horror, Menu. Автоматическое переключение в зависимости от ситуации!",
        type = "feature"
    },
    {
        date = "2024-12-22",
        title = "🔧 Исправления Q-меню",
        content = "Исправлена проблема с Q-меню во время игры. Теперь меню работает корректно и добавлена грави пушка для всех игроков.",
        type = "fix"
    },
    {
        date = "2024-12-22",
        title = "💥 Система пропов",
        content = "Добавлена система спавна пропов через Q-меню с кулдауном 60 секунд. Пропы можно дезинтегрировать топором убийцы.",
        type = "feature"
    },
    {
        date = "2024-12-22",
        title = "🎮 Система персонажей",
        content = "7 уникальных персонажей с разными способностями: Повстанец, Инженер, Медик, Охраник, Мэр, Ученый, Охотник.",
        type = "feature"
    }
}

-- Советы по игре
local GameTips = {
    "💡 Используйте Q-меню для создания баррикад и укрытий",
    "💡 Грави пушка поможет убрать мусор и создать препятствия",
    "💡 Работайте в команде - каждый персонаж имеет уникальные способности",
    "💡 Медик может лечить себя и тиммейтов аптечкой",
    "💡 Инженер может строить турели и раздатчики",
    "💡 Мэр может активировать ауру брони для команды",
    "💡 Охраник может ослеплять убийцу дубинкой",
    "💡 Ученый может замедлять убийцу пистолетом",
    "💡 Охотник может наносить дополнительный урон",
    "💡 Убийца может дезинтегрировать пропы топором"
}

-- Создание информационного меню
function CreateInfoMenu()
    if infoMenu then infoMenu:Remove() end
    
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    
    infoMenu = vgui.Create("DFrame")
    infoMenu:SetSize(1000, 700)
    infoMenu:Center()
    infoMenu:SetTitle("📰 GModsaken - Информация и Новости")
    infoMenu:SetDraggable(true)
    infoMenu:ShowCloseButton(true)
    makePopup(infoMenu)
    
    -- Закрытие меню
    function infoMenu:OnClose()
        infoMenuOpen = false
        gui.EnableScreenClicker(false)
    end
    
    -- Создаем панель с вкладками
    local tabPanel = vgui.Create("DPropertySheet", infoMenu)
    tabPanel:Dock(FILL)
    tabPanel:DockMargin(10, 10, 10, 10)
    
    -- Вкладка "Новости"
    local newsPanel = vgui.Create("DPanel")
    newsPanel:Dock(FILL)
    
    local newsScroll = vgui.Create("DScrollPanel", newsPanel)
    newsScroll:Dock(FILL)
    newsScroll:DockMargin(10, 10, 10, 10)
    
    -- Заголовок новостей
    local newsHeader = vgui.Create("DLabel", newsScroll)
    newsHeader:Dock(TOP)
    newsHeader:SetTall(40)
    newsHeader:SetText("📰 Последние обновления")
    newsHeader:SetFont("DermaLarge")
    newsHeader:SetTextColor(Color(255, 255, 255))
    newsHeader:DockMargin(0, 0, 0, 20)
    
    -- Добавляем новости
    for i, news in ipairs(GameNews) do
        local newsCard = vgui.Create("DPanel", newsScroll)
        newsCard:Dock(TOP)
        newsCard:SetTall(120)
        newsCard:DockMargin(0, 0, 0, 15)
        
        function newsCard:Paint(w, h)
            -- Фон карточки
            local bgColor = Color(40, 40, 40, 200)
            if news.type == "feature" then
                bgColor = Color(40, 60, 40, 200)
            elseif news.type == "fix" then
                bgColor = Color(60, 40, 40, 200)
            end
            
            draw.RoundedBox(8, 0, 0, w, h, bgColor)
            draw.RoundedBox(8, 0, 0, w, h, Color(80, 80, 80, 100), false)
        end
        
        -- Заголовок новости
        local titleLabel = vgui.Create("DLabel", newsCard)
        titleLabel:Dock(TOP)
        titleLabel:SetTall(25)
        titleLabel:DockMargin(15, 10, 15, 5)
        titleLabel:SetText(news.title)
        titleLabel:SetFont("DermaDefaultBold")
        titleLabel:SetTextColor(Color(255, 255, 255))
        
        -- Дата
        local dateLabel = vgui.Create("DLabel", newsCard)
        dateLabel:Dock(TOP)
        dateLabel:SetTall(20)
        dateLabel:DockMargin(15, 0, 15, 5)
        dateLabel:SetText("📅 " .. news.date)
        dateLabel:SetFont("DermaDefault")
        dateLabel:SetTextColor(Color(150, 150, 150))
        
        -- Содержание
        local contentLabel = vgui.Create("DLabel", newsCard)
        contentLabel:Dock(FILL)
        contentLabel:DockMargin(15, 0, 15, 10)
        contentLabel:SetText(news.content)
        contentLabel:SetFont("DermaDefault")
        contentLabel:SetTextColor(Color(200, 200, 200))
        contentLabel:SetWrap(true)
        contentLabel:SetAutoStretchVertical(true)
    end
    
    -- Вкладка "Советы"
    local tipsPanel = vgui.Create("DPanel")
    tipsPanel:Dock(FILL)
    
    local tipsScroll = vgui.Create("DScrollPanel", tipsPanel)
    tipsScroll:Dock(FILL)
    tipsScroll:DockMargin(10, 10, 10, 10)
    
    -- Заголовок советов
    local tipsHeader = vgui.Create("DLabel", tipsScroll)
    tipsHeader:Dock(TOP)
    tipsHeader:SetTall(40)
    tipsHeader:SetText("💡 Советы по игре")
    tipsHeader:SetFont("DermaLarge")
    tipsHeader:SetTextColor(Color(255, 255, 255))
    tipsHeader:DockMargin(0, 0, 0, 20)
    
    -- Добавляем советы
    for i, tip in ipairs(GameTips) do
        local tipCard = vgui.Create("DPanel", tipsScroll)
        tipCard:Dock(TOP)
        tipCard:SetTall(50)
        tipCard:DockMargin(0, 0, 0, 10)
        
        function tipCard:Paint(w, h)
            draw.RoundedBox(6, 0, 0, w, h, Color(50, 50, 50, 200))
            draw.RoundedBox(6, 0, 0, w, h, Color(100, 100, 100, 100), false)
        end
        
        local tipLabel = vgui.Create("DLabel", tipCard)
        tipLabel:Dock(FILL)
        tipLabel:DockMargin(15, 10, 15, 10)
        tipLabel:SetText(tip)
        tipLabel:SetFont("DermaDefault")
        tipLabel:SetTextColor(Color(255, 255, 255))
        tipLabel:SetWrap(true)
        tipLabel:SetAutoStretchVertical(true)
    end
    
    -- Вкладка "Статистика"
    local statsPanel = vgui.Create("DPanel")
    statsPanel:Dock(FILL)
    
    local statsScroll = vgui.Create("DScrollPanel", statsPanel)
    statsScroll:Dock(FILL)
    statsScroll:DockMargin(10, 10, 10, 10)
    
    -- Заголовок статистики
    local statsHeader = vgui.Create("DLabel", statsScroll)
    statsHeader:Dock(TOP)
    statsHeader:SetTall(40)
    statsHeader:SetText("📊 Статистика игры")
    statsHeader:SetFont("DermaLarge")
    statsHeader:SetTextColor(Color(255, 255, 255))
    statsHeader:DockMargin(0, 0, 0, 20)
    
    -- Информация о текущем состоянии
    local currentStateCard = vgui.Create("DPanel", statsScroll)
    currentStateCard:Dock(TOP)
    currentStateCard:SetTall(200)
    currentStateCard:DockMargin(0, 0, 0, 15)
    
    function currentStateCard:Paint(w, h)
        draw.RoundedBox(8, 0, 0, w, h, Color(40, 40, 60, 200))
        draw.RoundedBox(8, 0, 0, w, h, Color(80, 80, 100, 100), false)
    end
    
    -- Заголовок карточки
    local stateTitle = vgui.Create("DLabel", currentStateCard)
    stateTitle:Dock(TOP)
    stateTitle:SetTall(30)
    stateTitle:DockMargin(15, 10, 15, 10)
    stateTitle:SetText("🎮 Текущее состояние")
    stateTitle:SetFont("DermaDefaultBold")
    stateTitle:SetTextColor(Color(255, 255, 255))
    
    -- Информация о состоянии
    local stateInfo = vgui.Create("DLabel", currentStateCard)
    stateInfo:Dock(FILL)
    stateInfo:DockMargin(15, 0, 15, 10)
    
    local stateText = "Состояние игры: " .. (GM and GM.GameState or "Неизвестно") .. "\n"
    stateText = stateText .. "Ваша команда: " .. (ply:Team() == (GM and GM.TEAM_SURVIVOR or 2) and "Выживший" or 
                                                  ply:Team() == (GM and GM.TEAM_KILLER or 3) and "Убийца" or 
                                                  ply:Team() == (GM and GM.TEAM_SPECTATOR or 1) and "Наблюдатель" or "Неизвестно") .. "\n"
    stateText = stateText .. "Ваш персонаж: " .. (ply.SelectedCharacter or "Не выбран") .. "\n"
    stateText = stateText .. "Здоровье: " .. ply:Health() .. "/" .. ply:GetMaxHealth() .. "\n"
    stateText = stateText .. "Броня: " .. ply:Armor() .. "\n"
    stateText = stateText .. "Игроков онлайн: " .. #player.GetAll()
    
    stateInfo:SetText(stateText)
    stateInfo:SetFont("DermaDefault")
    stateInfo:SetTextColor(Color(200, 200, 200))
    stateInfo:SetWrap(true)
    stateInfo:SetAutoStretchVertical(true)
    
    -- Информация о командах
    local teamsCard = vgui.Create("DPanel", statsScroll)
    teamsCard:Dock(TOP)
    teamsCard:SetTall(150)
    teamsCard:DockMargin(0, 0, 0, 15)
    
    function teamsCard:Paint(w, h)
        draw.RoundedBox(8, 0, 0, w, h, Color(40, 60, 40, 200))
        draw.RoundedBox(8, 0, 0, w, h, Color(80, 100, 80, 100), false)
    end
    
    -- Заголовок команд
    local teamsTitle = vgui.Create("DLabel", teamsCard)
    teamsTitle:Dock(TOP)
    teamsTitle:SetTall(30)
    teamsTitle:DockMargin(15, 10, 15, 10)
    teamsTitle:SetText("👥 Команды")
    teamsTitle:SetFont("DermaDefaultBold")
    teamsTitle:SetTextColor(Color(255, 255, 255))
    
    -- Информация о командах
    local teamsInfo = vgui.Create("DLabel", teamsCard)
    teamsInfo:Dock(FILL)
    teamsInfo:DockMargin(15, 0, 15, 10)
    
    local survivors = 0
    local killers = 0
    local spectators = 0
    
    for _, player in pairs(player.GetAll()) do
        if player:Team() == (GM and GM.TEAM_SURVIVOR or 2) then
            survivors = survivors + 1
        elseif player:Team() == (GM and GM.TEAM_KILLER or 3) then
            killers = killers + 1
        elseif player:Team() == (GM and GM.TEAM_SPECTATOR or 1) then
            spectators = spectators + 1
        end
    end
    
    local teamsText = "Выжившие: " .. survivors .. " игроков\n"
    teamsText = teamsText .. "Убийцы: " .. killers .. " игроков\n"
    teamsText = teamsText .. "Наблюдатели: " .. spectators .. " игроков\n"
    teamsText = teamsText .. "Всего: " .. #player.GetAll() .. " игроков"
    
    teamsInfo:SetText(teamsText)
    teamsInfo:SetFont("DermaDefault")
    teamsInfo:SetTextColor(Color(200, 200, 200))
    teamsInfo:SetWrap(true)
    teamsInfo:SetAutoStretchVertical(true)
    
    -- Вкладка "Команды"
    local commandsPanel = vgui.Create("DPanel")
    commandsPanel:Dock(FILL)
    
    local commandsScroll = vgui.Create("DScrollPanel", commandsPanel)
    commandsScroll:Dock(FILL)
    commandsScroll:DockMargin(10, 10, 10, 10)
    
    -- Заголовок команд
    local commandsHeader = vgui.Create("DLabel", commandsScroll)
    commandsHeader:Dock(TOP)
    commandsHeader:SetTall(40)
    commandsHeader:SetText("⌨️ Полезные команды")
    commandsHeader:SetFont("DermaLarge")
    commandsHeader:SetTextColor(Color(255, 255, 255))
    commandsHeader:DockMargin(0, 0, 0, 20)
    
    -- Список команд
    local commands = {
        {cmd = "gmodsaken_debug_state", desc = "Показать состояние игры"},
        {cmd = "gmodsaken_give_gravgun", desc = "Получить грави пушку"},
        {cmd = "gmodsaken_test_disintegration", desc = "Тест эффектов дезинтеграции"},
        {cmd = "gmodsaken_music_volume 0.5", desc = "Установить громкость музыки"},
        {cmd = "gmodsaken_music_toggle", desc = "Включить/выключить музыку"},
        {cmd = "gmodsaken_weapon_info", desc = "Информация об оружии персонажа"},
        {cmd = "gmodsaken_test_medkit", desc = "Тест аптечки медика"},
        {cmd = "gmodsaken_test_mayor_aura", desc = "Тест ауры мэра"}
    }
    
    for i, command in ipairs(commands) do
        local cmdCard = vgui.Create("DPanel", commandsScroll)
        cmdCard:Dock(TOP)
        cmdCard:SetTall(60)
        cmdCard:DockMargin(0, 0, 0, 10)
        
        function cmdCard:Paint(w, h)
            draw.RoundedBox(6, 0, 0, w, h, Color(50, 50, 50, 200))
            draw.RoundedBox(6, 0, 0, w, h, Color(100, 100, 100, 100), false)
        end
        
        -- Команда
        local cmdLabel = vgui.Create("DLabel", cmdCard)
        cmdLabel:Dock(TOP)
        cmdLabel:SetTall(25)
        cmdLabel:DockMargin(15, 10, 15, 5)
        cmdLabel:SetText("⌨️ " .. command.cmd)
        cmdLabel:SetFont("DermaDefaultBold")
        cmdLabel:SetTextColor(Color(100, 200, 255))
        
        -- Описание
        local descLabel = vgui.Create("DLabel", cmdCard)
        descLabel:Dock(FILL)
        descLabel:DockMargin(15, 0, 15, 10)
        descLabel:SetText(command.desc)
        descLabel:SetFont("DermaDefault")
        descLabel:SetTextColor(Color(200, 200, 200))
    end
    
    -- Добавляем вкладки
    tabPanel:AddSheet("📰 Новости", newsPanel, "icon16/feed.png")
    tabPanel:AddSheet("💡 Советы", tipsPanel, "icon16/lightbulb.png")
    tabPanel:AddSheet("📊 Статистика", statsPanel, "icon16/chart_bar.png")
    tabPanel:AddSheet("⌨️ Команды", commandsPanel, "icon16/keyboard.png")
    
    infoMenuOpen = true
    gui.EnableScreenClicker(true)
end

-- Обработка нажатия F3
hook.Add("Think", "GModsaken_InfoMenuKey", function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    
    if input.IsKeyDown(KEY_F3) and not infoMenuOpen then
        CreateInfoMenu()
    end
end)

-- Команда для открытия меню
concommand.Add("gmodsaken_info_menu", function(ply, cmd, args)
    if not IsValid(ply) then return end
    CreateInfoMenu()
end)

-- Отладочная команда для информационного меню
concommand.Add("gmodsaken_debug_info_menu", function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    
    print("=== GModsaken Info Menu Debug ===")
    print("Info menu state:", infoMenuOpen)
    print("Menu valid:", IsValid(infoMenu))
    print("Player:", ply:Nick())
    print("Team:", ply:Team())
    print("GameState:", GM and GM.GameState or "Unknown")
    print("News count:", #GameNews)
    print("Tips count:", #GameTips)
    print("================================")
end)

print("[GModsaken] Information menu system loaded") 