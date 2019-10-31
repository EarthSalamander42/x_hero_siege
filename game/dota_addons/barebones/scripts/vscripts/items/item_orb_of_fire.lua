-- Credits: EarthSalamander #42
-- Date (DD/MM/YYYY): 22/10/2019

LinkLuaModifier("modifier_orb_of_fire_active", "items/item_orb_of_fire.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_orb_of_fire_passive", "items/item_orb_of_fire.lua", LUA_MODIFIER_MOTION_NONE)

local function StartSpell(caster, ability)
	if caster:HasModifier("modifier_orb_of_fire_active") then
		caster:RemoveModifierByName("modifier_orb_of_fire_active")
	else
		caster:AddNewModifier(caster, ability, "modifier_orb_of_fire_active", {})
	end
end

item_orb_of_fire = class({})

function item_orb_of_fire:GetIntrinsicModifierName()
	return "modifier_orb_of_fire_passive"
end

function item_orb_of_fire:OnSpellStart()
	if IsServer() then
		StartSpell(self:GetCaster(), self)
	end
end

function item_orb_of_fire:GetAbilityTextureName()
	if self:GetCaster():HasModifier("modifier_orb_of_fire_active") then
		return "custom/orb_of_fire"
	end

	return "custom/orb_of_fire_off"
end

--------------------------------------------------------------

item_orb_of_fire2 = class({})

function item_orb_of_fire2:GetIntrinsicModifierName()
	return "modifier_orb_of_fire_passive"
end

function item_orb_of_fire2:OnSpellStart()
	if IsServer() then
		StartSpell(self:GetCaster(), self)
	end
end

function item_orb_of_fire2:GetAbilityTextureName()
	if self:GetCaster():HasModifier("modifier_orb_of_fire_active") then
		return "custom/orb_of_fire2"
	end

	return "custom/orb_of_fire2_off"
end

--------------------------------------------------------------

item_searing_blade = class({})

function item_searing_blade:GetIntrinsicModifierName()
	return "modifier_orb_of_fire_passive"
end

function item_searing_blade:OnSpellStart()
	if IsServer() then
		StartSpell(self:GetCaster(), self)
	end
end

function item_searing_blade:GetAbilityTextureName()
	if self:GetCaster():HasModifier("modifier_orb_of_fire_active") then
		return "custom/searing_blade"
	end

	return "custom/searing_blade_off"
end

--------------------------------------------------------------

modifier_orb_of_fire_active = class({})

function modifier_orb_of_fire_active:IsHidden() return false end
function modifier_orb_of_fire_active:IsPurgable() return false end
function modifier_orb_of_fire_active:IsPurgeException() return false end
function modifier_orb_of_fire_active:IsDebuff() return false end
function modifier_orb_of_fire_active:RemoveOnDeath() return false end

function modifier_orb_of_fire_active:GetEffectAttachType()
	return "attach_attack1"
end

function modifier_orb_of_fire_active:GetEffectName()
	return "particles/custom/items/orb/orb_of_fire/orb.vpcf"
end

function modifier_orb_of_fire_active:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_ATTACK_LANDED,
	}
end

function modifier_orb_of_fire_active:OnAttackLanded(params)
	if IsServer() then
		if params.attacker == self:GetParent() and params.target:GetTeamNumber() ~= params.attacker:GetTeamNumber() then
			local ability = self:GetAbility()

			local items = {
				"item_searing_blade",
				"item_orb_of_fire2",
				"item_orb_of_fire",
			}

			if ability == nil then
				for _, item_name in ipairs(items) do
					if self:GetParent():HasItemInInventory(item_name) then
						ability = self:GetParent():FindItemByName(item_name, false)

						break
					end
				end
			end

			-- if it's still nil after item check
			if ability == nil then
				print("No item for this modifier, remove it!")
				self:GetParent():RemoveModifierByName("modifier_orb_of_fire_active")

				return
			end

			if not params.target:IsBuilding() then
				local event = {}
				event.caster = params.attacker
				event.target = params.target
				event.ability = ability
				Splash(event)
			end
		end
	end
end

--------------------------------------------------------------

modifier_orb_of_fire_passive = class({})

function modifier_orb_of_fire_passive:IsHidden() return true end
function modifier_orb_of_fire_passive:IsPurgable() return false end
function modifier_orb_of_fire_passive:IsPurgeException() return false end
function modifier_orb_of_fire_passive:IsDebuff() return false end
function modifier_orb_of_fire_passive:RemoveOnDeath() return false end

-- allow multiple instances of that modifier
function modifier_orb_of_fire_passive:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_orb_of_fire_passive:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
	}
end

function modifier_orb_of_fire_passive:GetModifierPreAttack_BonusDamage()
	return self:GetAbility():GetSpecialValueFor("bonus_damage")
end
