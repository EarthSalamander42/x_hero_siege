_G.DialogDefinition =
{
	npc_xhs_paladin =
	{
		{
			szText = "Dialog_ForestChief_DefendTheCamp",
			szRequireQuestActive = "teleport_top",
			flAdvanceTime = 25.0,
			bSendToAll = true,
			bAdvance = true,
			Gesture = ACT_DOTA_CAST_ABILITY_3,
		},
		{
			szText = "Dialog_Shal_Lightbinder_2",
			szRequireQuestActive = "teleport_top",
			flAdvanceTime = 25.0,
			bSendToAll = true,
			bAdvance = true,
		},
		{
			szText = "Dialog_Shal_Lightbinder_3",
			szRequireQuestActive = "teleport_top",
			flAdvanceTime = 25.0,
			bSendToAll = true,
			bAdvance = true,
		},
		{
			szText = "Dialog_Shal_Lightbinder_4",
			szRequireQuestActive = "teleport_top",
			flAdvanceTime = 30.0,
			bSendToAll = true,
			bAdvance = false,
			bPlayersConfirm = true,
			szConfirmToken = "LearnAboutHoldout",
			Gesture = ACT_DOTA_CAST_ABILITY_3,
		},
	},
	npc_xhs_paladin_2 =
	{
		{
			szText = "Dialog_ForestChief_DefendTheCamp2",
			szRequireQuestActive = "teleport_arthas",
			flAdvanceTime = 25.0,
			bSendToAll = true,
			bAdvance = true,
			Gesture = ACT_DOTA_CAST_ABILITY_3,
		},
		{
			szText = "Dialog_Uther_Lightbringer_2",
			szRequireQuestActive = "teleport_arthas",
			flAdvanceTime = 25.0,
			bSendToAll = true,
			bAdvance = true,
		},
		{
			szText = "Dialog_Uther_Lightbringer_3",
			szRequireQuestActive = "teleport_arthas",
			flAdvanceTime = 25.0,
			bSendToAll = true,
			bAdvance = true,
		},
		{
			szText = "Dialog_Uther_Lightbringer_4",
			szRequireQuestActive = "teleport_arthas",
			flAdvanceTime = 30.0,
			bSendToAll = true,
			bAdvance = false,
			bPlayersConfirm = true,
			szConfirmToken = "LearnAboutHoldout2",
			Gesture = ACT_DOTA_CAST_ABILITY_3,
		},
	},
}
