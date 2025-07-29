list.Set( "PlayerOptionsModel", "HL (Lenoax): Gordon Freeman", "models/Lenoax/gordonfreeman_pm.mdl" )
player_manager.AddValidModel( "HL (Lenoax): Gordon Freeman", "models/Lenoax/gordonfreeman_pm.mdl" )
player_manager.AddValidHands( "HL (Lenoax): Gordon Freeman", "models/Lenoax/gordonfreeman_markv_hands.mdl", 0, "00000000" )

list.Set( "PlayerOptionsModel", "HL (Lenoax): Mark IV", "models/Lenoax/markiv_pm.mdl" )
player_manager.AddValidModel( "HL (Lenoax): Mark IV", "models/Lenoax/markiv_pm.mdl" )
player_manager.AddValidHands( "HL (Lenoax): Mark IV", "models/Lenoax/gordonfreeman_markiv_hands.mdl", 0, "00000000" )

local NPC =
{
	Name = "Gordon Freeman",
	Class = "npc_citizen",
	KeyValues = { citizentype = 4 },
	Model = "models/Lenoax/gordonfreeman_npc.mdl",
	Category = "Half-Life"
}

list.Set( "NPC", "npc_hl_gordonfreeman", NPC )

local NPC =
{
	Name = "Mark IV",
	Class = "npc_citizen",
	KeyValues = { citizentype = 4 },
	Model = "models/Lenoax/markiv_npc.mdl",
	Category = "Half-Life"
}

list.Set( "NPC", "npc_hl_markiv", NPC )

