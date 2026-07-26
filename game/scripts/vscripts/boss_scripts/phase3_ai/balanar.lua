require("boss_scripts/phase3_ai/core")
require("boss_scripts/phase3_ai/telegraphs")
require("boss_scripts/phase3_ai/balanar_abilities")

LinkLuaModifier("modifier_xhs_balanar_phase3_ai", "boss_scripts/phase3_ai/balanar.lua", LUA_MODIFIER_MOTION_NONE)

modifier_xhs_balanar_phase3_ai = modifier_xhs_balanar_phase3_ai or class({})
modifier_xhs_balanar_phase3_ai.XHS_LINK_CLIENT = true

local BALANAR_ABILITIES = {
	"xhs_balanar_nightfall",
	"xhs_balanar_dread_howl",
	"xhs_balanar_sleeping_terror",
	"xhs_balanar_carrion_swarm",
	"xhs_balanar_rain_of_chaos",
	"xhs_balanar_vampiric_presence",
}

local RAIN_OF_CHAOS_THRESHOLDS = { 75, 50, 25 }

local function IsValidAlive(unit)
	return unit ~= nil and IsValidEntity(unit) and not unit:IsNull() and unit:IsAlive()
end

local function GetBalanarArenaCenter(fallback)
	local spawner = Entities:FindByName(nil, "spawn_balanar")
	if spawner ~= nil then return spawner:GetAbsOrigin() end
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

	ability.xhs_balanar_context = context or {}
	ability.xhs_balanar_context.arena_center = ability.xhs_balanar_context.arena_center or GetBalanarArenaCenter(boss:GetAbsOrigin())

	if facePosition ~= nil then
		FaceUnitTowardsPosition(boss, facePosition)
	end

	XHSPhase3BossAI:ProtectCast(boss, ability)
	boss:CastAbilityNoTarget(ability, -1)
	return ability
end

function XHSBalanar_AttachPhase3AI(boss)
	if boss == nil or not IsValidEntity(boss) or boss:IsNull() then return end
	if boss:GetUnitName() ~= "npc_dota_hero_balanar" then return end

	boss:RemoveModifierByName("modifier_ai")
	if boss:HasModifier("modifier_xhs_balanar_phase3_ai") then return end
	XHSPhase3BossAI:HideVanillaHealthBar(boss)
	boss:AddNewModifier(boss, nil, "modifier_xhs_balanar_phase3_ai", {})
end

function modifier_xhs_balanar_phase3_ai:IsHidden() return true end
function modifier_xhs_balanar_phase3_ai:IsPurgable() return false end

function modifier_xhs_balanar_phase3_ai:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_TAKEDAMAGE,
		MODIFIER_EVENT_ON_ATTACK_LANDED,
	}
end

function modifier_xhs_balanar_phase3_ai:OnCreated()
	if not IsServer() then return end

	local boss = self:GetParent()
	self.arena_center = GetBalanarArenaCenter(boss:GetAbsOrigin())
	self.recent_positions = {}
	self.thresholds_done = {}
	self.patterns = {}
	self.state = "intro"
	self.cast_until = 0
	self.recover_until = 0
	self.last_pattern = nil

	boss.xhs_boss_bar_colors = {
		light_color = "#9b37ff",
		dark_color = "#160325",
	}
	boss.xhs_boss_bar_icon = "spellicons/custom/xhs_balanar_vampiric_presence"

	boss:RemoveModifierByName("modifier_ai")
	XHSPhase3BossAI:SetAbilityLevels(boss, BALANAR_ABILITIES)
	local bossHealth = boss:FindAbilityByName("boss_health")
	if bossHealth ~= nil and bossHealth:GetLevel() < 1 then bossHealth:SetLevel(1) end
	local cantDie = boss:FindAbilityByName("cant_die_generic")
	if cantDie ~= nil and cantDie:GetLevel() < 1 then cantDie:SetLevel(1) end

	self:UpdateBossBarMarkers()

	self:BuildPatternDeck()
	self:StartIntervalThink(0.25)
end

function modifier_xhs_balanar_phase3_ai:OnTakeDamage(event)
	if not IsServer() then return end
	if XHSPhase3BossAI:ShouldRevealBossBarFromDamageEvent(self, event) then
		XHSPhase3BossAI:RevealBossBarOnce(self)
	end
end

function modifier_xhs_balanar_phase3_ai:OnAttackLanded(event)
	if not IsServer() then return end
	if XHSPhase3BossAI:ShouldRevealBossBarFromAttackEvent(self, event) then
		XHSPhase3BossAI:RevealBossBarOnce(self)
	end
end

function modifier_xhs_balanar_phase3_ai:IsBossActive()
	local boss = self:GetParent()
	return boss ~= nil and IsValidEntity(boss) and not boss:IsNull() and boss:IsAlive() and boss.deathStart ~= true
end

function modifier_xhs_balanar_phase3_ai:BuildPatternDeck()
	local now = GameRules:GetGameTime()
	self.patterns = {
		{ id = "nightfall", weight = 2, cooldown = 18.0, ready_at = now + 5.0, run = function() return self:CastNightfall(nil) end },
		{ id = "dread_howl", weight = 3, cooldown = 8.0, ready_at = now + 1.5, run = function() return self:CastDreadHowl() end },
		{ id = "sleeping_terror", weight = 3, cooldown = 9.0, ready_at = now + 3.0, run = function() return self:CastSleepingTerror() end },
		{ id = "carrion_swarm", weight = 4, cooldown = 7.0, ready_at = now + 2.0, run = function() return self:CastCarrionSwarm() end },
	}
end

function modifier_xhs_balanar_phase3_ai:UpdateBossBarMarkers()
	local boss = self:GetParent()
	boss.xhs_boss_bar_markers = {}

	for index, threshold in ipairs(RAIN_OF_CHAOS_THRESHOLDS) do
		boss.xhs_boss_bar_markers[index] = {
			pct = threshold,
			kind = "companion",
			label = "Rain of Chaos",
			description = "Balanar calls down a violent meteor storm and becomes invulnerable while it falls.",
			triggered = self.thresholds_done[threshold] == true,
		}
	end
end

function modifier_xhs_balanar_phase3_ai:OnIntervalThink()
	XHSPhase3BossAI:RevealBossBarFromAggro(self)

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

	if self:TryThresholdRainOfChaos(now) then return end

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

function modifier_xhs_balanar_phase3_ai:TrackHeroPositions()
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

function modifier_xhs_balanar_phase3_ai:GetPredictedHeroPosition(hero, lead)
	if hero == nil then return self.arena_center end

	local tracked = self.recent_positions[tostring(hero:entindex())]
	if tracked == nil then return hero:GetAbsOrigin() end

	return tracked.current + (tracked.current - tracked.previous) * (lead or 1.0)
end

function modifier_xhs_balanar_phase3_ai:TryThresholdRainOfChaos(now)
	if self.state == "casting" or self.state == "recovery" then return false end

	local boss = self:GetParent()
	local hpPct = boss:GetHealth() / math.max(1, boss:GetMaxHealth()) * 100
	for _, threshold in ipairs(RAIN_OF_CHAOS_THRESHOLDS) do
		if hpPct <= threshold and self.thresholds_done[threshold] ~= true then
			local duration = self:CastRainOfChaos(threshold)
			if duration == nil or duration <= 0 then return false end

			self.thresholds_done[threshold] = true
			self.state = "casting"
			self.cast_until = now + duration
			self.recover_until = self.cast_until + XHSPhase3BossAI:ScaleDelay(0.9)
			self:UpdateBossBarMarkers()
			if UpdateBossBar ~= nil then
				UpdateBossBar(boss)
			end
			return true
		end
	end

	return false
end

function modifier_xhs_balanar_phase3_ai:RunPattern(entry, now)
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
	self.recover_until = self.cast_until + XHSPhase3BossAI:ScaleDelay(0.75)
end

function modifier_xhs_balanar_phase3_ai:PickHero(radius)
	local heroes = XHSPhase3BossAI:GetLivingHeroes(self.arena_center, radius or 2200)
	return heroes[RandomInt(1, math.max(1, #heroes))]
end

function modifier_xhs_balanar_phase3_ai:Reposition()
	local boss = self:GetParent()
	local target = self:PickHero(1800)
	if target == nil then return end

	local direction = boss:GetAbsOrigin() - target:GetAbsOrigin()
	direction.z = 0
	if direction:Length2D() <= 0 then direction = RandomVector(1) end
	XHSPhase3BossAI:MoveBoss(boss, target:GetAbsOrigin() + direction:Normalized() * RandomFloat(320, 520))
end

function modifier_xhs_balanar_phase3_ai:CastNightfall(threshold)
	local boss = self:GetParent()
	local ability = CastPreparedAbility(boss, "xhs_balanar_nightfall", { threshold = threshold }, boss:GetAbsOrigin() + boss:GetForwardVector() * 100)
	if ability == nil then return nil end
	return GetAbilityCastPoint(ability) + 0.35
end

function modifier_xhs_balanar_phase3_ai:CastDreadHowl()
	local boss = self:GetParent()
	local ability = CastPreparedAbility(boss, "xhs_balanar_dread_howl", {}, boss:GetAbsOrigin() + boss:GetForwardVector() * 100)
	if ability == nil then return nil end
	return GetAbilityCastPoint(ability) + 0.25
end

function modifier_xhs_balanar_phase3_ai:CastSleepingTerror()
	local boss = self:GetParent()
	local ability = boss:FindAbilityByName("xhs_balanar_sleeping_terror")
	if ability == nil then return nil end

	local target = self:PickHero(2200)
	if target == nil then return nil end
	local position = self:GetPredictedHeroPosition(target, 0.8)
	local castAbility = CastPreparedAbility(boss, "xhs_balanar_sleeping_terror", {
		target = target,
		position = position,
	}, position)
	if castAbility == nil then return nil end
	return GetAbilityCastPoint(castAbility) + 0.3
end

function modifier_xhs_balanar_phase3_ai:CastCarrionSwarm()
	local boss = self:GetParent()
	local target = self:PickHero(2200)
	if target == nil then return nil end

	local targetPosition = self:GetPredictedHeroPosition(target, 0.85)
	local castAbility = CastPreparedAbility(boss, "xhs_balanar_carrion_swarm", {
		direction = NormalizeDirection(targetPosition - boss:GetAbsOrigin()),
	}, targetPosition)
	if castAbility == nil then return nil end
	return GetAbilityCastPoint(castAbility) + 0.25
end

function modifier_xhs_balanar_phase3_ai:CastRainOfChaos()
	local boss = self:GetParent()
	local ability = boss:FindAbilityByName("xhs_balanar_rain_of_chaos")
	if ability == nil then return nil end

	local castAbility = CastPreparedAbility(boss, "xhs_balanar_rain_of_chaos", {}, boss:GetAbsOrigin() + boss:GetForwardVector() * 100)
	if castAbility == nil then return nil end
	return GetAbilityCastPoint(castAbility) + ability:GetSpecialValueFor("duration") + 0.35
end
