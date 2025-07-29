--[[
    GModsaken - Guard's Baton Weapon (Client)
    Copyright (C) 2024 GModsaken Contributors
]]

include("shared.lua")

SWEP.PrintName = "Дубинка Охраника"
SWEP.Author = "GModsaken"
SWEP.Instructions = "ЛКМ - Атака\nПКМ - Ослепление (тратит 35 стамины)"
SWEP.Category = "GModsaken"

SWEP.Slot = 1
SWEP.SlotPos = 1
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = true

function SWEP:DrawHUD()
    local owner = self:GetOwner()
    if not IsValid(owner) then return end
    
    local screenW, screenH = ScrW(), ScrH()
    
    draw.SimpleText("Дубинка Охраника", "DermaDefault", 20, screenH - 80, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    draw.SimpleText("Урон: " .. (self.Primary.Damage or 20), "DermaDefault", 20, screenH - 60, Color(255, 255, 0), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    draw.SimpleText("Ослепление: " .. (self.BlindDuration or 4.0) .. "с | Стоимость: " .. (self.StaminaCost or 30) .. " стамины", "DermaDefault", 20, screenH - 40, Color(150, 255, 150), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    draw.SimpleText("Стамина: " .. (owner.Stamina or 0) .. "/100", "DermaDefault", 20, screenH - 20, Color(255, 150, 150), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
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
hook.Add("Think", "GModsaken_UpdateBatonArms", function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    
    local weapon = ply:GetActiveWeapon()
    if IsValid(weapon) and weapon:GetClass() == "weapon_gmodsaken_baton" then
        weapon:SetViewModelArms(ply)
    end
end) 