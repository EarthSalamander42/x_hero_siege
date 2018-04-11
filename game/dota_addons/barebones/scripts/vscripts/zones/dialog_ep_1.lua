_G.DialogDefinition =
{
	npc_xhs_paladin =
	{
		{
			szText = "Dialog_ForestChief_DefendTheCamp",
			szRequireQuestActive = "teleport_top",
			flAdvanceTime = 25.0,
			bSendToAll = true,
			bAdvance = false, 
			bPlayersConfirm = true,
			szConfirmToken = "LearnAboutHoldout",
			Gesture = ACT_DOTA_CAST_ABILITY_3,
		},
	},
}
