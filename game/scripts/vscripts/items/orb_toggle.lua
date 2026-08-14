XHSOrbToggle = XHSOrbToggle or {}

local function IsValidEntity(entity)
	return entity ~= nil and not entity:IsNull()
end

local function FindActiveModifier(parent, modifier_name)
	if not IsValidEntity(parent) then return nil end
	return parent:FindModifierByName(modifier_name)
end

local function IsAbilityInMainInventory(parent, ability)
	if not IsValidEntity(parent) or not IsValidEntity(ability) then return false end

	for slot = 0, 5 do
		if parent:GetItemInSlot(slot) == ability then
			return true
		end
	end

	return false
end

local function RemoveActiveModifier(active_modifier)
	if active_modifier == nil then return end

	if active_modifier.DestroyControlledUnits ~= nil then
		active_modifier:DestroyControlledUnits()
	end

	active_modifier:Destroy()
end

local function ActivateIfDesired(parent, ability, modifier_name)
	if not IsAbilityInMainInventory(parent, ability)
		or not ability.xhs_orb_active
	then
		return false
	end

	local active_modifier = FindActiveModifier(parent, modifier_name)
	if active_modifier ~= nil then
		return active_modifier:GetAbility() == ability
	end

	parent:AddNewModifier(parent, ability, modifier_name, {})
	active_modifier = FindActiveModifier(parent, modifier_name)
	return active_modifier ~= nil and active_modifier:GetAbility() == ability
end

function XHSOrbToggle.Toggle(caster, ability, modifier_name)
	if not IsServer() or not IsValidEntity(caster) or not IsValidEntity(ability) then return end

	local active_modifier = FindActiveModifier(caster, modifier_name)
	if active_modifier ~= nil then
		local active_ability = active_modifier:GetAbility()
		if IsValidEntity(active_ability) then
			active_ability.xhs_orb_active = false
		end
		ability.xhs_orb_active = false
		RemoveActiveModifier(active_modifier)
		return
	end

	ability.xhs_orb_active = true
	caster:AddNewModifier(caster, ability, modifier_name, {})
end

function XHSOrbToggle.OnIntrinsicCreated(intrinsic_modifier, active_modifier_name)
	if not IsServer() or intrinsic_modifier == nil then return end

	local parent = intrinsic_modifier:GetParent()
	local ability = intrinsic_modifier:GetAbility()
	if not IsValidEntity(parent) or not IsValidEntity(ability) or parent:IsIllusion() then return end
	intrinsic_modifier.xhs_orb_ability = ability

	if ability.xhs_orb_active == nil then
		ability.xhs_orb_active = true
	end

	if ActivateIfDesired(parent, ability, active_modifier_name) then
		return
	end

	-- Recipe upgrades can create the new intrinsic before destroying the old one.
	-- Retry throughout the inventory transaction so level 2/3 recipe results
	-- reliably inherit the default active state.
	if Timers ~= nil then
		local attempts = 0
		Timers:CreateTimer(0.03, function()
			if not IsValidEntity(parent)
				or not IsValidEntity(ability)
				or not ability.xhs_orb_active
			then
				return nil
			end

			if ActivateIfDesired(parent, ability, active_modifier_name) then
				return nil
			end

			attempts = attempts + 1
			if attempts >= 20 then
				return nil
			end

			return 0.05
		end)
	end
end

function XHSOrbToggle.OnIntrinsicDestroyed(intrinsic_modifier, active_modifier_name)
	if not IsServer() or intrinsic_modifier == nil then return end

	local parent = intrinsic_modifier:GetParent()
	local ability = intrinsic_modifier.xhs_orb_ability or intrinsic_modifier:GetAbility()
	local active_modifier = FindActiveModifier(parent, active_modifier_name)
	if active_modifier == nil then return end

	local active_ability = active_modifier:GetAbility()
	if ability ~= nil and active_ability ~= nil and active_ability ~= ability then return end
	RemoveActiveModifier(active_modifier)
end
