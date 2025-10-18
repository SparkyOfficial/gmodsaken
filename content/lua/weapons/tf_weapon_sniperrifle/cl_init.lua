include('shared.lua')

SWEP.PrintName = "Sniper Rifle"
SWEP.Slot = 0
SWEP.SlotPos = 17
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = false

SWEP.WepSelectIcon		= surface.GetTextureID( "sprites/bucket_sniper" )

killicon.Add("tf_weapon_sniperrifle","sprites/bucket_sniper",Color ( 255, 255, 255, 255 ) )


/*---------------------------------------------------------
	You can draw to the HUD here - it will only draw when
	the client has the weapon deployed..
---------------------------------------------------------*/
function SWEP:DrawHUD()
	local team = LocalPlayer():Team()
	if team == 1 then
		team = "blue"
	else
		team = "red"
	end

	local ammo = math.Round(LocalPlayer():GetCustomAmmo( self.Primary.Ammo ))
	
	local scale_w = LocalPlayer():GetPanelScale()[1]
	local scale_h = LocalPlayer():GetPanelScale()[2]
			
	local tex=surface.GetTextureID("HUD/ammo_" .. team .. "_bg")
	surface.SetTexture(tex)
	surface.SetDrawColor(255,255,255,255)
	surface.DrawTexturedRect(ScrW() *0.79, ScrH() *0.86, 235 /scale_w, 110 /scale_h )
	
	draw.SimpleText(ammo, "TF2_font_build_dpa1", ScrW() *0.84, ScrH() *0.9, Color(236,227,203,255), 1, 1)
	
	if !self:GetNetworkedBool("scoping") or self:GetNetworkedBool("noscope") then return end
	surface.SetTexture(surface.GetTextureID("HUD/scope_sniper_ul"))
	surface.DrawTexturedRectRotated( ScrW() *0.25, ScrH() *0.25, ScrW() *0.5, ScrH() *0.5, 0 )
	
	surface.SetTexture(surface.GetTextureID("HUD/scope_sniper_ur"))
	surface.DrawTexturedRectRotated( ScrW() *0.75, ScrH() *0.25, ScrW() *0.5, ScrH() *0.5, 0 )
	
	surface.SetTexture(surface.GetTextureID("HUD/scope_sniper_ll"))
	surface.DrawTexturedRectRotated( ScrW() *0.25, ScrH() *0.75, ScrW() *0.5, ScrH() *0.5, 0 )
	
	surface.SetTexture(surface.GetTextureID("HUD/scope_sniper_lr"))
	surface.DrawTexturedRectRotated( ScrW() *0.75, ScrH() *0.75, ScrW() *0.5, ScrH() *0.5, 0 )
	
	//surface.SetTexture(surface.GetTextureID("HUD/sniperscope_numbers"))
	//surface.DrawTexturedRect( ScrW() *0.6, ScrH() *0.37, 165 /scale_w, 310 /scale_h )
	
	local charge = self:GetNetworkedInt("charge")
	
	render.SetMaterial( Material( "sprites/glow02" ) )
	render.DrawSprite( self.Owner:GetEyeTrace().HitPos, 3, 3, Color(255, 0, 0, 255) )
	
	local size = (80 /100) *charge +20
	surface.SetTexture( surface.GetTextureID( "sprites/redglow1" ) )
	surface.SetDrawColor( 255, 0, 0, 255 )
	surface.DrawTexturedRect( ScrW() / 2 -(size /2), ScrH() / 2 -(size /2), size, size )
	
	local color = Color(252,248,88,255)
	local w = 0.6
	local size_h = 4
	local charge_bars = charge
	for i = 1,10 do
		if charge_bars > 0 then
			if charge_bars <= 10 then
				local alpha = (charge_bars /10) *255
				color = Color(252,248,88,alpha)
			end
			draw.RoundedBox( 2.2, ScrW() *w, ScrH() *0.5, 5, size_h, color ) 
			w = w +0.005
			size_h = size_h +4
			charge_bars = charge_bars -10
		end
	end
	
	if charge -80 < 0 then return end
	local alpha = (255 /20) *(charge -80)
	draw.SimpleText("100%", "ChatFont", ScrW() *0.68, ScrH() *0.512, Color(255,255,100,alpha), 1, 1)
end

function SWEP:ViewModelDrawn()
	if !self:GetNetworkedBool("scoping") or self:GetNetworkedBool("noscope") then return end
	local size = (4 /100) *self:GetNetworkedInt("charge") +2
	render.SetMaterial( Material( "sprites/redglow1" ) )
	render.DrawSprite( self.Owner:GetEyeTrace().HitPos, size, size, Color(255, 0, 0, 255) ) 
end	
