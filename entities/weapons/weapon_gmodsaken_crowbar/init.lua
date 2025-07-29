--[[
    GModsaken - Gordon Freeman's Crowbar Weapon
    Copyright (C) 2024 GModsaken Contributors
]]

AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

SWEP.PrintName = "Лом Гордона"
SWEP.Author = "GModsaken"
SWEP.Instructions = "ЛКМ - Атака (замедляет убийцу)"
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

-- Модель и звуки
SWEP.ViewModel = "models/weapons/c_crowbar.mdl"
SWEP.WorldModel = "models/weapons/w_crowbar.mdl"
SWEP.UseHands = true

-- Звуки
SWEP.Primary.Sound = Sound("weapons/crowbar/crowbar_swing1.wav")
SWEP.HitSound = Sound("weapons/crowbar/crowbar_hit1.wav")

-- Урон
SWEP.Damage = 25
SWEP.Range = 100

-- Способности
SWEP.SlowdownDuration = 3 -- секунды
SWEP.SlowdownMultiplier = 0.5 -- множитель замедления

function SWEP:Initialize()
    self:SetHoldType("melee")
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
    owner:SetAnimation(PLAYER_ATTACK1)
    
    -- Звук атаки
    if self.Primary.Sound then
        owner:EmitSound(self.Primary.Sound)
    end
    
    -- Урон
    local damage = self.Primary.Damage or 25
    local range = 100
    
    local tr = util.TraceLine({
        start = owner:GetShootPos(),
        endpos = owner:GetShootPos() + owner:GetAimVector() * range,
        filter = owner
    })
    
    if tr.Hit and IsValid(tr.Entity) then
        if tr.Entity:IsPlayer() then
            -- Используем универсальную функцию для урона с броней
            GAMEMODE:ApplyDamageWithArmor(tr.Entity, damage, owner, self)
            
            -- Замедление убийцы на 3 секунды
            if tr.Entity:Team() == GAMEMODE.TEAM_KILLER and owner:Team() == GAMEMODE.TEAM_SURVIVOR then
                self:SlowdownKiller(tr.Entity)
                print("GModsaken: " .. owner:Nick() .. " замедлил убийцу " .. tr.Entity:Nick() .. " на 3 секунды!")
                tr.Entity:ChatPrint("Вы замедлены ломом Гордона на 3 секунды!")
            end
        end
    end
    
    self:SetNextPrimaryFire(CurTime() + (self.Primary.Delay or 0.8))
end

function SWEP:SecondaryAttack()
    if not IsFirstTimePredicted() then return end
    
    local owner = self:GetOwner()
    if not IsValid(owner) then return end
    
    if CurTime() < self:GetNextSecondaryFire() then return end
    
    -- Толчок
    local tr = util.TraceLine({
        start = owner:GetShootPos(),
        endpos = owner:GetShootPos() + owner:GetAimVector() * 150,
        filter = owner
    })
    
    if tr.Hit and IsValid(tr.Entity) then
        if tr.Entity:IsPlayer() then
            local direction = (tr.Entity:GetPos() - owner:GetPos()):GetNormalized()
            tr.Entity:SetVelocity(direction * 500)
        end
    end
    
    self:SetNextSecondaryFire(CurTime() + (self.Secondary.Delay or 2.0))
end

function SWEP:SlowdownKiller(killer)
    if not IsValid(killer) then return end
    
    -- Сохраняем оригинальную скорость
    if not killer.OriginalSpeed then
        killer.OriginalSpeed = {
            walk = killer:GetWalkSpeed(),
            run = killer:GetRunSpeed()
        }
    end
    
    -- Применяем замедление
    killer:SetWalkSpeed(killer.OriginalSpeed.walk * self.SlowdownMultiplier)
    killer:SetRunSpeed(killer.OriginalSpeed.run * self.SlowdownMultiplier)
    
    -- Восстанавливаем скорость через время
    timer.Simple(self.SlowdownDuration, function()
        if IsValid(killer) and killer.OriginalSpeed then
            killer:SetWalkSpeed(killer.OriginalSpeed.walk)
            killer:SetRunSpeed(killer.OriginalSpeed.run)
            killer:ChatPrint("Замедление закончилось!")
        end
    end)
end

function SWEP:DrawHUD()
    local owner = self:GetOwner()
    if not IsValid(owner) then return end
    
    local screenW, screenH = ScrW(), ScrH()
    
    draw.SimpleText("Лом Гордона Фримена", "DermaDefault", 20, screenH - 60, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    draw.SimpleText("Урон: " .. self.Damage .. " | Замедление: " .. self.SlowdownDuration .. "с", "DermaDefault", 20, screenH - 40, Color(150, 255, 150), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
end 