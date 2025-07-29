/*------------------------------------
   GetFontScale
------------------------------------*/
local function GetFontScale()
	local scale = 1
	if ScrW() == 1024 then
		scale = 1.5625
	elseif ScrW() == 1152 then
		scale = 1.35
	elseif ScrW() == 1280 then
		scale = 1.25
	end
	return scale
end

function TF_CreateFonts()
	local scale = GetFontScale()
	surface.CreateFont( "akbar", 20 /scale, 195, true, true, "TF2_akbar" )  
	surface.CreateFont( "TF2 Secondary", 32 /scale, 320, true, true, "TF2_font1" )  
	surface.CreateFont( "TF2 Secondary", 43 /scale, 400, true, true, "TF2_font2" )  
	surface.CreateFont( "TF2", 50 /scale, 400, true, true, "TF2_font_eng_metal" )  
	surface.CreateFont( "TF2", 42 /scale, 400, true, true, "TF2_font_ammo1" )  
	surface.CreateFont( "TF2 Build", 110 /scale, 400, true, true, "TF2_font_build_dpa1" )  
	surface.CreateFont( "Verdana", 26 /scale, 400, true, true, "TF2_font_build_dpa2" )  
	surface.CreateFont( "Default", 20 /scale, 40, true, true, "TF2_engineer_hud_font1" )  
end
hook.Add( "Initialize", "TF Create Fonts", TF_CreateFonts ); 