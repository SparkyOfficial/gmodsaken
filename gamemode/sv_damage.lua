--[[ GModsaken - Damage System ]]

-- Ensure GM table exists
if not _G.GM then
    _G.GM = {}
end
local GM = _G.GM
_G.GAMEMODE = GM

-- Хук для обработки урона с учетом брони
hook.Add("EntityTakeDamage", "GModsaken_ArmorDamage", function(target, dmgInfo)
    if not IsValid(target) or not target:IsPlayer() then return end
    if not GM.ProcessDamageWithArmor then return end
    
    local attacker = dmgInfo:GetAttacker()
    local inflictor = dmgInfo:GetInflictor()
    local damage = dmgInfo:GetDamage()
    
    -- Обрабатываем урон с учетом брони
    local finalDamage = GM:ProcessDamageWithArmor(target, damage, attacker, inflictor)
    
    -- Устанавливаем финальный урон
    dmgInfo:SetDamage(finalDamage)
    
    -- Показываем информацию об уроне
    if SERVER and IsValid(attacker) and attacker:IsPlayer() then
        local armorInfo = GM:GetArmorInfo(target)
        if armorInfo.armor > 0 then
            attacker:ChatPrint("Урон по " .. target:Nick() .. ": " .. math.floor(finalDamage) .. " (броня поглотила " .. math.floor(damage - finalDamage) .. ")")
        end
    end
end)

-- Хук для траты стамины при атаке
hook.Add("PlayerAttack", "GModsaken_AttackStamina", function(attacker, weapon)
    if not IsValid(attacker) or not attacker:IsPlayer() then return end
    if not GM.DrainStaminaFromAttack then return end
    
    -- Тратим стамину при атаке
    GM:DrainStaminaFromAttack(attacker)
end)

print("[GModsaken] Damage system loaded")
