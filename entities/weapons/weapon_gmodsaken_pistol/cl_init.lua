--[[
    GModsaken - Rebel's Pistol Weapon (Client)
    Copyright (C) 2024 GModsaken Contributors
]]

include("shared.lua")

SWEP.PrintName = "Пистолет Повстанца"
SWEP.Author = "GModsaken"
SWEP.Instructions = "ЛКМ - Стрельба (временно замедляет убийцу)\nR - Перезарядка"
SWEP.Category = "GModsaken"

SWEP.Slot = 1
SWEP.SlotPos = 1
SWEP.DrawAmmo = true
SWEP.DrawCrosshair = true

function SWEP:DrawHUD()
    local owner = self:GetOwner()
    if not IsValid(owner) then return end
    
    local screenW, screenH = ScrW(), ScrH()
    
    draw.SimpleText("Пистолет Повстанца", "DermaDefault", 20, screenH - 80, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    draw.SimpleText("Патроны: " .. self:Clip1() .. "/" .. owner:GetAmmoCount(self.Primary.Ammo), "DermaDefault", 20, screenH - 60, Color(255, 255, 0), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    draw.SimpleText("Урон: " .. (self.Primary.Damage or 15) .. " | Замедление: " .. (self.SlowDuration or 2.0) .. "с", "DermaDefault", 20, screenH - 40, Color(150, 255, 150), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    draw.SimpleText("Шанс заклинивания: " .. ((self.JamChance or 0.1) * 100) .. "%", "DermaDefault", 20, screenH - 20, Color(255, 150, 150), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
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
hook.Add("Think", "GModsaken_UpdatePistolArms", function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    
    local weapon = ply:GetActiveWeapon()
    if IsValid(weapon) and weapon:GetClass() == "weapon_gmodsaken_pistol" then
        if weapon.SetViewModelArms then
            weapon:SetViewModelArms(ply)
        end
    end
end) 