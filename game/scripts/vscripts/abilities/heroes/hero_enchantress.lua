LinkLuaModifier("modifier_tyrande_multiple_arrows", "abilities/heroes/hero_enchantress", LUA_MODIFIER_MOTION_NONE)

local function ApplySplitShotPoison(caster, target)
	if not caster or caster:IsNull() or not target or target:IsNull() then return end
	if caster:PassivesDisabled() or target:IsMagicImmune() then return end

	local poison = caster:FindAbilityByName("holdout_poison_attack")
	if not poison or not poison:IsTrained() then return end

	poison:ApplyDataDrivenModifier(caster, target, "modifier_poison_attack_debuff", {})
end

tyrande_multiple_arrows = tyrande_multiple_arrows or class({})

function tyrande_multiple_arrows:GetIntrinsicModifierName()
	return "modifier_tyrande_multiple_arrows"
end

modifier_tyrande_multiple_arrows = modifier_tyrande_multiple_arrows or class({})
modifier_tyrande_multiple_arrows.XHS_LINK_CLIENT = true

function modifier_tyrande_multiple_arrows:IsHidden() return true end

function modifier_tyrande_multiple_arrows:DeclareFunctions()
    return {
		MODIFIER_EVENT_ON_ATTACK,
		MODIFIER_EVENT_ON_ATTACK_LANDED,
		MODIFIER_EVENT_ON_ATTACK_RECORD_DESTROY,
		MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE,
		MODIFIER_PROPERTY_TRANSLATE_ACTIVITY_MODIFIERS,
    }
end

function modifier_tyrande_multiple_arrows:OnAttack(keys)
	if not IsServer() then return end
	if keys.attacker ~= self:GetParent() then return end

	-- PerformAttack disables procs so secondary arrows cannot trigger Critical
	-- Arrows or unrelated attack modifiers. Keep their records so Poison Attack
	-- can be applied explicitly once the corresponding projectile lands.
	if self.creating_split_attack then
		if keys.record ~= nil then
			self.split_shot_records = self.split_shot_records or {}
			self.split_shot_records[keys.record] = true
		end
		return
	end

	-- "Secondary arrows are not released upon attacking allies."
	-- The "not keys.no_attack_cooldown" clause seems to make sure the function doesn't trigger on PerformAttacks with that false tag so this thing doesn't crash
	if keys.target and keys.target:GetTeamNumber() ~= self:GetParent():GetTeamNumber() and not keys.no_attack_cooldown and not self:GetParent():PassivesDisabled() and self:GetAbility():IsTrained() then
		local enemies = FindUnitsInRadius(self:GetParent():GetTeamNumber(), self:GetParent():GetAbsOrigin(), nil, self:GetParent():Script_GetAttackRange() + self:GetAbility():GetSpecialValueFor("split_shot_bonus_range"), DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE + DOTA_UNIT_TARGET_FLAG_NO_INVIS + DOTA_UNIT_TARGET_FLAG_NOT_ATTACK_IMMUNE, FIND_CLOSEST, false)
		local target_number = 0

		for _, enemy in pairs(enemies) do
			if enemy ~= keys.target then
				self.creating_split_attack = true
				self.split_shot_target = true

				self:GetParent():PerformAttack(enemy, false, false, true, true, true, false, false)

				self.split_shot_target = false
				self.creating_split_attack = false

				target_number = target_number + 1

				if target_number >= self:GetAbility():GetSpecialValueFor("arrow_count") then
					break
				end
			end
		end
	end
end

function modifier_tyrande_multiple_arrows:OnAttackLanded(keys)
	if not IsServer() or keys.attacker ~= self:GetParent() or not self.split_shot_records then return end
	if not self.split_shot_records[keys.record] then return end

	self.split_shot_records[keys.record] = nil
	ApplySplitShotPoison(self:GetParent(), keys.target)
end

function modifier_tyrande_multiple_arrows:OnAttackRecordDestroy(keys)
	if not IsServer() or keys.attacker ~= self:GetParent() or not self.split_shot_records then return end
	self.split_shot_records[keys.record] = nil
end

function modifier_tyrande_multiple_arrows:GetModifierDamageOutgoing_Percentage()
	if not IsServer() then return end

	if self.split_shot_target then
		return self:GetAbility():GetSpecialValueFor("damage_modifier_tooltip") - 100
	else
		return 0
	end
end

function modifier_tyrande_multiple_arrows:GetActivityTranslationModifiers()
	return "split_shot"
end

LinkLuaModifier("modifier_xhs_trueshot_aura", "abilities/heroes/hero_enchantress", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_xhs_trueshot", "abilities/heroes/hero_enchantress", LUA_MODIFIER_MOTION_NONE)

xhs_trueshot_aura = xhs_trueshot_aura or class({})

function xhs_trueshot_aura:GetIntrinsicModifierName()
	return "modifier_xhs_trueshot_aura"
end

modifier_xhs_trueshot_aura = modifier_xhs_trueshot_aura or class({})
modifier_xhs_trueshot_aura.XHS_LINK_CLIENT = true

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

function modifier_xhs_trueshot_aura:GetAuraEntityReject(target)
	return IsXHSRuneUnit and IsXHSRuneUnit(target)
end

modifier_xhs_trueshot = modifier_xhs_trueshot or class({})
modifier_xhs_trueshot.XHS_LINK_CLIENT = true

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
