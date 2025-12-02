function StartPhase2()
	CustomTimers:IncrementGamePhase() -- Phase 1 to Phase 2
	CustomTimers.timers_paused = 0

	local DoorObs = Entities:FindAllByName("obstruction_phase2_1")

	for _, obs in pairs(DoorObs) do
		obs:SetEnabled(false, true)
	end

	DoEntFire("door_phase2_left", "SetAnimation", "gate_entrance002_open", 0, nil, nil)
	Phase2CreepsLeft()

	if PlayerResource:GetPlayerCount() > 1 then
		local DoorObs = Entities:FindAllByName("obstruction_phase2_2")

		for _, obs in pairs(DoorObs) do
			obs:SetEnabled(false, true)
		end

		DoEntFire("door_phase2_right", "SetAnimation", "gate_entrance002_open", 0, nil, nil)
		Phase2CreepsRight()
	end

	for c = 1, 8 do
		CREEP_LANES[c][1] = 0
		CREEP_LANES[c][3] = 0
	end
end

function Phase2CreepsLeft()
	local EntIceTower = Entities:FindByName(nil, "npc_tower_cold_1")
	local point = Entities:FindByName(nil, "npc_dota_spawner_top_left_1"):GetAbsOrigin()
	local difficulty = GameRules:GetCustomGameDifficulty()
	local wave_count = 0

	Timers:CreateTimer(function()
		if not EntIceTower:IsNull() and CustomTimers.timers_paused == 0 then
			wave_count = wave_count + 1

			for j = 1, 8 do
				local unit = CreateUnitByName("npc_ghul_II", point + RandomVector(RandomInt(0, 50)), true, nil, nil, DOTA_TEAM_CUSTOM_1)
				unit:SetBaseDamageMin(unit:GetRealDamageDone(unit) + (PHASE_2_UPGRADE["damage"][difficulty] * wave_count))
				unit:SetBaseDamageMax(unit:GetRealDamageDone(unit) + (PHASE_2_UPGRADE["damage"][difficulty] * wave_count) * 1.1)
				unit:SetMaxHealth(unit:GetMaxHealth() + (PHASE_2_UPGRADE["health"][difficulty] * wave_count))
				unit:SetBaseMaxHealth(unit:GetMaxHealth() + (PHASE_2_UPGRADE["health"][difficulty] * wave_count))
				unit:SetHealth(unit:GetMaxHealth())
				unit:SetPhysicalArmorBaseValue(unit:GetPhysicalArmorValue(false) + (PHASE_2_UPGRADE["armor"][difficulty] * wave_count))
				if not unit.GrowthOverheadPfx then
					unit.GrowthOverheadPfx = ParticleManager:CreateParticle("particles/units/heroes/hero_abaddon/abaddon_curse_counter_stack.vpcf", PATTACH_OVERHEAD_FOLLOW, unit)
				end

				ParticleManager:SetParticleControl(unit.GrowthOverheadPfx, 1, Vector(0, wave_count, 0))
				--				local stack_10 = math.floor(wave_count / 10)
				--				ParticleManager:SetParticleControl(unit.GrowthOverheadPfx, 2, Vector(stack_10, wave_count - stack_10*10, 0))
			end

			return XHS_CREEPS_INTERVAL
		elseif EntIceTower:IsNull() then
			return nil
		else -- if CustomTimers.timers_paused == 1 or 2
			return XHS_CREEPS_INTERVAL
		end
	end)
end

function Phase2CreepsRight()
	local EntIceTower = Entities:FindByName(nil, "npc_tower_cold_2")
	local point = Entities:FindByName(nil, "npc_dota_spawner_top_right_1"):GetAbsOrigin()
	local difficulty = GameRules:GetCustomGameDifficulty()
	local wave_count = 0

	Timers:CreateTimer(0, function()
		if not EntIceTower:IsNull() and CustomTimers.timers_paused ~= 1 then
			wave_count = wave_count + 1
			for j = 1, 8 do
				local unit = CreateUnitByName("npc_orc_II", point + RandomVector(RandomInt(0, 50)), true, nil, nil, DOTA_TEAM_CUSTOM_1)
				unit:SetBaseDamageMin(unit:GetRealDamageDone(unit) + (PHASE_2_UPGRADE["damage"][difficulty] * wave_count))
				unit:SetBaseDamageMax(unit:GetRealDamageDone(unit) + (PHASE_2_UPGRADE["damage"][difficulty] * wave_count) * 1.1)
				unit:SetMaxHealth(unit:GetMaxHealth() + (PHASE_2_UPGRADE["health"][difficulty] * wave_count))
				unit:SetBaseMaxHealth(unit:GetMaxHealth() + (PHASE_2_UPGRADE["health"][difficulty] * wave_count))
				unit:SetHealth(unit:GetMaxHealth())
				unit:SetPhysicalArmorBaseValue(unit:GetPhysicalArmorValue(false) + (PHASE_2_UPGRADE["armor"][difficulty] * wave_count))
				if not unit.GrowthOverheadPfx then
					unit.GrowthOverheadPfx = ParticleManager:CreateParticle("particles/units/heroes/hero_abaddon/abaddon_curse_counter_stack.vpcf", PATTACH_OVERHEAD_FOLLOW, unit)
				end

				ParticleManager:SetParticleControl(unit.GrowthOverheadPfx, 1, Vector(0, wave_count, 0))
				--				local stack_10 = math.floor(wave_count / 10)
				--				ParticleManager:SetParticleControl(unit.GrowthOverheadPfx, 2, Vector(stack_10, wave_count - stack_10*10, 0))
			end
			return 30
		elseif CustomTimers.timers_paused == 1 then
			return 30
		elseif EntIceTower:IsNull() then
			return nil
		end
	end)
end

function EndPhase2()
	local ice_towers = Entities:FindAllByName("npc_tower_death")
	for _, tower in pairs(ice_towers) do
		tower:Kill(nil, nil)
	end

	for TW = 1, 2 do
		local ice_towers_main = Entities:FindByName(nil, "npc_tower_cold_" .. TW)
		ice_towers_main:Kill(nil, nil)
	end
end

function FinalWave()
	KillCreeps(DOTA_TEAM_CUSTOM_1)
	RefreshPlayers()
	GameRules:SetHeroRespawnEnabled(false)

	TeleportAllHeroes("final_wave_player_", 30.0)

	EmitSoundOn("yaskar_01.music.ui_hero_select", Entities:FindByClassname(nil, "npc_dota_fort"))

	Timers:CreateTimer(10, function()
		FinalWaveSpawner("npc_abomination", "npc_banshee", "npc_necro", "npc_magnataur", "npc_dota_hero_balanar", 0, "west", "final_wave_player_2")
	end)

	Timers:CreateTimer(15, function()
		FinalWaveSpawner("npc_tauren", "npc_chaos_orc", "npc_warlock", "npc_orc_raider", "npc_dota_hero_grom_hellscream", 270, "north", "final_wave_player_4")
	end)

	Timers:CreateTimer(20, function()
		FinalWaveSpawner("npc_druid", "npc_guard", "npc_keeper", "npc_luna", "npc_dota_hero_illidan", 180, "east", "final_wave_player_6")
	end)

	Timers:CreateTimer(25, function()
		FinalWaveSpawner("npc_captain", "npc_marine", "npc_marine", "npc_knight", "npc_dota_hero_proudmoore", 90, "south", "final_wave_player_0")
	end)

	Timers:CreateTimer(30, function()
		for _, hero in pairs(HeroList:GetAllHeroes()) do
			if hero:IsRealHero() and hero:GetTeam() == DOTA_TEAM_GOODGUYS then
				CustomGameEventManager:Send_ServerToPlayer(hero:GetPlayerOwner(), "set_player_camera", { hPosition = hero:GetAbsOrigin() })
			end
		end
	end)

	Timers:CreateTimer(31, function()
		StopSoundOn("yaskar_01.music.ui_hero_select", Entities:FindByClassname(nil, 'npc_dota_fort'))

		local units = FindUnitsInRadius(DOTA_TEAM_NEUTRALS, Vector(0, 0, 0), nil, FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_INVULNERABLE, FIND_ANY_ORDER, false)
		local number = 0

		for _, v in pairs(units) do
			number = number + 1
		end

		if number > 0 then
			return 1
		end
	end)
end

local final_wave_stun_time = 0

function FinalWaveSpawner(creep1, creep2, creep3, creep4, boss_name, angles, direction, waypoint)
	local number = 1
	local waypoint = Entities:FindByName(nil, "final_wave_player_2")

	for i = 1, 3 do
		local unit = CreateUnitByName(creep1 .. "_final_wave", Entities:FindByName(nil, "final_wave_" .. direction .. "_" .. number):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_CUSTOM_1)
		unit:SetAngles(0, angles, 0)
		number = number + 1
	end

	for i = 1, 3 do
		local unit = CreateUnitByName(creep2 .. "_final_wave", Entities:FindByName(nil, "final_wave_" .. direction .. "_" .. number):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_CUSTOM_1)
		unit:SetAngles(0, angles, 0)
		number = number + 1
	end

	for i = 1, 3 do
		local unit = CreateUnitByName(creep3 .. "_final_wave", Entities:FindByName(nil, "final_wave_" .. direction .. "_" .. number):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_CUSTOM_1)
		unit:SetAngles(0, angles, 0)
		number = number + 1
	end

	for i = 1, 3 do
		local unit = CreateUnitByName(creep4 .. "_final_wave", Entities:FindByName(nil, "final_wave_" .. direction .. "_" .. number):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_CUSTOM_1)
		unit:SetAngles(0, angles, 0)
		number = number + 1
	end

	local boss = CreateUnitByName(boss_name .. "_final_wave", Entities:FindByName(nil, "final_wave_" .. direction .. "_" .. number):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_CUSTOM_1)
	boss:SetAngles(0, angles, 0)
	boss:EmitSound("Hero_TemplarAssassin.Trap")
	boss:SetInitialGoalEntity(waypoint)
	ExecuteOrderFromTable({
		UnitIndex = boss:entindex(),
		OrderType = DOTA_UNIT_ORDER_ATTACK_MOVE,
		Position = waypoint:GetAbsOrigin(),
	})

	local units = FindUnitsInRadius(DOTA_TEAM_CUSTOM_1, Vector(0, 0, 0), nil, FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
	for _, v in pairs(units) do
		if v:IsCreature() and v:HasMovementCapability() then
			v:AddNewModifier(v, nil, "modifier_pause_creeps", { duration = 25 + final_wave_stun_time, IsHidden = true }):SetStackCount(1)
			v:AddNewModifier(v, nil, "modifier_invulnerable", { duration = 25 + final_wave_stun_time, IsHidden = true })
		end
	end

	final_wave_stun_time = final_wave_stun_time - 5

	for _, hero in pairs(HeroList:GetAllHeroes()) do
		if hero:IsRealHero() and hero:GetTeam() == DOTA_TEAM_GOODGUYS then
			CustomGameEventManager:Send_ServerToPlayer(hero:GetPlayerOwner(), "set_player_camera", { hPosition = boss:GetAbsOrigin() })
		end
	end
end
