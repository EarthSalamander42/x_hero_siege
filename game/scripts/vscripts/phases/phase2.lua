local function FormatPhase2CreepTimer(seconds)
	seconds = math.max(0, math.floor(seconds or 0))
	return tostring(math.floor(seconds / 60)) .. ":" .. string.format("%02d", seconds % 60)
end

local function ActivatePhase2CreepTimer()
	if XHSSetGlobalObjectiveState == nil or CustomTimers == nil then return end

	local remaining = math.max(0, (CustomTimers.current_time and CustomTimers.current_time["special_event"] or XHS_SPECIAL_EVENT_INTERVAL) - 1)
	XHSSetGlobalObjectiveState("phase2_creeps", "Active", "Phase 2 creeps: " .. FormatPhase2CreepTimer(remaining), remaining)
end

local PHASE_2_WAVE_COUNTS = { left = 0, right = 0 }
local PHASE_2_SIDES = {
	left = {
		unit_name = "npc_ghul_II",
		spawner_name = "npc_dota_spawner_top_left_1",
		door_name = "door_phase2_left",
		obstruction_name = "obstruction_phase2_1",
	},
	right = {
		unit_name = "npc_orc_II",
		spawner_name = "npc_dota_spawner_top_right_1",
		door_name = "door_phase2_right",
		obstruction_name = "obstruction_phase2_2",
	},
}

function ResetPhase2CreepWaveCounts()
	PHASE_2_WAVE_COUNTS.left = 0
	PHASE_2_WAVE_COUNTS.right = 0
end

local function GetPhase2Sides(side)
	if side == "left" then return { "left" } end
	if side == "right" then return { "right" } end
	if side == "both" then return { "left", "right" } end
	return nil
end

function OpenPhase2Doors(side, cinematic, callback)
	local sides = GetPhase2Sides(side)
	if sides == nil then return false end

	local doors = {}
	local obstructions = {}
	for _, side_name in ipairs(sides) do
		local config = PHASE_2_SIDES[side_name]
		table.insert(doors, config.door_name)
		table.insert(obstructions, config.obstruction_name)
	end

	if cinematic == true and XHSOpenDoorsWithCinematic ~= nil then
		-- Both phase-two gates open together, but the reveal must stay on the
		-- first (left) gate so the camera does not frame the empty midpoint.
		local first_door = Entities:FindByName(nil, PHASE_2_SIDES.left.door_name)
		local camera_position = first_door ~= nil and first_door:GetAbsOrigin() or nil
		XHSOpenDoorsWithCinematic(doors, obstructions, "gate_entrance002_open", callback, {
			camera_position = camera_position,
			move_duration = 1.35,
			hold_duration = 1.25,
			return_duration = 1.0,
		})
		return true
	end

	for _, obstruction_name in ipairs(obstructions) do
		for _, obstruction in pairs(Entities:FindAllByName(obstruction_name)) do
			obstruction:SetEnabled(false, true)
		end
	end
	for _, door_name in ipairs(doors) do
		DoEntFire(door_name, "SetAnimation", "gate_entrance002_open", 0, nil, nil)
	end
	if callback ~= nil then callback() end
	return true
end

function SpawnPhase2CreepWave(side, register_dev_units)
	local sides = GetPhase2Sides(side)
	if sides == nil then return 0 end

	local difficulty = math.max(1, math.min(5, GameRules:GetCustomGameDifficulty() or 1))
	local spawned = 0

	for _, side_name in ipairs(sides) do
		local config = PHASE_2_SIDES[side_name]
		local spawner = Entities:FindByName(nil, config.spawner_name)
		if spawner == nil then
			error("Missing Phase 2 spawner: " .. config.spawner_name)
		end

		PHASE_2_WAVE_COUNTS[side_name] = PHASE_2_WAVE_COUNTS[side_name] + 1
		local wave_count = PHASE_2_WAVE_COUNTS[side_name]
		local point = spawner:GetAbsOrigin()

		for _ = 1, 8 do
			local unit = CreateUnitByName(config.unit_name, point + RandomVector(RandomInt(0, 50)), true, nil, nil, DOTA_TEAM_CUSTOM_1)
			if unit ~= nil then
				unit:SetBaseDamageMin(unit:GetRealDamageDone(unit) + (PHASE_2_UPGRADE["damage"][difficulty] * wave_count))
				unit:SetBaseDamageMax(unit:GetRealDamageDone(unit) + (PHASE_2_UPGRADE["damage"][difficulty] * wave_count) * 1.1)
				unit:SetMaxHealth(unit:GetMaxHealth() + (PHASE_2_UPGRADE["health"][difficulty] * wave_count))
				unit:SetBaseMaxHealth(unit:GetMaxHealth() + (PHASE_2_UPGRADE["health"][difficulty] * wave_count))
				unit:SetHealth(unit:GetMaxHealth())
				unit:SetPhysicalArmorBaseValue(unit:GetPhysicalArmorValue(false) + (PHASE_2_UPGRADE["armor"][difficulty] * wave_count))
				ApplyGrowthOverheadMarker(unit, wave_count)
				if register_dev_units == true and XHSDevTools ~= nil then
					XHSDevTools:RegisterSpawnedUnit(unit)
				end
				spawned = spawned + 1
			end
		end
	end

	return spawned
end

function StartPhase2()
	CustomTimers:IncrementGamePhase() -- Phase 1 to Phase 2
	CustomTimers.timers_paused = 0
	ActivatePhase2CreepTimer()
	ResetPhase2CreepWaveCounts()

	local combatParticipants = GetXHSCombatParticipantCount ~= nil
		and GetXHSCombatParticipantCount()
		or PlayerResource:GetPlayerCount()
	local multiplayer = combatParticipants > 1
	CustomTimers.phase2_active_ice_towers = multiplayer and { 1, 2 } or { 1 }
	CustomTimers.shal_lightbinder_released = false

	for c = 1, 8 do
		CREEP_LANES[c][1] = 0
		CREEP_LANES[c][3] = 0
	end

	OpenPhase2Doors(multiplayer and "both" or "left", true, function()
		Phase2CreepsLeft()
		if multiplayer then
			Phase2CreepsRight()
		end
	end)
end

function Phase2CreepsLeft()
	local EntIceTower = Entities:FindByName(nil, "npc_tower_cold_1")
	Timers:CreateTimer(function()
		if EntIceTower == nil or EntIceTower:IsNull() or not EntIceTower:IsAlive() or CustomTimers.proc_final_wave == true or CustomTimers.game_phase >= 3 then
			return nil
		elseif XHSDevTools ~= nil and XHSDevTools:IsSandboxActive() then
			return XHS_CREEPS_INTERVAL
		elseif CustomTimers.timers_paused == 0 then
			SpawnPhase2CreepWave("left", false)
			return XHS_CREEPS_INTERVAL
		else -- if CustomTimers.timers_paused == 1 or 2
			return XHS_CREEPS_INTERVAL
		end
	end)
end

function Phase2CreepsRight()
	local EntIceTower = Entities:FindByName(nil, "npc_tower_cold_2")
	Timers:CreateTimer(0, function()
		if EntIceTower == nil or EntIceTower:IsNull() or not EntIceTower:IsAlive() or CustomTimers.proc_final_wave == true or CustomTimers.game_phase >= 3 then
			return nil
		elseif XHSDevTools ~= nil and XHSDevTools:IsSandboxActive() then
			return 30
		elseif CustomTimers.timers_paused == 0 then
			SpawnPhase2CreepWave("right", false)
			return 30
		elseif CustomTimers.timers_paused ~= 0 then
			return 30
		end
	end)
end

local SHAL_LIGHTBINDER_UNIT_NAME = "npc_xhs_paladin"
local SHAL_RELEASE_CAMERA_MOVE_DURATION = 1.15
local SHAL_RELEASE_CAMERA_HOLD_DURATION = 2.35
local SHAL_RELEASE_FOW_RADIUS = 900
local SHAL_RELEASE_FOW_DURATION = 5.0
local SHAL_TOWER_EXIT_DISTANCE = 180
local SHAL_RELEASE_FROST_PARTICLE = "particles/units/heroes/hero_crystalmaiden/maiden_freezing_field_explosion.vpcf"
local SHAL_RELEASE_LIGHT_PARTICLE = "particles/units/heroes/hero_omniknight/omniknight_purification.vpcf"

local function IsValidPhase2Entity(entity)
	return entity ~= nil and IsValidEntity(entity) and not entity:IsNull()
end

local function GetGoodguysRealHeroes()
	local heroes = {}
	for _, hero in pairs(HeroList:GetAllHeroes()) do
		if IsValidPhase2Entity(hero) and hero:IsRealHero() and hero:GetTeamNumber() == DOTA_TEAM_GOODGUYS then
			table.insert(heroes, hero)
		end
	end
	return heroes
end

local function GetClosestEntity(origin, entities)
	local closest = nil
	local closestDistance = nil
	for _, entity in pairs(entities) do
		if IsValidPhase2Entity(entity) then
			local distance = (entity:GetAbsOrigin() - origin):Length2D()
			if closestDistance == nil or distance < closestDistance then
				closest = entity
				closestDistance = distance
			end
		end
	end
	return closest
end

local function RefreshPhase2VIPNetTable()
	if CDungeonZone == nil or CDungeonZone.VIPsAlive == nil then return end

	local netTable = {}
	for index, vip in pairs(CDungeonZone.VIPsAlive) do
		if IsValidPhase2Entity(vip) then
			netTable[index] = vip:entindex()
		end
	end
	CustomNetTables:SetTableValue("vips", string.format("%d", 0), netTable)
end

local function SpawnHiddenShalAtTower(tower)
	if not IsValidPhase2Entity(tower) then return nil end

	local shal = nil
	if CDungeonZone ~= nil and CDungeonZone.SpawnVIPs ~= nil then
		local previousCount = #(CDungeonZone.VIPsAlive or {})
		CDungeonZone:SpawnVIPs({
			{
				szVIPName = SHAL_LIGHTBINDER_UNIT_NAME,
				szSpawnerName = tower:GetName(),
				nCount = 1,
				Activity = ACT_DOTA_IDLE,
			},
		})
		shal = CDungeonZone.VIPsAlive and CDungeonZone.VIPsAlive[previousCount + 1] or nil
	end

	if not IsValidPhase2Entity(shal) then
		shal = CreateUnitByName(SHAL_LIGHTBINDER_UNIT_NAME, tower:GetAbsOrigin(), true, nil, nil, DOTA_TEAM_GOODGUYS)
		if IsValidPhase2Entity(shal) then
			shal.zone = CDungeonZone
			shal.isInHoldout = true
			shal.bRequired = false
			shal:AddNewModifier(shal, nil, "modifier_npc_dialog", { duration = -1 })
			if CDungeonZone ~= nil then
				CDungeonZone.VIPsAlive = CDungeonZone.VIPsAlive or {}
				table.insert(CDungeonZone.VIPsAlive, shal)
			end
		end
	end

	if IsValidPhase2Entity(shal) then
		shal.xhs_freed_shal_lightbinder = true
		shal:AddNoDraw()
		shal:SetAbsOrigin(tower:GetAbsOrigin())
	end

	return shal
end

local function GetShalExitDirection(towerOrigin, towerForward)
	local fort = Entities:FindByName(nil, "dota_goodguys_fort")
	if IsValidPhase2Entity(fort) then
		local towardFort = fort:GetAbsOrigin() - towerOrigin
		towardFort = Vector(towardFort.x, towardFort.y, 0)
		if towardFort:Length2D() > 1 then
			return towardFort:Normalized()
		end
	end

	local forward = Vector(towerForward.x, towerForward.y, 0)
	if forward:Length2D() > 1 then
		return forward:Normalized()
	end
	return Vector(0, -1, 0)
end

local function RevealFreedShal(record)
	local shal = record and record.shal or nil
	if not IsValidPhase2Entity(shal) then return end

	local direction = GetShalExitDirection(record.origin, record.forward)
	shal:RemoveNoDraw()
	shal:RemoveModifierByName("modifier_stack_count_animation_controller")
	shal:SetForwardVector(direction)
	FindClearSpaceForUnit(shal, record.origin + direction * SHAL_TOWER_EXIT_DISTANCE, true)
	shal:StartGesture(ACT_DOTA_CAST_ABILITY_3)

	local lightParticle = ParticleManager:CreateParticle(SHAL_RELEASE_LIGHT_PARTICLE, PATTACH_ABSORIGIN_FOLLOW, shal)
	ParticleManager:ReleaseParticleIndex(lightParticle)
end

local function PlayShalReleaseCamera(towers)
	for _, hero in pairs(GetGoodguysRealHeroes()) do
		local targetTower = GetClosestEntity(hero:GetAbsOrigin(), towers)
		local player = hero:GetPlayerOwner()
		if targetTower ~= nil and player ~= nil then
			local playerID = hero:GetPlayerOwnerID()
			CameraMotion:Sequence(playerID, {
				{
					type = "move",
					to = targetTower,
					from = hero,
					duration = SHAL_RELEASE_CAMERA_MOVE_DURATION,
					easing = "smootherstep",
				},
				{ type = "hold", duration = SHAL_RELEASE_CAMERA_HOLD_DURATION },
				{
					type = "return",
					to = function() return PlayerResource:GetSelectedHeroEntity(playerID) end,
					duration = 0.85,
					easing = "smootherstep",
				},
				{ type = "release", mode = "free" },
			}, {
				owner = "shal_release",
				priority = 70,
				policy = "replace",
			})
		end
	end
end

local function FindFreedShalLightbinders()
	local shals = {}
	local units = FindUnitsInRadius(
		DOTA_TEAM_GOODGUYS,
		Vector(0, 0, 0),
		nil,
		FIND_UNITS_EVERYWHERE,
		DOTA_UNIT_TARGET_TEAM_FRIENDLY,
		DOTA_UNIT_TARGET_ALL,
		DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
		FIND_ANY_ORDER,
		false
	)
	for _, unit in pairs(units) do
		if IsValidPhase2Entity(unit) and unit:IsAlive() and unit:GetUnitName() == SHAL_LIGHTBINDER_UNIT_NAME then
			table.insert(shals, unit)
		end
	end
	return shals
end

function XHSFocusPlayersOnShalLightbinder()
	local shals = FindFreedShalLightbinders()
	if #shals == 0 then return false end

	for _, hero in pairs(GetGoodguysRealHeroes()) do
		local shal = GetClosestEntity(hero:GetAbsOrigin(), shals)
		local player = hero:GetPlayerOwner()
		if shal ~= nil and player ~= nil then
			AddFOWViewer(DOTA_TEAM_GOODGUYS, shal:GetAbsOrigin(), SHAL_RELEASE_FOW_RADIUS, SHAL_RELEASE_FOW_DURATION, false)
			local playerID = hero:GetPlayerOwnerID()
			CameraMotion:Sequence(playerID, {
				{
					type = "move",
					to = shal,
					from = hero,
					duration = 0.65,
					easing = "smootherstep",
				},
				{ type = "hold", duration = 2.35 },
				{
					type = "return",
					to = function() return PlayerResource:GetSelectedHeroEntity(playerID) end,
					duration = 0.75,
					easing = "smootherstep",
				},
				{ type = "release", mode = "free" },
			}, {
				owner = "shal_lightbinder_focus",
				priority = 70,
				policy = "replace",
			})
		end
	end

	return true
end

function EndPhase2()
	if CustomTimers.shal_lightbinder_released == true then return end
	CustomTimers.shal_lightbinder_released = true

	if XHSSetGlobalObjectiveState ~= nil then
		XHSSetGlobalObjectiveState("phase2_creeps", "Completed", "Phase 2 creep assault survived", nil)
	end

	local activeTowerIndices = CustomTimers.phase2_active_ice_towers or { 1 }
	local activeTowerLookup = {}
	for _, towerIndex in ipairs(activeTowerIndices) do
		activeTowerLookup[towerIndex] = true
	end

	local allMainTowers = {}
	local activeMainTowers = {}
	local releaseRecords = {}
	for towerIndex = 1, 2 do
		local tower = Entities:FindByName(nil, "npc_tower_cold_" .. towerIndex)
		if IsValidPhase2Entity(tower) then
			table.insert(allMainTowers, tower)
			if activeTowerLookup[towerIndex] == true then
				table.insert(activeMainTowers, tower)
				AddFOWViewer(DOTA_TEAM_GOODGUYS, tower:GetAbsOrigin(), SHAL_RELEASE_FOW_RADIUS, SHAL_RELEASE_FOW_DURATION, false)
				table.insert(releaseRecords, {
					tower = tower,
					origin = tower:GetAbsOrigin(),
					forward = tower:GetForwardVector(),
					shal = SpawnHiddenShalAtTower(tower),
				})
			end
		end
	end

	RefreshPhase2VIPNetTable()
	PlayShalReleaseCamera(activeMainTowers)

	Timers:CreateTimer(SHAL_RELEASE_CAMERA_MOVE_DURATION, function()
		if CustomTimers.shal_lightbinder_released ~= true then return nil end

		for _, tower in pairs(Entities:FindAllByName("npc_tower_death")) do
			if IsValidPhase2Entity(tower) and tower:IsAlive() then
				tower:Kill(nil, nil)
			end
		end

		for _, tower in pairs(allMainTowers) do
			if IsValidPhase2Entity(tower) and tower:IsAlive() then
				tower:Kill(nil, nil)
			end
		end

		for _, record in pairs(releaseRecords) do
			local frostParticle = ParticleManager:CreateParticle(SHAL_RELEASE_FROST_PARTICLE, PATTACH_WORLDORIGIN, nil)
			ParticleManager:SetParticleControl(frostParticle, 0, record.origin)
			ParticleManager:ReleaseParticleIndex(frostParticle)
		end

		Timers:CreateTimer(0.2, function()
			for _, record in pairs(releaseRecords) do
				RevealFreedShal(record)
			end
			RefreshPhase2VIPNetTable()
			return nil
		end)

		return nil
	end)

	if #activeMainTowers == 0 then
		for _, tower in pairs(Entities:FindAllByName("npc_tower_death")) do
			if IsValidPhase2Entity(tower) and tower:IsAlive() then
				tower:Kill(nil, nil)
			end
		end
		for _, tower in pairs(allMainTowers) do
			if IsValidPhase2Entity(tower) and tower:IsAlive() then
				tower:Kill(nil, nil)
			end
		end
	end
end

local FINAL_WAVE_QUEST_NAME = "kill_final_wave"
local FINAL_WAVE_TOTAL_UNITS = 52
local FINAL_WAVE_INTRO_DURATION = 52.0
local FINAL_WAVE_CARDINAL_REVEAL_DELAY = 2.8
local FINAL_WAVE_BOSS_SUMMON_DELAY = 0.65
local FINAL_WAVE_UNIT_SPAWN_INTERVAL = 0.18
local FINAL_WAVE_PORTAL_FOW_RADIUS = 900
local FINAL_WAVE_PORTAL_FOW_DURATION = 9.0
local FINAL_WAVE_MUSIC_SOUND = "XHS.FinalWaveMusic"
local FINAL_WAVE_PLAYER_TELEPORT_DELAY = 1.5
local FINAL_WAVE_CINEMATIC_ID = "final_wave_intro"
local FINAL_WAVE_LETTERBOX_PERCENT = 10
local FINAL_WAVE_LETTERBOX_TRANSITION = 0.75
local FINAL_WAVE_PORTAL_START_PARTICLE = "particles/items2_fx/teleport_start.vpcf"
local FINAL_WAVE_PORTAL_END_PARTICLE = "particles/items2_fx/teleport_end.vpcf"
local FINAL_WAVE_PORTAL_RING_PARTICLE = "particles/units/heroes/hero_templar_assassin/templar_assassin_trap_rings_inner.vpcf"

local FINAL_WAVE_CAMERA_OFFSETS = {
	west = Vector(325, 0, 0),
	east = Vector(-325, 0, 0),
	north = Vector(0, -425, 0),
	south = Vector(0, 325, 0),
}

local FINAL_WAVE_CARDINALS = {
	{
		delay = 8.0,
		direction = "west",
		direction_label = "West",
		boss_label = "Balanar",
		angle = 0,
		waypoint = "final_wave_player_2",
		boss = "npc_dota_hero_balanar",
		creeps = { "npc_abomination", "npc_banshee", "npc_necro", "npc_magnataur" },
	},
	{
		delay = 18.0,
		direction = "north",
		direction_label = "North",
		boss_label = "Grom",
		angle = 270,
		waypoint = "final_wave_player_4",
		boss = "npc_dota_hero_grom_hellscream",
		creeps = { "npc_tauren", "npc_chaos_orc", "npc_warlock", "npc_orc_raider" },
	},
	{
		delay = 28.0,
		direction = "east",
		direction_label = "East",
		boss_label = "Illidan",
		angle = 180,
		waypoint = "final_wave_player_6",
		boss = "npc_dota_hero_illidan",
		creeps = { "npc_druid", "npc_guard", "npc_keeper", "npc_luna" },
	},
	{
		delay = 38.0,
		direction = "south",
		direction_label = "South",
		boss_label = "Proudmoore",
		angle = 90,
		waypoint = "final_wave_player_0",
		boss = "npc_dota_hero_proudmoore",
		creeps = { "npc_captain", "npc_marine", "npc_marine", "npc_knight" },
	},
}

local function FindFinalWaveQuest()
	if GameMode == nil or GameMode.Zones == nil then
		return nil, nil
	end

	for _, zone in pairs(GameMode.Zones) do
		if zone ~= nil and zone.Quests ~= nil then
			for _, quest in pairs(zone.Quests) do
				if quest ~= nil and quest.szQuestName == FINAL_WAVE_QUEST_NAME then
					return zone, quest
				end
			end
		end
	end

	return nil, nil
end

local function SendFinalWaveQuestProgress(zone, quest)
	if zone == nil or quest == nil then return end

	CustomGameEventManager:Send_ServerToAllClients("quest_completed", {
		ZoneName = zone.szName,
		QuestName = quest.szQuestName,
		QuestType = quest.szQuestType,
		Completed = quest.nCompleted,
		CompleteLimit = quest.nCompleteLimit,
		XPReward = quest.RewardXP or 0,
		GoldReward = quest.RewardGold or 0,
		ZoneCompleted = false,
		Optional = quest.bOptional,
		ZoneStars = zone.nStars,
	})
end

local function UpdateFinalWaveQuestLimit()
	local spawnedCount = math.min(CustomTimers.final_wave_spawned_kill_limit or 0, FINAL_WAVE_TOTAL_UNITS)
	if spawnedCount <= 0 then return end

	local zone, quest = FindFinalWaveQuest()
	if zone == nil or quest == nil or quest.bCompleted == true then return end

	quest.nCompleteLimit = spawnedCount

	if quest.bActivated ~= true then
		quest.nCompleted = 0
		GameRules.GameMode:OnQuestStarted(zone, quest)
	else
		SendFinalWaveQuestProgress(zone, quest)
	end
end

local function RegisterFinalWaveUnit(unit)
	if unit == nil then return end

	unit.zone = "xhs_holdout"
	unit.xhs_final_wave_unit = true
	CustomTimers.final_wave_spawned_kill_limit = (CustomTimers.final_wave_spawned_kill_limit or 0) + 1
end

local function IsFinalWaveSequenceActive(sequenceId)
	return sequenceId == nil or CustomTimers.final_wave_sequence_id == sequenceId
end

local function GetFinalWaveFort()
	return Entities:FindByClassname(nil, "npc_dota_fort")
end

local function FindFinalWaveSpawner(direction, index)
	return Entities:FindByName(nil, "final_wave_" .. direction .. "_" .. index)
end

local function GetFinalWavePortalOrigin(config)
	local bossSpawner = FindFinalWaveSpawner(config.direction, 13)
	if bossSpawner ~= nil then
		return bossSpawner:GetAbsOrigin()
	end

	local firstSpawner = FindFinalWaveSpawner(config.direction, 1)
	if firstSpawner ~= nil then
		return firstSpawner:GetAbsOrigin()
	end

	return Vector(0, 0, 0)
end

local function GetFinalWaveCameraPosition(config, position)
	local offset = FINAL_WAVE_CAMERA_OFFSETS[config.direction]
	if offset == nil then
		return position
	end

	return position + offset
end

local function SendFinalWaveCamera(position, speed)
	for _, hero in pairs(HeroList:GetAllHeroes()) do
		if hero:IsRealHero() and hero:GetTeam() == DOTA_TEAM_GOODGUYS then
			CameraMotion:Move(hero:GetPlayerOwnerID(), position, {
				from = hero,
				duration = speed or 0.65,
				easing = "smootherstep",
				owner = "final_wave_intro",
				priority = 100,
				policy = "replace",
				persistent = true,
			})
		end
	end
end

local function ApplyFinalWaveCinematicLock(unit, duration)
	if unit == nil or unit:IsNull() then return end
	if duration <= 0 then return end

	local pauseModifier = unit:AddNewModifier(unit, nil, "modifier_pause_creeps", { duration = duration, IsHidden = true })
	if pauseModifier ~= nil then
		pauseModifier:SetStackCount(1)
	end
	unit:AddNewModifier(unit, nil, "modifier_invulnerable", { duration = duration, IsHidden = true })
end

local function QueueFinalWaveRelease(unit, waypoint)
	if unit == nil or unit:IsNull() then return end

	CustomTimers.final_wave_pending_units = CustomTimers.final_wave_pending_units or {}
	table.insert(CustomTimers.final_wave_pending_units, {
		unit = unit,
		waypoint = waypoint,
	})
end

local function ReleaseFinalWaveUnit(unit, waypoint)
	if unit == nil or unit:IsNull() or not unit:IsAlive() then return end

	unit:RemoveModifierByName("modifier_pause_creeps")
	unit:RemoveModifierByName("modifier_invulnerable")

	if waypoint ~= nil and not waypoint:IsNull() then
		unit:SetInitialGoalEntity(waypoint)
		ExecuteOrderFromTable({
			UnitIndex = unit:entindex(),
			OrderType = DOTA_UNIT_ORDER_ATTACK_MOVE,
			Position = waypoint:GetAbsOrigin(),
		})
	end
end

local function ReleaseFinalWavePendingUnits()
	if CustomTimers.final_wave_pending_units ~= nil then
		for _, data in pairs(CustomTimers.final_wave_pending_units) do
			ReleaseFinalWaveUnit(data.unit, data.waypoint)
		end
	end

	CustomTimers.final_wave_pending_units = nil
	UpdateFinalWaveQuestLimit()
	CustomTimers.final_wave_kill_counting = (CustomTimers.final_wave_spawned_kill_limit or 0) >= FINAL_WAVE_TOTAL_UNITS
end

local function DestroyFinalWaveParticle(particle)
	if particle == nil then return end

	ParticleManager:DestroyParticle(particle, false)
	ParticleManager:ReleaseParticleIndex(particle)
end

local function CreateFinalWaveSpawnMarker(spawner)
	if spawner == nil or spawner:IsNull() then return nil end

	local particle = ParticleManager:CreateParticle(FINAL_WAVE_PORTAL_RING_PARTICLE, PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleControl(particle, 0, spawner:GetAbsOrigin())
	return particle
end

local function CreateFinalWaveTeleportChannel(origin)
	-- This is deliberately the effect formerly played on arrival: it reads much
	-- better as the visible channel while the boss itself is still hidden.
	local particle = ParticleManager:CreateParticle(FINAL_WAVE_PORTAL_END_PARTICLE, PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleControl(particle, 0, origin)
	ParticleManager:SetParticleControl(particle, 1, origin)
	return particle
end

local function CreateFinalWavePortalEffects(origin)
	AddFOWViewer(DOTA_TEAM_GOODGUYS, origin, FINAL_WAVE_PORTAL_FOW_RADIUS, FINAL_WAVE_PORTAL_FOW_DURATION, false)
	return CreateFinalWaveTeleportChannel(origin)
end

local function PlayFinalWaveArrivalEffects(unit)
	if unit == nil or unit:IsNull() then return end

	local origin = unit:GetAbsOrigin()
	local particle = ParticleManager:CreateParticle(FINAL_WAVE_PORTAL_START_PARTICLE, PATTACH_ABSORIGIN_FOLLOW, unit)
	ParticleManager:SetParticleControl(particle, 0, origin)
	ParticleManager:SetParticleControl(particle, 1, origin)

	Timers:CreateTimer(0.8, function()
		DestroyFinalWaveParticle(particle)
	end)

	unit:EmitSound("Portal.Hero_Appear")
end

local function NotifyFinalWaveArrival(config)
	if Notifications == nil then return end

	Notifications:TopToAll({
		text = config.boss_label .. " arrives from the " .. config.direction_label,
		duration = 3.0,
		style = { color = "#ffdc73", ["font-size"] = "28px", ["font-weight"] = "bold" },
	})
end

local function SpawnFinalWaveUnit(unitName, spawner, angle, releaseWaypoint, lockDuration, hiddenUntilReveal)
	if spawner == nil then return nil end

	local unit = CreateUnitByName(unitName .. "_final_wave", spawner:GetAbsOrigin(), true, nil, nil, DOTA_TEAM_CUSTOM_1)
	if unit == nil then return nil end

	if hiddenUntilReveal == true then
		unit:AddNoDraw()
	end

	RegisterFinalWaveUnit(unit)
	unit:SetAngles(0, angle, 0)
	ApplyFinalWaveCinematicLock(unit, lockDuration)
	QueueFinalWaveRelease(unit, releaseWaypoint)

	UpdateFinalWaveQuestLimit()
	CustomTimers.final_wave_kill_counting = (CustomTimers.final_wave_spawned_kill_limit or 0) >= FINAL_WAVE_TOTAL_UNITS

	return unit
end

function FinalWave(force)
	if force ~= true and XHSDevTools ~= nil and XHSDevTools:IsSandboxActive() then return end

	CustomTimers.proc_final_wave = true
	CustomTimers.final_wave_kill_counting = false
	CustomTimers.final_wave_spawned_kill_limit = 0
	CustomTimers.final_wave_pending_units = {}
	CustomTimers.final_wave_sequence_id = (CustomTimers.final_wave_sequence_id or 0) + 1
	local finalWaveSequenceId = CustomTimers.final_wave_sequence_id

	CustomTimers.current_time["special_event"] = 1
	CustomTimers:Countdown("special_event")
	if XHSSetGlobalObjectiveState ~= nil then
		XHSSetGlobalObjectiveState("final_wave", "Active", "Final Wave active")
	else
		CustomGameEventManager:Send_ServerToAllClients("xhs_global_objective_update", {
			id = "final_wave",
			state = "Active",
			text = "Final Wave active",
		})
	end
	KillCreeps(DOTA_TEAM_CUSTOM_1)
	RefreshPlayers()
	GameRules:SetHeroRespawnEnabled(false)

	TeleportAllHeroes("final_wave_player_", FINAL_WAVE_INTRO_DURATION, FINAL_WAVE_PLAYER_TELEPORT_DELAY)

	Timers:CreateTimer(FINAL_WAVE_PLAYER_TELEPORT_DELAY, function()
		if not IsFinalWaveSequenceActive(finalWaveSequenceId) then return end

		if Runes ~= nil and Runes.OnFinalWaveTeleport ~= nil then
			Runes:OnFinalWaveTeleport()
		end

		-- Music must not depend on the Panorama cinematic panel being loaded.
		-- The custom sound event owns the requested 2x gain and this global
		-- server emission reaches every player even after a script hot reload.
		EmitGlobalSound(FINAL_WAVE_MUSIC_SOUND)

		if XHSCinematics ~= nil then
			XHSCinematics:BeginForAll(FINAL_WAVE_CINEMATIC_ID, {
				-- Start the exit animation early so the HUD and full viewport are
				-- restored exactly when the final wave is released.
				duration = FINAL_WAVE_INTRO_DURATION
					- FINAL_WAVE_PLAYER_TELEPORT_DELAY
					- FINAL_WAVE_LETTERBOX_TRANSITION,
				letterbox_pct = FINAL_WAVE_LETTERBOX_PERCENT,
				transition = FINAL_WAVE_LETTERBOX_TRANSITION,
				hide_hud = true,
			})
		end
	end)

	for _, config in ipairs(FINAL_WAVE_CARDINALS) do
		Timers:CreateTimer(config.delay, function()
			if not IsFinalWaveSequenceActive(finalWaveSequenceId) then return end
			FinalWaveSpawner(config, finalWaveSequenceId)
		end)
	end

	Timers:CreateTimer(FINAL_WAVE_INTRO_DURATION, function()
		if not IsFinalWaveSequenceActive(finalWaveSequenceId) then return end

		for _, hero in pairs(HeroList:GetAllHeroes()) do
			if hero:IsRealHero() and hero:GetTeam() == DOTA_TEAM_GOODGUYS then
				local playerID = hero:GetPlayerOwnerID()
				CameraMotion:Return(playerID, function()
					return PlayerResource:GetSelectedHeroEntity(playerID)
				end, {
					duration = 0.85,
					easing = "smootherstep",
					owner = "final_wave_intro",
					priority = 100,
					policy = "replace",
					release = "free",
				})
			end
		end

		ReleaseFinalWavePendingUnits()

		if XHSCinematics ~= nil then
			XHSCinematics:EndForAll(FINAL_WAVE_CINEMATIC_ID)
		end

		local finalWaveFort = GetFinalWaveFort()
		if finalWaveFort ~= nil then
			EmitSoundOn("Hero_TemplarAssassin.Trap", finalWaveFort)
		end
	end)
end

function FinalWaveSpawner(configOrCreep1, creep2, creep3, creep4, bossName, angle, direction, waypointName)
	local config = configOrCreep1
	local sequenceId = nil
	if type(configOrCreep1) == "table" then
		sequenceId = creep2
	end

	if not IsFinalWaveSequenceActive(sequenceId) then return end

	if type(configOrCreep1) ~= "table" then
		config = {
			delay = 0,
			direction = direction,
			direction_label = direction or "",
			boss_label = bossName or "",
			angle = angle or 0,
			waypoint = waypointName,
			boss = bossName,
			creeps = { configOrCreep1, creep2, creep3, creep4 },
		}
	end

	if config == nil or config.direction == nil or config.boss == nil then return end

	local releaseWaypoint = Entities:FindByName(nil, config.waypoint)
	local lockDuration = math.max(1.0, FINAL_WAVE_INTRO_DURATION - (config.delay or 0))
	local portalOrigin = GetFinalWavePortalOrigin(config)
	local bossSpawner = FindFinalWaveSpawner(config.direction, 13)
	if bossSpawner == nil then return end

	local teleportChannel = CreateFinalWavePortalEffects(portalOrigin)
	NotifyFinalWaveArrival(config)

	local spawnMarkers = {}
	local spawnSlotCount = #config.creeps * 3
	for slot = 1, spawnSlotCount do
		local spawner = FindFinalWaveSpawner(config.direction, slot)
		if spawner ~= nil then
			spawnMarkers[slot] = CreateFinalWaveSpawnMarker(spawner)
		end
	end

	local boss = SpawnFinalWaveUnit(config.boss, bossSpawner, config.angle, releaseWaypoint, lockDuration, true)
	if boss == nil then
		DestroyFinalWaveParticle(teleportChannel)
		for _, marker in pairs(spawnMarkers) do
			DestroyFinalWaveParticle(marker)
		end
		return
	end

	boss:EmitSound("Portal.Loop_Appear")
	SendFinalWaveCamera(GetFinalWaveCameraPosition(config, boss:GetAbsOrigin()), 0.65)

	Timers:CreateTimer(FINAL_WAVE_CARDINAL_REVEAL_DELAY, function()
		DestroyFinalWaveParticle(teleportChannel)
		teleportChannel = nil

		if boss == nil or boss:IsNull() then return end
		StopSoundOn("Portal.Loop_Appear", boss)
		if not IsFinalWaveSequenceActive(sequenceId) then
			boss:RemoveNoDraw()
			return
		end

		boss:RemoveNoDraw()
		PlayFinalWaveArrivalEffects(boss)
		boss:StartGesture(ACT_DOTA_CAST_ABILITY_2)
	end)

	local spawnSlot = 1
	for _, creepName in ipairs(config.creeps) do
		for _ = 1, 3 do
			local currentSlot = spawnSlot
			local currentCreepName = creepName
			Timers:CreateTimer(FINAL_WAVE_CARDINAL_REVEAL_DELAY + FINAL_WAVE_BOSS_SUMMON_DELAY + ((spawnSlot - 1) * FINAL_WAVE_UNIT_SPAWN_INTERVAL), function()
				DestroyFinalWaveParticle(spawnMarkers[currentSlot])
				spawnMarkers[currentSlot] = nil

				if not IsFinalWaveSequenceActive(sequenceId) then return end
				local spawner = FindFinalWaveSpawner(config.direction, currentSlot)
				if spawner == nil then return end
				local creep = SpawnFinalWaveUnit(currentCreepName, spawner, config.angle, releaseWaypoint, lockDuration, false)
				if creep ~= nil then
					creep:EmitSound("Hero_TemplarAssassin.Trap")
				end
			end)
			spawnSlot = spawnSlot + 1
		end
	end
end
