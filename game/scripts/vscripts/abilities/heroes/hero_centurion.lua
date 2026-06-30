function Purge(keys)
local caster = keys.caster
local index = ParticleManager:CreateParticle("particles/units/heroes/hero_slark/slark_dark_pact_start.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)

	ParticleManager:SetParticleControlEnt(index, 1, caster, PATTACH_ABSORIGIN_FOLLOW, nil, caster:GetAbsOrigin(), true)
	ParticleManager:ReleaseParticleIndex(index)

	Timers:CreateTimer(1.5, function()
	local index = ParticleManager:CreateParticle("particles/units/heroes/hero_slark/slark_dark_pact_pulses.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
		ParticleManager:SetParticleControlEnt(index, 1, caster, PATTACH_ABSORIGIN_FOLLOW, nil, caster:GetAbsOrigin(), true)
		ParticleManager:SetParticleControl(index, 2, Vector(300, 0, 0))
		caster:Purge( true, true, false, true, false)
	end)
end

function Transform( keys )
	local caster = keys.caster
	local ability = keys.ability
	local level = ability:GetLevel()
	local modifier_one = keys.modifier_one
	local modifier_two = keys.modifier_two
	local modifier_three = keys.modifier_three

	local modifier
	if level == 1 then
		modifier = modifier_one
	elseif level == 2 then
		modifier = modifier_two
	else
		modifier = modifier_three
	end

	ability:ApplyDataDrivenModifier(caster, caster, modifier, {})
end

function ModelSwapStart( keys )
	local caster = keys.caster
	local model = keys.model
	local projectile_model = keys.projectile_model
	local ability = keys.ability
	local vision_fow = ability:GetLevelSpecialValueFor("vision_fow", (ability:GetLevel() - 1))
	local vision_fow_duration = ability:GetLevelSpecialValueFor("duration", (ability:GetLevel() - 1))
	local caster_location = caster:GetAbsOrigin()

	if caster.caster_model == nil then
		caster.caster_model = caster:GetModelName()
	end
	caster.caster_attack = caster:GetAttackCapability()

	caster:SetOriginalModel(model)
	caster:SetRangedProjectileName(projectile_model)

	caster:SetAttackCapability(DOTA_UNIT_CAP_RANGED_ATTACK)
end

function ModelSwapEnd( keys )
local caster = keys.caster

	caster:SetModel(caster.caster_model)
	caster:SetOriginalModel(caster.caster_model)
	caster:SetAttackCapability(caster.caster_attack)
end

function DarkDimension(keys)
local caster = keys.caster
local ability = keys.ability
local radius = ability:GetLevelSpecialValueFor("radius", (ability:GetLevel() - 1))
local damage_pct = ability:GetLevelSpecialValueFor("self_damage_percent", (ability:GetLevel() - 1))
local damage = caster:GetMaxHealth() / 4

	ApplyDamage({victim = caster, attacker = caster, damage = damage, damage_type = DAMAGE_TYPE_MAGICAL, ability = ability})

	local eclipse = ParticleManager:CreateParticle("particles/units/heroes/hero_obsidian_destroyer/obsidian_destroyer_sanity_eclipse_area.vpcf", PATTACH_ABSORIGIN, caster)
	ParticleManager:SetParticleControl(eclipse, 0, caster:GetAbsOrigin())
	ParticleManager:SetParticleControl(eclipse, 1, Vector(radius, 0, 0))
	ParticleManager:SetParticleControl(eclipse, 2, Vector(radius, 0, 0))
	ParticleManager:SetParticleControl(eclipse, 3, Vector(radius, 0, 0))
	ParticleManager:ReleaseParticleIndex(eclipse)
end

LinkLuaModifier("modifier_xhs_centurion_necromastery", "abilities/heroes/hero_centurion.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_xhs_centurion_atrophy_aura", "abilities/heroes/hero_centurion.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_xhs_centurion_atrophy_debuff", "abilities/heroes/hero_centurion.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_xhs_centurion_atrophy_bonus", "abilities/heroes/hero_centurion.lua", LUA_MODIFIER_MOTION_NONE)

xhs_centurion_necromastery = xhs_centurion_necromastery or class({})

function xhs_centurion_necromastery:GetIntrinsicModifierName()
	return "modifier_xhs_centurion_necromastery"
end

modifier_xhs_centurion_necromastery = modifier_xhs_centurion_necromastery or class({})

function modifier_xhs_centurion_necromastery:IsHidden() return false end
function modifier_xhs_centurion_necromastery:IsPurgable() return false end
function modifier_xhs_centurion_necromastery:RemoveOnDeath() return false end

function modifier_xhs_centurion_necromastery:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_DEATH,
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
	}
end

function modifier_xhs_centurion_necromastery:OnDeath(keys)
	if not IsServer() then return end

	local parent = self:GetParent()
	local ability = self:GetAbility()
	if not ability then return end

	if keys.unit == parent then
		local release = ability:GetSpecialValueFor("necromastery_soul_release")
		self:SetStackCount(math.max(0, math.floor(self:GetStackCount() * (1 - release))))
		return
	end

	if keys.attacker ~= parent then return end
	if not keys.unit or keys.unit:IsBuilding() then return end
	if keys.unit:GetTeamNumber() == parent:GetTeamNumber() then return end
	if parent:PassivesDisabled() then return end

	local max_souls = ability:GetSpecialValueFor("necromastery_max_souls")
	local hero_bonus = 0
	if keys.unit:IsRealHero() then
		hero_bonus = ability:GetSpecialValueFor("necromastery_souls_hero_bonus")
	end

	self:SetStackCount(math.min(max_souls, self:GetStackCount() + 1 + hero_bonus))
end

function modifier_xhs_centurion_necromastery:GetModifierPreAttack_BonusDamage()
	local ability = self:GetAbility()
	if not ability or self:GetParent():PassivesDisabled() then return 0 end

	return self:GetStackCount() * ability:GetSpecialValueFor("necromastery_damage_per_soul")
end

xhs_centurion_atrophy_aura = xhs_centurion_atrophy_aura or class({})

function xhs_centurion_atrophy_aura:GetIntrinsicModifierName()
	return "modifier_xhs_centurion_atrophy_aura"
end

modifier_xhs_centurion_atrophy_aura = modifier_xhs_centurion_atrophy_aura or class({})

function modifier_xhs_centurion_atrophy_aura:IsHidden() return true end
function modifier_xhs_centurion_atrophy_aura:IsPurgable() return false end
function modifier_xhs_centurion_atrophy_aura:IsAura() return not self:GetParent():PassivesDisabled() end
function modifier_xhs_centurion_atrophy_aura:GetModifierAura() return "modifier_xhs_centurion_atrophy_debuff" end
function modifier_xhs_centurion_atrophy_aura:GetAuraRadius() return self:GetAbility():GetSpecialValueFor("radius") end
function modifier_xhs_centurion_atrophy_aura:GetAuraSearchTeam() return DOTA_UNIT_TARGET_TEAM_ENEMY end
function modifier_xhs_centurion_atrophy_aura:GetAuraSearchType() return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC end
function modifier_xhs_centurion_atrophy_aura:GetAuraSearchFlags() return DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES end

function modifier_xhs_centurion_atrophy_aura:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_DEATH,
	}
end

function modifier_xhs_centurion_atrophy_aura:OnDeath(keys)
	if not IsServer() then return end

	local parent = self:GetParent()
	local ability = self:GetAbility()
	if not ability or parent:PassivesDisabled() then return end
	if not keys.unit or keys.unit == parent or keys.unit:IsBuilding() then return end
	if keys.unit:GetTeamNumber() == parent:GetTeamNumber() then return end
	if (keys.unit:GetAbsOrigin() - parent:GetAbsOrigin()):Length2D() > ability:GetSpecialValueFor("radius") then return end

	local bonus_damage = ability:GetSpecialValueFor("bonus_damage_from_creep")
	if keys.unit:IsRealHero() then
		bonus_damage = ability:GetSpecialValueFor("bonus_damage_from_hero")
	end

	local bonus = parent:AddNewModifier(parent, ability, "modifier_xhs_centurion_atrophy_bonus", {
		duration = ability:GetSpecialValueFor("bonus_damage_duration")
	})

	if bonus then
		bonus:SetStackCount(bonus:GetStackCount() + bonus_damage)
	end
end

modifier_xhs_centurion_atrophy_debuff = modifier_xhs_centurion_atrophy_debuff or class({})

function modifier_xhs_centurion_atrophy_debuff:IsDebuff() return true end
function modifier_xhs_centurion_atrophy_debuff:IsPurgable() return false end

function modifier_xhs_centurion_atrophy_debuff:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_BASEDAMAGEOUTGOING_PERCENTAGE,
	}
end

function modifier_xhs_centurion_atrophy_debuff:GetModifierBaseDamageOutgoing_Percentage()
	local ability = self:GetAbility()
	if not ability then return 0 end

	return -ability:GetSpecialValueFor("damage_reduction_pct")
end

modifier_xhs_centurion_atrophy_bonus = modifier_xhs_centurion_atrophy_bonus or class({})

function modifier_xhs_centurion_atrophy_bonus:IsHidden() return false end
function modifier_xhs_centurion_atrophy_bonus:IsPurgable() return false end

function modifier_xhs_centurion_atrophy_bonus:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
	}
end

function modifier_xhs_centurion_atrophy_bonus:GetModifierPreAttack_BonusDamage()
	return self:GetStackCount()
end
