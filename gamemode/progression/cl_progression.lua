--[[
    GModsaken - Progression System (Client)
    Copyright (C) 2024 GModsaken Contributors
]]

include("sh_progression.lua")

-- Текущая прогрессия игрока
local LocalPlayerProgression = {}

-- Функция для создания меню прогрессии
function GM:CreateProgressionMenu()
    local frame = vgui.Create("DFrame")
    frame:SetSize(600, 500)
    frame:Center()
    frame:SetTitle("Прогрессия")
    frame:MakePopup()
    
    -- Панель с вкладками
    local sheet = vgui.Create("DPropertySheet", frame)
    sheet:Dock(FILL)
    
    -- Вкладка с общей информацией
    local infoPanel = self:CreateProgressionInfoPanel()
    sheet:AddSheet("Информация", infoPanel, "icon16/user.png")
    
    -- Вкладка с перками
    local perksPanel = self:CreatePerksPanel()
    sheet:AddSheet("Перки", perksPanel, "icon16/star.png")
    
    -- Вкладка с косметикой
    local cosmeticsPanel = self:CreateCosmeticsPanel()
    sheet:AddSheet("Косметика", cosmeticsPanel, "icon16/palette.png")
end

-- Функция для создания панели с общей информацией
function GM:CreateProgressionInfoPanel()
    local panel = vgui.Create("DPanel")
    panel:Dock(FILL)
    panel:DockPadding(10, 10, 10, 10)
    
    -- Информация об уровне и XP
    local infoPanel = vgui.Create("DPanel", panel)
    infoPanel:Dock(TOP)
    infoPanel:SetTall(100)
    infoPanel:DockMargin(0, 0, 0, 10)
    
    local levelLabel = vgui.Create("DLabel", infoPanel)
    levelLabel:SetPos(10, 10)
    levelLabel:SetText("Уровень: загрузка...")
    levelLabel:SetFont("DermaLarge")
    
    local xpLabel = vgui.Create("DLabel", infoPanel)
    xpLabel:SetPos(10, 40)
    xpLabel:SetText("XP: загрузка...")
    
    local xpBar = vgui.Create("DProgress", infoPanel)
    xpBar:SetPos(10, 70)
    xpBar:SetSize(560, 20)
    xpBar:SetFraction(0)
    
    -- Кнопка для запроса обновления
    local refreshButton = vgui.Create("DButton", panel)
    refreshButton:Dock(TOP)
    refreshButton:SetText("Обновить")
    refreshButton:SetTall(30)
    refreshButton:DockMargin(0, 0, 0, 10)
    refreshButton.DoClick = function()
        net.Start("GModsaken_RequestProgression")
        net.SendToServer()
    end
    
    -- Обновляем информацию
    self:UpdateProgressionInfo(levelLabel, xpLabel, xpBar)
    
    return panel
end

-- Функция для обновления информации о прогрессии
function GM:UpdateProgressionInfo(levelLabel, xpLabel, xpBar)
    if not LocalPlayerProgression then return end
    
    local level = LocalPlayerProgression.level or 1
    local xp = LocalPlayerProgression.xp or 0
    
    local xpRequired = GM.XPRequirements[level + 1] or GM.XPRequirements[level]
    local xpCurrentLevel = GM.XPRequirements[level] or 0
    local xpNeeded = xpRequired - xpCurrentLevel
    local xpProgress = xp - xpCurrentLevel
    
    if levelLabel then
        levelLabel:SetText("Уровень: " .. level)
    end
    
    if xpLabel then
        xpLabel:SetText("XP: " .. xp .. " / " .. xpRequired .. " (до следующего уровня: " .. (xpNeeded - xpProgress) .. ")")
    end
    
    if xpBar then
        local fraction = xpNeeded > 0 and (xpProgress / xpNeeded) or 0
        xpBar:SetFraction(fraction)
    end
end

-- Функция для создания панели перков
function GM:CreatePerksPanel()
    local panel = vgui.Create("DPanel")
    panel:Dock(FILL)
    panel:DockPadding(10, 10, 10, 10)
    
    local scrollPanel = vgui.Create("DScrollPanel", panel)
    scrollPanel:Dock(FILL)
    
    local layout = vgui.Create("DListLayout", scrollPanel)
    layout:Dock(FILL)
    
    -- Определяем роль игрока
    local role = LocalPlayer():Team() == GM.TEAM_KILLER and "killer" or "survivor"
    local perks = GM.Perks[role] or {}
    
    -- Создаем панели для каждого перка
    for _, perk in pairs(perks) do
        local perkPanel = vgui.Create("DPanel", layout)
        perkPanel:SetTall(80)
        perkPanel:Dock(TOP)
        perkPanel:DockMargin(0, 0, 0, 5)
        
        -- Проверяем, разблокирован ли перк
        local isUnlocked = false
        for _, unlockedPerkID in pairs(LocalPlayerProgression.unlockedPerks or {}) do
            if unlockedPerkID == perk.id then
                isUnlocked = true
                break
            end
        end
        
        -- Цвет в зависимости от состояния
        if isUnlocked then
            perkPanel:SetBackgroundColor(Color(0, 100, 0, 100))
        elseif LocalPlayerProgression.level >= perk.levelRequired then
            perkPanel:SetBackgroundColor(Color(100, 100, 0, 100))
        else
            perkPanel:SetBackgroundColor(Color(100, 0, 0, 100))
        end
        
        local nameLabel = vgui.Create("DLabel", perkPanel)
        nameLabel:SetPos(10, 10)
        nameLabel:SetText(perk.name)
        nameLabel:SetFont("DermaMedium")
        
        local descLabel = vgui.Create("DLabel", perkPanel)
        descLabel:SetPos(10, 35)
        descLabel:SetText(perk.description)
        descLabel:SetSize(400, 20)
        descLabel:SetWrap(true)
        
        local levelLabel = vgui.Create("DLabel", perkPanel)
        levelLabel:SetPos(10, 55)
        levelLabel:SetText("Требуемый уровень: " .. perk.levelRequired)
        
        -- Кнопка разблокировки (если доступно)
        if not isUnlocked and LocalPlayerProgression.level >= perk.levelRequired then
            local unlockButton = vgui.Create("DButton", perkPanel)
            unlockButton:SetPos(450, 25)
            unlockButton:SetSize(100, 30)
            unlockButton:SetText("Разблокировать")
            unlockButton.DoClick = function()
                net.Start("GModsaken_UnlockPerk")
                net.WriteString(perk.id)
                net.SendToServer()
            end
        elseif isUnlocked then
            local unlockedLabel = vgui.Create("DLabel", perkPanel)
            unlockedLabel:SetPos(450, 25)
            unlockedLabel:SetText("Разблокирован")
            unlockedLabel:SetTextColor(Color(0, 255, 0))
        end
    end
    
    return panel
end

-- Функция для создания панели косметики
function GM:CreateCosmeticsPanel()
    local panel = vgui.Create("DPanel")
    panel:Dock(FILL)
    panel:DockPadding(10, 10, 10, 10)
    
    local scrollPanel = vgui.Create("DScrollPanel", panel)
    scrollPanel:Dock(FILL)
    
    local layout = vgui.Create("DListLayout", scrollPanel)
    layout:Dock(FILL)
    
    -- Определяем роль игрока
    local role = LocalPlayer():Team() == GM.TEAM_KILLER and "killer" or "survivor"
    local cosmetics = GM.Cosmetics[role] or {}
    
    -- Создаем панели для каждой косметики
    for _, cosmetic in pairs(cosmetics) do
        local cosmeticPanel = vgui.Create("DPanel", layout)
        cosmeticPanel:SetTall(80)
        cosmeticPanel:Dock(TOP)
        cosmeticPanel:DockMargin(0, 0, 0, 5)
        
        -- Проверяем, разблокирована ли косметика
        local isUnlocked = false
        for _, unlockedCosmeticID in pairs(LocalPlayerProgression.unlockedCosmetics or {}) do
            if unlockedCosmeticID == cosmetic.id then
                isUnlocked = true
                break
            end
        end
        
        -- Цвет в зависимости от состояния
        if isUnlocked then
            cosmeticPanel:SetBackgroundColor(Color(0, 100, 0, 100))
        elseif LocalPlayerProgression.level >= cosmetic.levelRequired then
            cosmeticPanel:SetBackgroundColor(Color(100, 100, 0, 100))
        else
            cosmeticPanel:SetBackgroundColor(Color(100, 0, 0, 100))
        end
        
        local nameLabel = vgui.Create("DLabel", cosmeticPanel)
        nameLabel:SetPos(10, 10)
        nameLabel:SetText(cosmetic.name)
        nameLabel:SetFont("DermaMedium")
        
        local descLabel = vgui.Create("DLabel", cosmeticPanel)
        descLabel:SetPos(10, 35)
        descLabel:SetText(cosmetic.description)
        descLabel:SetSize(400, 20)
        descLabel:SetWrap(true)
        
        local levelLabel = vgui.Create("DLabel", cosmeticPanel)
        levelLabel:SetPos(10, 55)
        levelLabel:SetText("Требуемый уровень: " .. cosmetic.levelRequired)
        
        -- Кнопка разблокировки (если доступно)
        if not isUnlocked and LocalPlayerProgression.level >= cosmetic.levelRequired then
            local unlockButton = vgui.Create("DButton", cosmeticPanel)
            unlockButton:SetPos(450, 25)
            unlockButton:SetSize(100, 30)
            unlockButton:SetText("Разблокировать")
            unlockButton.DoClick = function()
                net.Start("GModsaken_UnlockCosmetic")
                net.WriteString(cosmetic.id)
                net.SendToServer()
            end
        elseif isUnlocked then
            local unlockedLabel = vgui.Create("DLabel", cosmeticPanel)
            unlockedLabel:SetPos(450, 25)
            unlockedLabel:SetText("Разблокирована")
            unlockedLabel:SetTextColor(Color(0, 255, 0))
        end
    end
    
    return panel
end

-- Обработчик сетевого сообщения с обновлением прогрессии
net.Receive("GModsaken_ProgressionUpdate", function()
    LocalPlayerProgression = net.ReadTable()
    
    -- Если меню открыто, обновляем его
    if IsValid(GM.ProgressionMenu) then
        -- Здесь можно добавить код для обновления открытого меню
    end
end)

-- Консольная команда для открытия меню прогрессии
concommand.Add("gmodsaken_progression", function()
    GAMEMODE:CreateProgressionMenu()
end)