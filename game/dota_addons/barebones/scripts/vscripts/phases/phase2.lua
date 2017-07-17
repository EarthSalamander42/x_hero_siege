require('libraries/timers')

first_time_teleport = true
first_time_teleport_arthas = true
first_time_teleport_arthas_real = true

function trigger_second_wave_left()
--	local skywrath = Entities:FindByName(nil, "SkywrathMage_Guardian1"):GetAbsOrigin()
	DoEntFire("trigger_phase2_left", "Kill", nil ,0 ,nil ,nil)
--	UTIL_REMOVE(skywrath)
	Timers:CreateTimer(2.5, spawn_second_phase_left)
end

function trigger_second_wave_right()
	DoEntFire("trigger_phase2_right", "Kill", nil, 0, nil, nil)
	Timers:CreateTimer(2.5, spawn_second_phase_right)
end

function spawn_second_phase_left()
	local EntIceTower = Entities:FindByName(nil, "npc_tower_cold_1")
	local point = Entities:FindByName(nil, "npc_dota_spawner_top_left_1"):GetAbsOrigin()

	Timers:CreateTimer(0, function()
		if not EntIceTower:IsNull() and SPECIAL_EVENT == 0 then
			for j = 1, 8 do
			local unit = CreateUnitByName("npc_ghul_II", point+RandomVector(RandomInt(0, 50)), true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		return 30
		elseif SPECIAL_EVENT == 1 then
			print("Phase 2 creeps paused, special event!")
			return 30
		elseif EntIceTower:IsNull() then
			return nil
		end
	end)
end

function spawn_second_phase_right()
	local EntIceTower = Entities:FindByName(nil, "npc_tower_cold_2")
	local point = Entities:FindByName(nil, "npc_dota_spawner_top_right_1"):GetAbsOrigin()
	Timers:CreateTimer(0, function()
		if not EntIceTower:IsNull() and SPECIAL_EVENT == 0 then
			for j = 1, 8 do
			local unit = CreateUnitByName("npc_orc_II", point+RandomVector(RandomInt(0, 50)), true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		return 30
		elseif SPECIAL_EVENT == 1 then
			print("Phase 2 creeps paused, special event!")
			return 30
		elseif EntIceTower:IsNull() then
			return nil
		end
	end)
end

function killed_frost_tower_left(keys)
GameMode.FrostTowers_killed = GameMode.FrostTowers_killed +1

	if GameMode.FrostTowers_killed >= 2 then
		Notifications:TopToAll({text="WARNING! Final Wave incoming. Arriving in 60 seconds! Back to the Castle!" , duration=10.0})
		Timers:CreateTimer(59, RefreshPlayers)
		Timers:CreateTimer(60,FinalWave)
		FrostTowersToFinalWave()
		for _, hero in pairs(HeroList:GetAllHeroes()) do
			hero:SetRespawnsDisabled(false)
		end
	end
end

function killed_frost_tower_right(keys)
GameMode.FrostTowers_killed = GameMode.FrostTowers_killed +1

	if GameMode.FrostTowers_killed >= 2 then
		Notifications:TopToAll({text="WARNING! Final Wave incoming. Arriving in 60 seconds! Back to the Castle!" , duration=10.0})
		Timers:CreateTimer(59, RefreshPlayers)
		Timers:CreateTimer(60, FinalWave)
		FrostTowersToFinalWave()
		for _, hero in pairs(HeroList:GetAllHeroes()) do
			hero:SetRespawnsDisabled(false)
		end
	end
end

function FinalWave()
	for _, hero in pairs(HeroList:GetAllHeroes()) do
		if hero:GetTeam() == DOTA_TEAM_GOODGUYS then
			local id = hero:GetPlayerID()
			local point = Entities:FindByName(nil, "final_wave_player_"..id)
			FindClearSpaceForUnit(hero, point:GetAbsOrigin(), true)
			hero:AddNewModifier(nil, nil, "modifier_boss_stun", {duration= 30, IsHidden = true})
			hero:AddNewModifier(nil, nil, "modifier_invulnerable", {duration= 30, IsHidden = true})
			PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(), hero)
		end

		Timers:CreateTimer(30, function()
			PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(), nil)
		end)
	end
	
	Timers:CreateTimer(31, function()
	local units = FindUnitsInRadius(DOTA_TEAM_NEUTRALS, Vector(0, 0, 0), nil, FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_INVULNERABLE , FIND_ANY_ORDER, false )
	local number = 0

		for _, v in pairs(units) do
			number = number +1
		end

		print("Detecting neutrals...", number)
		if number <= 0 then
			StartMagtheridonArena()
		else
			return 1
		end
	end)

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
end
