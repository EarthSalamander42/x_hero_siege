-- Generic XHS creature AI. Scheduling and ability discovery are centralized in
-- XHSCreepAIDirector so identical units do not own interval thinkers or rescan
-- the same ability layout.

modifier_ai = modifier_ai or class({})
modifier_ai.XHS_LINK_CLIENT = true

local DEFAULT_ACTIVE_INTERVAL = 0.75
local DEFAULT_PASSIVE_INTERVAL = 2.0
local SILENCED_INTERVAL = 0.5
local ACTION_RETRY_INTERVAL = 0.2
local connectedPlayerCache = { at = -math.huge, count = 0 }

local function IsValidEntityHandle(entity)
	return entity ~= nil
		and (entity.IsNull == nil or not entity:IsNull())
end

local function IsBreakableTarget(target)
	if not IsValidEntityHandle(target) or target.GetUnitName == nil then return false end
	local unitName = target:GetUnitName()
	return unitName == "npc_dota_crate"
		or unitName == "npc_dota_chest"
		or unitName == "npc_dota_vase"
end

local function IsLivingTarget(target)
	if not IsValidEntityHandle(target) then return false end
	return target.IsAlive == nil or target:IsAlive()
end

local function IsValidGoodGuyHero(target)
	return IsValidEntityHandle(target)
		and target:IsAlive()
		and target:GetTeamNumber() == DOTA_TEAM_GOODGUYS
		and target:IsRealHero()
		and not target:IsIllusion()
		and not target:IsInvisible()
		and not target:IsInvulnerable()
end

local function IsMultiplayerOnlyAbility(abilityName)
	for _, restrictedAbilityName in pairs(_G.multiplayer_abilities_cast or {}) do
		if abilityName == restrictedAbilityName then return true end
	end
	return false
end

local function GetConnectedGoodGuyPlayerCount(now)
	now = tonumber(now) or GameRules:GetGameTime()
	if now - connectedPlayerCache.at < 2 then return connectedPlayerCache.count end

	local count = 0
	for playerID = 0, DOTA_MAX_TEAM_PLAYERS - 1 do
		if PlayerResource:IsValidPlayerID(playerID)
			and PlayerResource:GetTeam(playerID) == DOTA_TEAM_GOODGUYS
			and PlayerResource:GetConnectionState(playerID) == DOTA_CONNECTION_STATE_CONNECTED then
			count = count + 1
		end
	end
	connectedPlayerCache.at = now
	connectedPlayerCache.count = count
	return count
end

local function HasBehavior(behavior, flag)
	return bit.band(tonumber(behavior) or 0, flag) == flag
end

local function HasTargetTeam(targetTeam, flag)
	return bit.band(tonumber(targetTeam) or 0, flag) == flag
end

function modifier_ai:GetAttributes()
	return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_ai:IsPurgeException() return false end
function modifier_ai:IsPurgable() return false end
function modifier_ai:IsHidden() return true end

function modifier_ai:GetPriority()
	return MODIFIER_PRIORITY_SUPER_ULTRA
end

function modifier_ai:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_ATTACK_START,
		MODIFIER_EVENT_ON_ATTACK_FAIL,
		MODIFIER_EVENT_ON_ATTACK_LANDED,
	}
end

function modifier_ai:CheckState()
	return {}
end

function modifier_ai:OnCreated(params)
	if not IsServer() then return end
	self.parent = self:GetParent()
	self.last_movement = 0
	self.find_enemy_distance = 1000
	self.ai_state = tonumber(params.state) or 1
	if self.ai_state == 3 or self.ai_state == 4 then
		self.find_enemy_distance = 2000
	end
	self.isAttacking = false
	self.next_spell_check = 0
	self.ability_ready_at = {}
	self.ancient = nil

	if XHSCreepAIDirector ~= nil then
		XHSCreepAIDirector:Register(self)
	else
		-- Safe fallback for partial script reloads. New matches always use the
		-- director, but an already running VM may not have loaded it yet.
		self:StartIntervalThink(1)
	end
end

function modifier_ai:OnDestroy()
	if IsServer() and XHSCreepAIDirector ~= nil then
		XHSCreepAIDirector:Unregister(self)
	end
end

function modifier_ai:OnIntervalThink()
	self:RunDirectorThink(nil, GameRules:GetGameTime())
end

function modifier_ai:GetAncient()
	if IsValidEntityHandle(self.ancient) then return self.ancient end
	self.ancient = Entities:FindByName(nil, "dota_goodguys_fort")
		or Entities:FindByName(nil, "base_spawn")
	return self.ancient
end

function modifier_ai:MovePastBreakable()
	local ancient = self:GetAncient()
	if not IsValidEntityHandle(ancient) then return end

	self.isAttacking = false
	self.parent.xhs_breakable_ignore_until = GameRules:GetGameTime() + 1.5
	self.parent:SetForceAttackTarget(nil)
	if self.parent.SetAttacking ~= nil then
		self.parent:SetAttacking(nil)
	end
	self.parent:Stop()
	ExecuteOrderFromTable({
		UnitIndex = self.parent:entindex(),
		OrderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION,
		Position = ancient:GetAbsOrigin(),
	})
end

function modifier_ai:GetFallbackProfile()
	if self.fallback_profile ~= nil then return self.fallback_profile end
	if XHSCreepAIDirector ~= nil then
		self.fallback_profile = XHSCreepAIDirector:GetAbilityProfile(self.parent)
		return self.fallback_profile
	end

	local abilities = {}
	for abilityIndex = 0, GetUnitAbilityCount(self.parent) - 1 do
		local ability = GetUnitAbilityBySafeIndex(self.parent, abilityIndex)
		if IsValidEntityHandle(ability)
			and ability:GetLevel() > 0
			and not ability:IsPassive()
			and not ability:IsHidden() then
			table.insert(abilities, {
				name = ability:GetAbilityName(),
				behavior = tonumber(tostring(ability:GetBehavior())) or 0,
				target_team = ability:GetAbilityTargetTeam(),
				target_type = ability:GetAbilityTargetType(),
				target_flags = ability:GetAbilityTargetFlags(),
			})
		end
	end
	self.fallback_profile = {
		active_abilities = abilities,
		has_active_abilities = #abilities > 0,
	}
	return self.fallback_profile
end

function modifier_ai:TryCastFinalWaveIllidanAbility()
	if self.parent:GetUnitName() ~= "npc_dota_hero_illidan_final_wave" then
		return false
	end

	local negativeEnergy = self.parent:FindAbilityByName("demonhunter_negative_energy_small")
	if IsValidEntityHandle(negativeEnergy)
		and negativeEnergy:GetLevel() > 0
		and negativeEnergy:IsActivated()
		and negativeEnergy:IsCooldownReady()
		and not negativeEnergy:IsInAbilityPhase() then
		local castRange = negativeEnergy:GetCastRange(self.parent:GetAbsOrigin(), nil) or 800
		if castRange <= 0 then castRange = 800 end
		local targets = FindUnitsInRadius(
			self.parent:GetTeamNumber(),
			self.parent:GetAbsOrigin(),
			nil,
			castRange,
			DOTA_UNIT_TARGET_TEAM_ENEMY,
			DOTA_UNIT_TARGET_HERO,
			negativeEnergy:GetAbilityTargetFlags(),
			FIND_CLOSEST,
			false
		)
		for _, target in pairs(targets) do
			if IsValidGoodGuyHero(target) then
				self.parent:Stop()
				self.parent:CastAbilityOnTarget(target, negativeEnergy, -1)
				return true
			end
		end
	end

	local immolation = self.parent:FindAbilityByName("demonhunter_immolation_small")
	if IsValidEntityHandle(immolation)
		and immolation:GetLevel() > 0
		and immolation:IsActivated()
		and immolation:IsCooldownReady()
		and not immolation:IsInAbilityPhase()
		and not immolation:GetToggleState() then
		local radius = immolation:GetSpecialValueFor("radius")
		if radius <= 0 then radius = 600 end
		local targets = FindUnitsInRadius(
			self.parent:GetTeamNumber(),
			self.parent:GetAbsOrigin(),
			nil,
			radius,
			DOTA_UNIT_TARGET_TEAM_ENEMY,
			DOTA_UNIT_TARGET_HERO,
			immolation:GetAbilityTargetFlags(),
			FIND_CLOSEST,
			false
		)
		for _, target in pairs(targets) do
			if IsValidGoodGuyHero(target) then
				immolation:ToggleAbility()
				return true
			end
		end
	end
	return false
end

function modifier_ai:GetFarmEventHero()
	if self.ai_state ~= 5 or self.parent.xhs_farm_event ~= true then return nil end
	local playerID = tonumber(self.parent.xhs_farm_event_player_id)
	if playerID == nil or not PlayerResource:HasSelectedHero(playerID) then return nil end
	local hero = PlayerResource:GetSelectedHeroEntity(playerID)
	return IsValidGoodGuyHero(hero) and hero or nil
end

function modifier_ai:MaintainFarmEvent()
	local hero = self:GetFarmEventHero()
	if hero == nil then
		self.parent:SetForceAttackTarget(nil)
		return false
	end

	local attackTarget = self.parent:GetAttackTarget()
	if not IsLivingTarget(attackTarget) or attackTarget ~= hero then
		self.parent:SetForceAttackTarget(hero)
		ExecuteOrderFromTable({
			UnitIndex = self.parent:entindex(),
			OrderType = DOTA_UNIT_ORDER_ATTACK_TARGET,
			TargetIndex = hero:entindex(),
		})
	end
	return true
end

function modifier_ai:MaintainMovement(now)
	if self.ai_state == 5 then
		return self:MaintainFarmEvent()
	end

	if self.parent.xhs_wave_order_controller == true then
		if XHSPerformanceCounters ~= nil then
			XHSPerformanceCounters:Increment("wave_thinks", 1)
		end
		if XHSLagLabIsActive ~= nil and XHSLagLabIsActive("pause_waves") then
			return false
		end
	end

	local aggroTarget = self.parent:GetAggroTarget()
	local attackTarget = self.parent:GetAttackTarget()
	if not IsLivingTarget(aggroTarget) then aggroTarget = nil end
	if not IsLivingTarget(attackTarget) then attackTarget = nil end

	if XHSPerformanceCounters ~= nil then
		local target = attackTarget or aggroTarget
		local targetIndex = target ~= nil and target:entindex() or -1
		if self.xhs_performance_target_index ~= targetIndex then
			if self.xhs_performance_target_index ~= nil then
				XHSPerformanceCounters:Increment("target_changes", 1)
			end
			self.xhs_performance_target_index = targetIndex
		end
	end

	if IsBreakableTarget(aggroTarget) or IsBreakableTarget(attackTarget) then
		self:MovePastBreakable()
		return false
	end

	if self.parent.xhs_breakable_ignore_until ~= nil
		and now < self.parent.xhs_breakable_ignore_until then
		self.parent:SetForceAttackTarget(nil)
		return false
	end

	if self.last_attack_time ~= nil and now - self.last_attack_time < 0.5 then
		return true
	end

	local hasTarget = aggroTarget ~= nil or attackTarget ~= nil
	if self.ai_state == 1 and not hasTarget then
		self.isAttacking = false
		local ancient = self:GetAncient()
		if not IsValidEntityHandle(ancient) then return false end
		local ancientPosition = ancient:GetAbsOrigin()
		local distance = (self.parent:GetAbsOrigin() - ancientPosition):Length2D()
		if distance < 500 then
			self.parent:SetAttacking(ancient)
			return true
		end

		local attackRange = math.max(self.parent:Script_GetAttackRange(), 800)
		for _, vip in pairs(CDungeonZone.VIPsAlive or {}) do
			if IsValidEntityHandle(vip)
				and (self.parent:GetAbsOrigin() - vip:GetAbsOrigin()):Length2D() < attackRange then
				self.parent:SetForceAttackTarget(nil)
				ExecuteOrderFromTable({
					UnitIndex = self.parent:entindex(),
					OrderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION,
					Position = ancientPosition,
				})
				self.last_movement = now
				return false
			end
		end

		if not self.parent:IsMoving() or now - self.last_movement >= 3 then
			self.parent:SetForceAttackTarget(nil)
			ExecuteOrderFromTable({
				UnitIndex = self.parent:entindex(),
				OrderType = DOTA_UNIT_ORDER_ATTACK_MOVE,
				Position = ancientPosition,
			})
			self.last_movement = now
		end
	elseif self.ai_state == 3 then
		local randomGoal = RandomInt(1, 4)
		if self.last_goal ~= randomGoal
			and not self.parent:IsMoving()
			and not self.parent:IsAttacking() then
			local waypoint = Entities:FindByName(nil, "roshan_wp_" .. randomGoal)
			if IsValidEntityHandle(waypoint) then
				ExecuteOrderFromTable({
					UnitIndex = self.parent:entindex(),
					OrderType = DOTA_UNIT_ORDER_ATTACK_MOVE,
					Position = waypoint:GetAbsOrigin(),
				})
				self.last_goal = randomGoal
			end
		end
	elseif self.ai_state == 4 and not hasTarget then
		local ancient = self:GetAncient()
		if IsValidEntityHandle(ancient) and not self.parent:IsMoving() then
			ExecuteOrderFromTable({
				UnitIndex = self.parent:entindex(),
				OrderType = DOTA_UNIT_ORDER_ATTACK_MOVE,
				Position = ancient:GetAbsOrigin(),
			})
		end
	end
	return hasTarget
end

function modifier_ai:FindAbilityTargets(ability, entry, castRange)
	local targetTeam = tonumber(entry.target_team) or ability:GetAbilityTargetTeam()
	local targetType = tonumber(entry.target_type) or ability:GetAbilityTargetType()
	local targetFlags = tonumber(entry.target_flags) or ability:GetAbilityTargetFlags()
	if targetTeam == 0 then targetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY end
	if targetType == 0 then
		targetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
	end
	local searchOrder = (self.ai_state == 3 or self.ai_state == 4)
		and FIND_CLOSEST or FIND_ANY_ORDER
	local enemies = {}
	local allies = {}

	if self.ai_state == 5 then
		local hero = self:GetFarmEventHero()
		if HasTargetTeam(targetTeam, DOTA_UNIT_TARGET_TEAM_ENEMY)
			and hero ~= nil
			and (hero:GetAbsOrigin() - self.parent:GetAbsOrigin()):Length2D() <= castRange then
			enemies = { hero }
		end
		if HasTargetTeam(targetTeam, DOTA_UNIT_TARGET_TEAM_FRIENDLY)
			and SpecialEvents ~= nil
			and SpecialEvents.GetFarmEventActiveUnits ~= nil then
			local candidates = {}
			local config = SpecialEvents:GetFarmEventAbilityConfig(ability:GetAbilityName()) or {}
			for _, candidate in ipairs(
				SpecialEvents:GetFarmEventActiveUnits(self.parent.xhs_farm_event_player_id)
			) do
				if IsLivingTarget(candidate)
					and (candidate:GetAbsOrigin() - self.parent:GetAbsOrigin()):Length2D() <= castRange
					and (config.modifier == nil or not candidate:HasModifier(config.modifier)) then
					table.insert(candidates, candidate)
				end
			end
			table.sort(candidates, function(left, right)
				return left:GetAverageTrueAttackDamage(left)
					> right:GetAverageTrueAttackDamage(right)
			end)
			allies = candidates
		end
		return enemies, allies
	end

	if HasTargetTeam(targetTeam, DOTA_UNIT_TARGET_TEAM_ENEMY) then
		enemies = FindUnitsInRadius(
			self.parent:GetTeamNumber(),
			self.parent:GetAbsOrigin(),
			nil,
			castRange,
			DOTA_UNIT_TARGET_TEAM_ENEMY,
			targetType,
			targetFlags,
			searchOrder,
			false
		)
	end
	if HasTargetTeam(targetTeam, DOTA_UNIT_TARGET_TEAM_FRIENDLY) then
		allies = FindUnitsInRadius(
			self.parent:GetTeamNumber(),
			self.parent:GetAbsOrigin(),
			nil,
			castRange,
			DOTA_UNIT_TARGET_TEAM_FRIENDLY,
			targetType,
			targetFlags,
			searchOrder,
			false
		)
	end

	if self.ai_state == 3 or self.ai_state == 4 then
		local heroes = {}
		for _, enemy in pairs(enemies) do
			if IsValidGoodGuyHero(enemy) then table.insert(heroes, enemy) end
		end
		enemies = heroes
	end
	return enemies, allies
end

function modifier_ai:TryCastAbility(ability, entry)
	local behavior = tonumber(entry.behavior)
		or tonumber(tostring(ability:GetBehavior())) or 0
	local castRange = ability:GetCastRange(self.parent:GetAbsOrigin(), self.parent)
		or self.find_enemy_distance
	if self.ai_state == 5
		and SpecialEvents ~= nil
		and SpecialEvents.GetFarmEventAbilityConfig ~= nil then
		local farmConfig = SpecialEvents:GetFarmEventAbilityConfig(ability:GetAbilityName())
		if farmConfig ~= nil and tonumber(farmConfig.trigger_range) ~= nil then
			castRange = tonumber(farmConfig.trigger_range)
		end
	end
	if castRange <= 0 then castRange = self.find_enemy_distance end
	castRange = castRange * 0.9
	local enemies, allies = self:FindAbilityTargets(ability, entry, castRange)
	local hasTargets = #enemies > 0 or #allies > 0

	if HasBehavior(behavior, DOTA_ABILITY_BEHAVIOR_TOGGLE) then
		if hasTargets and not ability:GetToggleState() then
			ability:ToggleAbility()
			return true
		elseif not hasTargets and ability:GetToggleState() then
			ability:ToggleAbility()
			return true
		end
		return false
	end
	if not hasTargets then return false end

	if HasBehavior(behavior, DOTA_ABILITY_BEHAVIOR_NO_TARGET) then
		self.parent:Stop()
		self.parent:CastAbilityNoTarget(ability, -1)
		return true
	end

	if HasBehavior(behavior, DOTA_ABILITY_BEHAVIOR_POINT) then
		local target = enemies[1] or allies[1]
		if IsLivingTarget(target) and not target:IsInvisible() and not target:IsInvulnerable() then
			self.parent:Stop()
			ExecuteOrderFromTable({
				UnitIndex = self.parent:entindex(),
				OrderType = DOTA_UNIT_ORDER_CAST_POSITION,
				AbilityIndex = ability:entindex(),
				Position = target:GetAbsOrigin(),
			})
			return true
		end
	end

	if HasBehavior(behavior, DOTA_ABILITY_BEHAVIOR_UNIT_TARGET) then
		local target = enemies[1] or allies[1]
		if IsLivingTarget(target) and not target:IsInvisible() and not target:IsInvulnerable() then
			self.parent:Stop()
			self.parent:CastAbilityOnTarget(target, ability, -1)
			return true
		end
	end
	return false
end

function modifier_ai:RunAbilityLogic(profile, now)
	if XHSPerformanceCounters ~= nil then
		XHSPerformanceCounters:Increment("ability_loop_thinks", 1)
	end
	if XHSLagLabIsActive ~= nil and XHSLagLabIsActive("pause_abilities") then
		return DEFAULT_ACTIVE_INTERVAL
	end
	if self.parent:IsSilenced() then
		self.next_spell_check = now + SILENCED_INTERVAL
		return SILENCED_INTERVAL
	end
	if now < (self.next_spell_check or 0) then
		return math.max(ACTION_RETRY_INTERVAL, self.next_spell_check - now)
	end

	if self:TryCastFinalWaveIllidanAbility() then
		self.next_spell_check = now + ACTION_RETRY_INTERVAL
		return ACTION_RETRY_INTERVAL
	end

	local earliestRetry = DEFAULT_ACTIVE_INTERVAL
	for _, entry in ipairs(profile.active_abilities or {}) do
		local ability = self.parent:FindAbilityByName(entry.name)
		if IsValidEntityHandle(ability)
			and ability:GetLevel() > 0
			and not ability:IsPassive()
			and not ability:IsHidden()
			and ability:IsActivated()
			and not ability:IsInAbilityPhase()
			and not (
				IsMultiplayerOnlyAbility(entry.name)
				and GetConnectedGoodGuyPlayerCount(now) <= 1
			) then
			local sharedLockRemaining = 0
			local farmConfig = nil
			if self.ai_state == 5
				and SpecialEvents ~= nil
				and SpecialEvents.GetFarmEventAbilityConfig ~= nil then
				farmConfig = SpecialEvents:GetFarmEventAbilityConfig(entry.name)
				if farmConfig ~= nil then
					sharedLockRemaining = math.max(
						0,
						SpecialEvents:GetFarmEventAbilityLock(
							self.parent.xhs_farm_event_player_id,
							entry.name
						) - now
					)
				end
			end

			if sharedLockRemaining > 0 then
				earliestRetry = math.min(earliestRetry, sharedLockRemaining)
			else
				local cooldown = math.max(0, ability:GetCooldownTimeRemaining())
				if cooldown > 0 then
					earliestRetry = math.min(earliestRetry, cooldown)
				elseif self:TryCastAbility(ability, entry) then
					if farmConfig ~= nil then
						SpecialEvents:SetFarmEventAbilityLock(
							self.parent.xhs_farm_event_player_id,
							entry.name,
							now + (tonumber(farmConfig.shared_lock) or 0)
						)
					end
					self.next_spell_check = now + ACTION_RETRY_INTERVAL
					return ACTION_RETRY_INTERVAL
				end
			end
		end
	end

	earliestRetry = math.max(ACTION_RETRY_INTERVAL, earliestRetry)
	self.next_spell_check = now + earliestRetry
	return earliestRetry
end

function modifier_ai:RunDirectorThink(profile, now)
	if XHSPerformanceCounters ~= nil then
		XHSPerformanceCounters:Increment("ai_thinks", 1)
	end
	if not IsValidEntityHandle(self.parent) or not self.parent:IsAlive() then
		return DEFAULT_PASSIVE_INTERVAL
	end
	if XHSLagLabIsActive ~= nil and XHSLagLabIsActive("pause_ai") then
		return 0.25
	end

	now = tonumber(now) or GameRules:GetGameTime()
	profile = profile or self:GetFallbackProfile()
	local hasTarget = self:MaintainMovement(now)
	if profile == nil or profile.has_active_abilities ~= true then
		return hasTarget and 1.5 or DEFAULT_PASSIVE_INTERVAL
	end

	local spellDelay = self:RunAbilityLogic(profile, now)
	local movementDelay = hasTarget and 1.0 or DEFAULT_ACTIVE_INTERVAL
	return math.max(ACTION_RETRY_INTERVAL, math.min(spellDelay, movementDelay))
end

function modifier_ai:OnAttackStart(keys)
	if not IsServer() or self.parent ~= keys.attacker then return end
	if IsBreakableTarget(keys.target) then
		self:MovePastBreakable()
		return
	end
	self.isAttacking = true
end

function modifier_ai:OnAttackFail(keys)
	if IsServer() and self.parent == keys.attacker then
		self.isAttacking = false
	end
end

function modifier_ai:OnAttackLanded(keys)
	if IsServer() and self.parent == keys.attacker then
		self.isAttacking = false
		self.last_attack_time = GameRules:GetGameTime()
	end
end
