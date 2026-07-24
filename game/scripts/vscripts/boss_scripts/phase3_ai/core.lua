if XHSPhase3BossAI == nil then
	XHSPhase3BossAI = {}
end

LinkLuaModifier("modifier_xhs_boss_cast_protection", "boss_scripts/phase3_ai/core.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_xhs_phase3_hide_overhead_bar", "boss_scripts/phase3_ai/core.lua", LUA_MODIFIER_MOTION_NONE)

modifier_xhs_boss_cast_protection = modifier_xhs_boss_cast_protection or class({})
modifier_xhs_boss_cast_protection.XHS_LINK_CLIENT = true
modifier_xhs_phase3_hide_overhead_bar = modifier_xhs_phase3_hide_overhead_bar or class({})
modifier_xhs_phase3_hide_overhead_bar.XHS_LINK_CLIENT = true

local DIFFICULTY_SCALE = {
	[1] = { damage = 0.70, delay = 1.25, density = 0.65 },
	[2] = { damage = 1.00, delay = 1.00, density = 1.00 },
	[3] = { damage = 1.20, delay = 0.90, density = 1.15 },
	[4] = { damage = 1.40, delay = 0.82, density = 1.30 },
	[5] = { damage = 1.70, delay = 0.72, density = 1.55 },
}

local DEFAULT_CAST_AGGRO_RADIUS = 2600

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

function XHSPhase3BossAI:HideVanillaHealthBar(unit)
	if unit == nil or not IsValidEntity(unit) or unit:IsNull() then return end
	if not unit:HasModifier("modifier_xhs_phase3_hide_overhead_bar") then
		unit:AddNewModifier(unit, nil, "modifier_xhs_phase3_hide_overhead_bar", {})
	end
end

function XHSPhase3BossAI:DestroyParticle(particle, immediate)
	if particle == nil then return end
	ParticleManager:DestroyParticle(particle, immediate == true)
	ParticleManager:ReleaseParticleIndex(particle)
end

function XHSPhase3BossAI:ReleaseParticleAfter(particle, duration, immediate)
	if particle == nil then return end
	Timers:CreateTimer(math.max(0.03, duration or 0.1), function()
		XHSPhase3BossAI:DestroyParticle(particle, immediate)
		return nil
	end)
end

function XHSPhase3BossAI:EmitSoundOnce(unit, soundName, key, cooldown)
	if unit == nil or soundName == nil or soundName == "" then return false end
	local now = GameRules:GetGameTime()
	unit.xhs_phase3_sound_locks = unit.xhs_phase3_sound_locks or {}
	local lockKey = key or soundName
	if (unit.xhs_phase3_sound_locks[lockKey] or 0) > now then
		return false
	end

	unit.xhs_phase3_sound_locks[lockKey] = now + (cooldown or 0.35)
	unit:EmitSound(soundName)
	return true
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

function XHSPhase3BossAI:HasNearbyEnemyUnits(unit, radius)
	if unit == nil or not IsValidEntity(unit) or unit:IsNull() then return false end

	local enemies = FindUnitsInRadius(
		unit:GetTeamNumber(),
		unit:GetAbsOrigin(),
		nil,
		radius or DEFAULT_CAST_AGGRO_RADIUS,
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
		FIND_ANY_ORDER,
		false
	)

	for _, enemy in pairs(enemies) do
		if enemy ~= nil and IsValidEntity(enemy) and not enemy:IsNull() and enemy:IsAlive() then
			return true
		end
	end

	return false
end

function XHSPhase3BossAI:IsCastBlocked(unit)
	if unit == nil or not IsValidEntity(unit) or unit:IsNull() then return true end
	if unit.IsStunned ~= nil and unit:IsStunned() then return true end
	if unit.IsSilenced ~= nil and unit:IsSilenced() then return true end
	if unit.IsHexed ~= nil and unit:IsHexed() then return true end
	if not self:HasNearbyEnemyUnits(unit, unit.xhs_boss_ai_cast_radius) then return true end
	return false
end

function XHSPhase3BossAI:ProtectCast(boss, ability, extraDuration)
	if boss == nil or not IsValidEntity(boss) or boss:IsNull() then return end

	local castPoint = 0
	if ability ~= nil and not ability:IsNull() then
		if ability.GetCastPoint ~= nil then
			castPoint = ability:GetCastPoint() or 0
		end
		if castPoint <= 0 and ability.GetSpecialValueFor ~= nil then
			castPoint = ability:GetSpecialValueFor("cast_point") or 0
		end
	end

	boss:AddNewModifier(boss, nil, "modifier_xhs_boss_cast_protection", {
		duration = math.max(0.1, castPoint + (extraDuration or 0.25)),
	})
end

function XHSPhase3BossAI:IsPlayerControlledAttacker(attacker)
	if attacker == nil or not IsValidEntity(attacker) or attacker:IsNull() then return false end
	if attacker:GetTeamNumber() ~= DOTA_TEAM_GOODGUYS then return false end

	if attacker.GetPlayerOwnerID ~= nil then
		local playerID = attacker:GetPlayerOwnerID()
		if playerID ~= nil and playerID >= 0 then
			return true
		end
	end

	local owner = attacker.GetOwnerEntity ~= nil and attacker:GetOwnerEntity() or nil
	if owner ~= nil and IsValidEntity(owner) and not owner:IsNull() and owner.GetPlayerOwnerID ~= nil then
		local ownerPlayerID = owner:GetPlayerOwnerID()
		if ownerPlayerID ~= nil and ownerPlayerID >= 0 then
			return true
		end
	end

	return false
end

function XHSPhase3BossAI:ShouldRevealBossBarFromDamageEvent(modifier, event)
	if modifier == nil or event == nil then return false end
	if event.damage == nil or event.damage <= 0 then return false end

	local boss = modifier:GetParent()
	return (event.unit == boss and self:IsPlayerControlledAttacker(event.attacker))
		or (event.attacker == boss and self:IsPlayerControlledAttacker(event.unit))
end

function XHSPhase3BossAI:ShouldRevealBossBarFromAttackEvent(modifier, event)
	if modifier == nil or event == nil then return false end

	local boss = modifier:GetParent()
	return (event.target == boss and self:IsPlayerControlledAttacker(event.attacker))
		or (event.attacker == boss and self:IsPlayerControlledAttacker(event.target))
end

function XHSPhase3BossAI:RevealBossBarFromAggro(modifier)
	if modifier == nil or modifier.xhs_boss_bar_revealed == true then return end

	local boss = modifier:GetParent()
	if boss == nil or not IsValidEntity(boss) or boss:IsNull() then return end
	local target = boss.GetAggroTarget ~= nil and boss:GetAggroTarget() or nil
	if self:IsPlayerControlledAttacker(target) then
		self:RevealBossBarOnce(modifier)
	end
end

function XHSPhase3BossAI:RevealBossBarOnce(modifier)
	if modifier == nil or modifier.xhs_boss_bar_revealed == true then return end

	local boss = modifier:GetParent()
	if boss == nil or not IsValidEntity(boss) or boss:IsNull() or not boss:IsAlive() then return end
	if boss:HasModifier("modifier_invulnerable") or boss:HasModifier("modifier_pause_creeps") then return end

	boss.xhs_boss_bar_suppressed = false
	modifier.xhs_boss_bar_revealed = true
	if ShowBossBar ~= nil then
		ShowBossBar(boss)
	end
end

function modifier_xhs_boss_cast_protection:IsHidden() return true end
function modifier_xhs_boss_cast_protection:IsPurgable() return false end
function modifier_xhs_boss_cast_protection:RemoveOnDeath() return true end

function modifier_xhs_boss_cast_protection:OnCreated()
	if not IsServer() then return end
	self:StartIntervalThink(0.03)
	self:OnIntervalThink()
end

function modifier_xhs_boss_cast_protection:OnIntervalThink()
	if not IsServer() then return end
	local parent = self:GetParent()
	if parent == nil or parent:IsNull() or not parent:IsAlive() then return end
	parent:Purge(false, true, false, true, true)
end

function modifier_xhs_boss_cast_protection:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_STATUS_RESISTANCE_STACKING,
	}
end

function modifier_xhs_boss_cast_protection:GetModifierStatusResistanceStacking()
	return 100
end

function modifier_xhs_boss_cast_protection:CheckState()
	return {
		[MODIFIER_STATE_ROOTED] = false,
		[MODIFIER_STATE_HEXED] = false,
		[MODIFIER_STATE_SILENCED] = false,
		[MODIFIER_STATE_STUNNED] = false,
	}
end

function modifier_xhs_phase3_hide_overhead_bar:IsHidden() return true end
function modifier_xhs_phase3_hide_overhead_bar:IsPurgable() return false end
function modifier_xhs_phase3_hide_overhead_bar:RemoveOnDeath() return false end

function modifier_xhs_phase3_hide_overhead_bar:CheckState()
	return {
		[MODIFIER_STATE_NO_HEALTH_BAR] = true,
	}
end
