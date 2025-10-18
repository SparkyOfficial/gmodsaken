--[[
    GModsaken - Medic's Medkit Weapon
    Copyright (C) 2024 GModsaken Contributors
]]

AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

SWEP.PrintName = "Аптечка Медика"
SWEP.Author = "GModsaken"
SWEP.Instructions = "ЛКМ - Лечить себя\nПКМ - Лечить тиммейта\nR - Информация"
SWEP.Category = "GModsaken"

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

-- Модель и звуки
SWEP.ViewModel = "models/weapons/c_medkit.mdl"
SWEP.WorldModel = "models/weapons/w_medkit.mdl"
SWEP.UseHands = true

-- Звуки
SWEP.Primary.Sound = Sound("items/medshot4.wav")
SWEP.Secondary.Sound = Sound("items/medshot5.wav")
SWEP.ErrorSound = Sound("buttons/button10.wav")

-- Способности
SWEP.HealAmount = 50 -- Количество здоровья для лечения
SWEP.HealCooldown = 10 -- секунды между использованиями
SWEP.HealRange = 150 -- Дистанция для лечения тиммейтов
SWEP.LastHeal = 0

function SWEP:Initialize()
    self:SetHoldType("normal")
end

-- Функция для установки правильной модели рук
function SWEP:SetViewModelArms(ply)
    if not IsValid(ply) then return end
    
    local characterName = ply.SelectedCharacter or "default"
    local armsModel = self.ViewModelArms[characterName] or self.ViewModelArms["default"]
    
    if armsModel then
        self.ViewModelArmsModel = armsModel
        if CLIENT then
            self:SetViewModelArmsModel(armsModel)
        end
    end
end

function SWEP:PrimaryAttack()
    if not IsFirstTimePredicted() then return end
    
    local owner = self:GetOwner()
    if not IsValid(owner) then return end
    
    if CurTime() < self:GetNextPrimaryFire() then return end
    
    -- Проверяем кулдаун
    if CurTime() - self.LastHeal < self.HealCooldown then
        owner:ChatPrint("Аптечка еще не готова! Подождите " .. math.ceil(self.HealCooldown - (CurTime() - self.LastHeal)) .. " секунд")
        if self.ErrorSound then
            owner:EmitSound(self.ErrorSound)
        end
        return
    end
    
    -- Лечим себя
    local currentHealth = owner:Health()
    local maxHealth = owner:GetMaxHealth()
    
    if currentHealth >= maxHealth then
        owner:ChatPrint("Вы полностью здоровы!")
        if self.ErrorSound then
            owner:EmitSound(self.ErrorSound)
        end
        return
    end
    
    -- Лечим здоровье
    local newHealth = math.min(currentHealth + self.HealAmount, maxHealth)
    owner:SetHealth(newHealth)
    
    -- Звук лечения
    if self.Primary.Sound then
        owner:EmitSound(self.Primary.Sound)
    end
    
    -- Обновляем время последнего использования
    self.LastHeal = CurTime()
    
    -- Уведомляем игрока
    owner:ChatPrint("Вы вылечили себя! Здоровье: " .. newHealth .. "/" .. maxHealth)
    
    self:SetNextPrimaryFire(CurTime() + 1.0)
end

function SWEP:SecondaryAttack()
    if not IsFirstTimePredicted() then return end
    
    local owner = self:GetOwner()
    if not IsValid(owner) then return end
    
    if CurTime() < self:GetNextSecondaryFire() then return end
    
    -- Проверяем кулдаун
    if CurTime() - self.LastHeal < self.HealCooldown then
        owner:ChatPrint("Аптечка еще не готова! Подождите " .. math.ceil(self.HealCooldown - (CurTime() - self.LastHeal)) .. " секунд")
        if self.ErrorSound then
            owner:EmitSound(self.ErrorSound)
        end
        return
    end
    
    -- Ищем ближайшего тиммейта для лечения
    local closestTeammate = nil
    local closestDistance = self.HealRange
    
    for _, ply in pairs(player.GetAll()) do
        if IsValid(ply) and ply ~= owner and ply:Team() == owner:Team() and ply:Alive() then
            local distance = owner:GetPos():Distance(ply:GetPos())
            if distance <= closestDistance then
                local currentHealth = ply:Health()
                local maxHealth = ply:GetMaxHealth()
                if currentHealth < maxHealth then
                    closestTeammate = ply
                    closestDistance = distance
                end
            end
        end
    end
    
    if not closestTeammate then
        owner:ChatPrint("Нет раненых тиммейтов рядом!")
        if self.ErrorSound then
            owner:EmitSound(self.ErrorSound)
        end
        return
    end
    
    -- Лечим тиммейта
    local currentHealth = closestTeammate:Health()
    local maxHealth = closestTeammate:GetMaxHealth()
    local newHealth = math.min(currentHealth + self.HealAmount, maxHealth)
    closestTeammate:SetHealth(newHealth)
    
    -- Звук лечения
    if self.Secondary.Sound then
        owner:EmitSound(self.Secondary.Sound)
    end
    
    -- Обновляем время последнего использования
    self.LastHeal = CurTime()
    
    -- Уведомляем игроков
    owner:ChatPrint("Вы вылечили " .. closestTeammate:Nick() .. "! Здоровье: " .. newHealth .. "/" .. maxHealth)
    closestTeammate:ChatPrint(owner:Nick() .. " вылечил вас! Здоровье: " .. newHealth .. "/" .. maxHealth)
    
    self:SetNextSecondaryFire(CurTime() + 1.0)
end

function SWEP:Reload()
    if not IsFirstTimePredicted() then return end
    
    local owner = self:GetOwner()
    if not IsValid(owner) then return end
    
    -- Показываем информацию об аптечке
    owner:ChatPrint("=== АПТЕЧКА МЕДИКА ===")
    owner:ChatPrint("ЛКМ - Лечить себя (" .. self.HealAmount .. " HP)")
    owner:ChatPrint("ПКМ - Лечить тиммейта (" .. self.HealAmount .. " HP)")
    owner:ChatPrint("Кулдаун: " .. self.HealCooldown .. " секунд")
    owner:ChatPrint("Дистанция лечения: " .. self.HealRange .. " единиц")
    
    local cooldownRemaining = self.HealCooldown - (CurTime() - self.LastHeal)
    if cooldownRemaining > 0 then
        owner:ChatPrint("До готовности: " .. math.ceil(cooldownRemaining) .. " секунд")
    else
        owner:ChatPrint("Аптечка готова к использованию!")
    end
end

function SWEP:DrawHUD()
    local owner = self:GetOwner()
    if not IsValid(owner) then return end
    
    local screenW, screenH = ScrW(), ScrH()
    
    -- Информация об аптечке
    local cooldownRemaining = self.HealCooldown - (CurTime() - self.LastHeal)
    
    draw.SimpleText("Аптечка Медика", "DermaDefault", 20, screenH - 100, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    draw.SimpleText("ЛКМ - Лечить себя", "DermaDefault", 20, screenH - 80, Color(0, 255, 0), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    draw.SimpleText("ПКМ - Лечить тиммейта", "DermaDefault", 20, screenH - 60, Color(0, 255, 0), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    
    if cooldownRemaining > 0 then
        draw.SimpleText("Кулдаун: " .. math.ceil(cooldownRemaining) .. "с", "DermaDefault", 20, screenH - 40, Color(255, 0, 0), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    else
        draw.SimpleText("Готово к использованию", "DermaDefault", 20, screenH - 40, Color(0, 255, 0), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    end
    
    draw.SimpleText("Лечение: " .. self.HealAmount .. " HP", "DermaDefault", 20, screenH - 20, Color(150, 255, 150), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
end 