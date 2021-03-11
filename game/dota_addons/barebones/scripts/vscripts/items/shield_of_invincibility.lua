-- Author: Cookies
-- Date: 05.12.2019

LinkLuaModifier("modifier_ankh", "items/ankh_of_reincarnation.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_shield_of_invincibility", "items/shield_of_invincibility.lua", LUA_MODIFIER_MOTION_NONE)

item_shield_of_invincibility = item_shield_of_invincibility or class({})

function item_shield_of_invincibility:GetIntrinsicModifierName()
	return "modifier_shield_of_invincibility"
end

modifier_shield_of_invincibility = modifier_shield_of_invincibility or class({})

function modifier_shield_of_invincibility:RemoveOnDeath() return false end
function modifier_shield_of_invincibility:IsPurgable() return false end
function modifier_shield_of_invincibility:IsPurgeException() return false end
function modifier_shield_of_invincibility:GetEffectName() return "particles/items_fx/blademail.vpcf" end
function modifier_shield_of_invincibility:GetEffectAttachType() return PATTACH_ABSORIGIN_FOLLOW end
function modifier_shield_of_invincibility:GetTexture() return "modifiers/shield_of_invincibility" end

function modifier_shield_of_invincibility:DeclareFunctions() return {
	MODIFIER_EVENT_ON_ATTACKED,
	MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
	MODIFIER_PROPERTY_HEALTH_BONUS,
} end

function modifier_shield_of_invincibility:OnCreated()
	if not IsServer() then return end

	self:GetParent():AddNewModifier(self:GetParent(), self:GetAbility(), "modifier_ankh_passives", {})
end

function modifier_shield_of_invincibility:OnAttacked(params)
	if not IsServer() then return end

	if params.unit == self:GetParent() then
		-- only enemies, no buildings
		if params.attacker:GetTeamNumber() ~= self:GetParent():GetTeamNumber() and not params.attacker:IsBuilding() then
			local return_damage = ability:GetSpecialValueFor("damage_return_pct")
			local attacker_damage = params.original_damage
			local total_damage = attacker_damage / 100 * return_damage

			ApplyDamage({victim = params.attacker, attacker = self:GetParent(), damage = total_damage, damage_type = DAMAGE_TYPE_PHYSICAL})

			local particle_return_fx = ParticleManager:CreateParticle("particles/units/heroes/hero_centaur/centaur_return.vpcf", PATTACH_ABSORIGIN, self:GetParent())
			ParticleManager:SetParticleControlEnt(particle_return_fx, 0, self:GetParent(), PATTACH_POINT_FOLLOW, "attach_hitloc", self:GetParent():GetAbsOrigin(), true)
			ParticleManager:SetParticleControlEnt(particle_return_fx, 1, params.attacker, PATTACH_POINT_FOLLOW, "attach_hitloc", params.attacker:GetAbsOrigin(), true)
			ParticleManager:ReleaseParticleIndex(particle_return_fx)
		end
	end
end

function modifier_shield_of_invincibility:OnDestroy()
	if not IsServer() then return end

	for k, v in pairs(self:GetParent():FindAllModifiersByName("modifier_ankh")) do
		if v:GetAbility() == self:GetAbility() then
			v:Destroy()
			return
		end
	end
end


function modifier_shield_of_invincibility:GetModifierIncomingDamage_Percentage()
	return self:GetAbility():GetSpecialValueFor("damage_reduction") * (-1)
end

function modifier_shield_of_invincibility:GetModifierHealthBonus()
	return self:GetAbility():GetSpecialValueFor("bonus_hp")
end
