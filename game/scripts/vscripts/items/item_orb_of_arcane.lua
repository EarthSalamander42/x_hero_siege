LinkLuaModifier("modifier_orb_of_arcane", "items/item_orb_of_arcane.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_orb_of_arcane_active", "items/item_orb_of_arcane.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_orb_of_arcane_exposure", "items/item_orb_of_arcane.lua", LUA_MODIFIER_MOTION_NONE)

item_orb_of_arcane = item_orb_of_arcane or class({})
item_mystic_gem = item_mystic_gem or class({})
item_astral_core = item_astral_core or class({})

local function ToggleArcaneOrb(caster, ability)
	if caster:HasModifier("modifier_orb_of_arcane_active") then
		caster:RemoveModifierByName("modifier_orb_of_arcane_active")
	else
		caster:AddNewModifier(caster, ability, "modifier_orb_of_arcane_active", {})
	end
end

local function GetArcaneOrbTexture(caster, active_texture, inactive_texture)
	if caster and not caster:IsNull() and caster:HasModifier("modifier_orb_of_arcane_active") then
		return active_texture
	end

	return inactive_texture
end

local ARCANE_ACTIVE_MODIFIER_TEXTURES = {
	item_astral_core = "custom/astral_core",
	item_mystic_gem = "custom/mystic_gem",
	item_orb_of_arcane = "custom/orb_of_arcane",
}

local function GetArcaneActiveModifierTexture(ability)
	if ability and not ability:IsNull() then
		return ARCANE_ACTIVE_MODIFIER_TEXTURES[ability:GetName()] or "custom/orb_of_arcane"
	end

	return "custom/orb_of_arcane"
end

function item_orb_of_arcane:GetIntrinsicModifierName() return "modifier_orb_of_arcane" end
function item_mystic_gem:GetIntrinsicModifierName() return "modifier_orb_of_arcane" end
function item_astral_core:GetIntrinsicModifierName() return "modifier_orb_of_arcane" end

function item_orb_of_arcane:OnSpellStart() if IsServer() then ToggleArcaneOrb(self:GetCaster(), self) end end
function item_mystic_gem:OnSpellStart() if IsServer() then ToggleArcaneOrb(self:GetCaster(), self) end end
function item_astral_core:OnSpellStart() if IsServer() then ToggleArcaneOrb(self:GetCaster(), self) end end

function item_orb_of_arcane:GetAbilityTextureName()
	return GetArcaneOrbTexture(self:GetCaster(), "custom/orb_of_arcane", "custom/orb_of_arcane_off")
end

function item_mystic_gem:GetAbilityTextureName()
	return GetArcaneOrbTexture(self:GetCaster(), "custom/mystic_gem", "custom/mystic_gem_off")
end

function item_astral_core:GetAbilityTextureName()
	return GetArcaneOrbTexture(self:GetCaster(), "custom/astral_core", "custom/astral_core_off")
end

modifier_orb_of_arcane_active = modifier_orb_of_arcane_active or class({})
modifier_orb_of_arcane_active.XHS_LINK_CLIENT = true

function modifier_orb_of_arcane_active:IsHidden() return false end
function modifier_orb_of_arcane_active:IsPurgable() return false end
function modifier_orb_of_arcane_active:RemoveOnDeath() return false end
function modifier_orb_of_arcane_active:GetTexture() return GetArcaneActiveModifierTexture(self:GetAbility()) end

modifier_orb_of_arcane = modifier_orb_of_arcane or class({})
modifier_orb_of_arcane.XHS_LINK_CLIENT = true

function modifier_orb_of_arcane:IsHidden() return true end
function modifier_orb_of_arcane:IsPurgable() return false end
function modifier_orb_of_arcane:RemoveOnDeath() return false end
function modifier_orb_of_arcane:GetAttributes() return MODIFIER_ATTRIBUTE_MULTIPLE end

function modifier_orb_of_arcane:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE,
		MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
		MODIFIER_PROPERTY_MANACOST_PERCENTAGE,
		MODIFIER_PROPERTY_COOLDOWN_PERCENTAGE,
		MODIFIER_EVENT_ON_TAKEDAMAGE,
	}
end

function modifier_orb_of_arcane:GetModifierSpellAmplify_Percentage()
	return self:GetAbility():GetSpecialValueFor("spell_amp")
end

function modifier_orb_of_arcane:GetModifierConstantManaRegen()
	return self:GetAbility():GetSpecialValueFor("mana_regen")
end

function modifier_orb_of_arcane:GetModifierPercentageManacost()
	return 0 - self:GetAbility():GetSpecialValueFor("mana_cost_reduction_pct")
end

function modifier_orb_of_arcane:GetModifierPercentageCooldown()
	return self:GetAbility():GetSpecialValueFor("cooldown_reduction_pct")
end

function modifier_orb_of_arcane:OnTakeDamage(params)
	if not IsServer() or params.attacker ~= self:GetParent() then
		return
	end

	if not params.unit or not params.inflictor or params.unit:GetTeamNumber() == params.attacker:GetTeamNumber() then
		return
	end

	if params.inflictor.IsItem and params.inflictor:IsItem() then
		return
	end

	if not self:GetParent():HasModifier("modifier_orb_of_arcane_active") then
		return
	end

	local ability = self:GetAbility()
	if not ability or ability:IsNull() then
		return
	end

	local magic_resist_reduction = ability:GetSpecialValueFor("exposure_magic_resist_reduction")
	if magic_resist_reduction <= 0 then
		return
	end

	params.unit:AddNewModifier(params.attacker, ability, "modifier_orb_of_arcane_exposure", {
		duration = ability:GetSpecialValueFor("exposure_duration")
	})
end

modifier_orb_of_arcane_exposure = modifier_orb_of_arcane_exposure or class({})
modifier_orb_of_arcane_exposure.XHS_LINK_CLIENT = true

function modifier_orb_of_arcane_exposure:IsHidden() return false end
function modifier_orb_of_arcane_exposure:IsDebuff() return true end
function modifier_orb_of_arcane_exposure:IsPurgable() return true end

function modifier_orb_of_arcane_exposure:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
	}
end

function modifier_orb_of_arcane_exposure:GetModifierMagicalResistanceBonus()
	return 0 - self:GetAbility():GetSpecialValueFor("exposure_magic_resist_reduction")
end

function modifier_orb_of_arcane_exposure:GetEffectName()
	return "particles/items_fx/ethereal_blade_explosion.vpcf"
end

function modifier_orb_of_arcane_exposure:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end
