local function OrderWaveCreep(unit, waypoint)
	if unit == nil or unit:IsNull() then return end

	ForEachUnitAbility(unit, function(ability)
		if ability ~= nil and ability:GetLevel() <= 0 then
			ability:SetLevel(1)
		end
	end)

	if unit:GetUnitName() == "npc_magnataur_destroyer_crypt" then
		local thunderClap = unit:FindAbilityByName("creature_thunder_clap_low")
		if thunderClap ~= nil then
			thunderClap:StartCooldown(RandomFloat(1.5, 6.0))
		end
	end

	if waypoint ~= nil and unit.SetInitialGoalEntity ~= nil then
		unit:SetInitialGoalEntity(waypoint)
	end

	local target = waypoint or BASE_GOOD
	if target == nil or target.GetAbsOrigin == nil then return end

	Timers:CreateTimer(0.1, function()
		if unit == nil or unit:IsNull() or not unit:IsAlive() then return nil end
		ExecuteOrderFromTable({
			UnitIndex = unit:entindex(),
			OrderType = DOTA_UNIT_ORDER_ATTACK_MOVE,
			Position = target:GetAbsOrigin(),
		})

		return nil
	end)

	Timers:CreateTimer(8.0, function()
		if unit == nil or unit:IsNull() or not unit:IsAlive() then return nil end
		if unit:GetAttackTarget() ~= nil then return nil end
		ExecuteOrderFromTable({
			UnitIndex = unit:entindex(),
			OrderType = DOTA_UNIT_ORDER_ATTACK_MOVE,
			Position = target:GetAbsOrigin(),
		})

		return nil
	end)
end

local function SpawnWaveCreep(unitName, point, waypoint)
	if point == nil then return nil end

	local unit = CreateUnitByName(unitName, point:GetAbsOrigin(), true, nil, nil, DOTA_TEAM_CUSTOM_1)
	OrderWaveCreep(unit, waypoint)
	return unit
end

function ReissueWaveCreepOrders(delay)
	local target = BASE_GOOD
	if target == nil or target.GetAbsOrigin == nil then return end

	Timers:CreateTimer(delay or 0.1, function()
		local units = FindUnitsInRadius(DOTA_TEAM_CUSTOM_1, Vector(0, 0, 0), nil, FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_FLAG_INVULNERABLE, FIND_ANY_ORDER, false)
		for _, unit in pairs(units) do
			if unit ~= nil and not unit:IsNull() and unit:IsAlive() and unit:HasMovementCapability() and not unit.Boss and unit:GetAttackTarget() == nil and not unit:HasModifier("modifier_cinematic_pause") then
				ExecuteOrderFromTable({
					UnitIndex = unit:entindex(),
					OrderType = DOTA_UNIT_ORDER_ATTACK_MOVE,
					Position = target:GetAbsOrigin(),
				})
			end
		end

		return nil
	end)
end

function SpawnCreeps(force)
	if force ~= true and XHSDevTools ~= nil and XHSDevTools:IsSandboxActive() then return end

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

	for c = 1, 8 do -- replace 8 with player count, to open and close lanes super easily
		local point = Entities:FindByName(nil, "npc_dota_spawner_" .. c)
		local waypoint = Entities:FindByName(nil, "creep_path_" .. c)

		if not point.disabled then
			if CREEP_LANES[c][1] == 1 then -- Lane Activated?
				if CREEP_LANES[c][3] == 1 then -- Barrack Alive?
					if CREEP_LANES[c][2] == 1 then -- Lane Level
						for j = 1, 2 do
							SpawnWaveCreep(melee_1[GameMode.creep_roll["race"]], point, waypoint)
						end
						for j = 1, 1 do
							SpawnWaveCreep(ranged_1[GameMode.creep_roll["race"]], point, waypoint)
						end
					elseif CREEP_LANES[c][2] == 2 then
						for j = 1, 2 do
							SpawnWaveCreep(melee_2[GameMode.creep_roll["race"]], point, waypoint)
						end
						for j = 1, 1 do
							SpawnWaveCreep(ranged_2[GameMode.creep_roll["race"]], point, waypoint)
						end
					elseif CREEP_LANES[c][2] == 3 then
						for j = 1, 2 do
							SpawnWaveCreep(melee_3[GameMode.creep_roll["race"]], point, waypoint)
						end
						for j = 1, 1 do
							SpawnWaveCreep(ranged_3[GameMode.creep_roll["race"]], point, waypoint)
						end
					elseif CREEP_LANES[c][2] >= 4 then
						for j = 1, 2 do
							SpawnWaveCreep(melee_4[GameMode.creep_roll["race"]], point, waypoint)
						end
						for j = 1, 1 do
							SpawnWaveCreep(ranged_4[GameMode.creep_roll["race"]], point, waypoint)
						end
					end
				end
			end
		else
			print("Barracks: Spawner " .. c .. " disabled.")
		end
	end
end

function CreepLevels(level)
	local dragons = {}
	dragons[2] = "npc_dota_creature_red_dragon"
	dragons[3] = "npc_dota_creature_black_dragon"
	dragons[4] = "npc_dota_creature_green_dragon"

	SpawnDragons(dragons[level])

	for c = 1, 8 do
		if CREEP_LANES[c][2] < level then
			CREEP_LANES[c][2] = level
		end
	end

	CustomGameEventManager:Send_ServerToAllClients("xhs_creep_level_update", {
		level = level,
	})
	if CustomTimers ~= nil then
		CustomTimers.creep_level = math.max(CustomTimers.creep_level or level, level)
	end
	if XHSPersistQuestTimingState ~= nil then
		XHSPersistQuestTimingState()
	end

	Notifications:TopToAll({ text = "Creep Level " .. level .. " enabled!", style = { color = "lightgreen" }, duration = 5.0 })
end

-- this function is not used anymore
function SpawnRevenant(event)
	local caller = event.caller
	local cn = string.gsub(caller:GetName(), "dota_badguys_tower", "")
	local difficulty = GameRules:GetCustomGameDifficulty()
	local player = PlayerResource:GetPlayer(tonumber(cn) - 1)

	for j = 1, difficulty do
		if caller:GetUnitName() == "xhs_tower_lane_1" and CREEP_LANES[tonumber(cn)][2] < 2 then
			CreateUnitByName("xhs_death_revenant", caller:GetAbsOrigin(), true, nil, nil, DOTA_TEAM_CUSTOM_1)
			--			CREEP_LANES[tonumber(cn)][2] = CREEP_LANES[tonumber(cn)][2] + 1
			--			Notifications:Bottom(player, {text="Your creep lane is now level "..CREEP_LANES[tonumber(cn)][2].."!", duration=5.0, style={color="green"}})
		elseif caller:GetUnitName() == "xhs_tower_lane_2" and CREEP_LANES[tonumber(cn)][2] < 3 then
			CreateUnitByName("xhs_death_revenant_2", caller:GetAbsOrigin(), true, nil, nil, DOTA_TEAM_CUSTOM_1)
			--			CREEP_LANES[tonumber(cn)][2] = CREEP_LANES[tonumber(cn)][2] + 1
			--			Notifications:Bottom(player, {text="Your creep lane is now level "..CREEP_LANES[tonumber(cn)][2].."!", duration=5.0, style={color="green"}})
		end
	end
end

function SpawnMagnataur(hPos)
	for i = 1, GameRules:GetCustomGameDifficulty() do
		local unit = CreateUnitByName("npc_magnataur_destroyer_crypt", hPos, true, nil, nil, DOTA_TEAM_CUSTOM_1)
		OrderWaveCreep(unit, nil)
	end
end

function SpawnDragons(dragon)
	for c = 1, 8 do
		if CREEP_LANES[c][1] == 1 and CREEP_LANES[c][3] == 1 then
			local point = Entities:FindByName(nil, "npc_dota_spawner_" .. c)
			local waypoint = Entities:FindByName(nil, "creep_path_" .. c)
			for j = 1, GameRules:GetCustomGameDifficulty() do
				SpawnWaveCreep(dragon, point, waypoint)
			end
		end
	end
end
