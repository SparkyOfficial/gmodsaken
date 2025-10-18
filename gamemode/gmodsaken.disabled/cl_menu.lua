--[[
    GModsaken - Menu System (Client)
    Copyright (C) 2024 GModsaken Contributors
]]

local PANEL = {}
local config = GM.Menu.Config
local colors = config.Colors
local fonts = config.Fonts

-- Создаем основной фрейм меню
function PANEL:Init()
    self:SetSize(config.Width, config.Height)
    self:Center()
    self:SetTitle("")
    self:ShowCloseButton(false)
    self:SetDraggable(true)
    self:MakePopup()
    self:SetAlpha(0)
    self:AlphaTo(255, 0.2, 0)
    
    -- Заголовок окна
    self.title = vgui.Create("DLabel", self)
    self.title:SetText("GMODSAKEN")
    self.title:SetFont(fonts.Title)
    self.title:SetTextColor(colors.Text)
    self.title:SizeToContents()
    
    -- Кнопка закрытия
    self.closeButton = vgui.Create("DButton", self)
    self.closeButton:SetText("✕")
    self.closeButton:SetFont("DermaDefaultBold")
    self.closeButton:SetTextColor(colors.Text)
    self.closeButton.Paint = function(s, w, h)
        draw.RoundedBox(4, 0, 0, w, h, s:IsHovered() and Color(200, 50, 50, 150) or Color(0, 0, 0, 50))
    end
    self.closeButton.DoClick = function()
        GM.Menu:Toggle()
    end
    
    -- Создаем панель вкладок
    self.tabPanel = vgui.Create("DPanel", self)
    self.tabPanel.Paint = function(s, w, h)
        surface.SetDrawColor(colors.Header)
        surface.DrawRect(0, 0, w, h)
    end
    
    -- Создаем панель содержимого
    self.contentPanel = vgui.Create("DPanel", self)
    self.contentPanel.Paint = function(s, w, h)
        draw.RoundedBox(4, 0, 0, w, h, colors.Background)
    end
    
    -- Создаем вкладки
    self.tabs = {}
    self:CreateTabs()
    
    -- Выбираем первую вкладку
    if #self.tabs > 0 then
        self:SelectTab(1)
    end
end

-- Создаем вкладки
function PANEL:CreateTabs()
    local tabCount = #GM.Menu.Tabs
    local tabWidth = (self:GetWide() - config.Padding * 2) / tabCount - config.Padding
    
    for i, tabData in ipairs(GM.Menu.Tabs) do
        local tab = vgui.Create("DButton", self.tabPanel)
        tab:SetText(tabData.name)
        tab:SetFont(fonts.Tab)
        tab:SetTextColor(colors.Text)
        tab:SetSize(tabWidth, 40)
        tab:SetPos((i - 1) * (tabWidth + config.Padding) + config.Padding, 0)
        tab.tabId = i
        
        tab.Paint = function(s, w, h)
            local isActive = (self.activeTab == s.tabId)
            local isHovered = s:IsHovered()
            
            if isActive then
                draw.RoundedBoxEx(4, 0, 0, w, h, colors.TabActive, true, true, false, false)
            elseif isHovered then
                draw.RoundedBoxEx(4, 0, 0, w, h, colors.TabHover, true, true, false, false)
            else
                draw.RoundedBoxEx(4, 0, 0, w, h, colors.Tab, true, true, false, false)
            end
            
            -- Подчеркивание активной вкладки
            if isActive then
                surface.SetDrawColor(colors.Accent)
                surface.DrawRect(0, h - 4, w, 4)
            end
        end
        
        tab.DoClick = function()
            self:SelectTab(s.tabId)
        end
        
        self.tabs[i] = tab
    end
end

-- Выбор вкладки
function PANEL:SelectTab(tabId)
    self.activeTab = tabId
    GM.Menu:SetCurrentTab(tabId)
    
    -- Обновляем внешний вид вкладок
    for i, tab in ipairs(self.tabs) do
        if tab:IsValid() then
            if i == tabId then
                tab:SetFont(fonts.TabActive)
            else
                tab:SetFont(fonts.Tab)
            end
        end
    end
    
    -- Очищаем содержимое
    self.contentPanel:Clear()
    
    -- Загружаем содержимое выбранной вкладки
    local tabData = GM.Menu.Tabs[tabId]
    if tabData then
        local contentFunc = self["Load" .. string.upper(string.sub(tabData.id, 1, 1)) .. string.sub(tabData.id, 2) .. "Tab"]
        if contentFunc then
            contentFunc(self)
        end
    end
end

-- Загрузка вкладки новостей
function PANEL:LoadNewsTab()
    local scroll = vgui.Create("DScrollPanel", self.contentPanel)
    scroll:Dock(FILL)
    scroll:DockMargin(10, 10, 10, 10)
    scroll:GetVBar():SetWide(8)
    
    local newsList = vgui.Create("DListLayout", scroll)
    newsList:Dock(FILL)
    newsList:SetSpaceY(15)
    
    for _, news in ipairs(GM.Menu.News) do
        local newsPanel = vgui.Create("DPanel")
        newsPanel:SetTall(120)
        newsPanel:DockMargin(0, 0, 0, 10)
        newsPanel.Paint = function(s, w, h)
            -- Фон новости
            if news.important then
                draw.RoundedBox(4, 0, 0, w, h, Color(60, 40, 40, 200))
                surface.SetDrawColor(200, 50, 50, 100)
                surface.DrawOutlinedRect(0, 0, w, h, 2)
            else
                draw.RoundedBox(4, 0, 0, w, h, Color(40, 40, 50, 200))
            end
            
            -- Заголовок
            draw.SimpleText(news.title, fonts.Section, 15, 15, colors.Text)
            
            -- Дата
            draw.SimpleText(news.date, fonts.Small, w - 15, 20, colors.TextMuted, TEXT_ALIGN_RIGHT)
            
            -- Разделитель
            surface.SetDrawColor(colors.Border)
            surface.DrawLine(15, 50, w - 15, 50)
            
            -- Содержимое
            local y = 65
            for _, line in ipairs(news.content) do
                draw.SimpleText(line, fonts.Text, 20, y, colors.Text)
                y = y + 20
            end
        end
        
        newsList:Add(newsPanel)
    end
end

-- Загрузка вкладки геймплея
function PANEL:LoadGameplayTab()
    local scroll = vgui.Create("DScrollPanel", self.contentPanel)
    scroll:Dock(FILL)
    scroll:DockMargin(10, 10, 10, 10)
    scroll:GetVBar():SetWide(8)
    
    local gameInfo = vgui.Create("DListLayout", scroll)
    gameInfo:Dock(FILL)
    gameInfo:SetSpaceY(15)
    
    for _, section in ipairs(GM.Menu.Gameplay) do
        local sectionPanel = vgui.Create("DPanel")
        sectionPanel:SetTall(100)
        sectionPanel:DockMargin(0, 0, 0, 10)
        sectionPanel.Paint = function(s, w, h)
            draw.RoundedBox(4, 0, 0, w, h, Color(40, 40, 50, 200))
            
            -- Заголовок
            draw.SimpleText(section.title, fonts.Section, 15, 15, colors.Accent)
            
            -- Разделитель
            surface.SetDrawColor(colors.Border)
            surface.DrawLine(15, 45, w - 15, 45)
            
            -- Содержимое
            local y = 60
            for _, line in ipairs(section.content) do
                draw.SimpleText("• " .. line, fonts.Text, 20, y, colors.Text)
                y = y + 20
            end
        end
        
        gameInfo:Add(sectionPanel)
    end
end

-- Загрузка вкладки команд
function PANEL:LoadCommandsTab()
    local scroll = vgui.Create("DScrollPanel", self.contentPanel)
    scroll:Dock(FILL)
    scroll:DockMargin(10, 10, 10, 10)
    scroll:GetVBar():SetWide(8)
    
    local commandsList = vgui.Create("DListLayout", scroll)
    commandsList:Dock(FILL)
    commandsList:SetSpaceY(5)
    
    -- Разделяем команды на две колонки
    local columns = {vgui.Create("DListLayout"), vgui.Create("DListLayout")}
    
    for i, column in ipairs(columns) do
        column:Dock(LEFT)
        column:SetWide((self.contentPanel:GetWide() - 40) / 2)
        if i == 2 then
            column:DockMargin(10, 0, 0, 0)
        end
        commandsList:Add(column)
    end
    
    -- Распределяем команды по колонкам
    for i, cmd in ipairs(GM.Menu.Commands) do
        local column = columns[i % 2 + 1]
        
        local cmdPanel = vgui.Create("DPanel")
        cmdPanel:SetTall(40)
        cmdPanel:DockMargin(0, 0, 0, 5)
        cmdPanel.Paint = function(s, w, h)
            draw.RoundedBox(4, 0, 0, w, h, Color(40, 40, 50, 200))
            
            -- Клавиша
            draw.RoundedBox(4, 10, 8, 50, 24, colors.Accent)
            draw.SimpleText(cmd.command, fonts.Button, 35, 20, colors.Text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            
            -- Описание
            draw.SimpleText(cmd.description, fonts.Text, 70, 20, colors.Text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end
        
        column:Add(cmdPanel)
    end
end

-- Загрузка вкладки настроек
function PANEL:LoadSettingsTab()
    local scroll = vgui.Create("DScrollPanel", self.contentPanel)
    scroll:Dock(FILL)
    scroll:DockMargin(10, 10, 10, 10)
    scroll:GetVBar():SetWide(8)
    
    local settingsList = vgui.Create("DListLayout", scroll)
    settingsList:Dock(FILL)
    settingsList:SetSpaceY(15)
    
    for _, setting in ipairs(GM.Menu.Settings) do
        local settingPanel = vgui.Create("DPanel")
        settingPanel:SetTall(60)
        settingPanel:DockMargin(0, 0, 0, 10)
        settingPanel.Paint = function(s, w, h)
            draw.RoundedBox(4, 0, 0, w, h, Color(40, 40, 50, 200))
            draw.SimpleText(setting.name, fonts.Text, 15, 10, colors.Text)
        end
        
        -- Создаем элементы управления в зависимости от типа настройки
        if setting.type == "slider" then
            local slider = vgui.Create("DNumSlider", settingPanel)
            slider:SetSize(settingPanel:GetWide() - 30, 30)
            slider:SetPos(15, 30)
            slider:SetMin(setting.min or 0)
            slider:SetMax(setting.max or 100)
            slider:SetDecimals(setting.decimals or 0)
            slider:SetValue(GetConVar(setting.convar):GetFloat() or setting.value)
            slider:SetText("")
            
            slider.OnValueChanged = function(_, value)
                RunConsoleCommand(setting.convar, tostring(value))
            end
            
        elseif setting.type == "checkbox" then
            local checkbox = vgui.Create("DCheckBox", settingPanel)
            checkbox:SetPos(settingPanel:GetWide() - 40, 15)
            checkbox:SetValue(GetConVar(setting.convar):GetBool() and 1 or 0)
            
            checkbox.OnChange = function(_, value)
                RunConsoleCommand(setting.convar, value and "1" or "0")
            end
            
        elseif setting.type == "combo" then
            local combo = vgui.Create("DComboBox", settingPanel)
            combo:SetSize(200, 30)
            combo:SetPos(settingPanel:GetWide() - 215, 15)
            
            for _, option in ipairs(setting.options) do
                combo:AddChoice(option)
            end
            
            local currentValue = GetConVar(setting.convar):GetString()
            local selectedIndex = 1
            
            for i, option in ipairs(setting.options) do
                if option == currentValue then
                    selectedIndex = i
                    break
                end
            end
            
            combo:ChooseOptionID(selectedIndex)
            
            combo.OnSelect = function(_, index, value)
                RunConsoleCommand(setting.convar, tostring(value))
            end
        end
        
        settingsList:Add(settingPanel)
    end
end

-- Обработка изменения размера
function PANEL:PerformLayout(w, h)
    self.title:SetPos(15, 10)
    self.closeButton:SetSize(30, 30)
    self.closeButton:SetPos(w - 40, 5)
    
    self.tabPanel:SetPos(0, 40)
    self.tabPanel:SetSize(w, 40)
    
    self.contentPanel:SetPos(0, 80)
    self.contentPanel:SetSize(w, h - 80)
    
    -- Обновляем размеры вкладок
    local tabCount = #self.tabs
    if tabCount > 0 then
        local tabWidth = (w - config.Padding * 2) / tabCount - config.Padding
        for i, tab in ipairs(self.tabs) do
            if IsValid(tab) then
                tab:SetSize(tabWidth, 40)
                tab:SetPos((i - 1) * (tabWidth + config.Padding) + config.Padding, 0)
            end
        end
    end
end

-- Отрисовка фона
function PANEL:Paint(w, h)
    -- Затемнение фона
    draw.RoundedBox(0, 0, 0, w, h, Color(0, 0, 0, 200))
    
    -- Фон окна
    draw.RoundedBox(8, 0, 0, w, h, colors.Background)
    
    -- Заголовок
    draw.RoundedBoxEx(8, 0, 0, w, 40, colors.Header, true, true, false, false)
    
    -- Обводка
    surface.SetDrawColor(colors.Border)
    surface.DrawOutlinedRect(0, 0, w, h, 2)
    surface.DrawLine(0, 40, w, 40)
end

-- Анимация закрытия
function PANEL:Close()
    self:AlphaTo(0, 0.2, 0, function()
        self:Remove()
    end)
end

-- Регистрируем панель
vgui.Register("GModsakenMenu", PANEL, "DFrame")

-- Создаем меню
local menu = nil

-- Функция для открытия/закрытия меню
local function ToggleMenu()
    if IsValid(menu) then
        menu:Close()
        menu = nil
    else
        menu = vgui.Create("GModsakenMenu")
    end
    
    gui.EnableScreenClicker(IsValid(menu))
    return IsValid(menu)
end

-- Привязываем к клавише F3
hook.Add("PlayerButtonDown", "GModsakenMenuKey", function(_, key)
    if key == GM.Menu.Config.Key then
        ToggleMenu()
        return true
    end
end)

-- Блокируем F2
hook.Add("PlayerBindPress", "GModsakenBlockF2", function(_, bind)
    if string.find(bind:lower(), "+showscores") or string.find(bind:lower(), "showscores") then
        return true
    end
end)

-- Экспортируем функцию для открытия меню
function GM.Menu:Open()
    return ToggleMenu()
end

-- Обновляем функцию Toggle
function GM.Menu:Toggle()
    return ToggleMenu()
end

-- Функция для проверки видимости меню
function GM.Menu:IsOpen()
    return IsValid(menu)
end
