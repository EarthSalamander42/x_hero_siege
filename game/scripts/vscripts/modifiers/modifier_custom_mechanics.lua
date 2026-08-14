modifier_custom_mechanics = modifier_custom_mechanics or class({})
modifier_custom_mechanics.XHS_LINK_CLIENT = true

function modifier_custom_mechanics:IsHidden() return true end

function modifier_custom_mechanics:IsPurgable() return false end

function modifier_custom_mechanics:RemoveOnDeath() return false end

function modifier_custom_mechanics:CheckState()
	return {
		[MODIFIER_STATE_NO_HEALTH_BAR] = true,
	}
end

function modifier_custom_mechanics:DeclareFunctions()
	return {
		--	MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
		MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE,
		MODIFIER_EVENT_ON_ABILITY_EXECUTED,
		MODIFIER_EVENT_ON_ORDER,
		MODIFIER_EVENT_ON_TAKEDAMAGE,
	}
end

function modifier_custom_mechanics:OnCreated()
	self.required_intellect = 16

	if not IsServer() then return end

	self.last_logged_agility = nil
	-- self:StartIntervalThink(1.0)
	--	self.magical_resistance = 0
	--	self.intellect =
	--	self:SetHasCustomTransmitterData(true)
end

function modifier_custom_mechanics:LogAgilityArmorComparison()
	local parent = self:GetParent()
	if parent == nil or parent:IsNull() or not parent:IsRealHero() then return end

	local agility = tonumber(parent:GetAgility()) or 0
	if self.last_logged_agility ~= nil and math.abs(agility - self.last_logged_agility) < 0.01 then return end
	self.last_logged_agility = agility

	local currentArmor = tonumber(parent:GetPhysicalArmorValue(false)) or 0
	local vanillaAgilityArmor = agility / 6
	local xhsAgilityArmor = agility / 12
	local removedArmor = vanillaAgilityArmor - xhsAgilityArmor

	print(string.format(
		"[XHS][AgilityArmor] hero=%s agility=%.2f actual_total=%.2f vanilla_agi=%.2f xhs_agi=%.2f removed=%.2f total_if_vanilla=%.2f",
		parent:GetUnitName(), agility, currentArmor, vanillaAgilityArmor,
		xhsAgilityArmor, removedArmor, currentArmor + removedArmor
	))
end

--[[
function modifier_warpath_weaponsmith_basic_arms:AddCustomTransmitterData() return {
	bonus_damage = self.bonus_damage
} end

function modifier_warpath_weaponsmith_basic_arms:HandleCustomTransmitterData(data)
	self.bonus_damage = data.bonus_damage
end
--]]
-- function modifier_custom_mechanics:OnIntervalThink()
-- self:LogAgilityArmorComparison()
--	self.armor_fix = (self:GetParent():GetAgility() * 0.16) * (-1) -- Don't ask.
-- end

function modifier_custom_mechanics:GetModifierPhysicalArmorBonus()
	--	return self.armor_fix
end

function modifier_custom_mechanics:GetModifierSpellAmplify_Percentage()
	return self:GetParent():GetIntellect(true) * (1 / self.required_intellect)
end

function modifier_custom_mechanics:OnAbilityExecuted(keys)
	if not IsServer() or keys.unit ~= self:GetParent() then return end

	local ability = keys.ability
	if ability == nil or (ability.IsNull ~= nil and ability:IsNull()) then return end
	local level = math.floor(tonumber(ability:GetLevel()) or 0)
	if level <= 0 then return end

	-- Summoned NPCs frequently keep their KV unit level at 1 even when the
	-- summoning spell was upgraded. Preserve the cast-time level on the owner;
	-- the health-bar spawn relay consumes this immutable snapshot.
	local parent = self:GetParent()
	parent.xhs_last_executed_ability = {
		name = ability:GetAbilityName(),
		level = level,
		cast_time = GameRules:GetGameTime(),
	}
end

function modifier_custom_mechanics:OnOrder(keys)
	if not IsServer() then return end
	local parent = self:GetParent()
	if parent == nil or parent:IsNull() or keys == nil then return end

	-- OnOrder is lower-level than ExecuteOrderFilter for several inventory UI
	-- paths. Validate the GIVE_ITEM handles here so an invalid gift reports at
	-- click time. RejectInvalidXHSBotGiftAtIssue interrupts the ordered unit and
	-- follows with STOP because this modifier event is only observational.
	local unit = keys.unit
	local target = keys.target
	local ability = keys.ability
	local parentIsRelevant = unit == parent or target == parent
	if not parentIsRelevant and ability ~= nil and ability.GetCaster ~= nil then
		local ok, caster = pcall(function() return ability:GetCaster() end)
		parentIsRelevant = ok and caster == parent
	end
	if not parentIsRelevant then return end

	local gameMode = GameRules ~= nil and GameRules.GameMode or nil
	local rejected = false
	if gameMode ~= nil and gameMode.RejectInvalidXHSBotGiftAtIssue ~= nil then
		rejected = gameMode:RejectInvalidXHSBotGiftAtIssue(keys, parent) == true
	end
	if rejected then
		return false
	end
end

function modifier_custom_mechanics:OnTakeDamage(keys)
	if not IsServer() then return end

	local attacker = keys.attacker

	if self:GetParent() ~= attacker then return end

	local target = keys.unit

	if not target or target:IsNull() then return end

	if target:IsBuilding() or (target:GetTeam() == attacker:GetTeam()) then
		return
	end

	local is_attack_damage = keys.damage_category == DOTA_DAMAGE_CATEGORY_ATTACK
	if keys.damage_category == nil then
		is_attack_damage = keys.inflictor == nil
	end
	if not is_attack_damage or (tonumber(keys.damage) or 0) <= 0 then return end

	if bit ~= nil and bit.band(keys.damage_flags or 0, DOTA_DAMAGE_FLAG_REFLECTION) ~= 0 then
		return
	end

	attacker:SendLifestealAttack(target, keys.damage)
end
