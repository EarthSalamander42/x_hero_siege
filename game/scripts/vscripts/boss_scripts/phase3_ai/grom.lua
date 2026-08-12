require("boss_scripts/phase3_ai/core")
require("boss_scripts/phase3_ai/telegraphs")
require("boss_scripts/phase3_ai/grom_abilities")

LinkLuaModifier("modifier_xhs_grom_phase3_ai", "boss_scripts/phase3_ai/grom.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_xhs_grom_clone", "boss_scripts/phase3_ai/grom.lua", LUA_MODIFIER_MOTION_NONE)

modifier_xhs_grom_phase3_ai = modifier_xhs_grom_phase3_ai or class({})
modifier_xhs_grom_phase3_ai.XHS_LINK_CLIENT = true
modifier_xhs_grom_clone = modifier_xhs_grom_clone or class({})
modifier_xhs_grom_clone.XHS_LINK_CLIENT = true

local GROM_ABILITIES = {
	"xhs_grom_mirror_trial",
	"xhs_grom_blade_storm",
	"xhs_grom_mirror_cleave",
	"xhs_grom_windwalk_ambush",
	"xhs_grom_warsong_leap",
	"xhs_grom_blood_frenzy",
	"juggernaut_blade_dance",
	"chaos_knight_chaos_strike",
}

local MIRROR_THRESHOLDS = { 75, 50, 25 }
local GROM_COLORS = {
	primary = Vector(255, 62, 34),
	secondary = Vector(255, 185, 64),
	style = 4,
	family = "grom",
}

local function IsValidAlive(unit)
	return unit ~= nil and IsValidEntity(unit) and not unit:IsNull() and unit:IsAlive()
end

local function SyncAbilityCooldowns(source, target)
	if not IsValidAlive(source) or not IsValidAlive(target) then return end

	for _, abilityName in ipairs(GROM_ABILITIES) do
		local sourceAbility = source:FindAbilityByName(abilityName)
		local targetAbility = target:FindAbilityByName(abilityName)
		if sourceAbility ~= nil and targetAbility ~= nil then
			targetAbility:EndCooldown()
			local remaining = sourceAbility:GetCooldownTimeRemaining()
			if remaining > 0 then
				targetAbility:StartCooldown(remaining)
			end
		end
	end
end

local function FindNearestPlayerTarget(unit)
	if not IsValidAlive(unit) then return nil end

	local targets = FindUnitsInRadius(
		unit:GetTeamNumber(),
		unit:GetAbsOrigin(),
		nil,
		FIND_UNITS_EVERYWHERE,
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO,
		DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
		FIND_CLOSEST,
		false
	)
	for _, target in pairs(targets or {}) do
		if IsValidAlive(target) and XHSPhase3BossAI:IsPlayerControlledAttacker(target) then
			return target
		end
	end

	return nil
end

local function OrderCloneToAttack(clone, fallbackPosition)
	if not IsValidAlive(clone) then return end

	local target = FindNearestPlayerTarget(clone)
	if target ~= nil then
		ExecuteOrderFromTable({
			UnitIndex = clone:entindex(),
			OrderType = DOTA_UNIT_ORDER_ATTACK_TARGET,
			TargetIndex = target:entindex(),
			Queue = false,
		})
		return
	end

	ExecuteOrderFromTable({
		UnitIndex = clone:entindex(),
		OrderType = DOTA_UNIT_ORDER_ATTACK_MOVE,
		Position = fallbackPosition or clone:GetAbsOrigin(),
		Queue = false,
	})
end

local function GetGromArenaCenter(fallback)
	local spawner = Entities:FindByName(nil, "spawn_grom_hellscream")
	if spawner ~= nil then
		return spawner:GetAbsOrigin()
	end

	return fallback or Vector(0, 0, 0)
end

local function FaceUnitTowardsPosition(unit, position)
	if unit == nil or not IsValidEntity(unit) or unit:IsNull() or position == nil then return end

	local direction = position - unit:GetAbsOrigin()
	direction.z = 0
	if direction:Length2D() <= 0 then return end

	unit:SetForwardVector(direction:Normalized())
	unit:FaceTowards(position)
end

local function GetAbilityCastPoint(ability)
	if ability == nil then return 0 end
	if ability.GetCastPoint ~= nil then
		local castPoint = ability:GetCastPoint()
		if castPoint ~= nil and castPoint > 0 then return castPoint end
	end

	return ability:GetSpecialValueFor("cast_point")
end

local function PositionOnRing(center, radius, index, count, offsetDegrees)
	local angle = ((index - 1) / count) * 360 + (offsetDegrees or 0)
	return RotatePosition(center, QAngle(0, angle, 0), center + Vector(radius, 0, 0))
end

local function CastPreparedAbility(boss, abilityName, context, facePosition)
	if not IsValidAlive(boss) then return nil end

	local ability = boss:FindAbilityByName(abilityName)
	if ability == nil or ability:IsNull() or not ability:IsCooldownReady() then return nil end
	if XHSPhase3BossAI:IsCastBlocked(boss) then return nil end

	ability.xhs_grom_context = context or {}
	ability.xhs_grom_context.arena_center = ability.xhs_grom_context.arena_center or GetGromArenaCenter(boss:GetAbsOrigin())

	if facePosition ~= nil then
		FaceUnitTowardsPosition(boss, facePosition)
	end

	XHSPhase3BossAI:ProtectCast(boss, ability)
	boss:CastAbilityNoTarget(ability, -1)
	return ability
end

local function DamageEnemies(attacker, ability, position, radius, damage)
	if not IsValidAlive(attacker) then return end

	local enemies = FindUnitsInRadius(
		attacker:GetTeamNumber(),
		position,
		nil,
		radius,
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
		FIND_ANY_ORDER,
		false
	)

	for _, enemy in pairs(enemies) do
		if IsValidAlive(enemy) and not enemy:IsInvulnerable() then
			ApplyDamage({
				victim = enemy,
				attacker = attacker,
				ability = ability,
				damage = XHSPhase3BossAI:ScaleDamage(damage),
				damage_type = ability:GetAbilityDamageType(),
			})
		end
	end
end

function XHSGrom_AttachPhase3AI(boss)
	if boss == nil or not IsValidEntity(boss) or boss:IsNull() then return end
	if boss:GetUnitName() ~= "npc_dota_hero_grom_hellscream" then return end

	boss:RemoveModifierByName("modifier_ai")
	if boss:HasModifier("modifier_xhs_grom_phase3_ai") then return end
	XHSPhase3BossAI:HideVanillaHealthBar(boss)
	boss:AddNewModifier(boss, nil, "modifier_xhs_grom_phase3_ai", {})
end

function XHSGrom_StartMirrorTrial(caster, ability)
	if not IsValidAlive(caster) then return end

	local modifier = caster:FindModifierByName("modifier_xhs_grom_phase3_ai")
	if modifier ~= nil and modifier.BeginMirrorTrial ~= nil then
		modifier:BeginMirrorTrial(ability)
	end
end

function XHSGrom_OnFakeCloneKilled(clone, sourceEntIndex, abilityEntIndex, attacker)
	sourceEntIndex = tonumber(sourceEntIndex)
	if sourceEntIndex == nil then return end

	local boss = EntIndexToHScript(sourceEntIndex)
	if not IsValidAlive(boss) then return end

	local modifier = boss:FindModifierByName("modifier_xhs_grom_phase3_ai")
	if modifier ~= nil and modifier.OnFakeCloneKilled ~= nil then
		local ability = nil
		abilityEntIndex = tonumber(abilityEntIndex)
		if abilityEntIndex ~= nil then
			ability = EntIndexToHScript(abilityEntIndex)
		end
		modifier:OnFakeCloneKilled(clone, ability, attacker)
	end
end

function modifier_xhs_grom_phase3_ai:IsHidden() return true end
function modifier_xhs_grom_phase3_ai:IsPurgable() return false end

function modifier_xhs_grom_phase3_ai:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_TAKEDAMAGE,
		MODIFIER_EVENT_ON_ATTACK_LANDED,
		MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
	}
end

function modifier_xhs_grom_phase3_ai:OnCreated()
	if not IsServer() then return end

	local boss = self:GetParent()
	self.arena_center = GetGromArenaCenter(boss:GetAbsOrigin())
	self.recent_positions = {}
	self.thresholds_done = {}
	self.patterns = {}
	self.clones = {}
	self.state = "intro"
	self.cast_until = 0
	self.recover_until = 0
	self.last_pattern = nil
	self.trial_active = false

	boss.xhs_boss_bar_colors = {
		light_color = "#ffb13a",
		dark_color = "#4a0702",
	}
	boss.xhs_boss_bar_icon = "spellicons/custom/xhs_grom_mirror_trial"

	boss:RemoveModifierByName("modifier_ai")
	XHSPhase3BossAI:SetAbilityLevels(boss, GROM_ABILITIES)
	local bossHealth = boss:FindAbilityByName("boss_health")
	if bossHealth ~= nil and bossHealth:GetLevel() < 1 then bossHealth:SetLevel(1) end
	local cantDie = boss:FindAbilityByName("cant_die_generic")
	if cantDie ~= nil and cantDie:GetLevel() < 1 then cantDie:SetLevel(1) end
	self:UpdateBossBarMarkers()

	self:BuildPatternDeck()
	self:StartIntervalThink(0.25)
end

function modifier_xhs_grom_phase3_ai:OnDestroy()
	if not IsServer() then return end
	local boss = self:GetParent()
	if boss ~= nil and IsValidEntity(boss) and not boss:IsNull() then
		boss.xhs_grom_mirror_image = nil
		boss.xhs_grom_mirror_trial_token = nil
	end
	self:CleanupClones()
end

function modifier_xhs_grom_phase3_ai:IsBossActive()
	local boss = self:GetParent()
	return boss ~= nil and IsValidEntity(boss) and not boss:IsNull() and boss:IsAlive() and boss.deathStart ~= true
end

function modifier_xhs_grom_phase3_ai:BuildPatternDeck()
	local now = GameRules:GetGameTime()
	self.patterns = {
		{ id = "blade_storm", weight = 4, cooldown = 8.0, ready_at = 0, run = function() return self:CastBladeStorm() end },
		{ id = "mirror_cleave", weight = 4, cooldown = 7.0, ready_at = 0, run = function() return self:CastMirrorCleave() end },
		{ id = "windwalk_ambush", weight = 3, cooldown = 12.0, ready_at = now + 4.0, run = function() return self:CastWindwalkAmbush() end },
		{ id = "warsong_leap", weight = 3, cooldown = 10.0, ready_at = now + 2.0, run = function() return self:CastWarsongLeap() end },
	}
end

function modifier_xhs_grom_phase3_ai:UpdateBossBarMarkers()
	local boss = self:GetParent()
	boss.xhs_boss_bar_markers = {}

	for index, threshold in ipairs(MIRROR_THRESHOLDS) do
		boss.xhs_boss_bar_markers[index] = {
			pct = threshold,
			kind = "companion",
			label = "Mirror Trial",
			description = "Grom splits into mirror images. Find and strike the true Grom to end the trial.",
			triggered = self.thresholds_done[threshold] == true,
		}
	end
end

function modifier_xhs_grom_phase3_ai:OnIntervalThink()
	XHSPhase3BossAI:RevealBossBarFromAggro(self)

	if not self:IsBossActive() then
		self.state = "dead"
		self:CleanupClones()
		self:StartIntervalThink(-1)
		return
	end

	local boss = self:GetParent()
	local now = GameRules:GetGameTime()
	boss:RemoveModifierByName("modifier_ai")
	self:TrackHeroPositions()

	if boss:HasModifier("modifier_invulnerable") or boss:HasModifier("modifier_pause_creeps") then
		if self.trial_active ~= true then
			self.state = "intro"
		end
		return
	end

	if self.state == "mirror_trial" then
		if now >= (self.trial_ends_at or 0) then
			self:EndMirrorTrial(false)
		end
		return
	end

	if self.state == "casting" then
		if now < self.cast_until then return end
		self.state = "recovery"
	end

	if self.state == "recovery" then
		if now < self.recover_until then return end
		self.state = "idle"
	end

	if self:TryThresholdMirrorTrial(now) then return end

	local entry = XHSPhase3BossAI:WeightedChoice(self.patterns, now)
	if entry == nil then
		self:Reposition()
		return
	end

	self:RunPattern(entry, now)
end

function modifier_xhs_grom_phase3_ai:TrackHeroPositions()
	local heroes = XHSPhase3BossAI:GetLivingHeroes(self.arena_center, 2200, true)
	for _, hero in pairs(heroes) do
		if IsValidAlive(hero) then
			local key = tostring(hero:entindex())
			local previous = self.recent_positions[key]
			self.recent_positions[key] = {
				current = hero:GetAbsOrigin(),
				previous = previous and previous.current or hero:GetAbsOrigin(),
			}
		end
	end
end

function modifier_xhs_grom_phase3_ai:GetPredictedHeroPosition(hero, lead)
	if hero == nil then return self.arena_center end

	local position = hero:GetAbsOrigin()
	local tracked = self.recent_positions[tostring(hero:entindex())]
	if tracked == nil then return position end

	local velocity = tracked.current - tracked.previous
	return tracked.current + velocity * (lead or 1.0)
end

function modifier_xhs_grom_phase3_ai:TryThresholdMirrorTrial(now)
	if self.state == "casting" or self.state == "recovery" then return false end

	local boss = self:GetParent()
	local hpPct = boss:GetHealth() / math.max(1, boss:GetMaxHealth()) * 100
	for _, threshold in ipairs(MIRROR_THRESHOLDS) do
		if hpPct <= threshold and self.thresholds_done[threshold] ~= true then
			local duration = self:CastMirrorTrial(threshold)
			if duration == nil or duration <= 0 then return false end

			self.thresholds_done[threshold] = true
			self.state = "casting"
			self.cast_until = now + duration
			self.recover_until = self.cast_until + XHSPhase3BossAI:ScaleDelay(1.0)
			self:UpdateBossBarMarkers()
			if UpdateBossBar ~= nil then
				UpdateBossBar(boss)
			end
			return true
		end
	end

	return false
end

function modifier_xhs_grom_phase3_ai:RunPattern(entry, now)
	local duration = entry.run()
	if duration == nil or duration <= 0 then
		entry.ready_at = now + 1.0
		return
	end

	entry.ready_at = now + XHSPhase3BossAI:ScaleDelay(entry.cooldown)
	self.last_pattern = entry.id
	self.state = "casting"
	self.cast_until = now + duration
	self.recover_until = self.cast_until + XHSPhase3BossAI:ScaleDelay(0.75)
end

function modifier_xhs_grom_phase3_ai:Reposition()
	local boss = self:GetParent()
	local target = XHSPhase3BossAI:PickClosestHero(self.arena_center, 2200)
	local targetPosition = target ~= nil and target:GetAbsOrigin() or self.arena_center
	local direction = (boss:GetAbsOrigin() - targetPosition):Normalized()
	if direction:Length2D() <= 0 then direction = RandomVector(1) end

	XHSPhase3BossAI:MoveBoss(boss, self.arena_center + direction * RandomFloat(250, 460))
	self.state = "recovery"
	self.recover_until = GameRules:GetGameTime() + 0.6
end

function modifier_xhs_grom_phase3_ai:CastMirrorTrial(threshold)
	local boss = self:GetParent()
	local ability = boss:FindAbilityByName("xhs_grom_mirror_trial")
	if ability == nil then return nil end

	local castAbility = CastPreparedAbility(boss, "xhs_grom_mirror_trial", {
		threshold = threshold,
	}, boss:GetAbsOrigin() + Vector(0, -100, 0))
	if castAbility == nil then return nil end

	return GetAbilityCastPoint(castAbility) + 0.4
end

function modifier_xhs_grom_phase3_ai:CastBladeStorm()
	local boss = self:GetParent()
	local ability = CastPreparedAbility(boss, "xhs_grom_blade_storm", {}, boss:GetAbsOrigin() + Vector(0, -100, 0))
	if ability == nil then return nil end

	return GetAbilityCastPoint(ability) + ability:GetSpecialValueFor("duration") + 0.2
end

function modifier_xhs_grom_phase3_ai:CastMirrorCleave()
	local boss = self:GetParent()
	local ability = boss:FindAbilityByName("xhs_grom_mirror_cleave")
	local target = XHSPhase3BossAI:PickClosestHero(self.arena_center, 2200)
	if ability == nil or target == nil then return nil end

	local sourceCount = XHSPhase3BossAI:ScaleDensity(ability:GetSpecialValueFor("source_count"), 1)
	local targetPosition = self:GetPredictedHeroPosition(target, 1.1)
	local sources = self:GetMirrorSources(sourceCount)
	local cleaves = {}

	for index, source in ipairs(sources) do
		local direction = targetPosition - source
		direction.z = 0
		if direction:Length2D() <= 0 then direction = RandomVector(1) end
		cleaves[#cleaves + 1] = {
			start = source,
			direction = direction:Normalized(),
			delay = (index - 1) * XHSPhase3BossAI:ScaleDelay(ability:GetSpecialValueFor("source_stagger")),
			damage_scale = index == 1 and 1.0 or 0.65,
		}
	end

	local castAbility = CastPreparedAbility(boss, "xhs_grom_mirror_cleave", {
		cleaves = cleaves,
	}, targetPosition)
	if castAbility == nil then return nil end

	return GetAbilityCastPoint(castAbility) + #cleaves * XHSPhase3BossAI:ScaleDelay(ability:GetSpecialValueFor("source_stagger")) + 0.35
end

function modifier_xhs_grom_phase3_ai:CastWindwalkAmbush()
	local boss = self:GetParent()
	local ability = boss:FindAbilityByName("xhs_grom_windwalk_ambush")
	local target = XHSPhase3BossAI:PickFarthestHero(self.arena_center, 2200)
	if ability == nil or target == nil then return nil end

	local castAbility = CastPreparedAbility(boss, "xhs_grom_windwalk_ambush", {
		target = target,
		position = self:GetPredictedHeroPosition(target, 1.3),
	}, target:GetAbsOrigin())
	if castAbility == nil then return nil end

	return GetAbilityCastPoint(castAbility)
		+ castAbility:GetSpecialValueFor("vanish_delay")
		+ castAbility:GetSpecialValueFor("strike_delay")
		+ 0.4
end

function modifier_xhs_grom_phase3_ai:CastWarsongLeap()
	local boss = self:GetParent()
	local ability = boss:FindAbilityByName("xhs_grom_warsong_leap")
	local target = XHSPhase3BossAI:PickFarthestHero(self.arena_center, 2200)
	if ability == nil then return nil end

	local position = target ~= nil and self:GetPredictedHeroPosition(target, 1.0) or self.arena_center
	local castAbility = CastPreparedAbility(boss, "xhs_grom_warsong_leap", {
		position = position,
	}, position)
	if castAbility == nil then return nil end

	return GetAbilityCastPoint(castAbility) + castAbility:GetSpecialValueFor("travel_delay") + 0.35
end

function modifier_xhs_grom_phase3_ai:GetMirrorSources(count)
	local boss = self:GetParent()
	local sources = { boss:GetAbsOrigin() }

	for _, clone in pairs(self.clones or {}) do
		if #sources >= count then break end
		if IsValidAlive(clone) then
			sources[#sources + 1] = clone:GetAbsOrigin()
		end
	end

	while #sources < count do
		sources[#sources + 1] = PositionOnRing(boss:GetAbsOrigin(), 230, #sources, count, RandomFloat(0, 90))
	end

	return sources
end

function modifier_xhs_grom_phase3_ai:BeginMirrorTrial(ability)
	if not IsServer() or ability == nil then return end

	local boss = self:GetParent()
	self:CleanupClones()
	self.state = "mirror_trial"
	self.trial_active = true
	self.mirror_ability = ability

	local duration = ability:GetSpecialValueFor("trial_duration")
	local splitDelay = ability:GetSpecialValueFor("split_delay")
	local cloneCount = ability:GetSpecialValueFor("clone_count")
	local radius = ability:GetSpecialValueFor("spawn_radius")
	local totalImages = cloneCount + 1
	local realIndex = RandomInt(1, totalImages)
	self.mirror_trial_token = DoUniqueString("xhs_grom_mirror")
	boss.xhs_grom_mirror_image = true
	boss.xhs_grom_mirror_trial_token = self.mirror_trial_token
	local center = boss:GetAbsOrigin()
	local positions = {}

	for i = 1, totalImages do
		positions[i] = PositionOnRing(center, radius, i, totalImages, RandomFloat(0, 360))
		XHSBossTelegraphs:Target(positions[i], 130, splitDelay, GROM_COLORS)
	end

	self.trial_ends_at = GameRules:GetGameTime() + duration
	boss:AddNewModifier(boss, ability, "modifier_invulnerable", { duration = splitDelay + 0.1 })
	boss:EmitSound("Hero_ChaosKnight.Phantasm")

	Timers:CreateTimer(splitDelay, function()
		if not self:IsBossActive() or self.trial_active ~= true then return nil end

		FindClearSpaceForUnit(boss, positions[realIndex], true)
		boss:SetRenderColor(255, 255, 255)

		for i = 1, totalImages do
			if i ~= realIndex then
				local clone = CreateUnitByName("npc_dota_hero_grom_hellscream_clone", positions[i], true, boss, boss, boss:GetTeamNumber())
				if clone ~= nil then
					clone.xhs_grom_mirror_image = true
					clone.xhs_grom_mirror_trial_token = self.mirror_trial_token
					clone.zone = boss.zone or "xhs_holdout"
					clone:SetAngles(0, RandomFloat(0, 360), 0)
					clone:SetRenderColor(255, 255, 255)
					clone:AddNewModifier(boss, ability, "modifier_xhs_grom_clone", {
						duration = duration,
						source_entindex = boss:entindex(),
						ability_entindex = ability:entindex(),
						health = ability:GetSpecialValueFor("clone_health"),
					})
					clone:AddNewModifier(clone, nil, "modifier_kill", { duration = duration + 0.5 })
					self.clones[tostring(clone:entindex())] = clone

					OrderCloneToAttack(clone, self.arena_center)
				end
			end
		end

		return nil
	end)
end

function modifier_xhs_grom_phase3_ai:EndMirrorTrial(foundReal)
	if self.trial_active ~= true then return end

	local boss = self:GetParent()
	self.trial_active = false
	self.state = "recovery"
	self.recover_until = GameRules:GetGameTime() + XHSPhase3BossAI:ScaleDelay(foundReal == true and 0.75 or 1.5)
	boss:RemoveModifierByName("modifier_invulnerable")
	boss.xhs_grom_mirror_image = nil
	boss.xhs_grom_mirror_trial_token = nil
	self.mirror_trial_token = nil
	boss:SetRenderColor(255, 255, 255)
	self:CleanupClones()

	if foundReal == true then
		boss:EmitSound("Hero_Juggernaut.PreAttack")
	else
		boss:EmitSound("Hero_Juggernaut.BladeFuryStop")
	end
end

function modifier_xhs_grom_phase3_ai:CleanupClones()
	for key, clone in pairs(self.clones or {}) do
		if clone ~= nil and IsValidEntity(clone) and not clone:IsNull() then
			UTIL_Remove(clone)
		end
		self.clones[key] = nil
	end
end

function modifier_xhs_grom_phase3_ai:OnFakeCloneKilled(clone, ability, attacker)
	if self.trial_active ~= true or clone == nil then return end

	self.clones[tostring(clone:entindex())] = nil
	local boss = self:GetParent()
	local position = clone:GetAbsOrigin()
	local mirrorAbility = ability or self.mirror_ability or boss:FindAbilityByName("xhs_grom_mirror_trial")
	local radius = mirrorAbility ~= nil and mirrorAbility:GetSpecialValueFor("fake_punish_radius") or 260
	local damage = mirrorAbility ~= nil and mirrorAbility:GetSpecialValueFor("fake_punish_damage") or 2500

	self:ApplyBloodFrenzy()
	XHSBossTelegraphs:Circle(position, radius, 0.7, GROM_COLORS)

	Timers:CreateTimer(0.7, function()
		if not self:IsBossActive() then return nil end
		DamageEnemies(boss, mirrorAbility, position, radius, damage)
		-- The Blade Fury ground particle owns persistent world emitters and could
		-- survive the fake-clone punishment. Use the self-terminating hit burst.
		local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_juggernaut/juggernaut_blade_fury_tgt.vpcf", PATTACH_WORLDORIGIN, nil)
		ParticleManager:SetParticleControl(particle, 0, position)
		ParticleManager:ReleaseParticleIndex(particle)
		return nil
	end)
end

function modifier_xhs_grom_phase3_ai:ApplyBloodFrenzy()
	local boss = self:GetParent()
	local ability = boss:FindAbilityByName("xhs_grom_blood_frenzy")
	if ability == nil then return end

	local duration = ability:GetSpecialValueFor("stack_duration")
	local maxStacks = ability:GetSpecialValueFor("max_stacks")
	local modifier = boss:FindModifierByName("modifier_xhs_grom_blood_frenzy")
	if modifier == nil then
		modifier = boss:AddNewModifier(boss, ability, "modifier_xhs_grom_blood_frenzy", { duration = duration })
	end
	if modifier == nil then return end

	modifier:SetDuration(duration, true)
	modifier:SetStackCount(math.min(maxStacks, modifier:GetStackCount() + 1))
end

function modifier_xhs_grom_phase3_ai:OnTakeDamage(event)
	if not IsServer() then return end
	if XHSPhase3BossAI:ShouldRevealBossBarFromDamageEvent(self, event) then
		XHSPhase3BossAI:RevealBossBarOnce(self)
	end
end

function modifier_xhs_grom_phase3_ai:OnAttackLanded(event)
	if not IsServer() then return end
	if XHSPhase3BossAI:ShouldRevealBossBarFromAttackEvent(self, event) then
		XHSPhase3BossAI:RevealBossBarOnce(self)
	end
	if self.trial_active ~= true then return end
	if event.target ~= self:GetParent() then return end
	if event.attacker == nil or event.attacker:GetTeamNumber() ~= DOTA_TEAM_GOODGUYS then return end

	self:EndMirrorTrial(true)
end

function modifier_xhs_grom_phase3_ai:GetModifierIncomingDamage_Percentage(event)
	if self.trial_active == true then
		return -100
	end

	return 0
end

function modifier_xhs_grom_clone:IsHidden() return true end
function modifier_xhs_grom_clone:IsPurgable() return false end

function modifier_xhs_grom_clone:OnCreated(params)
	if not IsServer() then return end

	params = params or {}
	self.source_entindex = tonumber(params.source_entindex)
	self.ability_entindex = tonumber(params.ability_entindex)

	local parent = self:GetParent()
	local source = self.source_entindex ~= nil and EntIndexToHScript(self.source_entindex) or nil
	local maxHealth = IsValidAlive(source) and source:GetMaxHealth() or math.max(1, tonumber(params.health) or 6000)
	local health = IsValidAlive(source) and source:GetHealth() or maxHealth
	parent:SetBaseMaxHealth(maxHealth)
	parent:SetMaxHealth(maxHealth)
	parent:SetHealth(math.max(1, math.min(maxHealth, health)))
	if IsValidAlive(source) then
		local maxMana = source:GetMaxMana()
		parent:SetMaxMana(maxMana)
		parent:SetMana(math.min(maxMana, math.max(0, source:GetMana())))
	end
	parent:SetBaseDamageMin(math.floor(2500 * XHSPhase3BossAI:GetScale().damage))
	parent:SetBaseDamageMax(math.floor(3200 * XHSPhase3BossAI:GetScale().damage))
	parent:SetPhysicalArmorBaseValue(80)
	XHSPhase3BossAI:SetAbilityLevels(parent, GROM_ABILITIES)
	SyncAbilityCooldowns(source, parent)
	XHSPhase3BossAI:HideVanillaHealthBar(parent)
	self:StartIntervalThink(0.75)
	self:OnIntervalThink()
end

function modifier_xhs_grom_clone:OnIntervalThink()
	if not IsServer() then return end

	local parent = self:GetParent()
	if not IsValidAlive(parent) then
		self:StartIntervalThink(-1)
		return
	end

	OrderCloneToAttack(parent, GetGromArenaCenter(parent:GetAbsOrigin()))
end

function modifier_xhs_grom_clone:CheckState()
	return {
		[MODIFIER_STATE_NO_HEALTH_BAR] = true,
	}
end

function modifier_xhs_grom_clone:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_DEATH,
		MODIFIER_EVENT_ON_ATTACK_LANDED,
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL,
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_MAGICAL,
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PURE,
	}
end

function modifier_xhs_grom_clone:OnDeath(event)
	if not IsServer() then return end
	if event.unit ~= self:GetParent() then return end
	if self.resolved == true then return end

	self.resolved = true
	XHSGrom_OnFakeCloneKilled(self:GetParent(), self.source_entindex, self.ability_entindex, event.attacker)
end

function modifier_xhs_grom_clone:OnAttackLanded(event)
	if not IsServer() then return end
	if event.target ~= self:GetParent() then return end
	if self.resolved == true then return end
	if event.attacker == nil or event.attacker:GetTeamNumber() ~= DOTA_TEAM_GOODGUYS then return end

	self.resolved = true
	XHSGrom_OnFakeCloneKilled(self:GetParent(), self.source_entindex, self.ability_entindex, event.attacker)
	event.target:Kill(nil, event.attacker)
end

function modifier_xhs_grom_clone:GetAbsoluteNoDamagePhysical() return 1 end
function modifier_xhs_grom_clone:GetAbsoluteNoDamageMagical() return 1 end
function modifier_xhs_grom_clone:GetAbsoluteNoDamagePure() return 1 end
