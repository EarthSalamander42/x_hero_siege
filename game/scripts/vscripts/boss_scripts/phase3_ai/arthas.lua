require("boss_scripts/phase3_ai/core")
require("boss_scripts/phase3_ai/telegraphs")
require("boss_scripts/phase3_ai/arthas_abilities")

modifier_xhs_arthas_phase3_ai = modifier_xhs_arthas_phase3_ai or class({})
modifier_xhs_arthas_phase3_ai.XHS_LINK_CLIENT = true
LinkLuaModifier("modifier_xhs_arthas_phase3_ai", "boss_scripts/phase3_ai/arthas.lua", LUA_MODIFIER_MOTION_NONE)

local ARTHAS_ABILITIES = {
	"xhs_arthas_frostmourne_mark",
	"xhs_arthas_frozen_chains",
	"xhs_arthas_death_advance",
	"xhs_arthas_frostmourne_execute",
	"boss_health",
	"cant_die_generic",
}

local function IsValidAlive(unit)
	return unit ~= nil and IsValidEntity(unit) and not unit:IsNull() and unit:IsAlive()
end

local function GetArenaCenter(fallback)
	local point = Entities:FindByName(nil, "npc_dota_spawner_magtheridon_arena")
	if point ~= nil then return point:GetAbsOrigin() end
	return fallback or Vector(0, 0, 0)
end

local function NormalizeDirection(direction)
	if direction == nil then return Vector(1, 0, 0) end
	direction.z = 0
	if direction:Length2D() <= 0 then return Vector(1, 0, 0) end
	return direction:Normalized()
end

local function AddAbilityIfMissing(unit, abilityName)
	local ability = unit:FindAbilityByName(abilityName)
	if ability == nil then
		ability = unit:AddAbility(abilityName)
	end
	if ability ~= nil and ability:GetLevel() < 1 then
		ability:SetLevel(XHSPhase3BossAI:GetDifficulty())
	end
	return ability
end

local function CastPreparedAbility(boss, abilityName, context, position)
	if not IsValidAlive(boss) then return nil end
	local ability = boss:FindAbilityByName(abilityName)
	if ability == nil or ability:IsNull() or not ability:IsCooldownReady() then return nil end
	if XHSPhase3BossAI:IsCastBlocked(boss) then return nil end

	ability.xhs_arthas_context = context or {}
	XHSPhase3BossAI:ProtectCast(boss, ability, 0.25)
	boss:CastAbilityNoTarget(ability, -1)
	return ability
end

function XHSArthas_AttachPhase3AI(boss)
	if boss == nil or not IsValidEntity(boss) or boss:IsNull() then return end
	if boss:GetUnitName() ~= "npc_dota_hero_arthas" then return end
	if boss:HasModifier("modifier_xhs_arthas_phase3_ai") then return end

	boss:RemoveModifierByName("modifier_ai")
	XHSPhase3BossAI:HideVanillaHealthBar(boss)
	for _, abilityName in pairs(ARTHAS_ABILITIES) do
		AddAbilityIfMissing(boss, abilityName)
	end
	boss:AddNewModifier(boss, nil, "modifier_xhs_arthas_phase3_ai", {})
end

function modifier_xhs_arthas_phase3_ai:IsHidden() return true end
function modifier_xhs_arthas_phase3_ai:IsPurgable() return false end
function modifier_xhs_arthas_phase3_ai:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_TAKEDAMAGE,
		MODIFIER_EVENT_ON_ATTACK_LANDED,
	}
end

function modifier_xhs_arthas_phase3_ai:OnCreated()
	if not IsServer() then return end
	self.boss = self:GetParent()
	self.arena_center = GetArenaCenter(self.boss:GetAbsOrigin())
	self.hero_positions = {}
	self.next_action = GameRules:GetGameTime() + 3.0
	self.patterns = self:BuildPatternDeck()

	self.boss.xhs_boss_bar_icon = "spellicons/custom/arthas_frostmourne"
	self.boss.xhs_boss_bar_colors = {
		dark_color = "#08223a",
		light_color = "#bff4ff",
	}
	self.boss.xhs_boss_bar_markers = {
		{ percent = 66, label = "Frostmourne Mark", tooltip = "Marked heroes take amplified Arthas burst." },
		{ percent = 33, label = "Execute Priority", tooltip = "Arthas prefers rooted or marked heroes for Execute." },
	}
	ShowBossBar(self.boss)
	self:StartIntervalThink(0.25)
end

function modifier_xhs_arthas_phase3_ai:IsBossActive()
	return IsValidAlive(self.boss) and self.boss.deathStart ~= true and not self.boss:IsInvulnerable()
end

function modifier_xhs_arthas_phase3_ai:BuildPatternDeck()
	local now = GameRules:GetGameTime()
	return {
		{ id = "mark", weight = 1.2, cooldown = 7.5, ready_at = now + 1.0, run = function() return self:CastMark() end },
		{ id = "chains", weight = 1.4, cooldown = 8.5, ready_at = now + 2.0, run = function() return self:CastChains() end },
		{ id = "advance", weight = 1.2, cooldown = 7.0, ready_at = now + 3.0, run = function() return self:CastDeathAdvance() end },
		{ id = "execute", weight = 1.0, cooldown = 12.0, ready_at = now + 5.0, run = function() return self:CastExecute() end },
	}
end

function modifier_xhs_arthas_phase3_ai:OnIntervalThink()
	if not IsServer() then return end
	if not self:IsBossActive() then return end
	if XHSPhase3BossAI:IsCastBlocked(self.boss) then return end

	self:TrackHeroPositions()
	local now = GameRules:GetGameTime()
	if now < (self.next_action or 0) then return end

	local entry = XHSPhase3BossAI:WeightedChoice(self.patterns, now)
	if entry == nil then
		self.next_action = now + 0.8
		return
	end

	if entry.run() == true then
		local ability = self.boss:FindAbilityByName(self:GetAbilityNameForPattern(entry.id))
		entry.ready_at = now + XHSPhase3BossAI:ScaleDelay(entry.cooldown)
		self.next_action = now + (ability and ability:GetCastPoint() or 1.0) + 1.0
	else
		entry.ready_at = now + 1.0
		self.next_action = now + 0.6
	end
end

function modifier_xhs_arthas_phase3_ai:GetAbilityNameForPattern(id)
	if id == "mark" then return "xhs_arthas_frostmourne_mark" end
	if id == "chains" then return "xhs_arthas_frozen_chains" end
	if id == "advance" then return "xhs_arthas_death_advance" end
	return "xhs_arthas_frostmourne_execute"
end

function modifier_xhs_arthas_phase3_ai:TrackHeroPositions()
	local heroes = XHSPhase3BossAI:GetLivingHeroes(self.arena_center, 2600, true)
	for _, hero in pairs(heroes) do
		if IsValidAlive(hero) then
			local key = tostring(hero:entindex())
			local current = hero:GetAbsOrigin()
			local previous = self.hero_positions[key]
			local velocity = Vector(0, 0, 0)
			if previous ~= nil then
				velocity = current - previous.position
			end
			self.hero_positions[key] = { position = current, velocity = velocity }
		end
	end
end

function modifier_xhs_arthas_phase3_ai:GetPredictedHeroPosition(hero, lead)
	if not IsValidAlive(hero) then return self.arena_center end
	local data = self.hero_positions[tostring(hero:entindex())]
	if data == nil then return hero:GetAbsOrigin() end
	return hero:GetAbsOrigin() + (data.velocity or Vector(0, 0, 0)) * (lead or 1.0)
end

function modifier_xhs_arthas_phase3_ai:PickHero(preferMarked, preferRooted)
	local heroes = XHSPhase3BossAI:GetLivingHeroes(self.arena_center, 2600, true)
	local fallback = nil
	for _, hero in pairs(heroes) do
		if IsValidAlive(hero) then
			fallback = fallback or hero
			if preferRooted == true and hero:HasModifier("modifier_xhs_arthas_chains") then return hero end
			if preferMarked == true and hero:HasModifier("modifier_xhs_arthas_mark") then return hero end
		end
	end
	if fallback ~= nil then return fallback end
	return nil
end

function modifier_xhs_arthas_phase3_ai:CastMark()
	local target = self:PickHero(false, false)
	if target == nil then return false end
	local ability = CastPreparedAbility(self.boss, "xhs_arthas_frostmourne_mark", { target = target }, target:GetAbsOrigin())
	return ability ~= nil
end

function modifier_xhs_arthas_phase3_ai:CastChains()
	local target = self:PickHero(true, false)
	if target == nil then return false end
	local position = self:GetPredictedHeroPosition(target, 1.0)
	local ability = CastPreparedAbility(self.boss, "xhs_arthas_frozen_chains", { target = target, position = position }, position)
	return ability ~= nil
end

function modifier_xhs_arthas_phase3_ai:CastDeathAdvance()
	local target = self:PickHero(true, true)
	if target == nil then return false end
	local position = self:GetPredictedHeroPosition(target, 0.8)
	local direction = NormalizeDirection(position - self.boss:GetAbsOrigin())
	XHSPhase3BossAI:MoveBoss(self.boss, self.boss:GetAbsOrigin() + direction * 120)
	local ability = CastPreparedAbility(self.boss, "xhs_arthas_death_advance", { target = target, position = position }, position)
	return ability ~= nil
end

function modifier_xhs_arthas_phase3_ai:CastExecute()
	local target = self:PickHero(true, true)
	if target == nil then return false end
	local position = self:GetPredictedHeroPosition(target, 0.7)
	local ability = CastPreparedAbility(self.boss, "xhs_arthas_frostmourne_execute", { target = target, position = position }, position)
	return ability ~= nil
end

function modifier_xhs_arthas_phase3_ai:OnTakeDamage(event)
	if not IsServer() then return end
	if XHSPhase3BossAI:ShouldRevealBossBarFromDamageEvent(self, event) then
		XHSPhase3BossAI:RevealBossBarOnce(self)
	end
end

function modifier_xhs_arthas_phase3_ai:OnAttackLanded(event)
	if not IsServer() then return end
	if XHSPhase3BossAI:ShouldRevealBossBarFromAttackEvent(self, event) then
		XHSPhase3BossAI:RevealBossBarOnce(self)
	end
end
