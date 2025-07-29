--[[
    GModsaken - Meat's Axe Weapon (Shared)
    Copyright (C) 2024 GModsaken Contributors
]]

SWEP.PrintName = "Топор Мясного"
SWEP.Author = "GModsaken"
SWEP.Instructions = "ЛКМ - атака, ПКМ - заражение (создает хедкрабов), R - лазер из глаз"
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

-- Модель и анимации (TF2 Fireaxe)
SWEP.ViewModel = "models/weapons/v_models/v_fireaxe_pyro.mdl"
SWEP.WorldModel = "models/weapons/w_models/w_fireaxe.mdl"
SWEP.ViewModelFOV = 54
SWEP.UseHands = true

-- Модели рук для разных персонажей
SWEP.ViewModelArms = {
    ["gordon"] = "models/player/gmodsaken/gordon/c_arms_dr_freeman.mdl",
    ["default"] = "models/weapons/c_arms.mdl"
}

-- Звуки
SWEP.Primary.Sound = Sound("weapons/knife/knife_hit1.wav")
SWEP.Secondary.Sound = Sound("npc/headcrab/headcrab_die1.wav")

-- Урон
SWEP.Primary.Damage = 50
SWEP.Primary.Delay = 1.5
SWEP.Secondary.Delay = 5.0
SWEP.Range = 120

-- Способности
SWEP.InfectionCooldown = 0
SWEP.LaserCooldown = 0

-- Функция для установки модели рук
function SWEP:SetViewModelArms(ply)
    if not IsValid(ply) then return end
    
    local viewmodel = ply:GetViewModel()
    if not IsValid(viewmodel) then return end
    
    -- Для убийцы используем стандартную модель рук
    local armsModel = "models/weapons/c_arms.mdl"
    
    -- Устанавливаем модель рук
    if armsModel and util.IsModelLoaded(armsModel) then
        viewmodel:SetModel(armsModel)
    end
end 