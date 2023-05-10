-- Credits: EarthSalamander #42
-- Date (DD/MM/YYYY): 14/12/2018

LinkLuaModifier("modifier_orb_of_darkness_active", "items/item_orb_of_darkness.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_orb_of_darkness_passive", "items/item_orb_of_darkness.lua", LUA_MODIFIER_MOTION_NONE)

local function StartSpell(caster, ability)
	if caster:HasModifier("modifier_orb_of_darkness_active") then
		-- kill units under control when disabling the orb
		local darkness_units = FindUnitsInRadius(caster:GetTeamNumber(), Vector(0, 0, 0), nil, FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)

		for _, darkness_unit in pairs(darkness_units) do
			if darkness_unit:HasAbility("orb_of_darkness_unit") then
				darkness_unit:ForceKill(false)
			end
		end

		caster:RemoveModifierByName("modifier_orb_of_darkness_active")
	else
		caster:AddNewModifier(caster, ability, "modifier_orb_of_darkness_active", {})
	end
end

item_orb_of_darkness = item_orb_of_darkness or class({})

function item_orb_of_darkness:GetIntrinsicModifierName()
	return "modifier_orb_of_darkness_passive"
end

function item_orb_of_darkness:OnSpellStart()
	if not IsServer() then return end

	StartSpell(self:GetCaster(), self)
end

function item_orb_of_darkness:GetAbilityTextureName()
	if self:GetCaster():HasModifier("modifier_orb_of_darkness_active") then
		return "custom/orb_of_darkness"
	end

	return "custom/orb_of_darkness_off"
end

--------------------------------------------------------------

item_orb_of_darkness2 = item_orb_of_darkness2 or class({})

function item_orb_of_darkness2:GetIntrinsicModifierName()
	return "modifier_orb_of_darkness_passive"
end

function item_orb_of_darkness2:OnSpellStart()
	if not IsServer() then return end

	StartSpell(self:GetCaster(), self)
end

function item_orb_of_darkness2:GetAbilityTextureName()
	if self:GetCaster():HasModifier("modifier_orb_of_darkness_active") then
		return "custom/orb_of_darkness2"
	end

	return "custom/orb_of_darkness2_off"
end

--------------------------------------------------------------

item_bracer_of_the_void = item_bracer_of_the_void or class({})

function item_bracer_of_the_void:GetIntrinsicModifierName()
	return "modifier_orb_of_darkness_passive"
end

function item_bracer_of_the_void:OnSpellStart()
	if not IsServer() then return end

	StartSpell(self:GetCaster(), self)
end

function item_bracer_of_the_void:GetAbilityTextureName()
	if self:GetCaster():HasModifier("modifier_orb_of_darkness_active") then
		return "custom/bracer_of_the_void"
	end

	return "custom/bracer_of_the_void_off"
end

--------------------------------------------------------------

modifier_orb_of_darkness_active = modifier_orb_of_darkness_active or class({})

function modifier_orb_of_darkness_active:IsHidden() return false end

function modifier_orb_of_darkness_active:IsPurgable() return false end

function modifier_orb_of_darkness_active:IsPurgeException() return false end

function modifier_orb_of_darkness_active:IsDebuff() return false end

function modifier_orb_of_darkness_active:RemoveOnDeath() return false end

function modifier_orb_of_darkness_active:GetTexture() return "modifiers/orb_of_darkness" end

function modifier_orb_of_darkness_active:GetEffectAttachType()
	return "attach_attack1"
end

function modifier_orb_of_darkness_active:GetEffectName()
	return "particles/units/heroes/hero_ursa/ursa_enrage_buff_glow.vpcf"
end

function modifier_orb_of_darkness_active:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_DEATH,
	}
end

function modifier_orb_of_darkness_active:OnCreated()
	--	self.ability = self:GetAbility()
	self.duration = self:GetAbility():GetSpecialValueFor("duration")
	self.max_units = self:GetAbility():GetSpecialValueFor("max_units")

	self:StartIntervalThink(0.1)
end

function modifier_orb_of_darkness_active:OnIntervalThink()
	if not self or not self.GetParent or not self:GetParent().GetItemInSlot then return end

	local has_parent_item = false

	for i = 0, 5 do
		local item = self:GetParent():GetItemInSlot(i)

		if item then
			for k, v in pairs(MODIFIER_ITEMS_WITH_LEVELS["modifier_orb_of_darkness_active"]) do
				--				print(v, item:GetAbilityName())
				if v == item:GetAbilityName() then
					has_parent_item = true

					break
				end
			end
		end
	end

	--	print("Has parent item?", has_parent_item)
	if has_parent_item == false then
		--		print("has_parent_item:", has_parent_item)
		self:GetParent():RemoveModifierByName("modifier_orb_of_darkness_active")
	end
end

function modifier_orb_of_darkness_active:OnDeath(params)
	if not IsServer() then return end
	--	if self:GetAbility() == nil then
	--		local items = {
	--			"item_bracer_of_the_void",
	--			"item_orb_of_darkness2",
	--			"item_orb_of_darkness",
	--		}

	--		local new_item = false
	--		for _, item_name in ipairs(items) do
	--			if self:GetParent():HasItemInInventory(item_name) then
	--				print("Change main item with:", item_name)
	--				self.ability = self:GetParent():FindItemByName(item_name, false)
	--				new_item = true
	--				break
	--			end
	--		end
	--	end

	--	if new_item == false then
	--		print("No item for this modifier, remove it!")
	--		self:GetParent():RemoveModifierByName("modifier_orb_of_darkness_active")
	--
	--		return
	--	end

	if params.attacker == self:GetParent() and LeavesCorpse(params.unit) and params.unit.no_corpse ~= true and not params.unit:IsConsideredHero() then
		if self:GetStackCount() < self.max_units then
			local unit = CreateUnitByName(params.unit:GetUnitName(), params.unit:GetAbsOrigin(), true, self:GetParent(), self:GetParent(), self:GetParent():GetTeam())
			unit:SetControllableByPlayer(self:GetParent():GetPlayerID(), true)
			unit:SetOwner(self:GetParent())
			unit:SetForwardVector(params.unit:GetForwardVector())
			unit:AddAbility("holdout_blue_effect"):SetLevel(1)
			unit:AddAbility("orb_of_darkness_unit"):SetLevel(1)
			FindClearSpaceForUnit(unit, params.unit:GetAbsOrigin(), true)

			unit:AddNewModifier(self:GetParent(), nil, "modifier_kill", { duration = self.duration })
			unit:SetNoCorpse()
			unit.no_corpse = true

			for i = 0, 15 do
				local a = unit:GetAbilityByIndex(i)
				if a and not a:IsPassive() then
					a:SetActivated(false)
				end
			end

			-- the unit is reincarnated, don't want to see the previous unit dying
			params.unit:AddNoDraw()

			-- increase the number of units under your control
			self:SetStackCount(self:GetStackCount() + 1)
		end
	elseif params.unit:HasAbility("orb_of_darkness_unit") then
		-- reduce unit count under control when 1 of them is dying
		self:SetStackCount(self:GetStackCount() - 1)
	end
end

--------------------------------------------------------------

modifier_orb_of_darkness_passive = modifier_orb_of_darkness_passive or class({})

function modifier_orb_of_darkness_passive:IsHidden() return true end

function modifier_orb_of_darkness_passive:IsPurgable() return false end

function modifier_orb_of_darkness_passive:IsPurgeException() return false end

function modifier_orb_of_darkness_passive:IsDebuff() return false end

function modifier_orb_of_darkness_passive:RemoveOnDeath() return false end

-- allow multiple instances of that modifier
function modifier_orb_of_darkness_passive:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_orb_of_darkness_passive:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
		MODIFIER_PROPERTY_HEALTH_BONUS,
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
		MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
	}
end

function modifier_orb_of_darkness_passive:GetModifierPreAttack_BonusDamage()
	return self:GetAbility():GetSpecialValueFor("bonus_damage")
end

function modifier_orb_of_darkness_passive:GetModifierHealthBonus()
	return self:GetAbility():GetSpecialValueFor("bonus_hp")
end

function modifier_orb_of_darkness_passive:GetModifierPhysicalArmorBonus()
	return self:GetAbility():GetSpecialValueFor("bonus_armor")
end

function modifier_orb_of_darkness_passive:GetModifierConstantHealthRegen()
	return self:GetAbility():GetSpecialValueFor("bonus_health_regen")
end
