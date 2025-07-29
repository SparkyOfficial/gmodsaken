--[[
    GModsaken - Content Loading System
    Copyright (C) 2024 GModsaken Contributors
]]

-- Ensure GM table exists
if not _G.GM then
    _G.GM = {}
end
local GM = _G.GM
_G.GAMEMODE = GM

-- Загрузка кастомных материалов и моделей
function GM:LoadCustomContent()
    if SERVER then
        -- Предзагружаем модели для клиентов
        util.PrecacheModel("models/player/gmodsaken/gordon/dr freeman.mdl")
        util.PrecacheModel("models/player/gmodsaken/gordon/c_arms_dr_freeman.mdl")
        
        -- TF2 оружие
        util.PrecacheModel("models/weapons/v_models/v_fireaxe_pyro.mdl")
        util.PrecacheModel("models/weapons/w_models/w_fireaxe.mdl")
        util.PrecacheModel("models/weapons/v_models/v_pda_engineer.mdl")
        util.PrecacheModel("models/weapons/w_models/w_pda_engineer.mdl")
        
        -- Модели рук для разных персонажей
        util.PrecacheModel("models/weapons/c_arms.mdl")
        util.PrecacheModel("models/weapons/c_arms_engineer.mdl")
        util.PrecacheModel("models/weapons/c_arms_rebel.mdl")
        util.PrecacheModel("models/weapons/c_arms_guard.mdl")
        util.PrecacheModel("models/weapons/c_arms_medic.mdl")
        util.PrecacheModel("models/weapons/c_arms_mayor.mdl")
        
        print("[GModsaken] Custom content loaded successfully!")
    end
end

-- Вызываем загрузку контента при инициализации
hook.Add("Initialize", "GModsaken_LoadContent", function()
    if GM.LoadCustomContent then
        GM:LoadCustomContent()
    end
end) 