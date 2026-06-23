LinkLuaModifier("modifier_holdout_frost_arrows", "abilities/heroes/hero_lich/frost_arrows.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_holdout_frost_arrows_slow", "abilities/heroes/hero_lich/frost_arrows.lua", LUA_MODIFIER_MOTION_NONE)

holdout_frost_arrows = holdout_frost_arrows or class({})

function holdout_frost_arrows:GetIntrinsicModifierName()
	return "modifier_holdout_frost_arrows"
end

function holdout_frost_arrows:OnSpellStart()
	if not IsServer() then return end

	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	if caster == nil or target == nil then return end

	self.manual_cast_target = target
	caster:MoveToTargetToAttack(target)
end

modifier_holdout_frost_arrows = modifier_holdout_frost_arrows or class({})

function modifier_holdout_frost_arrows:IsHidden() return true end
function modifier_holdout_frost_arrows:IsPurgable() return false end

function modifier_holdout_frost_arrows:OnCreated()
	if not IsServer() then return end

	self.attack_records = {}
end

function modifier_holdout_frost_arrows:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_ATTACK_RECORD,
		MODIFIER_EVENT_ON_ATTACK_LANDED,
		MODIFIER_EVENT_ON_ATTACK_RECORD_DESTROY,
		MODIFIER_PROPERTY_PROJECTILE_NAME,
	}
end

function modifier_holdout_frost_arrows:ShouldUseFrostArrow(target)
	local parent = self:GetParent()
	local ability = self:GetAbility()
	if parent == nil or ability == nil then return false end
	if target == nil or target:IsNull() then return false end
	if target:GetTeamNumber() == parent:GetTeamNumber() then return false end
	if target:IsBuilding() or target:IsOther() then return false end
	if target:IsMagicImmune() then return false end
	if ability:GetLevel() <= 0 then return false end
	local is_manual_cast = ability.manual_cast_target == target
	if not ability:GetAutoCastState() and not is_manual_cast then return false end
	if not is_manual_cast and parent:GetMana() < ability:GetManaCost(ability:GetLevel() - 1) then return false end

	return true
end

function modifier_holdout_frost_arrows:OnAttackRecord(keys)
	if not IsServer() then return end
	if keys.attacker ~= self:GetParent() then return end
	if not self:ShouldUseFrostArrow(keys.target) then return end

	self.attack_records[keys.record] = true
	local ability = self:GetAbility()
	local is_manual_cast = ability.manual_cast_target == keys.target
	if is_manual_cast then
		ability.manual_cast_target = nil
	else
		self:GetParent():SpendMana(ability:GetManaCost(ability:GetLevel() - 1), ability)
	end
	self:GetParent():EmitSound("Hero_DrowRanger.FrostArrows")
end

function modifier_holdout_frost_arrows:OnAttackLanded(keys)
	if not IsServer() then return end
	if keys.attacker ~= self:GetParent() then return end
	if self.attack_records[keys.record] ~= true then return end
	if keys.target == nil or keys.target:IsNull() then return end

	local ability = self:GetAbility()
	local damage = ability:GetSpecialValueFor("bonus_damage")
	local duration = ability:GetSpecialValueFor("frost_arrows_duration")

	ApplyDamage({
		victim = keys.target,
		attacker = keys.attacker,
		ability = ability,
		damage = damage,
		damage_type = DAMAGE_TYPE_PHYSICAL,
	})

	keys.target:AddNewModifier(keys.attacker, ability, "modifier_holdout_frost_arrows_slow", { duration = duration })
	SendOverheadEventMessage(nil, OVERHEAD_ALERT_BONUS_SPELL_DAMAGE, keys.target, damage, nil)
end

function modifier_holdout_frost_arrows:OnAttackRecordDestroy(keys)
	if not IsServer() then return end

	self.attack_records[keys.record] = nil
end

function modifier_holdout_frost_arrows:GetModifierProjectileName()
	if self:ShouldUseFrostArrow(self:GetParent():GetAttackTarget()) then
		return "particles/units/heroes/hero_drow/drow_frost_arrow.vpcf"
	end
end

modifier_holdout_frost_arrows_slow = modifier_holdout_frost_arrows_slow or class({})

function modifier_holdout_frost_arrows_slow:IsDebuff() return true end
function modifier_holdout_frost_arrows_slow:IsHidden() return false end
function modifier_holdout_frost_arrows_slow:IsPurgable() return true end
function modifier_holdout_frost_arrows_slow:GetEffectName() return "particles/generic_gameplay/generic_slowed_cold.vpcf" end
function modifier_holdout_frost_arrows_slow:GetEffectAttachType() return PATTACH_ABSORIGIN_FOLLOW end

function modifier_holdout_frost_arrows_slow:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
	}
end

function modifier_holdout_frost_arrows_slow:GetModifierMoveSpeedBonus_Percentage()
	return self:GetAbility():GetSpecialValueFor("frost_arrows_movement_speed")
end
