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
	local EntIceTower = Entities:FindByName( nil, "npc_tower_cold_1" )
	local point = Entities:FindByName( nil, "npc_dota_spawner_top_left_1"):GetAbsOrigin()

	Timers:CreateTimer(0, function()
		if not EntIceTower:IsNull() then
			for j = 1, 8 do
			local unit = CreateUnitByName("npc_ghul_II", point+RandomVector(RandomInt(0, 50)), true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		return 30
		elseif EntIceTower:IsNull() then
		return nil
		end
	end)
end

function spawn_second_phase_right()
	local EntIceTower = Entities:FindByName( nil, "npc_tower_cold_2" )
	local point = Entities:FindByName( nil, "npc_dota_spawner_top_right_1"):GetAbsOrigin()
	Timers:CreateTimer(0, function()
		if not EntIceTower:IsNull() then
			for j = 1, 8 do
			local unit = CreateUnitByName("npc_orc_II", point+RandomVector(RandomInt(0, 50)), true, nil, nil, DOTA_TEAM_BADGUYS)
			end
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
		Timers:CreateTimer(60,FinalWave)
		FrostTowersToFinalWave()
	end
end

function killed_frost_tower_right(keys)
GameMode.FrostTowers_killed = GameMode.FrostTowers_killed +1

	if GameMode.FrostTowers_killed >= 2 then
		Notifications:TopToAll({text="WARNING! Final Wave incoming. Arriving in 60 seconds! Back to the Castle!" , duration=10.0})
		Timers:CreateTimer(60,FinalWave)
		FrostTowersToFinalWave()
	end
end

function FinalWave()
local heroes = HeroList:GetAllHeroes()
local difficulty = GameRules:GetCustomGameDifficulty()
local teleporters = Entities:FindAllByName("trigger_teleport_green")
local teleporters_2 = Entities:FindAllByName("trigger_teleport_phase3_creeps")
local heroes = HeroList:GetAllHeroes()
local point_west_1 = Entities:FindByName(nil,"final_wave_west_1"):GetAbsOrigin()
local point_west_2 = Entities:FindByName(nil,"final_wave_west_2"):GetAbsOrigin()
local point_west_3 = Entities:FindByName(nil,"final_wave_west_3"):GetAbsOrigin()
local point_west_4 = Entities:FindByName(nil,"final_wave_west_4"):GetAbsOrigin()
local point_west_5 = Entities:FindByName(nil,"final_wave_west_5"):GetAbsOrigin()
local point_west_6 = Entities:FindByName(nil,"final_wave_west_6"):GetAbsOrigin()
local point_west_7 = Entities:FindByName(nil,"final_wave_west_7"):GetAbsOrigin()
local point_west_8 = Entities:FindByName(nil,"final_wave_west_8"):GetAbsOrigin()
local point_west_9 = Entities:FindByName(nil,"final_wave_west_9"):GetAbsOrigin()
local point_west_10 = Entities:FindByName(nil,"final_wave_west_10"):GetAbsOrigin()
local point_west_11 = Entities:FindByName(nil,"final_wave_west_11"):GetAbsOrigin()
local point_west_12 = Entities:FindByName(nil,"final_wave_west_12"):GetAbsOrigin()
local point_west_13 = Entities:FindByName(nil,"final_wave_west_13"):GetAbsOrigin()
local point_north_1 = Entities:FindByName(nil,"final_wave_north_1"):GetAbsOrigin()
local point_north_2 = Entities:FindByName(nil,"final_wave_north_2"):GetAbsOrigin()
local point_north_3 = Entities:FindByName(nil,"final_wave_north_3"):GetAbsOrigin()
local point_north_4 = Entities:FindByName(nil,"final_wave_north_4"):GetAbsOrigin()
local point_north_5 = Entities:FindByName(nil,"final_wave_north_5"):GetAbsOrigin()
local point_north_6 = Entities:FindByName(nil,"final_wave_north_6"):GetAbsOrigin()
local point_north_7 = Entities:FindByName(nil,"final_wave_north_7"):GetAbsOrigin()
local point_north_8 = Entities:FindByName(nil,"final_wave_north_8"):GetAbsOrigin()
local point_north_9 = Entities:FindByName(nil,"final_wave_north_9"):GetAbsOrigin()
local point_north_10 = Entities:FindByName(nil,"final_wave_north_10"):GetAbsOrigin()
local point_north_11 = Entities:FindByName(nil,"final_wave_north_11"):GetAbsOrigin()
local point_north_12 = Entities:FindByName(nil,"final_wave_north_12"):GetAbsOrigin()
local point_north_13 = Entities:FindByName(nil,"final_wave_north_13"):GetAbsOrigin()
local point_east_1 = Entities:FindByName(nil,"final_wave_east_1"):GetAbsOrigin()
local point_east_2 = Entities:FindByName(nil,"final_wave_east_2"):GetAbsOrigin()
local point_east_3 = Entities:FindByName(nil,"final_wave_east_3"):GetAbsOrigin()
local point_east_4 = Entities:FindByName(nil,"final_wave_east_4"):GetAbsOrigin()
local point_east_5 = Entities:FindByName(nil,"final_wave_east_5"):GetAbsOrigin()
local point_east_6 = Entities:FindByName(nil,"final_wave_east_6"):GetAbsOrigin()
local point_east_7 = Entities:FindByName(nil,"final_wave_east_7"):GetAbsOrigin()
local point_east_8 = Entities:FindByName(nil,"final_wave_east_8"):GetAbsOrigin()
local point_east_9 = Entities:FindByName(nil,"final_wave_east_9"):GetAbsOrigin()
local point_east_10 = Entities:FindByName(nil,"final_wave_east_10"):GetAbsOrigin()
local point_east_11 = Entities:FindByName(nil,"final_wave_east_11"):GetAbsOrigin()
local point_east_12 = Entities:FindByName(nil,"final_wave_east_12"):GetAbsOrigin()
local point_east_13 = Entities:FindByName(nil,"final_wave_east_13"):GetAbsOrigin()
local point_south_1 = Entities:FindByName(nil,"final_wave_south_1"):GetAbsOrigin()
local point_south_2 = Entities:FindByName(nil,"final_wave_south_2"):GetAbsOrigin()
local point_south_3 = Entities:FindByName(nil,"final_wave_south_3"):GetAbsOrigin()
local point_south_4 = Entities:FindByName(nil,"final_wave_south_4"):GetAbsOrigin()
local point_south_5 = Entities:FindByName(nil,"final_wave_south_5"):GetAbsOrigin()
local point_south_6 = Entities:FindByName(nil,"final_wave_south_6"):GetAbsOrigin()
local point_south_7 = Entities:FindByName(nil,"final_wave_south_7"):GetAbsOrigin()
local point_south_8 = Entities:FindByName(nil,"final_wave_south_8"):GetAbsOrigin()
local point_south_9 = Entities:FindByName(nil,"final_wave_south_9"):GetAbsOrigin()
local point_south_10 = Entities:FindByName(nil,"final_wave_south_10"):GetAbsOrigin()
local point_south_11 = Entities:FindByName(nil,"final_wave_south_11"):GetAbsOrigin()
local point_south_12 = Entities:FindByName(nil,"final_wave_south_12"):GetAbsOrigin()
local point_south_13 = Entities:FindByName(nil,"final_wave_south_13"):GetAbsOrigin()
local WaypointWest6 = Entities:FindByName(nil,"west1_6")
local WaypointNorth6 = Entities:FindByName(nil,"north1_6")
local WaypointEast6 = Entities:FindByName(nil,"east1_6")
local WaypointSouth6 = Entities:FindByName(nil,"south1_6")

	for _,v in pairs(teleporters) do
		v:Enable()
	end

	for _,v in pairs(teleporters_2) do
		v:Enable()
	end

	Timers:CreateTimer(10, function()
		local unit1 = CreateUnitByName("npc_abomination_final_wave", point_west_1, true, nil, nil, DOTA_TEAM_NEUTRALS)
		local unit2 = CreateUnitByName("npc_abomination_final_wave", point_west_2, true, nil, nil, DOTA_TEAM_NEUTRALS)
		local unit3 = CreateUnitByName("npc_abomination_final_wave", point_west_3, true, nil, nil, DOTA_TEAM_NEUTRALS)

		local unit4 = CreateUnitByName("npc_banshee_final_wave", point_west_4, true, nil, nil, DOTA_TEAM_NEUTRALS)
		local unit5 = CreateUnitByName("npc_banshee_final_wave", point_west_5, true, nil, nil, DOTA_TEAM_NEUTRALS)
		local unit6 = CreateUnitByName("npc_banshee_final_wave", point_west_6, true, nil, nil, DOTA_TEAM_NEUTRALS)

		local unit7 = CreateUnitByName("npc_necro_final_wave", point_west_7, true, nil, nil, DOTA_TEAM_NEUTRALS)
		local unit8 = CreateUnitByName("npc_necro_final_wave", point_west_8, true, nil, nil, DOTA_TEAM_NEUTRALS)
		local unit9 = CreateUnitByName("npc_necro_final_wave", point_west_9, true, nil, nil, DOTA_TEAM_NEUTRALS)

		local unit10 = CreateUnitByName("npc_magnataur_final_wave", point_west_10, true, nil, nil, DOTA_TEAM_NEUTRALS)
		local unit11 = CreateUnitByName("npc_magnataur_final_wave", point_west_11, true, nil, nil, DOTA_TEAM_NEUTRALS)
		local unit12 = CreateUnitByName("npc_magnataur_final_wave", point_west_12, true, nil, nil, DOTA_TEAM_NEUTRALS)

		local unit13 = CreateUnitByName("npc_dota_hero_balanar_final_wave", point_west_13, true, nil, nil, DOTA_TEAM_NEUTRALS)
		unit13:EmitSound("Hero_TemplarAssassin.Trap")
		unit13:SetInitialGoalEntity(WaypointWest6)
		unit13:MoveToPositionAggressive(WaypointWest6:GetAbsOrigin())

		local units = FindUnitsInRadius( DOTA_TEAM_NEUTRALS, Vector(0, 0, 0), nil, FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_FLAG_NONE , FIND_ANY_ORDER, false )
		for _,v in pairs(units) do
			if v:IsCreature() and v:HasMovementCapability() then
				v:AddNewModifier(nil, nil, "modifier_boss_stun", {duration = 25, IsHidden = true})
				v:AddNewModifier(nil, nil, "modifier_invulnerable", {duration = 25, IsHidden = true})
			end
		end
	
		for _,hero in pairs(heroes) do
			if hero:GetTeam() == DOTA_TEAM_GOODGUYS then
				PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(), unit13)
			end
		end
	end)

	Timers:CreateTimer(15, function()
		local unit1 = CreateUnitByName("npc_tauren_final_wave", point_north_1, true, nil, nil, DOTA_TEAM_NEUTRALS)
		unit1:SetAngles(0, 270, 0)
		local unit2 = CreateUnitByName("npc_tauren_final_wave", point_north_2, true, nil, nil, DOTA_TEAM_NEUTRALS)
		unit2:SetAngles(0, 270, 0)
		local unit3 = CreateUnitByName("npc_tauren_final_wave", point_north_3, true, nil, nil, DOTA_TEAM_NEUTRALS)
		unit3:SetAngles(0, 270, 0)
		local unit4 = CreateUnitByName("npc_chaos_orc_final_wave", point_north_4, true, nil, nil, DOTA_TEAM_NEUTRALS)
		unit4:SetAngles(0, 270, 0)
		local unit5 = CreateUnitByName("npc_chaos_orc_final_wave", point_north_5, true, nil, nil, DOTA_TEAM_NEUTRALS)
		unit5:SetAngles(0, 270, 0)
		local unit6 = CreateUnitByName("npc_chaos_orc_final_wave", point_north_6, true, nil, nil, DOTA_TEAM_NEUTRALS)
		unit6:SetAngles(0, 270, 0)
		local unit7 = CreateUnitByName("npc_warlock_final_wave", point_north_7, true, nil, nil, DOTA_TEAM_NEUTRALS)
		unit7:SetAngles(0, 270, 0)
		local unit8 = CreateUnitByName("npc_warlock_final_wave", point_north_8, true, nil, nil, DOTA_TEAM_NEUTRALS)
		unit8:SetAngles(0, 270, 0)
		local unit9 = CreateUnitByName("npc_warlock_final_wave", point_north_9, true, nil, nil, DOTA_TEAM_NEUTRALS)
		unit9:SetAngles(0, 270, 0)
		local unit10 = CreateUnitByName("npc_orc_raider_final_wave", point_north_10, true, nil, nil, DOTA_TEAM_NEUTRALS)
		unit10:SetAngles(0, 270, 0)
		local unit11 = CreateUnitByName("npc_orc_raider_final_wave", point_north_11, true, nil, nil, DOTA_TEAM_NEUTRALS)
		unit11:SetAngles(0, 270, 0)
		local unit12 = CreateUnitByName("npc_orc_raider_final_wave", point_north_12, true, nil, nil, DOTA_TEAM_NEUTRALS)
		unit12:SetAngles(0, 270, 0)
		local unit13 = CreateUnitByName("npc_dota_hero_grom_hellscream_final_wave", point_north_13, true, nil, nil, DOTA_TEAM_NEUTRALS)
		unit13:EmitSound("Hero_TemplarAssassin.Trap")
		unit13:SetAngles(0, 270, 0)
		unit13:SetInitialGoalEntity(WaypointNorth6)
		unit13:MoveToPositionAggressive(WaypointNorth6:GetAbsOrigin())
	
		local units = FindUnitsInRadius( DOTA_TEAM_NEUTRALS, Vector(0, 0, 0), nil, FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_FLAG_NONE , FIND_ANY_ORDER, false )
		for _,v in pairs(units) do
			if v:IsCreature() and v:HasMovementCapability() then
				v:AddNewModifier(nil, nil, "modifier_boss_stun", {duration= 20, IsHidden = true})
				v:AddNewModifier(nil, nil, "modifier_invulnerable", {duration= 20, IsHidden = true})
			end
		end
	
		for _,hero in pairs(heroes) do
			if hero:GetTeam() == DOTA_TEAM_GOODGUYS then
				PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(), unit13)
			end
		end
	end)

	Timers:CreateTimer(20, function()
		local unit1 = CreateUnitByName("npc_druid_final_wave", point_east_1, true, nil, nil, DOTA_TEAM_NEUTRALS)
		unit1:SetAngles(0, 180, 0)
		local unit2 = CreateUnitByName("npc_druid_final_wave", point_east_2, true, nil, nil, DOTA_TEAM_NEUTRALS)
		unit2:SetAngles(0, 180, 0)
		local unit3 = CreateUnitByName("npc_druid_final_wave", point_east_3, true, nil, nil, DOTA_TEAM_NEUTRALS)
		unit3:SetAngles(0, 180, 0)
		local unit4 = CreateUnitByName("npc_guard_final_wave", point_east_4, true, nil, nil, DOTA_TEAM_NEUTRALS)
		unit4:SetAngles(0, 180, 0)
		local unit5 = CreateUnitByName("npc_guard_final_wave", point_east_5, true, nil, nil, DOTA_TEAM_NEUTRALS)
		unit5:SetAngles(0, 180, 0)
		local unit6 = CreateUnitByName("npc_guard_final_wave", point_east_6, true, nil, nil, DOTA_TEAM_NEUTRALS)
		unit6:SetAngles(0, 180, 0)
		local unit7 = CreateUnitByName("npc_keeper_final_wave", point_east_7, true, nil, nil, DOTA_TEAM_NEUTRALS)
		unit7:SetAngles(0, 180, 0)
		local unit8 = CreateUnitByName("npc_keeper_final_wave", point_east_8, true, nil, nil, DOTA_TEAM_NEUTRALS)
		unit8:SetAngles(0, 180, 0)
		local unit9 = CreateUnitByName("npc_keeper_final_wave", point_east_9, true, nil, nil, DOTA_TEAM_NEUTRALS)
		unit9:SetAngles(0, 180, 0)
		local unit10 = CreateUnitByName("npc_luna_final_wave", point_east_10, true, nil, nil, DOTA_TEAM_NEUTRALS)
		unit10:SetAngles(0, 180, 0)
		local unit11 = CreateUnitByName("npc_luna_final_wave", point_east_11, true, nil, nil, DOTA_TEAM_NEUTRALS)
		unit11:SetAngles(0, 180, 0)
		local unit12 = CreateUnitByName("npc_luna_final_wave", point_east_12, true, nil, nil, DOTA_TEAM_NEUTRALS)
		unit12:SetAngles(0, 180, 0)
		local unit13 = CreateUnitByName("npc_dota_hero_illidan_final_wave", point_east_13, true, nil, nil, DOTA_TEAM_NEUTRALS)
		unit13:EmitSound("Hero_TemplarAssassin.Trap")
		unit13:SetAngles(0, 180, 0)
		unit13:SetInitialGoalEntity(WaypointEast6)
		unit13:MoveToPositionAggressive(WaypointEast6:GetAbsOrigin())

		local units = FindUnitsInRadius( DOTA_TEAM_NEUTRALS, Vector(0, 0, 0), nil, FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_FLAG_NONE , FIND_ANY_ORDER, false )
		for _,v in pairs(units) do
			if v:IsCreature() and v:HasMovementCapability() then
				v:AddNewModifier(nil, nil, "modifier_boss_stun", {duration= 15, IsHidden = true})
				v:AddNewModifier(nil, nil, "modifier_invulnerable", {duration= 15, IsHidden = true})
			end
		end

		for _,hero in pairs(heroes) do
			if hero:GetTeam() == DOTA_TEAM_GOODGUYS then
				PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(), unit13)
			end
		end
	end)

	Timers:CreateTimer(25, function()
		local unit1 = CreateUnitByName("npc_captain_final_wave", point_south_1, true, nil, nil, DOTA_TEAM_NEUTRALS)
		unit1:SetAngles(0, 90, 0)
		local unit2 = CreateUnitByName("npc_captain_final_wave", point_south_2, true, nil, nil, DOTA_TEAM_NEUTRALS)
		unit2:SetAngles(0, 90, 0)
		local unit3 = CreateUnitByName("npc_captain_final_wave", point_south_3, true, nil, nil, DOTA_TEAM_NEUTRALS)
		unit3:SetAngles(0, 90, 0)
		local unit4 = CreateUnitByName("npc_marine_final_wave", point_south_4, true, nil, nil, DOTA_TEAM_NEUTRALS)
		unit4:SetAngles(0, 90, 0)
		local unit5 = CreateUnitByName("npc_marine_final_wave", point_south_5, true, nil, nil, DOTA_TEAM_NEUTRALS)
		unit5:SetAngles(0, 90, 0)
		local unit6 = CreateUnitByName("npc_marine_final_wave", point_south_6, true, nil, nil, DOTA_TEAM_NEUTRALS)
		unit6:SetAngles(0, 90, 0)
		local unit7 = CreateUnitByName("npc_marine_final_wave", point_south_7, true, nil, nil, DOTA_TEAM_NEUTRALS)
		unit7:SetAngles(0, 90, 0)
		local unit8 = CreateUnitByName("npc_marine_final_wave", point_south_8, true, nil, nil, DOTA_TEAM_NEUTRALS)
		unit8:SetAngles(0, 90, 0)
		local unit9 = CreateUnitByName("npc_marine_final_wave", point_south_9, true, nil, nil, DOTA_TEAM_NEUTRALS)
		unit9:SetAngles(0, 90, 0)
		local unit10 = CreateUnitByName("npc_knight_final_wave", point_south_10, true, nil, nil, DOTA_TEAM_NEUTRALS)
		unit10:SetAngles(0, 90, 0)
		local unit11 = CreateUnitByName("npc_knight_final_wave", point_south_11, true, nil, nil, DOTA_TEAM_NEUTRALS)
		unit11:SetAngles(0, 90, 0)
		local unit12 = CreateUnitByName("npc_knight_final_wave", point_south_12, true, nil, nil, DOTA_TEAM_NEUTRALS)
		unit12:SetAngles(0, 90, 0)
		local unit13 = CreateUnitByName("npc_dota_hero_proudmoore_final_wave", point_south_13, true, nil, nil, DOTA_TEAM_NEUTRALS)
		unit13:EmitSound("Hero_TemplarAssassin.Trap")
		unit13:SetAngles(0, 90, 0)
		unit13:SetInitialGoalEntity(WaypointSouth6)
		unit13:MoveToPositionAggressive(WaypointSouth6:GetAbsOrigin())

		local units = FindUnitsInRadius( DOTA_TEAM_NEUTRALS, Vector(0, 0, 0), nil, FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_FLAG_NONE , FIND_ANY_ORDER, false )
		for _,v in pairs(units) do
			if v:IsCreature() and v:HasMovementCapability() then
				v:AddNewModifier(nil, nil, "modifier_boss_stun", {duration= 10, IsHidden = true})
				v:AddNewModifier(nil, nil, "modifier_invulnerable", {duration= 10, IsHidden = true})
			end
		end

		for _,hero in pairs(heroes) do
			if hero:GetTeam() == DOTA_TEAM_GOODGUYS then
				PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(), unit13)
			end
		end
	end)

	for _,hero in pairs(heroes) do
		if hero:GetTeam() == DOTA_TEAM_GOODGUYS then
			local id = hero:GetPlayerID()
			print(id)
			local point = Entities:FindByName(nil, "final_wave_player_"..id)
			FindClearSpaceForUnit(hero, point:GetAbsOrigin(), true)
			hero:AddNewModifier(nil, nil, "modifier_animation_freeze_stun", {duration= 30, IsHidden = true})
			hero:AddNewModifier(nil, nil, "modifier_invulnerable", {duration= 25, IsHidden = true})
			PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(), hero)
		end

		Timers:CreateTimer(30, function()
			PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(),nil)
		end)
	end
end
