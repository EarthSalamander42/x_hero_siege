LinkLuaModifier(
	"modifier_xhs_phase_one_wave_scaling",
	"modifiers/modifier_xhs_phase_one_wave_scaling.lua",
	LUA_MODIFIER_MOTION_NONE
)

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

local function OrderWaveCreep(unit, waypoint)
	if unit == nil or unit:IsNull() then return end
	unit.xhs_wave_order_controller = true

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
	if level ~= nil then
		ApplyPhaseOneWaveScaling(unit, level, progress)
	end
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
							SpawnWaveCreep(melee_1[GameMode.creep_roll["race"]], point, waypoint, 1, waveProgress)
						end
						for j = 1, rangedCount do
							SpawnWaveCreep(ranged_1[GameMode.creep_roll["race"]], point, waypoint, 1, waveProgress)
						end
					elseif CREEP_LANES[c][2] == 2 then
						for j = 1, meleeCount do
							SpawnWaveCreep(melee_2[GameMode.creep_roll["race"]], point, waypoint, 2, waveProgress)
						end
						for j = 1, rangedCount do
							SpawnWaveCreep(ranged_2[GameMode.creep_roll["race"]], point, waypoint, 2, waveProgress)
						end
					elseif CREEP_LANES[c][2] == 3 then
						for j = 1, meleeCount do
							SpawnWaveCreep(melee_3[GameMode.creep_roll["race"]], point, waypoint, 3, waveProgress)
						end
						for j = 1, rangedCount do
							SpawnWaveCreep(ranged_3[GameMode.creep_roll["race"]], point, waypoint, 3, waveProgress)
						end
					elseif CREEP_LANES[c][2] >= 4 then
						for j = 1, meleeCount do
							SpawnWaveCreep(melee_4[GameMode.creep_roll["race"]], point, waypoint, 4, waveProgress)
						end
						for j = 1, rangedCount do
							SpawnWaveCreep(ranged_4[GameMode.creep_roll["race"]], point, waypoint, 4, waveProgress)
						end
					end
				end
			end
		else
			print("Barracks: Spawner " .. c .. " disabled.")
		end
	end

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
	local spawnedMagnataurs = {}
	for i = 1, GameRules:GetCustomGameDifficulty() do
		local unit = CreateUnitByName("npc_magnataur_destroyer_crypt", hPos, true, nil, nil, DOTA_TEAM_CUSTOM_1)
		OrderWaveCreep(unit, nil)
		firstMagnataur = firstMagnataur or unit
		table.insert(spawnedMagnataurs, unit)
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
