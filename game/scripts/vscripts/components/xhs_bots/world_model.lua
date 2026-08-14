if XHSBotWorldModel == nil then
	XHSBotWorldModel = {}
end

local MAX_FORECAST_SECONDS = 9999

local function Clamp(value, minimum, maximum)
	return math.max(minimum, math.min(maximum, tonumber(value) or 0))
end

local function SafeRatio(value)
	value = math.max(0, tonumber(value) or 0)
	if value > 2 then value = value / 100 end
	return value
end

local function BoundedSeconds(value)
	if value == math.huge then return MAX_FORECAST_SECONDS end
	return Clamp(value, 0, MAX_FORECAST_SECONDS)
end

-- Pure deterministic forecast. The caller owns perception and supplies only
-- server-visible observations; this module never discovers entities itself.
function XHSBotWorldModel:EstimateSurvival(snapshot)
	snapshot = snapshot or {}
	local maximumHealth = math.max(1, tonumber(snapshot.maximum_health) or 1)
	local currentHealth = Clamp(
		snapshot.current_health,
		0,
		maximumHealth
	)
	local projectedAttackDPS = 0
	local focusedBy = 0
	local visibleThreats = 0
	local noControlProbability = 1

	for _, enemy in ipairs(snapshot.enemies or {}) do
		local projectedDPS = math.max(0, tonumber(enemy.projected_dps) or 0)
		local reach = Clamp(enemy.reach_factor, 0, 1)
		local focused = enemy.focused == true
		local commitment = focused and 1 or 0.72
		projectedAttackDPS =
			projectedAttackDPS + projectedDPS * reach * commitment
		visibleThreats = visibleThreats + 1
		if focused then focusedBy = focusedBy + 1 end

		local disableRisk = Clamp(enemy.disable_risk, 0, 1) * reach
		noControlProbability = noControlProbability * (1 - disableRisk)
	end

	local controlRisk = Clamp(1 - noControlProbability, 0, 0.95)
	local recentDamageDPS = math.max(
		0,
		tonumber(snapshot.recent_damage_rate) or 0
	) * maximumHealth
	-- Recent observed damage includes bursts that the auto-attack projection
	-- cannot see. Preserve most of that evidence without double counting the
	-- already projected attacks.
	local incomingDPS = projectedAttackDPS
		+ math.max(0, recentDamageDPS - projectedAttackDPS) * 0.78
	incomingDPS = incomingDPS * (
		1 - Clamp(snapshot.cover_reduction, 0, 0.45)
	)

	local lifestealRatio = SafeRatio(snapshot.attack_lifesteal_pct)
	local combatUptime = Clamp(snapshot.combat_uptime, 0, 1)
	local lifestealDPS = math.max(
		0,
		tonumber(snapshot.attack_dps) or 0
	) * lifestealRatio * combatUptime
	local sustainDPS = math.max(0, tonumber(snapshot.health_regen) or 0)
		+ math.max(0, tonumber(snapshot.other_sustain_per_second) or 0)
		+ lifestealDPS
	local netIncomingDPS = math.max(0, incomingDPS - sustainDPS)

	local reactionTime = math.max(0, tonumber(snapshot.reaction_time) or 0)
	local movementSpeed = math.max(100, tonumber(snapshot.movement_speed) or 300)
	local escapeDistance = math.max(0, tonumber(snapshot.escape_distance) or 0)
	local escapeTime = reactionTime
		+ escapeDistance / movementSpeed
		+ controlRisk * 1.35
	local timeToDie = netIncomingDPS > 0
		and currentHealth / netIncomingDPS or MAX_FORECAST_SECONDS

	local confidence = Clamp(
		0.26
			+ math.min(0.32, visibleThreats * 0.08)
			+ math.min(0.24, focusedBy * 0.12)
			+ (recentDamageDPS > 0 and 0.18 or 0),
		0,
		1
	)
	local safetyMargin = Clamp(snapshot.safety_margin, 0, 3)
	if safetyMargin <= 0 then safetyMargin = 0.45 end
	local fatalBeforeEscape = confidence >= 0.48
		and netIncomingDPS > 0
		and timeToDie <= escapeTime + safetyMargin
	local healthAtEscape = Clamp(
		currentHealth - netIncomingDPS * escapeTime,
		0,
		maximumHealth
	)
	local pressureScore = Clamp(
		netIncomingDPS / maximumHealth * 5.5
			+ controlRisk * 0.34
			+ math.min(0.24, focusedBy * 0.08)
			+ (fatalBeforeEscape and 0.28 or 0),
		0,
		1.5
	)

	return {
		incoming_dps = incomingDPS,
		projected_attack_dps = projectedAttackDPS,
		recent_damage_dps = recentDamageDPS,
		sustain_per_second = sustainDPS,
		lifesteal_per_second = lifestealDPS,
		net_incoming_dps = netIncomingDPS,
		time_to_die = BoundedSeconds(timeToDie),
		escape_time = BoundedSeconds(escapeTime),
		health_at_escape = healthAtEscape,
		health_at_escape_ratio = healthAtEscape / maximumHealth,
		fatal_before_escape = fatalBeforeEscape,
		control_risk = controlRisk,
		focused_by = focusedBy,
		visible_threats = visibleThreats,
		confidence = confidence,
		pressure_score = pressureScore,
	}
end

-- Pure objective forecast used by the Team Director after it has observed
-- real attackers and their real attack targets.
function XHSBotWorldModel:EstimateObjectiveLoss(snapshot)
	snapshot = snapshot or {}
	local maximumHealth = math.max(1, tonumber(snapshot.maximum_health) or 1)
	local currentHealth = Clamp(
		snapshot.current_health,
		0,
		maximumHealth
	)
	local incomingDPS = 0
	local attackerCount = 0
	for _, attacker in ipairs(snapshot.attackers or {}) do
		incomingDPS = incomingDPS
			+ math.max(0, tonumber(attacker.projected_dps) or 0)
				* Clamp(attacker.uptime or 1, 0, 1)
		attackerCount = attackerCount + 1
	end
	local regeneration = math.max(0, tonumber(snapshot.health_regen) or 0)
	local netIncomingDPS = math.max(0, incomingDPS - regeneration)
	local lossTime = netIncomingDPS > 0
		and currentHealth / netIncomingDPS or MAX_FORECAST_SECONDS
	local confidence = Clamp(
		0.42 + math.min(0.45, attackerCount * 0.15),
		0,
		0.95
	)
	return {
		incoming_dps = incomingDPS,
		net_incoming_dps = netIncomingDPS,
		loss_time = BoundedSeconds(lossTime),
		attacker_count = attackerCount,
		confidence = confidence,
	}
end

-- Pure engagement forecast. Perception, grouping and target ownership remain
-- caller responsibilities; this function only compares the observed pack with
-- the force currently available to the hero.
function XHSBotWorldModel:EstimateEngagement(snapshot)
	snapshot = snapshot or {}
	local maximumHealth = math.max(1, tonumber(snapshot.maximum_health) or 1)
	local currentHealth = Clamp(snapshot.current_health, 0, maximumHealth)
	local packHealth = 0
	local incomingDPS = 0
	local bossCount = 0
	local specialCount = 0
	local focusedBy = 0
	local noControlProbability = 1
	local enemyCount = 0

	for _, enemy in ipairs(snapshot.enemies or {}) do
		packHealth = packHealth + math.max(1, tonumber(enemy.effective_health) or 1)
		local reach = Clamp(enemy.reach_factor, 0, 1)
		local focused = enemy.focused == true
		incomingDPS = incomingDPS
			+ math.max(0, tonumber(enemy.projected_dps) or 0)
				* reach * (focused and 1 or 0.72)
		if focused then focusedBy = focusedBy + 1 end
		if enemy.boss == true then bossCount = bossCount + 1 end
		if enemy.special == true then specialCount = specialCount + 1 end
		noControlProbability = noControlProbability
			* (1 - Clamp(enemy.disable_risk, 0, 1) * reach)
		enemyCount = enemyCount + 1
	end

	local controlRisk = Clamp(1 - noControlProbability, 0, 0.95)
	local availableBurst = math.max(0, tonumber(snapshot.available_burst) or 0)
	packHealth = math.max(1, packHealth - availableBurst)
	local heroDPS = math.max(1, tonumber(snapshot.hero_dps) or 1)
	local allyDPS = math.max(0, tonumber(snapshot.ally_dps) or 0)
	local areaFactor = Clamp(snapshot.area_factor or 1, 0.5, 4)
	local combatUptime = Clamp(snapshot.combat_uptime or 0.82, 0.15, 1)
	local clearDPS = (heroDPS * areaFactor + allyDPS) * combatUptime
	local sustain = math.max(0, tonumber(snapshot.sustain_per_second) or 0)
	local coverReduction = Clamp(snapshot.cover_reduction, 0, 0.55)
	incomingDPS = incomingDPS * (1 - coverReduction)
	local netIncomingDPS = math.max(0, incomingDPS - sustain)
	local timeToClear = packHealth / math.max(1, clearDPS)
	local timeToDie = netIncomingDPS > 0
		and currentHealth / netIncomingDPS or MAX_FORECAST_SECONDS
	local survivalRatio = timeToDie / math.max(0.1, timeToClear)
	local objectiveLossTime = BoundedSeconds(snapshot.objective_loss_time or MAX_FORECAST_SECONDS)
	local urgentObjective = snapshot.structure_emergency == true
		or objectiveLossTime <= timeToClear + math.max(2, tonumber(snapshot.travel_time) or 0)
	local unavoidable = snapshot.unavoidable == true
	local affordablePowerSpike = snapshot.affordable_power_spike == true

	local classification = "SUICIDAL"
	if netIncomingDPS <= 0 or survivalRatio >= 1.75 then
		classification = "FARMABLE"
	elseif survivalRatio >= 1.12 then
		classification = "CONTESTABLE"
	elseif affordablePowerSpike and not urgentObjective and not unavoidable then
		classification = "NEEDS_GEAR"
	elseif survivalRatio >= 0.72 or urgentObjective then
		classification = "NEEDS_HELP"
	end

	local ranged = snapshot.ranged == true
	local pullable = snapshot.pullable == true and enemyCount >= 3
	local mode = "FULL_COMMIT"
	if classification == "NEEDS_GEAR" then
		mode = "SHOP_POWER_SPIKE"
	elseif classification == "NEEDS_HELP" then
		mode = urgentObjective and "HOLD_UNDER_COVER" or "WAIT_FOR_ONE_HELPER"
	elseif classification == "SUICIDAL" then
		if unavoidable or urgentObjective then
			mode = "LAST_STAND"
		elseif ranged then
			mode = pullable and "PULL_SMALL_GROUP" or "KITE_EDGE"
		else
			mode = "FARM_ALTERNATIVE"
		end
	elseif classification == "CONTESTABLE" then
		mode = ranged and "KITE_EDGE" or "HOLD_UNDER_COVER"
	end

	local confidence = Clamp(
		0.28 + math.min(0.42, enemyCount * 0.075)
			+ math.min(0.12, focusedBy * 0.06)
			+ (bossCount + specialCount > 0 and 0.12 or 0),
		0,
		0.96
	)
	local feasibility = Clamp(
		math.log(math.max(0.05, survivalRatio) + 1) / math.log(3)
			- controlRisk * 0.18,
		0,
		1
	)

	return {
		classification = classification,
		mode = mode,
		pack_health = packHealth,
		available_burst = availableBurst,
		clear_dps = clearDPS,
		incoming_dps = incomingDPS,
		net_incoming_dps = netIncomingDPS,
		time_to_clear = BoundedSeconds(timeToClear),
		time_to_die = BoundedSeconds(timeToDie),
		survival_ratio = Clamp(survivalRatio, 0, 99),
		feasibility = feasibility,
		confidence = confidence,
		control_risk = controlRisk,
		enemy_count = enemyCount,
		focused_by = focusedBy,
		boss_count = bossCount,
		special_count = specialCount,
		objective_loss_time = objectiveLossTime,
		urgent_objective = urgentObjective,
	}
end
