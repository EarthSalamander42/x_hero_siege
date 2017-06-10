modifier_souls = class({})

--------------------------------------------------------------------------------

function modifier_souls:IsHidden()
	return false
end

function modifier_souls:IsDebuff()
	return false
end

function modifier_souls:IsPurgable()
	return false
end

function modifier_souls:RemoveOnDeath()
	return false
end

function modifier_souls:AllowIllusionDuplicate()
	return true
end

function modifier_souls:GetTexture()
	return "nevermore_necromastery"
end

function modifier_souls:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
		MODIFIER_PROPERTY_TOOLTIP,
	}

	return funcs
end

function modifier_souls:GetModifierPreAttack_BonusDamage(event)
	return self:GetParent():GetAverageTrueAttackDamage() * 100 / self:GetStackCount()
end

function modifier_souls:OnTooltip(event)
	if self:GetParent():IsHero() then
		return 50
	end
	
	return 100
end
