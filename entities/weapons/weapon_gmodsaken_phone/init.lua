--[[
    GModsaken - Mayor's Phone Weapon
    Copyright (C) 2024 GModsaken Contributors
]]

AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

SWEP.PrintName = "Телефон Мэра"
SWEP.Author = "GModsaken"
SWEP.Instructions = "ЛКМ - Радар тиммейтов\nПКМ - Активировать ауру брони\nR - Информация"
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
SWEP.ViewModel = "models/weapons/c_pda.mdl"
SWEP.WorldModel = "models/weapons/w_pda.mdl"
SWEP.UseHands = true

-- Звуки
SWEP.RadarSound = Sound("buttons/button15.wav")
SWEP.AuraSound = Sound("weapons/physcannon/energy_sing.wav")

-- Способности
SWEP.RadarCooldown = 10 -- секунды
SWEP.AuraCooldown = 20 -- секунды
SWEP.AuraDuration = 15 -- секунды
SWEP.AuraRadius = 200 -- радиус ауры
SWEP.LastRadar = 0
SWEP.LastAura = 0
SWEP.AuraActive = false
SWEP.AuraEndTime = 0

function SWEP:Initialize()
    self:SetHoldType("normal")
    
    -- Инициализируем переменные времени
    self.LastRadar = 0
    self.LastAura = 0
    self.AuraActive = false
    self.AuraEndTime = 0
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
    
    -- Показываем союзников на радаре
    owner:ChatPrint("Радар активирован! Ищите союзников на карте.")
    
    -- Отправляем команду клиенту для показа радара
    if util.NetworkStringToID("GModsaken_ShowRadar") > 0 then
        net.Start("GModsaken_ShowRadar")
        net.WriteFloat(self.RadarDuration or 10.0)
        net.Send(owner)
    end
    
    self:SetNextPrimaryFire(CurTime() + (self.Primary.Delay or 1.0))
end

function SWEP:SecondaryAttack()
    if not IsFirstTimePredicted() then return end
    
    local owner = self:GetOwner()
    if not IsValid(owner) then return end
    
    if CurTime() < self:GetNextSecondaryFire() then return end
    
    -- Проверяем кулдаун ауры
    if CurTime() - self.LastAura < self.AuraCooldown then
        owner:ChatPrint("Аура брони еще не готова! Подождите " .. math.ceil(self.AuraCooldown - (CurTime() - self.LastAura)) .. " секунд")
        return
    end
    
    -- Активируем ауру брони
    self:ActivateAura(owner)
    
    -- Обновляем время последнего использования
    self.LastAura = CurTime()
    
    self:SetNextSecondaryFire(CurTime() + (self.Secondary.Delay or 1.0))
end

function SWEP:Reload()
    if not IsFirstTimePredicted() then return end
    
    local owner = self:GetOwner()
    if not IsValid(owner) then return end
    
    -- Экстренный вызов
    owner:ChatPrint("Экстренный вызов отправлен! Все союзники уведомлены!")
    
    -- Уведомляем всех союзников
    for _, ply in pairs(player.GetAll()) do
        if IsValid(ply) and ply:Team() == owner:Team() and ply ~= owner then
            ply:ChatPrint("ЭКСТРЕННЫЙ ВЫЗОВ от " .. owner:Nick() .. "!")
        end
    end
end

function SWEP:ActivateRadar(owner)
    if SERVER then
        -- Отправляем команду клиенту для показа радара
        net.Start("GModsaken_ShowRadar")
        net.WriteFloat(10) -- длительность 10 секунд
        net.Send(owner)
        
        -- Уведомляем тиммейтов
        for _, ply in pairs(player.GetAll()) do
            if ply:Team() == GAMEMODE.TEAM_SURVIVOR and ply ~= owner then
                ply:ChatPrint("Мэр активировал радар!")
            end
        end
    end
end

function SWEP:ActivateAura(owner)
    if SERVER then
        self.AuraActive = true
        self.AuraEndTime = CurTime() + self.AuraDuration
        
        owner:ChatPrint("Аура брони активирована на " .. self.AuraDuration .. " секунд!")
        
        -- Запускаем таймер ауры
        timer.Create("MayorAura_" .. owner:EntIndex(), 1, self.AuraDuration, function()
            if IsValid(owner) and self.AuraActive then
                -- Лечим всех тиммейтов в радиусе
                for _, ply in pairs(player.GetAll()) do
                    if ply:Team() == GAMEMODE.TEAM_SURVIVOR and ply:GetPos():Distance(owner:GetPos()) <= self.AuraRadius then
                        -- Добавляем броню
                        local currentArmor = ply:Armor()
                        ply:SetArmor(math.min(currentArmor + 1, 100))
                        
                        -- Лечим здоровье
                        local currentHealth = ply:Health()
                        local maxHealth = ply:GetMaxHealth()
                        if currentHealth < maxHealth then
                            ply:SetHealth(math.min(currentHealth + 5, maxHealth))
                        end
                    end
                end
                
                -- Проверяем окончание ауры
                if CurTime() >= self.AuraEndTime then
                    self.AuraActive = false
                    owner:ChatPrint("Аура брони закончилась!")
                end
            end
        end)
        
        -- Уведомляем тиммейтов
        for _, ply in pairs(player.GetAll()) do
            if ply:Team() == GAMEMODE.TEAM_SURVIVOR and ply ~= owner then
                ply:ChatPrint("Мэр активировал ауру брони! Вы получаете +1 брони и +5 HP в секунду.")
            end
        end
    end
end

function SWEP:ShowInfo(owner)
    if SERVER then
        owner:ChatPrint("=== ТЕЛЕФОН МЭРА ===")
        owner:ChatPrint("ЛКМ - Радар тиммейтов (кулдаун: " .. self.RadarCooldown .. "с)")
        owner:ChatPrint("ПКМ - Аура брони (кулдаун: " .. self.AuraCooldown .. "с, длительность: " .. self.AuraDuration .. "с)")
        owner:ChatPrint("Радиус ауры: " .. self.AuraRadius .. " единиц")
        owner:ChatPrint("===================")
    end
end

function SWEP:DrawHUD()
    local owner = self:GetOwner()
    if not IsValid(owner) then return end
    
    local screenW, screenH = ScrW(), ScrH()
    
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