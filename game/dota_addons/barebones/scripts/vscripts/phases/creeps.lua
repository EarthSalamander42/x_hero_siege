first_rax = true

function SpawnCreeps()
	for c = 1, 8 do
	local point = Entities:FindByName( nil, "npc_dota_spawner_"..c)
	local Waypoint = Entities:FindByName( nil, "creep_path_"..c)
		if CREEP_LANES[c] == 1 then -- Level 1 lower than 6 min
			if BARRACKMENTS[c] == 1 then
				if time_elapsed < 390 then
					for j = 1, 3 do
						local unit = CreateUnitByName("npc_dota_creature_mini_lifestealers", point:GetAbsOrigin(), true, nil, nil, DOTA_TEAM_BADGUYS)
						unit:SetInitialGoalEntity(Waypoint)
						unit:MoveToPositionAggressive(Waypoint:GetAbsOrigin())
					end
					for j = 1, 2 do
						local unit = CreateUnitByName("npc_dota_creature_mini_weavers", point:GetAbsOrigin(), true, nil, nil, DOTA_TEAM_BADGUYS)
						unit:SetInitialGoalEntity(Waypoint)
						unit:MoveToPositionAggressive(Waypoint:GetAbsOrigin())
					end
				elseif time_elapsed < 750 then -- Level 2, 6 to 14 Min
					for j = 1, 3 do
						local unit = CreateUnitByName("npc_dota_creature_mini_undyings", point:GetAbsOrigin(), true, nil, nil, DOTA_TEAM_BADGUYS)
						unit:SetInitialGoalEntity(Waypoint)
						unit:MoveToPositionAggressive(Waypoint:GetAbsOrigin())
					end
					for j = 1, 2 do
						local unit = CreateUnitByName("npc_dota_creature_mini_necrolytes", point:GetAbsOrigin(), true, nil, nil, DOTA_TEAM_BADGUYS)
						unit:SetInitialGoalEntity(Waypoint)
						unit:MoveToPositionAggressive(Waypoint:GetAbsOrigin())
					end
				elseif time_elapsed < 1230 then -- Level 3, 14 to 20 Min
					for j = 1, 3 do
						local unit = CreateUnitByName("npc_dota_creature_mini_nyxes", point:GetAbsOrigin(), true, nil, nil, DOTA_TEAM_BADGUYS)
						unit:SetInitialGoalEntity(Waypoint)
						unit:MoveToPositionAggressive(Waypoint:GetAbsOrigin())
					end
					for j = 1, 2 do
						local unit = CreateUnitByName("npc_dota_creature_mini_fiends", point:GetAbsOrigin(), true, nil, nil, DOTA_TEAM_BADGUYS)
						unit:SetInitialGoalEntity(Waypoint)
						unit:MoveToPositionAggressive(Waypoint:GetAbsOrigin())
					end
				elseif time_elapsed < 1770 then -- Level 4, 20 to 29 Min (-3 min farm event)
					for j = 1, 3 do
						local unit = CreateUnitByName("npc_dota_creature_mini_dooms", point:GetAbsOrigin(), true, nil, nil, DOTA_TEAM_BADGUYS)
						unit:SetInitialGoalEntity(Waypoint)
						unit:MoveToPositionAggressive(Waypoint:GetAbsOrigin())
					end
					for j = 1, 2 do
						local unit = CreateUnitByName("npc_dota_creature_mini_black_dragons", point:GetAbsOrigin(), true, nil, nil, DOTA_TEAM_BADGUYS)
						unit:SetInitialGoalEntity(Waypoint)
						unit:MoveToPositionAggressive(Waypoint:GetAbsOrigin())
					end
				elseif time_elapsed < 2130 then -- Level 5, 29 to 35 Min
					for j = 1, 3 do
						local unit = CreateUnitByName("npc_dota_creature_mini_lancers", point:GetAbsOrigin(), true, nil, nil, DOTA_TEAM_BADGUYS)
						unit:SetInitialGoalEntity(Waypoint)
						unit:MoveToPositionAggressive(Waypoint:GetAbsOrigin())
					end
					for j = 1, 2 do
						local unit = CreateUnitByName("npc_dota_creature_mini_miranas", point:GetAbsOrigin(), true, nil, nil, DOTA_TEAM_BADGUYS)
						unit:SetInitialGoalEntity(Waypoint)
						unit:MoveToPositionAggressive(Waypoint:GetAbsOrigin())
					end
				elseif time_elapsed >= 2190 then -- Level 6, 35 to Infinite.
					for j = 1, 3 do
						local unit = CreateUnitByName("npc_dota_creature_mini_tinys", point:GetAbsOrigin(), true, nil, nil, DOTA_TEAM_BADGUYS)
						unit:SetInitialGoalEntity(Waypoint)
						unit:MoveToPositionAggressive(Waypoint:GetAbsOrigin())
					end
					for j = 1, 2 do
						local unit = CreateUnitByName("npc_dota_creature_mini_wyverns", point:GetAbsOrigin(), true, nil, nil, DOTA_TEAM_BADGUYS)
						unit:SetInitialGoalEntity(Waypoint)
						unit:MoveToPositionAggressive(Waypoint:GetAbsOrigin())
					end
				end
			end
		end
	end
end

function SpawnRedDragon()
local difficulty = GameRules:GetCustomGameDifficulty()

	for c = 1, 8 do
		if CREEP_LANES[c] == 1 and BARRACKMENTS[c] == 1 then
		local point = Entities:FindByName( nil, "npc_dota_spawner_"..c)
		local Waypoint = Entities:FindByName( nil, "creep_path_"..c)
			for j = 1, difficulty do
				local dragon = CreateUnitByName("npc_dota_creature_red_dragon", point:GetAbsOrigin(), true, nil, nil, DOTA_TEAM_BADGUYS)
				dragon:SetInitialGoalEntity(Waypoint)
				dragon:MoveToPositionAggressive(Waypoint:GetAbsOrigin())
			end
		end
	end
end

function SpawnBlackDragon()
local difficulty = GameRules:GetCustomGameDifficulty()

	for c = 1, 8 do
		if CREEP_LANES[c] == 1 and BARRACKMENTS[c] == 1 then
		local point = Entities:FindByName( nil, "npc_dota_spawner_"..c)
		local Waypoint = Entities:FindByName( nil, "creep_path_"..c)
			for j = 1, difficulty do
				local dragon = CreateUnitByName("npc_dota_creature_black_dragon", point:GetAbsOrigin(), true, nil, nil, DOTA_TEAM_BADGUYS)
				dragon:SetInitialGoalEntity(Waypoint)
				dragon:MoveToPositionAggressive(Waypoint:GetAbsOrigin())
			end
		end
	end
end

function SpawnRevenant(event)
local caller = event.caller
local difficulty = GameRules:GetCustomGameDifficulty()

	for j = 1, difficulty do
		local unit = CreateUnitByName("npc_death_ghost_tower", caller:GetAbsOrigin(), true, nil, nil, DOTA_TEAM_BADGUYS)
	end
end

function SpawnMagnataur(event)
local caller = event.caller
local difficulty = GameRules:GetCustomGameDifficulty()

	for j = 1, difficulty do
		local unit = CreateUnitByName("npc_magnataur_destroyer_crypt", caller:GetAbsOrigin(), true, nil, nil, DOTA_TEAM_BADGUYS)
	end

	if first_rax then
		first_rax = false
		Entities:FindByName(nil, "trigger_phase2_left"):Enable()
		Entities:FindByName(nil, "trigger_phase2_right"):Enable()
		local DoorObs = Entities:FindAllByName("obstruction_phase2")
		for _, obs in pairs(DoorObs) do 
			obs:SetEnabled(false, true)
		end
		DoEntFire("door_phase2_left", "SetAnimation", "gate_entrance002_open", 0, nil, nil)
		DoEntFire("door_phase2_right", "SetAnimation", "gate_entrance002_open", 0, nil, nil)
		Notifications:TopToAll({text = "Phase 2 creeps can now be triggered!", duration = 11.0})
	end
end
