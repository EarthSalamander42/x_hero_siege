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

	for c = 1, 8 do
	local point = Entities:FindByName( nil, "npc_dota_spawner_"..c)
	local Waypoint = Entities:FindByName( nil, "creep_path_"..c)
		if CREEP_LANES[c][1] == 1 then -- Lane Activated?
			if CREEP_LANES[c][3] == 1 then -- Barrack Alive?
				if CREEP_LANES[c][2] == 1 then -- Lane Level
					for j = 1, 4 do
						local unit = CreateUnitByName(melee_1[GameMode.creep_roll["race"]], point:GetAbsOrigin(), true, nil, nil, DOTA_TEAM_BADGUYS)
					end
					for j = 1, 2 do
						local unit = CreateUnitByName(ranged_1[GameMode.creep_roll["race"]], point:GetAbsOrigin(), true, nil, nil, DOTA_TEAM_BADGUYS)
					end
				elseif CREEP_LANES[c][2] == 2 then
					for j = 1, 4 do
						local unit = CreateUnitByName(melee_2[GameMode.creep_roll["race"]], point:GetAbsOrigin(), true, nil, nil, DOTA_TEAM_BADGUYS)
					end
					for j = 1, 2 do
						local unit = CreateUnitByName(ranged_2[GameMode.creep_roll["race"]], point:GetAbsOrigin(), true, nil, nil, DOTA_TEAM_BADGUYS)
					end
				elseif CREEP_LANES[c][2] == 3 then
					for j = 1, 4 do
						local unit = CreateUnitByName(melee_3[GameMode.creep_roll["race"]], point:GetAbsOrigin(), true, nil, nil, DOTA_TEAM_BADGUYS)
					end
					for j = 1, 2 do
						local unit = CreateUnitByName(ranged_3[GameMode.creep_roll["race"]], point:GetAbsOrigin(), true, nil, nil, DOTA_TEAM_BADGUYS)
					end
				elseif CREEP_LANES[c][2] >= 4 then
					for j = 1, 4 do
						local unit = CreateUnitByName(melee_4[GameMode.creep_roll["race"]], point:GetAbsOrigin(), true, nil, nil, DOTA_TEAM_BADGUYS)
					end
					for j = 1, 2 do
						local unit = CreateUnitByName(ranged_4[GameMode.creep_roll["race"]], point:GetAbsOrigin(), true, nil, nil, DOTA_TEAM_BADGUYS)
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
print(caller:GetName())
print(cn)

	CREEP_LANES[tonumber(cn)][2] = CREEP_LANES[tonumber(cn)][2] + 1
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
