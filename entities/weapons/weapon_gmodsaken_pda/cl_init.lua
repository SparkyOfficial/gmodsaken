--[[
    GModsaken - Engineer's PDA Weapon (Client)
    Copyright (C) 2024 GModsaken Contributors
]]

include("shared.lua")

SWEP.PrintName = "КПК Инженера"
SWEP.Author = "GModsaken"
SWEP.Instructions = "ЛКМ - Построить турель\nПКМ - Построить раздатчик\nR - Меню построек"
SWEP.Category = "GModsaken"

SWEP.Slot = 1
SWEP.SlotPos = 3
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = true

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
hook.Add("Think", "GModsaken_UpdatePDAArms", function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    
    local weapon = ply:GetActiveWeapon()
    if IsValid(weapon) and weapon:GetClass() == "weapon_gmodsaken_pda" then
        weapon:SetViewModelArms(ply)
    end
end)

function SWEP:DrawHUD()
    local owner = self:GetOwner()
    if not IsValid(owner) then return end
    
    local screenW, screenH = ScrW(), ScrH()
    
    -- Информация о способностях
    local turretTime = self.TurretCooldown - (CurTime() - self.LastTurret)
    local dispenserTime = self.DispenserCooldown - (CurTime() - self.LastDispenser)
    
    draw.SimpleText("КПК Инженера", "DermaDefault", 20, screenH - 100, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    
    if turretTime > 0 then
        draw.SimpleText("Турель: " .. math.ceil(turretTime) .. "с", "DermaDefault", 20, screenH - 80, Color(255, 0, 0), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    else
        draw.SimpleText("Турель готова (ЛКМ)", "DermaDefault", 20, screenH - 80, Color(0, 255, 0), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    end
    
    if dispenserTime > 0 then
        draw.SimpleText("Раздатчик: " .. math.ceil(dispenserTime) .. "с", "DermaDefault", 20, screenH - 60, Color(255, 0, 0), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    else
        draw.SimpleText("Раздатчик готов (ПКМ)", "DermaDefault", 20, screenH - 60, Color(0, 255, 0), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    end
end 