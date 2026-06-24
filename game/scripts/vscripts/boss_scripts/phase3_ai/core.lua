if XHSPhase3BossAI == nil then
	XHSPhase3BossAI = {}
end

local DIFFICULTY_SCALE = {
	[1] = { damage = 0.70, delay = 1.25, density = 0.65 },
	[2] = { damage = 1.00, delay = 1.00, density = 1.00 },
	[3] = { damage = 1.20, delay = 0.90, density = 1.15 },
	[4] = { damage = 1.40, delay = 0.82, density = 1.30 },
	[5] = { damage = 1.70, delay = 0.72, density = 1.55 },
}

function XHSPhase3BossAI:GetDifficulty()
	if GameRules == nil then return 1 end
	return math.max(1, math.min(5, GameRules:GetCustomGameDifficulty() or 1))
end

function XHSPhase3BossAI:GetScale()
	return DIFFICULTY_SCALE[self:GetDifficulty()] or DIFFICULTY_SCALE[1]
end

function XHSPhase3BossAI:ScaleDamage(value)
	return (value or 0) * self:GetScale().damage
end

function XHSPhase3BossAI:ScaleDelay(value)
	return math.max(0.1, (value or 0) * self:GetScale().delay)
end

function XHSPhase3BossAI:ScaleDensity(value, minimum)
	return math.max(minimum or 1, math.floor((value or 0) * self:GetScale().density + 0.5))
end

function XHSPhase3BossAI:GetLivingHeroes(center, radius, includeInvulnerable)
	local flags = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES
	if includeInvulnerable == true then
		flags = flags + DOTA_UNIT_TARGET_FLAG_INVULNERABLE
	end

	return FindUnitsInRadius(
		DOTA_TEAM_GOODGUYS,
		center or Vector(0, 0, 0),
		nil,
		radius or FIND_UNITS_EVERYWHERE,
		DOTA_UNIT_TARGET_TEAM_FRIENDLY,
		DOTA_UNIT_TARGET_HERO,
		flags,
		FIND_ANY_ORDER,
		false
	)
end

function XHSPhase3BossAI:PickClosestHero(center, radius)
	local heroes = self:GetLivingHeroes(center, radius, true)
	local best = nil
	local bestDistance = nil

	for _, hero in pairs(heroes) do
		if hero ~= nil and IsValidEntity(hero) and not hero:IsNull() and hero:IsAlive() then
			local distance = (hero:GetAbsOrigin() - center):Length2D()
			if bestDistance == nil or distance < bestDistance then
				best = hero
				bestDistance = distance
			end
		end
	end

	return best
end

function XHSPhase3BossAI:PickFarthestHero(center, radius)
	local heroes = self:GetLivingHeroes(center, radius, true)
	local best = nil
	local bestDistance = -1

	for _, hero in pairs(heroes) do
		if hero ~= nil and IsValidEntity(hero) and not hero:IsNull() and hero:IsAlive() then
			local distance = (hero:GetAbsOrigin() - center):Length2D()
			if distance > bestDistance then
				best = hero
				bestDistance = distance
			end
		end
	end

	return best
end

function XHSPhase3BossAI:MoveBoss(boss, position)
	if boss == nil or not IsValidEntity(boss) or boss:IsNull() or position == nil then return end

	ExecuteOrderFromTable({
		UnitIndex = boss:entindex(),
		OrderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION,
		Position = position,
	})
end

function XHSPhase3BossAI:WeightedChoice(entries, now)
	local total = 0
	for _, entry in pairs(entries) do
		if entry ~= nil and (entry.ready_at == nil or entry.ready_at <= now) and (entry.can_run == nil or entry.can_run()) then
			total = total + (entry.weight or 1)
		end
	end

	if total <= 0 then return nil end

	local roll = RandomFloat(0, total)
	local cursor = 0
	for _, entry in pairs(entries) do
		if entry ~= nil and (entry.ready_at == nil or entry.ready_at <= now) and (entry.can_run == nil or entry.can_run()) then
			cursor = cursor + (entry.weight or 1)
			if roll <= cursor then
				return entry
			end
		end
	end

	return nil
end

function XHSPhase3BossAI:SetAbilityLevels(boss, abilityNames)
	if boss == nil then return end

	local difficulty = self:GetDifficulty()
	for _, abilityName in pairs(abilityNames or {}) do
		local ability = boss:FindAbilityByName(abilityName)
		if ability ~= nil then
			ability:SetLevel(difficulty)
		end
	end
end
