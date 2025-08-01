
include('shared.lua')


SWEP.PrintName			= "Scripted Weapon"		// 'Nice' Weapon name (Shown on HUD)	
SWEP.Slot				= 0						// Slot in the weapon selection menu
SWEP.SlotPos			= 10					// Position in the slot
SWEP.DrawAmmo			= true					// Should draw the default HL2 ammo counter
SWEP.DrawCrosshair		= true 					// Should draw the default crosshair
SWEP.DrawWeaponInfoBox	= false					// Should draw the weapon info box
SWEP.BounceWeaponIcon   = true					// Should the weapon icon bounce?
SWEP.SwayScale			= 1.0					// The scale of the viewmodel sway
SWEP.BobScale			= 1.0					// The scale of the viewmodel bob
SWEP.Crosshair = "sprites/tf_crosshair_01"

SWEP.RenderGroup 		= RENDERGROUP_OPAQUE

// Override this in your SWEP to set the icon in the weapon selection
SWEP.WepSelectIcon		= surface.GetTextureID( "weapons/swep" )
SWEP.BounceWeaponIcon = false 

// This is the corner of the speech bubble
SWEP.SpeechBubbleLid	= surface.GetTextureID( "gui/speech_lid" )

/*---------------------------------------------------------
   Name: SWEP:PrimaryAttack( )
   Desc: +attack1 has been pressed
---------------------------------------------------------*/
function SWEP:PrimaryAttack()
end


/*---------------------------------------------------------
   Name: SWEP:SecondaryAttack( )
   Desc: +attack2 has been pressed
---------------------------------------------------------*/
function SWEP:SecondaryAttack()
end

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
	
	local tex=surface.GetTextureID(self.Crosshair)
	surface.SetTexture(tex)
	surface.SetDrawColor(255,255,255,255)
	surface.DrawTexturedRect(ScrW() *0.5 -16, ScrH() *0.5 -16, 24, 24 )
end


/*---------------------------------------------------------
	Checks the objects before any action is taken
	This is to make sure that the entities haven't been removed
---------------------------------------------------------*/
function SWEP:DrawWeaponSelection( x, y, wide, tall, alpha )
	// Set us up the texture
	surface.SetDrawColor( 255, 255, 255, alpha )
	surface.SetTexture( self.WepSelectIcon )
	
	// Lets get a sin wave to make it bounce
	local fsin = 0
	
	if ( self.BounceWeaponIcon == true ) then
		fsin = math.sin( CurTime() * 10 ) * 5
	end
	
	// Borders
	y = y + 10
	x = x + 10
	wide = wide - 20
	
	// Draw that mother
	surface.DrawTexturedRect( x + (fsin), y - (fsin),  wide-fsin*2 , ( wide / 2 ) + (fsin) )
	
	// Draw weapon info box
	self:PrintWeaponInfo( x + wide + 20, y + tall * 0.95, alpha )
	
end


/*---------------------------------------------------------
	This draws the weapon info box
---------------------------------------------------------*/
function SWEP:PrintWeaponInfo( x, y, alpha )
	if ( self.DrawWeaponInfoBox == false ) then return end

	if (self.InfoMarkup == nil ) then
		local str
		local title_color = "<color=230,230,230,255>"
		local text_color = "<color=150,150,150,255>"
		
		str = "<font=HudSelectionText>"
		if ( self.Author != "" ) then str = str .. title_color .. "Author:</color>\t"..text_color..self.Author.."</color>\n" end
		if ( self.Contact != "" ) then str = str .. title_color .. "Contact:</color>\t"..text_color..self.Contact.."</color>\n\n" end
		if ( self.Purpose != "" ) then str = str .. title_color .. "Purpose:</color>\n"..text_color..self.Purpose.."</color>\n\n" end
		if ( self.Instructions != "" ) then str = str .. title_color .. "Instructions:</color>\n"..text_color..self.Instructions.."</color>\n" end
		str = str .. "</font>"
		
		self.InfoMarkup = markup.Parse( str, 250 )
	end
	
	surface.SetDrawColor( 60, 60, 60, alpha )
	surface.SetTexture( self.SpeechBubbleLid )
	
	surface.DrawTexturedRect( x, y - 64 - 5, 128, 64 ) 
	draw.RoundedBox( 8, x - 5, y - 6, 260, self.InfoMarkup:GetHeight() + 18, Color( 60, 60, 60, alpha ) )
	
	self.InfoMarkup:Draw( x+5, y+5, nil, nil, alpha )
	
end


/*---------------------------------------------------------
   Name: SWEP:FreezeMovement()
   Desc: Return true to freeze moving the view
---------------------------------------------------------*/
function SWEP:FreezeMovement()
	return false
end


/*---------------------------------------------------------
   Name: SWEP:ViewModelDrawn()
   Desc: Called straight after the viewmodel has been drawn
---------------------------------------------------------*/
function SWEP:ViewModelDrawn()
end


/*---------------------------------------------------------
   Name: OnRestore
   Desc: Called immediately after a "load"
---------------------------------------------------------*/
function SWEP:OnRestore()
end

/*---------------------------------------------------------
   Name: OnRemove
   Desc: Called just before entity is deleted
---------------------------------------------------------*/
function SWEP:OnRemove()
end

/*---------------------------------------------------------
   Name: CustomAmmoDisplay
   Desc: Return a table
---------------------------------------------------------*/
function SWEP:CustomAmmoDisplay()
	return self.AmmoDisplay
end

/*---------------------------------------------------------
   Name: TranslateFOV
   Desc: Allows the weapon to translate the player's FOV (clientside)
---------------------------------------------------------*/
function SWEP:TranslateFOV( current_fov )
	
	return current_fov

end


/*---------------------------------------------------------
   Name: DrawWorldModel
   Desc: Draws the world model (not the viewmodel)
---------------------------------------------------------*/
function SWEP:DrawWorldModel()
	
	self.Weapon:DrawModel()

end


/*---------------------------------------------------------
   Name: DrawWorldModelTranslucent
   Desc: Draws the world model (not the viewmodel)
---------------------------------------------------------*/
function SWEP:DrawWorldModelTranslucent()
	
	self.Weapon:DrawModel()

end


/*---------------------------------------------------------
   Name: AdjustMouseSensitivity()
   Desc: Allows you to adjust the mouse sensitivity.
---------------------------------------------------------*/
function SWEP:AdjustMouseSensitivity()

	return nil
	
end