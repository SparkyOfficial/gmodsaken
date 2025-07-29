--[[
    GModsaken - Stamina System
    Copyright (C) 2024 GModsaken Contributors
]]

-- Ensure GM table exists
if not _G.GM then
    _G.GM = {}
end
local GM = _G.GM
_G.GAMEMODE = GM

-- Система стамины
GM.StaminaSystem = {
    MaxStamina = 100,            -- Максимальная стамина для выживших
    KillerMaxStamina = 225,      -- Максимальная стамина для убийцы
    StaminaDrainRate = 0.5,      -- Уменьшено с 1.0 до 0.5
    StaminaRegenRate = 0.3,      -- Уменьшено с 0.5 до 0.3
    SprintStaminaCost = 0.8,     -- Уменьшено с 1.0 до 0.8
    JumpStaminaCost = 5,
    AttackStaminaCost = 3,
    MinStaminaForSprint = 1      -- Минимальная стамина для бега
}

-- Глобальная настройка для отключения стамины
GM.StaminaSystemEnabled = true -- Включено по умолчанию

-- Флаг для отслеживания активных сетевых сообщений
local isNetworkMessageActive = false

-- Сообщение при загрузке
print("[GModsaken] Stamina system loaded (enabled by default)")
print("[GModsaken] Use 'gmodsaken_disable_stamina' to disable the stamina system")

-- Инициализация стамины для игрока
function GM:InitializeStamina(ply)
    if not IsValid(ply) then return end
    
    -- Устанавливаем стамину в зависимости от команды
    if self:IsKiller(ply) then
        ply.Stamina = self.StaminaSystem.KillerMaxStamina
        ply.MaxStamina = self.StaminaSystem.KillerMaxStamina
    else
        ply.Stamina = self.StaminaSystem.MaxStamina
        ply.MaxStamina = self.StaminaSystem.MaxStamina
    end
    
    ply.IsSprinting = false
    ply.LastStaminaUpdate = CurTime()
    
    if SERVER then
        ply:SetNWFloat("Stamina", ply.Stamina)
        ply:SetNWBool("IsSprinting", false)
    end
    
    print("GModsaken: Стамина инициализирована для " .. ply:Nick() .. " (" .. ply.Stamina .. ")")
    
    -- Синхронизируем с клиентом
    timer.Simple(0.1, function()
        if IsValid(ply) then
            self:UpdateStamina(ply)
        end
    end)
end

-- Обновление стамины
function GM:UpdateStamina(ply)
    if not IsValid(ply) then return end
    if not ply.Stamina then
        self:InitializeStamina(ply)
        return
    end
    
    local currentTime = CurTime()
    local deltaTime = currentTime - (ply.LastStaminaUpdate or currentTime)
    ply.LastStaminaUpdate = currentTime
    
    -- Определяем максимальную стамину
    local maxStamina = self:IsKiller(ply) and self.StaminaSystem.KillerMaxStamina or self.StaminaSystem.MaxStamina
    
    -- Восстановление стамины
    if not ply.IsSprinting then
        ply.Stamina = math.min(ply.Stamina + (self.StaminaSystem.StaminaRegenRate * deltaTime * 60), maxStamina)
    end
    
    -- Обновляем сетевые переменные
    if SERVER then
        ply:SetNWFloat("Stamina", ply.Stamina)
    end
end

-- Проверка возможности бега
function GM:CanPlayerSprint(ply)
    if not IsValid(ply) then return false end
    if not ply.Stamina then return false end
    
    return ply.Stamina > self.StaminaSystem.MinStaminaForSprint
end

-- Начало бега
function GM:StartSprint(ply)
    if not IsValid(ply) then return end
    if not self:CanPlayerSprint(ply) then return end
    
    ply.IsSprinting = true
    ply:SetRunSpeed(ply:GetRunSpeed() * 1.2) -- Увеличиваем скорость бега
    
    if SERVER then
        ply:SetNWBool("IsSprinting", true)
    end
end

-- Остановка бега
function GM:StopSprint(ply)
    if not IsValid(ply) then return end
    
    ply.IsSprinting = false
    ply:SetRunSpeed(400) -- Возвращаем нормальную скорость
    
    if SERVER then
        ply:SetNWBool("IsSprinting", false)
    end
end

-- Трата стамины при беге
function GM:DrainStaminaFromSprint(ply)
    if not IsValid(ply) then return end
    if not ply.IsSprinting then return end
    if not self:CanPlayerSprint(ply) then
        self:StopSprint(ply)
        return
    end
    
    ply.Stamina = math.max(ply.Stamina - (self.StaminaSystem.SprintStaminaCost * 0.016), 0) -- 0.016 = 60 FPS
    
    if SERVER then
        ply:SetNWFloat("Stamina", ply.Stamina)
    end
    
    -- Останавливаем бег если стамина закончилась
    if ply.Stamina <= self.StaminaSystem.MinStaminaForSprint then
        self:StopSprint(ply)
    end
end

-- Трата стамины при прыжке
function GM:DrainStaminaFromJump(ply)
    if not IsValid(ply) then return end
    if not ply.Stamina then return end
    
    ply.Stamina = math.max(ply.Stamina - self.StaminaSystem.JumpStaminaCost, 0)
    
    if SERVER then
        ply:SetNWFloat("Stamina", ply.Stamina)
    end
end

-- Трата стамины при атаке
function GM:DrainStaminaFromAttack(ply)
    if not IsValid(ply) then return end
    if not ply.Stamina then return end
    
    ply.Stamina = math.max(ply.Stamina - self.StaminaSystem.AttackStaminaCost, 0)
    
    if SERVER then
        ply:SetNWFloat("Stamina", ply.Stamina)
    end
end

-- Получение информации о стамине для HUD
function GM:GetStaminaInfo(ply)
    if not IsValid(ply) then return { stamina = 0, maxStamina = 100, percentage = 0 } end
    
    local stamina = ply:GetNWFloat("Stamina", 100)
    local maxStamina = self.StaminaSystem.MaxStamina
    local percentage = (stamina / maxStamina) * 100
    
    return {
        stamina = stamina,
        maxStamina = maxStamina,
        percentage = percentage
    }
end

-- Хук для обработки движения
hook.Add("Move", "GModsaken_StaminaMovement", function(ply, moveData)
    if not IsValid(ply) then return end
    if not GM.UpdateStamina then return end
    
    -- Обновляем стамину
    GM:UpdateStamina(ply)
    
    -- Проверяем бег
    if moveData:KeyDown(IN_SPEED) and GM:CanPlayerSprint(ply) then
        if not ply.IsSprinting then
            GM:StartSprint(ply)
        end
        GM:DrainStaminaFromSprint(ply)
    else
        if ply.IsSprinting then
            GM:StopSprint(ply)
        end
    end
    
    -- Ограничиваем бег при недостатке стамины
    if ply.IsSprinting and not GM:CanPlayerSprint(ply) then
        GM:StopSprint(ply)
    end
end)

-- Хук для обработки прыжков
hook.Add("OnPlayerJump", "GModsaken_StaminaJump", function(ply)
    if not IsValid(ply) then return end
    if not GM.DrainStaminaFromJump then return end
    
    GM:DrainStaminaFromJump(ply)
end)

-- Использование стамины
function GM:UseStamina(ply, amount)
    if not IsValid(ply) then return false end
    if not self.StaminaSystemEnabled then return true end
    
    ply.Stamina = ply.Stamina or ply.MaxStamina or 100
    ply.MaxStamina = ply.MaxStamina or 100
    
    if ply.Stamina >= amount then
        ply.Stamina = ply.Stamina - amount
        self:UpdateStamina(ply)
        return true
    end
    
    return false
end

-- Восстановление стамины
function GM:RestoreStamina(ply, amount)
    if not IsValid(ply) then return end
    if not self.StaminaSystemEnabled then return end
    
    ply.Stamina = ply.Stamina or 0
    ply.MaxStamina = ply.MaxStamina or 100
    
    local oldStamina = ply.Stamina
    ply.Stamina = math.min(ply.Stamina + amount, ply.MaxStamina)
    
    -- Обновляем только если стамина изменилась
    if ply.Stamina ~= oldStamina then
        -- Используем таймер для отложенной отправки, чтобы избежать конфликтов
        timer.Simple(0.1, function()
            if IsValid(ply) then
                self:UpdateStamina(ply)
            end
        end)
    end
end

-- Проверка, может ли игрок атаковать
function GM:CanPlayerAttack(ply)
    if not IsValid(ply) then return false end
    if not self.StaminaSystemEnabled then return true end
    
    ply.Stamina = ply.Stamina or 0
    return ply.Stamina > 0
end

-- Получение стамины игрока
function GM:GetPlayerStamina(ply)
    if not IsValid(ply) then return 0 end
    return ply.Stamina or 0
end

-- Получение максимальной стамины игрока
function GM:GetPlayerMaxStamina(ply)
    if not IsValid(ply) then return 100 end
    return ply.MaxStamina or 100
end

-- Хук для обработки атак
hook.Add("PlayerCanAttack", "GModsaken_AttackStamina", function(ply)
    if not IsValid(ply) then return false end
    if not GM or not GM.StaminaSystemEnabled then return true end
    
    -- Проверяем, инициализирован ли GM
    if not GM.CanPlayerAttack then return true end
    
    -- Проверяем стамину для атаки
    if not GM:CanPlayerAttack(ply) then
        return false
    end
    
    -- Тратим стамину при атаке
    local attackCost = 15 -- Стоимость атаки
    if not GM:UseStamina(ply, attackCost) then
        return false
    end
    
    return true
end)

-- Хук для инициализации стамины при спавне
hook.Add("PlayerSpawn", "GModsaken_StaminaSpawn", function(ply)
    timer.Simple(0.1, function()
        if IsValid(ply) and GM and GM.InitializeStamina and GM.StaminaSystemEnabled then
            GM:InitializeStamina(ply)
        end
    end)
end)

-- Команда для проверки стамины
concommand.Add("gmodsaken_stamina", function(ply, cmd, args)
    if not IsValid(ply) then return end
    
    if not GM or not GM.GetPlayerStamina then
        ply:ChatPrint("Система стамины не инициализирована!")
        return
    end
    
    local stamina = GM:GetPlayerStamina(ply)
    local maxStamina = GM:GetPlayerMaxStamina(ply)
    
    ply:ChatPrint("Стамина: " .. stamina .. "/" .. maxStamina)
end)

-- Команда для отключения/включения стамины (индивидуальная)
concommand.Add("gmodsaken_toggle_stamina", function(ply, cmd, args)
    if not IsValid(ply) then return end
    
    if not GM then
        ply:ChatPrint("GM не инициализирован!")
        return
    end
    
    ply.StaminaEnabled = not ply.StaminaEnabled
    
    if ply.StaminaEnabled then
        ply:ChatPrint("Система стамины включена")
        if GM.InitializeStamina then
            GM:InitializeStamina(ply)
        end
    else
        ply:ChatPrint("Система стамины отключена")
    end
end)

-- Команда для глобального отключения/включения стамины (только для админов)
concommand.Add("gmodsaken_global_stamina", function(ply, cmd, args)
    if IsValid(ply) and not ply:IsSuperAdmin() then
        ply:ChatPrint("Только суперадмины могут управлять глобальными настройками!")
        return
    end
    
    if not GM then
        if IsValid(ply) then
            ply:ChatPrint("GM не инициализирован!")
        end
        return
    end
    
    GM.StaminaSystemEnabled = not GM.StaminaSystemEnabled
    
    local status = GM.StaminaSystemEnabled and "включена" or "отключена"
    
    if IsValid(ply) then
        ply:ChatPrint("Глобальная система стамины " .. status)
    end
    print("[GModsaken] Global stamina system " .. status)
    
    -- Уведомляем всех игроков
    for _, player in pairs(player.GetAll()) do
        player:ChatPrint("[СИСТЕМА] Стамина " .. status)
    end
end)

-- Команда для быстрого отключения стамины (для отладки)
concommand.Add("gmodsaken_disable_stamina", function(ply, cmd, args)
    if not GM then
        if IsValid(ply) then
            ply:ChatPrint("GM не инициализирован!")
        end
        return
    end
    
    GM.StaminaSystemEnabled = false
    
    if IsValid(ply) then
        ply:ChatPrint("Система стамины отключена!")
    end
    print("[GModsaken] Stamina system disabled for debugging")
    
    -- Уведомляем всех игроков
    for _, player in pairs(player.GetAll()) do
        player:ChatPrint("[СИСТЕМА] Стамина отключена для отладки")
    end
end)

-- Команда для быстрого включения стамины
concommand.Add("gmodsaken_enable_stamina", function(ply, cmd, args)
    if not GM then
        if IsValid(ply) then
            ply:ChatPrint("GM не инициализирован!")
        end
        return
    end
    
    GM.StaminaSystemEnabled = true
    
    if IsValid(ply) then
        ply:ChatPrint("Система стамины включена!")
    end
    print("[GModsaken] Stamina system enabled")
    
    -- Уведомляем всех игроков
    for _, player in pairs(player.GetAll()) do
        player:ChatPrint("[СИСТЕМА] Стамина включена")
    end
end)

-- Функция замедления игрока
function GM:SlowPlayer(ply, duration, multiplier)
    if not IsValid(ply) then return end
    
    -- Сохраняем оригинальную скорость
    if not ply.OriginalSpeed then
        ply.OriginalSpeed = {
            walk = ply:GetWalkSpeed(),
            run = ply:GetRunSpeed()
        }
    end
    
    -- Применяем замедление
    ply:SetWalkSpeed(ply.OriginalSpeed.walk * multiplier)
    ply:SetRunSpeed(ply.OriginalSpeed.run * multiplier)
    
    -- Восстанавливаем скорость через указанное время
    timer.Simple(duration, function()
        if IsValid(ply) and ply.OriginalSpeed then
            ply:SetWalkSpeed(ply.OriginalSpeed.walk)
            ply:SetRunSpeed(ply.OriginalSpeed.run)
        end
    end)
end 