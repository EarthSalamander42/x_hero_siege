if XHSCreepAIDirector == nil then
	_G.XHSCreepAIDirector = class({})
end

local TICK_INTERVAL = 0.05
local MIN_BUDGET = 4
local MAX_BUDGET = 12
local AGENTS_PER_BUDGET_SLOT = 32
local DEFAULT_RETRY = 1.0
local HARD_DISABLE_RETRY = 0.4
local ACTION_LOCK_RETRY = 0.2

local function ProfileNow()
	if os ~= nil and os.clock ~= nil then
		local ok, value = pcall(os.clock)
		if ok and tonumber(value) ~= nil then return tonumber(value) end
	end
	if Time ~= nil then return Time() end
	if RealTime ~= nil then return RealTime() end
	return GameRules:GetGameTime()
end

local function IsValidEntityHandle(entity)
	return entity ~= nil
		and (entity.IsNull == nil or not entity:IsNull())
end

local function Counter(name, amount)
	if XHSPerformanceCounters ~= nil then
		XHSPerformanceCounters:Increment(name, amount or 1)
	end
end

local function Traceback(errorMessage)
	if debug ~= nil and debug.traceback ~= nil then
		return debug.traceback(errorMessage)
	end
	return tostring(errorMessage)
end

local function HeapLess(left, right)
	if left.at == right.at then
		return left.sequence < right.sequence
	end
	return left.at < right.at
end

local function HeapPush(heap, node)
	local index = #heap + 1
	heap[index] = node
	while index > 1 do
		local parent = math.floor(index / 2)
		if HeapLess(heap[parent], node) then break end
		heap[index] = heap[parent]
		index = parent
	end
	heap[index] = node
end

local function HeapPop(heap)
	local root = heap[1]
	local last = table.remove(heap)
	if #heap == 0 then return root end

	local index = 1
	while true do
		local left = index * 2
		if left > #heap then break end
		local right = left + 1
		local child = left
		if right <= #heap and HeapLess(heap[right], heap[left]) then
			child = right
		end
		if HeapLess(last, heap[child]) then break end
		heap[index] = heap[child]
		index = child
	end
	heap[index] = last
	return root
end

local function SafeBooleanCall(entity, methodName)
	if not IsValidEntityHandle(entity) or entity[methodName] == nil then return false end
	local ok, value = pcall(function() return entity[methodName](entity) end)
	return ok and value == true
end

function XHSCreepAIDirector:BuildAbilityProfile(unit)
	local profile = {
		unit_name = unit:GetUnitName(),
		active_abilities = {},
		has_active_abilities = false,
	}

	local abilityCount = GetUnitAbilityCount(unit)
	for abilityIndex = 0, abilityCount - 1 do
		local ability = GetUnitAbilityBySafeIndex(unit, abilityIndex)
		if IsValidEntityHandle(ability)
			and ability:GetLevel() > 0
			and not ability:IsPassive()
			and not ability:IsHidden() then
			table.insert(profile.active_abilities, {
				name = ability:GetAbilityName(),
				behavior = tonumber(tostring(ability:GetBehavior())) or 0,
				target_team = ability:GetAbilityTargetTeam(),
				target_type = ability:GetAbilityTargetType(),
				target_flags = ability:GetAbilityTargetFlags(),
			})
		end
	end

	profile.has_active_abilities = #profile.active_abilities > 0
	Counter("ai_profile_builds")
	if not profile.has_active_abilities then
		Counter("ai_no_active_profiles")
	end
	return profile
end

function XHSCreepAIDirector:GetAbilityProfile(unit)
	if not IsValidEntityHandle(unit) then return nil end
	local unitName = unit:GetUnitName()
	local profile = self.profile_cache[unitName]
	if profile ~= nil then
		Counter("ai_profile_cache_hits")
		return profile
	end

	profile = self:BuildAbilityProfile(unit)
	self.profile_cache[unitName] = profile
	return profile
end

function XHSCreepAIDirector:InvalidateAbilityProfile(unitName)
	unitName = tostring(unitName or "")
	if unitName ~= "" then
		self.profile_cache[unitName] = nil
	end
end

function XHSCreepAIDirector:Schedule(record, delay)
	if record == nil or record.active ~= true then return end
	delay = math.max(TICK_INTERVAL, tonumber(delay) or DEFAULT_RETRY)
	record.version = (record.version or 0) + 1
	self.next_sequence = self.next_sequence + 1
	HeapPush(self.heap, {
		at = GameRules:GetGameTime() + delay,
		record = record,
		version = record.version,
		sequence = self.next_sequence,
	})
end

function XHSCreepAIDirector:Register(modifier)
	if modifier == nil or modifier.GetParent == nil then return nil end
	self:Init()

	local unit = modifier:GetParent()
	if not IsValidEntityHandle(unit) then return nil end
	local entindex = unit:entindex()
	local existing = self.records[entindex]
	if existing ~= nil then
		existing.modifier = modifier
		existing.unit = unit
		existing.profile = nil
		existing.active = true
		return existing
	end

	local record = {
		entindex = entindex,
		unit = unit,
		modifier = modifier,
		-- npc_spawned can run inside CreateUnitByName, before the caller has
		-- levelled the unit's abilities. Build the shared profile on the first
		-- scheduled pass, after the spawn stack has completed.
		profile = nil,
		active = true,
		version = 0,
	}
	self.records[entindex] = record
	self.active_count = self.active_count + 1
	Counter("ai_agents_registered")

	-- Spread fresh wave spawns across the first scheduling window instead of
	-- waking an entire batch on the same server frame.
	local stagger = TICK_INTERVAL
		+ ((entindex + self.active_count) % 20) * TICK_INTERVAL
	self:Schedule(record, stagger)
	return record
end

function XHSCreepAIDirector:Unregister(modifierOrUnit)
	if modifierOrUnit == nil then return end
	local unit = modifierOrUnit.GetParent ~= nil
		and modifierOrUnit:GetParent()
		or modifierOrUnit
	if not IsValidEntityHandle(unit) then return end

	local record = self.records[unit:entindex()]
	if record == nil then return end
	record.active = false
	record.version = (record.version or 0) + 1
	self.records[record.entindex] = nil
	self.active_count = math.max(0, self.active_count - 1)
end

function XHSCreepAIDirector:GetHardSleepDelay(unit)
	if not IsValidEntityHandle(unit) or not unit:IsAlive() then return nil end
	if unit:IsIllusion() then return DEFAULT_RETRY end
	if SafeBooleanCall(unit, "IsOutOfGame")
		or SafeBooleanCall(unit, "IsCommandRestricted")
		or SafeBooleanCall(unit, "IsStunned")
		or SafeBooleanCall(unit, "IsHexed") then
		Counter("ai_agents_sleeping")
		return HARD_DISABLE_RETRY
	end
	if SafeBooleanCall(unit, "IsChanneling")
		or unit.GetCurrentActiveAbility ~= nil
			and IsValidEntityHandle(unit:GetCurrentActiveAbility()) then
		Counter("ai_agents_sleeping")
		return ACTION_LOCK_RETRY
	end
	return 0
end

function XHSCreepAIDirector:GetBudget()
	return math.max(
		MIN_BUDGET,
		math.min(
			MAX_BUDGET,
			math.ceil(math.max(1, self.active_count) / AGENTS_PER_BUDGET_SLOT)
		)
	)
end

function XHSCreepAIDirector:ProcessRecord(record)
	if record == nil or record.active ~= true then return end
	local unit = record.unit
	local modifier = record.modifier
	if not IsValidEntityHandle(unit) or not unit:IsAlive()
		or modifier == nil or modifier.IsNull ~= nil and modifier:IsNull() then
		record.active = false
		self.records[record.entindex] = nil
		self.active_count = math.max(0, self.active_count - 1)
		return
	end

	if XHSLagLabIsActive ~= nil and XHSLagLabIsActive("pause_ai") then
		self:Schedule(record, 0.25)
		return
	end

	local sleepDelay = self:GetHardSleepDelay(unit)
	if sleepDelay == nil then
		self:Unregister(unit)
		return
	end
	if sleepDelay > 0 then
		self:Schedule(record, sleepDelay)
		return
	end

	if record.profile == nil then
		record.profile = self:GetAbilityProfile(unit)
	end

	Counter("ai_agents_processed")
	local startedAt = ProfileNow()
	local ok, nextDelay = xpcall(function()
		return modifier:RunDirectorThink(record.profile, GameRules:GetGameTime())
	end, Traceback)
	local elapsedMs = math.max(0, (ProfileNow() - startedAt) * 1000)
	record.profile.think_calls = (record.profile.think_calls or 0) + 1
	record.profile.think_cost_total_ms =
		(record.profile.think_cost_total_ms or 0) + elapsedMs
	record.profile.think_cost_max_ms = math.max(
		record.profile.think_cost_max_ms or 0,
		elapsedMs
	)
	if not ok then
		print("[XHSCreepAIDirector] " .. tostring(nextDelay))
		nextDelay = DEFAULT_RETRY
	end
	self:Schedule(record, nextDelay)
end

function XHSCreepAIDirector:Tick()
	Counter("ai_director_ticks")
	local now = GameRules:GetGameTime()
	local budget = self:GetBudget()
	local processed = 0

	while processed < budget and #self.heap > 0 do
		local node = self.heap[1]
		if node.at > now then break end
		HeapPop(self.heap)
		local record = node.record
		if record ~= nil
			and record.active == true
			and node.version == record.version then
			processed = processed + 1
			self:ProcessRecord(record)
		end
	end
	return TICK_INTERVAL
end

function XHSCreepAIDirector:GetState()
	local cachedProfiles = 0
	local profilesWithoutActives = 0
	local activeAbilityAgents = 0
	local activeProfileCounts = {}
	for _, profile in pairs(self.profile_cache or {}) do
		cachedProfiles = cachedProfiles + 1
		if profile.has_active_abilities ~= true then
			profilesWithoutActives = profilesWithoutActives + 1
		end
	end
	for _, record in pairs(self.records or {}) do
		if record.active == true and record.profile ~= nil then
			local profile = record.profile
			local unitName = tostring(profile.unit_name or "unknown")
			local profileCount = activeProfileCounts[unitName]
			if profileCount == nil then
				local abilityNames = {}
				for _, ability in ipairs(profile.active_abilities or {}) do
					table.insert(abilityNames, tostring(ability.name or "unknown"))
				end
				table.sort(abilityNames)
				profileCount = {
					unit_name = unitName,
					agents = 0,
					abilities = abilityNames,
					think_calls = tonumber(profile.think_calls) or 0,
					think_cost_average_ms = (tonumber(profile.think_calls) or 0) > 0
						and (tonumber(profile.think_cost_total_ms) or 0)
							/ tonumber(profile.think_calls)
						or 0,
					think_cost_max_ms = tonumber(profile.think_cost_max_ms) or 0,
				}
				activeProfileCounts[unitName] = profileCount
			end
			profileCount.agents = profileCount.agents + 1
			if profile.has_active_abilities == true then
				activeAbilityAgents = activeAbilityAgents + 1
			end
		end
	end
	local activeProfiles = {}
	for _, profileCount in pairs(activeProfileCounts) do
		table.insert(activeProfiles, profileCount)
	end
	table.sort(activeProfiles, function(left, right)
		if left.agents == right.agents then
			return left.unit_name < right.unit_name
		end
		return left.agents > right.agents
	end)
	return {
		active_agents = self.active_count or 0,
		active_ability_agents = activeAbilityAgents,
		queued_agents = #(self.heap or {}),
		cached_profiles = cachedProfiles,
		profiles_without_actives = profilesWithoutActives,
		active_profiles = activeProfiles,
		budget = self:GetBudget(),
	}
end

function XHSCreepAIDirector:Init()
	if self.initialized == true then return end
	self.initialized = true
	self.profile_cache = {}
	self.records = {}
	self.heap = {}
	self.active_count = 0
	self.next_sequence = 0

	GameRules:GetGameModeEntity():SetContextThink("XHSCreepAIDirector", function()
		if GameRules:State_Get() >= DOTA_GAMERULES_STATE_POST_GAME then
			return nil
		end
		return XHSCreepAIDirector:Tick()
	end, TICK_INTERVAL)
	print("[XHSCreepAIDirector] Budgeted creep AI scheduler enabled.")
end

return XHSCreepAIDirector
