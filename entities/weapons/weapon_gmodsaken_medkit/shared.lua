--[[
    GModsaken - Medic's Medkit Weapon (Shared)
    Copyright (C) 2024 GModsaken Contributors
]]

SWEP.PrintName = "Аптечка Медика"
SWEP.Author = "GModsaken"
SWEP.Instructions = "ЛКМ - Лечить себя\nПКМ - Лечить тиммейта\nR - Информация"
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
SWEP.SlotPos = 4
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = true

-- Модель и анимации
SWEP.ViewModel = "models/weapons/c_medkit.mdl"
SWEP.WorldModel = "models/weapons/w_medkit.mdl"
SWEP.ViewModelFOV = 54
SWEP.UseHands = true

-- Модели рук для разных персонажей
SWEP.ViewModelArms = {
    ["gordon"] = "models/player/gmodsaken/gordon/c_arms_dr_freeman.mdl",
    ["medic"] = "models/weapons/c_arms_medic.mdl",
    ["default"] = "models/weapons/c_arms.mdl"
}

-- Звуки
SWEP.Primary.Sound = Sound("items/medshot4.wav")
SWEP.Secondary.Sound = Sound("items/medshot5.wav")
SWEP.ErrorSound = Sound("buttons/button10.wav")
SWEP.HealSound = Sound("weapons/medkit/medkit_heal.wav")

-- Способности
SWEP.HealAmount = 50 -- Количество здоровья для лечения
SWEP.HealCooldown = 10 -- секунды между использованиями
SWEP.HealRange = 150 -- Дистанция для лечения тиммейтов
SWEP.Primary.Delay = 1.0
SWEP.Secondary.Delay = 1.0

-- Лечение
SWEP.HealDelay = 3.0
SWEP.Range = 200

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
        elseif ply.SelectedCharacter == "Медик" then
            armsModel = "models/weapons/c_arms_medic.mdl"
        end
    end
    
    -- Устанавливаем модель рук
    if armsModel and util.IsModelLoaded(armsModel) then
        viewmodel:SetModel(armsModel)
    end
end 