--[[
    GModsaken - Mayor's Phone Weapon (Shared)
    Copyright (C) 2024 GModsaken Contributors
]]

SWEP.PrintName = "Телефон Мэра"
SWEP.Author = "GModsaken"
SWEP.Instructions = "ЛКМ - радар, ПКМ - аура брони, R - экстренный вызов"
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
SWEP.SlotPos = 5
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = true

-- Модель и анимации
SWEP.ViewModel = "models/weapons/c_pda.mdl"
SWEP.WorldModel = "models/weapons/w_pda.mdl"
SWEP.ViewModelFOV = 54
SWEP.UseHands = true

-- Модели рук для разных персонажей
SWEP.ViewModelArms = {
    ["gordon"] = "models/player/gmodsaken/gordon/c_arms_dr_freeman.mdl",
    ["mayor"] = "models/weapons/c_arms_mayor.mdl",
    ["default"] = "models/weapons/c_arms.mdl"
}

-- Звуки
SWEP.Primary.Sound = Sound("weapons/pda/pda_click.wav")
SWEP.Secondary.Sound = Sound("weapons/pda/pda_click.wav")

-- Способности
SWEP.RadarRange = 1000
SWEP.ArmorAuraRange = 200
SWEP.ArmorAuraAmount = 1

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
        elseif ply.SelectedCharacter == "Мэр" then
            armsModel = "models/weapons/c_arms_mayor.mdl"
        end
    end
    
    -- Устанавливаем модель рук
    if armsModel and util.IsModelLoaded(armsModel) then
        viewmodel:SetModel(armsModel)
    end
end 