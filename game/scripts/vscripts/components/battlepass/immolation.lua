-- Supporter Pass Immolation renderer.
--
-- Gameplay abilities keep deciding which units are damaged. Their narrowly
-- scoped hooks report an active source and the units selected by the original
-- damage action. This module owns only the cosmetic particle lifecycle and
-- creates the equipped player's final particle paths directly.
local THINK_INTERVAL = 0.10
local TARGET_GRACE = 0.15
local CONTEXT_THINK = "XHSSupporterPassImmolation"
local GOOD_TEAM = DOTA_TEAM_GOODGUYS or 2
local TARGET_DIRECTION_CONTROL_POINT = 1

local SOURCE_ALLOWLIST = {
	item_xhs_cloak_of_flames = true,
	holdout_permanent_immolation = true,
	holdout_bane_permanent_immolation = true,
	holdout_permanent_lightning = true,
	holdout_consuming_flame = true,
	holdout_active_immolation = true,
	ghost_revenant_ghost_immolation = true,
}

-- These are not general direct slots. They are accepted only on the exact
-- player summon units listed here, after recursive owner resolution.
local OWNED_SUMMON_RULES = {
	warlock_golem_permanent_immolation = {
		units = { npc_dota_golem_inferno = true },
		scan_targets = true,
	},
	dread_lord_inferno_immolation = {
		units = { npc_dota_golem_inferno = true },
	},
	doom_golem_hot_skin = {
		units = {
			npc_dota_dark_king = true,
			npc_dota_doom_golem_1 = true,
			npc_dota_doom_golem_2 = true,
			npc_dota_doom_golem_3 = true,
		},
	},
}

local FALLBACK_RADIUS_CONTROL = {
	item_xhs_cloak_of_flames = true,
	holdout_permanent_immolation = true,
	holdout_bane_permanent_immolation = true,
	holdout_permanent_lightning = true,
	holdout_consuming_flame = true,
	holdout_active_immolation = true,
}

SupporterPassImmolation = SupporterPassImmolation or {}
SupporterPassImmolation.SOURCE_ALLOWLIST = SOURCE_ALLOWLIST
SupporterPassImmolation.OWNED_SUMMON_RULES = OWNED_SUMMON_RULES
SupporterPassImmolation.sources = SupporterPassImmolation.sources or {}
SupporterPassImmolation.targetParticles = SupporterPassImmolation.targetParticles or {}
SupporterPassImmolation.pendingSummons = SupporterPassImmolation.pendingSummons or {}

local function IsServerRuntime()
	return IsServer == nil or IsServer()
end

local function IsValidEntityHandle(entity)
	if entity == nil then return false end
	if entity.IsNull ~= nil and entity:IsNull() then return false end
	if IsValidEntity ~= nil and not IsValidEntity(entity) then return false end
	return true
end

local function SafeEntityIndex(entity)
	if not IsValidEntityHandle(entity) or entity.entindex == nil then return nil end
	local ok, value = pcall(entity.entindex, entity)
	if not ok then return nil end
	return tonumber(value)
end

local function SafeUnitName(unit)
	if not IsValidEntityHandle(unit) or unit.GetUnitName == nil then return "" end
	local ok, value = pcall(unit.GetUnitName, unit)
	return ok and tostring(value or "") or ""
end

local function IsValidPlayerID(playerID)
	playerID = tonumber(playerID)
	if playerID == nil or playerID < 0 then return false end
	if PlayerResource == nil or PlayerResource.IsValidPlayerID == nil then return false end
	return PlayerResource:IsValidPlayerID(playerID)
end

local function IsEligibleTrueHero(hero)
	if not IsValidEntityHandle(hero) then return false end
	if hero.IsRealHero == nil or not hero:IsRealHero() then return false end
	if hero.IsIllusion ~= nil and hero:IsIllusion() then return false end
	if hero.IsClone ~= nil and hero:IsClone() then return false end
	if hero.IsTempestDouble ~= nil and hero:IsTempestDouble() then return false end
	if hero.GetTeamNumber == nil or hero:GetTeamNumber() ~= GOOD_TEAM then return false end
	if hero.GetPlayerOwnerID == nil then return false end
	return IsValidPlayerID(hero:GetPlayerOwnerID())
end

local function GetSelectedHero(playerID)
	if not IsValidPlayerID(playerID) or PlayerResource.GetSelectedHeroEntity == nil then return nil end
	local hero = PlayerResource:GetSelectedHeroEntity(playerID)
	return IsEligibleTrueHero(hero) and hero or nil
end

local function IsExcludedSource(unit)
	if not IsValidEntityHandle(unit) then return true end
	if unit.GetTeamNumber == nil or unit:GetTeamNumber() ~= GOOD_TEAM then return true end
	if unit.Boss == true or unit.bBoss == true then return true end

	-- XHS marks phase/event bosses through this helper. The allowlist below is
	-- still the primary boundary; this is defense in depth for controlled or
	-- tools-spawned boss entities.
	if XHSIsBossDamageTarget ~= nil and XHSIsBossDamageTarget(unit) then
		return true
	end

	return false
end

local function GetAbilityName(ability)
	if not IsValidEntityHandle(ability) or ability.GetAbilityName == nil then return nil end
	local ok, value = pcall(ability.GetAbilityName, ability)
	if not ok or value == nil then return nil end
	return tostring(value)
end

local function GetAbilityRule(ability, caster)
	local abilityName = GetAbilityName(ability)
	if abilityName == nil then return nil end
	if SOURCE_ALLOWLIST[abilityName] == true then
		return { direct = true }
	end

	local summonRule = OWNED_SUMMON_RULES[abilityName]
	if summonRule == nil or summonRule.units[SafeUnitName(caster)] ~= true then
		return nil
	end
	return summonRule
end

local function IsAllowedAbility(ability, caster)
	return GetAbilityRule(ability, caster) ~= nil
end

local function GetGameTime()
	if GameRules ~= nil and GameRules.GetGameTime ~= nil then
		return GameRules:GetGameTime()
	end
	return 0
end

local function GetEquippedPair(hero)
	if Battlepass == nil or Battlepass.GetPlayerParticle == nil then return nil end
	local owner = Battlepass:GetPlayerParticle(hero, "immolation_owner_pfx")
	local target = Battlepass:GetPlayerParticle(hero, "immolation_target_pfx")

	-- A partial family is never rendered.
	if owner == nil or target == nil then return nil end
	return {
		owner = owner,
		target = target,
		key = owner .. "\n" .. target,
	}
end

local function DestroyParticle(particleIndex)
	if particleIndex == nil or ParticleManager == nil then return end
	ParticleManager:DestroyParticle(particleIndex, true)
	ParticleManager:ReleaseParticleIndex(particleIndex)
end

local function CreateParticle(path, attachType, parent)
	if path == nil or path == "" or not IsValidEntityHandle(parent) then return nil end
	if ParticleManager == nil then return nil end

	local particleIndex = ParticleManager:CreateParticle(path, attachType, parent)
	if particleIndex == nil or particleIndex < 0 then return nil end
	return particleIndex
end

-- Valve's radiance_target families use CP1 as a world-space repulsion source:
-- particles travel away from that point. Following the burn caster therefore
-- makes the authored flame trail point away from the caster instead of using
-- the particle's default south-facing CP1.
local function SetTargetDirectionSource(particleIndex, caster)
	if particleIndex == nil or ParticleManager == nil then return end
	if ParticleManager.SetParticleControlEnt == nil then return end
	if not IsValidEntityHandle(caster) or caster.GetAbsOrigin == nil then return end

	ParticleManager:SetParticleControlEnt(
		particleIndex,
		TARGET_DIRECTION_CONTROL_POINT,
		caster,
		PATTACH_ABSORIGIN_FOLLOW,
		nil,
		caster:GetAbsOrigin(),
		false
	)
end

local function GetSourceKey(token, caster, ability)
	local abilityIndex = SafeEntityIndex(ability)
	local casterIndex = SafeEntityIndex(caster)
	if abilityIndex ~= nil then
		return "ability:" .. tostring(abilityIndex) .. ":caster:" .. tostring(casterIndex or -1)
	end

	local tokenIndex = SafeEntityIndex(token)
	if tokenIndex ~= nil then
		return "entity:" .. tostring(tokenIndex) .. ":caster:" .. tostring(casterIndex or -1)
	end

	return "token:" .. tostring(token) .. ":caster:" .. tostring(casterIndex or -1)
end

local function GetTargetKey(target)
	local targetIndex = SafeEntityIndex(target)
	return targetIndex ~= nil and tostring(targetIndex) or tostring(target)
end

local function GetTargetTTL(ability)
	local tickTime = 1
	if IsValidEntityHandle(ability) and ability.GetSpecialValueFor ~= nil then
		local ok, value = pcall(ability.GetSpecialValueFor, ability, "tick_time")
		if ok and tonumber(value) ~= nil and tonumber(value) > 0 then
			tickTime = tonumber(value)
		end
	end
	return math.max(THINK_INTERVAL * 2, tickTime + TARGET_GRACE)
end

function SupporterPassImmolation:ResolveTrueHero(unit)
	if not IsValidEntityHandle(unit) or IsExcludedSource(unit) then return nil end

	local visited = {}
	local function Resolve(candidate, depth)
		if not IsValidEntityHandle(candidate) or depth > 8 then return nil end

		local index = SafeEntityIndex(candidate)
		local visitKey = index ~= nil and ("entity:" .. tostring(index)) or tostring(candidate)
		if visited[visitKey] then return nil end
		visited[visitKey] = true

		if IsEligibleTrueHero(candidate) then return candidate end

		if candidate.GetPlayerOwnerID ~= nil then
			local ok, playerID = pcall(candidate.GetPlayerOwnerID, candidate)
			if ok then
				local selectedHero = GetSelectedHero(playerID)
				if selectedHero ~= nil then return selectedHero end
			end
		end

		if candidate.GetCloneSource ~= nil then
			local ok, cloneSource = pcall(candidate.GetCloneSource, candidate)
			if ok then
				local hero = Resolve(cloneSource, depth + 1)
				if hero ~= nil then return hero end
			end
		end

		for _, getter in ipairs({ "GetOwnerEntity", "GetOwner" }) do
			if candidate[getter] ~= nil then
				local ok, owner = pcall(candidate[getter], candidate)
				if ok then
					local hero = Resolve(owner, depth + 1)
					if hero ~= nil then return hero end
				end
			end
		end

		if candidate.GetAssignedHero ~= nil then
			local ok, assignedHero = pcall(candidate.GetAssignedHero, candidate)
			if ok then return Resolve(assignedHero, depth + 1) end
		end

		return nil
	end

	local hero = Resolve(unit, 0)
	if hero == nil then return nil end

	-- A summon/illusion must genuinely be on its owner's Radiant team.
	if unit.GetTeamNumber == nil or unit:GetTeamNumber() ~= hero:GetTeamNumber() then
		return nil
	end
	return hero
end

function SupporterPassImmolation:_CreateOwner(source)
	if source.ownerParticle ~= nil then return end
	if not IsValidEntityHandle(source.caster) or not source.caster:IsAlive() then return end

	local path = source.pair ~= nil and source.pair.owner or source.fallbackOwner
	source.ownerParticle = CreateParticle(
		path,
		PATTACH_ABSORIGIN_FOLLOW,
		source.caster
	)

	-- Preserve the original Flame Guard / Brewmaster child setup for players
	-- without the new pair. Modern Supporter pairs keep their authored CPs.
	if source.ownerParticle ~= nil
	and source.pair == nil
	and FALLBACK_RADIUS_CONTROL[source.abilityName] == true
	and source.ability.GetSpecialValueFor ~= nil then
		local ok, radius = pcall(source.ability.GetSpecialValueFor, source.ability, "radius")
		if ok and tonumber(radius) ~= nil then
			ParticleManager:SetParticleControl(source.ownerParticle, 0, Vector(0, 0, 0))
			ParticleManager:SetParticleControl(source.ownerParticle, 1, Vector(tonumber(radius), 1, 1))
		end
	end
end

function SupporterPassImmolation:_TargetVisualKey(source, fallbackTarget)
	if source.pair ~= nil then
		return "supporter:" .. source.pair.target
	end
	if fallbackTarget ~= nil and fallbackTarget ~= "" then
		return "fallback:" .. fallbackTarget
	end
	return nil
end

function SupporterPassImmolation:_AcquireTargetParticle(source, targetState)
	if targetState.groupKey ~= nil then return end
	if not IsValidEntityHandle(targetState.target) then return end

	local visualKey = self:_TargetVisualKey(source, targetState.fallbackTarget)
	if visualKey == nil then return end

	local heroIndex = SafeEntityIndex(source.hero) or source.hero:GetPlayerOwnerID()
	local targetKey = GetTargetKey(targetState.target)
	local groupKey = tostring(heroIndex) .. ":" .. targetKey .. ":" .. visualKey
	local group = self.targetParticles[groupKey]

	if group == nil then
		local path = source.pair ~= nil and source.pair.target or targetState.fallbackTarget
		local particle = CreateParticle(
			path,
			PATTACH_ABSORIGIN_FOLLOW,
			targetState.target
		)
		if particle == nil then return end

		group = {
			particle = particle,
			refs = {},
			target = targetState.target,
			hero = source.hero,
			directionSourceKey = source.key,
		}
		self.targetParticles[groupKey] = group
	end

	group.refs[source.key] = true
	local directionSource = self.sources[group.directionSourceKey]
	if directionSource == nil or not IsValidEntityHandle(directionSource.caster) then
		group.directionSourceKey = source.key
		directionSource = source
	end
	SetTargetDirectionSource(group.particle, directionSource.caster)
	targetState.groupKey = groupKey
end

function SupporterPassImmolation:_ReleaseTargetParticle(source, targetState)
	local groupKey = targetState.groupKey
	if groupKey == nil then return end

	local group = self.targetParticles[groupKey]
	if group ~= nil then
		group.refs[source.key] = nil
		if next(group.refs) == nil then
			DestroyParticle(group.particle)
			self.targetParticles[groupKey] = nil
		elseif group.directionSourceKey == source.key then
			local nextSourceKey = next(group.refs)
			local nextSource = self.sources[nextSourceKey]
			group.directionSourceKey = nextSourceKey
			if nextSource ~= nil then
				SetTargetDirectionSource(group.particle, nextSource.caster)
			end
		end
	end

	targetState.groupKey = nil
end

function SupporterPassImmolation:_DestroySource(source)
	if source == nil then return end

	for _, targetState in pairs(source.targets) do
		self:_ReleaseTargetParticle(source, targetState)
	end
	source.targets = {}

	DestroyParticle(source.ownerParticle)
	source.ownerParticle = nil
	self.sources[source.key] = nil
end

function SupporterPassImmolation:_RefreshSource(source)
	for _, targetState in pairs(source.targets) do
		self:_ReleaseTargetParticle(source, targetState)
	end
	DestroyParticle(source.ownerParticle)
	source.ownerParticle = nil

	source.pair = GetEquippedPair(source.hero)
	source.pairKey = source.pair ~= nil and source.pair.key or ""
	self:_CreateOwner(source)

	local now = GetGameTime()
	for _, targetState in pairs(source.targets) do
		if IsValidEntityHandle(targetState.target)
			and targetState.target:IsAlive()
			and now - targetState.lastTouch <= targetState.ttl then
			self:_AcquireTargetParticle(source, targetState)
		end
	end
end

function SupporterPassImmolation:_QueueOwnedSummon(unit)
	if not IsValidEntityHandle(unit) then return end
	local unitName = SafeUnitName(unit)
	if OWNED_SUMMON_RULES.warlock_golem_permanent_immolation.units[unitName] ~= true then
		return
	end

	local index = SafeEntityIndex(unit)
	if index ~= nil then self.pendingSummons[index] = unit end
end

function SupporterPassImmolation:_RegisterPendingSummons()
	for index, unit in pairs(self.pendingSummons) do
		if not IsValidEntityHandle(unit) or IsExcludedSource(unit) then
			self.pendingSummons[index] = nil
		elseif unit.FindAbilityByName ~= nil then
			local ability = unit:FindAbilityByName("warlock_golem_permanent_immolation")
			if IsValidEntityHandle(ability) then
				local source = self:Acquire(ability, unit, ability)
				if source ~= nil then
					source.rule = OWNED_SUMMON_RULES.warlock_golem_permanent_immolation
					source.nextTargetScan = 0
					self.pendingSummons[index] = nil
				end
			end
		end
	end
end

local function GetScanRadius(ability, caster)
	if not IsValidEntityHandle(ability) then return 0 end

	local radius = 0
	if ability.GetCastRange ~= nil then
		local origin = IsValidEntityHandle(caster) and caster:GetAbsOrigin() or Vector(0, 0, 0)
		local ok, value = pcall(ability.GetCastRange, ability, origin, nil)
		if ok then radius = tonumber(value) or 0 end
	end
	if ability.GetSpecialValueFor ~= nil then
		for _, specialName in ipairs({ "radius", "aura_radius" }) do
			if radius > 0 then break end
			local ok, value = pcall(ability.GetSpecialValueFor, ability, specialName)
			if ok then radius = math.max(radius, tonumber(value) or 0) end
		end
	end
	return radius
end

local function HasSourceBurnModifier(target, source)
	if target.FindAllModifiers == nil then return false end

	for _, modifier in pairs(target:FindAllModifiers() or {}) do
		if modifier ~= nil and (modifier.IsNull == nil or not modifier:IsNull()) then
			local modifierAbility = modifier.GetAbility ~= nil and modifier:GetAbility() or nil
			local modifierCaster = modifier.GetCaster ~= nil and modifier:GetCaster() or nil
			if modifierAbility == source.ability and modifierCaster == source.caster then
				return true
			end
		end
	end

	return false
end

function SupporterPassImmolation:_ScanOwnedSummonTargets(source, now)
	if source.rule == nil or source.rule.scan_targets ~= true then return end
	if now < (source.nextTargetScan or 0) then return end
	source.nextTargetScan = now + 0.20

	local caster = source.caster
	local ability = source.ability
	source.scanRadius = source.scanRadius or GetScanRadius(ability, caster)
	local radius = source.scanRadius
	if radius <= 0 or FindUnitsInRadius == nil or caster.GetAbsOrigin == nil then return end

	local targets = {}
	if caster.PassivesDisabled == nil or not caster:PassivesDisabled() then
		targets = FindUnitsInRadius(
			caster:GetTeamNumber(),
			caster:GetAbsOrigin(),
			nil,
			radius,
			DOTA_UNIT_TARGET_TEAM_ENEMY,
			DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
			DOTA_UNIT_TARGET_FLAG_NONE,
			FIND_ANY_ORDER,
			false
		)
	end

	local seen = {}
	for _, target in pairs(targets or {}) do
		if IsValidEntityHandle(target)
		and target:IsAlive()
		and HasSourceBurnModifier(target, source) then
			local targetKey = GetTargetKey(target)
			seen[targetKey] = true
			self:AcquireTarget(ability, caster, target, ability)
		end
	end

	for targetKey, targetState in pairs(source.targets) do
		if seen[targetKey] ~= true then
			self:_ReleaseTargetParticle(source, targetState)
			source.targets[targetKey] = nil
		end
	end
end

function SupporterPassImmolation:Init()
	if not IsServerRuntime() or self.initialized == true then return self end
	self.initialized = true

	if ListenToGameEvent ~= nil then
		ListenToGameEvent("npc_spawned", function(event)
			local unit = event.entindex ~= nil and EntIndexToHScript(event.entindex) or nil
			if SupporterPassImmolation ~= nil then
				SupporterPassImmolation:_QueueOwnedSummon(unit)
			end
		end, nil)
	end

	if Entities ~= nil and Entities.FindAllByName ~= nil then
		for _, unit in pairs(Entities:FindAllByName("npc_dota_golem_inferno") or {}) do
			self:_QueueOwnedSummon(unit)
		end
	end

	if GameRules ~= nil and GameRules.GetGameModeEntity ~= nil then
		local gameMode = GameRules:GetGameModeEntity()
		if gameMode ~= nil and gameMode.SetContextThink ~= nil then
			gameMode:SetContextThink(CONTEXT_THINK, function()
				if SupporterPassImmolation ~= nil then
					SupporterPassImmolation:_Prune()
					return THINK_INTERVAL
				end
				return nil
			end, THINK_INTERVAL)
		end
	end

	return self
end

function SupporterPassImmolation:Acquire(sourceToken, caster, ability, fallbackOwner, fallbackTarget)
	if not IsServerRuntime() or not IsAllowedAbility(ability, caster) then return nil end
	if IsExcludedSource(caster) then return nil end

	local hero = self:ResolveTrueHero(caster)
	if hero == nil then return nil end

	self:Init()
	local key = GetSourceKey(sourceToken, caster, ability)
	local existing = self.sources[key]
	if existing ~= nil then
		existing.fallbackOwner = fallbackOwner or existing.fallbackOwner
		existing.fallbackTarget = fallbackTarget or existing.fallbackTarget
		return existing
	end

	local pair = GetEquippedPair(hero)
	local source = {
		key = key,
		token = sourceToken,
		caster = caster,
		ability = ability,
		abilityName = GetAbilityName(ability),
		hero = hero,
		fallbackOwner = fallbackOwner,
		fallbackTarget = fallbackTarget,
		pair = pair,
		pairKey = pair ~= nil and pair.key or "",
		targets = {},
		rule = GetAbilityRule(ability, caster),
	}
	self.sources[key] = source
	self:_CreateOwner(source)
	return source
end

function SupporterPassImmolation:AcquireTarget(sourceToken, caster, target, ability, fallbackOwner, fallbackTarget)
	if not IsServerRuntime() or not IsValidEntityHandle(target) or not target:IsAlive() then return nil end
	if not IsValidEntityHandle(caster) then return nil end
	if target.GetTeamNumber ~= nil and caster.GetTeamNumber ~= nil
	and target:GetTeamNumber() == caster:GetTeamNumber() then
		return nil
	end

	local source = self:Acquire(sourceToken, caster, ability, fallbackOwner, fallbackTarget)
	if source == nil then return nil end

	local targetKey = GetTargetKey(target)
	local targetState = source.targets[targetKey]
	if targetState == nil then
		targetState = {
			target = target,
			fallbackTarget = fallbackTarget or source.fallbackTarget,
			lastTouch = GetGameTime(),
			ttl = GetTargetTTL(ability),
		}
		source.targets[targetKey] = targetState
	else
		targetState.target = target
		targetState.fallbackTarget = fallbackTarget or targetState.fallbackTarget
		targetState.lastTouch = GetGameTime()
		targetState.ttl = GetTargetTTL(ability)
	end

	self:_AcquireTargetParticle(source, targetState)
	return targetState
end

function SupporterPassImmolation:ReleaseTarget(sourceToken, caster, target, ability)
	if not IsServerRuntime() or target == nil then return end

	local source = self.sources[GetSourceKey(sourceToken, caster, ability)]
	if source == nil then return end

	local targetKey = GetTargetKey(target)
	local targetState = source.targets[targetKey]
	if targetState == nil then return end

	self:_ReleaseTargetParticle(source, targetState)
	source.targets[targetKey] = nil
end

function SupporterPassImmolation:Release(sourceToken, caster, ability)
	if not IsServerRuntime() then return end
	local source = self.sources[GetSourceKey(sourceToken, caster, ability)]
	self:_DestroySource(source)
end

function SupporterPassImmolation:Refresh(hero)
	if not IsServerRuntime() then return end
	hero = IsEligibleTrueHero(hero) and hero or self:ResolveTrueHero(hero)
	if hero == nil then return end

	local heroIndex = SafeEntityIndex(hero)
	for _, source in pairs(self.sources) do
		if source.hero == hero or SafeEntityIndex(source.hero) == heroIndex then
			self:_RefreshSource(source)
		end
	end
end

function SupporterPassImmolation:Cleanup(hero)
	if not IsServerRuntime() then return end
	local heroIndex = hero ~= nil and SafeEntityIndex(hero) or nil

	local destroy = {}
	for key, source in pairs(self.sources) do
		if hero == nil or source.hero == hero or SafeEntityIndex(source.hero) == heroIndex then
			destroy[#destroy + 1] = key
		end
	end

	for _, key in ipairs(destroy) do
		self:_DestroySource(self.sources[key])
	end
end

function SupporterPassImmolation:_Prune()
	if not IsServerRuntime() then return end
	self:_RegisterPendingSummons()
	local now = GetGameTime()
	local destroySources = {}

	for key, source in pairs(self.sources) do
		if not IsValidEntityHandle(source.caster)
		or not IsValidEntityHandle(source.ability)
		or not IsEligibleTrueHero(source.hero)
		or not IsAllowedAbility(source.ability, source.caster)
		or IsExcludedSource(source.caster) then
			destroySources[#destroySources + 1] = key
		else
			local pair = GetEquippedPair(source.hero)
			local pairKey = pair ~= nil and pair.key or ""
			if pairKey ~= source.pairKey then
				self:_RefreshSource(source)
			end

			if not source.caster:IsAlive() then
				DestroyParticle(source.ownerParticle)
				source.ownerParticle = nil
				for targetKey, targetState in pairs(source.targets) do
					self:_ReleaseTargetParticle(source, targetState)
					source.targets[targetKey] = nil
				end
			else
				self:_CreateOwner(source)
				self:_ScanOwnedSummonTargets(source, now)
				for targetKey, targetState in pairs(source.targets) do
					if not IsValidEntityHandle(targetState.target)
					or not targetState.target:IsAlive()
					or now - targetState.lastTouch > targetState.ttl then
						self:_ReleaseTargetParticle(source, targetState)
						source.targets[targetKey] = nil
					end
				end
			end
		end
	end

	for _, key in ipairs(destroySources) do
		self:_DestroySource(self.sources[key])
	end
end

-- DataDriven entry points. Keeping these tiny makes the KV hooks auditable.
function XHSSupporterImmolationAcquire(keys)
	if not IsServerRuntime() then return end
	SupporterPassImmolation:Acquire(
		keys.ability,
		keys.caster,
		keys.ability,
		keys.fallback_owner_pfx,
		keys.fallback_target_pfx
	)
end

function XHSSupporterImmolationRelease(keys)
	if not IsServerRuntime() then return end
	SupporterPassImmolation:Release(keys.ability, keys.caster, keys.ability)
end

function XHSSupporterImmolationReleaseTarget(keys)
	if not IsServerRuntime() then return end
	local target = keys.target or keys.unit
	if target ~= nil then
		SupporterPassImmolation:ReleaseTarget(keys.ability, keys.caster, target, keys.ability)
	end
end

function XHSSupporterImmolationBurnTarget(keys)
	if not IsServerRuntime() then return end

	local targets = keys.target_entities
	if type(targets) == "table" then
		for _, target in pairs(targets) do
			SupporterPassImmolation:AcquireTarget(
				keys.ability,
				keys.caster,
				target,
				keys.ability,
				keys.fallback_owner_pfx,
				keys.fallback_target_pfx
			)
		end
		return
	end

	local target = keys.target or keys.unit
	if target ~= nil then
		SupporterPassImmolation:AcquireTarget(
			keys.ability,
			keys.caster,
			target,
			keys.ability,
			keys.fallback_owner_pfx,
			keys.fallback_target_pfx
		)
	end
end

return SupporterPassImmolation
