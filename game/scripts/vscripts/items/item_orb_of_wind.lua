LinkLuaModifier("modifier_orb_of_wind", "items/item_orb_of_wind.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_orb_of_wind_zephyr", "items/item_orb_of_wind.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_orb_of_wind_guard", "items/item_orb_of_wind.lua", LUA_MODIFIER_MOTION_NONE)

item_orb_of_wind = item_orb_of_wind or class({})
item_zephyr_gem = item_zephyr_gem or class({})
item_tempest_aegis = item_tempest_aegis or class({})

local function ToggleWindOrb(caster, ability)
	if caster:HasModifier("modifier_orb_of_wind_active") then
		caster:RemoveModifierByName("modifier_orb_of_wind_active")
	else
		caster:AddNewModifier(caster, ability, "modifier_orb_of_wind_active", {})
	end
end

local function GetWindOrbTexture(caster, active_texture, inactive_texture)
	if caster and not caster:IsNull() and caster:HasModifier("modifier_orb_of_wind_active") then
		return active_texture
	end

	return inactive_texture
end

LinkLuaModifier("modifier_orb_of_wind_active", "items/item_orb_of_wind.lua", LUA_MODIFIER_MOTION_NONE)

function item_orb_of_wind:GetIntrinsicModifierName() return "modifier_orb_of_wind" end
function item_zephyr_gem:GetIntrinsicModifierName() return "modifier_orb_of_wind" end
function item_tempest_aegis:GetIntrinsicModifierName() return "modifier_orb_of_wind" end

function item_orb_of_wind:OnSpellStart() if IsServer() then ToggleWindOrb(self:GetCaster(), self) end end
function item_zephyr_gem:OnSpellStart() if IsServer() then ToggleWindOrb(self:GetCaster(), self) end end
function item_tempest_aegis:OnSpellStart() if IsServer() then ToggleWindOrb(self:GetCaster(), self) end end

function item_orb_of_wind:GetAbilityTextureName()
	return GetWindOrbTexture(self:GetCaster(), "custom/talisman_of_evasion_datadriven", "custom/talisman_of_evasion_datadriven_off")
end

function item_zephyr_gem:GetAbilityTextureName()
	return GetWindOrbTexture(self:GetCaster(), "custom/zephyr_gem", "custom/zephyr_gem_off")
end

function item_tempest_aegis:GetAbilityTextureName()
	return GetWindOrbTexture(self:GetCaster(), "custom/tempest_aegis", "custom/tempest_aegis_off")
end

modifier_orb_of_wind_active = modifier_orb_of_wind_active or class({})

function modifier_orb_of_wind_active:IsHidden() return false end
function modifier_orb_of_wind_active:IsPurgable() return false end
function modifier_orb_of_wind_active:RemoveOnDeath() return false end
function modifier_orb_of_wind_active:GetTexture() return "custom/talisman_of_evasion_datadriven" end

modifier_orb_of_wind = modifier_orb_of_wind or class({})

function modifier_orb_of_wind:IsHidden() return true end
function modifier_orb_of_wind:IsPurgable() return false end
function modifier_orb_of_wind:RemoveOnDeath() return false end
function modifier_orb_of_wind:GetAttributes() return MODIFIER_ATTRIBUTE_MULTIPLE end

function modifier_orb_of_wind:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_EVASION_CONSTANT,
		MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT,
		MODIFIER_EVENT_ON_ATTACK_FAIL,
	}
end

function modifier_orb_of_wind:GetModifierEvasion_Constant()
	return self:GetAbility():GetSpecialValueFor("bonus_evasion")
end

function modifier_orb_of_wind:GetModifierMoveSpeedBonus_Constant()
	return self:GetAbility():GetSpecialValueFor("bonus_movement_speed")
end

function modifier_orb_of_wind:OnCreated()
	self.next_proc_time = 0
end

function modifier_orb_of_wind:OnAttackFail(params)
	if not IsServer() or params.target ~= self:GetParent() then
		return
	end

	local ability = self:GetAbility()
	if not ability or ability:IsNull() then
		return
	end

	if not self:GetParent():HasModifier("modifier_orb_of_wind_active") then
		return
	end

	local cooldown = ability:GetSpecialValueFor("evasion_proc_cooldown")
	if cooldown <= 0 or GameRules:GetGameTime() < self.next_proc_time then
		return
	end

	local move_speed_pct = ability:GetSpecialValueFor("evasion_proc_movespeed_pct")
	local damage_reduction_pct = ability:GetSpecialValueFor("evasion_proc_damage_reduction_pct")
	local duration = ability:GetSpecialValueFor("evasion_proc_duration")

	if move_speed_pct > 0 then
		self:GetParent():AddNewModifier(self:GetParent(), ability, "modifier_orb_of_wind_zephyr", { duration = duration })
	end

	if damage_reduction_pct > 0 then
		self:GetParent():AddNewModifier(self:GetParent(), ability, "modifier_orb_of_wind_guard", { duration = duration })
	end

	if move_speed_pct > 0 or damage_reduction_pct > 0 then
		self.next_proc_time = GameRules:GetGameTime() + cooldown
	end
end

modifier_orb_of_wind_zephyr = modifier_orb_of_wind_zephyr or class({})

function modifier_orb_of_wind_zephyr:IsHidden() return false end
function modifier_orb_of_wind_zephyr:IsPurgable() return true end

function modifier_orb_of_wind_zephyr:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
	}
end

function modifier_orb_of_wind_zephyr:GetModifierMoveSpeedBonus_Percentage()
	return self:GetAbility():GetSpecialValueFor("evasion_proc_movespeed_pct")
end

function modifier_orb_of_wind_zephyr:GetEffectName()
	return "particles/units/heroes/hero_windrunner/windrunner_windrun.vpcf"
end

function modifier_orb_of_wind_zephyr:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

modifier_orb_of_wind_guard = modifier_orb_of_wind_guard or class({})

function modifier_orb_of_wind_guard:IsHidden() return false end
function modifier_orb_of_wind_guard:IsPurgable() return true end

function modifier_orb_of_wind_guard:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
	}
end

function modifier_orb_of_wind_guard:GetModifierIncomingDamage_Percentage()
	return 0 - self:GetAbility():GetSpecialValueFor("evasion_proc_damage_reduction_pct")
end

function modifier_orb_of_wind_guard:GetEffectName()
	return "particles/items2_fx/pipe_of_insight.vpcf"
end

function modifier_orb_of_wind_guard:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end
