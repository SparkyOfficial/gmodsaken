--[[
    GModsaken - Music System (Client)
    Copyright (C) 2024 GModsaken Contributors
]]

-- Ensure GM table exists
if not _G.GM then
    _G.GM = GAMEMODE or {}
    print("[GModsaken] Created GM table in cl_music.lua")
end
local GM = _G.GM
_G.GAMEMODE = GM

print("[GModsaken] cl_music.lua loaded")

-- Переменные для управления музыкой
local currentMusic = nil
local currentMusicChannel = nil
local musicVolume = 0.5
local musicEnabled = true
local isMusicPlaying = false
local fadeTimer = nil

-- Инициализация системы музыки
function InitializeMusicSystem()
    -- Загружаем настройки из файла
    musicVolume = cookie.GetNumber("gmodsaken_music_volume", 0.5)
    musicEnabled = cookie.GetNumber("gmodsaken_music_enabled", 1) == 1
    
    print("[GModsaken] Music system initialized - Volume: " .. musicVolume .. ", Enabled: " .. tostring(musicEnabled))
end

-- Воспроизведение музыки
function PlayMusic(track, fadeIn)
    if not musicEnabled or not track then return end
    
    -- Останавливаем текущую музыку
    StopMusic(fadeIn and 1.0 or 0.0)
    
    -- Проверяем существование трека
    if not GM:IsMusicTrackValid(track) then
        print("[GModsaken] Invalid music track: " .. tostring(track))
        return
    end
    
    -- Создаем звук
    local sound = CreateSound(LocalPlayer(), track)
    if not sound then
        print("[GModsaken] Failed to create sound for track: " .. track)
        return
    end
    
    -- Настраиваем звук
    sound:SetVolume(musicVolume)
    sound:SetPlaybackRate(1.0)
    
    -- Воспроизводим
    sound:Play()
    
    -- Сохраняем ссылки
    currentMusic = track
    currentMusicChannel = sound
    isMusicPlaying = true
    
    -- Устанавливаем зацикливание
    if GM.MusicSettings.Loop then
        sound:SetLooping(true)
    end
    
    print("[GModsaken] Playing music: " .. GM:GetMusicTrackName(track))
    
    -- Плавное появление
    if fadeIn then
        sound:SetVolume(0)
        local targetVolume = musicVolume
        local fadeTime = GM.MusicSettings.FadeTime or 2.0
        local fadeStep = targetVolume / (fadeTime * 10) -- 10 обновлений в секунду
        
        timer.Create("GModsaken_MusicFadeIn", 0.1, 0, function()
            if not IsValid(sound) then
                timer.Remove("GModsaken_MusicFadeIn")
                return
            end
            
            local currentVol = sound:GetVolume()
            if currentVol >= targetVolume then
                sound:SetVolume(targetVolume)
                timer.Remove("GModsaken_MusicFadeIn")
            else
                sound:SetVolume(math.min(currentVol + fadeStep, targetVolume))
            end
        end)
    end
end

-- Остановка музыки
function StopMusic(fadeOut)
    if not currentMusicChannel then return end
    
    if fadeOut and fadeOut > 0 then
        -- Плавное затухание
        local fadeTime = fadeOut
        local currentVol = currentMusicChannel:GetVolume()
        local fadeStep = currentVol / (fadeTime * 10)
        
        timer.Create("GModsaken_MusicFadeOut", 0.1, 0, function()
            if not IsValid(currentMusicChannel) then
                timer.Remove("GModsaken_MusicFadeOut")
                return
            end
            
            local vol = currentMusicChannel:GetVolume()
            if vol <= 0 then
                currentMusicChannel:Stop()
                currentMusicChannel = nil
                currentMusic = nil
                isMusicPlaying = false
                timer.Remove("GModsaken_MusicFadeOut")
            else
                currentMusicChannel:SetVolume(math.max(vol - fadeStep, 0))
            end
        end)
    else
        -- Мгновенная остановка
        currentMusicChannel:Stop()
        currentMusicChannel = nil
        currentMusic = nil
        isMusicPlaying = false
    end
    
    print("[GModsaken] Music stopped")
end

-- Переключение на другую музыку
function SwitchMusic(newTrack, crossfade)
    if not musicEnabled then return end
    
    if crossfade and GM.MusicSettings.Crossfade then
        -- Плавное переключение
        local fadeTime = GM.MusicSettings.FadeTime or 2.0
        
        -- Запускаем новую музыку с нулевой громкостью
        PlayMusic(newTrack, false)
        if currentMusicChannel then
            currentMusicChannel:SetVolume(0)
        end
        
        -- Плавно увеличиваем громкость новой музыки
        timer.Create("GModsaken_MusicCrossfade", 0.1, 0, function()
            if not IsValid(currentMusicChannel) then
                timer.Remove("GModsaken_MusicCrossfade")
                return
            end
            
            local currentVol = currentMusicChannel:GetVolume()
            if currentVol >= musicVolume then
                currentMusicChannel:SetVolume(musicVolume)
                timer.Remove("GModsaken_MusicCrossfade")
            else
                currentMusicChannel:SetVolume(math.min(currentVol + (musicVolume / (fadeTime * 10)), musicVolume))
            end
        end)
    else
        -- Обычное переключение
        PlayMusic(newTrack, true)
    end
end

-- Воспроизведение случайного трека из категории
function PlayRandomMusic(category)
    if not musicEnabled then return end
    
    local track = GM:GetRandomMusicTrack(category)
    if track then
        PlayMusic(track, true)
    end
end

-- Установка громкости
function SetMusicVolume(volume)
    volume = math.Clamp(volume, 0.0, 1.0)
    musicVolume = volume
    
    -- Сохраняем в куки
    cookie.Set("gmodsaken_music_volume", tostring(volume))
    
    -- Применяем к текущей музыке
    if currentMusicChannel and IsValid(currentMusicChannel) then
        currentMusicChannel:SetVolume(volume)
    end
    
    print("[GModsaken] Music volume set to: " .. volume)
end

-- Включение/выключение музыки
function SetMusicEnabled(enabled)
    musicEnabled = enabled
    
    -- Сохраняем в куки
    cookie.Set("gmodsaken_music_enabled", enabled and "1" or "0")
    
    if not enabled then
        StopMusic(1.0)
    end
    
    print("[GModsaken] Music " .. (enabled and "enabled" or "disabled"))
end

-- Получение текущего состояния музыки
function GetCurrentMusicState()
    return {
        Track = currentMusic,
        IsPlaying = isMusicPlaying,
        Volume = musicVolume,
        Enabled = musicEnabled
    }
end

-- Обработка сетевых сообщений
net.Receive("GModsaken_UpdateMusicVolume", function()
    local volume = net.ReadFloat()
    SetMusicVolume(volume)
end)

net.Receive("GModsaken_UpdateMusicEnabled", function()
    local enabled = net.ReadBool()
    SetMusicEnabled(enabled)
end)

net.Receive("GModsaken_PlayMusic", function()
    local track = net.ReadString()
    local fadeIn = net.ReadBool()
    PlayMusic(track, fadeIn)
end)

net.Receive("GModsaken_StopMusic", function()
    local fadeOut = net.ReadFloat()
    StopMusic(fadeOut)
end)

net.Receive("GModsaken_SwitchMusic", function()
    local newTrack = net.ReadString()
    local crossfade = net.ReadBool()
    SwitchMusic(newTrack, crossfade)
end)

-- Хуки для автоматического воспроизведения музыки
hook.Add("GModsaken_GameStateChanged", "GModsaken_MusicStateChange", function(oldState, newState)
    if not musicEnabled then return end
    
    if newState == "LOBBY" then
        -- Музыка лобби
        PlayRandomMusic("ambient")
    elseif newState == "PLAYING" then
        -- Музыка игры
        PlayRandomMusic("ambient")
    elseif newState == "ROUND_END" then
        -- Музыка конца раунда
        PlayRandomMusic("menu")
    end
end)

hook.Add("GModsaken_KillerNearby", "GModsaken_HorrorMusic", function(isNearby)
    if not musicEnabled then return end
    
    if isNearby then
        -- Музыка ужаса когда убийца рядом
        PlayRandomMusic("horror")
    else
        -- Возвращаемся к обычной музыке
        PlayRandomMusic("ambient")
    end
end)

hook.Add("GModsaken_ChaseStarted", "GModsaken_ActionMusic", function()
    if not musicEnabled then return end
    
    -- Активная музыка во время погони
    PlayRandomMusic("action")
end)

hook.Add("GModsaken_ChaseEnded", "GModsaken_ReturnToAmbient", function()
    if not musicEnabled then return end
    
    -- Возвращаемся к атмосферной музыке
    PlayRandomMusic("ambient")
end)

-- Инициализация при загрузке
hook.Add("Initialize", "GModsaken_InitializeMusic", function()
    timer.Simple(1, function()
        InitializeMusicSystem()
    end)
end)

-- Очистка при выгрузке
hook.Add("ShutDown", "GModsaken_CleanupMusic", function()
    StopMusic(0)
end)

-- Команды для управления музыкой
concommand.Add("gmodsaken_music_volume", function(ply, cmd, args)
    local volume = tonumber(args[1]) or 0.5
    SetMusicVolume(volume)
    if IsValid(ply) then
        ply:ChatPrint("Громкость музыки установлена: " .. math.floor(volume * 100) .. "%")
    end
end)

concommand.Add("gmodsaken_music_toggle", function(ply, cmd, args)
    SetMusicEnabled(not musicEnabled)
    if IsValid(ply) then
        ply:ChatPrint("Музыка " .. (musicEnabled and "включена" or "выключена"))
    end
end)

concommand.Add("gmodsaken_music_play", function(ply, cmd, args)
    local category = args[1] or "ambient"
    PlayRandomMusic(category)
    if IsValid(ply) then
        ply:ChatPrint("Воспроизводится музыка категории: " .. category)
    end
end)

concommand.Add("gmodsaken_music_stop", function(ply, cmd, args)
    StopMusic(1.0)
    if IsValid(ply) then
        ply:ChatPrint("Музыка остановлена")
    end
end)

-- Экспорт функций для использования в других файлах
_G.GModsakenMusic = {
    Play = PlayMusic,
    Stop = StopMusic,
    Switch = SwitchMusic,
    PlayRandom = PlayRandomMusic,
    SetVolume = SetMusicVolume,
    SetEnabled = SetMusicEnabled,
    GetState = GetCurrentMusicState
} 