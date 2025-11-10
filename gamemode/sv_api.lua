--[[
    GModsaken - Web API Integration
    Copyright (C) 2024 GModsaken Contributors
    
    This module handles communication with the web backend API
]]

if SERVER then
    -- Request queue for offline mode
    GM.APIRequestQueue = GM.APIRequestQueue or {}
    GM.APIOnline = true
    GM.APILastCheck = 0

    -- Helper function to log API events
    local function APILog(level, message, data)
        local prefix = "[GModsaken API]"
        local logMessage = string.format("%s [%s] %s", prefix, level, message)
        
        if data then
            logMessage = logMessage .. " | Data: " .. util.TableToJSON(data)
        end
        
        print(logMessage)
    end

    -- HTTP request wrapper with retry logic
    local function MakeAPIRequest(method, endpoint, data, callback, retryCount)
        retryCount = retryCount or 0
        
        -- Check if API is enabled
        if not GM.Config.API.Enabled then
            APILog("WARN", "API is disabled in configuration")
            if callback then callback(false, "API disabled") end
            return
        end

        local url = GM.Config.API.BaseURL .. endpoint
        local timeout = GM.Config.API.Timeout or 5
        
        -- Prepare request parameters
        local requestParams = {
            method = method,
            url = url,
            timeout = timeout,
            headers = {
                ["Content-Type"] = "application/json",
                ["X-API-Key"] = GM.Config.API.APIKey
            },
            success = function(code, body, headers)
                GM.APIOnline = true
                APILog("INFO", string.format("%s %s - Success (HTTP %d)", method, endpoint, code))
                
                -- Parse JSON response
                local response = util.JSONToTable(body)
                if callback then
                    callback(true, response, code)
                end
            end,
            failed = function(error)
                APILog("ERROR", string.format("%s %s - Failed: %s", method, endpoint, error))
                
                -- Retry logic
                if retryCount < GM.Config.API.RetryAttempts then
                    local delay = GM.Config.API.RetryDelay * (retryCount + 1)
                    APILog("INFO", string.format("Retrying in %d seconds (attempt %d/%d)", 
                        delay, retryCount + 1, GM.Config.API.RetryAttempts))
                    
                    timer.Simple(delay, function()
                        MakeAPIRequest(method, endpoint, data, callback, retryCount + 1)
                    end)
                else
                    -- All retries failed
                    GM.APIOnline = false
                    APILog("ERROR", "All retry attempts failed")
                    
                    -- Queue request if offline queueing is enabled
                    if GM.Config.API.QueueOfflineRequests then
                        GM:QueueAPIRequest(method, endpoint, data, callback)
                    end
                    
                    if callback then
                        callback(false, error)
                    end
                end
            end
        }
        
        -- Add body for POST/PUT requests
        if method == "POST" or method == "PUT" then
            requestParams.body = util.TableToJSON(data)
        end
        
        -- Make the HTTP request
        HTTP(requestParams)
    end

    -- Queue API request for later
    function GM:QueueAPIRequest(method, endpoint, data, callback)
        if #self.APIRequestQueue >= GM.Config.API.MaxQueueSize then
            APILog("WARN", "Request queue is full, dropping oldest request")
            table.remove(self.APIRequestQueue, 1)
        end
        
        table.insert(self.APIRequestQueue, {
            method = method,
            endpoint = endpoint,
            data = data,
            callback = callback,
            timestamp = os.time()
        })
        
        APILog("INFO", string.format("Queued request: %s %s (Queue size: %d)", 
            method, endpoint, #self.APIRequestQueue))
    end

    -- Process queued requests
    function GM:ProcessAPIQueue()
        if #self.APIRequestQueue == 0 then return end
        if not self.APIOnline then return end
        
        APILog("INFO", string.format("Processing %d queued requests", #self.APIRequestQueue))
        
        local queue = table.Copy(self.APIRequestQueue)
        self.APIRequestQueue = {}
        
        for _, request in ipairs(queue) do
            MakeAPIRequest(request.method, request.endpoint, request.data, request.callback)
        end
    end

    -- Send match results to API
    function GM:SendMatchResults(matchData, callback)
        APILog("INFO", "Sending match results", {matchId = matchData.matchId})
        
        -- Validate required fields
        if not matchData.matchId or not matchData.mapName or not matchData.winner then
            APILog("ERROR", "Missing required match data fields")
            if callback then callback(false, "Missing required fields") end
            return
        end
        
        MakeAPIRequest("POST", "/matches", matchData, function(success, response, code)
            if success then
                APILog("INFO", "Match results sent successfully", {matchId = matchData.matchId})
            else
                APILog("ERROR", "Failed to send match results", {matchId = matchData.matchId})
            end
            
            if callback then callback(success, response, code) end
        end)
    end

    -- Update player XP
    function GM:UpdatePlayerXP(steamID, xp, reason, callback)
        APILog("INFO", string.format("Updating XP for player %s: +%d (%s)", steamID, xp, reason))
        
        if not steamID or not xp then
            APILog("ERROR", "Missing required parameters: steamID and xp")
            if callback then callback(false, "Missing required parameters") end
            return
        end
        
        local data = {
            xp = xp,
            reason = reason or "Unknown"
        }
        
        MakeAPIRequest("POST", "/players/" .. steamID .. "/xp", data, function(success, response, code)
            if success then
                APILog("INFO", string.format("XP updated for player %s", steamID))
            else
                APILog("ERROR", string.format("Failed to update XP for player %s", steamID))
            end
            
            if callback then callback(success, response, code) end
        end)
    end

    -- Record quest completion
    function GM:RecordQuestCompletion(steamID, questName, callback)
        APILog("INFO", string.format("Recording quest completion for player %s: %s", steamID, questName))
        
        if not steamID or not questName then
            APILog("ERROR", "Missing required parameters: steamID and questName")
            if callback then callback(false, "Missing required parameters") end
            return
        end
        
        local data = {
            questName = questName,
            completedAt = os.date("!%Y-%m-%dT%H:%M:%SZ")
        }
        
        MakeAPIRequest("POST", "/players/" .. steamID .. "/quests", data, function(success, response, code)
            if success then
                APILog("INFO", string.format("Quest completion recorded for player %s", steamID))
            else
                APILog("ERROR", string.format("Failed to record quest for player %s", steamID))
            end
            
            if callback then callback(success, response, code) end
        end)
    end

    -- Fetch player profile from API
    function GM:FetchPlayerProfile(steamID, callback)
        APILog("INFO", string.format("Fetching profile for player %s", steamID))
        
        if not steamID then
            APILog("ERROR", "Missing required parameter: steamID")
            if callback then callback(false, "Missing required parameter") end
            return
        end
        
        MakeAPIRequest("GET", "/players/" .. steamID, nil, function(success, response, code)
            if success then
                APILog("INFO", string.format("Profile fetched for player %s", steamID))
                if callback then callback(true, response.player) end
            else
                APILog("ERROR", string.format("Failed to fetch profile for player %s", steamID))
                if callback then callback(false, response) end
            end
        end)
    end

    -- Update server status
    function GM:UpdateServerStatus(statusData, callback)
        local data = {
            online = true,
            playerCount = #player.GetAll(),
            maxPlayers = GM.Config.Gameplay.MaxPlayers,
            mapName = game.GetMap(),
            gameState = GM.GameState or "LOBBY",
            uptime = CurTime(),
            activePlayers = {}
        }
        
        -- Add active player info
        for _, ply in ipairs(player.GetAll()) do
            if IsValid(ply) then
                table.insert(data.activePlayers, {
                    steamId = ply:SteamID64(),
                    username = ply:Nick(),
                    team = team.GetName(ply:Team())
                })
            end
        end
        
        -- Merge with provided status data
        if statusData then
            table.Merge(data, statusData)
        end
        
        MakeAPIRequest("POST", "/server/status", data, function(success, response, code)
            if success then
                APILog("INFO", "Server status updated")
            else
                APILog("WARN", "Failed to update server status")
            end
            
            if callback then callback(success, response, code) end
        end)
    end

    -- Timer to process queued requests
    timer.Create("GModsaken_ProcessAPIQueue", 30, 0, function()
        if GM and GM.ProcessAPIQueue then
            GM:ProcessAPIQueue()
        end
    end)

    -- Timer to update server status
    timer.Create("GModsaken_UpdateServerStatus", 30, 0, function()
        if GM and GM.UpdateServerStatus and GM.Config.API.Enabled then
            GM:UpdateServerStatus()
        end
    end)

    -- Cleanup on shutdown
    hook.Add("ShutDown", "GModsaken_APICleanup", function()
        timer.Remove("GModsaken_ProcessAPIQueue")
        timer.Remove("GModsaken_UpdateServerStatus")
        
        -- Try to send offline status
        if GM and GM.UpdateServerStatus then
            GM:UpdateServerStatus({online = false})
        end
    end)

    APILog("INFO", "API client initialized")
end
