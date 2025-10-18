--[[
    GModsaken - Medic's Medkit Weapon (Client)
    Copyright (C) 2024 GModsaken Contributors
]]

include("shared.lua")

SWEP.PrintName = "Аптечка Медика"
SWEP.Author = "GModsaken"
SWEP.Instructions = "ЛКМ - Лечение игрока\nR - Лечение себя"
SWEP.Category = "GModsaken"

SWEP.Slot = 1
SWEP.SlotPos = 4
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = true

-- Модель и анимации
SWEP.ViewModel = "models/weapons/c_medkit.mdl"
SWEP.WorldModel = "models/weapons/w_medkit.mdl"
SWEP.ViewModelFOV = 54
SWEP.UseHands = true

function SWEP:Initialize()
    self:SetHoldType("normal")
end

function SWEP:DrawHUD()
    local owner = self:GetOwner()
    if not IsValid(owner) then return end
    
    local screenW, screenH = ScrW(), ScrH()
    
    -- Информация об аптечке
    local cooldownRemaining = self.HealCooldown - (CurTime() - (self.LastHeal or 0))
    
    draw.SimpleText("Аптечка Медика", "DermaDefault", 20, screenH - 100, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    draw.SimpleText("ЛКМ - Лечить себя", "DermaDefault", 20, screenH - 80, Color(0, 255, 0), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    draw.SimpleText("ПКМ - Лечить тиммейта", "DermaDefault", 20, screenH - 60, Color(0, 255, 0), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    
    if cooldownRemaining > 0 then
        draw.SimpleText("Кулдаун: " .. math.ceil(cooldownRemaining) .. "с", "DermaDefault", 20, screenH - 40, Color(255, 0, 0), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    else
        draw.SimpleText("Готово к использованию", "DermaDefault", 20, screenH - 40, Color(0, 255, 0), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    end
    
    draw.SimpleText("Лечение: " .. (self.HealAmount or 50) .. " HP", "DermaDefault", 20, screenH - 20, Color(150, 255, 150), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
end

-- Функция для установки модели рук
function SWEP:SetViewModelArmsModel(model)
    if not IsValid(self.Owner) then return end
    
    local viewmodel = self.Owner:GetViewModel()
    if IsValid(viewmodel) then
        viewmodel:SetSubMaterial(0, "") -- Сбрасываем материал
        viewmodel:SetModel(model)
    end
end

-- Обновляем модель рук при получении оружия
function SWEP:Equip()
    if IsValid(self.Owner) then
        self:SetViewModelArms(self.Owner)
    end
end

-- Обновляем модель рук при смене персонажа
hook.Add("Think", "GModsaken_UpdateMedkitArms", function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    
    local weapon = ply:GetActiveWeapon()
    if IsValid(weapon) and weapon:GetClass() == "weapon_gmodsaken_medkit" then
        weapon:SetViewModelArms(ply)
    end
end) 