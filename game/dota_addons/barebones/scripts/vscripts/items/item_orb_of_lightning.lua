-- Credits: EarthSalamander #42
-- Date (DD/MM/YYYY): 14/12/2018

LinkLuaModifier("modifier_orb_of_lightning_active", "items/item_orb_of_lightning.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_orb_of_lightning_passive", "items/item_orb_of_lightning.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_orb_of_lightning_purge", "items/item_orb_of_lightning.lua", LUA_MODIFIER_MOTION_NONE)

local function StartSpell(caster, ability)
	if caster:HasModifier("modifier_orb_of_lightning_active") then
		caster:RemoveModifierByName("modifier_orb_of_lightning_active")
	else
		caster:AddNewModifier(caster, ability, "modifier_orb_of_lightning_active", {})
	end
end

local function StartLightningOrbsCooldown(hero, items, cooldown)
	for i = 0, 5 do
		local item = hero:GetItemInSlot(i)

		if item then
			for _, item_name in ipairs(items) do
				if item:GetName() == item_name then
					item:StartCooldown(cooldown)
				end
			end
		end
	end
end

item_orb_of_lightning = class({})

function item_orb_of_lightning:GetIntrinsicModifierName()
	return "modifier_orb_of_lightning_passive"
end

function item_orb_of_lightning:OnSpellStart()
	if IsServer() then
		StartSpell(self:GetCaster(), self)
	end
end

function item_orb_of_lightning:GetAbilityTextureName()
	if self:GetCaster():HasModifier("modifier_orb_of_lightning_active") then
		return "custom/orb_of_lightning"
	end

	return "custom/orb_of_lightning_off"
end

--------------------------------------------------------------

item_orb_of_lightning2 = class({})

function item_orb_of_lightning2:GetIntrinsicModifierName()
	return "modifier_orb_of_lightning_passive"
end

function item_orb_of_lightning2:OnSpellStart()
	if IsServer() then
		StartSpell(self:GetCaster(), self)
	end
end

function item_orb_of_lightning2:GetAbilityTextureName()
	if self:GetCaster():HasModifier("modifier_orb_of_lightning_active") then
		return "custom/orb_of_lightning2"
	end

	return "custom/orb_of_lightning2_off"
end

--------------------------------------------------------------

item_celestial_claws = class({})

function item_celestial_claws:GetIntrinsicModifierName()
	return "modifier_orb_of_lightning_passive"
end

function item_celestial_claws:OnSpellStart()
	if IsServer() then
		StartSpell(self:GetCaster(), self)
	end
end

function item_celestial_claws:GetAbilityTextureName()
	if self:GetCaster():HasModifier("modifier_orb_of_lightning_active") then
		return "custom/celestial_claws"
	end

	return "custom/celestial_claws_off"
end

function item_celestial_claws:OnEquip()
	local BAT = self:GetCaster():GetBaseAttackTime()
	local BAT_Dec = self:GetSpecialValueFor("bat_reduction")

	print("Equip: Reduce BAT!")
	self:GetCaster():SetBaseAttackTime(BAT - BAT_Dec)
end

function item_celestial_claws:OnUnequip()
	local BAT = self:GetCaster():GetBaseAttackTime()
	local BAT_Dec = self:GetLevelSpecialValueFor("bat_reduction")

	print("Unequip: Increase BAT!")
	self:GetCaster():SetBaseAttackTime(BAT + BAT_Dec)
end

--------------------------------------------------------------

modifier_orb_of_lightning_active = class({})

function modifier_orb_of_lightning_active:IsHidden() return false end
function modifier_orb_of_lightning_active:IsPurgable() return false end
function modifier_orb_of_lightning_active:IsPurgeException() return false end
function modifier_orb_of_lightning_active:IsDebuff() return false end
function modifier_orb_of_lightning_active:RemoveOnDeath() return false end

function modifier_orb_of_lightning_active:GetEffectAttachType()
	return "attach_attack1"
end

function modifier_orb_of_lightning_active:GetEffectName()
	return "particles/custom/items/orb/orb_of_lightning/orb.vpcf"
end

function modifier_orb_of_lightning_active:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_ATTACK_LANDED,
	}
end

function modifier_orb_of_lightning_active:OnCreated()
--	self.ability = self:GetAbility()
	self.duration = self:GetAbility():GetSpecialValueFor("duration")
	self.purge_chance = self:GetAbility():GetSpecialValueFor("purge_chance")
	self.purge_cooldown = self:GetAbility():GetSpecialValueFor("purge_cooldown")
end

function modifier_orb_of_lightning_active:OnAttackLanded(params)
	if IsServer() then
		if params.attacker == self:GetParent() and params.target:GetTeamNumber() ~= params.attacker:GetTeamNumber() then
			local ability = self:GetAbility()

			local items = {
				"item_celestial_claws",
				"item_orb_of_lightning2",
				"item_orb_of_lightning",
			}

			if ability == nil then
				local new_item = false

				for _, item_name in ipairs(items) do
					if self:GetParent():HasItemInInventory(item_name) then
						new_item = true
						ability = self:GetParent():FindItemByName(item_name, false)

						break
					end
				end
			end

			if new_item == false then
				print("No item for this modifier, remove it!")
				self:GetParent():RemoveModifierByName("modifier_orb_of_lightning_active")

				return
			end

			if RandomInt(1, 100) <= self.purge_chance then
				if ability:IsCooldownReady() then
					if not params.target:IsBuilding() then
						params.target:AddNewModifier(caster, ability, "modifier_orb_of_lightning_purge", {duration = self.duration})
						StartLightningOrbsCooldown(params.attacker, items, self.purge_cooldown)
					end
				end
			end
		end
	end
end

--------------------------------------------------------------

modifier_orb_of_lightning_passive = class({})

function modifier_orb_of_lightning_passive:IsHidden() return true end
function modifier_orb_of_lightning_passive:IsPurgable() return false end
function modifier_orb_of_lightning_passive:IsPurgeException() return false end
function modifier_orb_of_lightning_passive:IsDebuff() return false end
function modifier_orb_of_lightning_passive:RemoveOnDeath() return false end

-- allow multiple instances of that modifier
function modifier_orb_of_lightning_passive:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_orb_of_lightning_passive:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
		MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT,
		MODIFIER_PROPERTY_BASE_ATTACK_TIME_CONSTANT,
	}
end

function modifier_orb_of_lightning_passive:GetModifierPreAttack_BonusDamage()
	return self:GetAbility():GetSpecialValueFor("bonus_damage")
end

function modifier_orb_of_lightning_passive:GetModifierMoveSpeedBonus_Constant()
	return self:GetAbility():GetSpecialValueFor("bonus_movespeed")
end

--------------------------------------------------------------

modifier_orb_of_lightning_purge = class({})

function modifier_orb_of_lightning_purge:IsHidden() return false end
function modifier_orb_of_lightning_purge:IsPurgable() return false end
function modifier_orb_of_lightning_purge:IsPurgeException() return false end
function modifier_orb_of_lightning_purge:IsDebuff() return true end

function modifier_orb_of_lightning_purge:CheckState()
	return {
		[MODIFIER_STATE_ROOTED] = true,
	}
end

function modifier_orb_of_lightning_purge:GetEffectName()
	return "particles/generic_gameplay/generic_purge.vpcf"
end

function modifier_orb_of_lightning_purge:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_orb_of_lightning_purge:OnCreated()
	if IsServer() then
		local RemovePositiveBuffs = true
		local RemoveDebuffs = false
		local BuffsCreatedThisFrameOnly = false
		local RemoveStuns = false
		local RemoveExceptions = false

		self:GetParent():EmitSound("DOTA_Item.DiffusalBlade.Target")
		self:GetParent():Purge(RemovePositiveBuffs, RemoveDebuffs, BuffsCreatedThisFrameOnly, RemoveStuns, RemoveExceptions)

		if self:GetParent():IsSummoned() then
			ApplyDamage({victim = self:GetParent(), attacker = self:GetCaster(), damage = self:GetAbility():GetSpecialValueFor('damage_to_summons'), damage_type = DAMAGE_TYPE_PURE, ability = self:GetAbility()})
			StartLightningOrbsCooldown(params.attacker, items, 10.0)
		end
	end
end
