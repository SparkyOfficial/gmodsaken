local meta = FindMetaTable( "Player" );
if( !meta ) then
	return;
end

/*------------------------------------
   GetFontScale
------------------------------------*/
function meta:GetFontScale()
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

/*------------------------------------
   GetPanelScale
------------------------------------*/
function meta:GetPanelScale()
	local scale_w = 1
	local scale_h = 1
	if ScrW() == 1024 then
		scale_w = 1.5625
		scale_h = 1.58
	elseif ScrW() == 1152 then
		scale_w = 1.35
		scale_h = 1.45
	elseif ScrW() == 1280 then
		scale_w = 1.25
		if ScrH() == 960 then
			scale_h = 1.27
		else
			scale_h = 1.225
		end
	end
	return {scale_w,scale_h}
end