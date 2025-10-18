local function AddPlayerModel( name, model )

	list.Set( "PlayerOptionsModel", name, model )
	player_manager.AddValidModel( name, model )
	
end


AddPlayerModel( "HL1 Gordon Freeman", 					"models/player/pappy/gordon/dr freeman.mdl" )
player_manager.AddValidModel( "HL1 Gordon Freeman", 						"models/player/pappy/gordon/dr freeman.mdl" )
player_manager.AddValidHands( "HL1 Gordon Freeman", 						"models/player/pappy/gordon/c_arms_dr_freeman.mdl", 0, "00000000" )