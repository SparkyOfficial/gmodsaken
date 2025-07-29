--[[ GModsaken - Prop Menu System (Client) Copyright (C) 2024 GModsaken Contributors ]]

local propMenu = nil
local propMenuOpen = false
local lastPropSpawn = 0
local propCooldown = 60 -- 60 секунд

-- Разрешенные пропы для выживших (только надежные модели)
local allowedProps = {
    "models/props_junk/wooden_box01a.mdl",
    "models/props_junk/wooden_box02a.mdl", 
    "models/props_junk/wooden_box03a.mdl",
    "models/props_junk/wooden_box04a.mdl",
    "models/props_junk/wooden_box05a.mdl"
}

-- Создание Q-меню
function CreatePropMenu()
    if propMenu then propMenu:Remove() end
    
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    
    -- Проверяем, что игрок выживший
    if not GM or not GM.IsSurvivor or not GM:IsSurvivor(ply) then 
        ply:ChatPrint("Q-меню доступно только выжившим!")
        return 
    end
    
    propMenu = vgui.Create("DFrame")
    propMenu:SetSize(600, 400)
    propMenu:Center()
    propMenu:SetTitle("Q-Меню - Спавн Пропов")
    propMenu:SetDraggable(true)
    propMenu:ShowCloseButton(true)
    propMenu:MakePopup()
    
    -- Закрытие меню
    function propMenu:OnClose()
        propMenuOpen = false
        gui.EnableScreenClicker(false)
    end
    
    -- Список пропов
    local propsList = vgui.Create("DScrollPanel", propMenu)
    propsList:Dock(FILL)
    propsList:DockMargin(10, 10, 10, 10)
    
    -- Добавляем пропы
    for _, model in pairs(allowedProps) do
        local button = vgui.Create("DButton", propsList)
        button:Dock(TOP)
        button:DockMargin(0, 0, 0, 5)
        button:SetTall(60)
        button:SetText("Спавн: " .. model)
        
        function button:DoClick()
            local timeLeft = propCooldown - (CurTime() - lastPropSpawn)
            if timeLeft > 0 then
                ply:ChatPrint("Подождите " .. math.ceil(timeLeft) .. " секунд перед следующим спавном!")
                return
            end
            
            net.Start("GModsaken_SpawnProp")
            net.WriteString(model)
            net.SendToServer()
            
            lastPropSpawn = CurTime()
            propMenu:Close()
            ply:ChatPrint("Проп создан!")
        end
    end
    
    -- Информация
    local infoLabel = vgui.Create("DLabel", propMenu)
    infoLabel:Dock(BOTTOM)
    infoLabel:DockMargin(10, 10, 10, 10)
    infoLabel:SetText("Информация:\n• Кулдаун: 60 секунд\n• Пропы нельзя заморозить\n• Убийца может разрушить пропы топором")
    infoLabel:SetWrap(true)
    infoLabel:SetAutoStretchVertical(true)
    
    propMenuOpen = true
    gui.EnableScreenClicker(true)
end

-- Обработка нажатия Q
hook.Add("Think", "GModsaken_PropMenuKey", function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    
    if input.IsKeyDown(KEY_Q) and not propMenuOpen then
        CreatePropMenu()
    end
end)

print("[GModsaken] Prop menu system loaded")
