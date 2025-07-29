--[[
    GModsaken - Quest System
    Copyright (C) 2024 GModsaken Contributors
]]

-- Ensure GM table exists
if not _G.GM then
    _G.GM = {}
end
local GM = _G.GM
_G.GAMEMODE = GM

-- Координаты для квестов
GM.QuestData = {
    -- Мусорный бак (цель)
    TrashDumpster = {
        pos = Vector(-512.406738, -1772.493896, -79.968750),
        model = "models/props_junk/trashdumpster02.mdl"
    },
    
    -- Точки спавна мусора
    TrashSpawnPoints = {
        Vector(-3682.334229, 2990.098633, 15.012653),
        Vector(-1697.571411, 73.499260, -83.968750),
        Vector(132.388412, 1901.763428, -71.911926),
        Vector(1104.948364, 2495.072510, 32.031250),
        Vector(767.933655, 4239.131348, 32.031250),
        Vector(787.569946, -1721.306030, -79.968750),
        Vector(1613.433716, -423.299652, -79.968750),
        Vector(-2201.997314, -111.184998, -447.968750),
        Vector(-2531.063965, -2112.684326, 320.031250),
        Vector(-3810.473145, 4571.469238, -31.968750)
    },
    
    -- Точки спавна интерфейсов Combine
    InterfaceSpawnPoints = {
        Vector(-1689.872314, -932.624512, -79.646790),
        Vector(1451.787476, -805.976807, -79.968750),
        Vector(-3872.618164, 5643.802246, -31.968750)
    }
}

-- Статистика квестов
GM.QuestStats = {
    TrashCollected = 0,
    InterfacesUsed = 0,
    TimeAdded = 0
}

-- Модели мусора (только надежные)
GM.TrashModels = {
    "models/props_junk/garbage_plasticbottle001a.mdl",
    "models/props_junk/garbage_plasticbottle001a.mdl",
    "models/props_junk/garbage_plasticbottle001a.mdl",
    "models/props_junk/garbage_plasticbottle001a.mdl",
    "models/props_junk/garbage_plasticbottle001a.mdl",
    "models/props_junk/garbage_plasticbottle001a.mdl",
    "models/props_junk/garbage_plasticbottle001a.mdl",
    "models/props_junk/garbage_plasticbottle001a.mdl",
    "models/props_junk/garbage_plasticbottle001a.mdl",
    "models/props_junk/garbage_plasticbottle001a.mdl"
}

-- Создание мусорного бака
function GM:CreateTrashDumpster()
    if SERVER then
        -- Удаляем старый мусорный бак если есть
        for _, ent in pairs(ents.FindByClass("prop_physics")) do
            if ent:GetModel() == self.QuestData.TrashDumpster.model then
                ent:Remove()
            end
        end
        
        -- Создаем новый мусорный бак
        local dumpster = ents.Create("prop_physics")
        if IsValid(dumpster) then
            dumpster:SetModel(self.QuestData.TrashDumpster.model)
            dumpster:SetPos(self.QuestData.TrashDumpster.pos)
            dumpster:SetAngles(Angle(0, 0, 0))
            dumpster:Spawn()
            dumpster:SetMoveType(MOVETYPE_NONE)
            dumpster:SetSolid(SOLID_VPHYSICS)
            dumpster:SetCollisionGroup(COLLISION_GROUP_WORLD)
            
            -- Делаем его интерактивным
            dumpster:SetNWString("QuestType", "TrashDumpster")
            dumpster:SetNWBool("IsQuestObject", true)
            
            print("[GModsaken] Trash dumpster created at: " .. tostring(self.QuestData.TrashDumpster.pos))
        end
    end
end

-- Создание мусора
function GM:CreateTrash()
    if SERVER then
        -- Удаляем старый мусор
        for _, ent in pairs(ents.FindByClass("prop_physics")) do
            if ent:GetNWString("QuestType") == "Trash" then
                ent:Remove()
            end
        end
        
        -- Создаем новый мусор в случайных точках
        for i, spawnPos in pairs(self.QuestData.TrashSpawnPoints) do
            local trash = ents.Create("prop_physics")
            if IsValid(trash) then
                local randomModel = self.TrashModels[math.random(1, #self.TrashModels)]
                trash:SetModel(randomModel)
                trash:SetPos(spawnPos + Vector(0, 0, 10)) -- Немного поднимаем
                trash:SetAngles(Angle(0, math.random(0, 360), 0))
                trash:Spawn()
                
                -- Делаем его интерактивным
                trash:SetNWString("QuestType", "Trash")
                trash:SetNWBool("IsQuestObject", true)
                trash:SetNWInt("TrashID", i)
                
                -- Добавляем физику
                local phys = trash:GetPhysicsObject()
                if IsValid(phys) then
                    phys:Wake()
                end
                
                print("[GModsaken] Trash created at: " .. tostring(spawnPos))
            end
        end
    end
end

-- Создание интерфейса Combine
function GM:CreateCombineInterface()
    if SERVER then
        -- Удаляем старый интерфейс
        for _, ent in pairs(ents.FindByClass("prop_physics")) do
            if ent:GetNWString("QuestType") == "CombineInterface" then
                ent:Remove()
            end
        end
        
        -- Выбираем случайную точку спавна
        local spawnPos = self.QuestData.InterfaceSpawnPoints[math.random(1, #self.QuestData.InterfaceSpawnPoints)]
        
        -- Создаем интерфейс
        local interface = ents.Create("prop_physics")
        if IsValid(interface) then
            interface:SetModel("models/props_combine/combine_interface001.mdl")
            interface:SetPos(spawnPos)
            interface:SetAngles(Angle(0, math.random(0, 360), 0))
            interface:Spawn()
            interface:SetMoveType(MOVETYPE_NONE)
            interface:SetSolid(SOLID_VPHYSICS)
            interface:SetCollisionGroup(COLLISION_GROUP_WORLD)
            
            -- Делаем его интерактивным
            interface:SetNWString("QuestType", "CombineInterface")
            interface:SetNWBool("IsQuestObject", true)
            interface:SetNWBool("CanUse", true)
            interface:SetNWFloat("LastUseTime", 0)
            
            print("[GModsaken] Combine interface created at: " .. tostring(spawnPos))
        end
    end
end

-- Обработка сбора мусора
function GM:CollectTrash(trash, player)
    if not IsValid(trash) or not IsValid(player) then return end
    if trash:GetNWString("QuestType") ~= "Trash" then return end
    
    -- Удаляем мусор
    trash:Remove()
    
    -- Обновляем статистику
    self.QuestStats.TrashCollected = self.QuestStats.TrashCollected + 1
    self.QuestStats.TimeAdded = self.QuestStats.TimeAdded + 20
    
    -- Уменьшаем время до победы (ускоряем победу выживших)
    if self.RoundEndTime then
        self.RoundEndTime = self.RoundEndTime - 20
        print("[GModsaken] Reduced round time by 20 seconds. New end time: " .. os.date("%H:%M:%S", self.RoundEndTime))
    end
    
    -- Уведомляем игрока
    player:ChatPrint("✓ Мусор собран! -20 секунд до победы выживших")
    
    -- Звуковой эффект
    player:EmitSound("items/ammo_pickup.wav")
    
    -- Отправляем обновление всем клиентам
    if util.NetworkStringToID("GModsaken_UpdateQuestStats") ~= 0 then
        net.Start("GModsaken_UpdateQuestStats")
        net.WriteInt(self.QuestStats.TrashCollected, 32)
        net.WriteInt(self.QuestStats.InterfacesUsed, 32)
        net.WriteInt(self.QuestStats.TimeAdded, 32)
        net.Broadcast()
    end
end

-- Обработка использования интерфейса Combine
function GM:UseCombineInterface(interface, player)
    if not IsValid(interface) or not IsValid(player) then return end
    if interface:GetNWString("QuestType") ~= "CombineInterface" then return end
    
    local currentTime = CurTime()
    local lastUseTime = interface:GetNWFloat("LastUseTime", 0)
    
    -- Проверяем кулдаун
    if currentTime - lastUseTime < 90 then
        local remainingTime = math.ceil(90 - (currentTime - lastUseTime))
        player:ChatPrint("⏰ Интерфейс перезагружается... Осталось: " .. remainingTime .. " секунд")
        player:EmitSound("buttons/button10.wav")
        return
    end
    
    -- Обновляем время последнего использования
    interface:SetNWFloat("LastUseTime", currentTime)
    
    -- Обновляем статистику
    self.QuestStats.InterfacesUsed = self.QuestStats.InterfacesUsed + 1
    self.QuestStats.TimeAdded = self.QuestStats.TimeAdded + 30
    
    -- Уменьшаем время до победы (ускоряем победу выживших)
    if self.RoundEndTime then
        self.RoundEndTime = self.RoundEndTime - 30
        print("[GModsaken] Reduced round time by 30 seconds. New end time: " .. os.date("%H:%M:%S", self.RoundEndTime))
    end
    
    -- Уведомляем игрока
    player:ChatPrint("✓ Интерфейс активирован! -30 секунд до победы выживших")
    
    -- Звуковые эффекты
    player:EmitSound("buttons/button15.wav")
    timer.Simple(0.5, function()
        if IsValid(player) then
            player:EmitSound("ambient/machines/steam_release_1.wav")
        end
    end)
    
    -- Визуальный эффект
    local effectData = EffectData()
    effectData:SetOrigin(interface:GetPos())
    util.Effect("cball_explode", effectData)
    
    -- Отправляем обновление всем клиентам
    if util.NetworkStringToID("GModsaken_UpdateQuestStats") ~= 0 then
        net.Start("GModsaken_UpdateQuestStats")
        net.WriteInt(self.QuestStats.TrashCollected, 32)
        net.WriteInt(self.QuestStats.InterfacesUsed, 32)
        net.WriteInt(self.QuestStats.TimeAdded, 32)
        net.Broadcast()
    end
end

-- Инициализация квестов в начале раунда
function GM:InitializeQuests()
    if SERVER then
        print("[GModsaken] Initializing quests...")
        
        -- Сбрасываем статистику
        self.QuestStats = {
            TrashCollected = 0,
            InterfacesUsed = 0,
            TimeAdded = 0
        }
        
        -- Создаем объекты квестов
        self:CreateTrashDumpster()
        self:CreateTrash()
        self:CreateCombineInterface()
        
        -- Отправляем обновление клиентам
        if util.NetworkStringToID("GModsaken_UpdateQuestStats") ~= 0 then
            net.Start("GModsaken_UpdateQuestStats")
            net.WriteInt(self.QuestStats.TrashCollected, 32)
            net.WriteInt(self.QuestStats.InterfacesUsed, 32)
            net.WriteInt(self.QuestStats.TimeAdded, 32)
            net.Broadcast()
        end
        
        print("[GModsaken] Quests initialized successfully!")
    end
end

-- Очистка квестов в конце раунда
function GM:CleanupQuests()
    if SERVER then
        print("[GModsaken] Cleaning up quests...")
        
        -- Удаляем все объекты квестов
        for _, ent in pairs(ents.FindByClass("prop_physics")) do
            if ent:GetNWBool("IsQuestObject") then
                ent:Remove()
            end
        end
        
        print("[GModsaken] Quests cleaned up!")
    end
end

-- Получение статистики квестов
function GM:GetQuestStats()
    return self.QuestStats or {
        TrashCollected = 0,
        InterfacesUsed = 0,
        TimeAdded = 0
    }
end 