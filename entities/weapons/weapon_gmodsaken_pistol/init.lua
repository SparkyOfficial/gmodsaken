--[[
    GModsaken - Rebel's Pistol Weapon
    Copyright (C) 2024 GModsaken Contributors
]]

AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

SWEP.PrintName = "Пистолет Повстанца"
SWEP.Author = "GModsaken"
SWEP.Instructions = "ЛКМ - Стрельба (временно замедляет убийцу)\nR - Перезарядка"
SWEP.Category = "GModsaken"

SWEP.Spawnable = true
SWEP.AdminSpawnable = true

SWEP.Primary.ClipSize = 12
SWEP.Primary.DefaultClip = 36
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "pistol"

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"

SWEP.Weight = 5
SWEP.AutoSwitchTo = false
SWEP.AutoSwitchFrom = false

SWEP.Slot = 1
SWEP.SlotPos = 1
SWEP.DrawAmmo = true
SWEP.DrawCrosshair = true

-- Модель и звуки
SWEP.ViewModel = "models/weapons/c_pistol.mdl"
SWEP.WorldModel = "models/weapons/w_pistol.mdl"
SWEP.UseHands = true

-- Звуки
SWEP.Primary.Sound = Sound("weapons/pistol/pistol_fire2.wav")
SWEP.EmptySound = Sound("weapons/pistol/pistol_empty.wav")
SWEP.ReloadSound = Sound("weapons/pistol/pistol_reload1.wav")

-- Урон
SWEP.Damage = 15
SWEP.Range = 1000

-- Способности
SWEP.SlowdownDuration = 3 -- секунды
SWEP.SlowdownMultiplier = 0.7 -- множитель замедления (не полное замедление)
SWEP.JamChance = 0.15 -- 15% шанс заклинивания

function SWEP:Initialize()
    self:SetHoldType("pistol")
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
    
    if self:Clip1() <= 0 then
        self:Reload()
        return
    end
    
    -- Проверка заклинивания
    if math.random() < (self.JamChance or 0.1) then
        owner:ChatPrint("Пистолет заклинило!")
        self:SetNextPrimaryFire(CurTime() + 2.0)
        return
    end
    
    -- Анимация выстрела
    owner:SetAnimation(PLAYER_ATTACK1)
    
    -- Звук выстрела
    if self.Primary.Sound then
        owner:EmitSound(self.Primary.Sound)
    end
    
    -- Создаем пулю
    local bullet = {}
    bullet.Num = 1
    bullet.Src = owner:GetShootPos()
    bullet.Dir = owner:GetAimVector()
    bullet.Spread = Vector(0.01, 0.01, 0)
    bullet.Tracer = 1
    bullet.TracerName = "Tracer"
    bullet.Force = 5
    bullet.Damage = self.Damage or 15
    bullet.Callback = function(attacker, tr, dmginfo)
        if tr.Hit and IsValid(tr.Entity) and tr.Entity:IsPlayer() then
            -- Используем универсальную функцию для урона с броней
            GAMEMODE:ApplyDamageWithArmor(tr.Entity, self.Damage or 15, owner, self)
            
            -- Замедление убийцы
            if tr.Entity:Team() == GAMEMODE.TEAM_KILLER and owner:Team() == GAMEMODE.TEAM_SURVIVOR then
                self:TemporarySlowdown(tr.Entity)
                tr.Entity:ChatPrint("Вы временно замедлены пистолетом повстанца!")
            end
            
            -- Проверяем смерть
            if tr.Entity:Health() <= 0 then
                tr.Entity:Kill()
                print("GModsaken: " .. tr.Entity:Nick() .. " убит пистолетом повстанца!")
            end
        end
    end
    
    owner:FireBullets(bullet)
    
    -- Отдача
    owner:ViewPunch(Angle(-self.Primary.Recoil or 2, 0, 0))
    
    self:TakePrimaryAmmo(1)
    self:SetNextPrimaryFire(CurTime() + (self.Primary.Delay or 0.5))
end

function SWEP:SecondaryAttack()
    -- Вторичная атака не используется
    return false
end

function SWEP:Reload()
    if not IsFirstTimePredicted() then return end
    
    local owner = self:GetOwner()
    if not IsValid(owner) then return end
    
    if self:Clip1() >= self.Primary.ClipSize then return end
    
    if self.ReloadSound then
        owner:EmitSound(self.ReloadSound)
    end
    
    self:DefaultReload(ACT_VM_RELOAD)
end

function SWEP:TemporarySlowdown(killer)
    if not IsValid(killer) then return end
    
    -- Сохраняем оригинальную скорость только если еще не сохранена
    if not killer.OriginalSpeed then
        killer.OriginalSpeed = {
            walk = killer:GetWalkSpeed(),
            run = killer:GetRunSpeed()
        }
    end
    
    -- Применяем временное замедление
    local slowMultiplier = self.SlowdownMultiplier or 0.7
    killer:SetWalkSpeed(killer.OriginalSpeed.walk * slowMultiplier)
    killer:SetRunSpeed(killer.OriginalSpeed.run * slowMultiplier)
    
    print("GModsaken: " .. killer:Nick() .. " замедлен на " .. self.SlowdownDuration .. " секунд")
    
    -- Восстанавливаем скорость через время
    timer.Simple(self.SlowdownDuration, function()
        if IsValid(killer) and killer.OriginalSpeed then
            killer:SetWalkSpeed(killer.OriginalSpeed.walk)
            killer:SetRunSpeed(killer.OriginalSpeed.run)
            killer:ChatPrint("Временное замедление закончилось!")
            print("GModsaken: " .. killer:Nick() .. " - замедление снято")
        end
    end)
end

function SWEP:DrawHUD()
    local owner = self:GetOwner()
    if not IsValid(owner) then return end
    
    local screenW, screenH = ScrW(), ScrH()
    
    draw.SimpleText("Пистолет Повстанца", "DermaDefault", 20, screenH - 80, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    draw.SimpleText("Патроны: " .. self:Clip1() .. "/" .. owner:GetAmmoCount(self.Primary.Ammo), "DermaDefault", 20, screenH - 60, Color(255, 255, 0), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    draw.SimpleText("Урон: " .. self.Damage .. " | Замедление: " .. self.SlowdownDuration .. "с", "DermaDefault", 20, screenH - 40, Color(150, 255, 150), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    draw.SimpleText("Шанс заклинивания: " .. (self.JamChance * 100) .. "%", "DermaDefault", 20, screenH - 20, Color(255, 150, 150), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
end 