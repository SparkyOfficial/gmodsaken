--[[
    GModsaken - Guard's Baton Weapon (Shared)
    Copyright (C) 2024 GModsaken Contributors
]]

SWEP.PrintName = "Дубинка Охраника"
SWEP.Author = "GModsaken"
SWEP.Instructions = "ЛКМ - атака с ослеплением (тратит стамину), R - восстановление стамины"
SWEP.Category = "GModsaken Weapons"

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
SWEP.SlotPos = 2
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = true

-- Модель и анимации
SWEP.ViewModel = "models/weapons/c_stunstick.mdl"
SWEP.WorldModel = "models/weapons/w_stunbaton.mdl"
SWEP.ViewModelFOV = 54
SWEP.UseHands = true

-- Модели рук для разных персонажей
SWEP.ViewModelArms = {
    ["gordon"] = "models/player/gmodsaken/gordon/c_arms_dr_freeman.mdl",
    ["guard"] = "models/weapons/c_arms_guard.mdl",
    ["default"] = "models/weapons/c_arms.mdl"
}

-- Звуки
SWEP.Primary.Sound = Sound("weapons/stunstick/stunstick_swing1.wav")
SWEP.HitSound = Sound("weapons/stunstick/stunstick_fleshhit1.wav")

-- Урон
SWEP.Primary.Damage = 20
SWEP.Primary.Delay = 1.2
SWEP.Secondary.Delay = 3.0

-- Способности
SWEP.BlindDuration = 4.0
SWEP.StaminaCost = 30
SWEP.StaminaRegenRate = 10

-- Функция для установки модели рук
function SWEP:SetViewModelArms(ply)
    if not IsValid(ply) then return end
    
    local viewmodel = ply:GetViewModel()
    if not IsValid(viewmodel) then return end
    
    -- Определяем модель рук в зависимости от персонажа
    local armsModel = self.ViewModelArms.default
    
    if ply.SelectedCharacter then
        if ply.SelectedCharacter == "Гордон Фримен" then
            armsModel = self.ViewModelArms.gordon
        elseif ply.SelectedCharacter == "Охраник" then
            armsModel = self.ViewModelArms.guard
        end
    end
    
    -- Устанавливаем модель рук
    if armsModel and util.IsModelLoaded(armsModel) then
        viewmodel:SetModel(armsModel)
    end
end 