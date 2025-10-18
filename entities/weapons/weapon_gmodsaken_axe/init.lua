--[[
    GModsaken - Meat's Axe Weapon
    Copyright (C) 2024 GModsaken Contributors
]]

AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

SWEP.PrintName = "Топор Мясного"
SWEP.Author = "GModsaken"
SWEP.Instructions = "ЛКМ - Атака\nПКМ - Заражение (создает хедкрабов)\nR - Лазер из глаз"
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
SWEP.SlotPos = 1
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = true

-- Модель и звуки (TF2 Fireaxe)
SWEP.ViewModel = "models/weapons/v_models/v_fireaxe_pyro.mdl"
SWEP.WorldModel = "models/weapons/w_models/w_fireaxe.mdl"
SWEP.UseHands = true

-- Звуки
SWEP.Primary.Sound = Sound("weapons/crowbar/crowbar_swing1.wav")
SWEP.HitSound = Sound("weapons/crowbar/crowbar_hit1.wav")

-- Урон
SWEP.Damage = 25
SWEP.Range = 100

-- Способности
SWEP.InfectionCooldown = 30 -- секунды
SWEP.LaserCooldown = 15 -- секунды
SWEP.LastInfection = 0
SWEP.LastLaser = 0

function SWEP:Initialize()
    self:SetHoldType("melee")
    
    -- Анимации для убийцы
    if SERVER then
        self:SetNWString("AnimSet", "melee")
    end
end

function SWEP:SetupDataTables()
    self:NetworkVar("Bool", 0, "InfectionReady")
    self:NetworkVar("Bool", 1, "LaserReady")
    self:NetworkVar("Bool", 2, "IsAttacking")
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
    
    -- Анимация атаки
    self:SetIsAttacking(true)
    if SERVER then
        owner:SetAnimation(PLAYER_ATTACK1)
        -- Анимации для Мясного
        if owner.SelectedCharacter == "Мясной" or owner.SelectedCharacter == "butcher" then
            owner:AnimRestartGesture(GESTURE_SLOT_ATTACK_AND_RELOAD, ACT_HL2MP_SWIM_IDLE, true)
            -- Дополнительная анимация для зомби
            owner:SetSequence(ACT_HL2MP_SWIM_IDLE)
        else
            owner:AnimRestartGesture(GESTURE_SLOT_ATTACK_AND_RELOAD, ACT_HL2MP_SWIM_IDLE, true)
        end
    end
    
    -- Звук атаки
    if self.Primary.Sound then
        owner:EmitSound(self.Primary.Sound)
    end
    
    -- Трейс для определения попадания
    local tr = util.TraceLine({
        start = owner:GetShootPos(),
        endpos = owner:GetShootPos() + owner:GetAimVector() * self.Range,
        filter = owner
    })
    
    local damage = self.Damage
    
    if tr.Hit and IsValid(tr.Entity) then
        if tr.Entity:IsPlayer() then
            print("GModsaken: Топор попал в игрока " .. tr.Entity:Nick() .. " (команда: " .. tr.Entity:Team() .. ")")
            
            -- Проверяем, что цель - выживший
            if tr.Entity:Team() == GAMEMODE.TEAM_SURVIVOR then
                -- Отключаем GodMode перед нанесением урона
                local wasGod = tr.Entity:HasGodMode()
                if wasGod then
                    tr.Entity:GodDisable()
                end
                
                -- Используем универсальную функцию для урона с броней
                GAMEMODE:ApplyDamageWithArmor(tr.Entity, damage, owner, self)
                
                -- Включаем GodMode обратно если был
                if wasGod then
                    tr.Entity:GodEnable()
                end
                
                -- Звук попадания
                if self.HitSound then
                    owner:EmitSound(self.HitSound)
                end
                
                -- Проверяем смерть
                if tr.Entity:Health() <= 0 then
                    tr.Entity:Kill()
                    print("GModsaken: " .. tr.Entity:Nick() .. " убит топором!")
                end
            else
                owner:ChatPrint("Вы не можете атаковать других убийц! Цель: " .. tr.Entity:Nick() .. " (команда: " .. tr.Entity:Team() .. ")")
            end
        elseif tr.Entity:GetClass() == "npc_turret_floor" or tr.Entity:GetClass() == "npc_turret_ceiling" then
            -- Разрушаем турели
            print("GModsaken: " .. owner:Nick() .. " разрушил турель!")
            owner:ChatPrint("Турель разрушена!")
            tr.Entity:Remove()
            
            -- Звук разрушения
            owner:EmitSound("physics/metal/metal_box_break1.wav")
            
        elseif tr.Entity:GetClass() == "item_ammopack_full" or 
               tr.Entity:GetClass() == "item_ammopack_medium" or 
               tr.Entity:GetClass() == "item_ammopack_small" or
               tr.Entity:GetClass() == "item_ammopack_base" then
            -- Разрушаем раздатчики патронов
            print("GModsaken: " .. owner:Nick() .. " разрушил раздатчик патронов!")
            owner:ChatPrint("Раздатчик патронов разрушен!")
            tr.Entity:Remove()
            
            -- Звук разрушения
            owner:EmitSound("physics/metal/metal_box_break1.wav")
            
        elseif tr.Entity:GetClass() == "item_healthkit_full" or 
               tr.Entity:GetClass() == "item_healthkit_medium" or 
               tr.Entity:GetClass() == "item_healthkit_small" then
            -- Разрушаем аптечки
            print("GModsaken: " .. owner:Nick() .. " разрушил аптечку!")
            owner:ChatPrint("Аптечка разрушена!")
            tr.Entity:Remove()
            
            -- Звук разрушения
            owner:EmitSound("physics/metal/metal_box_break1.wav")
            
        elseif tr.Entity:GetClass() == "prop_physics" and tr.Entity.IsQMenuProp then
            -- Дезинтегрируем пропы из Q-меню
            print("GModsaken: " .. owner:Nick() .. " дезинтегрировал проп из Q-меню!")
            
            -- Используем функцию дезинтеграции из гейммода
            if GM and GM.DisintegrateProp then
                GM:DisintegrateProp(tr.Entity, owner)
            else
                -- Fallback если функция не найдена
                owner:ChatPrint("Проп дезинтегрирован!")
                
                -- Эффект дезинтеграции
                local effectdata = EffectData()
                effectdata:SetOrigin(tr.Entity:GetPos())
                effectdata:SetScale(2)
                util.Effect("cball_explode", effectdata)
                
                -- Звук дезинтеграции
                owner:EmitSound("physics/metal/metal_box_break1.wav")
                
                -- Уведомляем создателя пропа
                if IsValid(tr.Entity.PropOwner) and tr.Entity.PropOwner ~= owner then
                    tr.Entity.PropOwner:ChatPrint("Ваш проп был дезинтегрирован убийцей!")
                end
                
                tr.Entity:Remove()
            end
        end
    end
    
    -- Сбрасываем флаг атаки через 0.5 секунды
    timer.Simple(0.5, function()
        if IsValid(self) then
            self:SetIsAttacking(false)
        end
    end)
    
    self:SetNextPrimaryFire(CurTime() + (self.Primary.Delay or 1.0))
end

function SWEP:SecondaryAttack()
    if not IsFirstTimePredicted() then return end
    
    local owner = self:GetOwner()
    if not IsValid(owner) then return end
    
    if CurTime() < self:GetNextSecondaryFire() then return end
    
    -- Проверяем, что владелец - убийца
    if owner:Team() ~= GAMEMODE.TEAM_KILLER then
        owner:ChatPrint("Только убийца может создавать хедкрабов!")
        return
    end
    
    -- Заражение (создание хедкрабов)
    for i = 1, 3 do
        timer.Simple(i * 0.5, function()
            if IsValid(owner) then
                local headcrab = ents.Create("npc_headcrab")
                if IsValid(headcrab) then
                    headcrab:SetPos(owner:GetPos() + Vector(0, 0, 20))
                    headcrab:Spawn()
                    headcrab:SetOwner(owner)
                    
                    -- Настраиваем хедкраба для атаки только выживших
                    headcrab.IsGModsakenHeadcrab = true
                    headcrab.TargetSurvivors = true
                    
                    -- Устанавливаем урон хедкраба
                    headcrab:SetKeyValue("damage", "10")
                    
                    -- Хук для кастомной логики атаки
                    hook.Add("EntityTakeDamage", "GModsaken_HeadcrabDamage_" .. headcrab:EntIndex(), function(target, dmginfo)
                        if dmginfo:GetAttacker() == headcrab and target:IsPlayer() then
                            print("GModsaken: Хедкраб атакует " .. target:Nick() .. " (команда: " .. target:Team() .. ")")
                            
                            -- Хедкраб может атаковать только выживших
                            if target:Team() == GAMEMODE.TEAM_SURVIVOR then
                                -- Отключаем GodMode перед нанесением урона
                                local wasGod = target:HasGodMode()
                                if wasGod then
                                    target:GodDisable()
                                end
                                
                                -- Наносим урон напрямую
                                local oldHealth = target:Health()
                                local damage = 10
                                local newHealth = math.max(0, oldHealth - damage)
                                target:SetHealth(newHealth)
                                
                                print("GModsaken: Хедкраб наносит " .. damage .. " урона " .. target:Nick() .. " (было: " .. oldHealth .. ", стало: " .. newHealth .. ")")
                                target:ChatPrint("Вас атаковал хедкраб убийцы! (" .. damage .. " урона)")
                                
                                -- Включаем GodMode обратно если был
                                if wasGod then
                                    target:GodEnable()
                                end
                                
                                -- Проверяем смерть
                                if newHealth <= 0 then
                                    target:Kill()
                                    print("GModsaken: " .. target:Nick() .. " убит хедкрабом!")
                                end
                                
                                -- Отменяем стандартный урон, так как мы уже нанесли свой
                                dmginfo:SetDamage(0)
                            else
                                -- Отменяем урон по убийцам
                                dmginfo:SetDamage(0)
                                print("GModsaken: Хедкраб не может атаковать убийцу " .. target:Nick())
                            end
                        end
                    end)
                    
                    -- Удаляем через 30 секунд
                    timer.Simple(30, function()
                        if IsValid(headcrab) then
                            hook.Remove("EntityTakeDamage", "GModsaken_HeadcrabDamage_" .. headcrab:EntIndex())
                            timer.Remove("GModsaken_HeadcrabAI_" .. headcrab:EntIndex())
                            headcrab:Remove()
                        end
                    end)
                    
                    -- Логика поиска и атаки целей
                    timer.Create("GModsaken_HeadcrabAI_" .. headcrab:EntIndex(), 1, 0, function()
                        if not IsValid(headcrab) then
                            timer.Remove("GModsaken_HeadcrabAI_" .. headcrab:EntIndex())
                            return
                        end
                        
                        -- Ищем ближайшего выжившего
                        local nearestSurvivor = nil
                        local nearestDistance = 1000
                        
                        for _, ply in pairs(player.GetAll()) do
                            if IsValid(ply) and ply:Team() == GAMEMODE.TEAM_SURVIVOR and ply:Alive() then
                                local distance = headcrab:GetPos():Distance(ply:GetPos())
                                if distance < nearestDistance then
                                    nearestDistance = distance
                                    nearestSurvivor = ply
                                end
                            end
                        end
                        
                        -- Если нашли цель и она близко, атакуем
                        if IsValid(nearestSurvivor) and nearestDistance < 100 then
                            -- Атакуем цель
                            local damage = DamageInfo()
                            damage:SetDamage(10)
                            damage:SetAttacker(headcrab)
                            damage:SetInflictor(headcrab)
                            damage:SetDamageType(DMG_SLASH)
                            
                            nearestSurvivor:TakeDamageInfo(damage)
                            print("GModsaken: Хедкраб атакует " .. nearestSurvivor:Nick() .. " на расстоянии " .. nearestDistance)
                        end
                    end)
                end
            end
        end)
    end
    
    owner:ChatPrint("Создано 3 хедкраба! Они будут атаковать выживших.")
    
    if self.Secondary.Sound then
        owner:EmitSound(self.Secondary.Sound)
    end
    
    self:SetNextSecondaryFire(CurTime() + (self.Secondary.Delay or 5.0))
end

function SWEP:Reload()
    if not IsFirstTimePredicted() then return end
    
    local owner = self:GetOwner()
    if not IsValid(owner) then return end
    
    -- Лазер из глаз для убийцы
    if owner:Team() == GAMEMODE.TEAM_KILLER then
        local tr = util.TraceLine({
            start = owner:GetShootPos(),
            endpos = owner:GetShootPos() + owner:GetAimVector() * 1000,
            filter = owner
        })
        
        if tr.Hit and IsValid(tr.Entity) then
            if tr.Entity:IsPlayer() then
                tr.Entity:TakeDamage(100, owner, self)
            end
        end
        
        -- Эффект лазера
        local effectdata = EffectData()
        effectdata:SetOrigin(tr.HitPos)
        effectdata:SetStart(owner:GetShootPos())
        util.Effect("laser", effectdata)
    end
end

function SWEP:DrawHUD()
    local owner = self:GetOwner()
    if not IsValid(owner) then return end
    
    local screenW, screenH = ScrW(), ScrH()
    
    -- Информация о способностях
    local infectionTime = self.InfectionCooldown - (CurTime() - self.LastInfection)
    local laserTime = self.LaserCooldown - (CurTime() - self.LastLaser)
    
    draw.SimpleText("Топор Мясного", "DermaDefault", 20, screenH - 100, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    
    if infectionTime > 0 then
        draw.SimpleText("Заражение: " .. math.ceil(infectionTime) .. "с", "DermaDefault", 20, screenH - 80, Color(255, 0, 0), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    else
        draw.SimpleText("Заражение готово (ПКМ)", "DermaDefault", 20, screenH - 80, Color(0, 255, 0), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    end
    
    if laserTime > 0 then
        draw.SimpleText("Лазер: " .. math.ceil(laserTime) .. "с", "DermaDefault", 20, screenH - 60, Color(255, 0, 0), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    else
        draw.SimpleText("Лазер готов (R)", "DermaDefault", 20, screenH - 60, Color(0, 255, 0), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    end
end 