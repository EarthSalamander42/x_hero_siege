--------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------
-- Fountain's Relief Aura (increases tenacity and damage reduction)
--------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------

xhs_vampiric_aura = xhs_vampiric_aura or class({})
LinkLuaModifier("modifier_xhs_vampiric_aura", "modifiers/lifesteal.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_lifesteal_custom", "modifiers/lifesteal.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_lifesteal_custom_unique", "modifiers/lifesteal.lua", LUA_MODIFIER_MOTION_NONE)

function xhs_vampiric_aura:GetAbilityTextureName()
	return "custom/holdout_thirst_aura"
end

function xhs_vampiric_aura:GetIntrinsicModifierName()
	return "modifier_xhs_vampiric_aura"
end

-- Fountain aura 
modifier_xhs_vampiric_aura = modifier_xhs_vampiric_aura or class({})

function modifier_xhs_vampiric_aura:OnCreated()
	self.caster = self:GetCaster()
	self.ability = self:GetAbility()
	if not self.ability or not self.caster:IsRealHero() then
		self:Destroy()
		return nil
	end

	-- Ability specials
	self.aura_radius = self.ability:GetSpecialValueFor("aura_radius")
	self.aura_stickyness = self.ability:GetSpecialValueFor("aura_stickyness")
end

--ability properties
function modifier_xhs_vampiric_aura:OnRefresh()
	self:OnCreated()
end

function modifier_xhs_vampiric_aura:GetAuraDuration()
	return self.aura_stickyness
end

function modifier_xhs_vampiric_aura:GetAuraRadius()
	return self.aura_radius
end

function modifier_xhs_vampiric_aura:GetAuraSearchFlags()
	return DOTA_UNIT_TARGET_FLAG_PLAYER_CONTROLLED
end

function modifier_xhs_vampiric_aura:GetAuraSearchTeam()
	return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_xhs_vampiric_aura:GetAuraSearchType()
	return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
end

function modifier_xhs_vampiric_aura:GetModifierAura()
	return "modifier_lifesteal_custom"
end

function modifier_xhs_vampiric_aura:IsAura() return true end
function modifier_xhs_vampiric_aura:IsDebuff() return false end
function modifier_xhs_vampiric_aura:IsHidden() return true end


-- Author: Shush
-- Date: 12.03.2017
-----------------------
--    MORBID MASK    --
-----------------------
item_lifesteal_mask = class({})

function item_lifesteal_mask:GetIntrinsicModifierName()
	return "modifier_lifesteal_custom"
end

function item_lifesteal_mask:GetAbilityTextureName()
	return "custom/lifesteal_mask"
end

-- morbid mask modifier
modifier_lifesteal_custom = class({})
function modifier_lifesteal_custom:GetAbilityTextureName()
	return "custom/lifesteal_mask"
end

function modifier_lifesteal_custom:OnCreated()
	-- Ability properties
	self.caster = self:GetCaster()
	self.ability = self:GetAbility()
	self.particle_lifesteal = "particles/generic_gameplay/generic_lifesteal.vpcf"

	if IsServer() then
		-- Change to lifesteal projectile, if there's nothing "stronger"
		ChangeAttackProjectile(self.caster)
	end
end

function modifier_lifesteal_custom:DeclareFunctions()
	local decFunc = {
	MODIFIER_EVENT_ON_ATTACK_LANDED}

	return decFunc
end

function modifier_lifesteal_custom:OnAttackLanded(keys)
	if IsServer() then
		local parent = self:GetParent()
		local attacker = keys.attacker

		-- If this attack was not performed by the modifier's parent, do nothing
		if parent ~= attacker then
			return
		end

		-- Else, keep going
		local target = keys.target
		local lifesteal_amount = attacker:GetLifesteal()

		-- If there's no valid target, or lifesteal amount, do nothing
		if target:IsBuilding() or (target:GetTeam() == attacker:GetTeam()) or lifesteal_amount <= 0 then
			return
		end

		-- Calculate actual lifesteal amount
		local damage = keys.damage
		local target_armor = target:GetPhysicalArmorValue()
		local heal = damage * lifesteal_amount * 0.01 * GetReductionFromArmor(target_armor) * 0.01
		SendOverheadEventMessage(nil, OVERHEAD_ALERT_HEAL, parent, heal, nil)

		-- Choose the particle to draw
		local lifesteal_particle = "particles/generic_gameplay/generic_lifesteal.vpcf"

		-- Heal and fire the particle
		attacker:Heal(heal, attacker)
		local lifesteal_pfx = ParticleManager:CreateParticle(lifesteal_particle, PATTACH_ABSORIGIN_FOLLOW, attacker)
		ParticleManager:SetParticleControl(lifesteal_pfx, 0, attacker:GetAbsOrigin())
		ParticleManager:ReleaseParticleIndex(lifesteal_pfx)
	end
end

function modifier_lifesteal_custom:OnDestroy()
	if IsServer() then
		-- Remove lifesteal projectile
		ChangeAttackProjectile(self.caster) 
	end
end

function modifier_lifesteal_custom:IsHidden()
	return false
end

function modifier_lifesteal_custom:IsPurgable()
	return false
end

function modifier_lifesteal_custom:IsDebuff()
	return false
end

--	function modifier_lifesteal_custom:GetAttributes()
--		return MODIFIER_ATTRIBUTE_MULTIPLE
--	end

function modifier_lifesteal_custom:GetModifierLifesteal()
	return self:GetAbility():GetSpecialValueFor("lifesteal_pct")
end
