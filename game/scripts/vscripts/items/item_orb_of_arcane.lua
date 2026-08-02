LinkLuaModifier("modifier_orb_of_arcane", "items/item_orb_of_arcane.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_astral_core_ethereal", "items/item_orb_of_arcane.lua", LUA_MODIFIER_MOTION_NONE)

item_orb_of_arcane = item_orb_of_arcane or class({})
item_mystic_gem = item_mystic_gem or class({})
item_astral_core = item_astral_core or class({})

function item_orb_of_arcane:GetIntrinsicModifierName() return "modifier_orb_of_arcane" end
function item_mystic_gem:GetIntrinsicModifierName() return "modifier_orb_of_arcane" end
function item_astral_core:GetIntrinsicModifierName() return "modifier_orb_of_arcane" end

function item_astral_core:OnSpellStart()
	if not IsServer() then return end

	local target = self:GetCursorTarget()
	if target == nil or target:IsNull() then return end

	ProjectileManager:CreateTrackingProjectile({
		Target = target,
		Source = self:GetCaster(),
		Ability = self,
		EffectName = "particles/items_fx/ethereal_blade.vpcf",
		iMoveSpeed = self:GetSpecialValueFor("projectile_speed"),
		bDodgeable = true,
		bProvidesVision = false,
		iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_ATTACK_1,
	})

	self:GetCaster():EmitSound("Hero_Viper.viperStrike")
end

function item_astral_core:OnProjectileHit(target, _location)
	if not IsServer() or target == nil or target:IsNull() then return end
	if target:TriggerSpellAbsorb(self) then return end

	target:AddNewModifier(self:GetCaster(), self, "modifier_astral_core_ethereal", {
		duration = self:GetSpecialValueFor("ethereal_duration"),
	})
	target:EmitSound("DOTA_Item.GhostScepter.Activate")
	local particle = ParticleManager:CreateParticle(
		"particles/items_fx/ethereal_blade_explosion.vpcf",
		PATTACH_ABSORIGIN_FOLLOW,
		target
	)
	ParticleManager:ReleaseParticleIndex(particle)
end

modifier_orb_of_arcane = modifier_orb_of_arcane or class({})
modifier_orb_of_arcane.XHS_LINK_CLIENT = true

function modifier_orb_of_arcane:IsHidden() return true end
function modifier_orb_of_arcane:IsPurgable() return false end
function modifier_orb_of_arcane:RemoveOnDeath() return false end
function modifier_orb_of_arcane:GetAttributes() return MODIFIER_ATTRIBUTE_MULTIPLE end
function modifier_orb_of_arcane:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE,
		MODIFIER_EVENT_ON_TAKEDAMAGE,
	}
end

function modifier_orb_of_arcane:GetModifierSpellAmplify_Percentage()
	return self:GetAbility():GetSpecialValueFor("spell_amp")
end

function modifier_orb_of_arcane:OnTakeDamage(params)
	if not IsServer() or not params or params.attacker ~= self:GetParent() then
		return
	end

	if not IsValidEntity(params.attacker)
		or not IsValidEntity(params.unit)
		or not IsValidEntity(params.inflictor)
		or params.unit:GetTeamNumber() == params.attacker:GetTeamNumber()
	then
		return
	end

	if params.inflictor.IsItem and params.inflictor:IsItem() then
		return
	end

	local ability = self:GetAbility()
	if not ability or ability:IsNull() then
		return
	end

	if params.unit:IsBuilding() or params.unit:IsIllusion() or params.damage <= 0 then
		return
	end

	local health_before = self:GetParent():GetHealth()
	self:GetParent():Heal(params.damage * ability:GetSpecialValueFor("spell_lifesteal_pct") / 100, ability)
	local actual_heal = math.max(0, self:GetParent():GetHealth() - health_before)
	if actual_heal > 0 and XHSQueueSupporterSpellLifestealFX ~= nil then
		XHSQueueSupporterSpellLifestealFX(self:GetParent(), params.unit, actual_heal)
	end
end

modifier_astral_core_ethereal = modifier_astral_core_ethereal or class({})
modifier_astral_core_ethereal.XHS_LINK_CLIENT = true

function modifier_astral_core_ethereal:IsHidden() return false end
function modifier_astral_core_ethereal:IsDebuff() return true end
function modifier_astral_core_ethereal:IsPurgable() return true end
function modifier_astral_core_ethereal:GetStatusEffectName() return "particles/status_fx/status_effect_ghost.vpcf" end
function modifier_astral_core_ethereal:StatusEffectPriority() return 15 end
function modifier_astral_core_ethereal:GetEffectName() return "particles/items_fx/ghost.vpcf" end
function modifier_astral_core_ethereal:GetEffectAttachType() return PATTACH_ABSORIGIN_FOLLOW end

function modifier_astral_core_ethereal:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL,
		MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
	}
end

function modifier_astral_core_ethereal:GetAbsoluteNoDamagePhysical() return 1 end

function modifier_astral_core_ethereal:GetModifierMagicalResistanceBonus()
	local ability = self:GetAbility()
	return ability and not ability:IsNull() and ability:GetSpecialValueFor("extra_spell_damage_percent") or 0
end

function modifier_astral_core_ethereal:GetModifierMoveSpeedBonus_Percentage()
	local ability = self:GetAbility()
	return ability and not ability:IsNull() and ability:GetSpecialValueFor("ethereal_movement_slow_pct") or 0
end

function modifier_astral_core_ethereal:CheckState()
	return {
		[MODIFIER_STATE_ATTACK_IMMUNE] = true,
		[MODIFIER_STATE_DISARMED] = true,
	}
end
