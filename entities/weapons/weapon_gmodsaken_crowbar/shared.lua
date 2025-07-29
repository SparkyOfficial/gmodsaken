--[[
    GModsaken - Gordon's Crowbar Weapon (Shared)
    Copyright (C) 2024 GModsaken Contributors
]]

SWEP.PrintName = "Лом Гордона"
SWEP.Author = "GModsaken"
SWEP.Instructions = "ЛКМ - атака с замедлением убийцы, R - специальная атака"
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
SWEP.SlotPos = 1
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = true

-- Модель и анимации
SWEP.ViewModel = "models/weapons/c_crowbar.mdl"
SWEP.WorldModel = "models/weapons/w_crowbar.mdl"
SWEP.ViewModelFOV = 54
SWEP.UseHands = true

-- Модели рук для разных персонажей
SWEP.ViewModelArms = {
    ["gordon"] = "models/player/gmodsaken/gordon/c_arms_dr_freeman.mdl",
    ["default"] = "models/weapons/c_arms.mdl"
}

-- Звуки
SWEP.Primary.Sound = Sound("weapons/crowbar/crowbar_swing1.wav")
SWEP.HitSound = Sound("weapons/crowbar/crowbar_hit1.wav")

-- Урон
SWEP.Primary.Damage = 25
SWEP.Primary.Delay = 1.0
SWEP.Secondary.Delay = 3.0

-- Способности
SWEP.SlowDuration = 3.0
SWEP.SlowAmount = 0.8

-- Функция для установки модели рук
function SWEP:SetViewModelArms(ply)
    if not IsValid(ply) then return end
    
    local viewmodel = ply:GetViewModel()
    if not IsValid(viewmodel) then return end
    
    -- Определяем модель рук в зависимости от персонажа
    local armsModel = "models/weapons/c_arms.mdl" -- По умолчанию
    
    if ply.SelectedCharacter then
        if ply.SelectedCharacter == "Гордон Фримен" then
            armsModel = "models/player/gmodsaken/gordon/c_arms_dr_freeman.mdl"
        end
    end
    
    -- Устанавливаем модель рук
    if armsModel and util.IsModelLoaded(armsModel) then
        viewmodel:SetModel(armsModel)
    end
end 