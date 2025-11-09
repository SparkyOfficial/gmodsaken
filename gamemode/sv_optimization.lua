--[[
    GModsaken - Performance Optimization (Server)
    Copyright (C) 2024 GModsaken Contributors
    
    Replaces Think hooks with efficient timers for better performance.
]]

-- Get GM table reference
local GM = _G.GM or GAMEMODE
_G.GM = GM
_G.GAMEMODE = GM

print("[GModsaken] Loading optimization module...")

-- Turret and Dispenser Logic Timer (0.5s interval)
timer.Create("GModsaken_TurretDispenserLogic", 0.5, 0, function()
    if not GM or GM.GameState ~= "PLAYING" then return end
    
    -- Get config values
    local turretRange = GM:GetConfig("Gameplay.TurretRange", 500)
    local turretDamage = GM:GetConfig("Gameplay.TurretDamage", 10)
    local dispenserRange = GM:GetConfig("Gameplay.DispenserRange", 200)
    local dispenserHealRate = GM:GetConfig("Gameplay.DispenserHealRate", 5)
    local dispenserHealInterval = GM:GetConfig("Gameplay.DispenserHealInterval", 2.0)
    
    -- Process turrets
    for _, ent in pairs(ents.FindByClass("npc_turret_floor")) do
        if IsValid(ent) and ent.IsGModsakenTurret then
            -- Check if enough time has passed since last damage
            if CurTime() - (ent.LastDamageTime or 0) >= 1.0 then
                local killers = {}
                
                -- Find killers in range
                for _, ply in pairs(player.GetAll()) do
                    if IsValid(ply) and ply:Team() == GM.TEAM_KILLER and ply:Alive() then
                        local distance = ent:GetPos():Distance(ply:GetPos())
                        if distance <= turretRange then
                            table.insert(killers, ply)
                        end
                    end
                end
                
                -- Attack first killer in range
                if #killers > 0 then
                    local target = killers[1]
                    target:TakeDamage(turretDamage, ent, ent)
                    
                    -- Apply slow effect
                    if GM.SlowPlayer then
                        GM:SlowPlayer(target, 3.0, 0.8)
                    end
                    
                    ent:EmitSound("weapons/turret/turret_fire1.wav")
                    ent.LastDamageTime = CurTime()
                end
            end
        end
    end
    
    -- Process dispensers
    for _, ent in pairs(ents.FindByClass("npc_turret_ceiling")) do
        if IsValid(ent) and ent.IsGModsakenDispenser then
            -- Check if enough time has passed since last heal
            if CurTime() - (ent.LastHealTime or 0) >= dispenserHealInterval then
                -- Find survivors in range
                for _, ply in pairs(player.GetAll()) do
                    if IsValid(ply) and ply:Team() == GM.TEAM_SURVIVOR and ply:Alive() then
                        local distance = ent:GetPos():Distance(ply:GetPos())
                        if distance <= dispenserRange then
                            -- Heal health
                            if ply:Health() < ply:GetMaxHealth() then
                                ply:SetHealth(math.min(ply:GetMaxHealth(), ply:Health() + dispenserHealRate))
                            end
                            
                            -- Heal armor
                            if ply:Armor() < 100 then
                                ply:SetArmor(math.min(100, ply:Armor() + 2))
                            end
                        end
                    end
                end
                ent.LastHealTime = CurTime()
            end
        end
    end
end)

-- Chase Music Check Timer (0.25s interval)
timer.Create("GModsaken_ChaseMusicCheck", 0.25, 0, function()
    if not GM or not GM.CheckMyasnoiMusic then return end
    if GM.GameState ~= "PLAYING" then return end
    
    GM:CheckMyasnoiMusic()
end)

-- Win Condition Check Timer (1.0s interval)
timer.Create("GModsaken_WinConditionCheck", 1.0, 0, function()
    if not GM or not GM.CheckWinConditions then return end
    if GM.GameState ~= "PLAYING" and GM.GameState ~= "LMS_PLAYING" then return end
    
    GM:CheckWinConditions()
end)

-- Lobby Timer Update (1.0s interval)
timer.Create("GModsaken_LobbyTimer", 1.0, 0, function()
    if not GM then return end
    
    if GM.GameState == "PREPARING" then
        -- Countdown lobby timer
        if GM.LobbyTimer and GM.LobbyTimer > 0 then
            GM.LobbyTimer = GM.LobbyTimer - 1
            
            -- Broadcast updated state
            if GM.BroadcastGameState then
                GM:BroadcastGameState()
            end
            
            -- Start round when timer reaches 0
            if GM.LobbyTimer <= 0 and GM.StartRound then
                GM:StartRound()
            end
        end
    elseif GM.GameState == "PLAYING" or GM.GameState == "LMS_PLAYING" then
        -- Countdown round timer
        if GM.RoundTimer and GM.RoundTimer > 0 then
            GM.RoundTimer = GM.RoundTimer - 1
            
            -- Broadcast updated state
            if GM.BroadcastGameState then
                GM:BroadcastGameState()
            end
            
            -- Check win conditions when timer reaches 0
            if GM.RoundTimer <= 0 and GM.CheckWinConditions then
                GM:CheckWinConditions()
            end
        end
    elseif GM.GameState == "ENDING" then
        -- Countdown end timer
        if GM.EndTimer and GM.EndTimer > 0 then
            GM.EndTimer = GM.EndTimer - 1
            
            -- Broadcast updated state
            if GM.BroadcastGameState then
                GM:BroadcastGameState()
            end
            
            -- Return to lobby when timer reaches 0
            if GM.EndTimer <= 0 and GM.InitializeLobby then
                GM:InitializeLobby()
            end
        end
    end
end)

-- Cleanup function to remove timers on shutdown
hook.Add("ShutDown", "GModsaken_CleanupTimers", function()
    timer.Remove("GModsaken_TurretDispenserLogic")
    timer.Remove("GModsaken_ChaseMusicCheck")
    timer.Remove("GModsaken_WinConditionCheck")
    timer.Remove("GModsaken_LobbyTimer")
    print("[GModsaken] Optimization timers cleaned up")
end)

-- Remove old Think hook if it exists
hook.Remove("Think", "GModsaken_TurretDispenserLogic")

print("[GModsaken] Optimization module loaded successfully")
