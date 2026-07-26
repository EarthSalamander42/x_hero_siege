local function IsBreakableLaneTarget(target)
	if target == nil or target:IsNull() or target.GetUnitName == nil then return false end

	local unitName = target:GetUnitName()
	return unitName == "npc_dota_crate" or unitName == "npc_dota_chest" or unitName == "npc_dota_vase"
end

local function GetBreakableLaneTarget(unit)
	if unit == nil or unit:IsNull() then return nil end

	local attackTarget = unit:GetAttackTarget()
	if IsBreakableLaneTarget(attackTarget) then return attackTarget end

	local aggroTarget = unit:GetAggroTarget()
	if IsBreakableLaneTarget(aggroTarget) then return aggroTarget end

	return nil
end

local function ClearBreakableLaneTarget(unit, target)
	if unit == nil or unit:IsNull() or not IsBreakableLaneTarget(target) then return false end

	unit:SetForceAttackTarget(nil)
	if unit.SetAttacking ~= nil then
		unit:SetAttacking(nil)
	end
	unit:Stop()
	return true
end

local function MoveCreepPastBreakable(unit, destination)
	if unit == nil or unit:IsNull() or destination == nil or destination.GetAbsOrigin == nil then return end

	-- Do not immediately issue ATTACK_MOVE again: that makes the native AI
	-- reacquire the same crate every frame. Give the creep a short movement-only
	-- window so it actually clears the breakable's collision/aggro radius.
	unit.xhs_breakable_ignore_until = GameRules:GetGameTime() + 1.5
	local origin = unit:GetAbsOrigin()
	local destinationPosition = destination:GetAbsOrigin()
	local direction = destinationPosition - origin
	direction.z = 0
	if direction:Length2D() > 0 then
		direction = direction:Normalized()
		destinationPosition = origin + direction * 500
	end
	ExecuteOrderFromTable({
		UnitIndex = unit:entindex(),
		OrderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION,
		Position = destinationPosition,
	})
end

local function StartDestroyerMagnataurAbilityAI(unit)
	if unit == nil or unit:IsNull() or unit:GetUnitName() ~= "npc_magnataur_destroyer_crypt" then return end
	if unit.xhs_destroyer_ability_ai_started == true then return end

	unit.xhs_destroyer_ability_ai_started = true

	Timers:CreateTimer(RandomFloat(0.2, 0.6), function()
		if unit == nil or unit:IsNull() or not unit:IsAlive() then return nil end

		local thunderClap = unit:FindAbilityByName("creature_thunder_clap_low")
		if thunderClap == nil or thunderClap:GetLevel() <= 0 then return 0.25 end
		if not thunderClap:IsFullyCastable() or unit:IsStunned() or unit:IsSilenced() or unit:IsChanneling() then
			return 0.25
		end

		local radius = thunderClap:GetSpecialValueFor("radius")
		if radius == nil or radius <= 0 then radius = 350 end

		local enemies = FindUnitsInRadius(
			unit:GetTeamNumber(),
			unit:GetAbsOrigin(),
			nil,
			radius,
			DOTA_UNIT_TARGET_TEAM_ENEMY,
			DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
			DOTA_UNIT_TARGET_FLAG_NONE,
			FIND_CLOSEST,
			false
		)

		if #enemies > 0 then
			ExecuteOrderFromTable({
				UnitIndex = unit:entindex(),
				OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET,
				AbilityIndex = thunderClap:entindex(),
			})
			return 0.5
		end

		return 0.25
	end)
end

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
		StartDestroyerMagnataurAbilityAI(unit)
	end

	if waypoint ~= nil and unit.SetInitialGoalEntity ~= nil then
		unit:SetInitialGoalEntity(waypoint)
	end

	local target = waypoint or BASE_GOOD
	if target == nil or target.GetAbsOrigin == nil then return end
	local finalDestination = BASE_GOOD or target

	Timers:CreateTimer(0.25, function()
		if unit == nil or unit:IsNull() or not unit:IsAlive() then return nil end

		if ClearBreakableLaneTarget(unit, GetBreakableLaneTarget(unit)) then
			MoveCreepPastBreakable(unit, finalDestination)
			return 0.25
		end

		if unit.xhs_breakable_ignore_until ~= nil and GameRules:GetGameTime() < unit.xhs_breakable_ignore_until then
			return 0.25
		end

		return 0.25
	end)

	Timers:CreateTimer(0.1, function()
		if unit == nil or unit:IsNull() or not unit:IsAlive() then return nil end
		if ClearBreakableLaneTarget(unit, GetBreakableLaneTarget(unit)) then
			MoveCreepPastBreakable(unit, finalDestination)
			return nil
		end
		ExecuteOrderFromTable({
			UnitIndex = unit:entindex(),
			OrderType = DOTA_UNIT_ORDER_ATTACK_MOVE,
			Position = target:GetAbsOrigin(),
		})

		return nil
	end)

	Timers:CreateTimer(8.0, function()
		if unit == nil or unit:IsNull() or not unit:IsAlive() then return nil end
		if unit.xhs_breakable_ignore_until ~= nil and GameRules:GetGameTime() < unit.xhs_breakable_ignore_until then return nil end
		if unit:GetAttackTarget() ~= nil then return nil end
		ExecuteOrderFromTable({
			UnitIndex = unit:entindex(),
			OrderType = DOTA_UNIT_ORDER_ATTACK_MOVE,
			Position = finalDestination:GetAbsOrigin(),
		})

		return nil
	end)
end

function SpawnReleasedPhaseOneCreep(unitName, position)
	local unit = CreateUnitByName(unitName, position, true, nil, nil, DOTA_TEAM_CUSTOM_1)
	if unit ~= nil then
		OrderWaveCreep(unit, nil)
	end
	return unit
end

local function DestroyPhaseOneStructure(structure, attacker)
	if structure == nil or structure:IsNull() or not structure:IsAlive() then return false end

	structure:RemoveModifierByName("modifier_invulnerable")
	structure:Kill(nil, attacker or structure)
	return true
end

function CollapsePhaseOneLane(lane, attacker)
	lane = tonumber(lane)
	if lane == nil then return end

	for _, tower in pairs(Entities:FindAllByName("dota_badguys_tower" .. lane)) do
		DestroyPhaseOneStructure(tower, attacker)
	end

	for _, rax in pairs(Entities:FindAllByName("dota_badguys_barracks_" .. lane)) do
		DestroyPhaseOneStructure(rax, attacker)
	end

	if CREEP_LANES[lane] ~= nil then
		CREEP_LANES[lane][3] = 0
	end
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
			local hasBreakableTarget = unit ~= nil and not unit:IsNull() and ClearBreakableLaneTarget(unit, GetBreakableLaneTarget(unit))
			if hasBreakableTarget then
				MoveCreepPastBreakable(unit, target)
			elseif unit ~= nil and not unit:IsNull() and unit:IsAlive() and unit:HasMovementCapability() and not unit.Boss and unit.xhs_breakable_ignore_until ~= nil and GameRules:GetGameTime() < unit.xhs_breakable_ignore_until then
				-- Keep the movement-only order until the creep has passed the crate.
			elseif unit ~= nil and not unit:IsNull() and unit:IsAlive() and unit:HasMovementCapability() and not unit.Boss and unit:GetAttackTarget() == nil and not unit:HasModifier("modifier_cinematic_pause") then
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

		if point ~= nil and not point.disabled then
			if CREEP_LANES[c][1] == 1 then -- Lane Activated?
				if CREEP_LANES[c][3] == 1 then -- Barrack Alive?
					local meleeCount = 4
					local rangedCount = 2

					-- The 4-player map keeps two visual lanes per player: the first
					-- lane carries melee creeps and the second carries ranged creeps.
					if CREEP_LANES_TYPE == 2 then
						if c % 2 == 1 then
							rangedCount = 0
						else
							meleeCount = 0
						end
					end

					if CREEP_LANES[c][2] == 1 then -- Lane Level
						for j = 1, meleeCount do
							SpawnWaveCreep(melee_1[GameMode.creep_roll["race"]], point, waypoint)
						end
						for j = 1, rangedCount do
							SpawnWaveCreep(ranged_1[GameMode.creep_roll["race"]], point, waypoint)
						end
					elseif CREEP_LANES[c][2] == 2 then
						for j = 1, meleeCount do
							SpawnWaveCreep(melee_2[GameMode.creep_roll["race"]], point, waypoint)
						end
						for j = 1, rangedCount do
							SpawnWaveCreep(ranged_2[GameMode.creep_roll["race"]], point, waypoint)
						end
					elseif CREEP_LANES[c][2] == 3 then
						for j = 1, meleeCount do
							SpawnWaveCreep(melee_3[GameMode.creep_roll["race"]], point, waypoint)
						end
						for j = 1, rangedCount do
							SpawnWaveCreep(ranged_3[GameMode.creep_roll["race"]], point, waypoint)
						end
					elseif CREEP_LANES[c][2] >= 4 then
						for j = 1, meleeCount do
							SpawnWaveCreep(melee_4[GameMode.creep_roll["race"]], point, waypoint)
						end
						for j = 1, rangedCount do
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
	level = tonumber(level)
	if level == nil or level < 1 or level > 4 then return end

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
	local firstMagnataur = nil
	for i = 1, GameRules:GetCustomGameDifficulty() do
		local unit = CreateUnitByName("npc_magnataur_destroyer_crypt", hPos, true, nil, nil, DOTA_TEAM_CUSTOM_1)
		OrderWaveCreep(unit, nil)
		firstMagnataur = firstMagnataur or unit
	end
	return firstMagnataur
end

function SpawnDragons(dragon)
	for c = 1, 8 do
		local isDragonLane = CREEP_LANES_TYPE ~= 2 or c % 2 == 0
		if isDragonLane and CREEP_LANES[c][1] == 1 and CREEP_LANES[c][3] == 1 then
			local point = Entities:FindByName(nil, "npc_dota_spawner_" .. c)
			local waypoint = Entities:FindByName(nil, "creep_path_" .. c)
			for j = 1, GameRules:GetCustomGameDifficulty() do
				SpawnWaveCreep(dragon, point, waypoint)
			end
		end
	end
end
