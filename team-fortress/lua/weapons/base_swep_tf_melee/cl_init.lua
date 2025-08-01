
include('shared.lua')


SWEP.PrintName			= "Scripted Weapon"		// 'Nice' Weapon name (Shown on HUD)	
SWEP.Slot				= 0						// Slot in the weapon selection menu
SWEP.SlotPos			= 10					// Position in the slot
SWEP.DrawAmmo			= false					// Should draw the default HL2 ammo counter
SWEP.DrawCrosshair		= false 					// Should draw the default crosshair
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

function SWEP:PrimaryAttack()
end

function SWEP:SecondaryAttack()
end

/*---------------------------------------------------------
   Name: CustomAmmoDisplay
   Desc: Return a table
---------------------------------------------------------*/
function SWEP:CustomAmmoDisplay()
	return self.AmmoDisplay
end

function SWEP:DrawHUD()
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
---------------------------------------------------------
function SWEP:CustomAmmoDisplay()
	self.AmmoDisplay = self.AmmoDisplay or {}
	self.AmmoDisplay.Draw = true
	if self.GotPrimary then
		if !self.Primary.Global then
			self.AmmoDisplay.PrimaryClip 	= self:GetAmmo( self.Primary.Ammo );
		else
			self.AmmoDisplay.PrimaryClip 	= LocalPlayer():GetCustomAmmo( self.Primary.Ammo )
		end
		if self.GotGlobalClip then
			self.AmmoDisplay.PrimaryAmmo 	= LocalPlayer():GetCustomAmmo( self.Primary.Ammo )
		else
			self.AmmoDisplay.PrimaryAmmo 	= "AlyxGun"
		end
	else
		self.AmmoDisplay.PrimaryClip 	= -1
		self.AmmoDisplay.PrimaryAmmo 	= -1
	end
	if self.GotSecondary then
		self.AmmoDisplay.SecondaryClip = self:GetAmmo( self.Secondary.Ammo );
		self.AmmoDisplay.SecondaryAmmo 	=  LocalPlayer():GetCustomAmmo( self.Secondary.Ammo )
	else
		self.AmmoDisplay.SecondaryClip = -1
		self.AmmoDisplay.SecondaryAmmo 	=  -1
	end
	return self.AmmoDisplay
end*/

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

function ItemPickedUp( um )
	local um_sep = string.Explode( ",", um:ReadString() ) 
	for k, v in pairs( um_sep ) do
		if k == 1 then
			AmmoName = v
		else
			AmmoAmmount = v
		end
	end
	gamemode.Call( "HUDAmmoPickedUp", AmmoName, AmmoAmmount )
	AmmoName = nil
	AmmoAmmount = nil
end
usermessage.Hook("ItemPickedUp", ItemPickedUp) 
