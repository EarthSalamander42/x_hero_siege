first_rax = true

function SpawnCreeps()

	if GameMode.creep_roll["race"] < 4 then
		GameMode.creep_roll["race"] = GameMode.creep_roll["race"] + 1
	else
		GameMode.creep_roll["race"] = 1
	end

	local melee_1 = {
		"npc_xhs_undead_creep_melee_1",
		"npc_xhs_orc_creep_melee_1",
		"npc_xhs_elf_creep_melee_1",
		"npc_xhs_human_creep_melee_1"
	}

	local ranged_1 = {
		"npc_xhs_undead_creep_ranged_1",
		"npc_xhs_orc_creep_ranged_1",
		"npc_xhs_elf_creep_ranged_1",
		"npc_xhs_human_creep_ranged_1"
	}

	local melee_2 = {
		"npc_xhs_undead_creep_melee_2",
		"npc_xhs_orc_creep_melee_2",
		"npc_xhs_elf_creep_melee_2",
		"npc_xhs_human_creep_melee_2"
	}

	local ranged_2 = {
		"npc_xhs_undead_creep_ranged_2",
		"npc_xhs_orc_creep_ranged_2",
		"npc_xhs_elf_creep_ranged_2",
		"npc_xhs_human_creep_ranged_2"
	}

	local melee_3 = {
		"npc_xhs_undead_creep_melee_3",
		"npc_xhs_orc_creep_melee_3",
		"npc_xhs_elf_creep_melee_3",
		"npc_xhs_human_creep_melee_3"
	}

	local ranged_3 = {
		"npc_xhs_undead_creep_ranged_3",
		"npc_xhs_orc_creep_ranged_3",
		"npc_xhs_elf_creep_ranged_3",
		"npc_xhs_human_creep_ranged_3"
	}

	local melee_4 = {
		"npc_xhs_undead_creep_melee_4",
		"npc_xhs_orc_creep_melee_4",
		"npc_xhs_elf_creep_melee_4",
		"npc_xhs_human_creep_melee_4"
	}

	local ranged_4 = {
		"npc_xhs_undead_creep_ranged_4",
		"npc_xhs_orc_creep_ranged_4",
		"npc_xhs_elf_creep_ranged_4",
		"npc_xhs_human_creep_ranged_4"
	}

	local Spawners = 0
	if GetMapName() == "x_hero_siege" then
		Spawners = 8
	else
		Spawners = 4
	end
	for c = 1, Spawners do -- replace 8 with player count, to open and close lanes super easily
	local point = Entities:FindByName( nil, "npc_dota_spawner_"..c)
	local Waypoint = Entities:FindByName( nil, "creep_path_"..c)
		if CREEP_LANES[c][1] == 1 then -- Lane Activated?
			if CREEP_LANES[c][3] == 1 then -- Barrack Alive?
				if CREEP_LANES[c][2] == 1 then -- Lane Level
					for j = 1, 4 do
						local unit = CreateUnitByName(melee_1[GameMode.creep_roll["race"]], point:GetAbsOrigin(), true, nil, nil, DOTA_TEAM_CUSTOM_1)
					end
					for j = 1, 2 do
						local unit = CreateUnitByName(ranged_1[GameMode.creep_roll["race"]], point:GetAbsOrigin(), true, nil, nil, DOTA_TEAM_CUSTOM_1)
					end
				elseif CREEP_LANES[c][2] == 2 then
					for j = 1, 4 do
						local unit = CreateUnitByName(melee_2[GameMode.creep_roll["race"]], point:GetAbsOrigin(), true, nil, nil, DOTA_TEAM_CUSTOM_1)
					end
					for j = 1, 2 do
						local unit = CreateUnitByName(ranged_2[GameMode.creep_roll["race"]], point:GetAbsOrigin(), true, nil, nil, DOTA_TEAM_CUSTOM_1)
					end
				elseif CREEP_LANES[c][2] == 3 then
					for j = 1, 4 do
						local unit = CreateUnitByName(melee_3[GameMode.creep_roll["race"]], point:GetAbsOrigin(), true, nil, nil, DOTA_TEAM_CUSTOM_1)
					end
					for j = 1, 2 do
						local unit = CreateUnitByName(ranged_3[GameMode.creep_roll["race"]], point:GetAbsOrigin(), true, nil, nil, DOTA_TEAM_CUSTOM_1)
					end
				elseif CREEP_LANES[c][2] >= 4 then
					for j = 1, 4 do
						local unit = CreateUnitByName(melee_4[GameMode.creep_roll["race"]], point:GetAbsOrigin(), true, nil, nil, DOTA_TEAM_CUSTOM_1)
					end
					for j = 1, 2 do
						local unit = CreateUnitByName(ranged_4[GameMode.creep_roll["race"]], point:GetAbsOrigin(), true, nil, nil, DOTA_TEAM_CUSTOM_1)
					end
				end
			end
		end
	end
end

function SpawnRevenant(event)
local caller = event.caller
local cn = string.gsub(caller:GetName(), "dota_badguys_tower", "")
local difficulty = GameRules:GetCustomGameDifficulty()
local player = PlayerResource:GetPlayer(tonumber(cn)-1)

	CREEP_LANES[tonumber(cn)][2] = CREEP_LANES[tonumber(cn)][2] + 1
	Notifications:Bottom(player, {text="Your creep lane is now level "..CREEP_LANES[tonumber(cn)][2].."!", duration=5.0, style={color="green"}})
	for j = 1, difficulty do
		if caller:GetUnitName() == "xhs_tower_lane_1" then
			local unit = CreateUnitByName("xhs_death_revenant", caller:GetAbsOrigin(), true, nil, nil, DOTA_TEAM_CUSTOM_1)
		elseif caller:GetUnitName() == "xhs_tower_lane_2" then
			local unit = CreateUnitByName("xhs_death_revenant_2", caller:GetAbsOrigin(), true, nil, nil, DOTA_TEAM_CUSTOM_1)
		end
	end
end

function SpawnMagnataur(event)
local caller = event.caller
local difficulty = GameRules:GetCustomGameDifficulty()

	for j = 1, difficulty do
		local unit = CreateUnitByName("npc_magnataur_destroyer_crypt", caller:GetAbsOrigin(), true, nil, nil, DOTA_TEAM_CUSTOM_1)
	end

	if first_rax == true then
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
