--[[
    GModsaken - Engineer's PDA Weapon (Shared)
    Copyright (C) 2024 GModsaken Contributors
]]

SWEP.PrintName = "КПК Инженера"
SWEP.Author = "GModsaken"
SWEP.Instructions = "ЛКМ - построить турель, ПКМ - построить раздатчик, R - меню построек"
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
SWEP.SlotPos = 3
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = true

-- Модель и анимации (TF2 PDA)
SWEP.ViewModel = "models/weapons/v_models/v_pda_engineer.mdl"
SWEP.WorldModel = "models/weapons/w_models/w_pda_engineer.mdl"
SWEP.ViewModelFOV = 54
SWEP.UseHands = true

-- Модели рук для разных персонажей
SWEP.ViewModelArms = {
    ["gordon"] = "models/player/gmodsaken/gordon/c_arms_dr_freeman.mdl",
    ["engineer"] = "models/weapons/c_arms_engineer.mdl",
    ["default"] = "models/weapons/c_arms.mdl"
}

-- Звуки
SWEP.Primary.Sound = Sound("weapons/pda/pda_click.wav")
SWEP.Secondary.Sound = Sound("weapons/pda/pda_click.wav")

-- Способности
SWEP.TurretCost = 100
SWEP.DispenserCost = 75
SWEP.MaxTurrets = 2
SWEP.MaxDispensers = 1
SWEP.BuildRange = 200

SWEP.BuildDelay = 5.0
SWEP.TurretCooldown = 30.0
SWEP.DispenserCooldown = 45.0

SWEP.LastTurret = 0
SWEP.LastDispenser = 0

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
        elseif ply.SelectedCharacter == "Инженер" then
            armsModel = "models/weapons/c_arms_engineer.mdl"
        end
    end
    
    -- Устанавливаем модель рук
    if armsModel and util.IsModelLoaded(armsModel) then
        viewmodel:SetModel(armsModel)
    end
end 