--[[
    GModsaken - Guard's Baton Weapon
    Copyright (C) 2024 GModsaken Contributors
]]

AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

SWEP.PrintName = "Дубинка Охраника"
SWEP.Author = "GModsaken"
SWEP.Instructions = "ЛКМ - Атака\nПКМ - Ослепление (тратит 35 стамины)"
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
SWEP.ViewModel = "models/weapons/c_stunstick.mdl"
SWEP.WorldModel = "models/weapons/w_stunbaton.mdl"
SWEP.UseHands = true

-- Звуки
SWEP.Primary.Sound = Sound("weapons/stunstick/stunstick_swing1.wav")
SWEP.HitSound = Sound("weapons/stunstick/stunstick_fleshhit1.wav")

-- Урон
SWEP.Damage = 20
SWEP.Range = 100

-- Способности
SWEP.BlindDuration = 3 -- секунды
SWEP.StaminaCost = 35 -- стоимость стамины для ослепления
SWEP.StaminaRegenRate = 10 -- восстановление стамины
SWEP.Primary.Delay = 1.2 -- задержка атаки

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
    if not IsValid(self.Owner) then return end
    
    -- Проверяем стамину
    if self.Owner.Stamina and self.Owner.Stamina < self.StaminaCost then
        self.Owner:ChatPrint("Недостаточно стамины! Нужно: " .. self.StaminaCost .. ", есть: " .. (self.Owner.Stamina or 0))
        return
    end
    
    -- Тратим стамину
    if self.Owner.Stamina then
        self.Owner.Stamina = math.max(0, self.Owner.Stamina - self.StaminaCost)
        if GM and GM.UpdateStamina then
            GM:UpdateStamina(self.Owner)
        end
    end
    
    -- Атака
    self.Owner:SetAnimation(PLAYER_ATTACK1)
    self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
    
    -- Звук атаки
    self.Owner:EmitSound(self.Primary.Sound)
    
    -- Урон
    local tr = self.Owner:GetEyeTrace()
    if IsValid(tr.Entity) and tr.Entity:IsPlayer() then
        -- Используем универсальную функцию для урона с броней
        GAMEMODE:ApplyDamageWithArmor(tr.Entity, self.Damage, self.Owner, self)
        
        -- Звук попадания
        self.Owner:EmitSound(self.HitSound)
        
        -- Ослепление убийцы
        if tr.Entity:Team() == GM.TEAM_KILLER then
            net.Start("GModsaken_BlindPlayer")
            net.WriteEntity(tr.Entity)
            net.WriteFloat(self.BlindDuration)
            net.Broadcast()
        end
    end
    
    -- Задержка
    self:SetNextPrimaryFire(CurTime() + 1.2)
end

function SWEP:SecondaryAttack()
    if not IsValid(self.Owner) then return end
    
    -- Восстановление стамины
    if self.Owner.Stamina and self.Owner.Stamina < 100 then
        self.Owner.Stamina = math.min(100, self.Owner.Stamina + self.StaminaRegenRate)
        if GM and GM.UpdateStamina then
            GM:UpdateStamina(self.Owner)
        end
        self.Owner:ChatPrint("Восстановлена стамина: " .. self.StaminaRegenRate)
    end
    
    self:SetNextSecondaryFire(CurTime() + self.Secondary.Delay)
end

function SWEP:DrawHUD()
    local owner = self:GetOwner()
    if not IsValid(owner) then return end
    
    local screenW, screenH = ScrW(), ScrH()
    
    draw.SimpleText("Дубинка Охраника", "DermaDefault", 20, screenH - 80, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    draw.SimpleText("Урон: " .. self.Damage, "DermaDefault", 20, screenH - 60, Color(150, 255, 150), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    draw.SimpleText("Ослепление: " .. self.BlindDuration .. "с (стоимость: " .. self.StaminaCost .. " стамины)", "DermaDefault", 20, screenH - 40, Color(255, 255, 0), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    
    -- Показываем стамину
    local stamina = owner.Stamina or 0
    local staminaColor = stamina >= self.StaminaCost and Color(0, 255, 0) or Color(255, 0, 0)
    draw.SimpleText("Стамина: " .. stamina .. "/" .. self.StaminaCost, "DermaDefault", 20, screenH - 20, staminaColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
end 