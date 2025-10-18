--[[
    GModsaken - Stealth and Detection System
    Copyright (C) 2024 GModsaken Contributors
]]

-- Ensure GM table exists
if not _G.GM then
    _G.GM = {}
end
local GM = _G.GM

-- Stealth states
GM.StealthStates = {
    VISIBLE = 0,    -- Fully visible to all
    HIDDEN = 1,     -- Completely hidden
    SUSPICIOUS = 2, -- Partially visible (footsteps, sounds, etc.)
    DETECTED = 3    -- Recently detected by survivors
}

-- Initialize player stealth data
hook.Add("PlayerInitialSpawn", "GModsaken_InitStealth", function(ply)
    ply:SetNWInt("StealthState", GM.StealthStates.VISIBLE)
    ply:SetNWFloat("LastStealthChange", 0)
    ply:SetNWFloat("NextStealthCheck", 0)
    ply:SetNWFloat("DetectionLevel", 0)
    ply:SetNWVector("LastKnownPos", Vector(0, 0, 0))
end)

-- Stealth check function
function GM:CheckStealthState(ply)
    if not IsValid(ply) or not ply:IsKiller() then return end
    
    local currentTime = CurTime()
    if ply:GetNWFloat("NextStealthCheck") > currentTime then return end
    
    ply:SetNWFloat("NextStealthCheck", currentTime + 0.5) -- Check twice per second
    
    local currentState = ply:GetNWInt("StealthState", self.StealthStates.VISIBLE)
    local newState = currentState
    local detectionLevel = ply:GetNWFloat("DetectionLevel", 0)
    
    -- Check movement and actions
    local velocity = ply:GetVelocity():Length()
    local isCrouching = ply:Crouching()
    local isRunning = ply:KeyDown(IN_SPEED)
    local isWalking = ply:KeyDown(IN_WALK)
    local isAttacking = ply:KeyDown(IN_ATTACK) or ply:KeyDown(IN_ATTACK2)
    
    -- State transition logic
    if currentState == self.StealthStates.VISIBLE then
        if not isAttacking and not isRunning and velocity < 10 then
            newState = self.StealthStates.HIDDEN
            detectionLevel = 0
        end
    elseif currentState == self.StealthStates.HIDDEN then
        if velocity > 50 or isAttacking then
            newState = self.StealthStates.VISIBLE
            detectionLevel = 1.0
        elseif velocity > 10 then
            newState = self.StealthStates.SUSPICIOUS
        end
    elseif currentState == self.StealthStates.SUSPICIOUS then
        if velocity < 10 and not isAttacking then
            newState = self.StealthStates.HIDDEN
            detectionLevel = 0
        elseif isRunning or isAttacking then
            newState = self.StealthStates.VISIBLE
            detectionLevel = 1.0
        end
    end
    
    -- Apply movement modifiers
    if isCrouching and newState ~= self.StealthStates.VISIBLE then
        detectionLevel = detectionLevel * 0.7
    end
    
    if isWalking then
        detectionLevel = detectionLevel * 0.5
    end
    
    -- Update state if changed
    if newState ~= currentState then
        ply:SetNWInt("StealthState", newState)
        ply:SetNWFloat("LastStealthChange", currentTime)
        
        -- Visual feedback
        if SERVER then
            net.Start("GModsaken_StealthStateChanged")
            net.WriteEntity(ply)
            net.WriteInt(newState, 8)
            net.Broadcast()
        end
    end
    
    -- Update detection level
    ply:SetNWFloat("DetectionLevel", math.Clamp(detectionLevel, 0, 1.0))
end

-- Detect killers based on proximity and line of sight
function GM:UpdatePlayerDetection()
    if CLIENT then return end
    
    local currentTime = CurTime()
    local killers = team.GetPlayers(TEAM_KILLER)
    local survivors = team.GetPlayers(TEAM_SURVIVOR)
    
    for _, killer in ipairs(killers) do
        if not IsValid(killer) then continue end
        
        local killerState = killer:GetNWInt("StealthState", self.StealthStates.VISIBLE)
        local detectionRange = 1000 -- Base detection range
        
        -- Adjust detection range based on killer's state
        if killerState == self.StealthStates.HIDDEN then
            detectionRange = 300
        elseif killerState == self.StealthStates.SUSPICIOUS then
            detectionRange = 600
        end
        
        -- Check each survivor's detection of this killer
        for _, survivor in ipairs(survivors) do
            if not IsValid(survivor) then continue end
            
            local distance = survivor:GetPos():Distance(killer:GetPos())
            if distance > detectionRange * 1.5 then continue end
            
            -- Line of sight check
            local trace = util.TraceLine({
                start = survivor:EyePos(),
                endpos = killer:EyePos(),
                filter = {survivor, killer},
                mask = MASK_VISIBLE_AND_NPCS
            })
            
            if trace.Hit and trace.Entity ~= killer then continue end
            
            -- Calculate detection chance
            local detectionChance = 0.5
            
            -- Distance factor
            local distanceFactor = 1 - (distance / detectionRange)
            detectionChance = detectionChance * distanceFactor
            
            -- Killer state factor
            if killerState == self.StealthStates.HIDDEN then
                detectionChance = detectionChance * 0.3
            elseif killerState == self.StealthStates.SUSPICIOUS then
                detectionChance = detectionChance * 0.7
            end
            
            -- Survivor awareness (based on character)
            local char = self:GetCharacter(survivor:GetNWString("Character", "rebel"))
            if char and char.awareness then
                detectionChance = detectionChance * char.awareness
            end
            
            -- Random chance to detect
            if math.Rand(0, 1) < detectionChance then
                killer:SetNWInt("StealthState", self.StealthStates.DETECTED)
                killer:SetNWVector("LastKnownPos", killer:GetPos())
                killer:SetNWFloat("LastDetectionTime", currentTime)
                
                -- Notify survivor
                net.Start("GModsaken_KillerDetected")
                net.WriteEntity(killer)
                net.WriteVector(killer:GetPos())
                net.Send(survivor)
                
                -- Killer knows they've been detected
                net.Start("GModsaken_PlayerDetected")
                net.WriteEntity(survivor)
                net.Send(killer)
                
                -- Reset detection after delay
                timer.Simple(10, function()
                    if IsValid(killer) and killer:GetNWInt("StealthState") == self.StealthStates.DETECTED then
                        killer:SetNWInt("StealthState", self.StealthStates.HIDDEN)
                    end
                end)
                
                break
            end
        end
    end
end

-- HUD elements for stealth
if CLIENT then
    local stealthIcons = {
        [GM.StealthStates.VISIBLE] = Material("hud/gmodsaken/eye.png", "smooth"),
        [GM.StealthStates.HIDDEN] = Material("hud/gmodsaken/eye_closed.png", "smooth"),
        [GM.StealthStates.SUSPICIOUS] = Material("hud/gmodsaken/eye_half.png", "smooth"),
        [GM.StealthStates.DETECTED] = Material("hud/gmodsaken/eye_alert.png", "smooth")
    }
    
    hook.Add("HUDPaint", "GModsaken_StealthHUD", function()
        local ply = LocalPlayer()
        if not IsValid(ply) then return end
        
        -- Only show for killer
        if not ply:IsKiller() then return end
        
        local state = ply:GetNWInt("StealthState", GM.StealthStates.VISIBLE)
        local detection = ply:GetNWFloat("DetectionLevel", 0)
        
        -- Draw stealth indicator
        local x = ScrW() - 100
        local y = 100
        local size = 64
        
        surface.SetMaterial(stealthIcons[state] or stealthIcons[GM.StealthStates.VISIBLE])
        surface.SetDrawColor(255, 255, 255, 200)
        surface.DrawTexturedRect(x, y, size, size)
        
        -- Draw detection meter
        if state ~= GM.StealthStates.VISIBLE then
            local barWidth = 100
            local barHeight = 10
            local barX = x + (size - barWidth) / 2
            local barY = y + size + 5
            
            -- Background
            surface.SetDrawColor(0, 0, 0, 200)
            surface.DrawRect(barX, barY, barWidth, barHeight)
            
            -- Fill
            local fillColor = Color(255, 255 - (detection * 255), 0)
            surface.SetDrawColor(fillColor)
            surface.DrawRect(barX, barY, barWidth * detection, barHeight)
            
            -- Border
            surface.SetDrawColor(255, 255, 255, 100)
            surface.DrawOutlinedRect(barX, barY, barWidth, barHeight)
        end
    end)
    
    -- Sound effects for state changes
    local lastState = GM.StealthStates.VISIBLE
    hook.Add("Think", "GModsaken_StealthSounds", function()
        local ply = LocalPlayer()
        if not IsValid(ply) or not ply:IsKiller() then return end
        
        local currentState = ply:GetNWInt("StealthState", GM.StealthStates.VISIBLE)
        if currentState ~= lastState then
            if currentState == GM.StealthStates.HIDDEN then
                surface.PlaySound("gmodsaken/stealth_hidden.wav")
            elseif currentState == GM.StealthStates.DETECTED then
                surface.PlaySound("gmodsaken/stealth_detected.wav")
            end
            lastState = currentState
        end
    end)
    
    -- Killer detection indicator
    local lastDetection = 0
    net.Receive("GModsaken_KillerDetected", function()
        local killer = net.ReadEntity()
        local pos = net.ReadVector()
        
        if not IsValid(killer) then return end
        
        -- Show indicator
        local indicator = vgui.Create("DPanel")
        indicator:SetSize(32, 32)
        indicator:SetPos(ScrW()/2 - 16, 50)
        indicator.Paint = function(self, w, h)
            surface.SetMaterial(Material("hud/gmodsaken/alert.png"))
            surface.SetDrawColor(255, 0, 0, 255)
            surface.DrawTexturedRect(0, 0, w, h)
        end
        
        -- Fade out and remove
        indicator:AlphaTo(0, 3, 0, function()
            if IsValid(indicator) then
                indicator:Remove()
            end
        end)
        
        -- Play sound
        surface.PlaySound("gmodsaken/detected.wav")
    end)
end

-- Initialize network messages
if SERVER then
    util.AddNetworkString("GModsaken_StealthStateChanged")
    util.AddNetworkString("GModsaken_KillerDetected")
    util.AddNetworkString("GModsaken_PlayerDetected")
    
    -- Update detection every second
    timer.Create("GModsaken_StealthUpdate", 0.5, 0, function()
        if not GM then return end
        GM:UpdatePlayerDetection()
    end)
end

-- Add console command to toggle stealth (for testing)
concommand.Add("gmodsaken_togglestealth", function(ply)
    if not IsValid(ply) or not ply:IsKiller() then return end
    
    local currentState = ply:GetNWInt("StealthState", GM.StealthStates.VISIBLE)
    local newState = (currentState == GM.StealthStates.VISIBLE) and 
                    GM.StealthStates.HIDDEN or GM.StealthStates.VISIBLE
    
    ply:SetNWInt("StealthState", newState)
    ply:SetNWFloat("LastStealthChange", CurTime())
    
    if newState == GM.StealthStates.HIDDEN then
        ply:ChatPrint("Stealth: HIDDEN")
    else
        ply:ChatPrint("Stealth: VISIBLE")
    end
end)
