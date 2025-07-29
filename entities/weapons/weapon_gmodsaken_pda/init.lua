--[[
    GModsaken - Engineer's PDA Weapon
    Copyright (C) 2024 GModsaken Contributors
]]

AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

SWEP.PrintName = "КПК Инженера"
SWEP.Author = "GModsaken"
SWEP.Instructions = "ЛКМ - Построить турель\nПКМ - Построить раздатчик\nR - Меню построек"
SWEP.Category = "GModsaken"

SWEP.Spawnable = true
SWEP.AdminSpawnable = true

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "none"

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"

SWEP.Weight = 5
SWEP.AutoSwitchTo = false
SWEP.AutoSwitchFrom = false

SWEP.Slot = 1
SWEP.SlotPos = 3
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = true

-- Модель и звуки (TF2 PDA)
SWEP.ViewModel = "models/weapons/v_models/v_pda_engineer.mdl"
SWEP.WorldModel = "models/weapons/w_models/w_pda_engineer.mdl"
SWEP.UseHands = true

-- Звуки
SWEP.Primary.Sound = Sound("weapons/pda/pda_click.wav")
SWEP.Secondary.Sound = Sound("weapons/pda/pda_click.wav")
SWEP.BuildSound = Sound("weapons/physcannon/energy_sing_explosion2.wav")

-- Способности
SWEP.TurretCooldown = 30 -- секунды
SWEP.DispenserCooldown = 45 -- секунды
SWEP.LastTurret = 0
SWEP.LastDispenser = 0

function SWEP:Initialize()
    self:SetHoldType("normal")
end

function SWEP:SetupDataTables()
    self:NetworkVar("Bool", 0, "TurretReady")
    self:NetworkVar("Bool", 1, "DispenserReady")
    self:NetworkVar("Bool", 2, "IsBuilding")
end

-- Функция для установки правильной модели рук
function SWEP:SetViewModelArms(ply)
    if not IsValid(ply) then return end
    
    local characterName = ply.SelectedCharacter or "default"
    local armsModel = self.ViewModelArms[characterName] or self.ViewModelArms["default"]
    
    if armsModel then
        self.ViewModelArmsModel = armsModel
        if CLIENT then
            self:SetViewModelArmsModel(armsModel)
        end
    end
end

function SWEP:PrimaryAttack()
    if not IsFirstTimePredicted() then return end
    
    local owner = self:GetOwner()
    if not IsValid(owner) then return end
    
    if CurTime() < self:GetNextPrimaryFire() then return end
    
    -- Проверяем задержку турели
    if CurTime() < self.LastTurret + self.TurretCooldown then
        local remainingTime = math.ceil(self.LastTurret + self.TurretCooldown - CurTime())
        owner:ChatPrint("Турель будет готова через " .. remainingTime .. " секунд!")
        return
    end
    
    -- Проверяем лимит турелей
    local turretCount = 0
    for _, ent in pairs(ents.FindByClass("npc_turret_floor")) do
        if IsValid(ent) and ent.Owner == owner and ent.IsGModsakenTurret then
            turretCount = turretCount + 1
        end
    end
    
    if turretCount >= (self.MaxTurrets or 1) then
        owner:ChatPrint("Достигнут лимит турелей! Максимум: " .. (self.MaxTurrets or 1))
        return
    end
    
    -- Строим турель
    local tr = util.TraceLine({
        start = owner:GetShootPos(),
        endpos = owner:GetShootPos() + owner:GetAimVector() * (self.BuildRange or 200),
        filter = owner
    })
    
    if tr.Hit then
        local turret = ents.Create("npc_turret_floor")
        if IsValid(turret) then
            turret:SetPos(tr.HitPos + tr.HitNormal * 10)
            turret:SetAngles(Angle(0, owner:EyeAngles().yaw, 0))
            turret:Spawn()
            
            -- Помечаем владельца
            turret.Owner = owner
            
            -- Настраиваем турель
            turret:SetKeyValue("spawnflags", "32") -- Не стреляет в игроков по умолчанию
            turret:SetKeyValue("health", "100")
            
            -- Делаем турель разрушимой
            turret:SetMaxHealth(100)
            turret:SetHealth(100)
            
            -- Добавляем кастомную логику для стрельбы только по убийцам
            turret.IsGModsakenTurret = true
            turret.TargetKillers = true
            turret.SlowdownEffect = true
            
            -- Обновляем время последней постройки
            self.LastTurret = CurTime()
            
            owner:ChatPrint("Турель построена! Следующая будет готова через " .. self.TurretCooldown .. " секунд.")
        end
    end
    
    self:SetNextPrimaryFire(CurTime() + (self.Primary.Delay or 1.0))
end

function SWEP:SecondaryAttack()
    if not IsFirstTimePredicted() then return end
    
    local owner = self:GetOwner()
    if not IsValid(owner) then return end
    
    if CurTime() < self:GetNextSecondaryFire() then return end
    
    -- Проверяем задержку раздатчика
    if CurTime() < self.LastDispenser + self.DispenserCooldown then
        local remainingTime = math.ceil(self.LastDispenser + self.DispenserCooldown - CurTime())
        owner:ChatPrint("Раздатчик будет готов через " .. remainingTime .. " секунд!")
        return
    end
    
    -- Проверяем лимит раздатчиков
    local dispenserCount = 0
    for _, ent in pairs(ents.FindByClass("npc_turret_ceiling")) do -- Используем потолочную турель как раздатчик
        if IsValid(ent) and ent.Owner == owner and ent.IsGModsakenDispenser then
            dispenserCount = dispenserCount + 1
        end
    end
    
    if dispenserCount >= (self.MaxDispensers or 1) then
        owner:ChatPrint("Достигнут лимит раздатчиков! Максимум: " .. (self.MaxDispensers or 1))
        return
    end
    
    -- Строим раздатчик
    local tr = util.TraceLine({
        start = owner:GetShootPos(),
        endpos = owner:GetShootPos() + owner:GetAimVector() * (self.BuildRange or 200),
        filter = owner
    })
    
    if tr.Hit then
        local dispenser = ents.Create("npc_turret_ceiling") -- Потолочная турель как раздатчик
        if IsValid(dispenser) then
            dispenser:SetPos(tr.HitPos + tr.HitNormal * 10)
            dispenser:SetAngles(Angle(0, owner:EyeAngles().yaw, 0))
            dispenser:Spawn()
            
            -- Настраиваем раздатчик
            dispenser.Owner = owner
            dispenser.IsGModsakenDispenser = true
            dispenser.LastHealTime = 0
            
            -- Делаем раздатчик зеленым для отличия
            dispenser:SetColor(Color(0, 255, 0, 255))
            
            -- Обновляем время последней постройки
            self.LastDispenser = CurTime()
            
            owner:ChatPrint("Раздатчик построен! Следующий будет готов через " .. self.DispenserCooldown .. " секунд.")
        end
    end
    
    self:SetNextSecondaryFire(CurTime() + (self.Secondary.Delay or 1.0))
end

function SWEP:Reload()
    if not IsFirstTimePredicted() then return end
    
    local owner = self:GetOwner()
    if not IsValid(owner) then return end
    
    -- Удаляем последнюю постройку (турель или раздатчик)
    local lastEnt = nil
    local lastTime = 0
    
    -- Ищем последнюю турель
    for _, ent in pairs(ents.FindByClass("npc_turret_floor")) do
        if IsValid(ent) and ent.Owner == owner and ent.IsGModsakenTurret then
            if not lastEnt or ent:GetCreationTime() > lastTime then
                lastEnt = ent
                lastTime = ent:GetCreationTime()
            end
        end
    end
    
    -- Ищем последний раздатчик
    for _, ent in pairs(ents.FindByClass("prop_physics")) do
        if IsValid(ent) and ent.Owner == owner and ent.IsDispenser then
            if not lastEnt or ent:GetCreationTime() > lastTime then
                lastEnt = ent
                lastTime = ent:GetCreationTime()
            end
        end
    end
    
    if IsValid(lastEnt) then
        local entType = "постройка"
        if lastEnt.IsGModsakenTurret then
            entType = "турель"
        elseif lastEnt.IsDispenser then
            entType = "раздатчик"
        end
        
        lastEnt:Remove()
        owner:ChatPrint("Последняя " .. entType .. " удалена!")
    else
        owner:ChatPrint("Нет построек для удаления!")
    end
end

function SWEP:BuildTurret(owner)
    if SERVER then
        local tr = owner:GetEyeTrace()
        local buildPos = tr.HitPos + tr.HitNormal * 10
        
        -- Создаем турель
        local turret = ents.Create("npc_turret_floor")
        if IsValid(turret) then
            turret:SetPos(buildPos)
            turret:SetAngles(Angle(0, owner:EyeAngles().yaw, 0))
            turret:Spawn()
            
            -- Помечаем владельца
            turret.Owner = owner
            
            -- Настраиваем турель
            turret:SetKeyValue("spawnflags", "32") -- Не стреляет в игроков по умолчанию
            turret:SetKeyValue("health", "100")
            
            -- Делаем турель разрушимой
            turret:SetMaxHealth(100)
            turret:SetHealth(100)
            
            -- Добавляем кастомную логику для стрельбы только по убийцам
            turret.IsGModsakenTurret = true
            turret.TargetKillers = true
            turret.SlowdownEffect = true
            
            -- Хук для кастомной логики стрельбы
            hook.Add("Think", "GModsaken_TurretLogic_" .. turret:EntIndex(), function()
                if not IsValid(turret) or not turret.IsGModsakenTurret then
                    hook.Remove("Think", "GModsaken_TurretLogic_" .. turret:EntIndex())
                    return
                end
                
                -- Проверяем кулдаун стрельбы
                if turret.LastShootTime and (CurTime() - turret.LastShootTime) < 2 then
                    return
                end
                
                -- Ищем только убийц в радиусе
                local killers = {}
                for _, ply in pairs(player.GetAll()) do
                    if IsValid(ply) and ply:Team() == GAMEMODE.TEAM_KILLER and ply:Alive() then
                        local distance = turret:GetPos():Distance(ply:GetPos())
                        if distance <= 500 then -- Радиус действия турели
                            table.insert(killers, ply)
                        end
                    end
                end
                
                -- Если есть убийцы, стреляем и замедляем
                if #killers > 0 then
                    local target = killers[1] -- Берем первого убийцу
                    
                    -- Наносим урон
                    local oldHealth = target:Health()
                    local damage = 10
                    local newHealth = math.max(0, oldHealth - damage)
                    target:SetHealth(newHealth)
                    
                    print("GModsaken: Турель наносит " .. damage .. " урона " .. target:Nick() .. " (было: " .. oldHealth .. ", стало: " .. newHealth .. ")")
                    
                    -- Проверяем смерть
                    if newHealth <= 0 then
                        target:Kill()
                        print("GModsaken: " .. target:Nick() .. " убит турелью!")
                    end
                    
                    -- Замедляем убийцу
                    if not target.OriginalSpeed then
                        target.OriginalSpeed = {
                            walk = target:GetWalkSpeed(),
                            run = target:GetRunSpeed()
                        }
                    end
                    
                    target:SetWalkSpeed(target.OriginalSpeed.walk * 0.8)
                    target:SetRunSpeed(target.OriginalSpeed.run * 0.8)
                    
                    -- Отменяем предыдущий таймер восстановления скорости
                    if target.SlowdownTimer then
                        timer.Remove(target.SlowdownTimer)
                    end
                    
                    -- Создаем уникальный таймер для этого игрока
                    local timerName = "GModsaken_Slowdown_" .. target:EntIndex() .. "_" .. CurTime()
                    target.SlowdownTimer = timerName
                    
                    -- Восстанавливаем скорость через 3 секунды
                    timer.Simple(3, function()
                        if IsValid(target) and target.OriginalSpeed and target.SlowdownTimer == timerName then
                            target:SetWalkSpeed(target.OriginalSpeed.walk)
                            target:SetRunSpeed(target.OriginalSpeed.run)
                            target.SlowdownTimer = nil
                            target:ChatPrint("Замедление от турели закончилось!")
                        end
                    end)
                    
                    -- Звук выстрела
                    turret:EmitSound("weapons/turret/turret_fire1.wav")
                    
                    -- Эффект попадания
                    target:ChatPrint("Вы поражены турелью! Замедление на 3 секунды.")
                    
                    -- Устанавливаем кулдаун
                    turret.LastShootTime = CurTime()
                end
            end)
            
            -- Хук для разрушения турели убийцей
            hook.Add("EntityTakeDamage", "GModsaken_TurretDamage_" .. turret:EntIndex(), function(target, dmginfo)
                if target == turret and IsValid(dmginfo:GetAttacker()) and dmginfo:GetAttacker():IsPlayer() then
                    local attacker = dmginfo:GetAttacker()
                    if attacker:Team() == GAMEMODE.TEAM_KILLER then
                        -- Убийца может разрушить турель
                        dmginfo:SetDamage(dmginfo:GetDamage() * 2) -- Двойной урон от убийцы
                        
                        if turret:Health() <= 0 then
                            attacker:ChatPrint("Турель разрушена!")
                            -- Удаляем хуки
                            hook.Remove("Think", "GModsaken_TurretLogic_" .. turret:EntIndex())
                            hook.Remove("EntityTakeDamage", "GModsaken_TurretDamage_" .. turret:EntIndex())
                        end
                    else
                        -- Выжившие не могут повредить турель
                        dmginfo:SetDamage(0)
                    end
                end
            end)
            
            -- Удаляем через 5 минут
            timer.Simple(300, function()
                if IsValid(turret) then
                    hook.Remove("Think", "GModsaken_TurretLogic_" .. turret:EntIndex())
                    hook.Remove("EntityTakeDamage", "GModsaken_TurretDamage_" .. turret:EntIndex())
                    turret:Remove()
                end
            end)
            
            -- Уведомляем всех игроков
            for _, ply in pairs(player.GetAll()) do
                if ply:Team() == GAMEMODE.TEAM_SURVIVOR then
                    ply:ChatPrint("Инженер построил турель! Она стреляет только по убийцам.")
                elseif ply:Team() == GAMEMODE.TEAM_KILLER then
                    ply:ChatPrint("Инженер построил турель! Вы можете её разрушить.")
                end
            end
        end
    end
end

function SWEP:BuildDispenser(owner)
    if SERVER then
        local tr = owner:GetEyeTrace()
        local buildPos = tr.HitPos + tr.HitNormal * 10
        
        -- Создаем раздатчик (используем prop_physics как заменитель)
        local dispenser = ents.Create("prop_physics")
        if IsValid(dispenser) then
            dispenser:SetModel("models/props_lab/reciever01a.mdl")
            dispenser:SetPos(buildPos)
            dispenser:SetAngles(Angle(0, owner:EyeAngles().yaw, 0))
            dispenser:Spawn()
            
            -- Помечаем владельца
            dispenser.Owner = owner
            
            -- Делаем раздатчик разрушимым
            dispenser:SetKeyValue("spawnflags", "256")
            dispenser:SetHealth(150)
            dispenser:SetMaxHealth(150)
            
            -- Добавляем функцию лечения
            dispenser.IsDispenser = true
            dispenser.HealRadius = 100
            dispenser.HealAmount = 10
            dispenser.LastHeal = 0
            
            -- Хук для лечения
            hook.Add("Think", "GModsaken_DispenserLogic_" .. dispenser:EntIndex(), function()
                if not IsValid(dispenser) or not dispenser.IsDispenser then
                    hook.Remove("Think", "GModsaken_DispenserLogic_" .. dispenser:EntIndex())
                    return
                end
                
                -- Лечим выживших в радиусе
                for _, ply in pairs(player.GetAll()) do
                    if ply:Team() == GAMEMODE.TEAM_SURVIVOR and ply:Alive() then
                        local distance = dispenser:GetPos():Distance(ply:GetPos())
                        if distance <= dispenser.HealRadius then
                            -- Лечим здоровье
                            local currentHealth = ply:Health()
                            local maxHealth = ply:GetMaxHealth()
                            if currentHealth < maxHealth then
                                ply:SetHealth(math.min(currentHealth + 2, maxHealth))
                            end
                            
                            -- Добавляем броню
                            local currentArmor = ply:Armor()
                            if currentArmor < 100 then
                                ply:SetArmor(math.min(currentArmor + 1, 100))
                            end
                        end
                    end
                end
            end)
            
            -- Хук для разрушения раздатчика убийцей
            hook.Add("EntityTakeDamage", "GModsaken_DispenserDamage_" .. dispenser:EntIndex(), function(target, dmginfo)
                if target == dispenser and IsValid(dmginfo:GetAttacker()) and dmginfo:GetAttacker():IsPlayer() then
                    local attacker = dmginfo:GetAttacker()
                    if attacker:Team() == GAMEMODE.TEAM_KILLER then
                        -- Убийца может разрушить раздатчик
                        dmginfo:SetDamage(dmginfo:GetDamage() * 2) -- Двойной урон от убийцы
                        
                        if dispenser:Health() <= 0 then
                            attacker:ChatPrint("Раздатчик разрушен!")
                            -- Удаляем хуки
                            hook.Remove("Think", "GModsaken_DispenserLogic_" .. dispenser:EntIndex())
                            hook.Remove("EntityTakeDamage", "GModsaken_DispenserDamage_" .. dispenser:EntIndex())
                        end
                    else
                        -- Выжившие не могут повредить раздатчик
                        dmginfo:SetDamage(0)
                    end
                end
            end)
            
            -- Удаляем через 5 минут
            timer.Simple(300, function()
                if IsValid(dispenser) then
                    hook.Remove("Think", "GModsaken_DispenserLogic_" .. dispenser:EntIndex())
                    hook.Remove("EntityTakeDamage", "GModsaken_DispenserDamage_" .. dispenser:EntIndex())
                    dispenser:Remove()
                end
            end)
            
            -- Уведомляем всех игроков
            for _, ply in pairs(player.GetAll()) do
                if ply:Team() == GAMEMODE.TEAM_SURVIVOR then
                    ply:ChatPrint("Инженер построил раздатчик! Он лечит и восстанавливает броню.")
                elseif ply:Team() == GAMEMODE.TEAM_KILLER then
                    ply:ChatPrint("Инженер построил раздатчик! Вы можете его разрушить.")
                end
            end
        end
    end
end

function SWEP:ShowBuildMenu(owner)
    if SERVER then
        owner:ChatPrint("=== МЕНЮ ПОСТРОЕК ===")
        owner:ChatPrint("ЛКМ - Построить турель (кулдаун: " .. self.TurretCooldown .. "с)")
        owner:ChatPrint("ПКМ - Построить раздатчик (кулдаун: " .. self.DispenserCooldown .. "с)")
        owner:ChatPrint("=====================")
    end
end

function SWEP:DrawHUD()
    local owner = self:GetOwner()
    if not IsValid(owner) then return end
    
    local screenW, screenH = ScrW(), ScrH()
    
    -- Информация о способностях
    local turretTime = self.TurretCooldown - (CurTime() - self.LastTurret)
    local dispenserTime = self.DispenserCooldown - (CurTime() - self.LastDispenser)
    
    draw.SimpleText("КПК Инженера", "DermaDefault", 20, screenH - 100, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    
    if turretTime > 0 then
        draw.SimpleText("Турель: " .. math.ceil(turretTime) .. "с", "DermaDefault", 20, screenH - 80, Color(255, 0, 0), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    else
        draw.SimpleText("Турель готова (ЛКМ)", "DermaDefault", 20, screenH - 80, Color(0, 255, 0), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    end
    
    if dispenserTime > 0 then
        draw.SimpleText("Раздатчик: " .. math.ceil(dispenserTime) .. "с", "DermaDefault", 20, screenH - 60, Color(255, 0, 0), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    else
        draw.SimpleText("Раздатчик готов (ПКМ)", "DermaDefault", 20, screenH - 60, Color(0, 255, 0), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    end
end 