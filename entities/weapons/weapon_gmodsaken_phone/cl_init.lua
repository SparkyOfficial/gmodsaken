--[[
    GModsaken - Mayor's Phone Weapon (Client)
    Copyright (C) 2024 GModsaken Contributors
]]

include("shared.lua")

SWEP.PrintName = "Телефон Мэра"
SWEP.Author = "GModsaken"
SWEP.Instructions = "ЛКМ - Радар\nПКМ - Аура брони\nR - Экстренный вызов"
SWEP.Category = "GModsaken"

SWEP.Slot = 1
SWEP.SlotPos = 5
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
hook.Add("Think", "GModsaken_UpdatePhoneArms", function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    
    local weapon = ply:GetActiveWeapon()
    if IsValid(weapon) and weapon:GetClass() == "weapon_gmodsaken_phone" then
        weapon:SetViewModelArms(ply)
    end
end)

function SWEP:DrawHUD()
    local owner = self:GetOwner()
    if not IsValid(owner) then return end
    
    local screenW, screenH = ScrW(), ScrH()
    
    -- Инициализируем переменные если они nil
    self.LastRadar = self.LastRadar or 0
    self.LastAura = self.LastAura or 0
    self.AuraActive = self.AuraActive or false
    self.AuraEndTime = self.AuraEndTime or 0
    self.RadarCooldown = self.RadarCooldown or 10
    self.AuraCooldown = self.AuraCooldown or 20
    
    -- Информация о способностях
    local radarTime = self.RadarCooldown - (CurTime() - self.LastRadar)
    local auraTime = self.AuraCooldown - (CurTime() - self.LastAura)
    
    draw.SimpleText("Телефон Мэра", "DermaDefault", 20, screenH - 100, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    
    if radarTime > 0 then
        draw.SimpleText("Радар: " .. math.ceil(radarTime) .. "с", "DermaDefault", 20, screenH - 80, Color(255, 0, 0), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    else
        draw.SimpleText("Радар готов (ЛКМ)", "DermaDefault", 20, screenH - 80, Color(0, 255, 0), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    end
    
    if auraTime > 0 then
        draw.SimpleText("Аура: " .. math.ceil(auraTime) .. "с", "DermaDefault", 20, screenH - 60, Color(255, 0, 0), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    else
        draw.SimpleText("Аура готова (ПКМ)", "DermaDefault", 20, screenH - 60, Color(0, 255, 0), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    end
    
    -- Показываем активную ауру
    if self.AuraActive then
        local auraTimeLeft = self.AuraEndTime - CurTime()
        if auraTimeLeft > 0 then
            draw.SimpleText("Аура активна: " .. math.ceil(auraTimeLeft) .. "с", "DermaDefault", 20, screenH - 40, Color(255, 255, 0), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        end
    end
end 