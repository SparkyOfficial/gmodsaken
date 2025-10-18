--[[
    GModsaken - Base Tool (Shared)
    Copyright (C) 2024 GModsaken Contributors
]]

if SERVER then
    AddCSLuaFile("weapons/gmod_tool/shared.lua")
end

TOOL.Category = "GModsaken"
TOOL.Name = "#Tool.none"

-- This is a placeholder file to prevent errors
-- Actual tool implementations should be in their own files

if CLIENT then
    language.Add("Tool.none", "No Tool Selected")
end
