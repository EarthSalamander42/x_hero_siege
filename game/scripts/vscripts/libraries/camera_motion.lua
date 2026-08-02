--[[
	Server-authoritative camera motion for Dota 2 custom games.

	The camera always follows an invisible per-player dummy through
	PlayerResource:SetCameraTarget. Motion, queuing, easing and arrival state are
	implemented here; Panorama is only used as a read-only bridge to sample the
	player's actual camera position before a move and after rendered arrival.

	PORTING REQUIREMENTS:
	- Copy the `dummy_unit_invulnerable` unit KV and its
	  `dummy_passive_invulnerable` ability/modifier KV into the destination mod.
	- Copy and LinkLuaModifier the `modifier_provides_fow_position` Lua modifier.
	  It keeps the moving target networked through fog without granting terrain
	  vision; keep the dummy's day/night vision ranges at zero.
	- Load the accompanying `camera_motion.js` Panorama bridge and preserve (or rename on
	  both sides) the `camera_motion_origin_request/response` events.

	AI AGENTS: when exporting this library, do not omit those three integration
	pieces. The native info_target fallback can move a camera, but is less
	reliable when travelling through fog of war.
]]

local CameraMotion = _G.CameraMotion or {}
_G.CameraMotion = CameraMotion

CameraMotion.VERSION = "1.4.0"
CameraMotion.controllers = CameraMotion.controllers or {}
CameraMotion.serial = CameraMotion.serial or 0
CameraMotion.thinker_started = CameraMotion.thinker_started or false
CameraMotion.think_name = CameraMotion.think_name or "camera_motion_server_think"

CameraMotion.config = CameraMotion.config or {
	tick_interval = 0.03,
	max_delta = 0.25,
	default_profile = "cinematic",
	log = nil,
	dummy_factory = nil,
	origin_provider = nil,
	position_provider = nil,
	origin_timeout = 0.25,
	confirm_rendered_arrival_default = true,
}
CameraMotion.pending_origins = CameraMotion.pending_origins or {}
CameraMotion.origin_listener_registered =
	CameraMotion.origin_listener_registered or false

CameraMotion.presets = CameraMotion.presets or {
	instant = { duration = 0, easing = "linear" },
	snappy = { duration = 0.28, easing = "smootherstep" },
	fast = { duration = 0.55, easing = "smootherstep" },
	cinematic = { duration = 0.85, easing = "smootherstep" },
	slow = { duration = 1.6, easing = "smootherstep" },
}

local EASINGS = {
	linear = function(t) return t end,
	smoothstep = function(t) return t * t * (3 - 2 * t) end,
	smootherstep = function(t) return t * t * t * (t * (t * 6 - 15) + 10) end,
	ease_in = function(t) return t * t * t end,
	ease_out = function(t)
		local inverse = 1 - t
		return 1 - inverse * inverse * inverse
	end,
}

local function Log(message)
	local logger = CameraMotion.config.log
	if type(logger) == "function" then
		pcall(logger, message)
	end
end

local function Now()
	if GameRules ~= nil and GameRules.GetGameTime ~= nil then
		return GameRules:GetGameTime()
	end
	return 0
end

local function IsFinite(value)
	return type(value) == "number" and value == value and value > -math.huge and value < math.huge
end

local function IsVector(value)
	if value == nil then return false end
	local ok, x, y, z = pcall(function()
		return value.x, value.y, value.z
	end)
	return ok and IsFinite(x) and IsFinite(y) and IsFinite(z)
end

local function CopyVector(value)
	if not IsVector(value) then return nil end
	return Vector(value.x, value.y, value.z)
end

local function IsEntity(value)
	if value == nil then return false end
	local ok, result = pcall(function()
		return IsValidEntity(value) and not value:IsNull() and value.GetAbsOrigin ~= nil
	end)
	return ok and result == true
end

local function ResolveTarget(value, context)
	if type(value) == "function" then
		local ok, resolved = pcall(value, context)
		if not ok then return nil, "target resolver failed: " .. tostring(resolved) end
		value = resolved
	end
	if IsVector(value) then
		return CopyVector(value), nil, nil
	end
	if IsEntity(value) then
		return CopyVector(value:GetAbsOrigin()), nil, value
	end
	return nil, "target must resolve to a valid entity or Vector"
end

local function ValidPlayerID(playerID)
	playerID = tonumber(playerID)
	if playerID == nil then return nil end
	playerID = math.floor(playerID)
	if playerID < 0 then return nil end
	if PlayerResource ~= nil and PlayerResource.IsValidPlayerID ~= nil
		and not PlayerResource:IsValidPlayerID(playerID) then
		return nil
	end
	return playerID
end

local function SafeCallback(callback, result)
	if type(callback) ~= "function" then return end
	local ok, err = pcall(callback, result)
	if not ok then Log("callback failed: " .. tostring(err)) end
end

local function CopyOptions(options)
	local copy = {}
	for key, value in pairs(options or {}) do copy[key] = value end
	return copy
end

local function MergeMissing(target, source)
	for key, value in pairs(source or {}) do
		if target[key] == nil then target[key] = value end
	end
end

local function DefaultHero(playerID)
	if PlayerResource == nil or PlayerResource.GetSelectedHeroEntity == nil then return nil end
	local hero = PlayerResource:GetSelectedHeroEntity(playerID)
	return IsEntity(hero) and hero or nil
end

local function ResultFor(request, status, reason)
	return {
		status = status,
		reason = reason,
		player_id = request.player_id,
		owner = request.owner,
		request_id = request.id,
		position = request.controller and CopyVector(request.controller.position) or nil,
		destination = CopyVector(request.destination),
		elapsed = math.max(0, Now() - (request.started_at or Now())),
		duration = request.total_duration,
	}
end

local Handle = {}
Handle.__index = Handle

function Handle:IsActive()
	local request = self._request
	return request ~= nil and request.controller ~= nil and request.controller.active == request
end

function Handle:HasArrived()
	return self._request ~= nil and self._request.arrived == true
end

function Handle:GetState()
	local request = self._request
	if request == nil then return nil end
	local state = ResultFor(request, request.status or "pending", request.reason)
	state.stage = request.stage
	state.active = self:IsActive()
	return state
end

function Handle:GetPosition()
	local request = self._request
	return request and request.controller and CopyVector(request.controller.position) or nil
end

function Handle:GetRemainingTime()
	local request = self._request
	if request == nil or request.controller == nil then return nil end
	return CameraMotion:GetRemainingTime(request.player_id)
end

function Handle:Cancel(reason)
	local request = self._request
	if request == nil then return false end
	return CameraMotion:Cancel(request.player_id, reason or "handle_cancel", self)
end

local function MakeHandle(request)
	local handle = setmetatable({ _request = request }, Handle)
	request.handle = handle
	return handle
end

local function CreateDefaultDummy(position, playerID)
	-- info_target is a native engine entity rather than a KV unit. It is
	-- inherently invisible, non-selectable, non-colliding and damage-immune,
	-- while still supporting SetAbsOrigin and SetCameraTarget. Using it keeps
	-- the library independent from a custom npc_units definition.
	local dummy = SpawnEntityFromTableSynchronous("info_target", {
		targetname = "camera_motion_target_" .. tostring(playerID),
		origin = position,
	})
	if not IsEntity(dummy) then return nil end
	dummy:SetAbsOrigin(position)
	return dummy
end

local function IsFiniteCoordinate(value)
	value = tonumber(value)
	return value ~= nil and value == value and value > -100000 and value < 100000
end

local function CompletePendingOrigin(playerID, pending, origin, reason)
	if CameraMotion.pending_origins[playerID] ~= pending then return false end
	CameraMotion.pending_origins[playerID] = nil
	local ok, result = pcall(pending.callback, origin, reason)
	return ok and result == true
end

local function OnCameraOriginResponse(_, event)
	local playerID = event and math.floor(tonumber(event.PlayerID) or -1) or -1
	local pending = CameraMotion.pending_origins[playerID]
	if pending == nil then return end
	if tonumber(event.request_id) ~= pending.request_id
		or tonumber(event.origin_token) ~= pending.origin_token then
		return
	end

	if not IsFiniteCoordinate(event.x)
		or not IsFiniteCoordinate(event.y)
		or not IsFiniteCoordinate(event.z) then
		CompletePendingOrigin(playerID, pending, nil, "invalid_client_origin")
		return
	end

	CompletePendingOrigin(playerID, pending, Vector(
		tonumber(event.x),
		tonumber(event.y),
		tonumber(event.z)
	), "client_camera")
end

local function EnsureOriginListener()
	if CameraMotion.origin_listener_registered then return true end
	if CustomGameEventManager == nil
		or CustomGameEventManager.RegisterListener == nil then
		return false
	end
	CustomGameEventManager:RegisterListener(
		"camera_motion_origin_response",
		OnCameraOriginResponse
	)
	CameraMotion.origin_listener_registered = true
	return true
end

local function RequestClientCameraOrigin(playerID, context, callback)
	if not EnsureOriginListener() then return false end
	local player = PlayerResource:GetPlayer(playerID)
	if player == nil then return false end
	if PlayerResource.IsFakeClient ~= nil
		and PlayerResource:IsFakeClient(playerID) then
		return false
	end

	local previous = CameraMotion.pending_origins[playerID]
	if previous ~= nil then
		CompletePendingOrigin(
			playerID,
			previous,
			nil,
			"origin_request_superseded"
		)
	end

	local pending = {
		request_id = tonumber(context.request_id),
		origin_token = tonumber(context.origin_token),
		callback = callback,
	}
	CameraMotion.pending_origins[playerID] = pending
	CustomGameEventManager:Send_ServerToPlayer(
		player,
		"camera_motion_origin_request",
		{
			request_id = pending.request_id,
			origin_token = pending.origin_token,
		}
	)
	return true
end

local function CreateCameraDummy(position, playerID)
	local playerTeam = DOTA_TEAM_GOODGUYS
	if PlayerResource ~= nil
		and PlayerResource.GetTeam ~= nil
		and PlayerResource:IsValidPlayerID(playerID) then
		playerTeam = PlayerResource:GetTeam(playerID)
	end
	-- Observer-team units are not reliably networked as camera targets. Keep
	-- the invisible motion anchor on a playable team while the observer camera
	-- remains fully server-controlled through SetCameraTarget.
	if playerTeam == 1 or playerTeam == DOTA_TEAM_NOTEAM then
		playerTeam = DOTA_TEAM_GOODGUYS
	end

	local ok, dummy = pcall(
		CreateUnitByName,
		"dummy_unit_invulnerable",
		position,
		false,
		nil,
		nil,
		playerTeam
	)
	if not ok or not IsEntity(dummy) then
		Log(
			"dummy_unit_invulnerable is unavailable; using the less reliable "
				.. "native info_target fallback"
		)
		return CreateDefaultDummy(position, playerID)
	end

	local passive = dummy:FindAbilityByName("dummy_passive_invulnerable")
	if passive ~= nil and passive:GetLevel() < 1 then passive:SetLevel(1) end

	-- Never path-correct the anchor: its position is the mathematical camera
	-- trajectory, including over cliffs and other unpathable terrain.
	dummy:SetAbsOrigin(position)
	dummy:AddNoDraw()
	dummy:SetDayTimeVisionRange(0)
	dummy:SetNightTimeVisionRange(0)
	dummy:SetAcquisitionRange(0)
	dummy:AddNewModifier(dummy, nil, "modifier_invulnerable", {})

	-- The modifier only networks the dummy position through FoW. Zero vision
	-- ranges ensure it does not reveal the surrounding map.
	local modifierOk = pcall(function()
		dummy:AddNewModifier(
			dummy,
			nil,
			"modifier_provides_fow_position",
			{}
		)
	end)
	if not modifierOk then
		Log(
			"modifier_provides_fow_position is unavailable; camera travel "
				.. "through fog may be interrupted"
		)
	end
	return dummy
end

-- These reliable defaults used to live in a project adapter. They now make
-- the complete camera behavior available from this single Lua library.
if CameraMotion.config.dummy_factory == nil then
	CameraMotion.config.dummy_factory = CreateCameraDummy
end
if CameraMotion.config.origin_provider == nil then
	CameraMotion.config.origin_provider = RequestClientCameraOrigin
end
if CameraMotion.config.position_provider == nil then
	CameraMotion.config.position_provider = RequestClientCameraOrigin
end
if CameraMotion.config.confirm_rendered_arrival_default == nil then
	CameraMotion.config.confirm_rendered_arrival_default = true
end

function CameraMotion:_EnsureDummy(controller, position)
	if IsEntity(controller.dummy) then return controller.dummy end
	local factory = self.config.dummy_factory
	local dummy
	if type(factory) == "function" then
		local ok, result = pcall(factory, position, controller.player_id)
		if ok then dummy = result end
	else
		dummy = CreateDefaultDummy(position, controller.player_id)
	end
	if not IsEntity(dummy) then return nil, "unable to create camera dummy" end
	controller.dummy = dummy
	controller.position = CopyVector(position)
	return dummy
end

function CameraMotion:_Controller(playerID)
	local controller = self.controllers[playerID]
	if controller == nil then
		controller = {
			player_id = playerID,
			active = nil,
			queue = {},
			dummy = nil,
			position = nil,
			captured = false,
		}
		self.controllers[playerID] = controller
	end
	return controller
end

function CameraMotion:_SetPosition(controller, position)
	if not IsEntity(controller.dummy) or not IsVector(position) then return false end
	controller.dummy:SetAbsOrigin(position)
	controller.position = CopyVector(position)
	return true
end

function CameraMotion:_DiscardDummy(controller)
	local dummy = controller.dummy
	controller.dummy = nil
	controller.position = nil
	if IsEntity(dummy) and UTIL_Remove ~= nil then
		pcall(function() UTIL_Remove(dummy) end)
	end
end

function CameraMotion:_Capture(controller, origin)
	-- A released dummy can retain its last networked position on the client.
	-- Rebinding the camera after moving that same entity lets SetCameraTarget
	-- arrive before the position update, producing a one-frame snap to the old
	-- location. Start every fresh capture with a newly networked anchor whose
	-- creation baseline already contains the requested origin.
	if controller.captured ~= true and IsEntity(controller.dummy) then
		self:_DiscardDummy(controller)
	end
	local dummy, err = self:_EnsureDummy(controller, origin)
	if dummy == nil then return false, err end
	self:_SetPosition(controller, origin)
	PlayerResource:SetCameraTarget(controller.player_id, dummy)
	controller.captured = true
	return true
end

function CameraMotion:_EnsureThinker()
	if self.thinker_started then return end
	if GameRules == nil or GameRules.GetGameModeEntity == nil then return end
	self.thinker_started = true
	local mode = GameRules:GetGameModeEntity()
	mode:SetContextThink(self.think_name, function()
		local ok, err = pcall(function() self:_Think() end)
		if not ok then Log("think failed: " .. tostring(err)) end
		return math.max(0.01, tonumber(self.config.tick_interval) or 0.03)
	end, 0)
end

local function ValidatePolicy(policy)
	return policy == "replace" or policy == "queue" or policy == "reject"
end

function CameraMotion:_ResolveMotionOptions(options)
	options = CopyOptions(options)
	local requestedKinematic = options.max_speed ~= nil
		or options.acceleration ~= nil
		or options.deceleration ~= nil
	local presetName = options.profile or self.config.default_profile
	local preset = self.presets[presetName]
	if options.profile ~= nil and preset == nil then
		return nil, "unknown camera profile: " .. tostring(options.profile)
	end
	if requestedKinematic then
		for key, value in pairs(preset or {}) do
			if key ~= "duration" and options[key] == nil then options[key] = value end
		end
	else
		MergeMissing(options, preset)
	end

	options.policy = options.policy or "replace"
	if not ValidatePolicy(options.policy) then return nil, "invalid policy" end
	options.owner = tostring(options.owner or "anonymous")
	options.priority = tonumber(options.priority) or 0
	options.interruptible = options.interruptible ~= false
	options.target_mode = options.target_mode or "snapshot"
	if options.target_mode ~= "snapshot" and options.target_mode ~= "follow" then
		return nil, "invalid target_mode"
	end
	options.origin_mode = options.origin_mode or "auto"
	if options.origin_mode ~= "auto"
		and options.origin_mode ~= "provider"
		and options.origin_mode ~= "server" then
		return nil, "invalid origin_mode"
	end

	local hasKinematic = options.max_speed ~= nil
		or options.acceleration ~= nil
		or options.deceleration ~= nil
	if hasKinematic and options.duration ~= nil then
		return nil, "duration and kinematic parameters are mutually exclusive"
	end
	if hasKinematic then
		options.motion_mode = "kinematic"
		options.max_speed = tonumber(options.max_speed)
		options.acceleration = tonumber(options.acceleration)
		options.deceleration = tonumber(options.deceleration)
		options.initial_speed = tonumber(options.initial_speed) or 0
		options.final_speed = tonumber(options.final_speed) or 0
		if not IsFinite(options.max_speed) or options.max_speed <= 0 then return nil, "max_speed must be positive" end
		if not IsFinite(options.acceleration) or options.acceleration <= 0 then return nil, "acceleration must be positive" end
		if not IsFinite(options.deceleration) or options.deceleration <= 0 then return nil, "deceleration must be positive" end
	else
		options.motion_mode = "duration"
		options.duration = tonumber(options.duration) or 0
		if not IsFinite(options.duration) or options.duration < 0 then return nil, "duration must be non-negative" end
		if type(options.easing) == "function" then
			options.easing_function = options.easing
		else
			options.easing_function = EASINGS[options.easing or "smootherstep"]
		end
		if type(options.easing_function) ~= "function" then return nil, "invalid easing" end
	end

	options.hold = tonumber(options.hold) or 0
	options.arrival_epsilon = math.max(0, tonumber(options.arrival_epsilon) or 1)
	options.settle_time = math.max(0, tonumber(options.settle_time) or 0.06)
	if options.confirm_rendered_arrival == nil then
		options.confirm_rendered_arrival =
			self.config.confirm_rendered_arrival_default == true
	else
		options.confirm_rendered_arrival = options.confirm_rendered_arrival == true
	end
	options.rendered_arrival_epsilon = math.max(
		0,
		tonumber(options.rendered_arrival_epsilon) or 96
	)
	options.rendered_arrival_timeout = math.max(
		0.1,
		tonumber(options.rendered_arrival_timeout) or 5
	)
	options.rendered_arrival_interval = math.max(
		0.03,
		tonumber(options.rendered_arrival_interval) or 0.10
	)
	options.rendered_arrival_samples = math.max(
		1,
		math.floor(tonumber(options.rendered_arrival_samples) or 1)
	)
	return options
end

local function BuildKinematicProfile(distance, options)
	if distance <= 0 then
		return {
			total_time = 0,
			accel_time = 0,
			cruise_time = 0,
			decel_time = 0,
			peak_speed = 0,
			accel_distance = 0,
			cruise_distance = 0,
		}
	end
	local acceleration = options.acceleration
	local deceleration = options.deceleration
	local initialSpeed = math.max(0, options.initial_speed)
	local finalSpeed = math.max(0, options.final_speed)
	local maxSpeed = math.max(options.max_speed, initialSpeed, finalSpeed)
	local accelDistance = math.max(0, (maxSpeed * maxSpeed - initialSpeed * initialSpeed) / (2 * acceleration))
	local decelDistance = math.max(0, (maxSpeed * maxSpeed - finalSpeed * finalSpeed) / (2 * deceleration))
	local peakSpeed = maxSpeed
	local cruiseDistance = distance - accelDistance - decelDistance

	if cruiseDistance < 0 then
		local numerator = 2 * acceleration * deceleration * distance
			+ deceleration * initialSpeed * initialSpeed
			+ acceleration * finalSpeed * finalSpeed
		peakSpeed = math.sqrt(math.max(0, numerator / (acceleration + deceleration)))
		accelDistance = math.max(0, (peakSpeed * peakSpeed - initialSpeed * initialSpeed) / (2 * acceleration))
		decelDistance = math.max(0, distance - accelDistance)
		cruiseDistance = 0
	end

	local accelTime = math.max(0, (peakSpeed - initialSpeed) / acceleration)
	local cruiseTime = peakSpeed > 0 and cruiseDistance / peakSpeed or 0
	local decelTime = math.max(0, (peakSpeed - finalSpeed) / deceleration)
	return {
		total_time = accelTime + cruiseTime + decelTime,
		accel_time = accelTime,
		cruise_time = cruiseTime,
		decel_time = decelTime,
		peak_speed = peakSpeed,
		accel_distance = accelDistance,
		cruise_distance = cruiseDistance,
		decel_distance = decelDistance,
		initial_speed = initialSpeed,
		final_speed = finalSpeed,
		acceleration = acceleration,
		deceleration = deceleration,
	}
end

local function KinematicDistance(profile, elapsed)
	if elapsed <= profile.accel_time then
		return profile.initial_speed * elapsed + 0.5 * profile.acceleration * elapsed * elapsed
	end
	elapsed = elapsed - profile.accel_time
	if elapsed <= profile.cruise_time then
		return profile.accel_distance + profile.peak_speed * elapsed
	end
	elapsed = math.min(profile.decel_time, elapsed - profile.cruise_time)
	return profile.accel_distance + profile.cruise_distance
		+ profile.peak_speed * elapsed - 0.5 * profile.deceleration * elapsed * elapsed
end

function CameraMotion:_PrepareMove(request, destination, options, firstMove)
	local context = { player_id = request.player_id, request = request, controller = request.controller }
	local target, err, entity = ResolveTarget(destination, context)
	if target == nil then return false, err end

	local origin
	if firstMove then
		local from = options.from
		if from == nil and request.controller.captured then from = request.controller.position end
		if from == nil then from = DefaultHero(request.player_id) end
		origin, err = ResolveTarget(from, context)
		if origin == nil then return false, "first camera capture needs a server-known origin: " .. tostring(err) end
		local captured
		captured, err = self:_Capture(request.controller, origin)
		if not captured then return false, err end
	else
		origin = CopyVector(request.controller.position)
	end

	request.origin = origin
	request.destination_source = destination
	request.destination_entity = entity
	request.destination = target
	request.target_mode = options.target_mode
	request.options = options
	request.stage = "moving"
	request.status = "moving"
	request.stage_started_at = Now()
	request.started_at = request.started_at or request.stage_started_at
	request.arrived = false
	request.settled_at = nil
	request.distance = (target - origin):Length()
	request.direction = request.distance > 0 and (target - origin):Normalized() or Vector(0, 0, 0)

	if options.motion_mode == "kinematic" then
		request.kinematic = BuildKinematicProfile(request.distance, options)
		request.total_duration = request.kinematic.total_time
	else
		request.kinematic = nil
		request.total_duration = options.duration
	end
	return true
end

function CameraMotion:_ShouldRequestOrigin(request, options, firstMove)
	if options.origin_mode == "server" then return false end
	if type(self.config.origin_provider) ~= "function" then return false end
	if options.origin_mode == "provider" then return true end
	return firstMove and not request.controller.captured
end

function CameraMotion:_ResumeAwaitingOrigin(request, origin, reason, token)
	if request == nil or request.finished or request.controller.active ~= request then return false end
	if request.stage ~= "awaiting_origin" or request.origin_token ~= token then return false end

	local destination = request.awaiting_destination
	local options = request.awaiting_options
	request.awaiting_destination = nil
	request.awaiting_options = nil
	request.origin_deadline = nil
	request.origin_reason = reason

	if origin ~= nil and IsVector(origin) then
		options = CopyOptions(options)
		options.from = origin
	elseif origin ~= nil then
		request.origin_reason = "invalid_provider_origin"
	end

	local ok, err = self:_PrepareMove(request, destination, options, true)
	if not ok then
		self:_CancelRequest(request, "camera origin resume failed: " .. tostring(err))
		return false
	end
	return true
end

function CameraMotion:_BeginMove(request, destination, options, firstMove)
	if not self:_ShouldRequestOrigin(request, options, firstMove) then
		return self:_PrepareMove(request, destination, options, firstMove)
	end

	request.origin_token = (request.origin_token or 0) + 1
	local token = request.origin_token
	local timeout = math.max(0.01, tonumber(options.origin_timeout)
		or tonumber(self.config.origin_timeout) or 0.25)
	request.stage = "awaiting_origin"
	request.status = "awaiting_origin"
	request.options = options
	request.awaiting_destination = destination
	request.awaiting_options = options
	request.origin_deadline = Now() + timeout

	local provider = self.config.origin_provider
	local callback = function(origin, reason)
		return self:_ResumeAwaitingOrigin(request, origin, reason or "provider", token)
	end
	local ok, accepted = pcall(provider, request.player_id, {
		request_id = request.id,
		origin_token = token,
		timeout = timeout,
		fallback = options.from,
		owner = request.owner,
	}, callback)
	if not ok or accepted == false then
		return self:_ResumeAwaitingOrigin(
			request,
			nil,
			ok and "provider_unavailable" or ("provider_error: " .. tostring(accepted)),
			token
		)
	end
	return true
end

function CameraMotion:_FinishRequest(request, status, reason)
	if request.finished then return end
	request.finished = true
	request.status = status
	request.reason = reason
	local controller = request.controller
	if controller.active == request then controller.active = nil end
	local result = ResultFor(request, status, reason)
	local callbacks = request.root_options or request.options
	if status == "cancelled" then
		SafeCallback(callbacks and callbacks.on_cancel, result)
	else
		SafeCallback(callbacks and callbacks.on_complete, result)
	end
	self:_StartNext(controller)
end

function CameraMotion:_CancelRequest(request, reason)
	if request == nil or request.finished then return false end
	self:_FinishRequest(request, "cancelled", reason or "cancelled")
	return true
end

function CameraMotion:_ApplyRelease(controller, release, request)
	if release == nil or release == false or release == "keep" then return end
	if release == true or release == "free" then
		PlayerResource:SetCameraTarget(controller.player_id, nil)
		controller.captured = false
		self:_DiscardDummy(controller)
		return
	end
	local target = release
	if type(release) == "table" and not IsVector(release) then
		target = release.target
	end
	if type(target) == "function" then
		local ok, resolved = pcall(target, {
			player_id = controller.player_id,
			request = request,
			controller = controller,
		})
		if ok then target = resolved else target = nil end
	end
	if IsEntity(target) then
		PlayerResource:SetCameraTarget(controller.player_id, target)
		controller.captured = false
	else
		PlayerResource:SetCameraTarget(controller.player_id, nil)
		controller.captured = false
	end
	self:_DiscardDummy(controller)
end

function CameraMotion:_FinalizeArrival(request, confirmationReason)
	if request.arrived then return end
	request.arrived = true
	request.arrived_at = Now()
	request.rendered_arrival_reason = confirmationReason
	request.status = "arrived"
	self:_SetPosition(request.controller, request.destination)
	SafeCallback(request.options.on_arrive, ResultFor(request, "arrived", nil))
	if request.options.persistent == true then
		-- Arrival confirmation temporarily changes the stage. Persistent follows
		-- must resume their moving-target updates once the rendered camera has
		-- caught the dummy; static persistent shots remain locked.
		request.stage = request.target_mode == "follow" and "moving" or "locked"
		return
	end
	if request.options.hold > 0 then
		request.stage = "holding"
		request.stage_started_at = Now()
		return
	end
	self:_CompleteStep(request)
end

function CameraMotion:_RequestRenderedArrivalSample(request)
	if request == nil
		or request.finished
		or request.stage ~= "confirming_rendered_arrival"
		or request.rendered_arrival_in_flight == true then
		return
	end

	local provider = self.config.position_provider or self.config.origin_provider
	if type(provider) ~= "function" then
		self:_FinalizeArrival(request, "position_provider_unavailable")
		return
	end

	-- Continue after the origin-handshake token so a very late origin response
	-- cannot be mistaken for the first rendered-arrival sample.
	request.rendered_arrival_token =
		(request.rendered_arrival_token or request.origin_token or 0) + 1
	local token = request.rendered_arrival_token
	request.rendered_arrival_in_flight = true

	local callback = function(position, reason)
		if request == nil
			or request.finished
			or request.controller.active ~= request
			or request.stage ~= "confirming_rendered_arrival"
			or request.rendered_arrival_token ~= token then
			return false
		end

		request.rendered_arrival_in_flight = false
		request.rendered_arrival_position = IsVector(position) and CopyVector(position) or nil
		request.rendered_arrival_last_reason = reason
		request.rendered_arrival_next_sample = Now()
			+ request.options.rendered_arrival_interval

		if IsVector(position) then
			local distance = (position - request.destination):Length2D()
			request.rendered_arrival_distance = distance
			if distance <= request.options.rendered_arrival_epsilon then
				request.rendered_arrival_sample_count =
					(request.rendered_arrival_sample_count or 0) + 1
				if request.rendered_arrival_sample_count
					>= request.options.rendered_arrival_samples then
					self:_FinalizeArrival(request, "rendered_camera_arrived")
				end
			else
				request.rendered_arrival_sample_count = 0
			end
		else
			request.rendered_arrival_sample_count = 0
		end
		return true
	end

	local ok, accepted = pcall(provider, request.player_id, {
		request_id = request.id,
		origin_token = token,
		timeout = request.options.rendered_arrival_interval,
		fallback = nil,
		owner = request.owner,
		purpose = "rendered_arrival",
	}, callback)
	if not ok or accepted == false then
		request.rendered_arrival_in_flight = false
		-- Fake clients and mods without a position provider reject immediately.
		-- Their server camera request must not stall every sequence until the
		-- rendered-arrival timeout.
		self:_FinalizeArrival(
			request,
			ok and "position_provider_rejected" or "position_provider_error"
		)
	end
end

function CameraMotion:_Arrive(request)
	if request.arrived or request.stage == "confirming_rendered_arrival" then return end
	self:_SetPosition(request.controller, request.destination)

	if request.options.confirm_rendered_arrival == true then
		local provider = self.config.position_provider or self.config.origin_provider
		if type(provider) == "function" then
			request.status = "confirming_rendered_arrival"
			request.stage = "confirming_rendered_arrival"
			request.rendered_arrival_started_at = Now()
			request.rendered_arrival_deadline = Now()
				+ request.options.rendered_arrival_timeout
			request.rendered_arrival_next_sample = Now()
			request.rendered_arrival_sample_count = 0
			request.rendered_arrival_in_flight = false
			self:_RequestRenderedArrivalSample(request)
			return
		end
	end

	self:_FinalizeArrival(request, "dummy_arrived")
end

function CameraMotion:_CompleteStep(request)
	if request.sequence ~= nil then
		request.sequence_index = request.sequence_index + 1
		self:_StartSequenceStep(request)
		return
	end
	self:_ApplyRelease(request.controller, request.options.release, request)
	self:_FinishRequest(request, "completed", nil)
end

function CameraMotion:_StartSequenceStep(request)
	local step = request.sequence[request.sequence_index]
	if step == nil then
		self:_ApplyRelease(request.controller, request.root_options.release, request)
		self:_FinishRequest(request, "completed", nil)
		return
	end
	local stepType = step.type or "move"
	if stepType == "move" or stepType == "return" then
		local options, err = self:_ResolveMotionOptions(step)
		if options == nil then
			self:_CancelRequest(request, "invalid sequence step: " .. tostring(err))
			return
		end
		options.owner = request.owner
		options.priority = request.priority
		options.on_arrive = step.on_arrive
		options.on_complete = nil
		options.on_cancel = nil
		options.release = nil
		local destination = step.to or step.target
		local ok
		ok, err = self:_BeginMove(request, destination, options, not request.controller.captured)
		if not ok then self:_CancelRequest(request, "sequence move failed: " .. tostring(err)) end
	elseif stepType == "hold" then
		request.stage = "holding"
		request.stage_started_at = Now()
		request.options = CopyOptions(request.options)
		request.options.hold = math.max(0, tonumber(step.duration) or 0)
	elseif stepType == "call" then
		SafeCallback(step.callback, ResultFor(request, "step", nil))
		request.sequence_index = request.sequence_index + 1
		self:_StartSequenceStep(request)
	elseif stepType == "release" then
		self:_ApplyRelease(request.controller, step.mode or "free", request)
		request.sequence_index = request.sequence_index + 1
		self:_StartSequenceStep(request)
	else
		self:_CancelRequest(request, "unknown sequence step: " .. tostring(stepType))
	end
end

function CameraMotion:_StartRequest(controller, request)
	controller.active = request
	request.controller = controller
	request.status = "active"
	request.started_at = Now()
	if request.sequence ~= nil then
		request.sequence_index = 1
		self:_StartSequenceStep(request)
		return true
	end
	local ok, err = self:_BeginMove(request, request.destination_source, request.options, not controller.captured)
	if not ok then
		controller.active = nil
		request.finished = true
		request.status = "cancelled"
		request.reason = err
		local callbacks = request.root_options or request.options
		SafeCallback(callbacks and callbacks.on_cancel, ResultFor(request, "cancelled", err))
		self:_StartNext(controller)
		return false, err
	end
	return true
end

function CameraMotion:_StartNext(controller)
	if controller.active ~= nil or #controller.queue == 0 then return end
	local nextRequest = table.remove(controller.queue, 1)
	self:_StartRequest(controller, nextRequest)
end

function CameraMotion:_Submit(playerID, request)
	local controller = self:_Controller(playerID)
	request.player_id = playerID
	request.controller = controller
	local active = controller.active
	if active ~= nil then
		local canPreempt = active.interruptible and request.priority >= active.priority
		if request.policy == "queue" then
			table.insert(controller.queue, request)
			request.status = "queued"
			return request.handle
		end
		if request.policy == "reject" or not canPreempt then
			request.finished = true
			request.status = "rejected"
			request.reason = "camera owned by " .. tostring(active.owner)
			SafeCallback(request.options.on_cancel, ResultFor(request, "rejected", request.reason))
			return nil, request.reason
		end
		-- Detach before cancellation so the cancelled request cannot auto-start a
		-- queued request ahead of the replacement.
		controller.active = nil
		active.finished = true
		active.status = "cancelled"
		active.reason = "replaced by " .. request.owner
		local callbacks = active.root_options or active.options
		SafeCallback(callbacks and callbacks.on_cancel, ResultFor(active, "cancelled", active.reason))
	end
	local ok, err = self:_StartRequest(controller, request)
	if not ok then return nil, err end
	self:_EnsureThinker()
	return request.handle
end

function CameraMotion:Move(playerID, destination, options)
	playerID = ValidPlayerID(playerID)
	if playerID == nil then return nil, "invalid player ID" end
	local resolvedOptions, err = self:_ResolveMotionOptions(options)
	if resolvedOptions == nil then return nil, err end
	self.serial = self.serial + 1
	local request = {
		id = self.serial,
		owner = resolvedOptions.owner,
		priority = resolvedOptions.priority,
		interruptible = resolvedOptions.interruptible,
		policy = resolvedOptions.policy,
		options = resolvedOptions,
		destination_source = destination,
	}
	MakeHandle(request)
	return self:_Submit(playerID, request)
end

function CameraMotion:Follow(playerID, entity, options)
	options = CopyOptions(options)
	options.target_mode = "follow"
	options.persistent = options.persistent ~= false
	if options.duration == nil and options.max_speed == nil then
		options.duration = 0
	end
	return self:Move(playerID, entity, options)
end

function CameraMotion:Return(playerID, destination, options)
	options = CopyOptions(options)
	options.owner = options.owner or "camera_return"
	if options.release == nil then options.release = "free" end
	return self:Move(playerID, destination, options)
end

function CameraMotion:Sequence(playerID, steps, options)
	playerID = ValidPlayerID(playerID)
	if playerID == nil then return nil, "invalid player ID" end
	if type(steps) ~= "table" or #steps == 0 then return nil, "sequence needs at least one step" end
	local resolvedOptions, err = self:_ResolveMotionOptions(options)
	if resolvedOptions == nil then return nil, err end
	self.serial = self.serial + 1
	local request = {
		id = self.serial,
		owner = resolvedOptions.owner,
		priority = resolvedOptions.priority,
		interruptible = resolvedOptions.interruptible,
		policy = resolvedOptions.policy,
		options = resolvedOptions,
		root_options = resolvedOptions,
		sequence = steps,
	}
	MakeHandle(request)
	return self:_Submit(playerID, request)
end

function CameraMotion:MoveAll(playerIDs, destination, options)
	local handles = {}
	for _, playerID in pairs(playerIDs or {}) do
		local handle, err = self:Move(playerID, destination, options)
		handles[playerID] = handle or { error = err }
	end
	return handles
end

function CameraMotion:Cancel(playerID, reason, ownerOrHandle)
	playerID = ValidPlayerID(playerID)
	if playerID == nil then return false end
	local controller = self.controllers[playerID]
	if controller == nil or controller.active == nil then return false end
	local request = controller.active
	if type(ownerOrHandle) == "string" and request.owner ~= ownerOrHandle then return false end
	if type(ownerOrHandle) == "table" and ownerOrHandle ~= request.handle then return false end
	return self:_CancelRequest(request, reason or "cancelled")
end

function CameraMotion:Release(playerID, options)
	playerID = ValidPlayerID(playerID)
	if playerID == nil then return false end
	options = options or {}
	local controller = self:_Controller(playerID)
	local active = controller.active
	if active ~= nil then
		if options.owner ~= nil and active.owner ~= options.owner then return false end
		controller.active = nil
		active.finished = true
		active.status = "cancelled"
		active.reason = options.reason or "released"
		local callbacks = active.root_options or active.options
		SafeCallback(callbacks and callbacks.on_cancel, ResultFor(active, "cancelled", active.reason))
	end
	if options.clear_queue ~= false then controller.queue = {} end
	self:_ApplyRelease(controller, options.target or options.mode or "free", active)
	return true
end

function CameraMotion:IsControlled(playerID)
	local controller = self.controllers[tonumber(playerID)]
	return controller ~= nil and controller.captured == true
end

-- PlayerResource:ReplaceHeroWith may reset the engine camera target even
-- while a persistent request is still logically locked. Reasserting the
-- existing dummy keeps the cinematic at its current position without
-- restarting or replacing the active motion.
function CameraMotion:RefreshTarget(playerID, owner)
	playerID = ValidPlayerID(playerID)
	if playerID == nil then return false end
	local controller = self.controllers[playerID]
	if controller == nil or not controller.captured or not IsEntity(controller.dummy) then
		return false
	end
	if owner ~= nil
		and controller.active ~= nil
		and controller.active.owner ~= owner then
		return false
	end
	PlayerResource:SetCameraTarget(playerID, controller.dummy)
	return true
end

function CameraMotion:IsMoving(playerID)
	local controller = self.controllers[tonumber(playerID)]
	return controller ~= nil and controller.active ~= nil and controller.active.stage == "moving"
end

function CameraMotion:HasArrived(playerID, handle)
	local controller = self.controllers[tonumber(playerID)]
	if controller == nil then return false end
	local request = handle and handle._request or controller.active
	return request ~= nil and request.arrived == true
end

function CameraMotion:GetPosition(playerID)
	local controller = self.controllers[tonumber(playerID)]
	return controller and CopyVector(controller.position) or nil
end

function CameraMotion:GetState(playerID)
	local controller = self.controllers[tonumber(playerID)]
	if controller == nil then return nil end
	if controller.active == nil then
		return {
			player_id = controller.player_id,
			active = false,
			captured = controller.captured,
			position = CopyVector(controller.position),
			queued = #controller.queue,
		}
	end
	local state = controller.active.handle:GetState()
	state.captured = controller.captured
	state.queued = #controller.queue
	return state
end

function CameraMotion:GetRemainingTime(playerID)
	local controller = self.controllers[tonumber(playerID)]
	local request = controller and controller.active or nil
	if request == nil then return nil end
	if request.stage == "holding" then
		return math.max(0, (request.options.hold or 0) - (Now() - request.stage_started_at))
	end
	if request.stage ~= "moving" or request.total_duration == nil then return nil end
	return math.max(0, request.total_duration - (Now() - request.stage_started_at))
end

function CameraMotion:Configure(options)
	for key, value in pairs(options or {}) do
		if key == "presets" and type(value) == "table" then
			for presetName, preset in pairs(value) do self.presets[presetName] = CopyOptions(preset) end
		else
			self.config[key] = value
		end
	end
	return self
end

local function DebugCommandPlayerID(...)
	for index = 1, select("#", ...) do
		local candidate = tonumber(select(index, ...))
		if candidate ~= nil and candidate >= 0 then return math.floor(candidate) end
	end
	return 0
end

function CameraMotion:RegisterDebugCommands()
	if self.debug_commands_registered or Convars == nil or Convars.RegisterCommand == nil then return false end
	self.debug_commands_registered = true

	Convars:RegisterCommand("camera_motion_status", function(...)
		local playerID = DebugCommandPlayerID(...)
		local state = self:GetState(playerID)
		if state == nil then
			print("[CameraMotion][Status] player=" .. tostring(playerID) .. " controller=none")
			return
		end
		print(
			"[CameraMotion][Status] player=" .. tostring(playerID)
			.. " active=" .. tostring(state.active)
			.. " captured=" .. tostring(state.captured)
			.. " stage=" .. tostring(state.stage)
			.. " owner=" .. tostring(state.owner)
			.. " request=" .. tostring(state.request_id)
			.. " queued=" .. tostring(state.queued)
		)
	end, "Print the server camera controller state for a player ID.", FCVAR_CHEAT)

	Convars:RegisterCommand("camera_motion_smoke", function(...)
		local playerID = DebugCommandPlayerID(...)
		local hero = DefaultHero(playerID)
		if not IsEntity(hero) then
			print("[CameraMotion][Smoke] FAIL player=" .. tostring(playerID) .. " reason=no selected hero")
			return
		end
		local origin = CopyVector(hero:GetAbsOrigin())
		print("[CameraMotion][Smoke] START player=" .. tostring(playerID))
		local _, err = self:Sequence(playerID, {
			{
				type = "move",
				to = origin + Vector(700, 0, 0),
				from = hero,
				duration = 0.8,
				easing = "smootherstep",
				on_arrive = function(result)
					print("[CameraMotion][Smoke] OUTBOUND_ARRIVED request=" .. tostring(result.request_id))
				end,
			},
			{ type = "hold", duration = 0.4 },
			{
				type = "return",
				to = function() return DefaultHero(playerID) end,
				duration = 0.8,
				easing = "smootherstep",
				on_arrive = function(result)
					print("[CameraMotion][Smoke] RETURN_ARRIVED request=" .. tostring(result.request_id))
				end,
			},
			{ type = "release", mode = "free" },
		}, {
			owner = "camera_motion_smoke",
			priority = 1000,
			policy = "replace",
			on_complete = function(result)
				print("[CameraMotion][Smoke] PASS request=" .. tostring(result.request_id))
			end,
			on_cancel = function(result)
				print("[CameraMotion][Smoke] FAIL request=" .. tostring(result.request_id)
					.. " reason=" .. tostring(result.reason))
			end,
		})
		if err ~= nil then print("[CameraMotion][Smoke] FAIL submit=" .. tostring(err)) end
	end, "Run an outbound/hold/return/release server camera smoke test.", FCVAR_CHEAT)

	return true
end

function CameraMotion:_UpdateMoving(request, now)
	local controller = request.controller
	if not IsEntity(controller.dummy) then
		self:_CancelRequest(request, "camera dummy became invalid")
		return
	end

	if request.target_mode == "follow" then
		local target, err = ResolveTarget(request.destination_source, {
			player_id = request.player_id,
			request = request,
			controller = controller,
		})
		if target == nil then
			local behavior = request.options.invalid_target or "cancel"
			if behavior == "last_position" then
				target = request.destination
			elseif behavior == "release" then
				self:_ApplyRelease(controller, "free", request)
				self:_CancelRequest(request, err)
				return
			else
				self:_CancelRequest(request, err)
				return
			end
		end
		request.destination = target
		if request.options.motion_mode == "kinematic" then
			local delta = math.max(0, math.min(
				tonumber(self.config.max_delta) or 0.25,
				now - (request.last_update_at or now)
			))
			request.last_update_at = now
			local offset = target - controller.position
			local distance = offset:Length()
			local desiredSpeed = math.min(
				request.options.max_speed,
				math.sqrt(math.max(0, 2 * request.options.deceleration * distance))
			)
			local speed = request.follow_speed or request.options.initial_speed
			if desiredSpeed > speed then
				speed = math.min(desiredSpeed, speed + request.options.acceleration * delta)
			else
				speed = math.max(desiredSpeed, speed - request.options.deceleration * delta)
			end
			request.follow_speed = speed
			local traveled = math.min(distance, speed * delta)
			if distance > 0 then
				self:_SetPosition(controller, controller.position + offset:Normalized() * traveled)
			end
		elseif request.options.duration == 0 then
			self:_SetPosition(controller, target)
			request.distance = 0
		else
			local elapsed = math.max(0, now - request.stage_started_at)
			local progress = request.total_duration > 0 and math.min(1, elapsed / request.total_duration) or 1
			local eased = request.options.easing_function(progress)
			self:_SetPosition(controller, request.origin + (target - request.origin) * eased)
		end
		local distance = (target - controller.position):Length()
		if distance <= request.options.arrival_epsilon then
			request.settled_at = request.settled_at or now
			if now - request.settled_at >= request.options.settle_time and not request.arrived then
				request.destination = target
				self:_Arrive(request)
			end
		else
			request.settled_at = nil
		end
		local lockDuration = tonumber(request.options.lock_duration)
		if request.arrived and lockDuration ~= nil and lockDuration >= 0
			and now - (request.arrived_at or now) >= lockDuration then
			request.options.persistent = false
			self:_CompleteStep(request)
		end
		return
	end

	local elapsed = math.max(0, now - request.stage_started_at)
	if request.total_duration <= 0 or elapsed >= request.total_duration then
		self:_Arrive(request)
		return
	end

	local progress
	if request.kinematic ~= nil then
		local traveled = KinematicDistance(request.kinematic, elapsed)
		progress = request.distance > 0 and math.min(1, traveled / request.distance) or 1
	else
		progress = math.min(1, math.max(0, request.options.easing_function(elapsed / request.total_duration)))
	end
	self:_SetPosition(controller, request.origin + (request.destination - request.origin) * progress)
end

function CameraMotion:_Think()
	local now = Now()
	for _, controller in pairs(self.controllers) do
		local request = controller.active
		if request ~= nil and not request.finished then
			if request.stage == "moving" then
				self:_UpdateMoving(request, now)
			elseif request.stage == "awaiting_origin" then
				if now >= (request.origin_deadline or now) then
					self:_ResumeAwaitingOrigin(
						request,
						nil,
						"provider_timeout",
						request.origin_token
					)
				end
			elseif request.stage == "confirming_rendered_arrival" then
				if now >= (request.rendered_arrival_deadline or now) then
					self:_FinalizeArrival(request, "rendered_arrival_timeout")
				elseif request.rendered_arrival_in_flight ~= true
					and now >= (request.rendered_arrival_next_sample or now) then
					self:_RequestRenderedArrivalSample(request)
				end
			elseif request.stage == "holding" then
				if now - request.stage_started_at >= (request.options.hold or 0) then
					self:_CompleteStep(request)
				end
			end
		end
	end
end

function CameraMotion:Shutdown()
	for playerID, controller in pairs(self.controllers) do
		pcall(function() PlayerResource:SetCameraTarget(playerID, nil) end)
		if IsEntity(controller.dummy) then pcall(function() UTIL_Remove(controller.dummy) end) end
	end
	self.controllers = {}
	self.thinker_started = false
	if GameRules ~= nil and GameRules.GetGameModeEntity ~= nil then
		pcall(function() GameRules:GetGameModeEntity():SetContextThink(self.think_name, nil, 0) end)
	end
end

return CameraMotion
