--[[
    GModsaken - Music System (Shared)
    Copyright (C) 2024 GModsaken Contributors
]]

-- Ensure GM table exists
if not _G.GM then
    _G.GM = GAMEMODE or {}
    print("[GModsaken] Created GM table in sh_music.lua")
end
local GM = _G.GM
_G.GAMEMODE = GM

print("[GModsaken] sh_music.lua loaded")

-- Музыкальные треки по категориям
GM.MusicTracks = {
    ["ambient"] = {
        "gmodsaken/music/ambient/ambient_night_wind_kevin_macleod.mp3",
        "gmodsaken/music/ambient/ambient_forest_whispers_freemusic.mp3",
        "gmodsaken/music/ambient/ambient_urban_night_bensound.mp3",
        "gmodsaken/music/ambient/ambient_industrial_hum_ccmixter.mp3",
        "gmodsaken/music/ambient/ambient_rain_on_roof_pixabay.mp3"
    },
    ["action"] = {
        "gmodsaken/music/action/action_chase_sequence_freemusic.mp3",
        "gmodsaken/music/action/action_escape_attempt_bensound.mp3",
        "gmodsaken/music/action/action_fight_for_survival_ccmixter.mp3",
        "gmodsaken/music/action/action_running_from_danger_pixabay.mp3",
        "gmodsaken/music/action/action_last_stand_unknown.mp3"
    },
    ["horror"] = {
        "gmodsaken/music/horror/horror_dark_corridor_bensound.mp3",
        "gmodsaken/music/horror/horror_something_lurking_freemusic.mp3",
        "gmodsaken/music/horror/horror_heartbeat_ccmixter.mp3",
        "gmodsaken/music/horror/horror_whispers_in_dark_pixabay.mp3",
        "gmodsaken/music/horror/horror_creepy_ambient_unknown.mp3"
    },
    ["menu"] = {
        "gmodsaken/music/menu/menu_main_theme_ccmixter.mp3",
        "gmodsaken/music/menu/menu_peaceful_thoughts_bensound.mp3",
        "gmodsaken/music/menu/menu_gentle_waves_freemusic.mp3",
        "gmodsaken/music/menu/menu_soft_electronics_pixabay.mp3",
        "gmodsaken/music/menu/menu_calm_meditation_unknown.mp3"
    }
}

-- Настройки музыки
GM.MusicSettings = {
    Volume = 0.5,           -- Громкость (0.0 - 1.0)
    Enabled = true,         -- Включена ли музыка
    Crossfade = true,       -- Плавное переключение
    Loop = true,            -- Зацикливание
    FadeTime = 2.0          -- Время затухания (секунды)
}

-- Получение случайного трека из категории
function GM:GetRandomMusicTrack(category)
    if not self.MusicTracks[category] then
        return nil
    end
    
    local tracks = self.MusicTracks[category]
    return tracks[math.random(1, #tracks)]
end

-- Получение всех треков категории
function GM:GetMusicTracks(category)
    return self.MusicTracks[category] or {}
end

-- Проверка существования трека
function GM:IsMusicTrackValid(track)
    if not track then return false end
    
    -- Проверяем, есть ли трек в любой категории
    for category, tracks in pairs(self.MusicTracks) do
        for _, existingTrack in ipairs(tracks) do
            if existingTrack == track then
                return true
            end
        end
    end
    
    return false
end

-- Получение категории трека
function GM:GetMusicTrackCategory(track)
    if not track then return nil end
    
    for category, tracks in pairs(self.MusicTracks) do
        for _, existingTrack in ipairs(tracks) do
            if existingTrack == track then
                return category
            end
        end
    end
    
    return nil
end

-- Получение имени трека из пути
function GM:GetMusicTrackName(track)
    if not track then return "Неизвестный трек" end
    
    local name = string.match(track, "([^/]+)%.mp3$")
    if name then
        -- Убираем расширение и заменяем подчеркивания на пробелы
        name = string.gsub(name, "_", " ")
        -- Делаем первую букву заглавной
        name = string.upper(string.sub(name, 1, 1)) .. string.sub(name, 2)
        return name
    end
    
    return "Неизвестный трек"
end

-- Получение автора трека из пути
function GM:GetMusicTrackAuthor(track)
    if not track then return "Неизвестный автор" end
    
    local author = string.match(track, "([^_]+)%.mp3$")
    if author then
        -- Убираем расширение и заменяем подчеркивания на пробелы
        author = string.gsub(author, "_", " ")
        -- Делаем первую букву заглавной
        author = string.upper(string.sub(author, 1, 1)) .. string.sub(author, 2)
        return author
    end
    
    return "Неизвестный автор"
end

-- Получение настроек музыки
function GM:GetMusicSettings()
    return self.MusicSettings
end

-- Установка громкости музыки
function GM:SetMusicVolume(volume)
    volume = math.Clamp(volume, 0.0, 1.0)
    self.MusicSettings.Volume = volume
    
    -- Отправляем обновление клиентам
    if SERVER then
        net.Start("GModsaken_UpdateMusicVolume")
        net.WriteFloat(volume)
        net.Broadcast()
    end
end

-- Включение/выключение музыки
function GM:SetMusicEnabled(enabled)
    self.MusicSettings.Enabled = enabled
    
    -- Отправляем обновление клиентам
    if SERVER then
        net.Start("GModsaken_UpdateMusicEnabled")
        net.WriteBool(enabled)
        net.Broadcast()
    end
end

-- Получение текущего состояния музыки
function GM:GetCurrentMusicState()
    return {
        Category = self.CurrentMusicCategory or "none",
        Track = self.CurrentMusicTrack or "none",
        Volume = self.MusicSettings.Volume,
        Enabled = self.MusicSettings.Enabled,
        IsPlaying = self.IsMusicPlaying or false
    }
end

-- Получение количества треков в категории
function GM:GetMusicTrackCount(category)
    if not self.MusicTracks[category] then
        return 0
    end
    
    return #self.MusicTracks[category]
end

-- Получение общего количества треков
function GM:GetTotalMusicTrackCount()
    local count = 0
    for category, tracks in pairs(self.MusicTracks) do
        count = count + #tracks
    end
    return count
end

-- Получение списка всех категорий
function GM:GetMusicCategories()
    local categories = {}
    for category, _ in pairs(self.MusicTracks) do
        table.insert(categories, category)
    end
    return categories
end

-- Проверка, поддерживается ли формат файла
function GM:IsMusicFormatSupported(filename)
    if not filename then return false end
    
    local supportedFormats = {
        ".mp3",
        ".wav",
        ".ogg"
    }
    
    local extension = string.lower(string.match(filename, "%.([^%.]+)$") or "")
    for _, format in ipairs(supportedFormats) do
        if "." .. extension == format then
            return true
        end
    end
    
    return false
end

-- Получение размера файла (примерно)
function GM:GetMusicFileSize(track)
    if not track then return 0 end
    
    -- Примерные размеры для разных битрейтов
    local bitrates = {
        ["128"] = 1,    -- 1 МБ на минуту
        ["192"] = 1.5,  -- 1.5 МБ на минуту
        ["320"] = 2.4   -- 2.4 МБ на минуту
    }
    
    -- Предполагаем средний битрейт 192 kbps
    local estimatedSize = bitrates["192"] * 3 -- 3 минуты в среднем
    return estimatedSize
end 