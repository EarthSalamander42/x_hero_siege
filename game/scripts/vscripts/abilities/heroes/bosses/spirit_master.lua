function PrimalSplit(event)
	local caster = event.caster
	local origin = caster:GetAbsOrigin()

	CustomGameEventManager:Send_ServerToAllClients("hide_boss_hp", {
		boss_count = caster.boss_count or 1,
		boss_bar_id = GetBossBarId and GetBossBarId(caster) or nil,
	})

	local Storm = CreateUnitByName("npc_dota_boss_spirit_master_storm", origin, true, nil, nil, DOTA_TEAM_CUSTOM_1)
	Storm.boss_count = 1
	Storm.xhs_boss_bar_id = "spirit_master_storm"
	ShowBossBar(Storm)

	local Earth = CreateUnitByName("npc_dota_boss_spirit_master_earth", origin, true, nil, nil, DOTA_TEAM_CUSTOM_1)
	Earth.boss_count = 2
	Earth.xhs_boss_bar_id = "spirit_master_earth"
	ShowBossBar(Earth)

	local Fire = CreateUnitByName("npc_dota_boss_spirit_master_fire", origin, true, nil, nil, DOTA_TEAM_CUSTOM_1)
	Fire.boss_count = 3
	Fire.xhs_boss_bar_id = "spirit_master_fire"
	ShowBossBar(Fire)
end
