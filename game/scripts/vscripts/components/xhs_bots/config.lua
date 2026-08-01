if XHSBotConfig == nil then
	XHSBotConfig = {}
end

-- The lobby reserves one ninth identity slot for the Tools-only observer.
-- Radiant remains capped at eight actual combat participants.
XHSBotConfig.MAX_SESSION_SIZE = 9
XHSBotConfig.MAX_TEAM_SIZE = 8
XHSBotConfig.MAX_BOTS = 8
XHSBotConfig.DEFAULTS = {
	enabled = false,
	count = 0,
	difficulty = "normal",
	composition = "balanced",
	spectator_mode = false,
	hero_selections = {},
}

XHSBotConfig.DIFFICULTIES = {
	easy = {
		id = "easy",
		think_interval = 0.55,
		reaction_min = 0.80,
		reaction_max = 1.40,
		target_commitment = 2.50,
		target_memory_duration = 0.90,
		perception_radius = 1850,
		ability_use_chance = 0.62,
		danger_response_chance = 0.72,
		danger_reaction_lead = 0.20,
		channel_interrupt_danger = 0.88,
		ally_heal_threshold = 0.30,
		self_retreat_multiplier = 1.08,
		threat_retreat_weight = 0.13,
		damage_spike_retreat_weight = 0.60,
		maximum_retreat_health = 0.62,
		order_jitter = 90,
		min_order_interval = 0.30,
		max_orders_per_second = 1,
		attack_move_chance = 0.35,
		max_chase_distance = 1050,
		anchor_leash = 1550,
		max_basic_chasers = 1,
		self_defense_radius = 575,
		director_replan_interval = 1.35,
		assignment_duration = 8.0,
		urgency_break_threshold = 0.62,
		lane_urgency_weight = 0.45,
		human_follow_weight = 0.20,
		human_follow_radius = 900,
		simple_combo_window = 0,
		simple_combo_bonus = 0,
		rune_search_radius = 12000,
		rune_priority = 218,
		rune_threat_ceiling = 1.15,
		rune_health_margin = 0.04,
		economy_think_interval = 2.75,
		shop_retry_interval = 24,
		max_concurrent_shoppers = 1,
		health_potion_threshold = 0.34,
		emergency_health_resupply_threshold = 0.70,
		mana_potion_threshold = 0.22,
		min_health_potion_charges = 15,
		min_mana_potion_charges = 15,
		target_health_potion_charges = 15,
		target_mana_potion_charges = 15,
		health_resupply_trigger_charges = 3,
		max_tomes_per_think = 1,
		pre_arena_tome_cap = 8,
		pre_arena_tomes_per_think = 4,
	},
	normal = {
		id = "normal",
		think_interval = 0.28,
		reaction_min = 0.25,
		reaction_max = 0.60,
		target_commitment = 1.25,
		target_memory_duration = 1.60,
		perception_radius = 2150,
		ability_use_chance = 0.88,
		danger_response_chance = 0.94,
		danger_reaction_lead = 0.55,
		channel_interrupt_danger = 0.68,
		ally_heal_threshold = 0.55,
		self_retreat_multiplier = 1.00,
		threat_retreat_weight = 0.18,
		damage_spike_retreat_weight = 0.82,
		maximum_retreat_health = 0.70,
		order_jitter = 45,
		min_order_interval = 0.16,
		max_orders_per_second = 2,
		attack_move_chance = 0.82,
		max_chase_distance = 1400,
		anchor_leash = 1900,
		max_basic_chasers = 2,
		self_defense_radius = 700,
		director_replan_interval = 0.85,
		assignment_duration = 6.0,
		urgency_break_threshold = 0.38,
		lane_urgency_weight = 0.85,
		human_follow_weight = 0.65,
		human_follow_radius = 1450,
		simple_combo_window = 1.8,
		simple_combo_bonus = 12,
		rune_search_radius = 12000,
		rune_priority = 226,
		rune_threat_ceiling = 1.25,
		rune_health_margin = 0.03,
		economy_think_interval = 1.5,
		shop_retry_interval = 12,
		max_concurrent_shoppers = 2,
		health_potion_threshold = 0.48,
		emergency_health_resupply_threshold = 0.74,
		mana_potion_threshold = 0.34,
		min_health_potion_charges = 15,
		min_mana_potion_charges = 15,
		target_health_potion_charges = 15,
		target_mana_potion_charges = 15,
		health_resupply_trigger_charges = 3,
		max_tomes_per_think = 3,
		pre_arena_tome_cap = 12,
		pre_arena_tomes_per_think = 6,
	},
}

XHSBotConfig.COMPOSITIONS = {
	balanced = true,
	damage = true,
	support = true,
	random = true,
}

local function CopyTable(source)
	local copy = {}
	for key, value in pairs(source or {}) do
		if type(value) == "table" then
			copy[key] = CopyTable(value)
		else
			copy[key] = value
		end
	end
	return copy
end

local function ClampInteger(value, minimum, maximum)
	value = math.floor(tonumber(value) or 0)
	return math.max(minimum, math.min(maximum, value))
end

local function IsTruthy(value)
	return value == true or value == 1 or value == "1" or value == "true"
end

function XHSBotConfig:IsBossTarget(unit)
	if unit == nil or unit.IsNull == nil or unit:IsNull() then return false end

	if XHSIsBossDamageTarget ~= nil then
		local ok, isBoss = pcall(XHSIsBossDamageTarget, unit)
		if ok and isBoss == true then return true end
	end

	if unit.Boss == true or unit.bBoss == true then return true end
	if unit.FindAbilityByName ~= nil then
		local ok, bossHealth = pcall(function()
			return unit:FindAbilityByName("boss_health")
		end)
		if ok and bossHealth ~= nil then return true end
	end

	local name = unit.GetUnitName ~= nil and unit:GetUnitName() or ""
	if string.find(name, "boss", 1, true) ~= nil then return true end
	return unit.IsHero ~= nil
		and unit:IsHero()
		and unit.GetTeamNumber ~= nil
		and unit:GetTeamNumber() == DOTA_TEAM_CUSTOM_2
end

function XHSBotConfig:GetDifficulty(id)
	id = string.lower(tostring(id or self.DEFAULTS.difficulty))
	return self.DIFFICULTIES[id] or self.DIFFICULTIES[self.DEFAULTS.difficulty]
end

function XHSBotConfig:Normalize(raw, humanCount)
	raw = type(raw) == "table" and raw or {}
	humanCount = ClampInteger(humanCount, 0, self.MAX_SESSION_SIZE)

	local difficulty = string.lower(tostring(raw.difficulty or self.DEFAULTS.difficulty))
	if self.DIFFICULTIES[difficulty] == nil then
		difficulty = self.DEFAULTS.difficulty
	end

	local composition = string.lower(tostring(raw.composition or self.DEFAULTS.composition))
	if self.COMPOSITIONS[composition] ~= true then
		composition = self.DEFAULTS.composition
	end

	local certifiedHeroCapacity = self.MAX_BOTS
	if XHSBotHeroProfiles ~= nil
		and XHSBotHeroProfiles.GetCertifiedHeroCount ~= nil then
		certifiedHeroCapacity = XHSBotHeroProfiles:GetCertifiedHeroCount()
	end
	local wantsSpectator = IsTruthy(raw.spectator_mode)
	local playHumanCount = math.min(self.MAX_TEAM_SIZE, humanCount)
	local spectatorHumanCount = math.max(0, playHumanCount - 1)
	local maximumPlayBots = math.min(
		self.MAX_BOTS,
		certifiedHeroCapacity,
		math.max(0, self.MAX_TEAM_SIZE - playHumanCount)
	)
	local maximumSpectatorBots = math.min(
		self.MAX_BOTS,
		certifiedHeroCapacity,
		math.max(0, self.MAX_TEAM_SIZE - spectatorHumanCount)
	)
	local maximumBots = wantsSpectator
		and maximumSpectatorBots
		or maximumPlayBots
	local count = ClampInteger(raw.count, 0, maximumBots)
	local spectatorMode = wantsSpectator and count > 0
	local heroSelections = {}
	local selectedHeroes = {}
	local rawHeroSelections = type(raw.hero_selections) == "table"
		and raw.hero_selections
		or {}
	for slot = 1, count do
		local heroName = tostring(
			rawHeroSelections[slot]
				or rawHeroSelections[tostring(slot)]
				or ""
		)
		if heroName ~= ""
			and XHSBotHeroProfiles ~= nil
			and XHSBotHeroProfiles.IsCertified ~= nil
			and XHSBotHeroProfiles:IsCertified(heroName)
			and selectedHeroes[heroName] ~= true then
			heroSelections[slot] = heroName
			selectedHeroes[heroName] = true
		end
	end

	return {
		enabled = count > 0,
		count = count,
		difficulty = difficulty,
		composition = composition,
		spectator_mode = spectatorMode,
		hero_selections = heroSelections,
		human_count = humanCount,
		combat_human_count = spectatorMode and spectatorHumanCount or playHumanCount,
		maximum_bots = maximumBots,
		maximum_play_bots = maximumPlayBots,
		maximum_spectator_bots = maximumSpectatorBots,
	}
end

function XHSBotConfig:CopyDefaults()
	return CopyTable(self.DEFAULTS)
end

return XHSBotConfig
