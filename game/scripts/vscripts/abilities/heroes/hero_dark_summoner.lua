require("libraries/timers")

LinkLuaModifier("modifier_holdout_soul_harvest", "abilities/heroes/hero_dark_summoner.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_holdout_souls_harvested", "abilities/heroes/hero_dark_summoner.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_holdout_soul_malefice_amp", "abilities/heroes/hero_dark_summoner.lua", LUA_MODIFIER_MOTION_NONE)

local SOUL_HARVEST_ABILITY_NAME = "holdout_soul_harvest"
local SOUL_HARVEST_MODIFIER_NAME = "modifier_holdout_souls_harvested"

local function GetSoulHarvestAbility(caster)
	if caster == nil or caster:IsNull() then return nil end
	return caster:FindAbilityByName(SOUL_HARVEST_ABILITY_NAME)
end

local function GetSoulHarvestSpecial(caster, name, fallback)
	local ability = GetSoulHarvestAbility(caster)
	if ability == nil then return fallback or 0 end
	local value = ability:GetSpecialValueFor(name)
	return value ~= 0 and value or (fallback or 0)
end

local function GetSoulsHarvested(caster)
	if caster == nil or caster:IsNull() then return 0 end
	local modifier = caster:FindModifierByName(SOUL_HARVEST_MODIFIER_NAME)
	return modifier ~= nil and modifier:GetStackCount() or 0
end

local function AddHarvestedSoul(caster, ability)
	if caster == nil or caster:IsNull() or not caster:IsAlive() then return end
	local modifier = caster:FindModifierByName(SOUL_HARVEST_MODIFIER_NAME)
	if modifier == nil then
		modifier = caster:AddNewModifier(caster, ability, SOUL_HARVEST_MODIFIER_NAME, {})
	end
	if modifier ~= nil and modifier.AddSoul ~= nil then
		modifier:AddSoul()
	end
end

function DarkSummonerShadowBoltSoulSynergy(keys)
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability
	if caster == nil or target == nil or ability == nil or target:IsNull() or not target:IsAlive() then return end

	local souls = GetSoulsHarvested(caster)
	if souls <= 0 then return end
	local damagePct = GetSoulHarvestSpecial(caster, "shadow_bolt_damage_per_soul", 2)
	local bonusDamage = ability:GetAbilityDamage() * souls * damagePct * 0.01
	if bonusDamage <= 0 then return end

	ApplyDamage({
		attacker = caster,
		victim = target,
		ability = ability,
		damage = bonusDamage,
		damage_type = DAMAGE_TYPE_MAGICAL,
	})
end

-- Shadowraze helper
function ShadowrazeCreateRaze(keys, point, radius, particle_raze)
local caster = keys.caster
local ability = keys.ability
local ability_level = ability:GetLevel() - 1
local sound_raze = keys.sound_raze
local damage = ability:GetLevelSpecialValueFor("raze_damage", ability_level)
local damage_type = ability:GetAbilityDamageType()
local souls = GetSoulsHarvested(caster)
local damagePerSoul = GetSoulHarvestSpecial(caster, "corruption_damage_per_soul", 2)
local radiusPerSoul = GetSoulHarvestSpecial(caster, "corruption_radius_per_soul", 5)
damage = damage * (1 + souls * damagePerSoul * 0.01)
radius = radius + souls * radiusPerSoul

	-- Raze particle
	local raze_pfx = ParticleManager:CreateParticle(particle_raze, PATTACH_CUSTOMORIGIN, nil)
	ParticleManager:SetParticleControl(raze_pfx, 0, point)
	ParticleManager:SetParticleControl(raze_pfx, 1, point)
	ParticleManager:ReleaseParticleIndex(raze_pfx)

	-- Raze sound (on dummy)
	local dummy = CreateUnitByName("npc_dummy_unit", point, false, nil, nil, caster:GetTeamNumber())
	dummy:EmitSound(sound_raze)
	dummy:Destroy()

	-- Find raze targets hit
	local enemies = FindUnitsInRadius(caster:GetTeam(), point, nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
	for _, enemy in pairs(enemies) do

		-- Apply damage AFTER combo check to allow combos on heroes that die from the raze damage
		ApplyDamage({attacker = caster, victim = enemy, ability = ability, damage = damage, damage_type = damage_type})
	end
end

function Shadowraze3Cast(keys)
local caster = keys.caster
local ability = keys.ability
local ability_level = ability:GetLevel() - 1
local radius = ability:GetLevelSpecialValueFor("shadowraze_radius", ability_level)
local distance1 = ability:GetLevelSpecialValueFor("shadowraze_range1", ability_level)
local distance2 = ability:GetLevelSpecialValueFor("shadowraze_range2", ability_level)
local distance3 = ability:GetLevelSpecialValueFor("shadowraze_range3", ability_level)
local raze_amount = ability:GetLevelSpecialValueFor("raze_amount", ability_level)
local raze_particles = "particles/econ/items/shadow_fiend/sf_fire_arcana/sf_fire_arcana_shadowraze.vpcf"	--particles/hero/nevermore/nevermore_shadowraze_150.vpcf

	local caster_loc = caster:GetAbsOrigin()
	local forward_vector = caster:GetForwardVector()
	local hero_hit = true
	raze_point1 = caster_loc + forward_vector * distance1
	raze_point2 = caster_loc + forward_vector * distance2
	raze_point3 = caster_loc + forward_vector * distance3

	hero_hit = ShadowrazeCreateRaze(keys, raze_point1, radius, raze_particles) or hero_hit
	Timers:CreateTimer(0.2, function()
		hero_hit = ShadowrazeCreateRaze(keys, raze_point2, radius, raze_particles) or hero_hit
	end)
	Timers:CreateTimer(0.4, function()
		hero_hit = ShadowrazeCreateRaze(keys, raze_point3, radius, raze_particles) or hero_hit
	end)
end

-- Octarine Core handling
function ConsumingFlame(keys)
local caster = keys.caster
local target = keys.unit
local ability = keys.ability
local ability_level = ability:GetLevel() - 1
local damage = keys.damage
local modifier_prevent = keys.modifier_prevent
local hero_lifesteal = ability:GetLevelSpecialValueFor("hero_lifesteal", ability_level)
local creep_lifesteal = ability:GetLevelSpecialValueFor("creep_lifesteal", ability_level)
local souls = GetSoulsHarvested(caster)
local lifestealPerSoul = GetSoulHarvestSpecial(caster, "consuming_flame_lifesteal_per_soul", 0.5)
hero_lifesteal = hero_lifesteal + souls * lifestealPerSoul
creep_lifesteal = creep_lifesteal + souls * lifestealPerSoul

	-- If there's no valid target, do nothing
	if target:IsBuilding() or target:IsTower() or target == caster or target:HasModifier(modifier_prevent) or target:IsIllusion() then
		return nil
	end

	-- Delay the lifesteal for one game tick to prevent blademail/octarine interaction
	Timers:CreateTimer(0.01, function()
		local health_before = caster:GetHealth()

		-- If the target is a real hero, heal for the full value
		if target:IsRealHero() or target:IsConsideredHero() then
			caster:Heal(damage * hero_lifesteal / 100, caster)
		-- else, heal for the reduced value
		else
			caster:Heal(damage * creep_lifesteal / 100, caster)
		end

		local actual_heal = math.max(0, caster:GetHealth() - health_before)
		if actual_heal > 0 and XHSQueueSupporterSpellLifestealFX ~= nil then
			XHSQueueSupporterSpellLifestealFX(caster, target, actual_heal)
		end
	end)
end

function ConsumingFlameAttack(keys)
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability
	local modifier_prevent = keys.modifier_prevent

	-- Applies the lifesteal-prevention modifier
	ability:ApplyDataDrivenModifier(caster, target, modifier_prevent, {})
end

function DarkSummonerDarkKingSoulSynergy(keys)
	local caster = keys.caster
	local ability = keys.ability
	local point = keys.target_points ~= nil and keys.target_points[1] or nil
	if caster == nil or ability == nil or point == nil then return end

	local souls = GetSoulsHarvested(caster)
	local soulsPerExtra = math.max(1, GetSoulHarvestSpecial(caster, "dark_king_souls_per_extra", 5))
	local extraCount = math.floor(souls / soulsPerExtra)
	if extraCount <= 0 then return end

	local duration = ability:GetSpecialValueFor("infernal_duration")
	for index = 1, extraCount do
		local angle = (index - 1) * (360 / extraCount)
		local offset = Vector(math.cos(math.rad(angle)), math.sin(math.rad(angle)), 0) * 90
		local summon = CreateUnitByName(
			"npc_dota_dark_king",
			point + offset,
			true,
			caster,
			caster,
			caster:GetTeamNumber()
		)
		if summon ~= nil then
			FindClearSpaceForUnit(summon, point + offset, true)
			summon:SetOwner(caster)
			local playerID = caster:GetPlayerOwnerID()
			if playerID ~= nil and playerID >= 0 then
				summon:SetControllableByPlayer(playerID, true)
			end
			summon:AddNewModifier(caster, ability, "modifier_kill", { duration = duration })
			summon:AddNewModifier(caster, ability, "modifier_invulnerable", { duration = duration })

			local shield = ParticleManager:CreateParticle(
				"particles/econ/items/abaddon/abaddon_alliance/abaddon_aphotic_shield_alliance_explosion.vpcf",
				PATTACH_ABSORIGIN_FOLLOW,
				summon
			)
			ParticleManager:ReleaseParticleIndex(shield)
			local coil = ParticleManager:CreateParticle(
				"particles/econ/items/abaddon/abaddon_alliance/abaddon_death_coil_alliance_explosion.vpcf",
				PATTACH_ABSORIGIN_FOLLOW,
				summon
			)
			ParticleManager:ReleaseParticleIndex(coil)
		end
	end
end

holdout_soul_harvest = holdout_soul_harvest or class({})

function holdout_soul_harvest:OnSpellStart()
	local caster = self:GetCaster()
	local radius = self:GetSpecialValueFor("radius")
	local duration = self:GetSpecialValueFor("duration")
	local enemies = FindUnitsInRadius(
		caster:GetTeamNumber(),
		caster:GetAbsOrigin(),
		nil,
		radius,
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		DOTA_UNIT_TARGET_FLAG_NOT_ANCIENTS,
		FIND_ANY_ORDER,
		false
	)

	for _, enemy in pairs(enemies) do
		enemy:AddNewModifier(caster, self, "modifier_holdout_soul_harvest", { duration = duration })
	end

	caster:EmitSound("Hero_Necrolyte.DeathPulse")
	local particle = ParticleManager:CreateParticle(
		"particles/units/heroes/hero_skeletonking/wraith_king_reincarnate_explode.vpcf",
		PATTACH_ABSORIGIN_FOLLOW,
		caster
	)
	ParticleManager:ReleaseParticleIndex(particle)
end

modifier_holdout_soul_harvest = modifier_holdout_soul_harvest or class({})
modifier_holdout_soul_harvest.XHS_LINK_CLIENT = true

function modifier_holdout_soul_harvest:IsHidden() return false end
function modifier_holdout_soul_harvest:IsDebuff() return true end
function modifier_holdout_soul_harvest:IsPurgable() return true end
function modifier_holdout_soul_harvest:GetEffectName()
	return "particles/units/heroes/hero_necrolyte/necrolyte_spirit_ground_aura.vpcf"
end
function modifier_holdout_soul_harvest:GetEffectAttachType() return PATTACH_ABSORIGIN_FOLLOW end

function modifier_holdout_soul_harvest:OnCreated()
	local ability = self:GetAbility()
	self.moveSlow = ability ~= nil and ability:GetSpecialValueFor("move_slow_pct") or 0
	self.exploded = false
end

function modifier_holdout_soul_harvest:OnRefresh()
	local ability = self:GetAbility()
	self.moveSlow = ability ~= nil and ability:GetSpecialValueFor("move_slow_pct") or 0
end

function modifier_holdout_soul_harvest:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
		MODIFIER_EVENT_ON_DEATH,
	}
end

function modifier_holdout_soul_harvest:GetModifierMoveSpeedBonus_Percentage()
	return self.moveSlow or 0
end

function modifier_holdout_soul_harvest:OnDeath(keys)
	if not IsServer() or self.exploded == true or keys.unit ~= self:GetParent() then return end
	self.exploded = true

	local caster = self:GetCaster()
	local ability = self:GetAbility()
	local victim = self:GetParent()
	if caster == nil
		or ability == nil
		or not IsValidEntity(caster)
		or caster:IsNull()
		or not caster:IsAlive()
	then
		return
	end

	if not victim:IsIllusion() then
		AddHarvestedSoul(caster, ability)
	end

	local origin = victim:GetAbsOrigin()
	local bonusDamage = math.min(
		victim:GetMaxHealth() * ability:GetSpecialValueFor("max_health_damage_pct") * 0.01,
		ability:GetSpecialValueFor("max_bonus_damage")
	)
	local damage = ability:GetSpecialValueFor("base_damage") + bonusDamage
	local enemies = FindUnitsInRadius(
		caster:GetTeamNumber(),
		origin,
		nil,
		ability:GetSpecialValueFor("explosion_radius"),
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		DOTA_UNIT_TARGET_FLAG_NONE,
		FIND_ANY_ORDER,
		false
	)

	local particle = ParticleManager:CreateParticle(
		"particles/econ/items/abaddon/abaddon_alliance/abaddon_aphotic_shield_alliance_explosion.vpcf",
		PATTACH_WORLDORIGIN,
		nil
	)
	ParticleManager:SetParticleControl(particle, 0, origin)
	ParticleManager:ReleaseParticleIndex(particle)

	local now = GameRules:GetGameTime()
	if (caster.xhsSoulHarvestNextSound or 0) <= now then
		EmitSoundOnLocationWithCaster(origin, "Hero_Necrolyte.DeathPulse", caster)
		caster.xhsSoulHarvestNextSound = now + 0.15
	end

	for _, enemy in pairs(enemies) do
		if enemy ~= victim and enemy:IsAlive() then
			ApplyDamage({
				attacker = caster,
				victim = enemy,
				ability = ability,
				damage = damage,
				damage_type = DAMAGE_TYPE_MAGICAL,
			})
		end
	end
end

modifier_holdout_souls_harvested = modifier_holdout_souls_harvested or class({})
modifier_holdout_souls_harvested.XHS_LINK_CLIENT = true

function modifier_holdout_souls_harvested:IsHidden() return false end
function modifier_holdout_souls_harvested:IsDebuff() return false end
function modifier_holdout_souls_harvested:IsPurgable() return false end
function modifier_holdout_souls_harvested:RemoveOnDeath() return true end
function modifier_holdout_souls_harvested:GetTexture() return "custom/holdout_stitch" end

function modifier_holdout_souls_harvested:OnCreated()
	if not IsServer() then return end
	self.expirations = {}
	self:StartIntervalThink(0.1)
end

function modifier_holdout_souls_harvested:AddSoul()
	if not IsServer() then return end
	self.expirations = self.expirations or {}
	local caster = self:GetParent()
	local duration = GetSoulHarvestSpecial(caster, "soul_stack_duration", 20)
	local cap = math.max(1, math.floor(GetSoulHarvestSpecial(caster, "soul_stack_cap", 20)))
	local expiry = GameRules:GetGameTime() + duration

	if #self.expirations >= cap then
		table.remove(self.expirations, 1)
	end
	table.insert(self.expirations, expiry)
	table.sort(self.expirations)
	self:SetStackCount(#self.expirations)
	self:ForceRefresh()
end

function modifier_holdout_souls_harvested:OnIntervalThink()
	local now = GameRules:GetGameTime()
	self.expirations = self.expirations or {}
	while #self.expirations > 0 and self.expirations[1] <= now do
		table.remove(self.expirations, 1)
	end

	if #self.expirations <= 0 then
		self:Destroy()
		return
	end
	self:SetStackCount(#self.expirations)
end

function modifier_holdout_souls_harvested:IsAura()
	local parent = self:GetParent()
	local malefice = parent and parent:FindAbilityByName("holdout_malefice_aura")
	return self:GetStackCount() > 0 and malefice ~= nil and malefice:GetLevel() > 0
end
function modifier_holdout_souls_harvested:GetModifierAura() return "modifier_holdout_soul_malefice_amp" end
function modifier_holdout_souls_harvested:GetAuraSearchTeam() return DOTA_UNIT_TARGET_TEAM_ENEMY end
function modifier_holdout_souls_harvested:GetAuraSearchType()
	return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
end
function modifier_holdout_souls_harvested:GetAuraSearchFlags()
	return DOTA_UNIT_TARGET_FLAG_NOT_ANCIENTS
end
function modifier_holdout_souls_harvested:GetAuraRadius()
	local caster = self:GetParent()
	local aura = caster:FindAbilityByName("holdout_malefice_aura")
	return aura ~= nil and aura:GetSpecialValueFor("radius") or 900
end

modifier_holdout_soul_malefice_amp = modifier_holdout_soul_malefice_amp or class({})
modifier_holdout_soul_malefice_amp.XHS_LINK_CLIENT = true

function modifier_holdout_soul_malefice_amp:IsHidden() return false end
function modifier_holdout_soul_malefice_amp:IsDebuff() return true end
function modifier_holdout_soul_malefice_amp:IsPurgable() return false end
function modifier_holdout_soul_malefice_amp:GetTexture() return "custom/holdout_divine_aura" end

function modifier_holdout_soul_malefice_amp:DeclareFunctions()
	return { MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS }
end

function modifier_holdout_soul_malefice_amp:GetModifierMagicalResistanceBonus()
	local caster = self:GetCaster()
	local souls = GetSoulsHarvested(caster)
	local reductionPerSoul = GetSoulHarvestSpecial(caster, "malefice_reduction_per_soul", 0.5)
	return -souls * reductionPerSoul
end
