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
