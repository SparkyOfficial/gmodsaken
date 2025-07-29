--[[
    GModsaken - Gordon's Crowbar Weapon (Client)
    Copyright (C) 2024 GModsaken Contributors
]]

include("shared.lua")

SWEP.PrintName = "Лом Гордона"
SWEP.Author = "GModsaken"
SWEP.Instructions = "ЛКМ - Атака (замедляет убийцу)\nR - Специальная атака"
SWEP.Category = "GModsaken"

SWEP.Slot = 1
SWEP.SlotPos = 1
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

-- Функция для установки модели рук на основе персонажа
function SWEP:SetViewModelArms(ply)
    if not IsValid(ply) then return end
    
    -- Получаем выбранного персонажа
    local character = ply.SelectedCharacter or "default"
    
    -- Определяем модель рук для персонажа
    local armsModel = "models/weapons/c_arms.mdl" -- Модель по умолчанию
    
    if character == "gordon" then
        armsModel = "models/paynamia/bms/c_arms_bms_hev.mdl"
    elseif character == "rebel" then
        armsModel = "models/weapons/c_arms.mdl"
    elseif character == "engineer" then
        armsModel = "models/weapons/c_arms.mdl"
    elseif character == "medic" then
        armsModel = "models/weapons/c_arms.mdl"
    elseif character == "guard" then
        armsModel = "models/weapons/c_arms.mdl"
    elseif character == "mayor" then
        armsModel = "models/weapons/c_arms.mdl"
    elseif character == "myasnoi" then
        armsModel = "models/weapons/c_arms.mdl"
    end
    
    -- Устанавливаем модель рук
    self:SetViewModelArmsModel(armsModel)
end

-- Обновляем модель рук при получении оружия
function SWEP:Equip()
    if IsValid(self.Owner) then
        self:SetViewModelArms(self.Owner)
    end
end

-- Обновляем модель рук при смене персонажа
hook.Add("Think", "GModsaken_UpdateCrowbarArms", function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    
    local weapon = ply:GetActiveWeapon()
    if IsValid(weapon) and weapon:GetClass() == "weapon_gmodsaken_crowbar" then
        weapon:SetViewModelArms(ply)
    end
end)

function SWEP:DrawHUD()
    local owner = self:GetOwner()
    if not IsValid(owner) then return end
    
    local screenW, screenH = ScrW(), ScrH()
    
    draw.SimpleText("Лом Гордона", "DermaDefault", 20, screenH - 80, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    draw.SimpleText("Урон: " .. (self.Primary.Damage or 25), "DermaDefault", 20, screenH - 60, Color(255, 255, 0), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    draw.SimpleText("Замедление: " .. (self.SlowDuration or 3.0) .. "с", "DermaDefault", 20, screenH - 40, Color(150, 255, 150), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    draw.SimpleText("Толчок: ПКМ", "DermaDefault", 20, screenH - 20, Color(255, 150, 150), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
end 