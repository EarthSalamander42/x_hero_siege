function PrimalSplit(event)
local caster = event.caster
local ability = event.ability
local level = ability:GetLevel()

local forwardV = caster:GetForwardVector()
local origin = caster:GetAbsOrigin()

	local Storm = CreateUnitByName("npc_dota_boss_spirit_master_storm", origin, true, nil, nil, DOTA_TEAM_CUSTOM_1)
	local Earth = CreateUnitByName("npc_dota_boss_spirit_master_earth", origin, true, nil, nil, DOTA_TEAM_CUSTOM_1)
	local Fire = CreateUnitByName("npc_dota_boss_spirit_master_fire", origin, true, nil, nil, DOTA_TEAM_CUSTOM_1)

	BossBar(Storm, "storm_spirit")
	Timers:CreateTimer(1.0, function()
		print("Earth Bar!")
		CustomNetTables:SetTableValue("round_data", "bossHealth", {boss = "storm_spirit", hp = Storm:GetHealthPercent(), boss3 = "true" , hp3 = Earth:GetHealthPercent()})
	return 1.0
	end)
	Timers:CreateTimer(2.0, function()
		print("Fire Bar!")
		CustomNetTables:SetTableValue("round_data", "bossHealth", {boss = "storm_spirit", hp = Storm:GetHealthPercent(), boss4 = "true" , hp4 = Fire:GetHealthPercent()})
	return 1.0
	end)
end
