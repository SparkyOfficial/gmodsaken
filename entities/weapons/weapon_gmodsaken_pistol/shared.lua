--[[
    GModsaken - Rebel's Pistol Weapon (Shared)
    Copyright (C) 2024 GModsaken Contributors
]]

SWEP.PrintName = "Пистолет Повстанца"
SWEP.Author = "GModsaken"
SWEP.Instructions = "ЛКМ - выстрел с временным замедлением, R - перезарядка"
SWEP.Category = "GModsaken Weapons"

SWEP.Spawnable = true
SWEP.AdminSpawnable = true

SWEP.Primary.ClipSize = 8
SWEP.Primary.DefaultClip = 24
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "pistol"

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"

SWEP.Weight = 5
SWEP.AutoSwitchTo = false
SWEP.AutoSwitchFrom = false

SWEP.Slot = 2
SWEP.SlotPos = 1
SWEP.DrawAmmo = true
SWEP.DrawCrosshair = true

-- Модель и анимации
SWEP.ViewModel = "models/weapons/c_pistol.mdl"
SWEP.WorldModel = "models/weapons/w_pistol.mdl"
SWEP.ViewModelFOV = 54
SWEP.UseHands = true

-- Модели рук для разных персонажей
SWEP.ViewModelArms = {
    ["gordon"] = "models/player/gmodsaken/gordon/c_arms_dr_freeman.mdl",
    ["rebel"] = "models/weapons/c_arms_rebel.mdl",
    ["default"] = "models/weapons/c_arms.mdl"
}

-- Звуки
SWEP.Primary.Sound = Sound("weapons/pistol/pistol_fire2.wav")
SWEP.ReloadSound = Sound("weapons/pistol/pistol_reload1.wav")

-- Урон
SWEP.Primary.Damage = 15
SWEP.Primary.Delay = 0.8
SWEP.Primary.Recoil = 2.0

-- Способности
SWEP.SlowDuration = 2.0
SWEP.SlowAmount = 0.7
SWEP.JamChance = 0.1

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
        elseif ply.SelectedCharacter == "Повстанец" then
            armsModel = "models/weapons/c_arms_rebel.mdl"
        end
    end
    
    -- Устанавливаем модель рук
    if armsModel and util.IsModelLoaded(armsModel) then
        viewmodel:SetModel(armsModel)
    end
end 