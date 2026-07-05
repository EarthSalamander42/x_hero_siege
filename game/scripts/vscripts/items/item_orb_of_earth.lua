-- Credits: EarthSalamander #42
-- Date (DD/MM/YYYY): 24/03/2019

LinkLuaModifier("modifier_orb_of_earth", "items/item_orb_of_earth.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_orb_of_earth_active", "items/item_orb_of_earth.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_orb_of_earth_bash", "items/item_orb_of_earth.lua", LUA_MODIFIER_MOTION_NONE)

item_orb_of_earth = item_orb_of_earth or class({})
item_orb_of_earth2 = item_orb_of_earth2 or class({})
item_orb_of_earth3 = item_orb_of_earth3 or class({})

local function ToggleEarthOrb(caster, ability)
	if caster:HasModifier("modifier_orb_of_earth_active") then
		caster:RemoveModifierByName("modifier_orb_of_earth_active")
	else
		caster:AddNewModifier(caster, ability, "modifier_orb_of_earth_active", {})
	end
end

local function GetEarthOrbTexture(caster, active_texture, inactive_texture)
	if caster and not caster:IsNull() and caster:HasModifier("modifier_orb_of_earth_active") then
		return active_texture
	end

	return inactive_texture
end

function item_orb_of_earth:GetIntrinsicModifierName() return "modifier_orb_of_earth" end
function item_orb_of_earth2:GetIntrinsicModifierName() return "modifier_orb_of_earth" end
function item_orb_of_earth3:GetIntrinsicModifierName() return "modifier_orb_of_earth" end

function item_orb_of_earth:OnSpellStart() if IsServer() then ToggleEarthOrb(self:GetCaster(), self) end end
function item_orb_of_earth2:OnSpellStart() if IsServer() then ToggleEarthOrb(self:GetCaster(), self) end end
function item_orb_of_earth3:OnSpellStart() if IsServer() then ToggleEarthOrb(self:GetCaster(), self) end end

function item_orb_of_earth:GetAbilityTextureName()
	return GetEarthOrbTexture(self:GetCaster(), "custom/orb_of_earth", "custom/orb_of_earth_off")
end

function item_orb_of_earth2:GetAbilityTextureName()
	return GetEarthOrbTexture(self:GetCaster(), "custom/orb_of_earth3", "custom/orb_of_earth3_off")
end

function item_orb_of_earth3:GetAbilityTextureName()
	return GetEarthOrbTexture(self:GetCaster(), "custom/orb_of_earth2", "custom/orb_of_earth2_off")
end

--------------------------------------------------------------

modifier_orb_of_earth = class({})
modifier_orb_of_earth.XHS_LINK_CLIENT = true

function modifier_orb_of_earth:IsHidden() return true end
function modifier_orb_of_earth:IsPurgable() return false end
function modifier_orb_of_earth:IsPurgeException() return false end
function modifier_orb_of_earth:IsDebuff() return false end
function modifier_orb_of_earth:RemoveOnDeath() return false end
function modifier_orb_of_earth:GetAttributes() return MODIFIER_ATTRIBUTE_MULTIPLE end

function modifier_orb_of_earth:DeclareFunctions()
	return {
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

modifier_orb_of_earth_active = modifier_orb_of_earth_active or class({})
modifier_orb_of_earth_active.XHS_LINK_CLIENT = true

function modifier_orb_of_earth_active:IsHidden() return false end
function modifier_orb_of_earth_active:IsPurgable() return false end
function modifier_orb_of_earth_active:IsPurgeException() return false end
function modifier_orb_of_earth_active:IsDebuff() return false end
function modifier_orb_of_earth_active:RemoveOnDeath() return false end
function modifier_orb_of_earth_active:GetTexture() return "modifiers/orb_of_earth" end

function modifier_orb_of_earth_active:GetEffectAttachType()
	return "attach_attack1"
end

function modifier_orb_of_earth_active:GetEffectName()
	return "particles/units/heroes/hero_ancient_apparition/ancient_apparition_chilling_touch_buff_green.vpcf"
end

function modifier_orb_of_earth_active:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_ATTACK_LANDED,
	}
end

function modifier_orb_of_earth_active:OnCreated()
	if self:GetParent():IsIllusion() then
		self:GetParent():RemoveModifierByName("modifier_orb_of_earth_active")
	end
end

function modifier_orb_of_earth_active:OnAttackLanded(params)
	if IsServer() then
		if params.attacker == self:GetParent() and params.target:GetTeamNumber() ~= params.attacker:GetTeamNumber() then
			local ability = self:GetAbility()

			if ability == nil then
				print("No item for this modifier, remove it!")
				self:GetParent():RemoveModifierByName("modifier_orb_of_earth_active")

				return
			end

			if RandomInt(1, 100) <= ability:GetSpecialValueFor("bash_chance") then
				if ability:IsCooldownReady() then
					if not params.target:IsBuilding() then
						params.target:AddNewModifier(params.attacker, ability, "modifier_orb_of_earth_bash", {duration = ability:GetSpecialValueFor("bash_duration")})
						ability:StartCooldown(ability:GetCooldown(ability:GetLevel()))
					end
				end
			end
		end
	end
end

--------------------------------------------------------------

modifier_orb_of_earth_bash = class({})
modifier_orb_of_earth_bash.XHS_LINK_CLIENT = true

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
