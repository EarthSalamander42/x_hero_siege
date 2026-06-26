LinkLuaModifier("modifier_orb_of_venom_xhs", "items/item_orb_of_venom_xhs.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_orb_of_venom_xhs_active", "items/item_orb_of_venom_xhs.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_orb_of_venom_poison", "items/item_orb_of_venom_xhs.lua", LUA_MODIFIER_MOTION_NONE)

item_xhs_orb_of_venom = item_xhs_orb_of_venom or class({})
item_viridian_gem = item_viridian_gem or class({})
item_plagueheart = item_plagueheart or class({})

local function ToggleVenomOrb(caster, ability)
	if caster:HasModifier("modifier_orb_of_venom_xhs_active") then
		caster:RemoveModifierByName("modifier_orb_of_venom_xhs_active")
	else
		caster:AddNewModifier(caster, ability, "modifier_orb_of_venom_xhs_active", {})
	end
end

local function GetVenomOrbTexture(caster, active_texture, inactive_texture)
	if caster and not caster:IsNull() and caster:HasModifier("modifier_orb_of_venom_xhs_active") then
		return active_texture
	end

	return inactive_texture
end

function item_xhs_orb_of_venom:GetIntrinsicModifierName() return "modifier_orb_of_venom_xhs" end
function item_viridian_gem:GetIntrinsicModifierName() return "modifier_orb_of_venom_xhs" end
function item_plagueheart:GetIntrinsicModifierName() return "modifier_orb_of_venom_xhs" end

function item_xhs_orb_of_venom:OnSpellStart() if IsServer() then ToggleVenomOrb(self:GetCaster(), self) end end
function item_viridian_gem:OnSpellStart() if IsServer() then ToggleVenomOrb(self:GetCaster(), self) end end
function item_plagueheart:OnSpellStart() if IsServer() then ToggleVenomOrb(self:GetCaster(), self) end end

function item_xhs_orb_of_venom:GetAbilityTextureName()
	return GetVenomOrbTexture(self:GetCaster(), "custom/orb_of_venom", "custom/orb_of_venom_off")
end

function item_viridian_gem:GetAbilityTextureName()
	return GetVenomOrbTexture(self:GetCaster(), "custom/viridian_gem", "custom/viridian_gem_off")
end

function item_plagueheart:GetAbilityTextureName()
	return GetVenomOrbTexture(self:GetCaster(), "custom/plagueheart", "custom/plagueheart_off")
end

modifier_orb_of_venom_xhs_active = modifier_orb_of_venom_xhs_active or class({})

function modifier_orb_of_venom_xhs_active:IsHidden() return false end
function modifier_orb_of_venom_xhs_active:IsPurgable() return false end
function modifier_orb_of_venom_xhs_active:RemoveOnDeath() return false end
function modifier_orb_of_venom_xhs_active:GetTexture() return "custom/orb_of_venom" end

modifier_orb_of_venom_xhs = modifier_orb_of_venom_xhs or class({})

function modifier_orb_of_venom_xhs:IsHidden() return true end
function modifier_orb_of_venom_xhs:IsPurgable() return false end
function modifier_orb_of_venom_xhs:RemoveOnDeath() return false end
function modifier_orb_of_venom_xhs:GetAttributes() return MODIFIER_ATTRIBUTE_MULTIPLE end

function modifier_orb_of_venom_xhs:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
		MODIFIER_EVENT_ON_ATTACK_LANDED,
	}
end

function modifier_orb_of_venom_xhs:GetModifierPreAttack_BonusDamage()
	return self:GetAbility():GetSpecialValueFor("bonus_damage")
end

function modifier_orb_of_venom_xhs:OnAttackLanded(params)
	if not IsServer() or params.attacker ~= self:GetParent() then
		return
	end

	if params.target:GetTeamNumber() == params.attacker:GetTeamNumber() or params.target:IsBuilding() then
		return
	end

	if not self:GetParent():HasModifier("modifier_orb_of_venom_xhs_active") then
		return
	end

	local ability = self:GetAbility()
	if not ability or ability:IsNull() then
		return
	end

	local toxic_damage = ability:GetSpecialValueFor("toxic_saturation_damage")
	if toxic_damage > 0 and params.target:HasModifier("modifier_orb_of_venom_poison") then
		ApplyDamage({
			victim = params.target,
			attacker = params.attacker,
			damage = toxic_damage,
			damage_type = DAMAGE_TYPE_MAGICAL,
			ability = ability,
		})
	end

	params.target:AddNewModifier(params.attacker, ability, "modifier_orb_of_venom_poison", {
		duration = ability:GetSpecialValueFor("poison_duration")
	})
end

modifier_orb_of_venom_poison = modifier_orb_of_venom_poison or class({})

function modifier_orb_of_venom_poison:IsHidden() return false end
function modifier_orb_of_venom_poison:IsDebuff() return true end
function modifier_orb_of_venom_poison:IsPurgable() return true end

function modifier_orb_of_venom_poison:OnCreated()
	self:RefreshSpecialValues()

	if IsServer() then
		self:StartIntervalThink(1.0)
	end
end

function modifier_orb_of_venom_poison:OnRefresh()
	self:RefreshSpecialValues()
end

function modifier_orb_of_venom_poison:RefreshSpecialValues()
	local ability = self:GetAbility()

	self.poison_damage_per_second = ability and ability:GetSpecialValueFor("poison_damage_per_second") or 0
	self.armor_reduction = ability and ability:GetSpecialValueFor("armor_reduction") or 0
end

function modifier_orb_of_venom_poison:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
	}
end

function modifier_orb_of_venom_poison:GetModifierPhysicalArmorBonus()
	return 0 - self.armor_reduction
end

function modifier_orb_of_venom_poison:OnIntervalThink()
	local caster = self:GetCaster()
	local parent = self:GetParent()
	local ability = self:GetAbility()

	if not caster or caster:IsNull() or not parent or parent:IsNull() or not ability or ability:IsNull() then
		return
	end

	ApplyDamage({
		victim = parent,
		attacker = caster,
		damage = self.poison_damage_per_second,
		damage_type = DAMAGE_TYPE_MAGICAL,
		ability = ability,
	})
end

function modifier_orb_of_venom_poison:GetEffectName()
	return "particles/units/heroes/hero_viper/viper_poison_debuff.vpcf"
end

function modifier_orb_of_venom_poison:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_orb_of_venom_poison:GetStatusEffectName()
	return "particles/status_fx/status_effect_poison_viper.vpcf"
end
