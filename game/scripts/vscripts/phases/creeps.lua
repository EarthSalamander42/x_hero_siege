LinkLuaModifier(
	"modifier_xhs_phase_one_wave_scaling",
	"modifiers/modifier_xhs_phase_one_wave_scaling.lua",
	LUA_MODIFIER_MOTION_NONE
)

local PHASE_ONE_SPAWN_SOFT_CAP = 100
local PHASE_ONE_SPAWN_HARD_CAP = 125
local PHASE_ONE_SPAWN_NOTICE_COOLDOWN = 90
local PHASE_ONE_SPAWN_NETTABLE = "xhs_phase_one_spawn_budget"
local PHASE_ONE_SPAWN_NETTABLE_KEY = "state"

local function GetPhaseOneSpawnBudgetRegistry()
	GameMode.phase_one_spawn_budget_units = GameMode.phase_one_spawn_budget_units or {}
	return GameMode.phase_one_spawn_budget_units
end

local function IsLivePhaseOneBudgetUnit(unit)
	return unit ~= nil
		and IsValidEntity(unit)
		and not unit:IsNull()
		and unit:IsAlive()
		and unit.xhs_phase_one_spawn_budget_enemy == true
end

local function CountPhaseOneBudgetEnemies()
	local registry = GetPhaseOneSpawnBudgetRegistry()
	local count = 0
	for entIndex, unit in pairs(registry) do
		if IsLivePhaseOneBudgetUnit(unit) then
			count = count + 1
		else
			registry[entIndex] = nil
		end
	end
	return count
end

function GetPhaseOneSpawnBudgetState()
	local state = GameMode.phase_one_spawn_budget_state or {}
	return {
		phase_active = state.phase_active == true and 1 or 0,
		pressure_active = state.pressure_active == true and 1 or 0,
		limited = state.limited == true and 1 or 0,
		active_units = tonumber(state.active_units) or 0,
		soft_cap = PHASE_ONE_SPAWN_SOFT_CAP,
		hard_cap = PHASE_ONE_SPAWN_HARD_CAP,
		planned = tonumber(state.planned) or 0,
		spawned = tonumber(state.spawned) or 0,
		skipped = tonumber(state.skipped) or 0,
		skipped_total = tonumber(GameMode.phase_one_spawn_budget_skipped_total) or 0,
		limited_waves = tonumber(GameMode.phase_one_spawn_budget_limited_waves) or 0,
		wave = tonumber(state.wave) or 0,
	}
end

local function PublishPhaseOneSpawnBudget(force)
	if CustomNetTables == nil then return end

	local isPhaseOne = CustomTimers ~= nil and tonumber(CustomTimers.game_phase) == 1
	local state = GameMode.phase_one_spawn_budget_state or {}
	local activeUnits = isPhaseOne and CountPhaseOneBudgetEnemies() or 0

	if activeUnits < PHASE_ONE_SPAWN_SOFT_CAP then
		state.pressure_active = false
		state.limited = false
		state.skipped = 0
		GameMode.phase_one_spawn_budget_notice_active = false
	end

	state.phase_active = isPhaseOne
	state.active_units = activeUnits
	state.pressure_active = isPhaseOne
		and (activeUnits >= PHASE_ONE_SPAWN_SOFT_CAP or state.limited == true)
	GameMode.phase_one_spawn_budget_state = state

	local payload = GetPhaseOneSpawnBudgetState()
	local signature = table.concat({
		payload.phase_active,
		payload.pressure_active,
		payload.limited,
		payload.active_units,
		payload.planned,
		payload.spawned,
		payload.skipped,
		payload.skipped_total,
		payload.limited_waves,
		payload.wave,
	}, ":")
	if force ~= true and signature == GameMode.phase_one_spawn_budget_signature then return end

	GameMode.phase_one_spawn_budget_signature = signature
	CustomNetTables:SetTableValue(PHASE_ONE_SPAWN_NETTABLE, PHASE_ONE_SPAWN_NETTABLE_KEY, payload)
end

local function SchedulePhaseOneSpawnBudgetPublish()
	if GameMode.phase_one_spawn_budget_publish_scheduled == true then return end
	if Timers == nil or Timers.CreateTimer == nil then
		PublishPhaseOneSpawnBudget(false)
		return
	end
	GameMode.phase_one_spawn_budget_publish_scheduled = true

	Timers:CreateTimer(0.25, function()
		GameMode.phase_one_spawn_budget_publish_scheduled = false
		PublishPhaseOneSpawnBudget(false)
		return nil
	end)
end

function RegisterPhaseOneBudgetEnemy(unit)
	if CustomTimers == nil or tonumber(CustomTimers.game_phase) ~= 1 then return unit end
	if unit == nil or unit:IsNull() or unit:GetTeamNumber() ~= DOTA_TEAM_CUSTOM_1 or unit.Boss then return unit end

	unit.xhs_phase_one_spawn_budget_enemy = true
	GetPhaseOneSpawnBudgetRegistry()[unit:entindex()] = unit
	SchedulePhaseOneSpawnBudgetPublish()
	return unit
end

function ResetPhaseOneSpawnBudget(resetTotals)
	GameMode.phase_one_spawn_budget_units = {}
	GameMode.phase_one_spawn_budget_state = {
		phase_active = false,
		pressure_active = false,
		limited = false,
		active_units = 0,
		planned = 0,
		spawned = 0,
		skipped = 0,
		wave = 0,
	}
	GameMode.phase_one_spawn_budget_notice_active = false
	if resetTotals == true then
		GameMode.phase_one_spawn_budget_skipped_total = 0
		GameMode.phase_one_spawn_budget_limited_waves = 0
		GameMode.phase_one_spawn_budget_last_notice = nil
		GameMode.phase_one_spawn_budget_lane_cursor = 1
	end
	PublishPhaseOneSpawnBudget(true)
end

local function CalculatePhaseOneWaveAllowance(plannedUnits)
	plannedUnits = math.max(0, math.floor(tonumber(plannedUnits) or 0))
	local activeUnits = CountPhaseOneBudgetEnemies()
	if plannedUnits <= 0 or activeUnits >= PHASE_ONE_SPAWN_HARD_CAP then
		return 0, activeUnits
	end

	local allowance = math.min(plannedUnits, PHASE_ONE_SPAWN_HARD_CAP - activeUnits)
	if activeUnits >= PHASE_ONE_SPAWN_SOFT_CAP then
		local pressureRoom = PHASE_ONE_SPAWN_HARD_CAP - PHASE_ONE_SPAWN_SOFT_CAP
		local remainingRatio = math.max(
			0,
			math.min(1, (PHASE_ONE_SPAWN_HARD_CAP - activeUnits) / pressureRoom)
		)
		allowance = math.min(
			allowance,
			math.floor(plannedUnits * remainingRatio + 0.5)
		)
	end

	return math.max(0, allowance), activeUnits
end

local function BuildFairLaneQuotas(lanePlans, allowance)
	local quotas = {}
	local laneCount = #lanePlans
	if laneCount <= 0 or allowance <= 0 then return quotas end

	local cursor = math.max(1, tonumber(GameMode.phase_one_spawn_budget_lane_cursor) or 1)
	cursor = ((cursor - 1) % laneCount) + 1
	local remaining = allowance
	local lastGrantedIndex = cursor

	while remaining > 0 do
		local grantedThisPass = false
		for offset = 0, laneCount - 1 do
			local planIndex = ((cursor - 1 + offset) % laneCount) + 1
			local plan = lanePlans[planIndex]
			local granted = quotas[plan.lane] or 0
			if granted < plan.capacity then
				quotas[plan.lane] = granted + 1
				remaining = remaining - 1
				lastGrantedIndex = planIndex
				grantedThisPass = true
				if remaining <= 0 then break end
			end
		end
		if not grantedThisPass then break end
	end

	GameMode.phase_one_spawn_budget_lane_cursor = (lastGrantedIndex % laneCount) + 1
	return quotas
end

local function RecordPhaseOneWaveBudget(planned, spawned, wave)
	local skipped = math.max(0, planned - spawned)
	local activeUnits = CountPhaseOneBudgetEnemies()
	local limited = skipped > 0

	if limited then
		GameMode.phase_one_spawn_budget_skipped_total =
			(tonumber(GameMode.phase_one_spawn_budget_skipped_total) or 0) + skipped
		GameMode.phase_one_spawn_budget_limited_waves =
			(tonumber(GameMode.phase_one_spawn_budget_limited_waves) or 0) + 1

		local now = GameRules:GetGameTime()
		local lastNotice = tonumber(GameMode.phase_one_spawn_budget_last_notice) or -PHASE_ONE_SPAWN_NOTICE_COOLDOWN
		if GameMode.phase_one_spawn_budget_notice_active ~= true
			and now - lastNotice >= PHASE_ONE_SPAWN_NOTICE_COOLDOWN then
			GameMode.phase_one_spawn_budget_notice_active = true
			GameMode.phase_one_spawn_budget_last_notice = now
		end
	end

	GameMode.phase_one_spawn_budget_state = {
		phase_active = true,
		pressure_active = activeUnits >= PHASE_ONE_SPAWN_SOFT_CAP or limited,
		limited = limited,
		active_units = activeUnits,
		planned = planned,
		spawned = spawned,
		skipped = skipped,
		wave = wave,
	}
	PublishPhaseOneSpawnBudget(true)
end

ListenToGameEvent("entity_killed", function(event)
	local entIndex = tonumber(event.entindex_killed)
	if entIndex == nil then return end

	local registry = GetPhaseOneSpawnBudgetRegistry()
	if registry[entIndex] == nil then return end

	registry[entIndex] = nil
	SchedulePhaseOneSpawnBudgetPublish()
end, nil)

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

local function SetWaveMovementOwner(unit)
	if unit == nil or unit:IsNull() then return nil end
	local hasModifierAI = unit:HasModifier("modifier_ai")
	if hasModifierAI then
		unit.xhs_wave_order_controller = false
		if XHSCreepOrderOwnership ~= nil then
			XHSCreepOrderOwnership:Claim(
				unit,
				XHSCreepOrderOwnership.OWNER_MODIFIER_AI,
				true
			)
		end
		return "modifier_ai"
	end

	unit.xhs_wave_order_controller = true
	if XHSCreepOrderOwnership ~= nil then
		XHSCreepOrderOwnership:Claim(
			unit,
			XHSCreepOrderOwnership.OWNER_WAVE,
			true
		)
	end
	return "wave"
end

local function IssueWaveMovementOrder(unit, order, minimumInterval)
	if XHSCreepOrderOwnership ~= nil then
		return XHSCreepOrderOwnership:Issue(
			unit,
			XHSCreepOrderOwnership.OWNER_WAVE,
			order,
			minimumInterval
		)
	end
	ExecuteOrderFromTable(order)
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
	IssueWaveMovementOrder(unit, {
		UnitIndex = unit:entindex(),
		OrderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION,
		Position = destinationPosition,
	}, 1.0)
end

local function OrderWaveCreep(unit, waypoint)
	if unit == nil or unit:IsNull() then return end
	unit.xhs_wave_unit = true
	SetWaveMovementOwner(unit)

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
	local finalDestination = BASE_GOOD or target

	Timers:CreateTimer(0.1, function()
		if unit == nil or unit:IsNull() or not unit:IsAlive() then return nil end
		if SetWaveMovementOwner(unit) == "modifier_ai" then return nil end
		if ClearBreakableLaneTarget(unit, GetBreakableLaneTarget(unit)) then
			MoveCreepPastBreakable(unit, finalDestination)
			return nil
		end
		IssueWaveMovementOrder(unit, {
			UnitIndex = unit:entindex(),
			OrderType = DOTA_UNIT_ORDER_ATTACK_MOVE,
			Position = target:GetAbsOrigin(),
		}, 1.0)

		return nil
	end)

	Timers:CreateTimer(8.0, function()
		if unit == nil or unit:IsNull() or not unit:IsAlive() then return nil end
		if SetWaveMovementOwner(unit) == "modifier_ai" then return nil end
		if unit.xhs_breakable_ignore_until ~= nil and GameRules:GetGameTime() < unit.xhs_breakable_ignore_until then return nil end
		if unit:GetAttackTarget() ~= nil then return nil end
		IssueWaveMovementOrder(unit, {
			UnitIndex = unit:entindex(),
			OrderType = DOTA_UNIT_ORDER_ATTACK_MOVE,
			Position = finalDestination:GetAbsOrigin(),
		}, 2.5)

		return nil
	end)
end

function SpawnReleasedPhaseOneCreep(unitName, position)
	local unit = CreateUnitByName(unitName, position, true, nil, nil, DOTA_TEAM_CUSTOM_1)
	if unit ~= nil then
		RegisterPhaseOneBudgetEnemy(unit)
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

local function ApplyPhaseOneWaveScaling(unit, level, progress)
	if unit == nil or unit:IsNull() then return end

	level = math.max(1, math.min(4, tonumber(level) or 1))
	progress = math.max(0, math.min(1, tonumber(progress) or 0))

	unit:AddNewModifier(unit, nil, "modifier_xhs_phase_one_wave_scaling", {
		level = level,
		progress = progress,
	})
	if unit.CalculateStatBonus ~= nil then
		unit:CalculateStatBonus(true)
	end
	unit:SetHealth(unit:GetMaxHealth())
end

local function SpawnWaveCreep(unitName, point, waypoint, level, progress)
	if point == nil then return nil end

	local unit = CreateUnitByName(unitName, point:GetAbsOrigin(), true, nil, nil, DOTA_TEAM_CUSTOM_1)
	RegisterPhaseOneBudgetEnemy(unit)
	if level ~= nil then
		ApplyPhaseOneWaveScaling(unit, level, progress)
	end
	OrderWaveCreep(unit, waypoint)
	return unit
end

function ReissueWaveCreepOrders(delay)
	local target = BASE_GOOD
	if target == nil or target.GetAbsOrigin == nil then return end
	if GameMode.xhs_wave_reissue_pending == true then return end
	GameMode.xhs_wave_reissue_pending = true

	Timers:CreateTimer(delay or 0.1, function()
		GameMode.xhs_wave_reissue_pending = false
		local units = FindUnitsInRadius(DOTA_TEAM_CUSTOM_1, Vector(0, 0, 0), nil, FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_FLAG_INVULNERABLE, FIND_ANY_ORDER, false)
		for _, unit in pairs(units) do
			if unit ~= nil and not unit:IsNull() and unit:HasModifier("modifier_ai") then
				SetWaveMovementOwner(unit)
				-- modifier_ai already owns recovery after its target dies. Issuing
				-- another ATTACK_MOVE here made one hero death fan out into an
				-- order/pathfinding burst across every living phase-one creep.
			elseif unit ~= nil and not unit:IsNull() then
				SetWaveMovementOwner(unit)
				local hasBreakableTarget = ClearBreakableLaneTarget(
					unit,
					GetBreakableLaneTarget(unit)
				)
				if hasBreakableTarget then
					MoveCreepPastBreakable(unit, target)
				elseif unit:IsAlive() and unit:HasMovementCapability() and not unit.Boss and unit.xhs_breakable_ignore_until ~= nil and GameRules:GetGameTime() < unit.xhs_breakable_ignore_until then
					-- Keep the movement-only order until the creep has passed the crate.
				elseif unit:IsAlive() and unit:HasMovementCapability() and not unit.Boss and unit:GetAttackTarget() == nil and not unit:HasModifier("modifier_cinematic_pause") then
					IssueWaveMovementOrder(unit, {
						UnitIndex = unit:entindex(),
						OrderType = DOTA_UNIT_ORDER_ATTACK_MOVE,
						Position = target:GetAbsOrigin(),
					}, 2.5)
				end
			end
		end

		return nil
	end)
end

function SpawnCreeps(force)
	if force ~= true and XHSDevTools ~= nil and XHSDevTools:IsSandboxActive() then return end

	local waveLevel = math.max(1, math.min(4, tonumber(CustomTimers and CustomTimers.creep_level) or 1))
	if GameMode.phase_one_scaling_level ~= waveLevel then
		GameMode.phase_one_scaling_level = waveLevel
		GameMode.phase_one_scaling_wave = 0
	end

	local wavesPerLevel = math.max(2, math.floor(XHS_CREEPS_UPGRADE_INTERVAL / XHS_CREEPS_INTERVAL) + 1)
	local waveIndex = math.max(0, tonumber(GameMode.phase_one_scaling_wave) or 0)
	local waveProgress = math.min(1, waveIndex / (wavesPerLevel - 1))
	GameMode.phase_one_scaling_progress = waveProgress

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

	local meleeByLevel = { melee_1, melee_2, melee_3, melee_4 }
	local rangedByLevel = { ranged_1, ranged_2, ranged_3, ranged_4 }
	local lanePlans = {}
	local plannedUnits = 0

	for c = 1, 8 do
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

					local laneLevel = math.max(1, math.min(4, tonumber(CREEP_LANES[c][2]) or waveLevel))
					local capacity = meleeCount + rangedCount
					table.insert(lanePlans, {
						lane = c,
						point = point,
						waypoint = waypoint,
						level = laneLevel,
						melee_count = meleeCount,
						ranged_count = rangedCount,
						capacity = capacity,
					})
					plannedUnits = plannedUnits + capacity
				end
			end
		else
			print("Barracks: Spawner " .. c .. " disabled.")
		end
	end

	local allowance = CalculatePhaseOneWaveAllowance(plannedUnits)
	local quotas = BuildFairLaneQuotas(lanePlans, allowance)
	local spawnedUnits = 0
	local race = GameMode.creep_roll["race"]

	for _, plan in ipairs(lanePlans) do
		local quota = math.max(0, math.min(plan.capacity, quotas[plan.lane] or 0))
		local meleeToSpawn = 0
		local rangedToSpawn = 0

		if plan.ranged_count <= 0 then
			meleeToSpawn = math.min(plan.melee_count, quota)
		elseif plan.melee_count <= 0 then
			rangedToSpawn = math.min(plan.ranged_count, quota)
		else
			meleeToSpawn = math.min(plan.melee_count, math.ceil(quota * 2 / 3))
			rangedToSpawn = math.min(plan.ranged_count, quota - meleeToSpawn)
			while meleeToSpawn + rangedToSpawn < quota and meleeToSpawn < plan.melee_count do
				meleeToSpawn = meleeToSpawn + 1
			end
			while meleeToSpawn + rangedToSpawn < quota and rangedToSpawn < plan.ranged_count do
				rangedToSpawn = rangedToSpawn + 1
			end
		end

		for _ = 1, meleeToSpawn do
			if SpawnWaveCreep(
				meleeByLevel[plan.level][race],
				plan.point,
				plan.waypoint,
				plan.level,
				waveProgress
			) ~= nil then
				spawnedUnits = spawnedUnits + 1
			end
		end
		for _ = 1, rangedToSpawn do
			if SpawnWaveCreep(
				rangedByLevel[plan.level][race],
				plan.point,
				plan.waypoint,
				plan.level,
				waveProgress
			) ~= nil then
				spawnedUnits = spawnedUnits + 1
			end
		end
	end

	RecordPhaseOneWaveBudget(plannedUnits, spawnedUnits, waveIndex + 1)
	GameMode.phase_one_scaling_wave = waveIndex + 1
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
	GameMode.phase_one_scaling_level = level
	GameMode.phase_one_scaling_wave = 0
	GameMode.phase_one_scaling_progress = 0
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
			RegisterPhaseOneBudgetEnemy(CreateUnitByName("xhs_death_revenant", caller:GetAbsOrigin(), true, nil, nil, DOTA_TEAM_CUSTOM_1))
			--			CREEP_LANES[tonumber(cn)][2] = CREEP_LANES[tonumber(cn)][2] + 1
			--			Notifications:Bottom(player, {text="Your creep lane is now level "..CREEP_LANES[tonumber(cn)][2].."!", duration=5.0, style={color="green"}})
		elseif caller:GetUnitName() == "xhs_tower_lane_2" and CREEP_LANES[tonumber(cn)][2] < 3 then
			RegisterPhaseOneBudgetEnemy(CreateUnitByName("xhs_death_revenant_2", caller:GetAbsOrigin(), true, nil, nil, DOTA_TEAM_CUSTOM_1))
			--			CREEP_LANES[tonumber(cn)][2] = CREEP_LANES[tonumber(cn)][2] + 1
			--			Notifications:Bottom(player, {text="Your creep lane is now level "..CREEP_LANES[tonumber(cn)][2].."!", duration=5.0, style={color="green"}})
		end
	end
end

function SpawnMagnataur(hPos)
	local firstMagnataur = nil
	local spawnedMagnataurs = {}
	local x = hPos ~= nil and tonumber(hPos.x) or nil
	local y = hPos ~= nil and tonumber(hPos.y) or nil
	local z = hPos ~= nil and tonumber(hPos.z) or nil
	if x == nil or y == nil or z == nil then
		print(
			"[XHS Phase2] SpawnMagnataur rejected invalid position type="
				.. tostring(type(hPos))
		)
		return nil, spawnedMagnataurs
	end
	-- Rebuild a native Vector at the engine boundary. Some map entity origins
	-- arrive here as vector-like userdata that expose x/y/z but fail the
	-- CreateUnitByName binding with "Parameter type mismatch".
	local spawnPosition = Vector(x, y, z)
	local teamNumber = tonumber(DOTA_TEAM_CUSTOM_1) or 6
	for i = 1, GameRules:GetCustomGameDifficulty() do
		local ok, unitOrError = xpcall(function()
			return CreateUnitByName(
				"npc_magnataur_destroyer_crypt",
				spawnPosition,
				true,
				nil,
				nil,
				teamNumber
			)
		end, debug.traceback)
		local unit = ok and unitOrError or nil
		if unit ~= nil and not unit:IsNull() then
			RegisterPhaseOneBudgetEnemy(unit)
			OrderWaveCreep(unit, nil)
			firstMagnataur = firstMagnataur or unit
			table.insert(spawnedMagnataurs, unit)
		else
			print(
				"[XHS Phase2] SpawnMagnataur failed index="
					.. tostring(i)
					.. " position=" .. tostring(spawnPosition)
					.. " error=" .. tostring(unitOrError)
			)
		end
	end
	return firstMagnataur, spawnedMagnataurs
end

local DRAGON_RENDER_COLORS = {
	npc_dota_creature_red_dragon = { 220, 70, 55 },
	npc_dota_creature_black_dragon = { 70, 70, 80 },
	npc_dota_creature_green_dragon = { 80, 180, 95 },
}

function SpawnDragons(dragon)
	local difficulty = math.max(1, GameRules:GetCustomGameDifficulty())

	for c = 1, 8 do
		local isDragonLane = CREEP_LANES_TYPE ~= 2 or c % 2 == 0
		if isDragonLane and CREEP_LANES[c][1] == 1 and CREEP_LANES[c][3] == 1 then
			local point = Entities:FindByName(nil, "npc_dota_spawner_" .. c)
			local waypoint = Entities:FindByName(nil, "creep_path_" .. c)
			for j = 1, difficulty do
				local spawnedDragon = SpawnWaveCreep(dragon, point, waypoint)
				if spawnedDragon ~= nil then
					local color = DRAGON_RENDER_COLORS[dragon]
					if color ~= nil then
						spawnedDragon:SetRenderColor(color[1], color[2], color[3])
					end

					-- Difficulty increases the number of dragons for combat, not
					-- the lane's total economy. OnNPCSpawned has already applied
					-- the difficulty bounty multiplier, so split that resulting
					-- bounty evenly between every dragon spawned on this lane.
					local splitBounty = math.max(0, math.floor(spawnedDragon:GetGoldBounty() / difficulty))
					spawnedDragon:SetMinimumGoldBounty(splitBounty)
					spawnedDragon:SetMaximumGoldBounty(splitBounty)
				end
			end
		end
	end
end
