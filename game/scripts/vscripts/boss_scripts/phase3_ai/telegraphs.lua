if XHSBossTelegraphs == nil then
	XHSBossTelegraphs = {}
end

XHSBossTelegraphs.PARTICLE = "particles/custom/xhs_boss_warning_circle.vpcf"
XHSBossTelegraphs.DEFAULT_PRIMARY = Vector(255, 110, 35)
XHSBossTelegraphs.DEFAULT_SECONDARY = Vector(120, 255, 80)

local function ValidVector(value)
	return value ~= nil and value.x ~= nil and value.y ~= nil and value.z ~= nil
end

local function CreateWarning(position, radius, duration, primary, secondary, style)
	if not ValidVector(position) then return nil end

	-- The visual telegraph remains authoritative for players. In a Tools bot
	-- session, mirror it into the AI danger registry so bots react to the exact
	-- same warning window instead of reading hidden spell state.
	if XHSBotDangerRegistry ~= nil and XHSBotDangerRegistry.AddCircle ~= nil then
		XHSBotDangerRegistry:AddCircle(position, radius or 180, duration or 1.0, {
			severity = 1,
			label = "phase3_boss_telegraph",
		})
	end

	local particle = ParticleManager:CreateParticle(XHSBossTelegraphs.PARTICLE, PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleControl(particle, 0, position)
	ParticleManager:SetParticleControl(particle, 1, Vector(radius or 180, 0, 0))
	ParticleManager:SetParticleControl(particle, 2, Vector(duration or 1.0, 0, 0))
	ParticleManager:SetParticleControl(particle, 3, primary or XHSBossTelegraphs.DEFAULT_PRIMARY)
	ParticleManager:SetParticleControl(particle, 4, secondary or XHSBossTelegraphs.DEFAULT_SECONDARY)
	ParticleManager:SetParticleControl(particle, 5, Vector(style or 0, 0, 0))
	Timers:CreateTimer(math.max(0.1, duration or 1.0) + 0.15, function()
		ParticleManager:DestroyParticle(particle, false)
		ParticleManager:ReleaseParticleIndex(particle)
		return nil
	end)
	return particle
end

function XHSBossTelegraphs:Circle(position, radius, duration, colors)
	colors = colors or {}
	return CreateWarning(position, radius, duration, colors.primary, colors.secondary, colors.style or 0)
end

function XHSBossTelegraphs:Target(position, radius, duration, colors)
	colors = colors or {}
	return CreateWarning(position, radius, duration, colors.primary, colors.secondary, colors.style or 1)
end

function XHSBossTelegraphs:Ring(center, ringRadius, nodeRadius, count, duration, colors, offsetDegrees)
	if not ValidVector(center) then return end

	count = math.max(1, count or 8)
	for i = 1, count do
		local angle = ((i - 1) / count) * 360 + (offsetDegrees or 0)
		local position = RotatePosition(center, QAngle(0, angle, 0), center + Vector(ringRadius or 500, 0, 0))
		CreateWarning(position, nodeRadius or 180, duration, colors and colors.primary, colors and colors.secondary, colors and colors.style or 2)
	end
end

function XHSBossTelegraphs:Line(startPosition, direction, spacing, nodeRadius, count, duration, colors, startDistance)
	if not ValidVector(startPosition) or direction == nil then return end

	direction.z = 0
	if direction:Length2D() <= 0 then direction = Vector(1, 0, 0) end
	direction = direction:Normalized()
	count = math.max(1, count or 1)

	for i = 1, count do
		local position = startPosition + direction * ((startDistance or 0) + spacing * (i - 1))
		CreateWarning(position, nodeRadius or 180, duration, colors and colors.primary, colors and colors.secondary, colors and colors.style or 3)
	end
end
