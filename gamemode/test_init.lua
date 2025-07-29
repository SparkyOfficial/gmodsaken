--[[
    GModsaken - Test Initialization
    Copyright (C) 2024 GModsaken Contributors
]]

print("=== GModsaken Test Initialization ===")

-- Проверяем инициализацию GM
if GM then
    print("✓ GM table exists")
    print("GM.Name: " .. (GM.Name or "NOT SET"))
    print("GM.GameState: " .. (GM.GameState or "NOT SET"))
    print("GM.TEAM_SURVIVOR: " .. (GM.TEAM_SURVIVOR or "NOT SET"))
    print("GM.TEAM_KILLER: " .. (GM.TEAM_KILLER or "NOT SET"))
    print("GM.TEAM_SPECTATOR: " .. (GM.TEAM_SPECTATOR or "NOT SET"))
else
    print("✗ GM table does not exist!")
end

-- Проверяем функции
if GM and GM.CreateTeams then
    print("✓ GM.CreateTeams function exists")
else
    print("✗ GM.CreateTeams function does not exist!")
end

if GM and GM.IsKiller then
    print("✓ GM.IsKiller function exists")
else
    print("✗ GM.IsKiller function does not exist!")
end

if GM and GM.IsSurvivor then
    print("✓ GM.IsSurvivor function exists")
else
    print("✗ GM.IsSurvivor function does not exist!")
end

if GM and GM.GetKillerCharacters then
    print("✓ GM.GetKillerCharacters function exists")
else
    print("✗ GM.GetKillerCharacters function does not exist!")
end

if GM and GM.GetSurvivorCharacters then
    print("✓ GM.GetSurvivorCharacters function exists")
else
    print("✗ GM.GetSurvivorCharacters function does not exist!")
end

print("=== End Test ===") 