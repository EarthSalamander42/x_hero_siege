-- Credits: EarthSalamander #42
-- Date (DD/MM/YYYY): 14/12/2018

LinkLuaModifier("modifier_orb_of_darkness_active", "items/item_orb_of_darkness.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_orb_of_darkness_controlled", "items/item_orb_of_darkness.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_orb_of_darkness_passive", "items/item_orb_of_darkness.lua", LUA_MODIFIER_MOTION_NONE)

local ORB_CONTROL_MARKER_ABILITY = "orb_of_darkness_unit"
local ORB_VISUAL_ABILITY = "holdout_blue_effect"
local ORB_ACTIVE_MODIFIER = "modifier_orb_of_darkness_active"
local ORB_CONTROLLED_MODIFIER = "modifier_orb_of_darkness_controlled"

local function IsValidEntity(entity)
	return entity ~= nil and not entity:IsNull()
end

local function IsValidLivingUnit(unit)
	return IsValidEntity(unit) and unit:IsAlive()
end

local function FindOrbItem(caster)
	if not IsValidEntity(caster) then
		return nil
	end

	local item_names = MODIFIER_ITEMS_WITH_LEVELS[ORB_ACTIVE_MODIFIER] or {}

	for slot = 0, 5 do
		local item = caster:GetItemInSlot(slot)

		if item then
			local item_name = item:GetAbilityName()

			for _, orb_item_name in ipairs(item_names) do
				if item_name == orb_item_name then
					return item
				end
			end
		end
	end

	return nil
end

local function HasOrbItem(caster)
	return FindOrbItem(caster) ~= nil
end

local function IsControlledByOrbOwner(unit, owner)
	if not IsValidEntity(unit) or not IsValidEntity(owner) then
		return false
	end

	if not unit:HasAbility(ORB_CONTROL_MARKER_ABILITY) then
		return false
	end

	if unit:GetOwner() == owner then
		return true
	end

	return unit:GetPlayerOwnerID() == owner:GetPlayerID()
end

local function KillOwnedOrbUnits(owner)
	if not IsValidEntity(owner) then
		return
	end

	local units = FindUnitsInRadius(
		owner:GetTeamNumber(),
		Vector(0, 0, 0),
		nil,
		FIND_UNITS_EVERYWHERE,
		DOTA_UNIT_TARGET_TEAM_FRIENDLY,
		DOTA_UNIT_TARGET_CREEP,
		DOTA_UNIT_TARGET_FLAG_NONE,
		FIND_ANY_ORDER,
		false
	)

	for _, unit in pairs(units) do
		if IsControlledByOrbOwner(unit, owner) then
			unit:Kill(nil, nil)
		end
	end
end

local function DisableActiveAbilities(unit)
	if not IsValidEntity(unit) then
		return
	end

	ForEachUnitAbility(unit, function(ability)
		if ability and not ability:IsPassive() then
			ability:SetActivated(false)
		end
	end)
end

local function ToggleOrb(caster, ability)
	if not IsServer() or not IsValidEntity(caster) then
		return
	end

	local active_modifier = caster:FindModifierByName(ORB_ACTIVE_MODIFIER)

	if active_modifier then
		active_modifier:DestroyControlledUnits()
		caster:RemoveModifierByName(ORB_ACTIVE_MODIFIER)
		return
	end

	caster:AddNewModifier(caster, ability, ORB_ACTIVE_MODIFIER, {})
end

local function GetOrbTexture(caster, active_texture, inactive_texture)
	if IsValidEntity(caster) and caster:HasModifier(ORB_ACTIVE_MODIFIER) then
		return active_texture
	end

	return inactive_texture
end

item_orb_of_darkness = item_orb_of_darkness or class({})

function item_orb_of_darkness:GetIntrinsicModifierName()
	return "modifier_orb_of_darkness_passive"
end

function item_orb_of_darkness:OnSpellStart()
	ToggleOrb(self:GetCaster(), self)
end

function item_orb_of_darkness:GetAbilityTextureName()
	return GetOrbTexture(self:GetCaster(), "custom/orb_of_darkness", "custom/orb_of_darkness_off")
end

item_orb_of_darkness2 = item_orb_of_darkness2 or class({})

function item_orb_of_darkness2:GetIntrinsicModifierName()
	return "modifier_orb_of_darkness_passive"
end

function item_orb_of_darkness2:OnSpellStart()
	ToggleOrb(self:GetCaster(), self)
end

function item_orb_of_darkness2:GetAbilityTextureName()
	return GetOrbTexture(self:GetCaster(), "custom/orb_of_darkness2", "custom/orb_of_darkness2_off")
end

item_bracer_of_the_void = item_bracer_of_the_void or class({})

function item_bracer_of_the_void:GetIntrinsicModifierName()
	return "modifier_orb_of_darkness_passive"
end

function item_bracer_of_the_void:OnSpellStart()
	ToggleOrb(self:GetCaster(), self)
end

function item_bracer_of_the_void:GetAbilityTextureName()
	return GetOrbTexture(self:GetCaster(), "custom/bracer_of_the_void", "custom/bracer_of_the_void_off")
end

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
	self.controlled_units = {}
	self:RefreshSpecialValues()

	if IsServer() then
		self:StartIntervalThink(0.5)
	end
end

function modifier_orb_of_darkness_active:OnRefresh()
	self:RefreshSpecialValues()

	if IsServer() then
		self:PruneControlledUnits()
	end
end

function modifier_orb_of_darkness_active:OnDestroy()
	if not IsServer() then
		return
	end

	self:SetStackCount(0)
end

function modifier_orb_of_darkness_active:RefreshSpecialValues()
	local ability = self:GetAbility()

	if IsServer() then
		ability = FindOrbItem(self:GetParent()) or ability
	end

	self.duration = ability and ability:GetSpecialValueFor("duration") or 25.0
	self.max_units = ability and ability:GetSpecialValueFor("max_units") or 10
end

function modifier_orb_of_darkness_active:OnIntervalThink()
	local parent = self:GetParent()

	if not IsValidEntity(parent) then
		self:Destroy()
		return
	end

	if not HasOrbItem(parent) then
		self:DestroyControlledUnits()
		parent:RemoveModifierByName(ORB_ACTIVE_MODIFIER)
		return
	end

	self:PruneControlledUnits()
end

function modifier_orb_of_darkness_active:PruneControlledUnits()
	if not self.controlled_units then
		self.controlled_units = {}
	end

	local count = 0

	for entindex, unit in pairs(self.controlled_units) do
		if IsValidLivingUnit(unit) and IsControlledByOrbOwner(unit, self:GetParent()) then
			count = count + 1
		else
			self.controlled_units[entindex] = nil
		end
	end

	self:SetStackCount(count)
	return count
end

function modifier_orb_of_darkness_active:RegisterControlledUnit(unit)
	if not IsValidEntity(unit) then
		return
	end

	if not self.controlled_units then
		self.controlled_units = {}
	end

	self.controlled_units[unit:entindex()] = unit
	self:PruneControlledUnits()
end

function modifier_orb_of_darkness_active:UnregisterControlledUnit(unit)
	if not self.controlled_units or not IsValidEntity(unit) then
		return
	end

	self.controlled_units[unit:entindex()] = nil
	self:PruneControlledUnits()
end

function modifier_orb_of_darkness_active:DestroyControlledUnits()
	local parent = self:GetParent()

	if self.controlled_units then
		for entindex, unit in pairs(self.controlled_units) do
			if IsValidLivingUnit(unit) then
				unit:Kill(nil, nil)
			end

			self.controlled_units[entindex] = nil
		end
	end

	KillOwnedOrbUnits(parent)
	self:SetStackCount(0)
end

function modifier_orb_of_darkness_active:CanConvertUnit(unit)
	if not IsValidEntity(unit) then
		return false
	end

	if unit.no_corpse == true or unit:IsConsideredHero() then
		return false
	end

	return LeavesCorpse(unit)
end

function modifier_orb_of_darkness_active:ConvertUnit(source_unit)
	local owner = self:GetParent()

	if not IsValidEntity(owner) or not self:CanConvertUnit(source_unit) then
		return
	end

	if self:PruneControlledUnits() >= self.max_units then
		return
	end

	local converted_unit = CreateUnitByName(
		source_unit:GetUnitName(),
		source_unit:GetAbsOrigin(),
		true,
		owner,
		owner,
		owner:GetTeamNumber()
	)

	converted_unit:SetControllableByPlayer(owner:GetPlayerID(), true)
	converted_unit:SetOwner(owner)
	converted_unit:SetForwardVector(source_unit:GetForwardVector())
	converted_unit:AddAbility(ORB_VISUAL_ABILITY):SetLevel(1)
	converted_unit:AddAbility(ORB_CONTROL_MARKER_ABILITY):SetLevel(1)

	FindClearSpaceForUnit(converted_unit, source_unit:GetAbsOrigin(), true)

	local ability = FindOrbItem(owner) or self:GetAbility()
	converted_unit:AddNewModifier(owner, ability, ORB_CONTROLLED_MODIFIER, { duration = self.duration })
	converted_unit:AddNewModifier(owner, ability, "modifier_kill", { duration = self.duration })
	converted_unit:SetNoCorpse()
	converted_unit.no_corpse = true

	DisableActiveAbilities(converted_unit)

	source_unit:AddNoDraw()
	self:RegisterControlledUnit(converted_unit)
end

function modifier_orb_of_darkness_active:OnDeath(params)
	if not IsServer() or not params or not IsValidEntity(params.unit) then
		return
	end

	local parent = self:GetParent()

	if params.attacker == parent then
		self:ConvertUnit(params.unit)
		return
	end

	if IsControlledByOrbOwner(params.unit, parent) then
		self:UnregisterControlledUnit(params.unit)
	end
end

modifier_orb_of_darkness_controlled = modifier_orb_of_darkness_controlled or class({})

function modifier_orb_of_darkness_controlled:IsHidden() return true end
function modifier_orb_of_darkness_controlled:IsPurgable() return false end
function modifier_orb_of_darkness_controlled:IsPurgeException() return false end
function modifier_orb_of_darkness_controlled:IsDebuff() return false end

function modifier_orb_of_darkness_controlled:OnDestroy()
	if not IsServer() then
		return
	end

	local owner = self:GetCaster()

	if not IsValidEntity(owner) then
		return
	end

	local active_modifier = owner:FindModifierByName(ORB_ACTIVE_MODIFIER)

	if active_modifier then
		active_modifier:UnregisterControlledUnit(self:GetParent())
	end
end

modifier_orb_of_darkness_passive = modifier_orb_of_darkness_passive or class({})

function modifier_orb_of_darkness_passive:IsHidden() return true end
function modifier_orb_of_darkness_passive:IsPurgable() return false end
function modifier_orb_of_darkness_passive:IsPurgeException() return false end
function modifier_orb_of_darkness_passive:IsDebuff() return false end
function modifier_orb_of_darkness_passive:RemoveOnDeath() return false end

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
