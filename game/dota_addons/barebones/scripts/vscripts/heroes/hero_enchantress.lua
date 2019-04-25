LinkLuaModifier("modifier_xhs_trueshot_aura", "heroes/hero_enchantress", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_xhs_trueshot", "heroes/hero_enchantress", LUA_MODIFIER_MOTION_NONE)

xhs_trueshot_aura = xhs_trueshot_aura or class({})

function xhs_trueshot_aura:GetIntrinsicModifierName()
	return "modifier_xhs_trueshot_aura"
end

modifier_xhs_trueshot_aura = modifier_xhs_trueshot_aura or class({})

-- Modifier properties
function modifier_xhs_trueshot_aura:IsAura() return true end
function modifier_xhs_trueshot_aura:IsAuraActiveOnDeath() return false end
function modifier_xhs_trueshot_aura:IsDebuff() return false end
function modifier_xhs_trueshot_aura:IsHidden() return true end
function modifier_xhs_trueshot_aura:IsPermanent() return true end
function modifier_xhs_trueshot_aura:IsPurgable() return false end

-- Aura properties
function modifier_xhs_trueshot_aura:GetAuraRadius()
	return 99999
end

function modifier_xhs_trueshot_aura:GetAuraSearchFlags()
	return self:GetAbility():GetAbilityTargetFlags()
end

function modifier_xhs_trueshot_aura:GetAuraSearchTeam()
	return self:GetAbility():GetAbilityTargetTeam()
end

function modifier_xhs_trueshot_aura:GetAuraSearchType()
	return self:GetAbility():GetAbilityTargetType()
end

function modifier_xhs_trueshot_aura:GetModifierAura()
	return "modifier_xhs_trueshot"
end

modifier_xhs_trueshot = modifier_xhs_trueshot or class({})

-- Modifier properties
function modifier_xhs_trueshot:IsDebuff() return false end
function modifier_xhs_trueshot:IsHidden() return false end
function modifier_xhs_trueshot:IsPurgable() return false end
function modifier_xhs_trueshot:IsPurgeException() return false end

function modifier_xhs_trueshot:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
	}
end

function modifier_xhs_trueshot:GetModifierPreAttack_BonusDamage()
	if self:GetCaster().GetAgility then
		self:SetStackCount(self:GetCaster():GetAgility() / 100 * self:GetAbility():GetSpecialValueFor("trueshot_ranged_damage"))
	end

	return self:GetStackCount()
end
