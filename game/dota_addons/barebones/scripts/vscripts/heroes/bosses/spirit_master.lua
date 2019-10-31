function PrimalSplit(event)
	local caster = event.caster

	local forwardV = caster:GetForwardVector()
	local origin = caster:GetAbsOrigin()

	local Storm = CreateUnitByName("npc_dota_boss_spirit_master_storm", origin, true, nil, nil, DOTA_TEAM_CUSTOM_1)
	local Earth = CreateUnitByName("npc_dota_boss_spirit_master_earth", origin, true, nil, nil, DOTA_TEAM_CUSTOM_1)
	Earth.boss_count = 2
	ShowBossBar(Earth)
	local Fire = CreateUnitByName("npc_dota_boss_spirit_master_fire", origin, true, nil, nil, DOTA_TEAM_CUSTOM_1)
	Fire.boss_count = 3
	ShowBossBar(Fire)
end
