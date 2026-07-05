require("boss_scripts/phase3_ai/core")
require("boss_scripts/phase3_ai/telegraphs")
require("boss_scripts/phase3_ai/illidan_abilities")

LinkLuaModifier("modifier_xhs_illidan_phase3_ai", "boss_scripts/phase3_ai/illidan.lua", LUA_MODIFIER_MOTION_NONE)

modifier_xhs_illidan_phase3_ai = modifier_xhs_illidan_phase3_ai or class({})
modifier_xhs_illidan_phase3_ai.XHS_LINK_CLIENT = true

local ILLIDAN_ABILITIES = {
	"xhs_illidan_metamorphosis",
	"xhs_illidan_fel_beam",
	"xhs_illidan_shadow_dash",
	"xhs_illidan_immolation_burst",
	"xhs_illidan_glaive_storm",
	"xhs_illidan_demon_hunter",
}

local METAMORPHOSIS_THRESHOLDS = { 70, 35 }

local function IsValidAlive(unit)
	return unit ~= nil and IsValidEntity(unit) and not unit:IsNull() and unit:IsAlive()
end

local function GetIllidanArenaCenter(fallback)
	local spawner = Entities:FindByName(nil, "spawn_illidan")
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

local function NormalizeDirection(direction)
	if direction == nil then return Vector(1, 0, 0) end
	direction.z = 0
	if direction:Length2D() <= 0 then return Vector(1, 0, 0) end
	return direction:Normalized()
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
	if ability == nil or ability:IsNull() then return nil end
	if XHSPhase3BossAI:IsCastBlocked(boss) then return nil end

	ability.xhs_illidan_context = context or {}
	ability.xhs_illidan_context.arena_center = ability.xhs_illidan_context.arena_center or GetIllidanArenaCenter(boss:GetAbsOrigin())

	if facePosition ~= nil then
		FaceUnitTowardsPosition(boss, facePosition)
	end

	XHSPhase3BossAI:ProtectCast(boss, ability)
	boss:CastAbilityNoTarget(ability, -1)
	return ability
end

function XHSIllidan_AttachPhase3AI(boss)
	if boss == nil or not IsValidEntity(boss) or boss:IsNull() then return end
	if boss:GetUnitName() ~= "npc_dota_hero_illidan" then return end

	boss:RemoveModifierByName("modifier_ai")
	if boss:HasModifier("modifier_xhs_illidan_phase3_ai") then return end
	XHSPhase3BossAI:HideVanillaHealthBar(boss)
	boss:AddNewModifier(boss, nil, "modifier_xhs_illidan_phase3_ai", {})
end

function modifier_xhs_illidan_phase3_ai:IsHidden() return true end
function modifier_xhs_illidan_phase3_ai:IsPurgable() return false end

function modifier_xhs_illidan_phase3_ai:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_TAKEDAMAGE,
		MODIFIER_EVENT_ON_ATTACK_LANDED,
	}
end

function modifier_xhs_illidan_phase3_ai:OnCreated()
	if not IsServer() then return end

	local boss = self:GetParent()
	self.arena_center = GetIllidanArenaCenter(boss:GetAbsOrigin())
	self.recent_positions = {}
	self.thresholds_done = {}
	self.patterns = {}
	self.state = "intro"
	self.cast_until = 0
	self.recover_until = 0
	self.last_pattern = nil

	boss.xhs_boss_bar_colors = {
		light_color = "#77ff3d",
		dark_color = "#170039",
	}
	boss.xhs_boss_bar_icon = "spellicons/custom/xhs_illidan_demon_hunter"

	boss:RemoveModifierByName("modifier_ai")
	XHSPhase3BossAI:SetAbilityLevels(boss, ILLIDAN_ABILITIES)
	local bossHealth = boss:FindAbilityByName("boss_health")
	if bossHealth ~= nil and bossHealth:GetLevel() < 1 then bossHealth:SetLevel(1) end
	local cantDie = boss:FindAbilityByName("cant_die_generic")
	if cantDie ~= nil and cantDie:GetLevel() < 1 then cantDie:SetLevel(1) end

	self:UpdateBossBarMarkers()

	self:BuildPatternDeck()
	self:StartIntervalThink(0.25)
end

function modifier_xhs_illidan_phase3_ai:OnTakeDamage(event)
	if not IsServer() then return end
	if XHSPhase3BossAI:ShouldRevealBossBarFromDamageEvent(self, event) then
		XHSPhase3BossAI:RevealBossBarOnce(self)
	end
end

function modifier_xhs_illidan_phase3_ai:OnAttackLanded(event)
	if not IsServer() then return end
	if XHSPhase3BossAI:ShouldRevealBossBarFromAttackEvent(self, event) then
		XHSPhase3BossAI:RevealBossBarOnce(self)
	end
end

function modifier_xhs_illidan_phase3_ai:IsBossActive()
	local boss = self:GetParent()
	return boss ~= nil and IsValidEntity(boss) and not boss:IsNull() and boss:IsAlive() and boss.deathStart ~= true
end

function modifier_xhs_illidan_phase3_ai:BuildPatternDeck()
	local now = GameRules:GetGameTime()
	self.patterns = {
		{ id = "fel_beam", weight = 4, cooldown = 7.0, ready_at = now + 1.5, run = function() return self:CastFelBeam() end },
		{ id = "shadow_dash", weight = 3, cooldown = 9.0, ready_at = now + 3.0, run = function() return self:CastShadowDash() end },
		{ id = "immolation_burst", weight = 3, cooldown = 11.0, ready_at = now + 2.0, run = function() return self:CastImmolationBurst() end },
		{ id = "glaive_storm", weight = 4, cooldown = 10.0, ready_at = now + 4.0, run = function() return self:CastGlaiveStorm() end },
	}
end

function modifier_xhs_illidan_phase3_ai:UpdateBossBarMarkers()
	local boss = self:GetParent()
	boss.xhs_boss_bar_markers = {}

	for index, threshold in ipairs(METAMORPHOSIS_THRESHOLDS) do
		boss.xhs_boss_bar_markers[index] = {
			pct = threshold,
			kind = "companion",
			label = "Metamorphosis",
			description = "Illidan erupts in fel energy, empowering his next attacks.",
			triggered = self.thresholds_done[threshold] == true,
		}
	end
end

function modifier_xhs_illidan_phase3_ai:OnIntervalThink()
	if not self:IsBossActive() then
		self.state = "dead"
		self:StartIntervalThink(-1)
		return
	end

	local boss = self:GetParent()
	local now = GameRules:GetGameTime()
	boss:RemoveModifierByName("modifier_ai")
	self:TrackHeroPositions()

	if boss:HasModifier("modifier_invulnerable") or boss:HasModifier("modifier_pause_creeps") then
		self.state = "intro"
		return
	end

	if self:TryThresholdMetamorphosis(now) then return end

	if self.state == "casting" then
		if now < self.cast_until then return end
		self.state = "recovery"
	end

	if self.state == "recovery" then
		if now < self.recover_until then return end
		self.state = "idle"
	end

	local entry = XHSPhase3BossAI:WeightedChoice(self.patterns, now)
	if entry == nil then
		self:Reposition()
		return
	end

	self:RunPattern(entry, now)
end

function modifier_xhs_illidan_phase3_ai:TrackHeroPositions()
	local heroes = XHSPhase3BossAI:GetLivingHeroes(self.arena_center, 2200)
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

function modifier_xhs_illidan_phase3_ai:GetPredictedHeroPosition(hero, lead)
	if hero == nil then return self.arena_center end

	local position = hero:GetAbsOrigin()
	local tracked = self.recent_positions[tostring(hero:entindex())]
	if tracked == nil then return position end

	local velocity = tracked.current - tracked.previous
	return tracked.current + velocity * (lead or 1.0)
end

function modifier_xhs_illidan_phase3_ai:TryThresholdMetamorphosis(now)
	if self.state == "casting" or self.state == "recovery" then return false end

	local boss = self:GetParent()
	local hpPct = boss:GetHealth() / math.max(1, boss:GetMaxHealth()) * 100
	for _, threshold in ipairs(METAMORPHOSIS_THRESHOLDS) do
		if hpPct <= threshold and self.thresholds_done[threshold] ~= true then
			local duration = self:CastMetamorphosis(threshold)
			if duration == nil or duration <= 0 then return false end

			self.thresholds_done[threshold] = true
			self.state = "casting"
			self.cast_until = now + duration
			self.recover_until = self.cast_until + XHSPhase3BossAI:ScaleDelay(1.0)
			self:UpdateBossBarMarkers()
			return true
		end
	end

	return false
end

function modifier_xhs_illidan_phase3_ai:RunPattern(entry, now)
	if entry == nil then return end

	local duration = entry.run()
	if duration == nil or duration <= 0 then
		entry.ready_at = now + 1.0
		return
	end

	entry.ready_at = now + XHSPhase3BossAI:ScaleDelay(entry.cooldown or 8.0)
	self.last_pattern = entry.id
	self.state = "casting"
	self.cast_until = now + duration
	self.recover_until = self.cast_until + XHSPhase3BossAI:ScaleDelay(0.8)
end

function modifier_xhs_illidan_phase3_ai:Reposition()
	local boss = self:GetParent()
	local heroes = XHSPhase3BossAI:GetLivingHeroes(self.arena_center, 1800)
	local target = heroes[RandomInt(1, math.max(1, #heroes))]
	if target == nil then return end

	local direction = boss:GetAbsOrigin() - target:GetAbsOrigin()
	direction.z = 0
	if direction:Length2D() <= 0 then direction = RandomVector(1) end
	local position = target:GetAbsOrigin() + direction:Normalized() * RandomFloat(380, 560)
	XHSPhase3BossAI:MoveBoss(boss, position)
end

function modifier_xhs_illidan_phase3_ai:CastMetamorphosis(threshold)
	local boss = self:GetParent()
	local ability = CastPreparedAbility(boss, "xhs_illidan_metamorphosis", { threshold = threshold }, boss:GetAbsOrigin() + boss:GetForwardVector() * 100)
	if ability == nil then return nil end

	return GetAbilityCastPoint(ability) + 0.35
end

function modifier_xhs_illidan_phase3_ai:CastFelBeam()
	local boss = self:GetParent()
	local ability = boss:FindAbilityByName("xhs_illidan_fel_beam")
	if ability == nil then return nil end

	local heroes = XHSPhase3BossAI:GetLivingHeroes(self.arena_center, 2200)
	local target = heroes[RandomInt(1, math.max(1, #heroes))]
	if target == nil then return nil end

	local targetPosition = self:GetPredictedHeroPosition(target, 0.9)
	local startPosition = boss:GetAbsOrigin()
	local direction = NormalizeDirection(targetPosition - startPosition)
	local castAbility = CastPreparedAbility(boss, "xhs_illidan_fel_beam", {
		start = startPosition,
		direction = direction,
	}, targetPosition)
	if castAbility == nil then return nil end

	return GetAbilityCastPoint(castAbility) + 0.25
end

function modifier_xhs_illidan_phase3_ai:CastShadowDash()
	local boss = self:GetParent()
	local ability = boss:FindAbilityByName("xhs_illidan_shadow_dash")
	if ability == nil then return nil end

	local heroes = XHSPhase3BossAI:GetLivingHeroes(self.arena_center, 2200)
	local target = heroes[RandomInt(1, math.max(1, #heroes))]
	if target == nil then return nil end

	local targetPosition = self:GetPredictedHeroPosition(target, 0.55)
	local castAbility = CastPreparedAbility(boss, "xhs_illidan_shadow_dash", {
		target = target,
		position = targetPosition,
	}, targetPosition)
	if castAbility == nil then return nil end

	return GetAbilityCastPoint(castAbility) + 0.35
end

function modifier_xhs_illidan_phase3_ai:CastImmolationBurst()
	local boss = self:GetParent()
	local ability = CastPreparedAbility(boss, "xhs_illidan_immolation_burst", {}, boss:GetAbsOrigin() + boss:GetForwardVector() * 100)
	if ability == nil then return nil end

	return GetAbilityCastPoint(ability) + ability:GetSpecialValueFor("duration")
end

function modifier_xhs_illidan_phase3_ai:CastGlaiveStorm()
	local boss = self:GetParent()
	local ability = boss:FindAbilityByName("xhs_illidan_glaive_storm")
	if ability == nil then return nil end

	local count = XHSPhase3BossAI:ScaleDensity(ability:GetSpecialValueFor("point_count"), 3)
	local points = {}
	local heroes = XHSPhase3BossAI:GetLivingHeroes(self.arena_center, 2200)
	for i = 1, count do
		local hero = heroes[RandomInt(1, math.max(1, #heroes))]
		local position
		if hero ~= nil then
			position = self:GetPredictedHeroPosition(hero, 0.65) + RandomVector(RandomFloat(80, 260))
		else
			position = PositionOnRing(self.arena_center, RandomFloat(300, 850), i, count, RandomFloat(0, 80))
		end

		points[#points + 1] = {
			position = position,
			delay = (i - 1) * ability:GetSpecialValueFor("point_delay"),
		}
	end

	local castAbility = CastPreparedAbility(boss, "xhs_illidan_glaive_storm", {
		points = points,
	}, points[1] and points[1].position or self.arena_center)
	if castAbility == nil then return nil end

	return GetAbilityCastPoint(castAbility) + (count - 1) * ability:GetSpecialValueFor("point_delay") + 0.4
end
