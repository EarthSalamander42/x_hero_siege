-- Credits: EarthSalamander #42
-- Date (DD/MM/YYYY): 24/03/2019

LinkLuaModifier("modifier_orb_of_earth", "items/item_orb_of_earth.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_orb_of_earth_bash", "items/item_orb_of_earth.lua", LUA_MODIFIER_MOTION_NONE)

item_orb_of_earth = class({})

function item_orb_of_earth:GetIntrinsicModifierName()
	return "modifier_orb_of_earth"
end

--------------------------------------------------------------

modifier_orb_of_earth = class({})

function modifier_orb_of_earth:IsHidden() return false end
function modifier_orb_of_earth:IsPurgable() return false end
function modifier_orb_of_earth:IsPurgeException() return false end
function modifier_orb_of_earth:IsDebuff() return false end
function modifier_orb_of_earth:RemoveOnDeath() return false end

function modifier_orb_of_earth:GetEffectAttachType()
	return "attach_attack1"
end

function modifier_orb_of_earth:GetEffectName()
	return "particles/units/heroes/hero_ancient_apparition/ancient_apparition_chilling_touch_buff_green.vpcf"
end

function modifier_orb_of_earth:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_ATTACK_LANDED,
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
	}
end

function modifier_orb_of_earth:GetModifierPreAttack_BonusDamage()
	return self:GetAbility():GetSpecialValueFor("bonus_damage")
end

function modifier_orb_of_earth:OnCreated()
	if self:GetParent():IsIllusion() then
		self:GetParent():RemoveModifierByName("modifier_orb_of_earth")

		return
	end
end

function modifier_orb_of_earth:OnAttackLanded(params)
	if IsServer() then
		if params.attacker == self:GetParent() and params.target:GetTeamNumber() ~= params.attacker:GetTeamNumber() then
			local ability = self:GetAbility()

			-- Not sure this fail-safe is required here
			if ability == nil then
				print("No item for this modifier, remove it!")
				self:GetParent():RemoveModifierByName("modifier_orb_of_earth")

				return
			end

			if RandomInt(1, 100) <= self:GetAbility():GetSpecialValueFor("bash_chance") then
				if ability:IsCooldownReady() then
					if not params.target:IsBuilding() then
						params.target:AddNewModifier(caster, ability, "modifier_orb_of_earth_bash", {duration = self:GetAbility():GetSpecialValueFor("bash_duration")})
						ability:StartCooldown(ability:GetCooldown(ability:GetLevel()))
					end
				end
			end
		end
	end
end

--------------------------------------------------------------

modifier_orb_of_earth_bash = class({})

function modifier_orb_of_earth_bash:IsHidden() return false end
function modifier_orb_of_earth_bash:IsPurgable() return false end
function modifier_orb_of_earth_bash:IsPurgeException() return false end
function modifier_orb_of_earth_bash:IsDebuff() return true end

function modifier_orb_of_earth_bash:CheckState()
	return {
		[MODIFIER_STATE_FROZEN] = true,
		[MODIFIER_STATE_STUNNED] = true,
	}
end

function modifier_orb_of_earth_bash:GetEffectName()
	return "particles/units/heroes/hero_medusa/medusa_stone_gaze_debuff_stoned.vpcf"
end

function modifier_orb_of_earth_bash:GetStatusEffectName()
	return "particles/units/heroes/hero_medusa/status_effect_medusa_stone_gaze_backup.vpcf"
end

function modifier_orb_of_earth_bash:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_orb_of_earth_bash:OnCreated()
	if IsServer() then
		self:GetParent():EmitSound("Hero_EarthSpirit.BoulderSmash.Target")
	end
end
