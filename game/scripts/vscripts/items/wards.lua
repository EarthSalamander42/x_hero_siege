require('libraries/timers')

item_healing_wards = class({})
item_healing_wards2 = class({})

local function SummonHealingWardFromAbility(ability, caster, point, ward_name)
	if not IsServer() then return end
	if not ability or not caster or not point then return end

	local duration = ability:GetSpecialValueFor("duration")
	local ward = CreateUnitByName(ward_name, point, false, caster, caster, caster:GetTeamNumber())

	ward:AddNewModifier(caster, nil, "modifier_kill", {duration = duration})
	ward:AddNewModifier(caster, nil, "modifier_invulnerable", {duration = duration})
	ward:AddNewModifier(caster, nil, "modifier_phased", {duration = duration})
	ward:EmitSound("Hero_Juggernaut.HealingWard.Cast")
	ward:EmitSound("Hero_Juggernaut.HealingWard.Loop")

	Timers:CreateTimer(duration, function()
		if not IsValidEntity(ward) then return end
		ward:EmitSound("Hero_Juggernaut.HealingWard.Stop")
		ward:StopSound("Hero_Juggernaut.HealingWard.Loop")
	end)

	ability:SpendCharge(0.0)
end

function item_healing_wards:GetAbilityTextureName()
	return "custom/healing_wards"
end

function item_healing_wards:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end

function item_healing_wards:OnSpellStart()
	SummonHealingWardFromAbility(self, self:GetCaster(), self:GetCursorPosition(), "healing_ward")
end

function item_healing_wards2:GetAbilityTextureName()
	return "custom/healing_wards2"
end

function item_healing_wards2:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end

function item_healing_wards2:OnSpellStart()
	SummonHealingWardFromAbility(self, self:GetCaster(), self:GetCursorPosition(), "healing_ward2")
end

function SummonHealingWard(event)
	local caster = event.caster
	local ability = event.ability
	local point = event.target_points[1]
	local ward_name = "healing_ward"

	if ability and ability:GetAbilityName() == "item_healing_wards2" then
		ward_name = "healing_ward2"
	end

	SummonHealingWardFromAbility(ability, caster, point, ward_name)
end
