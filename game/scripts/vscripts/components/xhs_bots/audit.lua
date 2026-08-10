if XHSBotDecisionAudit == nil then
	XHSBotDecisionAudit = class({})
end

XHSBotDecisionAudit.schema = 3
XHSBotDecisionAudit.sample_interval = 0.5
XHSBotDecisionAudit.heartbeat_interval = 10
XHSBotDecisionAudit.max_events = 3000
-- The backend owns the complete audit chronology. Keep VConsole quiet: the
-- Tools commands still return one bounded [XHSBots][QA] acknowledgement.
XHSBotDecisionAudit.console_output_enabled = false
XHSBotDecisionAudit.console_chunk_size = 1000
XHSBotDecisionAudit.console_chunk_batch_size = 8
XHSBotDecisionAudit.console_chunk_batch_interval = 0.05
XHSBotDecisionAudit.orb_affordable_gold = 10000

local function AuditNow()
	if GameRules ~= nil and GameRules.GetGameTime ~= nil then
		local ok, value = pcall(function() return GameRules:GetGameTime() end)
		if ok and tonumber(value) ~= nil then
			return math.max(0, tonumber(value))
		end
	end
	if Time ~= nil then
		local ok, value = pcall(Time)
		if ok and tonumber(value) ~= nil then
			return math.max(0, tonumber(value))
		end
	end
	return 0
end

local function IsValidHandle(entity)
	if entity == nil then return false end
	if IsValidEntity ~= nil then
		local ok, valid = pcall(IsValidEntity, entity)
		if not ok or valid ~= true then return false end
	end
	if type(entity.IsNull) == "function" then
		local ok, isNull = pcall(entity.IsNull, entity)
		if not ok or isNull == true then return false end
	end
	return true
end

local function SafeEntityName(entity)
	if not IsValidHandle(entity) then return "" end
	local getter = entity.GetUnitName
	if type(getter) ~= "function" then getter = entity.GetClassname end
	if type(getter) ~= "function" then return "" end
	local ok, name = pcall(getter, entity)
	return ok and tostring(name or "") or ""
end

local function SafeAbilityName(ability)
	if ability == nil or type(ability.GetAbilityName) ~= "function" then return "" end
	if type(ability.IsNull) == "function" then
		local ok, isNull = pcall(ability.IsNull, ability)
		if not ok or isNull == true then return "" end
	end
	local ok, name = pcall(ability.GetAbilityName, ability)
	return ok and tostring(name or "") or ""
end

local function SafeEntityFromIndex(entindex)
	entindex = tonumber(entindex)
	if entindex == nil or entindex < 0 or EntIndexToHScript == nil then return nil end
	local ok, entity = pcall(EntIndexToHScript, entindex)
	return ok and IsValidHandle(entity) and entity or nil
end

local function SafePosition(entity)
	if not IsValidHandle(entity) or type(entity.GetAbsOrigin) ~= "function" then
		return nil
	end
	local ok, position = pcall(entity.GetAbsOrigin, entity)
	return ok and position or nil
end

local function PositionText(position)
	if position == nil then return "none" end
	return tostring(math.floor(tonumber(position.x) or 0))
		.. "," .. tostring(math.floor(tonumber(position.y) or 0))
end

local function PositionBucket(position, size)
	if position == nil then return "none" end
	size = math.max(1, tonumber(size) or 400)
	return tostring(math.floor((tonumber(position.x) or 0) / size))
		.. ":" .. tostring(math.floor((tonumber(position.y) or 0) / size))
end

local function DistanceBetween(first, second)
	if first == nil or second == nil then return -1 end
	local dx = (tonumber(first.x) or 0) - (tonumber(second.x) or 0)
	local dy = (tonumber(first.y) or 0) - (tonumber(second.y) or 0)
	return math.sqrt(dx * dx + dy * dy)
end

local function BooleanNumber(value)
	return value == true and 1 or 0
end

local function JoinValues(values)
	local result = {}
	for _, value in ipairs(values or {}) do
		table.insert(result, tostring(value))
	end
	return table.concat(result, ",")
end

local function SafeGold(playerID)
	if XHSBotEconomy ~= nil and XHSBotEconomy.GetGold ~= nil then
		local ok, gold = pcall(function()
			return XHSBotEconomy:GetGold(playerID)
		end)
		if ok then return math.max(0, math.floor(tonumber(gold) or 0)) end
	end
	return 0
end

local function HeroHasOrb(hero, record)
	if tonumber(record and record.orb_owned_family_count) ~= nil
		and tonumber(record.orb_owned_family_count) > 0 then
		return true
	end
	if not IsValidHandle(hero) or type(hero.GetItemInSlot) ~= "function" then
		return false
	end
	for slot = 0, 14 do
		local ok, item = pcall(hero.GetItemInSlot, hero, slot)
		if ok and IsValidHandle(item) and type(item.GetAbilityName) == "function" then
			local itemOK, name = pcall(item.GetAbilityName, item)
			if itemOK and string.find(tostring(name or ""), "item_orb_", 1, true) == 1 then
				return true
			end
		end
	end
	return false
end

local function IsRetreatState(state)
	state = string.upper(tostring(state or ""))
	return string.find(state, "RETREAT", 1, true) ~= nil
		or string.find(state, "RECOVER", 1, true) ~= nil
		or state == "SEEKING_COVER"
end

local function AuditValue(value, maximumLength)
	local text = tostring(value == nil and "none" or value)
	text = string.gsub(text, "[%c%s=|]+", "_")
	text = string.gsub(text, "[^%w%._:%-,/]+", "_")
	if text == "" then text = "none" end
	return string.sub(text, 1, tonumber(maximumLength) or 160)
end

local function SortedFieldText(fields)
	local keys = {}
	for key in pairs(fields or {}) do table.insert(keys, tostring(key)) end
	table.sort(keys)
	local parts = {}
	for _, key in ipairs(keys) do
		table.insert(parts, key .. "=" .. AuditValue(fields[key], 220))
	end
	return table.concat(parts, " ")
end

local function EmitAuditLine(line)
	if XHSBotDecisionAudit == nil
		or XHSBotDecisionAudit.console_output_enabled ~= true then
		return
	end
	line = string.sub(tostring(line or ""), 1, 2048)
	local emitted = false
	if type(NativePrint) == "function" then
		emitted = pcall(NativePrint, line)
	end
	if not emitted and type(print) == "function" then
		emitted = pcall(print, line)
	end
	if not emitted and type(Warning) == "function" then
		pcall(Warning, line .. "\n")
	end
end

local function FormatEventLine(event)
	local fields = SortedFieldText(event and event.fields or {})
	return "[XHSBots][AUDIT] type=event"
		.. " seq=" .. tostring(event and event.seq or 0)
		.. " t=" .. string.format("%.1f", tonumber(event and event.t) or 0)
		.. " last_t=" .. string.format("%.1f", tonumber(event and event.last_t) or 0)
		.. " repeat=" .. tostring(event and event.repeats or 1)
		.. " pid=" .. tostring(event and event.player_id or -1)
		.. " kind=" .. AuditValue(event and event.kind, 48)
		.. (fields ~= "" and (" " .. fields) or "")
end

local function TopActionsText(actions)
	local result = {}
	for index = 1, math.min(3, #(actions or {})) do
		local action = actions[index] or {}
		table.insert(
			result,
			AuditValue(action.id, 32)
				.. ":" .. tostring(math.floor((tonumber(action.score) or 0) * 10) / 10)
				.. ":" .. AuditValue(action.reason, 80)
		)
	end
	return table.concat(result, ",")
end

function XHSBotDecisionAudit:Reset()
	self.console_printer_generation = (tonumber(self.console_printer_generation) or 0) + 1
	self.active = false
	self.finalized = false
	self.auto_dumped = false
	self.started_at = 0
	self.stopped_at = 0
	self.start_reason = ""
	self.sequence = 0
	self.event_count = 0
	self.event_write_index = 1
	self.event_slots = {}
	-- Console chunks are drained as they are printed. Keep a separate append-only
	-- chronology for the production backend so the admin copy contains the whole
	-- match instead of only the unprinted tail.
	self.backend_events = {}
	self.last_events = {}
	self.bot_stats = {}
	self.event_progress = {}
	self.global_signature = ""
	self.next_sample_at = 0
	self.last_sample_at = nil
	self.max_phase = 0
	self.dropped_events = 0
	self.dump_count = 0
	self.console_session_generation =
		(tonumber(self.console_session_generation) or 0) + 1
	self.console_session_id = ""
	self.console_chunk_count = 0
	self.console_flushed_events = 0
	self.console_chunks = {}
	self.console_chunk_printing = false
end

function XHSBotDecisionAudit:IsActive()
	return self.active == true
end

function XHSBotDecisionAudit:GetBotStats(playerID)
	playerID = tonumber(playerID) or -1
	local stats = self.bot_stats[playerID]
	if stats == nil then
		stats = {
			player_id = playerID,
			deaths = 0,
			respawns = 0,
			decisions_planned = 0,
			decisions_executed = 0,
			decisions_rejected = 0,
			purchase_attempts = 0,
			purchases = 0,
			purchase_failures = 0,
			orb_purchases = 0,
			arena_preparation_tomes = 0,
			arena_downtime_shop_assignments = 0,
			max_gold_without_orb = 0,
			orb_affordable_seconds = 0,
			shopping_seconds = 0,
			retreat_seconds = 0,
			retreat_stationary_seconds = 0,
			phase1_off_lane_seconds = 0,
			lane_mismatch_seconds = 0,
			base_response_ignored_seconds = 0,
			unnecessary_regroup_seconds = 0,
			first_orb_at = nil,
			initial_lane = nil,
			initial_participant_player_id = nil,
			previous_alive = nil,
			previous_position = nil,
			last_snapshot_signature = "",
			next_heartbeat_at = 0,
			seen_valid_hero = false,
			missing_hero_seconds = 0,
			missing_hero_reported = false,
		}
		self.bot_stats[playerID] = stats
	end
	return stats
end

function XHSBotDecisionAudit:Record(kind, playerID, signature, fields, aggregate)
	if self.active ~= true then return nil end
	local now = AuditNow()
	playerID = tonumber(playerID) or -1
	kind = tostring(kind or "unknown")
	signature = tostring(signature or kind)
	local lastKey = tostring(playerID) .. ":" .. kind
	local previous = self.last_events[lastKey]
	if aggregate == true
		and previous ~= nil
		and previous.signature == signature
		and self.sequence - (tonumber(previous.seq) or 0) < self.max_events then
		previous.repeats = (tonumber(previous.repeats) or 1) + 1
		previous.last_t = now
		previous.fields = fields or previous.fields
		return previous
	end

	self.sequence = self.sequence + 1
	local event = {
		seq = self.sequence,
		t = now,
		last_t = now,
		player_id = playerID,
		kind = kind,
		signature = signature,
		repeats = 1,
		fields = fields or {},
	}
	table.insert(self.backend_events, event)
	local slot = self.event_write_index
	self.event_slots[slot] = event
	if self.event_count < self.max_events then
		self.event_count = self.event_count + 1
	else
		self.dropped_events = self.dropped_events + 1
	end
	self.event_write_index = (slot % self.max_events) + 1
	self.last_events[lastKey] = event
	return event
end

function XHSBotDecisionAudit:Start(reason)
	self:Reset()
	self.active = true
	self.started_at = AuditNow()
	self.console_session_id = tostring(math.floor(self.started_at * 10))
		.. "_" .. tostring(self.console_session_generation)
	self.start_reason = tostring(reason or "manual")
	self:Record("audit_started", -1, self.start_reason, {
		reason = self.start_reason,
		game_state = GameRules ~= nil and GameRules:State_Get() or -1,
	}, false)
	return true
end

function XHSBotDecisionAudit:EnsureStarted(reason)
	if self.active == true then return false end
	if self.finalized == true then return false end
	self:Start(reason or "automatic")
	return true
end

function XHSBotDecisionAudit:RecordDecision(
	playerID,
	stage,
	action,
	record,
	assignment
)
	if self.active ~= true or type(action) ~= "table" then return end
	local stats = self:GetBotStats(playerID)
	stage = tostring(stage or "planned")
	if stage == "planned" then
		stats.decisions_planned = stats.decisions_planned + 1
	elseif stage == "executed" then
		stats.decisions_executed = stats.decisions_executed + 1
	else
		stats.decisions_rejected = stats.decisions_rejected + 1
	end

	local data = type(action.data) == "table" and action.data or {}
	local target = data.target
	local position = data.position
	local signature = stage
		.. ":" .. tostring(action.id or "")
		.. ":" .. SafeAbilityName(data.ability)
		.. ":" .. tostring(IsValidHandle(target) and target:entindex() or -1)
		.. ":" .. tostring(data.objective or "")
		.. ":" .. tostring(data.desired_state)
		.. ":" .. PositionBucket(position, 250)
	self:Record("decision_" .. stage, playerID, signature, {
		action = action.id or "",
		score = math.floor((tonumber(action.score) or 0) * 10) / 10,
		reason = action.reason or "",
		ability = SafeAbilityName(data.ability),
		target = SafeEntityName(target),
		target_entindex = IsValidHandle(target) and target:entindex() or -1,
		objective = data.objective or "",
		item = data.item_name or "",
		desired_state = data.desired_state == nil
			and "none" or tostring(data.desired_state),
		position = PositionText(position),
		state = record and record.state or "",
		macro = record and record.macro_state or "",
		goal = assignment and assignment.goal or record and record.goal or "",
		lane = assignment and assignment.lane or record and record.lane or 0,
		top = TopActionsText(record and record.top_actions or {}),
	}, true)
end

function XHSBotDecisionAudit:RecordPurchase(
	playerID,
	success,
	entry,
	record,
	requiredShop,
	actualShop,
	shopDistance,
	result
)
	if self.active ~= true then return end
	entry = type(entry) == "table" and entry or {}
	local stats = self:GetBotStats(playerID)
	stats.purchase_attempts = stats.purchase_attempts + 1
	local itemName = tostring(entry.name or entry.purchase_name or "")
	if success == true then
		stats.purchases = stats.purchases + 1
		if string.find(itemName, "item_orb_", 1, true) == 1 then
			stats.orb_purchases = stats.orb_purchases + 1
			stats.first_orb_at = stats.first_orb_at or AuditNow()
		end
	else
		stats.purchase_failures = stats.purchase_failures + 1
	end
	self:Record(
		success == true and "purchase_success" or "purchase_failure",
		playerID,
		tostring(success) .. ":" .. itemName .. ":" .. tostring(result or ""),
		{
			item = itemName,
			cost = math.floor(tonumber(entry.cost) or 0),
			gold_after = SafeGold(playerID),
			required_shop = requiredShop or "",
			actual_shop = actualShop or "",
			shop_distance = math.floor(tonumber(shopDistance) or -1),
			result = result or "",
			phase = record and record.economy_phase or "",
			reserve = math.floor(tonumber(record and record.economy_reserve_gold) or 0),
			planned_item = record and record.planned_item or "",
			item_action = record and record.last_item_action or "",
			item_rejection = record and record.last_item_rejection or "",
		},
		false
	)
end

function XHSBotDecisionAudit:RecordArenaPreparation(
	playerID,
	role,
	encounter,
	result,
	record,
	tomeCount
)
	if self.active ~= true then return end
	local stats = self:GetBotStats(playerID)
	tomeCount = math.max(0, math.floor(tonumber(tomeCount) or 0))
	if tostring(role) == "participant" then
		stats.arena_preparation_tomes =
			(stats.arena_preparation_tomes or 0) + tomeCount
	elseif tostring(role) == "downtime_shopper"
		and tostring(result) == "assigned" then
		stats.arena_downtime_shop_assignments =
			(stats.arena_downtime_shop_assignments or 0) + 1
	end
	self:Record("arena_preparation", playerID, table.concat({
		tostring(role or ""),
		tostring(encounter or ""),
		tostring(result or ""),
		tostring(tomeCount),
	}, ":"), {
		role = role or "",
		encounter = encounter or "",
		result = result or "",
		tomes = tomeCount,
		tomes_total = tonumber(record and record.arena_preparation_tomes) or 0,
		gold_after = SafeGold(playerID),
		reserve = math.floor(
			tonumber(record and record.economy_reserve_gold) or 0
		),
		planned_item = record and record.planned_item or "",
		shopping_item = type(record and record.shopping_goal) == "table"
			and record.shopping_goal.item or "",
	}, false)
end

function XHSBotDecisionAudit:TrackGameEvent(name, active, outcome)
	name = tostring(name or "unknown")
	local progress = self.event_progress[name]
	if progress == nil then
		progress = {
			status = "not_started",
			active = false,
		}
		self.event_progress[name] = progress
	end
	if active == true and progress.active ~= true then
		progress.active = true
		progress.status = "active"
		progress.started_at = AuditNow()
		self:Record("event_started", -1, name .. ":start", {
			event = name,
		}, false)
	elseif active ~= true and progress.active == true then
		progress.active = false
		progress.status = tostring(outcome or "completed")
		progress.ended_at = AuditNow()
		self:Record("event_finished", -1, name .. ":" .. progress.status, {
			event = name,
			outcome = progress.status,
			duration = string.format(
				"%.1f",
				math.max(0, progress.ended_at - (progress.started_at or progress.ended_at))
			),
		}, false)
	end
end

function XHSBotDecisionAudit:SampleGlobal()
	local phase = CustomTimers ~= nil
		and math.max(0, tonumber(CustomTimers.game_phase) or 0) or 0
	local creepLevel = CustomTimers ~= nil
		and math.max(0, tonumber(CustomTimers.creep_level) or 0) or 0
	self.max_phase = math.max(self.max_phase or 0, phase)

	local muradinActive = GameMode ~= nil and GameMode.Muradin_occuring == true
	local farmActive = GameMode ~= nil and GameMode.FarmEvent_occuring == true
	local arenaActive = GameMode ~= nil and GameMode.SpecialArena_occuring == true
	local arenaTrigger = SpecialEvents ~= nil
		and tonumber(SpecialEvents.Ramero_trigger) or 0
	local arenaName = arenaTrigger == 1 and "ramero_baristol"
		or arenaTrigger == 2 and "sogat" or ""

	self:TrackGameEvent("muradin", muradinActive, "completed")
	self:TrackGameEvent("farm", farmActive, "completed")
	self:TrackGameEvent(
		"ramero_baristol",
		arenaActive and arenaName == "ramero_baristol",
		SpecialEvents ~= nil
			and SpecialEvents.RameroDead == true
			and SpecialEvents.BaristolDead == true
			and "won" or "lost"
	)
	self:TrackGameEvent(
		"sogat",
		arenaActive and arenaName == "sogat",
		SpecialEvents ~= nil
			and (SpecialEvents.SogatRewardPending == true
				or SpecialEvents.SogatRewardHero ~= nil)
			and "won" or "lost"
	)

	local signature = table.concat({
		tostring(GameRules ~= nil and GameRules:State_Get() or -1),
		tostring(phase),
		tostring(creepLevel),
		tostring(muradinActive),
		tostring(farmActive),
		tostring(arenaActive),
		arenaName,
	}, ":")
	if signature ~= self.global_signature then
		self.global_signature = signature
		self:Record("game_transition", -1, signature, {
			game_state = GameRules ~= nil and GameRules:State_Get() or -1,
			phase = phase,
			creep_level = creepLevel,
			muradin = BooleanNumber(muradinActive),
			farm = BooleanNumber(farmActive),
			arena = arenaName,
		}, false)
	end
end

function XHSBotDecisionAudit:BuildSnapshotFields(
	playerID,
	record,
	hero,
	assignment,
	stats
)
	record = record or {}
	assignment = assignment or {}
	local position = SafePosition(hero)
	local anchor = assignment.anchor
	local health = IsValidHandle(hero) and type(hero.GetHealth) == "function"
		and hero:GetHealth() or 0
	local maxHealth = IsValidHandle(hero) and type(hero.GetMaxHealth) == "function"
		and hero:GetMaxHealth() or 0
	local healthPct = maxHealth > 0 and health / maxHealth or 0
	local shoppingGoal = type(record.shopping_goal) == "table"
		and record.shopping_goal or {}
	local target = SafeEntityFromIndex(record.target_entindex)
	return {
		hero = SafeEntityName(hero),
		alive = BooleanNumber(IsValidHandle(hero) and hero:IsAlive()),
		hp = tostring(math.floor(health)) .. "/" .. tostring(math.floor(maxHealth)),
		hp_pct = math.floor(healthPct * 100),
		position = PositionText(position),
		anchor = PositionText(anchor),
		anchor_distance = math.floor(DistanceBetween(position, anchor)),
		state = record.state or "",
		macro = record.macro_state or "",
		goal = assignment.goal or record.goal or "",
		label = assignment.label or "",
		lane = assignment.lane or record.lane or 0,
		physical_lanes = JoinValues(
			assignment.physical_lanes or record.physical_lanes or {}
		),
		participant_pid = assignment.participant_player_id
			or record.participant_player_id or -1,
		target = SafeEntityName(target),
		target_entindex = record.target_entindex or -1,
		planned_decision = record.planned_decision or "",
		planned_reason = record.planned_decision_reason or "",
		last_decision = record.last_decision or "",
		last_reason = record.last_decision_reason or "",
		last_order = record.last_order or "",
		top = TopActionsText(record.top_actions or {}),
		gold = SafeGold(playerID),
		economy_phase = record.economy_phase or "",
		reserve = math.floor(tonumber(record.economy_reserve_gold) or 0),
		planned_item = record.planned_item or "",
		planned_item_reason = record.planned_item_reason or "",
		shopping_item = shoppingGoal.item or "",
		shopping_shop = shoppingGoal.shop or "",
		shopping_urgent = BooleanNumber(shoppingGoal.urgent == true),
		emergency_hp = BooleanNumber(
			record.emergency_health_resupply_active == true
				or shoppingGoal.emergency_health_resupply == true
		),
		shop_allowed = BooleanNumber(
			XHSBotTeamDirector ~= nil
				and XHSBotTeamDirector.IsShoppingAssignmentAllowed ~= nil
				and XHSBotTeamDirector:IsShoppingAssignmentAllowed(playerID)
		),
		life_insurance = BooleanNumber(shoppingGoal.life_insurance == true),
		shopping_reason = shoppingGoal.reason or "",
		last_purchase = record.last_purchase_item or "",
		last_purchase_at = string.format("%.1f", tonumber(record.last_purchase_at) or 0),
		purchases = tonumber(record.items_purchased) or 0,
		items_sold = tonumber(record.items_sold) or 0,
		last_sale = record.last_sold_item or "",
		last_sale_reason = record.last_sold_item_reason or "",
		sale_gold = tonumber(record.item_sale_gold_recovered) or 0,
		basic_potions_obsolete =
			BooleanNumber(record.basic_potions_obsolete == true),
		item_rejection = record.last_item_rejection or "",
		orb_families = tonumber(record.orb_owned_family_count) or 0,
		hp_potions = tostring(tonumber(record.health_potion_charges) or 0)
			.. "/" .. tostring(tonumber(record.health_potion_target) or 0),
		ankh = tostring(tonumber(record.ankh_charges) or 0)
			.. "/" .. tostring(tonumber(record.ankh_target) or 0),
		threat = string.format("%.2f", tonumber(record.combat_threat) or 0),
		engagement = record.engagement_classification or "",
		engagement_mode = record.engagement_mode or "",
		engagement_packs = tonumber(record.engagement_pack_count) or 0,
		engagement_enemies = tonumber(record.engagement_enemy_count) or 0,
		engagement_ttk = string.format("%.1f", tonumber(record.engagement_time_to_clear) or 0),
		engagement_ttd = string.format("%.1f", tonumber(record.engagement_time_to_die) or 0),
		engagement_ratio = string.format("%.2f", tonumber(record.engagement_survival_ratio) or 0),
		engagement_buy = BooleanNumber(record.engagement_purchase_requested == true),
		engagement_help = BooleanNumber(record.engagement_help_requested == true),
		ultimate_reserve = record.ultimate_reservation_reason or "",
		close_enemies = tonumber(record.close_enemy_count) or 0,
		focused_by = tonumber(record.focused_by_count) or 0,
		base_response = BooleanNumber(record.base_response_required == true),
		base_selected = BooleanNumber(record.base_response_selected == true),
		base_responders = tonumber(record.base_responder_count) or 0,
		base_threat = string.format("%.2f", tonumber(record.base_threat_score) or 0),
		base_enemies = tonumber(record.base_threat_count) or 0,
		special_enemies = tonumber(record.base_special_count) or 0,
		encounter = record.encounter_mode or "",
		rune = record.rune_target_type or "",
		rune_distance = math.floor(tonumber(record.rune_target_distance) or -1),
		loot_kind = record.loot_kind or "",
		loot_item = record.loot_item or "",
		loot_distance = math.floor(tonumber(record.loot_distance) or -1),
		crates_targeted = tonumber(record.crates_targeted) or 0,
		loot_pickup_orders = tonumber(record.loot_pickup_orders) or 0,
		looted_tomes_used = tonumber(record.looted_tomes_used) or 0,
		arena_prep = record.arena_preparation_event or "",
		arena_prep_result = record.arena_preparation_result or "",
		arena_prep_tomes =
			tonumber(record.arena_preparation_tomes) or 0,
		retreats_s = string.format("%.1f", stats.retreat_seconds or 0),
		deaths = stats.deaths or 0,
		respawns = stats.respawns or 0,
	}
end

function XHSBotDecisionAudit:SampleBot(playerID, record, hero, assignment, now)
	if record == nil then return end
	local stats = self:GetBotStats(playerID)
	local previousSampleAt = tonumber(stats.last_sample_at)
	local elapsed = previousSampleAt ~= nil
		and math.max(0, math.min(2, now - previousSampleAt)) or 0
	stats.last_sample_at = now
	stats.hero = SafeEntityName(hero)
	stats.final_record = record

	local heroValid = IsValidHandle(hero)
	local alive = heroValid and hero:IsAlive()
	if heroValid then
		stats.seen_valid_hero = true
		stats.missing_hero_seconds = 0
		stats.missing_hero_reported = false
		stats.last_ankh_charges = tonumber(record.ankh_charges) or 0
		stats.last_ankh_target = tonumber(record.ankh_target) or 0
	elseif stats.seen_valid_hero == true and elapsed > 0 then
		stats.missing_hero_seconds = (stats.missing_hero_seconds or 0) + elapsed
		if stats.missing_hero_reported ~= true
			and stats.missing_hero_seconds >= 2 then
			stats.missing_hero_reported = true
			self:Record("registered_bot_missing_hero", playerID, "missing_hero", {
				missing_seconds = string.format("%.1f", stats.missing_hero_seconds),
				state = record.state or "",
				goal = assignment and assignment.goal or record.goal or "",
				last_order = record.last_order or "",
				deaths = stats.deaths or 0,
				respawns = stats.respawns or 0,
				gold = SafeGold(playerID),
				ankh_charges = stats.last_ankh_charges or 0,
				ankh_target = stats.last_ankh_target or 0,
				life_insurance = BooleanNumber(
					type(record.shopping_goal) == "table"
						and record.shopping_goal.life_insurance == true
				),
				shopping_item = type(record.shopping_goal) == "table"
					and record.shopping_goal.item or "",
				item_rejection = record.last_item_rejection or "",
			}, false)
		end
	end
	if stats.previous_alive == true and not alive then
		stats.deaths = stats.deaths + 1
		self:Record("death", playerID, "death:" .. tostring(stats.deaths), {
			hero = stats.hero,
			state = record.state or "",
			goal = assignment and assignment.goal or record.goal or "",
			lane = assignment and assignment.lane or record.lane or 0,
			gold = SafeGold(playerID),
			purchases = tonumber(record.items_purchased) or 0,
			orb_families = tonumber(record.orb_owned_family_count) or 0,
			ankh_charges = tonumber(record.ankh_charges)
				or stats.last_ankh_charges or 0,
			ankh_target = tonumber(record.ankh_target)
				or stats.last_ankh_target or 0,
			life_insurance = BooleanNumber(
				type(record.shopping_goal) == "table"
					and record.shopping_goal.life_insurance == true
			),
			threat = string.format("%.2f", tonumber(record.combat_threat) or 0),
			close_enemies = tonumber(record.close_enemy_count) or 0,
			base_response = BooleanNumber(record.base_response_required == true),
			last_decision = record.last_decision or "",
			last_order = record.last_order or "",
		}, false)
	elseif stats.previous_alive == false and alive then
		stats.respawns = stats.respawns + 1
		self:Record("respawn", playerID, "respawn:" .. tostring(stats.respawns), {
			hero = stats.hero,
			gold = SafeGold(playerID),
			purchases = tonumber(record.items_purchased) or 0,
			orb_families = tonumber(record.orb_owned_family_count) or 0,
			ankh_charges = tonumber(record.ankh_charges) or 0,
			ankh_target = tonumber(record.ankh_target) or 0,
		}, false)
	elseif stats.previous_alive == nil and not alive then
		self:Record("observed_dead", playerID, "initial_dead", {
			hero = stats.hero,
			gold = SafeGold(playerID),
		}, false)
	end
	stats.previous_alive = alive

	local goal = assignment and assignment.goal or record.goal or ""
	local lane = tonumber(assignment and assignment.lane or record.lane) or 0
	local participantPlayerID = tonumber(
		assignment and assignment.participant_player_id
			or record.participant_player_id
	)
	if lane > 0 and stats.initial_lane == nil then stats.initial_lane = lane end
	if participantPlayerID ~= nil and participantPlayerID >= 0
		and stats.initial_participant_player_id == nil then
		stats.initial_participant_player_id = participantPlayerID
	end

	local gold = SafeGold(playerID)
	local ownsOrb = HeroHasOrb(hero, record)
	if not ownsOrb then
		stats.max_gold_without_orb = math.max(stats.max_gold_without_orb or 0, gold)
		if gold >= self.orb_affordable_gold then
			stats.orb_affordable_seconds =
				(stats.orb_affordable_seconds or 0) + elapsed
		end
	end
	local shopping = goal == "shop" or type(record.shopping_goal) == "table"
	if shopping then stats.shopping_seconds = stats.shopping_seconds + elapsed end
	local retreating = IsRetreatState(record.state)
	if retreating then stats.retreat_seconds = stats.retreat_seconds + elapsed end

	local position = SafePosition(hero)
	local plannedDecision = tostring(record.planned_decision or "")
	local lastDecision = tostring(record.last_decision or "")
	local retreatMovementExpected = plannedDecision == "retreat"
		or plannedDecision == "evade_danger"
		or lastDecision == "retreat"
		or lastDecision == "evade_danger"
	if retreating and retreatMovementExpected
		and alive and elapsed > 0 and position ~= nil
		and stats.previous_position ~= nil
		and DistanceBetween(position, stats.previous_position) < 45 then
		stats.retreat_stationary_seconds =
			stats.retreat_stationary_seconds + elapsed
	end
	stats.previous_position = position

	local phase = CustomTimers ~= nil
		and tonumber(CustomTimers.game_phase) or 0
	local inEncounter = tostring(record.encounter_mode or "") ~= ""
	if phase == 1 and alive and elapsed > 0
		and goal ~= "defend_lane"
		and goal ~= "shop"
		and goal ~= "defend_base"
		and goal ~= "participate_event"
		and not retreating
		and not inEncounter then
		stats.phase1_off_lane_seconds = stats.phase1_off_lane_seconds + elapsed
	end
	if stats.initial_lane ~= nil and lane > 0 and lane ~= stats.initial_lane then
		stats.lane_mismatch_seconds = stats.lane_mismatch_seconds + elapsed
	end
	-- In 5+ participant games an ordinary base spill deliberately recalls only
	-- the closest half. Diagnose a missed response only for bots the director
	-- actually selected; otherwise healthy lane holders become false positives.
	if record.base_response_required == true
		and record.base_response_selected == true and alive
		and goal ~= "defend_base" and not inEncounter then
		stats.base_response_ignored_seconds =
			stats.base_response_ignored_seconds + elapsed
	end
	if goal == "regroup" and alive and not inEncounter
		and record.base_response_required ~= true
		and (tonumber(record.combat_threat) or 0) < 0.55
		and (tonumber(record.recent_damage_ratio) or 0) < 0.08 then
		stats.unnecessary_regroup_seconds =
			stats.unnecessary_regroup_seconds + elapsed
	end

	local fields = self:BuildSnapshotFields(
		playerID,
		record,
		hero,
		assignment,
		stats
	)
	-- Decisions, purchases, deaths, arena preparation and inventory changes
	-- already have dedicated events and the full snapshot remains available in
	-- the 10-second heartbeat. Only macro ownership belongs in the transition
	-- signature; volatile tactical fields previously emitted multi-kilobyte
	-- snapshots several times per second.
	local signature = table.concat({
		tostring(fields.alive),
		tostring(fields.state),
		tostring(fields.macro),
		tostring(fields.goal),
		tostring(fields.lane),
		tostring(fields.participant_pid),
		tostring(fields.shopping_item),
		tostring(fields.shopping_shop),
		tostring(fields.emergency_hp),
		tostring(fields.life_insurance),
		tostring(fields.base_response),
		tostring(fields.base_selected),
		tostring(fields.encounter),
		tostring(fields.rune),
	}, ":")
	if signature ~= stats.last_snapshot_signature then
		stats.last_snapshot_signature = signature
		stats.next_heartbeat_at = now + self.heartbeat_interval
		self:Record("state_transition", playerID, signature, fields, false)
	elseif now >= (tonumber(stats.next_heartbeat_at) or 0) then
		stats.next_heartbeat_at = now + self.heartbeat_interval
		self:Record(
			"heartbeat",
			playerID,
			signature .. ":" .. tostring(math.floor(now / self.heartbeat_interval)),
			fields,
			false
		)
	end
end

function XHSBotDecisionAudit:SampleAll(force)
	if self.active ~= true then return false end
	local now = AuditNow()
	if force ~= true and now < (tonumber(self.next_sample_at) or 0) then
		return false
	end
	self.next_sample_at = now + self.sample_interval
	self.last_sample_at = now
	self:SampleGlobal()
	if XHSBotPlayerRegistry == nil then return true end
	for _, playerID in ipairs(XHSBotPlayerRegistry:GetXHSBotPlayerIDs()) do
		local record = XHSBotPlayerRegistry:GetBot(playerID)
		local hero = XHSBotPlayerRegistry:GetBotHero(playerID)
		local assignment = XHSBotTeamDirector ~= nil
			and XHSBotTeamDirector:GetAssignment(playerID) or nil
		self:SampleBot(playerID, record, hero, assignment, now)
	end
	return true
end

function XHSBotDecisionAudit:GetOrderedEvents()
	local result = {}
	if self.event_count <= 0 then return result end
	local start = self.event_count < self.max_events
		and 1 or self.event_write_index
	for offset = 0, self.event_count - 1 do
		local slot = ((start + offset - 1) % self.max_events) + 1
		local event = self.event_slots[slot]
		if event ~= nil then table.insert(result, event) end
	end
	table.sort(result, function(first, second)
		return (tonumber(first.seq) or 0) < (tonumber(second.seq) or 0)
	end)
	return result
end

local function CopyAuditFields(fields)
	local copy = {}
	for key, value in pairs(fields or {}) do
		local valueType = type(value)
		if valueType == "string" or valueType == "number" or valueType == "boolean" then
			copy[tostring(key)] = value
		elseif value == nil then
			copy[tostring(key)] = "none"
		else
			copy[tostring(key)] = tostring(value)
		end
	end
	return copy
end

function XHSBotDecisionAudit:BuildBackendPayload(reason)
	if self.event_count <= 0 and #(self.backend_events or {}) <= 0 then
		return nil
	end
	if self.active == true then self:SampleAll(true) end

	local events = {}
	for _, event in ipairs(self.backend_events or {}) do
		table.insert(events, {
			seq = tonumber(event.seq) or 0,
			t = tonumber(event.t) or 0,
			last_t = tonumber(event.last_t) or tonumber(event.t) or 0,
			repeats = tonumber(event.repeats) or 1,
			player_id = tonumber(event.player_id) or -1,
			kind = tostring(event.kind or "unknown"),
			fields = CopyAuditFields(event.fields),
		})
	end

	local bots = {}
	for playerID, stats in pairs(self.bot_stats or {}) do
		local record = stats.final_record or {}
		table.insert(bots, {
			player_id = tonumber(playerID) or -1,
			hero = tostring(stats.hero or ""),
			deaths = tonumber(stats.deaths) or 0,
			respawns = tonumber(stats.respawns) or 0,
			decisions_planned = tonumber(stats.decisions_planned) or 0,
			decisions_executed = tonumber(stats.decisions_executed) or 0,
			decisions_rejected = tonumber(stats.decisions_rejected) or 0,
			purchase_attempts = tonumber(stats.purchase_attempts) or 0,
			purchases = tonumber(stats.purchases) or 0,
			purchase_failures = tonumber(stats.purchase_failures) or 0,
			orb_purchases = tonumber(stats.orb_purchases) or 0,
			arena_preparation_tomes = tonumber(stats.arena_preparation_tomes) or 0,
			arena_downtime_shop_assignments = tonumber(stats.arena_downtime_shop_assignments) or 0,
			first_orb_at = tonumber(stats.first_orb_at) or -1,
			max_gold_without_orb = tonumber(stats.max_gold_without_orb) or 0,
			orb_affordable_seconds = tonumber(stats.orb_affordable_seconds) or 0,
			shopping_seconds = tonumber(stats.shopping_seconds) or 0,
			retreat_seconds = tonumber(stats.retreat_seconds) or 0,
			retreat_stationary_seconds = tonumber(stats.retreat_stationary_seconds) or 0,
			missing_hero_seconds = tonumber(stats.missing_hero_seconds) or 0,
			phase1_off_lane_seconds = tonumber(stats.phase1_off_lane_seconds) or 0,
			lane_mismatch_seconds = tonumber(stats.lane_mismatch_seconds) or 0,
			base_response_ignored_seconds = tonumber(stats.base_response_ignored_seconds) or 0,
			unnecessary_regroup_seconds = tonumber(stats.unnecessary_regroup_seconds) or 0,
			final_gold = SafeGold(playerID),
			final_state = tostring(record.state or ""),
			final_goal = tostring(record.goal or ""),
			final_item = tostring(record.planned_item or ""),
			initial_lane = tonumber(stats.initial_lane) or 0,
			final_ankh = tonumber(stats.last_ankh_charges) or 0,
			issues = self:BuildIssues(stats, record),
		})
	end
	table.sort(bots, function(first, second)
		return (first.player_id or -1) < (second.player_id or -1)
	end)

	local progress = {}
	for name, state in pairs(self.event_progress or {}) do
		progress[tostring(name)] = CopyAuditFields(state)
	end
	local endedAt = self.stopped_at > 0 and self.stopped_at or AuditNow()
	return {
		schema = tonumber(self.schema) or 3,
		session = tostring(self.console_session_id or ""),
		reason = tostring(reason or "backend"),
		-- Live checkpoints and the terminal audit share the same session key on
		-- the backend. This flag lets the admin UI distinguish a recoverable
		-- in-progress snapshot from the immutable end-of-match dump.
		finalized = self.finalized == true,
		start_reason = tostring(self.start_reason or ""),
		started_at = tonumber(self.started_at) or 0,
		ended_at = endedAt,
		duration = math.max(0, endedAt - (tonumber(self.started_at) or endedAt)),
		max_phase = tonumber(self.max_phase) or 0,
		event_count = #events,
		dropped_events = tonumber(self.dropped_events) or 0,
		console_flushed_events = tonumber(self.console_flushed_events) or 0,
		campaign_stage = tostring(
			XHSBotCampaignDirector ~= nil and XHSBotCampaignDirector.stage or ""
		),
		event_progress = progress,
		bots = bots,
		events = events,
	}
end

function XHSBotDecisionAudit:RebuildEventBuffer(events)
	self.event_slots = {}
	self.event_count = 0
	self.event_write_index = 1
	self.last_events = {}
	for _, event in ipairs(events or {}) do
		local slot = self.event_write_index
		self.event_slots[slot] = event
		self.event_count = self.event_count + 1
		self.event_write_index = (slot % self.max_events) + 1
		local lastKey = tostring(event.player_id or -1)
			.. ":" .. tostring(event.kind or "unknown")
		self.last_events[lastKey] = event
	end
end

function XHSBotDecisionAudit:PrintNextConsoleChunkBatch(generation)
	if generation ~= self.console_printer_generation then return nil end
	local chunk = self.console_chunks and self.console_chunks[1] or nil
	if chunk == nil then
		self.console_chunk_printing = false
		return nil
	end
	if chunk.started ~= true then
		chunk.started = true
		EmitAuditLine(
			"[XHSBots][AUDIT] type=chunk_begin"
				.. " schema=" .. tostring(self.schema)
				.. " session=" .. AuditValue(self.console_session_id, 32)
				.. " chunk=" .. tostring(chunk.id)
				.. " seq_first=" .. tostring(chunk.seq_first)
				.. " seq_last=" .. tostring(chunk.seq_last)
				.. " count=" .. tostring(#chunk.events)
		)
	end

	local batchSize = math.max(1, tonumber(self.console_chunk_batch_size) or 8)
	local lastIndex = math.min(#chunk.events, chunk.next_index + batchSize - 1)
	for index = chunk.next_index, lastIndex do
		EmitAuditLine(FormatEventLine(chunk.events[index]))
	end
	chunk.next_index = lastIndex + 1
	if chunk.next_index > #chunk.events then
		EmitAuditLine(
			"[XHSBots][AUDIT] type=chunk_end"
				.. " session=" .. AuditValue(self.console_session_id, 32)
				.. " chunk=" .. tostring(chunk.id)
				.. " seq_first=" .. tostring(chunk.seq_first)
				.. " seq_last=" .. tostring(chunk.seq_last)
				.. " count=" .. tostring(#chunk.events)
		)
		table.remove(self.console_chunks, 1)
		if self.console_chunks[1] == nil then
			self.console_chunk_printing = false
		end
	end
	return self.console_chunks[1] ~= nil
		and math.max(0.01, tonumber(self.console_chunk_batch_interval) or 0.05)
		or nil
end

function XHSBotDecisionAudit:StartConsoleChunkPrinter()
	if self.console_chunk_printing == true then return end
	if self.console_chunks == nil or self.console_chunks[1] == nil then return end
	self.console_chunk_printing = true
	local generation = self.console_printer_generation
	local function PrintBatch()
		return self:PrintNextConsoleChunkBatch(generation)
	end
	if Timers ~= nil and type(Timers.CreateTimer) == "function" then
		local ok = pcall(function() Timers:CreateTimer(0, PrintBatch) end)
		if ok then return end
	end
	while self:PrintNextConsoleChunkBatch(generation) ~= nil do end
end

function XHSBotDecisionAudit:MaybeQueueConsoleChunk()
	if self.console_output_enabled ~= true then return false end
	local chunkSize = math.max(
		1,
		math.min(
			self.max_events,
			math.floor(tonumber(self.console_chunk_size) or 1000)
		)
	)
	if self.event_count < chunkSize then return false end
	local ordered = self:GetOrderedEvents()
	local chunkEvents = {}
	local remaining = {}
	for index, event in ipairs(ordered) do
		if index <= chunkSize then
			table.insert(chunkEvents, event)
		else
			table.insert(remaining, event)
		end
	end
	if #chunkEvents <= 0 then return false end

	self.console_chunk_count = (tonumber(self.console_chunk_count) or 0) + 1
	self.console_flushed_events =
		(tonumber(self.console_flushed_events) or 0) + #chunkEvents
	table.insert(self.console_chunks, {
		id = self.console_chunk_count,
		events = chunkEvents,
		next_index = 1,
		started = false,
		seq_first = tonumber(chunkEvents[1].seq) or 0,
		seq_last = tonumber(chunkEvents[#chunkEvents].seq) or 0,
	})
	self:RebuildEventBuffer(remaining)
	self:StartConsoleChunkPrinter()
	return true
end

function XHSBotDecisionAudit:EventStatus(name)
	local progress = self.event_progress[tostring(name)] or {}
	return tostring(progress.status or "not_started")
end

function XHSBotDecisionAudit:BuildIssues(stats, record)
	local issues = {}
	local function Add(issue)
		for _, existing in ipairs(issues) do
			if existing == issue then return end
		end
		table.insert(issues, issue)
	end
	record = record or {}
	if (stats.max_gold_without_orb or 0) >= self.orb_affordable_gold
		and (stats.orb_purchases or 0) <= 0 then
		Add("affordable_orb_never_bought")
	end
	if (stats.deaths or 0) >= 3 and (stats.orb_purchases or 0) <= 0 then
		Add("death_loop_without_orb")
	end
	if (stats.orb_affordable_seconds or 0) >= 15
		and (stats.orb_purchases or 0) <= 0 then
		Add("held_orb_budget_without_purchase")
	end
	if (stats.max_gold_without_orb or 0) >= self.orb_affordable_gold
		and (stats.shopping_seconds or 0) < 2 then
		Add("economy_never_requested_shop")
	end
	if (stats.shopping_seconds or 0) >= 12
		and (stats.purchases or 0) <= 0 then
		Add("shopping_without_purchase")
	end
	if (stats.deaths or 0) >= 3 and (stats.retreat_seconds or 0) < 3 then
		Add("repeated_deaths_without_retreat")
	end
	if (stats.retreat_stationary_seconds or 0) >= 5 then
		Add("retreat_not_moving")
	end
	if (stats.phase1_off_lane_seconds or 0) >= 10 then
		Add("phase1_lane_abandoned")
	end
	if (stats.lane_mismatch_seconds or 0) >= 5 then
		Add("assigned_lane_changed")
	end
	if (stats.base_response_ignored_seconds or 0) >= 3 then
		Add("base_response_not_assigned")
	end
	if (stats.unnecessary_regroup_seconds or 0) >= 10 then
		Add("low_threat_regroup")
	end
	if stats.seen_valid_hero == true
		and (stats.missing_hero_seconds or 0) >= 2 then
		Add("registered_bot_missing_hero")
		if (stats.last_ankh_charges or 0) <= 0 then
			Add("permanent_elimination_without_ankh")
		end
	end
	if (stats.decisions_executed or 0) <= 0 and (stats.deaths or 0) > 0 then
		Add("no_executed_decisions")
	end
	if (tonumber(record.safe_error_count) or 0) > 0 then
		Add("safe_runtime_errors")
	end
	if #issues == 0 then table.insert(issues, "none_detected") end
	return table.concat(issues, ",")
end

function XHSBotDecisionAudit:PrintSummary(reason)
	local now = AuditNow()
	EmitAuditLine(
		"[XHSBots][AUDIT] type=begin"
			.. " schema=" .. tostring(self.schema)
			.. " reason=" .. AuditValue(reason, 64)
			.. " started_at=" .. string.format("%.1f", self.started_at or 0)
			.. " ended_at=" .. string.format("%.1f", now)
			.. " duration=" .. string.format("%.1f", math.max(0, now - (self.started_at or now)))
			.. " events=" .. tostring(self.event_count or 0)
			.. " flushed=" .. tostring(self.console_flushed_events or 0)
			.. " chunks=" .. tostring(self.console_chunk_count or 0)
			.. " dropped=" .. tostring(self.dropped_events or 0)
			.. " max_phase=" .. tostring(self.max_phase or 0)
			.. " muradin=" .. AuditValue(self:EventStatus("muradin"), 24)
			.. " ramero_baristol=" .. AuditValue(self:EventStatus("ramero_baristol"), 24)
			.. " sogat=" .. AuditValue(self:EventStatus("sogat"), 24)
			.. " farm=" .. AuditValue(self:EventStatus("farm"), 24)
	)
end

function XHSBotDecisionAudit:Dump(reason)
	local backendEventCount = #(self.backend_events or {})
	if backendEventCount <= 0 and self.active ~= true and self.finalized ~= true then
		return false, "audit_not_started", "events=0"
	end
	if self.active == true then self:SampleAll(true) end
	self.dump_count = (tonumber(self.dump_count) or 0) + 1
	local botCount = 0
	for _ in pairs(self.bot_stats or {}) do
		botCount = botCount + 1
	end
	return true, "audit_snapshot_ready",
		"events=" .. tostring(#(self.backend_events or {}))
			.. " bots=" .. tostring(botCount)
			.. " dropped=" .. tostring(self.dropped_events or 0)
			.. " storage=backend"
end

function XHSBotDecisionAudit:Finalize(reason)
	if self.auto_dumped == true then return false, "audit_already_finalized" end
	if self.active == true then self:SampleAll(true) end
	self.active = false
	self.finalized = true
	self.stopped_at = AuditNow()
	self.auto_dumped = true
	return self:Dump(reason or "post_game")
end

function XHSBotDecisionAudit:Stop(reason, dump)
	if self.active ~= true then return false, "audit_not_active" end
	self:SampleAll(true)
	self.active = false
	self.stopped_at = AuditNow()
	if dump == true then return self:Dump(reason or "manual_stop") end
	return true, "audit_stopped",
		"events=" .. tostring(self.event_count or 0)
end

function XHSBotDecisionAudit:Status()
	local message = self.active == true and "audit_recording"
		or self.finalized == true and "audit_finalized"
		or "audit_idle"
	local fields = "active=" .. tostring(BooleanNumber(self.active == true))
			.. " finalized=" .. tostring(BooleanNumber(self.finalized == true))
			.. " events=" .. tostring(self.event_count or 0)
			.. " dropped=" .. tostring(self.dropped_events or 0)
			.. " started_at=" .. string.format("%.1f", self.started_at or 0)
			.. " max_phase=" .. tostring(self.max_phase or 0)
	return true, message, fields
end

if XHSBotDecisionAudit.event_slots == nil then
	XHSBotDecisionAudit:Reset()
end

return XHSBotDecisionAudit
