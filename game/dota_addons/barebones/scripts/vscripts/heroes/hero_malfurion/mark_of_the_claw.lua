--[[
	Author: Noya
	Date: 14.01.2015.
	Applies a Lifesteal modifier if the attacked target is not a building and not a mechanical unit
]]
function CleaveApply( event )
	-- Variables
	local attacker = event.attacker
	local target = event.target
	local ability = event.ability

	if target.GetInvulnCount == nil then
		ability:ApplyDataDrivenModifier(attacker, attacker, "modifier_great_cleave_datadriven", {duration = 0.03})
	end
end

function Splash(event)
	local attacker = event.caster
	local target = event.target
	local ability = event.ability
	local radius = ability:GetSpecialValueFor("radius")
	local full_damage = attacker:GetAttackDamage()

	local splash_targets = FindUnitsInRadius(attacker:GetTeamNumber(), target:GetAbsOrigin(), nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, FIND_ANY_ORDER, false)
	for _,unit in pairs(splash_targets) do
		if unit ~= target and not unit:IsBuilding() then
			ApplyDamage({victim = unit, attacker = attacker, damage = full_damage/5, ability = ability, damage_type = DAMAGE_TYPE_PHYSICAL})
		end
	end
end

-- New Splash Function
--	function Splash(event)
--		local attacker = event.caster
--		local target = event.target
--		local ability = event.ability
--		local radius = ability:GetSpecialValueFor("radius")
--		local full_damage = attacker:GetAttackDamage()
--		local damage_pct = ability:GetSpecialValueFor("damage_pct")
--		local divided_damage = full_damage / 100 * damage_pct
--	
--		local splash_targets = FindUnitsInRadius(attacker:GetTeamNumber(), target:GetAbsOrigin(), nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, FIND_ANY_ORDER, false)
--		for _,unit in pairs(splash_targets) do
--			if unit ~= target and not unit:IsBuilding() then
--				ApplyDamage({victim = unit, attacker = attacker, damage = full_damage/5, ability = ability, damage_type = DAMAGE_TYPE_PHYSICAL})
--			end
--		end
--	end