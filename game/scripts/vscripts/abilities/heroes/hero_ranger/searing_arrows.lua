LinkLuaModifier(
	"modifier_holdout_searing_arrows",
	"abilities/heroes/hero_ranger/searing_arrows.lua",
	LUA_MODIFIER_MOTION_NONE
)

holdout_searing_arrows = holdout_searing_arrows or class({})

function holdout_searing_arrows:GetIntrinsicModifierName()
	return "modifier_holdout_searing_arrows"
end

function holdout_searing_arrows:OnSpellStart()
	if not IsServer() then return end

	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	if caster == nil or target == nil then return end

	-- Manual orb casts spend their mana through the normal ability cast. The
	-- modifier remembers the target so the next matching attack is empowered.
	self.manual_cast_target = target
	caster:MoveToTargetToAttack(target)
end

modifier_holdout_searing_arrows = modifier_holdout_searing_arrows or class({})
modifier_holdout_searing_arrows.XHS_LINK_CLIENT = true

function modifier_holdout_searing_arrows:IsHidden() return true end
function modifier_holdout_searing_arrows:IsPurgable() return false end

function modifier_holdout_searing_arrows:OnCreated()
	if not IsServer() then return end
	self.attack_records = {}
end

function modifier_holdout_searing_arrows:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_ATTACK_RECORD,
		MODIFIER_EVENT_ON_ATTACK,
		MODIFIER_EVENT_ON_ATTACK_LANDED,
		MODIFIER_EVENT_ON_ATTACK_RECORD_DESTROY,
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
		MODIFIER_PROPERTY_PROJECTILE_NAME,
	}
end

function modifier_holdout_searing_arrows:CanUseSearingArrow(target)
	local parent = self:GetParent()
	local ability = self:GetAbility()
	if parent == nil or ability == nil or ability:IsNull() then return false end
	if target == nil or target:IsNull() then return false end
	if target.GetTeamNumber == nil or target.IsBuilding == nil or target.IsOther == nil then return false end
	if target:GetTeamNumber() == parent:GetTeamNumber() then return false end
	if target:IsBuilding() or target:IsOther() then return false end
	if ability:GetLevel() <= 0 then return false end

	local is_manual_cast = ability.manual_cast_target == target
	if not is_manual_cast and not ability:GetAutoCastState() then return false end
	if not is_manual_cast and parent:GetMana() < ability:GetManaCost(ability:GetLevel() - 1) then
		return false
	end

	return true
end

function modifier_holdout_searing_arrows:OnAttackRecord(keys)
	if not IsServer() then return end
	if keys.attacker ~= self:GetParent() then return end
	if not self:CanUseSearingArrow(keys.target) then return end

	self.attack_records = self.attack_records or {}
	self.attack_records[keys.record] = true

	local ability = self:GetAbility()
	local is_manual_cast = ability.manual_cast_target == keys.target
	if is_manual_cast then
		ability.manual_cast_target = nil
	else
		self:GetParent():SpendMana(ability:GetManaCost(ability:GetLevel() - 1), ability)
	end
end

function modifier_holdout_searing_arrows:GetModifierPreAttack_BonusDamage(keys)
	if not IsServer() then return 0 end
	if keys == nil or self.attack_records == nil or self.attack_records[keys.record] ~= true then
		return 0
	end

	local ability = self:GetAbility()
	return ability ~= nil and not ability:IsNull()
		and ability:GetSpecialValueFor("damage_bonus")
		or 0
end

function modifier_holdout_searing_arrows:OnAttack(keys)
	if not IsServer() then return end
	if keys.attacker ~= self:GetParent() then return end
	if self.attack_records == nil or self.attack_records[keys.record] ~= true then return end

	self:GetParent():EmitSound("Hero_Clinkz.SearingArrows")
end

function modifier_holdout_searing_arrows:OnAttackLanded(keys)
	if not IsServer() then return end
	if keys.attacker ~= self:GetParent() then return end
	if self.attack_records == nil or self.attack_records[keys.record] ~= true then return end
	if keys.target == nil or keys.target:IsNull() then return end

	keys.target:EmitSound("Hero_Clinkz.SearingArrows.Impact")
end

function modifier_holdout_searing_arrows:OnAttackRecordDestroy(keys)
	if not IsServer() or self.attack_records == nil then return end
	self.attack_records[keys.record] = nil
end

function modifier_holdout_searing_arrows:GetModifierProjectileName()
	local parent = self:GetParent()
	if parent ~= nil and not parent:IsNull() and self:CanUseSearingArrow(parent:GetAttackTarget()) then
		return "particles/units/heroes/hero_clinkz/clinkz_searing_arrow.vpcf"
	end
end
