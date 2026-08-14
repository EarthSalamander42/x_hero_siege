if XHSBotDangerRegistry == nil then
	XHSBotDangerRegistry = {}
end

XHSBotDangerRegistry.enabled = false
XHSBotDangerRegistry.entries = {}
XHSBotDangerRegistry.next_id = 1

local function Now()
	if GameRules ~= nil and GameRules.GetGameTime ~= nil then
		return GameRules:GetGameTime()
	end
	return 0
end

local function IsVector(value)
	return value ~= nil and value.x ~= nil and value.y ~= nil
end

local function Distance2D(a, b)
	local dx = a.x - b.x
	local dy = a.y - b.y
	return math.sqrt(dx * dx + dy * dy)
end

local function DistanceToSegment(point, startPosition, endPosition)
	local vx = endPosition.x - startPosition.x
	local vy = endPosition.y - startPosition.y
	local wx = point.x - startPosition.x
	local wy = point.y - startPosition.y
	local lengthSquared = vx * vx + vy * vy
	if lengthSquared <= 0.001 then
		return Distance2D(point, startPosition)
	end

	local t = math.max(0, math.min(1, (wx * vx + wy * vy) / lengthSquared))
	local closest = {
		x = startPosition.x + vx * t,
		y = startPosition.y + vy * t,
	}
	return Distance2D(point, closest)
end

local function Normalize2D(direction)
	local length = math.sqrt(direction.x * direction.x + direction.y * direction.y)
	if length <= 0.001 then
		return { x = 1, y = 0 }
	end
	return { x = direction.x / length, y = direction.y / length }
end

function XHSBotDangerRegistry:SetEnabled(enabled)
	self.enabled = enabled == true
	if not self.enabled then
		self:Clear()
	end
end

function XHSBotDangerRegistry:Clear()
	self.entries = {}
	self.next_id = 1
end

function XHSBotDangerRegistry:Add(definition)
	if self.enabled ~= true or type(definition) ~= "table" then return nil end

	local shape = tostring(definition.shape or "circle")
	local origin = definition.position or definition.origin or definition.start_position
	if not IsVector(origin) then return nil end

	local currentTime = Now()
	local entry = {
		id = self.next_id,
		shape = shape,
		position = definition.position or definition.origin,
		start_position = definition.start_position,
		end_position = definition.end_position,
		direction = definition.direction,
		radius = math.max(1, tonumber(definition.radius) or 180),
		length = math.max(1, tonumber(definition.length) or 1),
		angle = math.max(1, tonumber(definition.angle) or 45),
		starts_at = tonumber(definition.starts_at) or currentTime,
		activates_at = tonumber(definition.activates_at) or currentTime,
		expires_at = tonumber(definition.expires_at) or (currentTime + 1),
		severity = math.max(0, math.min(1, tonumber(definition.severity) or 1)),
		source = definition.source,
		label = tostring(definition.label or "boss_telegraph"),
		follow_entindex = tonumber(definition.follow_entindex),
	}

	self.next_id = self.next_id + 1
	self.entries[entry.id] = entry
	return entry.id
end

function XHSBotDangerRegistry:AddCircle(position, radius, duration, options)
	options = options or {}
	local currentTime = Now()
	local telegraphDuration = math.max(0.05, tonumber(duration) or 1)
	return self:Add({
		shape = "circle",
		position = position,
		radius = radius,
		starts_at = currentTime,
		activates_at = options.activates_at or (currentTime + telegraphDuration),
		expires_at = options.expires_at or (currentTime + telegraphDuration + 0.45),
		severity = options.severity,
		source = options.source,
		label = options.label,
		follow_entindex = options.follow_entindex,
	})
end

function XHSBotDangerRegistry:AddLine(startPosition, endPosition, radius, duration, options)
	options = options or {}
	local currentTime = Now()
	local telegraphDuration = math.max(0.05, tonumber(duration) or 1)
	return self:Add({
		shape = "line",
		start_position = startPosition,
		end_position = endPosition,
		radius = radius,
		starts_at = currentTime,
		activates_at = options.activates_at or (currentTime + telegraphDuration),
		expires_at = options.expires_at or (currentTime + telegraphDuration + 0.45),
		severity = options.severity,
		source = options.source,
		label = options.label,
	})
end

function XHSBotDangerRegistry:AddCone(origin, direction, length, angle, duration, options)
	options = options or {}
	local currentTime = Now()
	local telegraphDuration = math.max(0.05, tonumber(duration) or 1)
	return self:Add({
		shape = "cone",
		origin = origin,
		direction = direction,
		length = length,
		angle = angle,
		starts_at = currentTime,
		activates_at = options.activates_at or (currentTime + telegraphDuration),
		expires_at = options.expires_at or (currentTime + telegraphDuration + 0.45),
		severity = options.severity,
		source = options.source,
		label = options.label,
	})
end

function XHSBotDangerRegistry:Prune(currentTime)
	currentTime = tonumber(currentTime) or Now()
	for id, entry in pairs(self.entries) do
		if entry.expires_at < currentTime then
			self.entries[id] = nil
		end
	end
end

function XHSBotDangerRegistry:GetEntryPosition(entry)
	if entry.follow_entindex ~= nil and EntIndexToHScript ~= nil then
		local ok, entity = pcall(EntIndexToHScript, entry.follow_entindex)
		if ok and entity ~= nil and not entity:IsNull() then
			return entity:GetAbsOrigin()
		end
	end
	return entry.position
end

function XHSBotDangerRegistry:Contains(entry, position)
	if entry.shape == "circle" then
		local center = self:GetEntryPosition(entry)
		return IsVector(center) and Distance2D(center, position) <= entry.radius
	end

	if entry.shape == "line" then
		if not IsVector(entry.start_position) or not IsVector(entry.end_position) then return false end
		return DistanceToSegment(position, entry.start_position, entry.end_position) <= entry.radius
	end

	if entry.shape == "cone" then
		local origin = entry.position
		if not IsVector(origin) or not IsVector(entry.direction) then return false end
		local delta = { x = position.x - origin.x, y = position.y - origin.y }
		local distance = math.sqrt(delta.x * delta.x + delta.y * delta.y)
		if distance > entry.length then return false end
		if distance <= 0.001 then return true end
		local forward = Normalize2D(entry.direction)
		local toward = Normalize2D(delta)
		local dot = math.max(-1, math.min(1, forward.x * toward.x + forward.y * toward.y))
		local angle = math.deg(math.acos(dot))
		return angle <= entry.angle * 0.5
	end

	return false
end

function XHSBotDangerRegistry:GetDangerAt(position, queryTime, anticipation)
	if self.enabled ~= true or not IsVector(position) then return 0, {} end

	queryTime = tonumber(queryTime) or Now()
	anticipation = math.max(0, tonumber(anticipation) or 0)
	self:Prune(queryTime)

	local total = 0
	local matches = {}
	for _, entry in pairs(self.entries) do
		local relevantAt = queryTime + anticipation
		if relevantAt >= entry.starts_at and queryTime <= entry.expires_at and self:Contains(entry, position) then
			local imminence = 1
			if relevantAt < entry.activates_at then
				local window = math.max(0.05, entry.activates_at - entry.starts_at)
				imminence = math.max(0.15, 1 - ((entry.activates_at - relevantAt) / window))
			end
			local score = entry.severity * imminence
			total = total + score
			table.insert(matches, entry)
		end
	end

	return math.min(1, total), matches
end

function XHSBotDangerRegistry:FindSafestPosition(origin, anchor, preferredRange, anticipation)
	if not IsVector(origin) then return nil, 1 end

	preferredRange = math.max(220, tonumber(preferredRange) or 450)
	local bestPosition = origin
	local bestScore = self:GetDangerAt(origin, Now(), anticipation)
	local anchorPosition = IsVector(anchor) and anchor or origin
	local radii = { preferredRange * 0.65, preferredRange, preferredRange * 1.35 }

	for _, radius in ipairs(radii) do
		for index = 0, 15 do
			local angle = math.rad(index * 22.5)
			local candidate = Vector(
				origin.x + math.cos(angle) * radius,
				origin.y + math.sin(angle) * radius,
				origin.z or 0
			)
			local navigable = true
			if GridNav ~= nil and GridNav.CanFindPath ~= nil then
				navigable = GridNav:CanFindPath(origin, candidate)
			end
			if navigable then
				local danger = self:GetDangerAt(candidate, Now(), anticipation)
				local anchorPenalty = math.min(0.25, Distance2D(candidate, anchorPosition) / 8000)
				local score = danger + anchorPenalty
				if score < bestScore then
					bestScore = score
					bestPosition = candidate
				end
			end
		end
	end

	return bestPosition, bestScore
end

-- Stable public hooks for legacy encounter scripts. They are inert unless the
-- Tools-only bot thinker has enabled the registry.
function XHSRegisterBotDangerCircle(position, radius, duration, options)
	return XHSBotDangerRegistry:AddCircle(position, radius, duration, options)
end

function XHSRegisterBotDangerLine(startPosition, endPosition, radius, duration, options)
	return XHSBotDangerRegistry:AddLine(startPosition, endPosition, radius, duration, options)
end

function XHSRegisterBotDangerCone(origin, direction, length, angle, duration, options)
	return XHSBotDangerRegistry:AddCone(origin, direction, length, angle, duration, options)
end

return XHSBotDangerRegistry
