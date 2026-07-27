-- Supporter Pass Immolation renderer.
--
-- Gameplay abilities keep deciding which units are damaged. Their narrowly
-- scoped hooks only report an active source and the units selected by the
-- original damage action. This module owns the cosmetic particle lifecycle.

local OWNER_ANCHOR = "particles/custom/supporter_pass/immolation_owner_anchor.vpcf"
local TARGET_ANCHOR = "particles/custom/supporter_pass/immolation_target_anchor.vpcf"
local THINK_INTERVAL = 0.10
local TARGET_GRACE = 0.15
local CONTEXT_THINK = "XHSSupporterPassImmolation"
local GOOD_TEAM = DOTA_TEAM_GOODGUYS or 2

local SOURCE_ALLOWLIST = {
	item_xhs_cloak_of_flames = true,
	holdout_permanent_immolation = true,
	holdout_bane_permanent_immolation = true,
	holdout_permanent_lightning = true,
	holdout_consuming_flame = true,
	holdout_active_immolation = true,
	ghost_revenant_ghost_immolation = true,
}

SupporterPassImmolation = SupporterPassImmolation or {}
SupporterPassImmolation.OWNER_ANCHOR = OWNER_ANCHOR
SupporterPassImmolation.TARGET_ANCHOR = TARGET_ANCHOR
SupporterPassImmolation.SOURCE_ALLOWLIST = SOURCE_ALLOWLIST
SupporterPassImmolation.sources = SupporterPassImmolation.sources or {}
SupporterPassImmolation.targetParticles = SupporterPassImmolation.targetParticles or {}

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

local function IsAllowedAbility(ability)
	local abilityName = GetAbilityName(ability)
	return abilityName ~= nil and SOURCE_ALLOWLIST[abilityName] == true
end

local function GetGameTime()
	if GameRules ~= nil and GameRules.GetGameTime ~= nil then
		return GameRules:GetGameTime()
	end
	return 0
end

local function GetOverride(hero, anchor)
	if not IsEligibleTrueHero(hero) or CustomNetTables == nil then return nil end

	local playerID = hero:GetPlayerOwnerID()
	local value = CustomNetTables:GetTableValue(
		"supporter_pass_player",
		anchor .. "_" .. tostring(playerID)
	)
	if type(value) ~= "table" then return nil end

	local replacement = value["1"] or value[1]
	if replacement == nil then return nil end
	replacement = tostring(replacement)
	if replacement == "" or replacement == anchor then return nil end
	return replacement
end

local function GetEquippedPair(hero)
	local owner = GetOverride(hero, OWNER_ANCHOR)
	local target = GetOverride(hero, TARGET_ANCHOR)

	-- A partial family is never rendered. Catalog validation should prevent
	-- this, while the runtime guard keeps owner and target atomic.
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

local function CreateParticle(path, attachType, parent, hero)
	if path == nil or path == "" or not IsValidEntityHandle(parent) then return nil end
	if ParticleManager == nil then return nil end

	-- hCaster is intentionally the recursively resolved real hero. XHS's
	-- ParticleManager wrapper uses it to resolve the player's exact loadout.
	local particleIndex = ParticleManager:CreateParticle(path, attachType, parent, hero)
	if particleIndex == nil or particleIndex < 0 then return nil end
	return particleIndex
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

	local path = source.pair ~= nil and OWNER_ANCHOR or source.fallbackOwner
	source.ownerParticle = CreateParticle(
		path,
		PATTACH_ABSORIGIN_FOLLOW,
		source.caster,
		source.hero
	)
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
		local path = source.pair ~= nil and TARGET_ANCHOR or targetState.fallbackTarget
		group = {
			particle = CreateParticle(
				path,
				PATTACH_ABSORIGIN_FOLLOW,
				targetState.target,
				source.hero
			),
			refs = {},
			target = targetState.target,
			hero = source.hero,
		}
		self.targetParticles[groupKey] = group
	end

	group.refs[source.key] = true
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

function SupporterPassImmolation:Init()
	if not IsServerRuntime() or self.initialized == true then return self end
	self.initialized = true

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
	if not IsServerRuntime() or not IsAllowedAbility(ability) then return nil end
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
	}
	self.sources[key] = source
	self:_CreateOwner(source)
	return source
end

function SupporterPassImmolation:AcquireTarget(sourceToken, caster, target, ability, fallbackOwner, fallbackTarget)
	if not IsServerRuntime() or not IsValidEntityHandle(target) or not target:IsAlive() then return nil end
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
	local now = GetGameTime()
	local destroySources = {}

	for key, source in pairs(self.sources) do
		if not IsValidEntityHandle(source.caster)
		or not IsValidEntityHandle(source.ability)
		or not IsEligibleTrueHero(source.hero)
		or not IsAllowedAbility(source.ability)
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

function XHSSupporterImmolationBurnTarget(keys)
	if not IsServerRuntime() then return end
	SupporterPassImmolation:AcquireTarget(
		keys.ability,
		keys.caster,
		keys.target or keys.unit,
		keys.ability,
		keys.fallback_owner_pfx,
		keys.fallback_target_pfx
	)
end

return SupporterPassImmolation
