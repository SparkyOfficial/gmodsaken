--[[
    GModsaken - Spawn Menu System (Server)
    Copyright (C) 2024 GModsaken Contributors
]]

-- Ensure GM table exists
if not _G.GM then
    _G.GM = GAMEMODE or {}
    print("[GModsaken] Created GM table in sv_spawnmenu.lua")
end
local GM = _G.GM
_G.GAMEMODE = GM

print("[GModsaken] sv_spawnmenu.lua loaded")

-- Инициализация GM, если не существует
GM.SurvivorCharacters = GM.SurvivorCharacters or {}
GM.GameState = GM.GameState or "LOBBY"

-- Создаем сетевые сообщения
util.AddNetworkString("GModsaken_SpawnProp")
util.AddNetworkString("GModsaken_PropSpawned")
util.AddNetworkString("GModsaken_PropDisintegrated")
util.AddNetworkString("GModsaken_ClearProps")
util.AddNetworkString("GModsaken_UpdateCooldown")

-- Таблица для отслеживания кулдаунов игроков
local playerCooldowns = {}

-- Список созданных пропов для очистки
local spawnedProps = {}

-- Проверка кулдауна игрока
function GM:CanPlayerSpawnProp(ply)
    if not IsValid(ply) then return false end
    
    local steamID = ply:SteamID()
    local currentTime = CurTime()
    
    if not playerCooldowns[steamID] then
        return true
    end
    
    -- Кулдаун 60 секунд
    return (currentTime - playerCooldowns[steamID]) >= 60
end

-- Установка кулдауна игрока
function GM:SetPlayerPropCooldown(ply)
    if not IsValid(ply) then return end
    
    local steamID = ply:SteamID()
    playerCooldowns[steamID] = CurTime()
end

-- Получение оставшегося времени кулдауна
function GM:GetPlayerPropCooldown(ply)
    if not IsValid(ply) then return 0 end
    
    local steamID = ply:SteamID()
    local currentTime = CurTime()
    
    if not playerCooldowns[steamID] then
        return 0
    end
    
    local timeLeft = 60 - (currentTime - playerCooldowns[steamID])
    return math.max(0, timeLeft)
end

-- Спавн пропа
function GM:SpawnPlayerProp(ply, model, name)
    if not IsValid(ply) then return false, "Игрок недействителен" end
    
    -- Проверяем, что игрок выживший
    if not GM:IsSurvivor(ply) then
        return false, "Только выжившие могут создавать пропы"
    end
    
    -- Проверяем, что игра идет
    if not GM.GameState or GM.GameState ~= "PLAYING" then
        return false, "Пропы можно создавать только во время раунда"
    end
    
    -- Проверяем кулдаун
    if not GM:CanPlayerSpawnProp(ply) then
        local timeLeft = GM:GetPlayerPropCooldown(ply)
        return false, "Кулдаун: " .. math.ceil(timeLeft) .. " секунд"
    end
    
    -- Проверяем, разрешен ли проп
    if not GM:IsPropAllowed(model) then
        return false, "Этот проп не разрешен"
    end
    
    -- Получаем позицию перед игроком
    local trace = {}
    trace.start = ply:EyePos()
    trace.endpos = trace.start + ply:GetAimVector() * 200
    trace.filter = ply
    local tr = util.TraceLine(trace)
    
    if tr.Hit then
        -- Создаем проп
        local prop = ents.Create("prop_physics")
        if IsValid(prop) then
            prop:SetModel(model)
            prop:SetPos(tr.HitPos + tr.HitNormal * 10)
            prop:SetAngles(Angle(0, ply:EyeAngles().yaw, 0))
            prop:Spawn()
            
            -- Устанавливаем владельца пропа
            prop.PropOwner = ply
            prop.PropSpawnTime = CurTime()
            prop.IsQMenuProp = true -- Флаг для идентификации пропов из Q-меню
            
            -- Делаем проп не замораживаемым
            prop:SetMoveType(MOVETYPE_VPHYSICS)
            prop:SetCollisionGroup(COLLISION_GROUP_WORLD)
            
            -- Устанавливаем сетевые переменные
            prop:SetNWEntity("PropOwner", ply)
            prop:SetNWString("PropName", name)
            prop:SetNWFloat("PropSpawnTime", CurTime())
            prop:SetNWBool("IsQMenuProp", true)
            
            -- Устанавливаем кулдаун
            GM:SetPlayerPropCooldown(ply)
            
            -- Добавляем в список для очистки
            table.insert(spawnedProps, prop)
            
            print("GModsaken: Игрок " .. ply:Nick() .. " создал проп: " .. name)
            return true, "Проп создан: " .. name
        else
            return false, "Ошибка создания пропа"
        end
    else
        return false, "Нет места для пропа"
    end
end

-- Дезинтеграция пропа топором убийцы
function GM:DisintegrateProp(prop, killer)
    if not IsValid(prop) or not prop.IsQMenuProp then return end
    
    print("GModsaken: Проп дезинтегрирован убийцей " .. killer:Nick())
    
    -- Используем новые эффекты дезинтеграции
    if GM.CreateDisintegrationEffect then
        GM:CreateDisintegrationEffect(prop:GetPos(), killer)
    else
        -- Fallback эффект
        local effectdata = EffectData()
        effectdata:SetOrigin(prop:GetPos())
        effectdata:SetScale(2)
        util.Effect("cball_explode", effectdata)
        
        -- Звук дезинтеграции
        killer:EmitSound("physics/metal/metal_box_break1.wav")
    end
    
    -- Уведомляем создателя пропа
    if IsValid(prop.PropOwner) and prop.PropOwner ~= killer then
        prop.PropOwner:ChatPrint("Ваш проп был дезинтегрирован убийцей!")
    end
    
    -- Уведомляем убийцу
    killer:ChatPrint("Проп дезинтегрирован!")
    
    -- Отправляем эффект всем игрокам
    net.Start("GModsaken_PropDisintegrated")
    net.WriteEntity(prop)
    net.Broadcast()
    
    -- Удаляем проп
    prop:Remove()
    
    -- Удаляем из списка
    for i, spawnedProp in ipairs(spawnedProps) do
        if spawnedProp == prop then
            table.remove(spawnedProps, i)
            break
        end
    end
end

-- Обработка запроса на спавн пропа
net.Receive("GModsaken_SpawnProp", function(len, ply)
    if not IsValid(ply) then return end
    
    -- Проверяем, что игрок выживший
    if not GM or not GM.IsSurvivor or not GM:IsSurvivor(ply) then
        ply:ChatPrint("Только выжившие могут создавать пропы!")
        return
    end
    
    local model = net.ReadString()
    local name = net.ReadString() or (model and model:match("[^/]+$") or model) or "Неизвестный проп"
    
    -- Создаем проп
    local success, message = GM:SpawnPlayerProp(ply, model, name)
    
    -- Отправляем ответ клиенту
    net.Start("GModsaken_PropSpawned")
    net.WriteBool(success)
    net.WriteString(message)
    net.Send(ply)
    
    if success then
        ply:ChatPrint("✅ " .. message)
    else
        ply:ChatPrint("❌ " .. message)
    end
end)

-- Очистка всех пропов (админ команда)
net.Receive("GModsaken_ClearProps", function(len, ply)
    if not IsValid(ply) or not ply:IsAdmin() then return end
    
    local count = 0
    for _, prop in ipairs(spawnedProps) do
        if IsValid(prop) then
            prop:Remove()
            count = count + 1
        end
    end
    
    spawnedProps = {}
    ply:ChatPrint("Очищено пропов: " .. count)
    print("GModsaken: Админ " .. ply:Nick() .. " очистил все пропы (" .. count .. " шт.)")
end)

-- Очистка пропов в конце раунда
hook.Add("GModsaken_RoundEnd", "GModsaken_ClearPropsOnRoundEnd", function()
    local count = 0
    for _, prop in ipairs(spawnedProps) do
        if IsValid(prop) then
            prop:Remove()
            count = count + 1
        end
    end
    
    spawnedProps = {}
    print("GModsaken: Очищено пропов в конце раунда: " .. count)
end)

-- Очистка пропов при смене карты
hook.Add("ShutDown", "GModsaken_ClearPropsOnShutdown", function()
    for _, prop in ipairs(spawnedProps) do
        if IsValid(prop) then
            prop:Remove()
        end
    end
    spawnedProps = {}
end)

-- Команда для очистки пропов
concommand.Add("gmodsaken_clearprops", function(ply, cmd, args)
    if not IsValid(ply) or not ply:IsAdmin() then
        if IsValid(ply) then
            ply:ChatPrint("Только администраторы могут использовать эту команду!")
        end
        return
    end
    
    local count = 0
    for _, prop in ipairs(spawnedProps) do
        if IsValid(prop) then
            prop:Remove()
            count = count + 1
        end
    end
    
    spawnedProps = {}
    ply:ChatPrint("Очищено пропов: " .. count)
    print("GModsaken: Админ " .. ply:Nick() .. " очистил все пропы (" .. count .. " шт.)")
end)

-- Команда для получения информации о пропах
concommand.Add("gmodsaken_propsinfo", function(ply, cmd, args)
    if not IsValid(ply) then return end
    
    local count = 0
    for _, prop in ipairs(spawnedProps) do
        if IsValid(prop) then
            count = count + 1
        end
    end
    
    ply:ChatPrint("Активных пропов: " .. count)
end) 