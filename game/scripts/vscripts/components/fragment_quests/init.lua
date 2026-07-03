if FragmentQuests == nil then
	_G.FragmentQuests = class({})
end

local NET_TABLE = "fragment_quests"
local NET_STATE_KEY = "state"
local VERSION = 1
local BALANCE_VERSION = "fragment_quests_v1_2026_06_27"
local DEFAULT_REWARD_PER_STAR = 5
local FRONTLINE_PACT_THRESHOLDS = { 500000, 1000000, 2000000 }

local QUEST_CATEGORIES = {
	"general_fun",
	"event",
	"boss_or_phase",
}

local BOSS_UNIT_TO_ID = {
	npc_dota_hero_grom_hellscream = "grom",
	npc_dota_hero_illidan = "illidan",
	npc_dota_boss_lich_king = "lich_king",
	npc_dota_boss_spirit_master = "spirit_master",
}

local TARGET_LABELS = {
	ramero_baristol = "Ramero & Baristol",
	sogat = "Sogat",
	grom = "Grom",
	illidan = "Illidan",
	lich_king = "Lich King",
	spirit_master = "Spirit Master",
	hero_image = "Hero Image",
	all_hero_images = "All Hero Images",
	spirit_beast = "Spirit Beast",
	frost_infernal = "Frost Infernal",
}

local OPTIONAL_EVENT_TEMPLATE_IDS = {
	hero_image = "hero_image_win",
	all_hero_images = "all_hero_images_win",
	spirit_beast = "spirit_beast_win",
	frost_infernal = "frost_infernal_win",
}

local function Now()
	if GameRules ~= nil and GameRules.GetDOTATime ~= nil then
		return math.max(0, GameRules:GetDOTATime(false, false))
	end
	return 0
end

local function SafeFloor(value)
	value = tonumber(value) or 0
	return math.floor(value + 0.0001)
end

local function FormatTime(seconds)
	seconds = math.max(0, SafeFloor(seconds))
	local minutes = math.floor(seconds / 60)
	local remainder = seconds % 60
	return string.format("%d:%02d", minutes, remainder)
end

local function FormatCompactNumber(value)
	value = tonumber(value) or 0
	local abs = math.abs(value)
	if abs >= 1000000 then
		local text = string.format("%.1fM", value / 1000000)
		text = text:gsub("%.0M", "M")
		return text
	elseif abs >= 1000 then
		return string.format("%.0fk", value / 1000)
	end
	return tostring(SafeFloor(value))
end

local function ShallowCopyTable(source)
	local result = {}
	for key, value in pairs(source or {}) do
		result[key] = value
	end
	return result
end

local function IsValidUnit(unit)
	return unit ~= nil and IsValidEntity(unit) and not unit:IsNull()
end

local function IsGoodTeam(team)
	return team == DOTA_TEAM_GOODGUYS or team == 2
end

local function IsGoodUnit(unit)
	return IsValidUnit(unit) and IsGoodTeam(unit:GetTeamNumber())
end

local function GetPlayerIDFromUnit(unit)
	if not IsValidUnit(unit) then return nil end

	if XHSGetPlayerIDFromUnit ~= nil then
		local playerID = XHSGetPlayerIDFromUnit(unit)
		if playerID ~= nil and PlayerResource:IsValidPlayerID(playerID) then
			return playerID
		end
	end

	if unit.GetPlayerID ~= nil then
		local playerID = unit:GetPlayerID()
		if playerID ~= nil and PlayerResource:IsValidPlayerID(playerID) then
			return playerID
		end
	end

	if unit.GetPlayerOwnerID ~= nil then
		local playerID = unit:GetPlayerOwnerID()
		if playerID ~= nil and PlayerResource:IsValidPlayerID(playerID) then
			return playerID
		end
	end

	if unit.GetOwner ~= nil then
		local owner = unit:GetOwner()
		if IsValidUnit(owner) and owner.GetPlayerID ~= nil then
			local playerID = owner:GetPlayerID()
			if playerID ~= nil and PlayerResource:IsValidPlayerID(playerID) then
				return playerID
			end
		end
	end

	return nil
end

local function IsTower(unit)
	if not IsValidUnit(unit) then return false end
	if unit.IsTower ~= nil and unit:IsTower() then return true end

	if unit.GetUnitName ~= nil then
		local name = tostring(unit:GetUnitName() or "")
		return string.find(name, "tower") ~= nil
	end

	return false
end

local function IsFarmEventCreep(unit)
	if not IsValidUnit(unit) or unit.GetUnitName == nil then return false end
	local unitName = unit:GetUnitName()

	if FarmEvent_Creeps ~= nil then
		for _, creepName in pairs(FarmEvent_Creeps) do
			if unitName == creepName then
				return true
			end
		end
	end

	return false
end

local function GetBossID(unit)
	if not IsValidUnit(unit) or unit.GetUnitName == nil then return nil end
	return BOSS_UNIT_TO_ID[unit:GetUnitName()]
end

function FragmentQuests:GetTemplates()
	if self.templates ~= nil then
		return self.templates
	end

	self.templates = {
		{
			template_id = "team_healing",
			category = "general_fun",
			score_mode = "higher_is_better",
			thresholds = { 250000, 500000, 1000000 },
			title = "War Healers",
			description = "Reach team healing milestones.",
			metric = "team_healing",
			starts_active = true,
		},
		{
			template_id = "team_damage",
			category = "general_fun",
			score_mode = "higher_is_better",
			thresholds = { 5000000, 10000000, 20000000 },
			title = "Coordinated Carnage",
			description = "Reach team damage milestones.",
			metric = "team_damage",
			starts_active = true,
		},
		{
			template_id = "potion_discipline",
			category = "general_fun",
			score_mode = "lower_is_better",
			thresholds = { 40, 25, 15 },
			title = "Potion Discipline",
			description = "Keep total team potion usage low.",
			metric = "team_potions",
			starts_active = true,
		},
		{
			template_id = "potion_panic",
			category = "general_fun",
			score_mode = "higher_is_better",
			thresholds = { 10, 20, 30 },
			title = "Potion Panic",
			description = "Use potions during one boss fight or special wave.",
			metric = "potion_panic_max",
			starts_active = true,
			conflicts = { potion_discipline = true },
		},
		{
			template_id = "orb_diversity",
			category = "general_fun",
			score_mode = "higher_is_better",
			thresholds = { 3, 5, 7 },
			title = "Orbs of War",
			description = "Equip different orb types across the team.",
			metric = "orb_diversity",
			starts_active = true,
		},
		{
			template_id = "frontline_pact",
			category = "general_fun",
			score_mode = "higher_is_better",
			thresholds = FRONTLINE_PACT_THRESHOLDS,
			title = "Frontline Pact",
			description = "Absorb incoming damage as a team.",
			metric = "frontline_damage",
			starts_active = true,
		},
		{
			template_id = "tower_kill_control",
			category = "general_fun",
			score_mode = "lower_is_better",
			thresholds = { 10, 5, 0 },
			title = "No Lane Falls",
			description = "Limit enemy creeps finished by allied towers.",
			metric = "tower_kills",
			starts_active = true,
		},
		{
			template_id = "final_stand",
			category = "general_fun",
			score_mode = "hp_percent",
			thresholds = { 40, 70, 100 },
			title = "Final Stand",
			description = "Finish with high base HP.",
			metric = "base_hp_percent",
			starts_active = true,
		},
		{
			template_id = "farm_event_kills",
			category = "event",
			score_mode = "higher_is_better",
			thresholds = { 120, 180, 240 },
			title = "Farm Event Mastery",
			description = "Kill creeps during the Farm Event.",
			metric = "farm_event_kills",
		},
		{
			template_id = "muradin_death_cap",
			category = "event",
			score_mode = "lower_is_better",
			thresholds = { 4, 2, 0 },
			title = "Muradin Survivors",
			description = "Survive Muradin with few deaths. Ankh deaths count.",
			metric = "muradin_deaths",
		},
		{
			template_id = "arena_remaining_time",
			target_id = "ramero_baristol",
			category = "event",
			score_mode = "time_remaining",
			thresholds = { 10, 30, 60 },
			title = "Ramero & Baristol",
			description = "Win the arena with time remaining.",
			metric = "arena_remaining_time",
		},
		{
			template_id = "arena_remaining_time",
			target_id = "sogat",
			category = "event",
			score_mode = "time_remaining",
			thresholds = { 10, 25, 45 },
			title = "Sogat Slayer",
			description = "Kill Sogat with time remaining.",
			metric = "arena_remaining_time",
		},
		{
			template_id = "hero_image_win",
			target_id = "hero_image",
			category = "event",
			score_mode = "time_remaining",
			thresholds = { 10, 30, 60 },
			title = "Hero Image",
			description = "Defeat your Hero Image with time remaining.",
			metric = "optional_event_remaining_time",
		},
		{
			template_id = "all_hero_images_win",
			target_id = "all_hero_images",
			category = "event",
			score_mode = "time_remaining",
			thresholds = { 10, 30, 60 },
			title = "All Hero Images",
			description = "Clear All Hero Images with time remaining.",
			metric = "optional_event_remaining_time",
		},
		{
			template_id = "spirit_beast_win",
			target_id = "spirit_beast",
			category = "event",
			score_mode = "time_remaining",
			thresholds = { 10, 30, 60 },
			title = "Spirit Beast",
			description = "Kill Spirit Beast with time remaining.",
			metric = "optional_event_remaining_time",
		},
		{
			template_id = "frost_infernal_win",
			target_id = "frost_infernal",
			category = "event",
			score_mode = "time_remaining",
			thresholds = { 10, 30, 60 },
			title = "Frost Infernal",
			description = "Kill Frost Infernal with time remaining.",
			metric = "optional_event_remaining_time",
		},
		{
			template_id = "phase2_assault_timer",
			category = "boss_or_phase",
			score_mode = "time_elapsed",
			thresholds = { 300, 240, 180 },
			title = "Clean Assault",
			description = "Kill all Destroyer Magnataurs quickly after phase 2 starts.",
			metric = "phase2_elapsed",
		},
		{
			template_id = "boss_death_cap",
			target_id = "grom",
			category = "boss_or_phase",
			score_mode = "lower_is_better",
			thresholds = { 4, 2, 0 },
			title = "Grom Executed",
			description = "Kill Grom with few deaths. Ankh deaths count.",
			metric = "boss_deaths",
		},
		{
			template_id = "boss_timer",
			target_id = "illidan",
			category = "boss_or_phase",
			score_mode = "time_elapsed",
			thresholds = { 240, 180, 120 },
			title = "Illidan Hunter",
			description = "Kill Illidan before the fight drags on.",
			metric = "boss_elapsed",
		},
		{
			template_id = "boss_timer",
			target_id = "lich_king",
			category = "boss_or_phase",
			score_mode = "time_elapsed",
			thresholds = { 420, 330, 270 },
			title = "Lich King's End",
			description = "Kill the Lich King quickly.",
			metric = "boss_elapsed",
		},
		{
			template_id = "boss_timer",
			target_id = "spirit_master",
			category = "boss_or_phase",
			score_mode = "time_elapsed",
			thresholds = { 600, 480, 360 },
			title = "Spirit Master",
			description = "Defeat Spirit Master before the final fight drags on.",
			metric = "boss_elapsed",
		},
	}

	for _, template in ipairs(self.templates) do
		template.reward_per_star = template.reward_per_star or DEFAULT_REWARD_PER_STAR
	end

	return self.templates
end

function FragmentQuests:Init()
	if self.initialized == true then
		self:PublishState("init_repeat", true)
		return
	end

	self.initialized = true
	self.seed_source = self:GetSeedSource()
	self.seed = self:HashSeed(self.seed_source)
	self:ResetRuntime()
	self:SelectQuests()
	self:PublishState("init", true)
	print("[FragmentQuests] Init seed=" .. tostring(self.seed_source))
end

function FragmentQuests:ResetRuntime()
	self.selected = {}
	self.selected_template_ids = {}
	self.events = {}
	self.players = {}
	self.totals = {
		team_damage = 0,
		team_healing = 0,
		team_potions = 0,
		potion_panic_max = 0,
		potion_panic_current = 0,
		farm_event_kills = 0,
		muradin_deaths = 0,
		phase2_magnataur_kills = 0,
		frontline_damage = 0,
		tower_kills = 0,
		orb_diversity = 0,
		base_hp_percent = 0,
	}
	self.context = {
		farm_event_active = false,
		muradin_active = false,
		special_wave_active = false,
		panic_window_active = false,
		panic_window_reason = "",
		phase2_active = false,
		phase2_started_at = nil,
		arenas = {},
		optional_events = {},
		bosses = {},
	}
	self.last_publish_at = -100
	self.publish_pending = false
	self.last_orb_refresh_at = -100
	self.last_final_stand_refresh_at = -100
	self.last_hero_deaths = {}
	self.backend_status = "pending"
	self.backend_response = {}
	self.backend_fragment_quests_block = {}
	self.confirmed_fragment_quests = {}
	self.confirmed_quests_by_instance = {}
	self.confirmed_total_fragments = 0
	self.last_dev_payload_dump_summary = {}
	self.suppress_star_notifications = false
end

function FragmentQuests:GetSeedSource()
	if api ~= nil and api.GetApiGameId ~= nil then
		local gameID = api:GetApiGameId()
		if gameID ~= nil and tonumber(gameID) ~= 0 then
			return tostring(gameID)
		end
	end

	if api ~= nil and api.GetMatchID ~= nil then
		return tostring(api:GetMatchID())
	end

	if GameRules ~= nil and GameRules.Script_GetMatchID ~= nil then
		return tostring(GameRules:Script_GetMatchID())
	end

	return tostring(Now())
end

function FragmentQuests:GetGameIDForKeys()
	if api ~= nil and api.GetApiGameId ~= nil then
		local gameID = api:GetApiGameId()
		if gameID ~= nil and tonumber(gameID) ~= 0 then
			return tostring(gameID)
		end
	end

	if api ~= nil and api.GetMatchID ~= nil then
		return tostring(api:GetMatchID())
	end

	return tostring(self.seed_source or self.seed or 0)
end

function FragmentQuests:HashSeed(value)
	value = tostring(value or "")
	local hash = 0
	for i = 1, string.len(value) do
		hash = (hash * 131 + string.byte(value, i) + i) % 2147483647
	end
	if hash <= 0 then hash = 1 end
	return hash
end

function FragmentQuests:GetPool(category)
	local pool = {}
	for _, template in ipairs(self:GetTemplates()) do
		if template.category == category then
			table.insert(pool, template)
		end
	end
	return pool
end

function FragmentQuests:IsTemplateAllowed(template)
	if template == nil then return false end
	if self.selected_template_ids[template.template_id] == true then return false end

	if template.conflicts ~= nil then
		for templateID, active in pairs(template.conflicts) do
			if active == true and self.selected_template_ids[templateID] == true then
				return false
			end
		end
	end

	for _, selected in ipairs(self.selected or {}) do
		if selected.conflicts ~= nil and selected.conflicts[template.template_id] == true then
			return false
		end
	end

	return true
end

function FragmentQuests:SelectQuests()
	self.suppress_star_notifications = true
	self.selected = {}
	self.selected_template_ids = {}

	for slot, category in ipairs(QUEST_CATEGORIES) do
		local pool = self:GetPool(category)
		local selectedTemplate = nil

		if #pool > 0 then
			local startIndex = ((self.seed + slot * 7919) % #pool) + 1
			for offset = 0, #pool - 1 do
				local index = ((startIndex + offset - 1) % #pool) + 1
				local candidate = pool[index]
				if self:IsTemplateAllowed(candidate) then
					selectedTemplate = candidate
					break
				end
			end
		end

		if selectedTemplate ~= nil then
			self:AddSelectedQuest(selectedTemplate, slot)
		end
	end

	self:LogEvent("quests_selected", {
		count = #self.selected,
		seed = self.seed,
	})
	self:RecomputeAll()
	self.suppress_star_notifications = false
	self:PublishState("selected", true)
end

function FragmentQuests:AddSelectedQuest(template, slot)
	local quest = {}
	for key, value in pairs(template) do
		if type(value) == "table" then
			quest[key] = ShallowCopyTable(value)
		else
			quest[key] = value
		end
	end

	quest.slot = slot
	quest.target_id = quest.target_id or "team"
	quest.instance_id = tostring(slot) .. ":" .. quest.template_id .. ":" .. quest.target_id
	quest.current_value = 0
	quest.final_value = nil
	quest.stars = 0
	quest.fragments_awarded = 0
	quest.completed = false
	quest.started_at = quest.starts_active == true and Now() or nil
	quest.completed_at = nil
	quest.active = quest.starts_active == true

	table.insert(self.selected, quest)
	self.selected_template_ids[quest.template_id] = true
end

function FragmentQuests:FindTemplate(templateID, targetID)
	for _, template in ipairs(self:GetTemplates()) do
		if template.template_id == templateID and (targetID == nil or template.target_id == targetID or (template.target_id == nil and targetID == "team")) then
			return template
		end
	end
	return nil
end

function FragmentQuests:ForceQuest(templateID, targetID, slot)
	slot = tonumber(slot) or 1
	slot = math.max(1, math.min(3, slot))
	targetID = targetID or "team"

	local template = self:FindTemplate(templateID, targetID)
	if template == nil then
		return false, "Unknown fragment quest template"
	end

	local rebuilt = {}
	for _, quest in ipairs(self.selected or {}) do
		if quest.slot ~= slot then
			table.insert(rebuilt, quest)
		end
	end
	self.selected = rebuilt
	self.selected_template_ids = {}
	for _, quest in ipairs(self.selected) do
		self.selected_template_ids[quest.template_id] = true
	end

	self:AddSelectedQuest(template, slot)
	table.sort(self.selected, function(a, b) return (a.slot or 0) < (b.slot or 0) end)
	self.selected_template_ids = {}
	for _, quest in ipairs(self.selected) do
		self.selected_template_ids[quest.template_id] = true
	end

	self:LogEvent("dev_force_quest", {
		template_id = templateID,
		target_id = targetID,
		slot = slot,
	})
	self.suppress_star_notifications = true
	self:RecomputeAll()
	self.suppress_star_notifications = false
	self:PublishState("dev_force", true)
	return true, "Fragment quest forced"
end

function FragmentQuests:RecomputeAll()
	for _, quest in ipairs(self.selected or {}) do
		self:RecomputeQuest(quest)
	end
end

function FragmentQuests:RecomputeQuest(quest)
	if quest == nil then return end
	local previousStars = quest.stars or 0
	local value = quest.final_value
	if value == nil then
		value = self:GetCurrentValue(quest)
	end

	if value == nil then
		quest.current_value = 0
		quest.stars = 0
		quest.fragments_awarded = 0
		quest.completed = false
		return
	end

	quest.current_value = value
	quest.stars = self:CalculateStars(quest.score_mode, value, quest.thresholds)
	quest.fragments_awarded = quest.stars * (quest.reward_per_star or DEFAULT_REWARD_PER_STAR)
	quest.completed = quest.stars > 0

	if quest.started_at ~= nil and quest.stars > previousStars then
		self:LogEvent("quest_milestone", {
			instance_id = quest.instance_id,
			template_id = quest.template_id,
			target_id = quest.target_id,
			stars = quest.stars,
			value = value,
		})
		if self:ShouldSendStarNotification(quest) then
			self:SendStarNotification(quest, previousStars)
		end
	end
end

function FragmentQuests:ShouldSendStarNotification(quest)
	if self.suppress_star_notifications == true then return false end
	if quest == nil then return false end

	if quest.score_mode == "higher_is_better" then
		return true
	end

	return quest.final_value ~= nil
end

function FragmentQuests:SendStarNotification(quest, previousStars)
	if CustomGameEventManager == nil or quest == nil then return end

	CustomGameEventManager:Send_ServerToAllClients("xhs_fragment_quest_star", {
		instance_id = quest.instance_id,
		template_id = quest.template_id,
		target_id = quest.target_id,
		title = quest.title or quest.template_id or "Fragment Quest",
		description = quest.description or "",
		stars = quest.stars or 0,
		previous_stars = previousStars or 0,
		progress_text = self:BuildProgressText(quest),
		threshold_text = self:BuildThresholdText(quest),
		fragments_preview = quest.fragments_awarded or 0,
		reward_per_star = quest.reward_per_star or DEFAULT_REWARD_PER_STAR,
		duration = 6.0,
	})
end

function FragmentQuests:GetCurrentValue(quest)
	if quest.metric == "team_damage" then
		return self.totals.team_damage
	elseif quest.metric == "team_healing" then
		return self.totals.team_healing
	elseif quest.metric == "team_potions" then
		return self.totals.team_potions
	elseif quest.metric == "potion_panic_max" then
		return math.max(self.totals.potion_panic_max or 0, self.totals.potion_panic_current or 0)
	elseif quest.metric == "farm_event_kills" then
		if quest.started_at == nil then return nil end
		return self.totals.farm_event_kills
	elseif quest.metric == "muradin_deaths" then
		if quest.started_at == nil then return nil end
		return self.totals.muradin_deaths
	elseif quest.metric == "phase2_elapsed" then
		if self.context.phase2_started_at == nil then return nil end
		if quest.final_value ~= nil then return quest.final_value end
		return Now() - self.context.phase2_started_at
	elseif quest.metric == "arena_remaining_time" then
		if quest.started_at == nil then return nil end
		local arena = self.context.arenas[quest.target_id]
		if arena == nil then return 0 end
		return math.max(0, tonumber(arena.remaining_time) or 0)
	elseif quest.metric == "optional_event_remaining_time" then
		if quest.started_at == nil then return nil end
		local optionalEvent = self.context.optional_events[quest.target_id]
		if optionalEvent == nil then return 0 end
		return math.max(0, tonumber(optionalEvent.remaining_time) or 0)
	elseif quest.metric == "boss_deaths" then
		if quest.started_at == nil then return nil end
		local boss = self.context.bosses[quest.target_id]
		return boss and (boss.deaths or 0) or 0
	elseif quest.metric == "boss_elapsed" then
		local boss = self.context.bosses[quest.target_id]
		if boss == nil or boss.started_at == nil then return nil end
		return Now() - boss.started_at
	elseif quest.metric == "frontline_damage" then
		return self.totals.frontline_damage
	elseif quest.metric == "tower_kills" then
		return self.totals.tower_kills
	elseif quest.metric == "orb_diversity" then
		return self.totals.orb_diversity
	elseif quest.metric == "base_hp_percent" then
		return self.totals.base_hp_percent
	end

	return 0
end

function FragmentQuests:CalculateStars(scoreMode, value, thresholds)
	if value == nil then return 0 end
	local stars = 0

	for _, threshold in ipairs(thresholds or {}) do
		if scoreMode == "higher_is_better" or scoreMode == "time_remaining" or scoreMode == "hp_percent" then
			if value >= threshold then stars = stars + 1 end
		elseif scoreMode == "lower_is_better" or scoreMode == "time_elapsed" then
			if value <= threshold then stars = stars + 1 end
		end
	end

	return math.max(0, math.min(3, stars))
end

function FragmentQuests:MarkQuestStarted(templateID, targetID)
	for _, quest in ipairs(self.selected or {}) do
		if quest.template_id == templateID and (targetID == nil or quest.target_id == targetID) then
			if quest.started_at == nil then
				quest.started_at = Now()
			end
			quest.active = true
			self:RecomputeQuest(quest)
		end
	end
end

function FragmentQuests:SetQuestFinalValue(templateID, targetID, value)
	for _, quest in ipairs(self.selected or {}) do
		if quest.template_id == templateID and (targetID == nil or quest.target_id == targetID) then
			if quest.started_at == nil then
				quest.started_at = Now()
			end
			quest.final_value = value
			quest.completed_at = Now()
			quest.active = false
			self:RecomputeQuest(quest)
			self:LogEvent("quest_final_value", {
				instance_id = quest.instance_id,
				template_id = quest.template_id,
				target_id = quest.target_id,
				value = value,
				stars = quest.stars,
			})
		end
	end
	self:PublishState("quest_final", true)
end

function FragmentQuests:AddPlayerContribution(playerID, key, amount)
	if playerID == nil or not PlayerResource:IsValidPlayerID(playerID) then return end
	amount = tonumber(amount) or 0

	local id = tostring(playerID)
	self.players[id] = self.players[id] or {
		player_id = playerID,
		steam_id = tostring(PlayerResource:GetSteamID(playerID)),
		hero = "",
		damage = 0,
		healing = 0,
		potions = 0,
		deaths = 0,
		farm_event_kills = 0,
		frontline_damage = 0,
	}

	local hero = PlayerResource:GetSelectedHeroEntity(playerID)
	if IsValidUnit(hero) and hero.GetUnitName ~= nil then
		self.players[id].hero = hero:GetUnitName()
	end

	self.players[id][key] = (tonumber(self.players[id][key]) or 0) + amount
end

function FragmentQuests:LogEvent(eventType, data)
	self.events = self.events or {}
	table.insert(self.events, {
		t = Now(),
		type = eventType,
		data = data or {},
	})

	while #self.events > 300 do
		table.remove(self.events, 1)
	end
end

function FragmentQuests:RequestPublish(reason, force)
	local now = Now()
	if force == true or now - (self.last_publish_at or -100) >= 0.5 then
		self:PublishState(reason, true)
	else
		self.publish_pending = true
	end
end

function FragmentQuests:PublishState(reason, force)
	if CustomNetTables == nil then return end
	self.last_publish_at = Now()
	self.publish_pending = false
	CustomNetTables:SetTableValue(NET_TABLE, NET_STATE_KEY, self:BuildNetTableState(reason))
end

function FragmentQuests:Think()
	if self.initialized ~= true then return end

	local now = Now()
	local changed = false

	if now - (self.last_orb_refresh_at or -100) >= 2.0 then
		self.last_orb_refresh_at = now
		changed = self:RefreshOrbDiversity() or changed
	end

	if now - (self.last_final_stand_refresh_at or -100) >= 2.0 then
		self.last_final_stand_refresh_at = now
		changed = self:RefreshBaseHP() or changed
	end

	if self.publish_pending == true or changed == true then
		self:RequestPublish("think", changed)
	end
end

function FragmentQuests:OnDamage(filterTable)
	if self.initialized ~= true or filterTable == nil then return end

	local damage = tonumber(filterTable.damage) or 0
	if damage <= 0 then return end

	local attacker = nil
	local victim = nil
	if filterTable.entindex_attacker_const ~= nil then attacker = EntIndexToHScript(filterTable.entindex_attacker_const) end
	if filterTable.entindex_victim_const ~= nil then victim = EntIndexToHScript(filterTable.entindex_victim_const) end

	if IsValidUnit(victim) then
		local bossID = GetBossID(victim)
		if bossID ~= nil and IsGoodUnit(attacker) then
			self:OnBossFightStart(bossID)
		end
	end

	local attackerPlayerID = GetPlayerIDFromUnit(attacker)
	if attackerPlayerID ~= nil and IsGoodUnit(attacker) and IsValidUnit(victim) and not IsGoodTeam(victim:GetTeamNumber()) then
		self.totals.team_damage = self.totals.team_damage + damage
		self:AddPlayerContribution(attackerPlayerID, "damage", damage)
	end

	local victimPlayerID = GetPlayerIDFromUnit(victim)
	if victimPlayerID ~= nil and IsGoodUnit(victim) and IsValidUnit(attacker) and not IsGoodTeam(attacker:GetTeamNumber()) then
		self.totals.frontline_damage = self.totals.frontline_damage + damage
		self:AddPlayerContribution(victimPlayerID, "frontline_damage", damage)
	end

	self:RecomputeAll()
	self:RequestPublish("damage")
end

function FragmentQuests:AddHealing(playerID, amount)
	if self.initialized ~= true then return end
	amount = tonumber(amount) or 0
	if amount <= 0 then return end

	self.totals.team_healing = self.totals.team_healing + amount
	self:AddPlayerContribution(playerID, "healing", amount)
	self:RecomputeAll()
	self:RequestPublish("healing")
end

function FragmentQuests:OnPotionUsed(caster)
	if self.initialized ~= true then return end

	local playerID = GetPlayerIDFromUnit(caster)
	self.totals.team_potions = self.totals.team_potions + 1
	if playerID ~= nil then
		self:AddPlayerContribution(playerID, "potions", 1)
	end

	if self:IsPanicWindowActive() then
		self.totals.potion_panic_current = (self.totals.potion_panic_current or 0) + 1
		self.totals.potion_panic_max = math.max(self.totals.potion_panic_max or 0, self.totals.potion_panic_current)
	end

	self:LogEvent("potion_used", {
		player_id = playerID,
		panic_window = self.context.panic_window_reason or "",
	})
	self:RecomputeAll()
	self:RequestPublish("potion", true)
end

function FragmentQuests:IsPanicWindowActive()
	if self.context == nil then return false end
	if self.context.panic_window_active == true then return true end

	for _, boss in pairs(self.context.bosses or {}) do
		if boss.active == true then return true end
	end

	return false
end

function FragmentQuests:StartPanicWindow(reason)
	if self.context.panic_window_active == true then return end
	self.context.panic_window_active = true
	self.context.panic_window_reason = reason or ""
	self.totals.potion_panic_current = 0
	self:LogEvent("panic_window_start", { reason = reason or "" })
end

function FragmentQuests:EndPanicWindow(reason)
	if self.context.panic_window_active ~= true then return end
	self.totals.potion_panic_max = math.max(self.totals.potion_panic_max or 0, self.totals.potion_panic_current or 0)
	self.context.panic_window_active = false
	self.context.panic_window_reason = ""
	self.totals.potion_panic_current = 0
	self:LogEvent("panic_window_end", { reason = reason or "" })
end

function FragmentQuests:OnHeroDeath(hero, meta)
	if self.initialized ~= true or not IsValidUnit(hero) then return end
	if hero.IsRealHero == nil or not hero:IsRealHero() then return end
	if not IsGoodUnit(hero) then return end

	local now = Now()
	local key = tostring(hero:entindex())
	if self.last_hero_deaths[key] ~= nil and now - self.last_hero_deaths[key] < 0.35 then
		return
	end
	self.last_hero_deaths[key] = now

	local playerID = GetPlayerIDFromUnit(hero)
	if playerID ~= nil then
		self:AddPlayerContribution(playerID, "deaths", 1)
	end

	if self.context.muradin_active == true then
		self.totals.muradin_deaths = self.totals.muradin_deaths + 1
	end

	for bossID, boss in pairs(self.context.bosses or {}) do
		if boss.active == true then
			boss.deaths = (boss.deaths or 0) + 1
			if bossID == "grom" then
				self:MarkQuestStarted("boss_death_cap", bossID)
			end
		end
	end

	self:LogEvent("hero_death", {
		player_id = playerID,
		source = meta and meta.source or "entity_killed",
		muradin_active = self.context.muradin_active == true,
	})
	self:RecomputeAll()
	self:RequestPublish("hero_death", true)
end

function FragmentQuests:OnEntityKilled(killedUnit, killer)
	if self.initialized ~= true or not IsValidUnit(killedUnit) then return end

	local unitName = killedUnit.GetUnitName ~= nil and killedUnit:GetUnitName() or ""

	if self.context.farm_event_active == true and IsFarmEventCreep(killedUnit) then
		self.totals.farm_event_kills = self.totals.farm_event_kills + 1
		local playerID = GetPlayerIDFromUnit(killer)
		if playerID ~= nil then
			self:AddPlayerContribution(playerID, "farm_event_kills", 1)
		end
	end

	if unitName == "npc_magnataur_destroyer_crypt" then
		if self.context.phase2_started_at == nil then
			self:OnPhase2Start()
		end
		self.totals.phase2_magnataur_kills = (self.totals.phase2_magnataur_kills or 0) + 1
		if self.totals.phase2_magnataur_kills >= self:GetExpectedMagnataurKills() then
			self:OnPhase2End()
		end
	end

	if IsTower(killer) and IsGoodUnit(killer) and IsValidUnit(killedUnit) and not IsGoodTeam(killedUnit:GetTeamNumber()) then
		self.totals.tower_kills = self.totals.tower_kills + 1
	end

	local bossID = GetBossID(killedUnit)
	if bossID ~= nil then
		self:OnBossKilled(bossID)
	end

	self:RecomputeAll()
	self:RequestPublish("entity_killed")
end

function FragmentQuests:OnFarmEventStart(duration)
	if self.initialized ~= true then return end
	self.context.farm_event_active = true
	self.totals.farm_event_kills = 0
	self:MarkQuestStarted("farm_event_kills", "team")
	self:LogEvent("farm_event_start", { duration = tonumber(duration) or 0 })
	self:PublishState("farm_start", true)
end

function FragmentQuests:OnFarmEventEnd()
	if self.initialized ~= true then return end
	if self.context.farm_event_active ~= true then return end
	self.context.farm_event_active = false
	self:SetQuestFinalValue("farm_event_kills", "team", self.totals.farm_event_kills)
	self:LogEvent("farm_event_end", { kills = self.totals.farm_event_kills })
end

function FragmentQuests:OnMuradinStart(duration)
	if self.initialized ~= true then return end
	self.context.muradin_active = true
	self.totals.muradin_deaths = 0
	self:MarkQuestStarted("muradin_death_cap", "team")
	self:LogEvent("muradin_start", { duration = tonumber(duration) or 0 })
	self:PublishState("muradin_start", true)
end

function FragmentQuests:OnMuradinEnd()
	if self.initialized ~= true then return end
	if self.context.muradin_active ~= true then return end
	self.context.muradin_active = false
	self:SetQuestFinalValue("muradin_death_cap", "team", self.totals.muradin_deaths)
	self:LogEvent("muradin_end", { deaths = self.totals.muradin_deaths })
end

function FragmentQuests:OnArenaStart(arenaID, duration)
	if self.initialized ~= true or arenaID == nil then return end
	self.context.arenas[arenaID] = {
		active = true,
		started_at = Now(),
		duration = tonumber(duration) or 0,
		remaining_time = tonumber(duration) or 0,
	}
	self:MarkQuestStarted("arena_remaining_time", arenaID)
	self:StartPanicWindow("arena:" .. tostring(arenaID))
	self:LogEvent("arena_start", { arena_id = arenaID, duration = tonumber(duration) or 0 })
	self:PublishState("arena_start", true)
end

function FragmentQuests:OnArenaEnd(arenaID, won)
	if self.initialized ~= true or arenaID == nil then return end
	local arena = self.context.arenas[arenaID] or {}
	arena.active = false
	arena.remaining_time = self:GetSpecialArenaRemainingTime()
	self.context.arenas[arenaID] = arena

	local finalValue = won == true and arena.remaining_time or 0
	self:SetQuestFinalValue("arena_remaining_time", arenaID, finalValue)
	self:EndPanicWindow("arena:" .. tostring(arenaID))
	self:LogEvent("arena_end", {
		arena_id = arenaID,
		won = won == true,
		remaining_time = finalValue,
	})
end

function FragmentQuests:GetSpecialArenaRemainingTime()
	if CustomTimers ~= nil and CustomTimers.current_time ~= nil then
		return math.max(0, tonumber(CustomTimers.current_time["special_arena"]) or 0)
	end
	return 0
end

function FragmentQuests:GetOptionalEventTemplateID(eventID)
	return OPTIONAL_EVENT_TEMPLATE_IDS[tostring(eventID or "")]
end

function FragmentQuests:GetOptionalEventRemainingTime(eventID)
	eventID = tostring(eventID or "")
	if CustomTimers ~= nil and CustomTimers.current_time ~= nil then
		return math.max(0, tonumber(CustomTimers.current_time[eventID]) or 0)
	end
	local optionalEvent = self.context.optional_events[eventID]
	return math.max(0, tonumber(optionalEvent and optionalEvent.remaining_time) or 0)
end

function FragmentQuests:OnOptionalEventStart(eventID, duration)
	if self.initialized ~= true or eventID == nil then return end
	eventID = tostring(eventID)
	self.context.optional_events[eventID] = {
		active = true,
		started_at = Now(),
		duration = tonumber(duration) or 0,
		remaining_time = tonumber(duration) or 0,
	}
	self:MarkQuestStarted(self:GetOptionalEventTemplateID(eventID), eventID)
	self:StartPanicWindow("optional:" .. eventID)
	self:LogEvent("optional_event_start", { event_id = eventID, duration = tonumber(duration) or 0 })
	self:PublishState("optional_event_start", true)
end

function FragmentQuests:OnOptionalEventEnd(eventID, won)
	if self.initialized ~= true or eventID == nil then return end
	eventID = tostring(eventID)
	local optionalEvent = self.context.optional_events[eventID] or {}
	optionalEvent.active = false
	optionalEvent.remaining_time = self:GetOptionalEventRemainingTime(eventID)
	self.context.optional_events[eventID] = optionalEvent

	local finalValue = won == true and optionalEvent.remaining_time or 0
	self:SetQuestFinalValue(self:GetOptionalEventTemplateID(eventID), eventID, finalValue)
	self:EndPanicWindow("optional:" .. eventID)
	self:LogEvent("optional_event_end", {
		event_id = eventID,
		won = won == true,
		remaining_time = finalValue,
	})
end

function FragmentQuests:OnSpecialWaveStart(waveIndex, direction, total)
	if self.initialized ~= true then return end
	self.context.special_wave_active = true
	self:StartPanicWindow("special_wave")
	self:LogEvent("special_wave_start", {
		wave_index = waveIndex,
		direction = direction or "",
		total = total or 0,
	})
	self:PublishState("special_wave_start", true)
end

function FragmentQuests:OnSpecialWaveEnd(cleared)
	if self.initialized ~= true then return end
	self.context.special_wave_active = false
	self:EndPanicWindow("special_wave")
	self:LogEvent("special_wave_end", { cleared = cleared == true })
	self:RecomputeAll()
	self:PublishState("special_wave_end", true)
end

function FragmentQuests:OnPhase2Start()
	if self.initialized ~= true then return end
	if self.context.phase2_started_at ~= nil and self.context.phase2_active == true then return end
	self.context.phase2_active = true
	self.context.phase2_started_at = Now()
	self.totals.phase2_magnataur_kills = 0
	self:MarkQuestStarted("phase2_assault_timer", "team")
	self:LogEvent("phase2_start", { expected = self:GetExpectedMagnataurKills() })
	self:PublishState("phase2_start", true)
end

function FragmentQuests:OnPhase2End()
	if self.initialized ~= true then return end
	if self.context.phase2_started_at == nil then return end
	if self.context.phase2_active == false then return end

	self.context.phase2_active = false
	local elapsed = Now() - self.context.phase2_started_at
	self:SetQuestFinalValue("phase2_assault_timer", "team", elapsed)
	self:LogEvent("phase2_end", {
		elapsed = elapsed,
		kills = self.totals.phase2_magnataur_kills or 0,
	})
end

function FragmentQuests:GetExpectedMagnataurKills()
	local players = PlayerResource ~= nil and PlayerResource.GetPlayerCount ~= nil and PlayerResource:GetPlayerCount() or 1
	local lanes = CREEP_LANES_TYPE or 1
	local perLane = MAGNATAURS_TO_KILL or 1
	return math.max(1, perLane * players * lanes)
end

function FragmentQuests:OnBossSpawned(bossID)
	if self.initialized ~= true or bossID == nil then return end
	self.context.bosses[bossID] = self.context.bosses[bossID] or {
		active = false,
		deaths = 0,
	}
	self:LogEvent("boss_spawned", { boss_id = bossID })
end

function FragmentQuests:OnBossUnitSpawned(unit)
	local bossID = GetBossID(unit)
	if bossID ~= nil then
		self:OnBossSpawned(bossID)
	end
end

function FragmentQuests:OnBossFightStart(bossID)
	if self.initialized ~= true or bossID == nil then return end
	local boss = self.context.bosses[bossID] or {}
	if boss.started_at == nil then
		boss.started_at = Now()
		boss.deaths = boss.deaths or 0
		self:LogEvent("boss_fight_start", { boss_id = bossID })
	end
	boss.active = true
	self.context.bosses[bossID] = boss

	if bossID == "grom" then
		self:MarkQuestStarted("boss_death_cap", bossID)
	else
		self:MarkQuestStarted("boss_timer", bossID)
	end

	self:StartPanicWindow("boss:" .. tostring(bossID))
	self:RequestPublish("boss_start", true)
end

function FragmentQuests:OnBossKilled(bossID)
	if self.initialized ~= true or bossID == nil then return end
	local boss = self.context.bosses[bossID] or {}
	if boss.started_at == nil then
		boss.started_at = Now()
	end
	boss.active = false
	self.context.bosses[bossID] = boss

	if bossID == "grom" then
		self:SetQuestFinalValue("boss_death_cap", bossID, boss.deaths or 0)
	else
		self:SetQuestFinalValue("boss_timer", bossID, Now() - boss.started_at)
	end

	self:EndPanicWindow("boss:" .. tostring(bossID))
	self:LogEvent("boss_killed", {
		boss_id = bossID,
		elapsed = Now() - boss.started_at,
		deaths = boss.deaths or 0,
	})
end

function FragmentQuests:RefreshOrbDiversity()
	local orbTypes = {}

	if HeroList ~= nil and HeroList.GetAllHeroes ~= nil then
		for _, hero in pairs(HeroList:GetAllHeroes()) do
			if IsValidUnit(hero) and hero:IsRealHero() and IsGoodUnit(hero) then
				for slot = 0, 8 do
					local item = hero:GetItemInSlot(slot)
					if item ~= nil and not item:IsNull() then
						local orbType = self:GetOrbType(item:GetAbilityName())
						if orbType ~= nil then
							orbTypes[orbType] = true
						end
					end
				end
			end
		end
	end

	local count = 0
	for _ in pairs(orbTypes) do count = count + 1 end
	local changed = count ~= self.totals.orb_diversity
	self.totals.orb_diversity = count
	self.orb_types = orbTypes
	if changed then self:RecomputeAll() end
	return changed
end

function FragmentQuests:GetOrbType(itemName)
	itemName = string.lower(tostring(itemName or ""))
	if string.find(itemName, "recipe") ~= nil then return nil end

	if string.find(itemName, "orb_of_lightning") ~= nil then return "lightning" end
	if string.find(itemName, "orb_of_fire") ~= nil then return "fire" end
	if string.find(itemName, "orb_of_frost") ~= nil then return "frost" end
	if string.find(itemName, "orb_of_earth") ~= nil then return "earth" end
	if string.find(itemName, "orb_of_darkness") ~= nil then return "darkness" end
	if string.find(itemName, "orb_of_arcane") ~= nil then return "arcane" end
	if string.find(itemName, "orb_of_venom") ~= nil then return "venom" end

	return nil
end

function FragmentQuests:RefreshBaseHP()
	local hp = self:GetBaseHealthPercent()
	local changed = hp ~= self.totals.base_hp_percent
	self.totals.base_hp_percent = hp
	if changed then self:RecomputeAll() end
	return changed
end

function FragmentQuests:OnFinalWaveEnd()
	if self.initialized ~= true then return end
	self:RefreshBaseHP()
	self:SetQuestFinalValue("final_stand", "team", self.totals.base_hp_percent)
	self:LogEvent("final_wave_end", { base_hp_percent = self.totals.base_hp_percent })
end

function FragmentQuests:GetBaseHealthPercent()
	local candidates = {}
	if BASE_GOOD ~= nil then table.insert(candidates, BASE_GOOD) end

	local names = {
		"npc_dota_goodguys_fort",
		"dota_goodguys_fort",
		"good_fort",
		"base",
		"base_spawn",
	}

	for _, name in ipairs(names) do
		if Entities ~= nil and Entities.FindByName ~= nil then
			local entity = Entities:FindByName(nil, name)
			if entity ~= nil then table.insert(candidates, entity) end
		end
	end

	for _, entity in ipairs(candidates) do
		if IsValidUnit(entity) and entity.GetHealth ~= nil and entity.GetMaxHealth ~= nil then
			local maxHealth = tonumber(entity:GetMaxHealth()) or 0
			if maxHealth > 0 then
				return math.max(0, math.min(100, (entity:GetHealth() / maxHealth) * 100))
			end
		end
	end

	return 0
end

function FragmentQuests:FinalizeForPayload()
	self:RefreshOrbDiversity()
	self:RefreshBaseHP()

	if self.context.farm_event_active == true then
		self:OnFarmEventEnd()
	end
	if self.context.muradin_active == true then
		self:OnMuradinEnd()
	end
	if self.context.phase2_active == true then
		self:OnPhase2End()
	end

	for arenaID, arena in pairs(self.context.arenas or {}) do
		if arena.active == true then
			self:OnArenaEnd(arenaID, false)
		end
	end

	for bossID, boss in pairs(self.context.bosses or {}) do
		if boss.active == true then
			boss.active = false
			self.context.bosses[bossID] = boss
		end
	end

	for _, quest in ipairs(self.selected or {}) do
		if quest.final_value == nil and quest.starts_active == true then
			quest.final_value = self:GetCurrentValue(quest)
			quest.completed_at = Now()
			self:RecomputeQuest(quest)
		else
			self:RecomputeQuest(quest)
		end
	end

	self:PublishState("finalize", true)
end

function FragmentQuests:BuildThresholdTable(thresholds)
	local result = {}
	for i, value in ipairs(thresholds or {}) do
		result[tostring(i)] = value
	end
	return result
end

function FragmentQuests:BuildThresholdText(quest)
	local parts = {}
	for _, threshold in ipairs(quest.thresholds or {}) do
		if quest.score_mode == "time_elapsed" or quest.score_mode == "time_remaining" then
			table.insert(parts, FormatTime(threshold))
		elseif quest.score_mode == "hp_percent" then
			table.insert(parts, tostring(SafeFloor(threshold)) .. "%")
		else
			table.insert(parts, FormatCompactNumber(threshold))
		end
	end
	return table.concat(parts, " / ")
end

function FragmentQuests:BuildProgressText(quest)
	local value = quest.current_value or 0
	if quest.score_mode == "time_elapsed" or quest.score_mode == "time_remaining" then
		return FormatTime(value)
	elseif quest.score_mode == "hp_percent" then
		return tostring(SafeFloor(value)) .. "%"
	end
	return FormatCompactNumber(value)
end

function FragmentQuests:BuildQuestView(quest)
	local confirmedQuest = self:GetConfirmedQuest(quest.instance_id)
	local previewFragments = quest.fragments_awarded or 0
	local confirmedFragments = confirmedQuest ~= nil and (tonumber(confirmedQuest.fragments_awarded) or 0) or 0

	return {
		instance_id = quest.instance_id,
		template_id = quest.template_id,
		target_id = quest.target_id,
		category = quest.category,
		title = quest.title,
		description = quest.description,
		score_mode = quest.score_mode,
		thresholds = self:BuildThresholdTable(quest.thresholds),
		threshold_text = self:BuildThresholdText(quest),
		current_value = quest.current_value or 0,
		progress_text = self:BuildProgressText(quest),
		stars = quest.stars or 0,
		completed = quest.completed == true,
		started_at = quest.started_at or 0,
		completed_at = quest.completed_at or 0,
		reward_per_star = quest.reward_per_star or DEFAULT_REWARD_PER_STAR,
		preview_fragments = previewFragments,
		confirmed = confirmedQuest ~= nil,
		confirmed_fragments_awarded = confirmedFragments,
		fragments_awarded = confirmedQuest ~= nil and confirmedFragments or previewFragments,
		grant_status = confirmedQuest ~= nil and tostring(confirmedQuest.grant_status or "") or "",
		idempotency_key = confirmedQuest ~= nil and tostring(confirmedQuest.idempotency_key or "") or "",
		active = quest.active == true,
	}
end

function FragmentQuests:BuildNetTableState(reason)
	self:RecomputeAll()

	local selected = {}
	for index, quest in ipairs(self.selected or {}) do
		selected[tostring(index)] = self:BuildQuestView(quest)
	end

	return {
		version = VERSION,
		balance_version = BALANCE_VERSION,
		seed = self.seed or 0,
		seed_source = tostring(self.seed_source or ""),
		reason = reason or "",
		selected = selected,
		total_fragments_pending = self:GetTotalFragments(),
		total_fragments_preview = self:GetTotalFragments(),
		confirmed_total_fragments = self.confirmed_total_fragments or 0,
		confirmed_quests = self.confirmed_fragment_quests or {},
		backend_status = self.backend_status or "pending",
	}
end

function FragmentQuests:GetTotalFragments()
	local total = 0
	for _, quest in ipairs(self.selected or {}) do
		total = total + (quest.fragments_awarded or 0)
	end
	return total
end

function FragmentQuests:BuildSelectedPayload()
	local selected = {}
	local gameID = self:GetGameIDForKeys()

	for _, quest in ipairs(self.selected or {}) do
		table.insert(selected, {
			instance_id = quest.instance_id,
			template_id = quest.template_id,
			target_id = quest.target_id,
			category = quest.category,
			title = quest.title,
			description = quest.description,
			thresholds = ShallowCopyTable(quest.thresholds),
			score_mode = quest.score_mode,
			final_value = quest.final_value ~= nil and quest.final_value or quest.current_value or 0,
			stars = quest.stars or 0,
			completed = quest.completed == true,
			started_at = quest.started_at,
			completed_at = quest.completed_at,
			reward_per_star = quest.reward_per_star or DEFAULT_REWARD_PER_STAR,
			fragments_awarded = quest.fragments_awarded or 0,
			idempotency_key = "fragment-quest:" .. tostring(gameID) .. ":" .. tostring(quest.instance_id),
		})
	end

	return selected
end

function FragmentQuests:BuildPlayersPayload()
	local players = {}
	for _, contribution in pairs(self.players or {}) do
		table.insert(players, contribution)
	end
	return players
end

function FragmentQuests:BuildAnalyticsPayload()
	if self.initialized ~= true then
		return {
			version = VERSION,
			balance_version = BALANCE_VERSION,
			selected = {},
			events = {},
			players = {},
		}
	end

	self:FinalizeForPayload()

	return {
		version = VERSION,
		balance_version = BALANCE_VERSION,
		seed = self.seed or 0,
		seed_source = tostring(self.seed_source or ""),
		selected = self:BuildSelectedPayload(),
		events = self.events or {},
		players = self:BuildPlayersPayload(),
		total_fragments_pending = self:GetTotalFragments(),
		total_fragments_preview = self:GetTotalFragments(),
		backend_status = self.backend_status or "pending",
	}
end

function FragmentQuests:OnBackendComplete(success, data)
	self.backend_response = data or {}
	self.backend_fragment_quests_block = {}
	self.confirmed_fragment_quests = {}
	self.confirmed_quests_by_instance = {}
	self.confirmed_total_fragments = 0

	local block = success == true and self:GetBackendFragmentQuestBlock(data) or nil
	if success == true and self:IsConfirmedBackendBlock(block) then
		local confirmedQuests, byInstance = self:NormalizeConfirmedQuestList(block)
		self.backend_status = "synced"
		self.backend_fragment_quests_block = block
		self.confirmed_fragment_quests = confirmedQuests
		self.confirmed_quests_by_instance = byInstance
		self.confirmed_total_fragments = self:GetConfirmedTotalFragments(block, confirmedQuests)
	else
		self.backend_status = "error"
	end

	self:LogEvent("backend_complete", {
		success = success == true,
		status = self.backend_status,
		has_fragment_quests = block ~= nil,
		confirmed_total_fragments = self.confirmed_total_fragments or 0,
	})
	self:PublishState("backend_complete", true)
end

function FragmentQuests:GetBackendFragmentQuestBlock(data)
	if type(data) ~= "table" then return nil end
	if type(data.fragment_quests) == "table" then return data.fragment_quests end
	if type(data.data) == "table" and type(data.data.fragment_quests) == "table" then return data.data.fragment_quests end
	if type(data.payload) == "table" and type(data.payload.fragment_quests) == "table" then return data.payload.fragment_quests end
	return nil
end

function FragmentQuests:IsConfirmedBackendBlock(block)
	if type(block) ~= "table" then return false end

	local status = tostring(block.status or block.backend_status or "")
	status = string.lower(status)
	if status ~= "synced" and status ~= "confirmed" and status ~= "success" and status ~= "ok" then
		return false
	end

	local quests = block.quests or block.selected
	local hasQuest = false
	if type(quests) == "table" then
		for _, quest in pairs(quests) do
			if type(quest) == "table" and quest.instance_id ~= nil then
				hasQuest = true
				break
			end
		end
	end

	return hasQuest
end

function FragmentQuests:NormalizeConfirmedQuestList(block)
	local result = {}
	local byInstance = {}
	local quests = block and (block.quests or block.selected) or {}
	local index = 1

	if type(quests) ~= "table" then
		return result, byInstance
	end

	for _, quest in pairs(quests) do
		if type(quest) == "table" then
			local instanceID = tostring(quest.instance_id or quest.instanceId or "")
			if instanceID ~= "" then
				local normalized = {
					instance_id = instanceID,
					template_id = tostring(quest.template_id or quest.templateId or ""),
					target_id = tostring(quest.target_id or quest.targetId or "team"),
					stars = tonumber(quest.stars) or 0,
					fragments_awarded = tonumber(quest.fragments_awarded or quest.fragments or quest.reward) or 0,
					grant_status = tostring(quest.grant_status or quest.status or ""),
					idempotency_key = tostring(quest.idempotency_key or quest.idempotencyKey or ""),
				}

				result[tostring(index)] = normalized
				byInstance[instanceID] = normalized
				index = index + 1
			end
		end
	end

	return result, byInstance
end

function FragmentQuests:GetConfirmedTotalFragments(block, confirmedQuests)
	local total = tonumber(block and (block.total_fragments_awarded or block.total_fragments or block.fragments_awarded))
	if total ~= nil then
		return total
	end

	total = 0
	for _, quest in pairs(confirmedQuests or {}) do
		total = total + (tonumber(quest.fragments_awarded) or 0)
	end
	return total
end

function FragmentQuests:GetConfirmedQuest(instanceID)
	if self.backend_status ~= "synced" or instanceID == nil then return nil end
	return self.confirmed_quests_by_instance and self.confirmed_quests_by_instance[tostring(instanceID)] or nil
end

function FragmentQuests:DevAddProgress(metric, amount)
	amount = tonumber(amount) or 0
	if metric == "damage" then
		self.totals.team_damage = self.totals.team_damage + amount
	elseif metric == "healing" then
		self.totals.team_healing = self.totals.team_healing + amount
	elseif metric == "potions" then
		for _ = 1, math.max(1, SafeFloor(amount)) do
			self:OnPotionUsed(PlayerResource:GetSelectedHeroEntity(0))
		end
		return true
	elseif metric == "death" then
		local hero = PlayerResource:GetSelectedHeroEntity(0)
		if IsValidUnit(hero) then self:OnHeroDeath(hero, { source = "dev" }) end
		return true
	elseif metric == "farm_kills" then
		self.totals.farm_event_kills = self.totals.farm_event_kills + amount
	elseif metric == "frontline" then
		self.totals.frontline_damage = self.totals.frontline_damage + amount
	elseif metric == "tower_kills" then
		self.totals.tower_kills = self.totals.tower_kills + amount
	elseif metric == "base_hp" then
		self.totals.base_hp_percent = amount
	end

	self:LogEvent("dev_progress", { metric = metric, amount = amount })
	self:RecomputeAll()
	self:PublishState("dev_progress", true)
	return true
end

function FragmentQuests:DevReroll()
	self.seed = ((tonumber(self.seed) or 1) + 104729) % 2147483647
	if self.seed <= 0 then self.seed = 1 end
	self:ResetRuntime()
	self:SelectQuests()
	self:LogEvent("dev_reroll", { seed = self.seed })
	self:PublishState("dev_reroll", true)
	return true
end

function FragmentQuests:BuildDevConfirmedBlock()
	self:FinalizeForPayload()

	local quests = self:BuildSelectedPayload()
	for _, quest in ipairs(quests) do
		quest.grant_status = "dev_confirmed"
	end

	return {
		status = "synced",
		total_fragments_awarded = self:GetTotalFragments(),
		quests = quests,
	}
end

function FragmentQuests:DevSimulateBackend(success)
	if success == true then
		self:OnBackendComplete(true, {
			fragment_quests = self:BuildDevConfirmedBlock(),
		})
	else
		self:OnBackendComplete(false, {
			message = "Dev simulated backend fragment quest error",
		})
	end
	return true
end

function FragmentQuests:DevDumpPayload()
	local payload = self:BuildAnalyticsPayload()
	local selectedCount = 0
	for _, _ in pairs(payload.selected or {}) do selectedCount = selectedCount + 1 end
	local eventCount = 0
	for _, _ in pairs(payload.events or {}) do eventCount = eventCount + 1 end
	local playerCount = 0
	for _, _ in pairs(payload.players or {}) do playerCount = playerCount + 1 end

	self.last_dev_payload_dump_summary = {
		version = payload.version or VERSION,
		balance_version = payload.balance_version or BALANCE_VERSION,
		selected_count = selectedCount,
		event_count = eventCount,
		player_count = playerCount,
		total_fragments_preview = payload.total_fragments_preview or payload.total_fragments_pending or 0,
	}

	if json ~= nil and json.encode ~= nil then
		print("[FragmentQuests] Dev payload dump: " .. json.encode(payload))
	end

	self:PublishState("dev_dump_payload", true)
	return true
end

function FragmentQuests:DevCompleteWindow(window, value)
	window = tostring(window or "")
	value = tonumber(value)

	if window == "farm" then
		self.context.farm_event_active = true
		self:MarkQuestStarted("farm_event_kills", "team")
		self.totals.farm_event_kills = value or 240
		self:OnFarmEventEnd()
	elseif window == "muradin" then
		self:OnMuradinStart(0)
		self.totals.muradin_deaths = value or 0
		self:OnMuradinEnd()
	elseif window == "ramero" then
		self:MarkQuestStarted("arena_remaining_time", "ramero_baristol")
		self:SetQuestFinalValue("arena_remaining_time", "ramero_baristol", value or 60)
	elseif window == "sogat" then
		self:MarkQuestStarted("arena_remaining_time", "sogat")
		self:SetQuestFinalValue("arena_remaining_time", "sogat", value or 45)
	elseif window == "phase2" then
		local elapsed = value or 180
		self.context.phase2_active = true
		self.context.phase2_started_at = Now() - elapsed
		self.totals.phase2_magnataur_kills = self:GetExpectedMagnataurKills()
		self:MarkQuestStarted("phase2_assault_timer", "team")
		self:OnPhase2End()
	elseif window == "grom" then
		self.context.bosses.grom = {
			active = true,
			started_at = Now(),
			deaths = value or 0,
		}
		self:MarkQuestStarted("boss_death_cap", "grom")
		self:OnBossKilled("grom")
	elseif window == "illidan" then
		local elapsed = value or 120
		self.context.bosses.illidan = {
			active = true,
			started_at = Now() - elapsed,
			deaths = 0,
		}
		self:MarkQuestStarted("boss_timer", "illidan")
		self:OnBossKilled("illidan")
	elseif window == "lich_king" then
		local elapsed = value or 270
		self.context.bosses.lich_king = {
			active = true,
			started_at = Now() - elapsed,
			deaths = 0,
		}
		self:MarkQuestStarted("boss_timer", "lich_king")
		self:OnBossKilled("lich_king")
	elseif window == "final" then
		self.totals.base_hp_percent = value or 100
		self:SetQuestFinalValue("final_stand", "team", self.totals.base_hp_percent)
	else
		return false
	end

	self:LogEvent("dev_complete_window", { window = window, value = value or 0 })
	self:RecomputeAll()
	self:PublishState("dev_complete_window", true)
	return true
end

function FragmentQuests:BuildDevtoolsState()
	local state = self:BuildNetTableState("devtools")
	state.last_payload_dump = self.last_dev_payload_dump_summary or {}
	state.last_backend_fragment_quests = self.backend_fragment_quests_block or {}
	return state
end
