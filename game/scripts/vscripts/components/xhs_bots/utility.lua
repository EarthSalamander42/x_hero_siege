if XHSBotUtility == nil then
	XHSBotUtility = {}
end

local function Clamp(value, minimum, maximum)
	return math.max(minimum, math.min(maximum, value))
end

local function AddAction(actions, id, score, data, reason)
	table.insert(actions, {
		id = id,
		score = Clamp(tonumber(score) or 0, 0, 200),
		data = data or {},
		reason = reason or "",
	})
end

function XHSBotUtility:Sort(actions)
	table.sort(actions, function(left, right)
		if left.score == right.score then
			local leftAbility = left.data and left.data.ability
			local rightAbility = right.data and right.data.ability
			local leftName = leftAbility and leftAbility:GetAbilityName() or ""
			local rightName = rightAbility and rightAbility:GetAbilityName() or ""
			return (left.id .. ":" .. leftName) < (right.id .. ":" .. rightName)
		end
		return left.score > right.score
	end)
	return actions
end

function XHSBotUtility:Build(context)
	local actions = {}
	if context.alive ~= true then
		AddAction(actions, "dead", 200, {}, "hero is dead")
		return actions
	end

	if context.disabled == true then
		AddAction(actions, "wait", 200, {}, "hero cannot currently act")
		return actions
	end

	if context.arena_combat == true then
		-- Ramero/Baristol and Sogat are sealed fights: there is nowhere useful
		-- to retreat or kite. Keep offensive/defensive spell use, but never let
		-- generic danger, preferred-range repositioning, or anchor fallback
		-- pull the bot out of the engagement.
		for _, abilityAction in ipairs(context.ability_actions or {}) do
			local score = tonumber(abilityAction.score) or 60
			if abilityAction.is_heal == true
				and context.health_ratio <= 0.48 then
				score = math.max(score, 170)
			elseif (abilityAction.mode == "self_defensive"
				or abilityAction.mode == "defensive_toggle")
				and context.health_ratio <= 0.58 then
				score = math.max(score, 155)
			elseif abilityAction.mode == "enemy_unit"
				or abilityAction.mode == "point_aoe"
				or abilityAction.mode == "directional_point"
				or abilityAction.mode == "no_target_enemy"
				or abilityAction.mode == "no_target_mixed"
				or abilityAction.mode == "summon"
				or abilityAction.mode == "self_buff"
				or abilityAction.mode == "team_buff" then
				score = math.max(score, 145)
			end
			AddAction(
				actions,
				"cast_ability",
				score,
				abilityAction,
				"sealed arena combat; " .. tostring(abilityAction.reason or "profile ability")
			)
		end

		if context.target ~= nil then
			AddAction(
				actions,
				"attack_target",
				135 + (context.target_priority or 0),
				{
					target = context.target,
					maximum_distance = context.max_chase_distance,
				},
				"sealed arena: maintain strict boss focus"
			)
		else
			AddAction(
				actions,
				"attack_move",
				130,
				{ position = context.anchor },
				"sealed arena: advance and reacquire the priority boss"
			)
		end
		return self:Sort(actions)
	end

	if context.encounter_mode == "muradin_survival" then
		for _, abilityAction in ipairs(context.ability_actions or {}) do
			if abilityAction.no_combat_safe == true then
				local selfHeal = abilityAction.is_heal == true
					and abilityAction.heals_self == true
					and (tonumber(abilityAction.self_effective_heal_ratio) or 0) >= 0.04
					and context.health_ratio <= math.max(
						context.retreat_threshold or 0.25,
						0.42
					)
				local allyHeal = abilityAction.is_heal == true
					and (tonumber(abilityAction.effective_heal_ratio) or 0) >= 0.04
					and (tonumber(abilityAction.heal_target_health_ratio) or 1) <= 0.32
				local personalDefense = abilityAction.mode == "self_defensive"
					or abilityAction.mode == "defensive_toggle"
				if selfHeal or allyHeal or personalDefense then
					AddAction(
						actions,
						"cast_ability",
						selfHeal and 200 or allyHeal and 198 or 196,
						abilityAction,
						selfHeal and "emergency self-heal while escaping Muradin"
							or allyHeal and "emergency ally heal without damaging Muradin"
							or "personal defense without damaging Muradin"
					)
				end
			end
		end
		if context.anchor_distance ~= nil
			and context.anchor_distance > (context.encounter_reached_distance or 180) then
			AddAction(
				actions,
				"move_to_objective",
				194,
				{ position = context.anchor },
				"maximize distance from Muradin without attacking"
			)
		else
			AddAction(actions, "hold", 80, {}, "remain far from Muradin")
		end
		return self:Sort(actions)
	end

	if (context.danger or 0) > 0 then
		AddAction(
			actions,
			"evade_danger",
			105 + context.danger * 65,
			{
				position = context.safe_position,
				severity = context.danger,
				interrupt_channel = context.danger >= (context.channel_interrupt_danger or 0.75),
			},
			"telegraphed danger"
		)
	end

	if context.non_combat_objective == true then
		-- Dialogue/campaign travel is a first-class objective. It must not be
		-- displaced by nearby neutral/VIP entities, loot, runes or offensive
		-- casts. Keep lethal telegraph evasion and useful emergency sustain, and
		-- permit only a close attacker that is actively hitting this bot.
		for _, abilityAction in ipairs(context.ability_actions or {}) do
			local selfHeal = abilityAction.is_heal == true
				and abilityAction.heals_self == true
				and (tonumber(abilityAction.self_effective_heal_ratio) or 0) >= 0.04
				and context.health_ratio <= 0.55
			local personalDefense = (abilityAction.mode == "self_defensive"
				or abilityAction.mode == "defensive_toggle")
				and context.health_ratio <= 0.62
			if selfHeal or personalDefense then
				local sustainScore = (context.danger or 0) > 0
					and (selfHeal and 94 or 90)
					or (selfHeal and 190 or 178)
				AddAction(
					actions,
					"cast_ability",
					sustainScore,
					abilityAction,
					selfHeal and "campaign travel emergency self-heal"
						or "campaign travel personal defense"
				)
			end
		end
		if context.target ~= nil then
			AddAction(
				actions,
				"attack_target",
				185 + (context.target_priority or 0),
				{
					target = context.target,
					maximum_distance = context.max_chase_distance,
				},
				"campaign route immediate self-defense"
			)
		elseif context.anchor_distance ~= nil
			and context.anchor_distance
				> (tonumber(context.objective_reached_distance) or 180) then
			AddAction(
				actions,
				"move_to_objective",
				(context.danger or 0) > 0 and 80
					or 145 + (tonumber(context.assignment_urgency) or 0) * 25,
				{ position = context.anchor },
				"advance to non-combat campaign objective"
			)
		else
			AddAction(actions, "hold", 120, {}, "await campaign interaction")
		end
		return self:Sort(actions)
	end

	local retreatThreshold = context.retreat_threshold or 0.25
	if context.base_last_stand == true and context.shopping ~= true then
		-- The Ancient is the hard retreat limit, but the campfire is not a
		-- generic destination. Fight where contact happens; only a freshly
		-- respawned bot already surrounded at spawn treats this as a local hold.
		for _, abilityAction in ipairs(context.ability_actions or {}) do
			local score = (tonumber(abilityAction.score) or 60) + 45
			local reason = "base last stand; "
				.. tostring(abilityAction.reason or "profile ability")
			if abilityAction.is_heal == true
				and abilityAction.heals_self == true
				and (tonumber(abilityAction.self_effective_heal_ratio) or 0) >= 0.04
				and context.health_ratio <= 0.72 then
				score = math.max(score, 195)
				reason = "base last stand emergency self-heal"
			elseif (abilityAction.mode == "self_defensive"
				or abilityAction.mode == "defensive_toggle")
				and context.health_ratio <= 0.78 then
				score = math.max(score, 185)
				reason = "base last stand personal defense"
			end
			AddAction(actions, "cast_ability", score, abilityAction, reason)
		end

		if context.target ~= nil then
			AddAction(
				actions,
				"attack_target",
				175 + (context.target_priority or 0)
					+ (context.spawn_campfire_hold == true and 15 or 0),
				{
					target = context.target,
					maximum_distance = context.max_chase_distance,
				},
				context.spawn_campfire_hold == true
					and "fresh respawn surrounded: clear the spawn"
					or "Ancient retreat limit: stand and fight"
			)
		end
		return self:Sort(actions)
	end

	if context.at_ancient_retreat_limit == true
		and context.shopping ~= true
		and context.target == nil
		and context.health_ratio <= retreatThreshold then
		for _, abilityAction in ipairs(context.ability_actions or {}) do
			if abilityAction.is_heal == true
				and abilityAction.heals_self == true
				and (tonumber(abilityAction.self_effective_heal_ratio) or 0) >= 0.04 then
				AddAction(
					actions,
					"cast_ability",
					190,
					abilityAction,
					"recover at Ancient retreat limit"
				)
			end
		end
		local nearbyAttackers = (tonumber(context.close_enemies) or 0) > 0
		local lastStandPosition = context.strategic_threat_position
			or context.retreat_position
		if nearbyAttackers and lastStandPosition ~= nil then
			AddAction(
				actions,
				"attack_move",
				145,
				{ position = lastStandPosition },
				"Ancient last stand: clear nearby attackers"
			)
		else
			AddAction(actions, "hold", 120, {}, "recover in place at Ancient")
		end
		return self:Sort(actions)
	end

	local combatThreat = tonumber(context.combat_threat) or 0
	if context.revive_channeling == true then
		local mustAbort = (tonumber(context.raw_danger) or 0)
			>= (tonumber(context.channel_interrupt_danger) or 0.75)
			or combatThreat >= 0.85
			or (tonumber(context.recent_damage_ratio) or 0) >= 0.16
			or (tonumber(context.focused_by) or 0) >= 1
		if mustAbort and context.retreat_position ~= nil then
			AddAction(
				actions,
				"retreat",
				200,
				{ position = context.retreat_position, interrupt_channel = true },
				"abort threatened tombstone channel"
			)
		else
			AddAction(actions, "wait", 200, {}, "protect tombstone channel")
		end
		return self:Sort(actions)
	end

	if context.revive_target ~= nil then
		AddAction(
			actions,
			"revive_ally",
			188,
			{ target = context.revive_target },
			"safe tombstone revive opportunity"
		)
		return self:Sort(actions)
	end

	if context.shopping == true then
		for _, abilityAction in ipairs(context.ability_actions or {}) do
			local emergencyShopHeal = abilityAction.is_heal == true
				and abilityAction.heals_self == true
				and (tonumber(abilityAction.self_effective_heal_ratio) or 0) >= 0.04
				and context.health_ratio <= math.max(
					context.retreat_threshold or 0.25,
					0.40
				)
			if emergencyShopHeal then
				local healScore = (context.danger or 0) >= 0.75 and 150 or 175
				AddAction(
					actions,
					"cast_ability",
					healScore,
					abilityAction,
					"emergency self-heal while returning to shop"
				)
			end
		end
		if context.anchor_distance ~= nil and context.anchor_distance > 180 then
			AddAction(
				actions,
				"move_to_objective",
				context.shopping_urgent == true and 158 or 132,
				{ position = context.anchor },
				context.shopping_urgent == true
					and "emergency health potion restock"
					or "travel to assigned shop"
			)
		else
			AddAction(actions, "hold", 30, {}, "wait in shop range for purchase")
		end
		return self:Sort(actions)
	end

	local threatenedRetreat = combatThreat >= 1.05
		and context.health_ratio <= math.min(0.52, retreatThreshold + 0.08)
	-- Preemption contract: a confident fatal-before-escape forecast may beat
	-- ordinary combat, runes and lane movement. Sealed arenas, Muradin,
	-- shopping and Ancient/campfire last stand have already taken control
	-- above and therefore remain stronger authorities.
	local forecastFatal = context.fatal_before_escape == true
		and (tonumber(context.forecast_confidence) or 0) >= 0.48
		and (
			context.health_ratio <= math.min(0.82, retreatThreshold + 0.30)
			or (tonumber(context.time_to_die) or 9999)
				<= math.min(
					3.5,
					(tonumber(context.escape_time) or 0) + 0.55
				)
		)
	local shouldRetreat = context.no_retreat ~= true
		and context.last_stand ~= true
		and (
			context.health_ratio <= retreatThreshold
			or threatenedRetreat
			or forecastFatal
		)
	if shouldRetreat
		and (tonumber(context.retreat_distance) or math.huge) > 160 then
		local forecastMargin = math.max(
			0,
			(tonumber(context.escape_time) or 0)
				- (tonumber(context.time_to_die) or 9999)
		)
		local urgency = Clamp(
			(retreatThreshold - context.health_ratio) / math.max(0.05, retreatThreshold)
				+ combatThreat * 0.35
				+ (tonumber(context.recent_damage_ratio) or 0) * 1.5
				+ math.min(0.65, forecastMargin * 0.22)
				+ (forecastFatal and 0.35 or 0),
			0,
			1.5
		)
		AddAction(
			actions,
			"retreat",
			90 + urgency * 38 + math.min(28, combatThreat * 22),
			{
				position = context.retreat_position,
				interrupt_channel = context.health_ratio <= retreatThreshold * 0.78
					or combatThreat >= 1.05,
			},
			(forecastFatal and "fatal forecast " or "survival ")
				.. "threat="
				.. tostring(math.floor(combatThreat * 100) / 100)
				.. " ttd="
				.. tostring(
					math.floor((tonumber(context.time_to_die) or 9999) * 10) / 10
				)
				.. " escape="
				.. tostring(
					math.floor((tonumber(context.escape_time) or 0) * 10) / 10
				)
				.. " cover=" .. tostring(context.retreat_cover or "none")
		)
	end

	-- A spawned XHS rune is a progression objective, not incidental loot.
	-- Once a healthy bot has claimed one, ordinary creeps and offensive casts
	-- must not cancel the route every think tick. Survival, telegraphs, urgent
	-- shopping, base defense, and sealed encounters have already had the chance
	-- to take control above.
	local runeDistance = tonumber(context.rune_distance) or math.huge
	local runeCritical = context.rune_progression_critical == true
	local runeHealthMargin = tonumber(context.rune_health_margin)
		or (runeCritical and 0.03 or 0.08)
	local runeHealthFloor = math.max(
		retreatThreshold + runeHealthMargin,
		runeCritical and 0.34 or 0.44
	)
	local runeThreatCeiling = tonumber(context.rune_threat_ceiling) or 0.95
	if runeCritical then runeThreatCeiling = runeThreatCeiling + 0.22 end
	local rawDanger = tonumber(context.raw_danger)
		or tonumber(context.danger) or 0
	local recentDamage = tonumber(context.recent_damage_ratio) or 0
	local runeSafe = context.rune_position ~= nil
		and rawDanger <= 0
		and recentDamage < (runeCritical and 0.30 or 0.20)
		and (
			context.health_ratio > runeHealthFloor
				and combatThreat < runeThreatCeiling
			or runeDistance <= 450
				and context.health_ratio > retreatThreshold - 0.02
				and combatThreat < 1.15
		)
	if runeSafe and not shouldRetreat then
		local runePreWave = context.rune_pre_wave == true
		for _, abilityAction in ipairs(context.ability_actions or {}) do
			local selfEmergency = abilityAction.is_heal == true
				and abilityAction.heals_self == true
				and (tonumber(abilityAction.self_effective_heal_ratio) or 0) >= 0.04
				and context.health_ratio <= math.max(retreatThreshold + 0.16, 0.55)
			local allyEmergency = abilityAction.is_heal == true
				and (tonumber(abilityAction.effective_heal_ratio) or 0) >= 0.08
				and (tonumber(abilityAction.heal_target_health_ratio) or 1) <= 0.22
			local personalDefense = (abilityAction.mode == "self_defensive"
				or abilityAction.mode == "defensive_toggle")
				and context.health_ratio <= 0.58
				and combatThreat >= 0.35
			if selfEmergency or allyEmergency or personalDefense then
				AddAction(
					actions,
					"cast_ability",
					selfEmergency and 252 or allyEmergency and 250 or 246,
					abilityAction,
					selfEmergency and "emergency self-heal before continuing rune route"
						or allyEmergency and "critical ally rescue during rune route"
						or "personal defense while securing rune"
				)
			end
		end

		local runeScore = Clamp(
			(tonumber(context.rune_priority) or 218)
				+ (runeCritical and 18 or 0)
				+ (runePreWave and 12 or 0)
				- math.min(12, runeDistance / 1000)
				- math.min(10, combatThreat * 4),
			205,
			runePreWave and 248 or 242
		)
		AddAction(
			actions,
			"move_to_objective",
			runeScore,
			{
				position = context.rune_position,
				objective = "rune",
				rune_id = context.rune_id,
			},
			(runePreWave and "pre-wave preparation: collect "
				or runeCritical and "progression unlock: collect "
				or "collect central ")
				.. tostring(context.rune_type or "nearby") .. " rune"
		)
		return self:Sort(actions)
	end

	if not shouldRetreat and context.loot_entity ~= nil then
		if context.loot_kind == "drop"
			or context.loot_kind == "shared_tome" then
			local sharedTome = context.loot_kind == "shared_tome"
			AddAction(
				actions,
				"pickup_loot",
				sharedTome
					and Clamp(
						132 - (tonumber(context.loot_distance) or 0) / 70,
						116,
						132
					)
					or Clamp(
						118 - (tonumber(context.loot_distance) or 0) / 80,
						104,
						118
					),
				{
					target = context.loot_entity,
					position = context.loot_position,
					objective = sharedTome and "shared_tome" or "crate_loot",
					item_name = context.loot_item,
				},
				sharedTome
					and "pick up shared tome "
						.. tostring(context.loot_item or "")
					or "pick up crate loot "
						.. tostring(context.loot_item or "")
			)
		elseif context.loot_kind == "crate" then
			AddAction(
				actions,
				"break_crate",
				Clamp(76 - (tonumber(context.loot_distance) or 0) / 100, 67, 76),
				{
					target = context.loot_entity,
					maximum_distance = 900,
					objective = "crate",
				},
				"break nearby loot crate"
			)
		end
	end

	for _, abilityAction in ipairs(context.ability_actions or {}) do
		local abilityScore = abilityAction.score
			+ (context.last_stand == true and 35 or 0)
		local abilityReason = abilityAction.reason or "profile ability"
		if abilityAction.is_heal == true then
			local selfSaveThreshold = math.min(
				0.62,
				math.max(retreatThreshold + 0.12, 0.40)
			)
			local selfHealUseful = abilityAction.heals_self == true
				and (tonumber(abilityAction.self_effective_heal_ratio) or 0) >= 0.04
			local selfEmergency = selfHealUseful
				and context.health_ratio <= selfSaveThreshold
			local targetRatio = tonumber(abilityAction.heal_target_health_ratio) or 1
			local allyEmergency = (tonumber(abilityAction.effective_heal_ratio) or 0) >= 0.04
				and targetRatio <= math.min(0.58, retreatThreshold + 0.18)
			if selfEmergency then
				local missingSeverity = Clamp(
					(selfSaveThreshold - context.health_ratio) / math.max(0.10, selfSaveThreshold),
					0,
					1
				)
				abilityScore = math.max(
					abilityScore,
					152 + missingSeverity * 25
						+ math.min(12, combatThreat * 8)
						+ math.min(10, (tonumber(context.recent_damage_ratio) or 0) * 40)
				)
				abilityReason = "emergency self-heal before disengaging; " .. abilityReason
			elseif allyEmergency then
				abilityScore = math.max(
					abilityScore,
					138 + (0.58 - targetRatio) * 35
				)
				abilityReason = "rescue endangered ally; " .. abilityReason
			end
			if (context.danger or 0) >= 0.75 then
				abilityScore = math.min(abilityScore, 150)
				abilityReason = "evade lethal telegraph before healing; " .. abilityReason
			end
		end
		AddAction(
			actions,
			"cast_ability",
			abilityScore,
			abilityAction,
			abilityReason
		)
	end

	local engagementHolding = context.force_combat ~= true
		and context.target ~= nil
		and context.engagement_allow_attack == false
	if engagementHolding then
		local holdPosition = context.reposition_position
			or context.retreat_position
			or context.anchor
		if holdPosition ~= nil then
			AddAction(
				actions,
				"reposition",
				94,
				{ position = holdPosition },
				context.engagement_mode == "SHOP_POWER_SPIKE"
					and "do not feed: buy the planned power spike"
					or context.engagement_mode == "WAIT_FOR_ONE_HELPER"
						and "hold the pack edge for one responder"
					or "avoid an unfavourable pack and preserve resources"
			)
		end
	end

	if context.target ~= nil and not engagementHolding then
		if context.too_close == true then
			AddAction(
				actions,
				"reposition",
				84,
				{ position = context.reposition_position },
				"maintain preferred range"
			)
		end

		AddAction(
			actions,
			"attack_target",
			66 + (context.target_priority or 0)
				+ (context.force_combat == true and 44 or 0)
				+ (context.last_stand == true and 45 or 0),
			{
				target = context.target,
				maximum_distance = context.max_chase_distance,
			},
			context.force_combat == true
				and "committed phase 3/4 boss combat"
				or context.last_stand == true
				and "fight under Ancient or tower cover"
				or "combat target available"
		)
	end

	if context.target == nil and context.last_seen_position ~= nil then
		AddAction(
			actions,
			"move_to_last_seen",
			58,
			{ position = context.last_seen_position },
			"briefly inspect the target's last team-visible position"
		)
	end

	if not engagementHolding
		and context.anchor_distance ~= nil and context.anchor_distance > 260 then
		local movementScore = Clamp(
			42 + context.anchor_distance / 100
				+ (context.assignment_urgency or 0) * 12
				+ (context.returning_to_lane == true and context.target == nil and 30 or 0),
			42,
			context.returning_to_lane == true and 108 or 78
		)
		if context.attack_move == true then
			AddAction(
				actions,
				"attack_move",
				movementScore,
				{ position = context.anchor },
				context.returning_to_lane == true
					and "return to assigned lane while screening"
					or "advance while screening the team objective"
			)
		else
			AddAction(
				actions,
				"move_to_objective",
				movementScore,
				{ position = context.anchor },
				context.returning_to_lane == true
					and "return to assigned lane"
					or "team assignment"
			)
		end
	end

	AddAction(actions, "hold", 8, {}, "no higher utility action")
	return self:Sort(actions)
end

return XHSBotUtility
