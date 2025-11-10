--[[
    GModsaken - Web API Integration Hooks
    Copyright (C) 2024 GModsaken Contributors
    
    This module integrates API calls into gamemode events
]]

if SERVER then
    -- Store match data during the round
    GM.CurrentMatchData = nil
    GM.MatchStartTime = nil

    -- Hook: Player joins server - Fetch their profile
    hook.Add("PlayerInitialSpawn", "GModsaken_FetchPlayerProfile", function(ply)
        if not IsValid(ply) or not GM.Config.API.Enabled then return end
        
        local steamID = ply:SteamID64()
        
        -- Fetch player profile from API
        timer.Simple(2, function()
            if not IsValid(ply) then return end
            
            GM:FetchPlayerProfile(steamID, function(success, profile)
                if success and profile then
                    -- Store profile data on player
                    ply.APIProfile = profile
                    
                    -- Welcome message with level
                    if profile.level then
                        ply:ChatPrint(string.format("Добро пожаловать, %s! Ваш уровень: %d", 
                            ply:Nick(), profile.level))
                    end
                    
                    print(string.format("[GModsaken] Loaded profile for %s (Level %d, XP: %d)", 
                        ply:Nick(), profile.level or 1, profile.xp or 0))
                else
                    print(string.format("[GModsaken] Could not load profile for %s, will create on first match", 
                        ply:Nick()))
                end
            end)
        end)
    end)

    -- Hook: Round starts - Initialize match data
    hook.Add("GModsaken_GameStarted", "GModsaken_InitMatchData", function()
        if not GM.Config.API.Enabled then return end
        
        -- Generate unique match ID
        local matchId = string.format("match_%s_%d", game.GetMap(), os.time())
        
        GM.CurrentMatchData = {
            matchId = matchId,
            mapName = game.GetMap(),
            gameState = "PLAYING",
            winner = "DRAW",
            duration = 0,
            players = {},
            startedAt = os.date("!%Y-%m-%dT%H:%M:%SZ"),
            endedAt = nil
        }
        
        GM.MatchStartTime = CurTime()
        
        -- Initialize player data
        for _, ply in ipairs(player.GetAll()) do
            if IsValid(ply) and ply:Team() ~= GM.TEAM_SPECTATOR then
                table.insert(GM.CurrentMatchData.players, {
                    steamId = ply:SteamID64(),
                    username = ply:Nick(),
                    avatar = "https://steamcdn-a.akamaihd.net/steamcommunity/public/images/avatars/fe/fef49e7fa7e1997310d705b2a6158ff8dc1cdfeb_full.jpg",
                    team = team.GetName(ply:Team()),
                    character = ply.SelectedCharacter or "Unknown",
                    kills = 0,
                    deaths = 0,
                    xpEarned = 0,
                    questsCompleted = {}
                })
            end
        end
        
        print(string.format("[GModsaken] Match started: %s with %d players", 
            matchId, #GM.CurrentMatchData.players))
    end)

    -- Hook: Player kills another player - Update match stats
    hook.Add("PlayerDeath", "GModsaken_UpdateMatchStats", function(victim, inflictor, attacker)
        if not GM.CurrentMatchData or not GM.Config.API.Enabled then return end
        
        -- Update death count for victim
        if IsValid(victim) then
            for _, playerData in ipairs(GM.CurrentMatchData.players) do
                if playerData.steamId == victim:SteamID64() then
                    playerData.deaths = playerData.deaths + 1
                    break
                end
            end
        end
        
        -- Update kill count for attacker
        if IsValid(attacker) and attacker:IsPlayer() then
            for _, playerData in ipairs(GM.CurrentMatchData.players) do
                if playerData.steamId == attacker:SteamID64() then
                    playerData.kills = playerData.kills + 1
                    
                    -- Award XP for kill
                    local killXP = 10
                    playerData.xpEarned = playerData.xpEarned + killXP
                    
                    -- Send XP update to API
                    GM:UpdatePlayerXP(attacker:SteamID64(), killXP, "Kill")
                    
                    break
                end
            end
        end
    end)

    -- Hook: Quest completed - Record in match data and send to API
    hook.Add("GModsaken_QuestCompleted", "GModsaken_RecordQuestCompletion", function(ply, questName)
        if not IsValid(ply) or not GM.Config.API.Enabled then return end
        
        local steamID = ply:SteamID64()
        
        -- Update match data
        if GM.CurrentMatchData then
            for _, playerData in ipairs(GM.CurrentMatchData.players) do
                if playerData.steamId == steamID then
                    table.insert(playerData.questsCompleted, questName)
                    
                    -- Award XP for quest
                    local questXP = 50
                    playerData.xpEarned = playerData.xpEarned + questXP
                    
                    break
                end
            end
        end
        
        -- Send quest completion to API
        GM:RecordQuestCompletion(steamID, questName, function(success, response)
            if success then
                print(string.format("[GModsaken] Quest '%s' recorded for %s", questName, ply:Nick()))
            end
        end)
    end)

    -- Hook: Round ends - Send match results to API
    hook.Add("GModsaken_GameEnded", "GModsaken_SendMatchResults", function()
        if not GM.CurrentMatchData or not GM.Config.API.Enabled then return end
        
        -- Calculate match duration
        if GM.MatchStartTime then
            GM.CurrentMatchData.duration = math.floor(CurTime() - GM.MatchStartTime)
        end
        
        -- Set end time
        GM.CurrentMatchData.endedAt = os.date("!%Y-%m-%dT%H:%M:%SZ")
        
        -- Determine winner based on game state
        -- This will be set by the EndRound function
        if GM.LastRoundWinner then
            GM.CurrentMatchData.winner = GM.LastRoundWinner
        end
        
        -- Calculate XP for each player based on match outcome
        for _, playerData in ipairs(GM.CurrentMatchData.players) do
            local isWinner = false
            
            if GM.CurrentMatchData.winner == "KILLER" and playerData.team == "KILLER" then
                isWinner = true
            elseif (GM.CurrentMatchData.winner == "SURVIVORS" or GM.CurrentMatchData.winner == "TIMEOUT") 
                   and playerData.team == "SURVIVOR" then
                isWinner = true
            end
            
            -- Award match completion XP
            local matchXP = isWinner and 100 or 25
            playerData.xpEarned = playerData.xpEarned + matchXP
            
            -- Award survival time XP (1 XP per minute)
            local survivalXP = math.floor(GM.CurrentMatchData.duration / 60)
            playerData.xpEarned = playerData.xpEarned + survivalXP
        end
        
        -- Send match results to API
        GM:SendMatchResults(GM.CurrentMatchData, function(success, response, code)
            if success then
                print(string.format("[GModsaken] Match results sent successfully: %s", 
                    GM.CurrentMatchData.matchId))
            else
                print(string.format("[GModsaken] Failed to send match results: %s", 
                    tostring(response)))
            end
        end)
        
        -- Clear match data
        GM.CurrentMatchData = nil
        GM.MatchStartTime = nil
        GM.LastRoundWinner = nil
    end)

    -- Override EndRound to capture winner
    local originalEndRound = GM.EndRound
    function GM:EndRound(winner)
        -- Store winner for API call
        self.LastRoundWinner = winner
        
        -- Call original function
        if originalEndRound then
            originalEndRound(self, winner)
        end
    end

    -- Override AwardQuestReward to trigger quest completion hook
    local originalAwardQuestReward = GM.AwardQuestReward
    function GM:AwardQuestReward(ply, questName)
        -- Call original function
        if originalAwardQuestReward then
            originalAwardQuestReward(self, ply, questName)
        end
        
        -- Trigger quest completion hook
        hook.Call("GModsaken_QuestCompleted", GAMEMODE, ply, questName)
    end

    print("[GModsaken] API integration hooks initialized")
end
