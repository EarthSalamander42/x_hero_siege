if XHSLagLab == nil then
	_G.XHSLagLab = class({})
end

LinkLuaModifier("modifier_xhs_lag_lab_root", "components/devtools/lag_lab", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_xhs_lag_lab_no_collision", "components/devtools/lag_lab", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_xhs_lag_lab_disarm", "components/devtools/lag_lab", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_xhs_lag_lab_silence", "components/devtools/lag_lab", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_xhs_lag_lab_hidden", "components/devtools/lag_lab", LUA_MODIFIER_MOTION_NONE)

local BASELINE_SECONDS = 10
local WARMUP_SECONDS = 3
local TEST_SECONDS = 10
local SAMPLE_SECONDS = 1
local DEFAULT_CREEP_MODEL = "models/creeps/lane_creeps/creep_radiant_melee/radiant_melee.vmdl"

local EXPERIMENTS = {
	base_model = { label = "Base creep model", kind = "unit" },
	hide_creeps = { label = "Hide creep rendering", kind = "unit" },
	pause_ai = { label = "Pause modifier_ai", kind = "runtime" },
	pause_bots = { label = "Pause allied bots", kind = "bots" },
	pause_waves = { label = "Pause wave controllers", kind = "runtime" },
	pause_abilities = { label = "Pause creep ability loops", kind = "runtime" },
	suppress_orders = { label = "Suppress creep orders", kind = "runtime" },
	root_creeps = { label = "Root creeps", kind = "modifier", modifier = "modifier_xhs_lag_lab_root" },
	no_collision = { label = "Disable creep collision", kind = "modifier", modifier = "modifier_xhs_lag_lab_no_collision" },
	disarm_creeps = { label = "Disarm creeps", kind = "modifier", modifier = "modifier_xhs_lag_lab_disarm" },
	silence_creeps = { label = "Silence creeps", kind = "modifier", modifier = "modifier_xhs_lag_lab_silence" },
	hotspot_mute = { label = "Mute sampled spatial-query hotspot", kind = "hotspot" },
	hotspot_half = { label = "Run spatial-query hotspot at 50%", kind = "hotspot" },
	hotspot_quarter = { label = "Run spatial-query hotspot at 25%", kind = "hotspot" },
}

local METRICS = {
	"client_fps",
	"server_frame_ms",
	"creeps",
	"total_units",
	"scan_ms",
	"zone_searches_s",
	"zone_cost_ms_s",
	"orders_s",
	"repeated_orders_s",
	"ai_thinks_s",
	"director_processed_s",
	"director_sleeping_s",
	"wave_thinks_s",
	"ability_thinks_s",
	"damage_s",
	"projectiles_s",
	"target_changes_s",
}

local function RealNow()
	if RealTime ~= nil then return RealTime() end
	if Time ~= nil then return Time() end
	return GameRules:GetGameTime()
end

local function Round(value, precision)
	local multiplier = 10 ^ (precision or 0)
	return math.floor((tonumber(value) or 0) * multiplier + 0.5) / multiplier
end

local function IsValidEntity(entity)
	return entity ~= nil and (entity.IsNull == nil or not entity:IsNull())
end

local function EmptyAccumulator()
	return { count = 0, sums = {}, counts = {} }
end

local function RemoveUnitCosmetics(unit)
	if not IsValidEntity(unit) then return end

	if Wearable ~= nil and unit.Slots ~= nil then
		local slotNames = {}
		for slotName, _ in pairs(unit.Slots) do
			table.insert(slotNames, slotName)
		end
		for _, slotName in ipairs(slotNames) do
			if Wearable.TakeOffSlot ~= nil then
				pcall(function() Wearable:TakeOffSlot(unit, slotName) end)
			end
		end
	end

	if Wearable ~= nil and Wearable.RemoveWearables ~= nil then
		pcall(function() Wearable:RemoveWearables(unit) end)
	end

	-- KV AttachWearables are dota_item_wearable children. The mod's wearable
	-- library additionally parents wearable_dummy units to their owner.
	local children = unit.GetChildren ~= nil and unit:GetChildren() or {}
	for _, child in ipairs(children) do
		if IsValidEntity(child) then
			local className = child.GetClassname ~= nil and child:GetClassname() or ""
			local unitName = child.GetUnitName ~= nil and child:GetUnitName() or ""
			local isWearableDummy = unitName == "wearable_dummy"
				or (child.HasModifier ~= nil and child:HasModifier("modifier_wearable"))
			if className == "dota_item_wearable" or isWearableDummy then
				UTIL_Remove(child)
			end
		end
	end

	unit.Slots = {}
end

function XHSLagLab:HideRenderEntity(entity)
	if not IsValidEntity(entity) or entity.entindex == nil then return end
	local entindex = entity:entindex()

	local alphaRecord = self.changed_alpha[entindex]
	if alphaRecord == nil or alphaRecord.unit ~= entity then
		local alpha = 255
		if entity.GetRenderAlpha ~= nil then
			local ok, value = pcall(function() return entity:GetRenderAlpha() end)
			if ok and value ~= nil then alpha = value end
		end
		self.changed_alpha[entindex] = { unit = entity, alpha = alpha }
	end
	if entity.SetRenderAlpha ~= nil then entity:SetRenderAlpha(0) end

	local noDrawRecord = self.changed_no_draw[entindex]
	if noDrawRecord == nil or noDrawRecord.unit ~= entity then
		local wasNoDraw = entity.xhs_farm_staged == true
			or (entity.HasModifier ~= nil and entity:HasModifier("modifier_xhs_farm_staged"))
		if entity.IsNoDraw ~= nil then
			local ok, value = pcall(function() return entity:IsNoDraw() end)
			if ok then wasNoDraw = value == true end
		end
		self.changed_no_draw[entindex] = {
			unit = entity,
			remove_on_restore = not wasNoDraw,
		}
	end
	if entity.AddNoDraw ~= nil then entity:AddNoDraw() end
	local effectRecord = self.changed_no_draw_effect[entindex]
	if effectRecord == nil or effectRecord.unit ~= entity then
		local hadNoDrawEffect = false
		if entity.IsEffectActive ~= nil and EF_NODRAW ~= nil then
			local ok, value = pcall(function() return entity:IsEffectActive(EF_NODRAW) end)
			if ok then hadNoDrawEffect = value == true end
		end
		self.changed_no_draw_effect[entindex] = {
			unit = entity,
			remove_on_restore = not hadNoDrawEffect,
		}
	end
	if entity.AddEffects ~= nil and EF_NODRAW ~= nil then
		entity:AddEffects(EF_NODRAW)
	end
end

function XHSLagLab:HideUnitRendering(unit)
	if not IsValidEntity(unit) then return end
	local unitIndex = unit:entindex()
	if self.changed_wearables[unitIndex] == nil
		and Wearable ~= nil
		and Wearable.HideWearables ~= nil
		and type(unit.Slots) == "table"
		and next(unit.Slots) ~= nil then
		self.changed_wearables[unitIndex] = { unit = unit }
		pcall(function() Wearable:HideWearables(unit) end)
	end
	local visited = {}
	local function HideTree(entity, depth)
		if not IsValidEntity(entity) or entity.entindex == nil then return end
		local entindex = entity:entindex()
		if visited[entindex] == true then return end
		visited[entindex] = true
		self:HideRenderEntity(entity)
		if depth >= 2 or entity.GetChildren == nil then return end
		for _, child in ipairs(entity:GetChildren() or {}) do
			HideTree(child, depth + 1)
		end
	end
	HideTree(unit, 0)
end

function XHSLagLab:IsActive(experimentID)
	return self.state ~= nil
		and self.state.effect_active == true
		and self.state.experiment_id == experimentID
end

function XHSLagLab:IsHotspotExperimentActive()
	return self.state ~= nil
		and self.state.effect_active == true
		and EXPERIMENTS[self.state.experiment_id] ~= nil
		and EXPERIMENTS[self.state.experiment_id].kind == "hotspot"
end

function XHSLagLab:GetHotspotPolicy(source)
	if not self:IsHotspotExperimentActive() or source ~= self.state.source then return nil end
	if self.state.experiment_id == "hotspot_mute" then return 0 end
	if self.state.experiment_id == "hotspot_half" then return 2 end
	if self.state.experiment_id == "hotspot_quarter" then return 4 end
	return nil
end

function XHSLagLab:ShouldRunHotspot(source)
	local divisor = self:GetHotspotPolicy(source)
	if divisor == nil then return true end
	if divisor == 0 then return false end
	self.hotspot_sequence = (self.hotspot_sequence or 0) + 1
	return self.hotspot_sequence % divisor == 1
end

function XHSLagLab:IsTargetCreep(unit)
	if not IsValidEntity(unit) or unit.IsAlive == nil or not unit:IsAlive() then return false end
	if unit.IsRealHero ~= nil and unit:IsRealHero() then return false end
	if unit.Boss == true then return false end
	local unitName = unit.GetUnitName ~= nil and unit:GetUnitName() or ""
	if string.find(unitName, "boss", 1, true) ~= nil then return false end
	if unit.GetTeamNumber == nil or unit:GetTeamNumber() == DOTA_TEAM_GOODGUYS then return false end
	return (unit.IsCreep ~= nil and unit:IsCreep())
		or (unit.IsCreature ~= nil and unit:IsCreature())
end

function XHSLagLab:GetTargetCreeps()
	if XHSPerformanceCounters == nil or XHSPerformanceCounters.FindUnitsInRadiusUntracked == nil then
		return {}
	end
	local targetFlags = DOTA_UNIT_TARGET_FLAG_INVULNERABLE
	if DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES ~= nil then
		targetFlags = targetFlags + DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES
	end
	local units = XHSPerformanceCounters:FindUnitsInRadiusUntracked(
		DOTA_TEAM_NEUTRALS,
		Vector(0, 0, 0),
		nil,
		FIND_UNITS_EVERYWHERE,
		DOTA_UNIT_TARGET_TEAM_BOTH,
		DOTA_UNIT_TARGET_BASIC,
		targetFlags,
		FIND_ANY_ORDER,
		false
	)
	local result = {}
	local seen = {}
	local function AddUnit(unit)
		if not self:IsTargetCreep(unit) then return end
		local entindex = unit:entindex()
		if seen[entindex] == true then return end
		seen[entindex] = true
		table.insert(result, unit)
	end
	for _, unit in pairs(units) do
		AddUnit(unit)
	end

	-- Some hero-model wave units are not returned consistently by target-type
	-- searches. Enumerating the creature classname catches waves already alive
	-- when the experiment transitions from baseline to warmup.
	if Entities ~= nil and Entities.FindAllByClassname ~= nil then
		for _, unit in pairs(Entities:FindAllByClassname("npc_dota_creature") or {}) do
			AddUnit(unit)
		end
	end
	for entindex, _ in pairs(CustomTimers and CustomTimers.active_special_wave_units or {}) do
		local ok, unit = pcall(EntIndexToHScript, tonumber(entindex))
		if ok then AddUnit(unit) end
	end
	return result
end

function XHSLagLab:ApplyToUnit(unit)
	if not self:IsTargetCreep(unit) or self.state.effect_active ~= true then return end
	local experiment = EXPERIMENTS[self.state.experiment_id]
	if experiment == nil then return end

	local entindex = unit:entindex()
	if experiment.modifier ~= nil then
		unit:AddNewModifier(unit, nil, experiment.modifier, {})
	elseif self.state.experiment_id == "base_model" then
		local firstApplication = self.changed_models[entindex] == nil
		if self.changed_models[entindex] == nil then
			self.changed_models[entindex] = {
				unit = unit,
				model = unit.GetModelName ~= nil and unit:GetModelName() or "",
			}
		end
		RemoveUnitCosmetics(unit)
		unit:SetModel(DEFAULT_CREEP_MODEL)
		unit:SetOriginalModel(DEFAULT_CREEP_MODEL)
		if firstApplication and Timers ~= nil then
			Timers:CreateTimer(0.1, function()
				if self:IsActive("base_model") and self:IsTargetCreep(unit) then
					RemoveUnitCosmetics(unit)
					unit:SetModel(DEFAULT_CREEP_MODEL)
					unit:SetOriginalModel(DEFAULT_CREEP_MODEL)
				end
				return nil
			end)
		end
	elseif self.state.experiment_id == "hide_creeps" then
		local firstApplication = self.changed_no_draw[entindex] == nil
		unit:AddNewModifier(unit, nil, "modifier_xhs_lag_lab_hidden", {})
		self:HideUnitRendering(unit)
		-- Hero-model creep cosmetics can be attached shortly after npc_spawned.
		-- Revisit this unit twice without adding a global scan to the A/B test.
		if firstApplication and Timers ~= nil then
			for _, delay in ipairs({ 0.15, 0.75 }) do
				Timers:CreateTimer(delay, function()
					if self:IsActive("hide_creeps") and self:IsTargetCreep(unit) then
						self:HideUnitRendering(unit)
					end
					return nil
				end)
			end
		end
	end
end

function XHSLagLab:ApplyExperiment()
	self.state.effect_active = true
	self.hotspot_sequence = 0
	if self.state.experiment_id == "pause_bots" then
		self.bot_pause_state_captured = true
		self.bots_were_paused = XHSBots ~= nil and XHSBots.paused == true
		XHSBots:SetPaused(true)
	end
	local targetCreeps = self:GetTargetCreeps()
	self.state.affected_units = #targetCreeps
	for _, unit in pairs(targetCreeps) do
		self:ApplyToUnit(unit)
	end
end

function XHSLagLab:RestoreEffects()
	self.state.effect_active = false
	if self.bot_pause_state_captured == true and XHSBots ~= nil and XHSBots.SetPaused ~= nil then
		XHSBots:SetPaused(self.bots_were_paused == true)
		if self.bots_were_paused ~= true and XHSBots.StartThinker ~= nil then
			XHSBots:StartThinker()
		end
	end
	self.bot_pause_state_captured = false
	self.bots_were_paused = nil

	for _, modifierName in pairs({
		"modifier_xhs_lag_lab_root",
		"modifier_xhs_lag_lab_no_collision",
		"modifier_xhs_lag_lab_disarm",
		"modifier_xhs_lag_lab_silence",
		"modifier_xhs_lag_lab_hidden",
	}) do
		for _, unit in pairs(self:GetTargetCreeps()) do
			unit:RemoveModifierByName(modifierName)
		end
	end

	for _, record in pairs(self.changed_models or {}) do
		if IsValidEntity(record.unit) and record.model ~= "" then
			record.unit:SetModel(record.model)
			record.unit:SetOriginalModel(record.model)
		end
	end
	for _, record in pairs(self.changed_alpha or {}) do
		if IsValidEntity(record.unit) then
			record.unit:SetRenderAlpha(tonumber(record.alpha) or 255)
		end
	end
	for _, record in pairs(self.changed_no_draw or {}) do
		if IsValidEntity(record.unit)
			and record.remove_on_restore == true
			and record.unit.RemoveNoDraw ~= nil then
			record.unit:RemoveNoDraw()
		end
	end
	for _, record in pairs(self.changed_no_draw_effect or {}) do
		if IsValidEntity(record.unit)
			and record.remove_on_restore == true
			and record.unit.RemoveEffects ~= nil
			and EF_NODRAW ~= nil then
			record.unit:RemoveEffects(EF_NODRAW)
		end
	end
	for _, record in pairs(self.changed_wearables or {}) do
		if IsValidEntity(record.unit)
			and Wearable ~= nil
			and Wearable.ShowWearables ~= nil then
			pcall(function() Wearable:ShowWearables(record.unit) end)
		end
	end
	self.changed_models = {}
	self.changed_alpha = {}
	self.changed_no_draw = {}
	self.changed_no_draw_effect = {}
	self.changed_wearables = {}
	self.hotspot_sequence = 0
end

function XHSLagLab:ShouldSuppressOrder(order)
	if not self:IsActive("suppress_orders") then return false end
	local unitIndex = order ~= nil and tonumber(order.UnitIndex) or nil
	if unitIndex == nil or EntIndexToHScript == nil then return false end
	local ok, unit = pcall(EntIndexToHScript, unitIndex)
	return ok and self:IsTargetCreep(unit)
end

function XHSLagLab:CaptureMetrics()
	if XHSDevTools == nil or XHSDevTools.BuildPerformanceState == nil then return nil end
	local snapshot = XHSDevTools:BuildPerformanceState()
	local activity = snapshot.activity or {}
	local fpsSum = 0
	local fpsCount = 0
	for _, player in pairs(snapshot.players or {}) do
		local fps = tonumber(player.fps)
		if fps ~= nil and fps >= 0 then
			fpsSum = fpsSum + fps
			fpsCount = fpsCount + 1
		end
	end
	return {
		client_fps = fpsCount > 0 and fpsSum / fpsCount or -1,
		server_frame_ms = tonumber(snapshot.frame_ms) or 0,
		creeps = tonumber(snapshot.creeps) or 0,
		total_units = tonumber(snapshot.total_units) or 0,
		scan_ms = tonumber(snapshot.scan_ms) or 0,
		zone_searches_s = tonumber(
			activity.spatial_queries_per_second or activity.zone_searches_per_second
		) or 0,
		zone_cost_ms_s = tonumber(
			activity.spatial_query_cost_ms_per_second or activity.zone_search_cost_ms_per_second
		) or 0,
		orders_s = tonumber(activity.orders_per_second) or 0,
		repeated_orders_s = tonumber(activity.repeated_orders_per_second) or 0,
		ai_thinks_s = tonumber(activity.ai_thinks_per_second) or 0,
		director_processed_s = tonumber(activity.ai_agents_processed_per_second) or 0,
		director_sleeping_s = tonumber(activity.ai_agents_sleeping_per_second) or 0,
		wave_thinks_s = tonumber(activity.wave_thinks_per_second) or 0,
		ability_thinks_s = tonumber(activity.ability_loop_thinks_per_second) or 0,
		damage_s = tonumber(activity.damage_events_per_second) or 0,
		projectiles_s = tonumber(activity.projectiles_per_second) or 0,
		target_changes_s = tonumber(activity.target_changes_per_second) or 0,
	}
end

function XHSLagLab:AddSample(accumulator)
	local sample = self:CaptureMetrics()
	if sample == nil then return end
	accumulator.count = accumulator.count + 1
	for _, key in ipairs(METRICS) do
		local value = tonumber(sample[key]) or 0
		if key ~= "client_fps" or value >= 0 then
			accumulator.sums[key] = (accumulator.sums[key] or 0) + value
			accumulator.counts[key] = (accumulator.counts[key] or 0) + 1
		end
	end
end

function XHSLagLab:FinishAccumulator(accumulator)
	local result = {}
	for _, key in ipairs(METRICS) do
		local count = math.max(1, accumulator.counts[key] or 0)
		result[key] = Round((accumulator.sums[key] or 0) / count, 2)
	end
	return result
end

function XHSLagLab:BuildResult()
	local baseline = self:FinishAccumulator(self.baseline)
	local test = self:FinishAccumulator(self.test)
	local delta = {}
	for _, key in ipairs(METRICS) do
		delta[key] = Round((test[key] or 0) - (baseline[key] or 0), 2)
	end
	return {
		experiment_id = self.state.experiment_id,
		label = self.state.label,
		source = self.state.source or "",
		baseline = baseline,
		test = test,
		delta = delta,
		baseline_samples = self.baseline.count,
		test_samples = self.test.count,
	}
end

function XHSLagLab:Publish()
	if CustomNetTables == nil then return end
	local now = RealNow()
	local remaining = 0
	if self.stage_ends_at ~= nil then
		remaining = math.max(0, self.stage_ends_at - now)
	end
	CustomNetTables:SetTableValue("xhs_devtools", "lag_lab", {
		running = self.state.running == true,
		effect_active = self.state.effect_active == true,
		stage = self.state.stage or "idle",
		remaining = Round(remaining, 1),
		experiment_id = self.state.experiment_id or "",
		label = self.state.label or "",
		source = self.state.source or "",
		keep_active = self.state.keep_active == true,
		affected_units = tonumber(self.state.affected_units) or 0,
		last_result = self.last_result or {},
	})
end

function XHSLagLab:SetStage(stage, seconds)
	self.state.stage = stage
	self.stage_ends_at = seconds ~= nil and (RealNow() + seconds) or nil
	self.next_sample_at = RealNow()
	self.next_publish_at = RealNow() + 1
	self:Publish()
end

function XHSLagLab:Start(experimentID, source, keepActive)
	if not IsInToolsMode() then error("Lag Lab requires Workshop Tools mode") end
	if self.state == nil then
		self:Init()
	end
	if self.state == nil then error("Lag Lab runner failed to initialize") end
	local experiment = EXPERIMENTS[experimentID]
	if experiment == nil then error("Unknown Lag Lab experiment") end
	if experimentID == "pause_bots"
		and (XHSBots == nil or XHSBots.enabled ~= true or XHSBots.SetPaused == nil) then
		error("Allied XHS bots are not enabled in this match")
	end
	if experimentID == "pause_bots" and XHSBots.paused == true then
		error("Allied XHS bots are already paused; resume them before starting this comparison")
	end
	if experiment.kind == "hotspot" then
		source = tostring(source or "")
		if source == "" or XHSPerformanceCounters == nil
			or not XHSPerformanceCounters:IsObservedSource("zone", source) then
			error("Hotspot source is not in the observed server allowlist")
		end
	end

	self:Restore("replaced")
	self.state = {
		running = true,
		effect_active = false,
		stage = "baseline",
		experiment_id = experimentID,
		label = experiment.label,
		source = source or "",
		keep_active = keepActive == true,
	}
	self.baseline = EmptyAccumulator()
	self.test = EmptyAccumulator()
	self:SetStage("baseline", BASELINE_SECONDS)
	return "Lag Lab baseline started: " .. experiment.label
end

function XHSLagLab:Restore(reason)
	self:RestoreEffects()
	self.state = self.state or {}
	self.state.running = false
	self.state.stage = reason == "complete" and "complete" or "idle"
	self.stage_ends_at = nil
	self.next_sample_at = nil
	self.next_publish_at = nil
	self:Publish()
	return reason == "complete" and "Lag Lab test complete" or "Lag Lab restored"
end

function XHSLagLab:Think()
	if self.state.running ~= true then return end
	local now = RealNow()
	if now >= (self.next_sample_at or 0) then
		self.next_sample_at = now + SAMPLE_SECONDS
		if self.state.stage == "baseline" then
			self:AddSample(self.baseline)
		elseif self.state.stage == "test" then
			self:AddSample(self.test)
		end
	end

	if self.stage_ends_at == nil or now < self.stage_ends_at then
		if now >= (self.next_publish_at or 0) then
			self.next_publish_at = now + 1
			self:Publish()
		end
		return
	end

	if self.state.stage == "baseline" then
		self:ApplyExperiment()
		self:SetStage("warmup", WARMUP_SECONDS)
	elseif self.state.stage == "warmup" then
		self:SetStage("test", TEST_SECONDS)
	elseif self.state.stage == "test" then
		self.last_result = self:BuildResult()
		if self.state.keep_active == true then
			self.state.running = false
			self.state.stage = "latched"
			self.stage_ends_at = nil
			self.next_sample_at = nil
			self.next_publish_at = nil
			self:Publish()
		else
			self:Restore("complete")
		end
	end
end

function XHSLagLab:Init()
	if self.initialized then
		self.state = self.state or { running = false, effect_active = false, stage = "idle" }
		self.changed_models = self.changed_models or {}
		self.changed_alpha = self.changed_alpha or {}
		self.changed_no_draw = self.changed_no_draw or {}
		self.changed_no_draw_effect = self.changed_no_draw_effect or {}
		self.changed_wearables = self.changed_wearables or {}
		self:Publish()
		return
	end
	self.initialized = true
	self.state = { running = false, effect_active = false, stage = "idle" }
	self.changed_models = {}
	self.changed_alpha = {}
	self.changed_no_draw = {}
	self.changed_no_draw_effect = {}
	self.changed_wearables = {}
	ListenToGameEvent("npc_spawned", function(event)
		if XHSLagLab.state == nil or XHSLagLab.state.effect_active ~= true then return end
		local unitIndex = event and tonumber(event.entindex) or nil
		if unitIndex == nil then return end
		local ok, unit = pcall(EntIndexToHScript, unitIndex)
		if ok then XHSLagLab:ApplyToUnit(unit) end
	end, nil)
	GameRules:GetGameModeEntity():SetContextThink("XHSLagLabRunner", function()
		if GameRules:State_Get() >= DOTA_GAMERULES_STATE_POST_GAME then
			XHSLagLab:Restore("post_game")
			return nil
		end
		XHSLagLab:Think()
		return 0.25
	end, 0.25)
	self:Publish()
	print("[XHSLagLab] Tools-only A/B experiment runner enabled.")
end

function XHSLagLabModifierBase()
	return {
		IsHidden = function() return true end,
		IsPurgable = function() return false end,
		RemoveOnDeath = function() return true end,
	}
end

modifier_xhs_lag_lab_root = class(XHSLagLabModifierBase())
function modifier_xhs_lag_lab_root:CheckState()
	return { [MODIFIER_STATE_ROOTED] = true }
end

modifier_xhs_lag_lab_no_collision = class(XHSLagLabModifierBase())
function modifier_xhs_lag_lab_no_collision:CheckState()
	return { [MODIFIER_STATE_NO_UNIT_COLLISION] = true }
end

modifier_xhs_lag_lab_disarm = class(XHSLagLabModifierBase())
function modifier_xhs_lag_lab_disarm:CheckState()
	return { [MODIFIER_STATE_DISARMED] = true }
end

modifier_xhs_lag_lab_silence = class(XHSLagLabModifierBase())
function modifier_xhs_lag_lab_silence:CheckState()
	return { [MODIFIER_STATE_SILENCED] = true }
end

modifier_xhs_lag_lab_hidden = class(XHSLagLabModifierBase())
function modifier_xhs_lag_lab_hidden:CheckState()
	return { [MODIFIER_STATE_NO_HEALTH_BAR] = true }
end

function XHSLagLabIsActive(experimentID)
	return XHSLagLab ~= nil and XHSLagLab:IsActive(experimentID)
end

return XHSLagLab
