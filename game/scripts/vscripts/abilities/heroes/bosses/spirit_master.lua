local function ConfigureSpiritBossBar(boss, bossCount, bossBarId, bossName, bossIcon, darkColor, lightColor)
	if boss == nil or boss:IsNull() then
		return
	end

	boss.boss_count = bossCount
	boss.xhs_boss_bar_id = bossBarId
	boss.xhs_boss_bar_name = bossName
	boss.xhs_boss_bar_icon = bossIcon
	boss.xhs_boss_bar_colors = {
		dark_color = darkColor,
		light_color = lightColor,
	}

	if XHSPhase3BossAI ~= nil and XHSPhase3BossAI.HideVanillaHealthBar ~= nil then
		XHSPhase3BossAI:HideVanillaHealthBar(boss)
	end

	ShowBossBar(boss)
end

function PrimalSplit(event)
	local caster = event.caster
	local origin = caster:GetAbsOrigin()

	CustomGameEventManager:Send_ServerToAllClients("hide_boss_hp", {
		boss_count = caster.boss_count or 1,
		boss_bar_id = GetBossBarId and GetBossBarId(caster) or nil,
	})

	local Storm = CreateUnitByName("npc_dota_boss_spirit_master_storm", origin, true, nil, nil, DOTA_TEAM_CUSTOM_1)
	ConfigureSpiritBossBar(
		Storm,
		1,
		"spirit_master_storm",
		"npc_dota_boss_spirit_master_storm",
		"npc_dota_hero_storm_spirit",
		"#053f66",
		"#48d9ff"
	)

	local Earth = CreateUnitByName("npc_dota_boss_spirit_master_earth", origin, true, nil, nil, DOTA_TEAM_CUSTOM_1)
	ConfigureSpiritBossBar(
		Earth,
		2,
		"spirit_master_earth",
		"npc_dota_boss_spirit_master_earth",
		"npc_dota_hero_earth_spirit",
		"#1f4d20",
		"#79d67b"
	)

	local Fire = CreateUnitByName("npc_dota_boss_spirit_master_fire", origin, true, nil, nil, DOTA_TEAM_CUSTOM_1)
	ConfigureSpiritBossBar(
		Fire,
		3,
		"spirit_master_fire",
		"npc_dota_boss_spirit_master_fire",
		"npc_dota_hero_ember_spirit",
		"#5a1300",
		"#ff9a2f"
	)
end
