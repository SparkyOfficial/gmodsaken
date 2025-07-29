--[[
    GModsaken - Prop System (Server)
    Copyright (C) 2024 GModsaken Contributors
]]

-- Ensure GM table exists
if not _G.GM then
    _G.GM = GAMEMODE or {}
    print("[GModsaken] Created GM table in sv_prop_system.lua")
end
local GM = _G.GM
_G.GAMEMODE = GM

print("[GModsaken] sv_prop_system.lua loaded")

-- Создаем сетевое сообщение
util.AddNetworkString("GModsaken_SpawnProp")
util.AddNetworkString("GModsaken_PropSpawned")

-- Таблица для отслеживания кулдаунов игроков
local playerCooldowns = {}

-- Разрешенные пропы для выживших
local allowedProps = {
    "models/props_junk/wooden_box01a.mdl",
    "models/props_junk/wooden_box02a.mdl", 
    "models/props_junk/wooden_box03a.mdl",
    "models/props_junk/wooden_box04a.mdl",
    "models/props_junk/wooden_box05a.mdl"
}

-- Список созданных пропов для очистки
local spawnedProps = {}

-- Проверка, разрешен ли проп
local function IsPropAllowed(model)
    for _, allowedModel in pairs(allowedProps) do
        if allowedModel == model then
            return true
        end
    end
    return false
end

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
    if not IsPropAllowed(model) then
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
            
            -- Делаем проп не замораживаемым
            prop:SetMoveType(MOVETYPE_VPHYSICS)
            prop:SetCollisionGroup(COLLISION_GROUP_WORLD)
            
            -- Устанавливаем сетевые переменные
            prop:SetNWEntity("PropOwner", ply)
            prop:SetNWString("PropName", name)
            prop:SetNWFloat("PropSpawnTime", CurTime())
            
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

-- Обработка запроса на спавн пропа
net.Receive("GModsaken_SpawnProp", function(len, ply)
    if not IsValid(ply) then return end
    
    -- Проверяем, что игрок выживший
    if not GM or not GM.IsSurvivor or not GM:IsSurvivor(ply) then
        ply:ChatPrint("Только выжившие могут создавать пропы!")
        return
    end
    
    -- Проверяем кулдаун
    if ply.LastPropSpawn and CurTime() - ply.LastPropSpawn < 60 then
        local timeLeft = 60 - (CurTime() - ply.LastPropSpawn)
        ply:ChatPrint("Подождите " .. math.ceil(timeLeft) .. " секунд перед следующим спавном!")
        return
    end
    
    local model = net.ReadString()
    
    -- Проверяем, разрешен ли проп
    if not IsPropAllowed(model) then
        ply:ChatPrint("Этот проп не разрешен!")
        return
    end
    
    -- Создаем проп перед игроком
    local trace = ply:GetEyeTrace()
    local spawnPos = trace.HitPos + trace.HitNormal * 10
    
    local success, message = GM:SpawnPlayerProp(ply, model, model)
    
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
    for _, prop in pairs(spawnedProps) do
        if IsValid(prop) then
            prop:Remove()
            count = count + 1
        end
    end
    
    spawnedProps = {}
    ply:ChatPrint("Удалено " .. count .. " пропов!")
    print("GModsaken: Админ " .. ply:Nick() .. " удалил " .. count .. " пропов")
end)

-- Команда для очистки пропов
concommand.Add("gmodsaken_clear_props", function(ply, cmd, args)
    if not IsValid(ply) or not ply:IsAdmin() then return end
    
    local count = 0
    for _, prop in pairs(spawnedProps) do
        if IsValid(prop) then
            prop:Remove()
            count = count + 1
        end
    end
    
    spawnedProps = {}
    ply:ChatPrint("Удалено " .. count .. " пропов!")
    print("GModsaken: Админ " .. ply:Nick() .. " удалил " .. count .. " пропов через команду")
end)

-- Очистка пропов при окончании раунда
hook.Add("GModsaken_RoundEnd", "GModsaken_ClearPropsOnRoundEnd", function()
    for _, prop in pairs(spawnedProps) do
        if IsValid(prop) then
            prop:Remove()
        end
    end
    
    spawnedProps = {}
    print("GModsaken: Все пропы очищены при окончании раунда")
end)

-- Разрушение пропов топором убийцы
hook.Add("EntityTakeDamage", "GModsaken_DestroyPropsWithAxe", function(target, dmginfo)
    if not IsValid(target) or not IsValid(dmginfo:GetAttacker()) then return end
    
    local attacker = dmginfo:GetAttacker()
    local weapon = attacker:GetActiveWeapon()
    
    -- Проверяем, что это проп и атакует убийца топором
    if target:GetClass() == "prop_physics" and 
       target:GetNWBool("GModsaken_Unfreezable") and
       GM and GM.IsKiller and GM:IsKiller(attacker) and
       IsValid(weapon) and weapon:GetClass() == "weapon_gmodsaken_axe" then
        
        -- Увеличиваем урон
        dmginfo:SetDamage(dmginfo:GetDamage() * 2)
        
        -- Удаляем из списка
        for i, prop in pairs(spawnedProps) do
            if prop == target then
                table.remove(spawnedProps, i)
                break
            end
        end
        
        attacker:ChatPrint("Проп разрушен!")
        print("GModsaken: Убийца " .. attacker:Nick() .. " разрушил проп")
    end
end)

-- Команды для администраторов

-- Очистка всех пропов
concommand.Add("gmodsaken_clear_all_props", function(ply, cmd, args)
    if IsValid(ply) and not ply:IsAdmin() then
        ply:ChatPrint("Только администраторы могут использовать эту команду!")
        return
    end
    
    local propCount = 0
    
    for _, ent in pairs(ents.FindByClass("prop_physics")) do
        if ent.PropOwner then
            ent:Remove()
            propCount = propCount + 1
        end
    end
    
    local message = "Очищено " .. propCount .. " пропов"
    if IsValid(ply) then
        ply:ChatPrint("✅ " .. message)
    end
    print("GModsaken: " .. message .. " администратором " .. (IsValid(ply) and ply:Nick() or "консоль"))
end)

-- Спавн тестового пропа
concommand.Add("gmodsaken_spawn_test_prop", function(ply, cmd, args)
    if IsValid(ply) and not ply:IsAdmin() then
        ply:ChatPrint("Только администраторы могут использовать эту команду!")
        return
    end
    
    if not IsValid(ply) then
        print("GModsaken: Команда доступна только для игроков")
        return
    end
    
    local success, message = GM:SpawnPlayerProp(ply, "models/props_junk/wooden_box01a.mdl", "Тестовый проп")
    
    if success then
        ply:ChatPrint("✅ " .. message)
    else
        ply:ChatPrint("❌ " .. message)
    end
end)

-- Информация о пропах
concommand.Add("gmodsaken_prop_info", function(ply, cmd, args)
    if IsValid(ply) and not ply:IsAdmin() then
        ply:ChatPrint("Только администраторы могут использовать эту команду!")
        return
    end
    
    local propCount = 0
    local playerProps = {}
    
    for _, ent in pairs(ents.FindByClass("prop_physics")) do
        if ent.PropOwner then
            propCount = propCount + 1
            local ownerName = IsValid(ent.PropOwner) and ent.PropOwner:Nick() or "Неизвестно"
            playerProps[ownerName] = (playerProps[ownerName] or 0) + 1
        end
    end
    
    local message = "Всего пропов: " .. propCount
    if IsValid(ply) then
        ply:ChatPrint("📊 " .. message)
        for playerName, count in pairs(playerProps) do
            ply:ChatPrint("  " .. playerName .. ": " .. count .. " пропов")
        end
    end
    print("GModsaken: " .. message)
end)

-- Перезагрузка меню пропов
concommand.Add("gmodsaken_reload_prop_menu", function(ply, cmd, args)
    if IsValid(ply) and not ply:IsAdmin() then
        ply:ChatPrint("Только администраторы могут использовать эту команду!")
        return
    end
    
    -- Очищаем кулдауны
    playerCooldowns = {}
    
    local message = "Q-меню пропов перезагружено"
    if IsValid(ply) then
        ply:ChatPrint("🔄 " .. message)
    end
    print("GModsaken: " .. message .. " администратором " .. (IsValid(ply) and ply:Nick() or "консоль"))
end)

-- Команда для проверки кулдауна
concommand.Add("gmodsaken_prop_cooldown", function(ply, cmd, args)
    if not IsValid(ply) then return end
    
    if not GM:IsSurvivor(ply) then
        ply:ChatPrint("Только выжившие могут использовать пропы!")
        return
    end
    
    local timeLeft = GM:GetPlayerPropCooldown(ply)
    
    if timeLeft > 0 then
        ply:ChatPrint("⏰ Кулдаун пропов: " .. math.ceil(timeLeft) .. " секунд")
    else
        ply:ChatPrint("✅ Можете создать проп!")
    end
end)

print("GModsaken: Система пропов загружена!") 