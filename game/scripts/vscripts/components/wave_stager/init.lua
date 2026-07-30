if XHSWaveStager == nil then
	_G.XHSWaveStager = class({})
end

LinkLuaModifier(
	"modifier_xhs_wave_staged",
	"components/wave_stager/modifier_xhs_wave_staged",
	LUA_MODIFIER_MOTION_NONE
)

local TICK_INTERVAL = 0.05
local CAPACITY_RETRY = 0.25
local DEFAULT_WINDOW = 20
local DEFAULT_WAKE_SPREAD = 0.25
local MAX_GLOBAL_STAGED_UNITS = 64
local STAGING_ORIGIN = Vector(-15800, -15800, -2048)

local function IsValidUnit(unit)
	return unit ~= nil
		and IsValidEntity(unit)
		and not unit:IsNull()
		and unit:IsAlive()
end

local function ProfileNow()
	if os ~= nil and os.clock ~= nil then
		local ok, value = pcall(os.clock)
		if ok and tonumber(value) ~= nil then return tonumber(value) end
	end
	if Time ~= nil then return Time() end
	return GameRules:GetGameTime()
end

local function Counter(name, amount)
	if XHSPerformanceCounters ~= nil
		and XHSPerformanceCounters.Increment ~= nil then
		XHSPerformanceCounters:Increment(name, amount or 1)
	end
end

local function Traceback(errorMessage)
	if debug ~= nil and debug.traceback ~= nil then
		return debug.traceback(errorMessage)
	end
	return tostring(errorMessage)
end

local function CopyPosition(position)
	if position == nil then return nil end
	return Vector(position.x, position.y, position.z or 0)
end

function XHSWaveStager:GetStagingPosition(sequence)
	sequence = math.max(1, tonumber(sequence) or 1)
	local column = (sequence - 1) % 16
	local row = math.floor((sequence - 1) / 16)
	return STAGING_ORIGIN + Vector(column * 48, row * 48, 0)
end

function XHSWaveStager:GetStagedCount(owner)
	local count = 0
	for entindex, record in pairs(self.staged_units or {}) do
		if not IsValidUnit(record.unit) then
			self.staged_units[entindex] = nil
		elseif owner == nil or record.owner == owner then
			count = count + 1
		end
	end
	return count
end

function XHSWaveStager:GetJob(id)
	return self.jobs and self.jobs[tostring(id or "")] or nil
end

function XHSWaveStager:QueueCleanup(record, reason)
	if record == nil or record.cleanup_queued == true then return end
	record.cleanup_queued = true
	record.cleanup_reason = tostring(reason or "cancelled")
	record.unit.xhs_wave_staging_cleanup = true
	table.insert(self.cleanup_queue, record)
	Counter("wave_stage_units_cancelled")
end

function XHSWaveStager:CleanupOne()
	local record = table.remove(self.cleanup_queue, 1)
	if record == nil then return false end
	local unit = record.unit
	if IsValidUnit(unit) then
		UTIL_Remove(unit)
	end
	self.staged_units[record.entindex] = nil
	Counter("wave_stage_units_cleaned")
	return true
end

function XHSWaveStager:CancelJob(id, reason)
	id = tostring(id or "")
	local job = self.jobs[id]
	if job == nil then return false end
	job.active = false
	job.generation = job.generation + 1
	self.jobs[id] = nil
	for _, record in pairs(job.records or {}) do
		self:QueueCleanup(record, reason)
	end
	Counter("wave_stage_jobs_cancelled")
	return true
end

function XHSWaveStager:StartJob(id, descriptors, options)
	self:Init()
	id = tostring(id or "")
	if id == "" then return nil end
	self:CancelJob(id, "replaced")

	descriptors = type(descriptors) == "table" and descriptors or {}
	options = type(options) == "table" and options or {}
	local now = GameRules:GetGameTime()
	local window = math.max(TICK_INTERVAL, tonumber(options.window) or DEFAULT_WINDOW)
	local startDelay = math.max(0, tonumber(options.start_delay) or 0)
	local stagingStartsAt = now + startDelay
	local job = {
		id = id,
		owner = tostring(options.owner or id),
		descriptors = descriptors,
		options = options,
		records = {},
		cursor = 1,
		created = 0,
		active = true,
		generation = (tonumber(self.next_generation) or 0) + 1,
		started_at = stagingStartsAt,
		window = window,
		interval = #descriptors > 0 and window / #descriptors or window,
		next_due = stagingStartsAt,
	}
	self.next_generation = job.generation
	self.jobs[id] = job
	Counter("wave_stage_jobs_started")
	return job
end

function XHSWaveStager:IsJobValid(job)
	if job == nil or job.active ~= true or self.jobs[job.id] ~= job then
		return false
	end
	local callback = job.options and job.options.is_valid or nil
	if callback == nil then return true end
	local ok, valid = xpcall(function() return callback(job) end, Traceback)
	if not ok then
		print("[XHSWaveStager] is_valid failed job=" .. job.id .. " error=" .. tostring(valid))
		return false
	end
	return valid == true
end

function XHSWaveStager:CanCreate(job, descriptor, index)
	if self:GetStagedCount() >= MAX_GLOBAL_STAGED_UNITS then return false end
	local callback = job.options and job.options.can_stage or nil
	if callback == nil then return true end
	local ok, allowed = xpcall(function()
		return callback(job, descriptor, index)
	end, Traceback)
	if not ok then
		print("[XHSWaveStager] can_stage failed job=" .. job.id .. " error=" .. tostring(allowed))
		return false
	end
	return allowed == true
end

function XHSWaveStager:CreateUnitForDescriptor(job, descriptor, index, fallback)
	descriptor = descriptor or {}
	local position = self:GetStagingPosition(self.next_staging_sequence)
	self.next_staging_sequence = self.next_staging_sequence + 1
	local startedAt = ProfileNow()
	local unit = nil
	local create = job.options and job.options.create or nil
	local ok, result = xpcall(function()
		if create ~= nil then
			return create(job, descriptor, index, position)
		end
		return CreateUnitByName(
			tostring(descriptor.unit_name or ""),
			position,
			true,
			nil,
			nil,
			tonumber(descriptor.team) or DOTA_TEAM_CUSTOM_1
		)
	end, Traceback)
	local elapsedMs = math.max(0, (ProfileNow() - startedAt) * 1000)
	Counter("wave_stage_create_cost_ms", elapsedMs)
	self.create_cost_max_ms = math.max(self.create_cost_max_ms or 0, elapsedMs)
	if ok then unit = result end
	if not ok or not IsValidUnit(unit) then
		Counter("wave_stage_create_failures")
		print(
			"[XHSWaveStager] create failed job=" .. job.id
				.. " index=" .. tostring(index)
				.. " error=" .. tostring(result)
		)
		return nil
	end

	unit.xhs_wave_staged = true
	unit.xhs_wave_stage_owner = job.owner
	unit.xhs_wave_stage_job = job.id
	unit.xhs_wave_stage_index = index
	if unit.SetIdleAcquire ~= nil then unit:SetIdleAcquire(false) end
	unit:AddNoDraw()
	unit:AddNewModifier(unit, nil, "modifier_xhs_wave_staged", {})
	if XHSCreepAIDirector ~= nil and XHSCreepAIDirector.SetStaged ~= nil then
		XHSCreepAIDirector:SetStaged(unit, true)
	end

	local configure = job.options and job.options.configure or nil
	if configure ~= nil then
		local configured, configureError = xpcall(function()
			configure(job, unit, descriptor, index)
		end, Traceback)
		if not configured then
			print(
				"[XHSWaveStager] configure failed job=" .. job.id
					.. " index=" .. tostring(index)
					.. " error=" .. tostring(configureError)
			)
			UTIL_Remove(unit)
			return nil
		end
	end

	local record = {
		unit = unit,
		entindex = unit:entindex(),
		owner = job.owner,
		job_id = job.id,
		index = index,
		descriptor = descriptor,
		fallback = fallback == true,
	}
	job.records[index] = record
	job.created = job.created + 1
	self.staged_units[record.entindex] = record
	Counter(fallback == true
		and "wave_stage_units_fallback_created"
		or "wave_stage_units_created")
	return record
end

function XHSWaveStager:ProcessJob(job, now)
	if not self:IsJobValid(job) then
		self:CancelJob(job and job.id or "", "invalid")
		return false
	end
	if job.cursor > #job.descriptors then return false end
	local descriptor = job.descriptors[job.cursor]
	if not self:CanCreate(job, descriptor, job.cursor) then
		job.next_due = now + CAPACITY_RETRY
		Counter("wave_stage_capacity_deferred")
		return false
	end

	self:CreateUnitForDescriptor(job, descriptor, job.cursor, false)
	job.cursor = job.cursor + 1
	job.next_due = job.started_at + (job.cursor - 1) * job.interval
	return true
end

function XHSWaveStager:SelectDueJob(now)
	local selected = nil
	for _, job in pairs(self.jobs) do
		if job.active == true
			and job.cursor <= #job.descriptors
			and now >= (job.next_due or now)
			and (selected == nil or job.next_due < selected.next_due) then
			selected = job
		end
	end
	return selected
end

function XHSWaveStager:ActivateRecord(job, record, descriptor, releaseIndex, options)
	local unit = record and record.unit or nil
	if not IsValidUnit(unit) then return false end
	local targetPosition = descriptor.spawn_position
	if type(targetPosition) == "function" then
		targetPosition = targetPosition(job, descriptor, record.index)
	end
	if targetPosition ~= nil then
		unit:SetAbsOrigin(CopyPosition(targetPosition))
		FindClearSpaceForUnit(unit, unit:GetAbsOrigin(), true)
	end

	unit.xhs_wave_staged = false
	unit.xhs_wave_stage_owner = nil
	unit.xhs_wave_stage_job = nil
	unit.xhs_wave_stage_index = nil
	unit:RemoveModifierByName("modifier_xhs_wave_staged")
	unit:RemoveNoDraw()
	if unit.SetIdleAcquire ~= nil then unit:SetIdleAcquire(true) end
	self.staged_units[record.entindex] = nil

	local wakeSpread = math.max(
		0,
		tonumber(options.wake_spread)
			or tonumber(job.options.wake_spread)
			or DEFAULT_WAKE_SPREAD
	)
	local expected = math.max(1, tonumber(options.release_count) or #job.descriptors)
	local wakeDelay = expected > 1
		and ((releaseIndex - 1) / (expected - 1)) * wakeSpread or 0
	if XHSCreepAIDirector ~= nil and XHSCreepAIDirector.SetStaged ~= nil then
		XHSCreepAIDirector:SetStaged(unit, false, wakeDelay)
	end

	local activate = options.activate or job.options.activate
	if activate ~= nil then
		local ok, activateError = xpcall(function()
			activate(job, unit, descriptor, record.index, releaseIndex)
		end, Traceback)
		if not ok then
			print(
				"[XHSWaveStager] activate failed job=" .. job.id
					.. " index=" .. tostring(record.index)
					.. " error=" .. tostring(activateError)
			)
		end
	end
	Counter("wave_stage_units_released")
	return true
end

function XHSWaveStager:ActivateJob(id, options)
	id = tostring(id or "")
	local job = self.jobs[id]
	if job == nil then return 0, 0, 0 end
	options = type(options) == "table" and options or {}
	job.active = false
	job.generation = job.generation + 1
	self.jobs[id] = nil

	local shouldRelease = options.should_release
	local selected = {}
	for index, descriptor in ipairs(job.descriptors) do
		local release = true
		if shouldRelease ~= nil then
			local ok, value = xpcall(function()
				return shouldRelease(job, descriptor, index)
			end, Traceback)
			release = ok and value == true
		end
		if release then table.insert(selected, index) end
	end
	options.release_count = #selected

	local released = 0
	local fallback = 0
	local selectedSet = {}
	for _, index in ipairs(selected) do selectedSet[index] = true end
	for index, descriptor in ipairs(job.descriptors) do
		local record = job.records[index]
		if selectedSet[index] == true then
			if record == nil or not IsValidUnit(record.unit) then
				record = self:CreateUnitForDescriptor(job, descriptor, index, true)
				if record ~= nil then fallback = fallback + 1 end
			end
			if record ~= nil
				and self:ActivateRecord(job, record, descriptor, released + 1, options) then
				released = released + 1
			else
				Counter("wave_stage_release_missing")
			end
		elseif record ~= nil then
			self:QueueCleanup(record, "not_selected")
		end
	end
	Counter("wave_stage_jobs_released")
	return released, #selected, fallback
end

function XHSWaveStager:Tick()
	self:CleanupOne()
	local now = GameRules:GetGameTime()
	local job = self:SelectDueJob(now)
	if job ~= nil then self:ProcessJob(job, now) end
	return TICK_INTERVAL
end

function XHSWaveStager:GetState()
	local activeJobs = 0
	local pendingUnits = 0
	for _, job in pairs(self.jobs or {}) do
		activeJobs = activeJobs + 1
		pendingUnits = pendingUnits + math.max(0, #job.descriptors - job.cursor + 1)
	end
	return {
		active_jobs = activeJobs,
		staged_units = self:GetStagedCount(),
		pending_units = pendingUnits,
		cleanup_units = #(self.cleanup_queue or {}),
		global_cap = MAX_GLOBAL_STAGED_UNITS,
		create_cost_max_ms = self.create_cost_max_ms or 0,
	}
end

function XHSWaveStager:Init()
	if self.initialized == true then return end
	self.initialized = true
	self.jobs = self.jobs or {}
	self.staged_units = self.staged_units or {}
	self.cleanup_queue = self.cleanup_queue or {}
	self.next_generation = self.next_generation or 0
	self.next_staging_sequence = self.next_staging_sequence or 1
	self.create_cost_max_ms = self.create_cost_max_ms or 0
	GameRules:GetGameModeEntity():SetContextThink("XHSWaveStager", function()
		if GameRules:State_Get() >= DOTA_GAMERULES_STATE_POST_GAME then
			return nil
		end
		return XHSWaveStager:Tick()
	end, TICK_INTERVAL)
	print("[XHSWaveStager] Progressive dormant wave staging enabled.")
end

return XHSWaveStager
