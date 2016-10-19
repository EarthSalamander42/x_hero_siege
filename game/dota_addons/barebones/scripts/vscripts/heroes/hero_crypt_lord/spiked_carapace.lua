--[[
	Author: Noya
	Date: 9.1.2015.
	Does base damage plus a percent of the hero strength
]]
function Return( event )
	-- Variables
	local caster = event.caster
	local attacker = event.attacker
	local ability = event.ability
	local damageType = ability:GetAbilityDamageType()
	local divided_damage = ability:GetLevelSpecialValueFor( "divided_damage" , ability:GetLevel() - 1  )
	local attacker_damage = attacker:GetBaseDamageMin()

	-- Damage
	if attacker:GetTeamNumber() ~= caster:GetTeamNumber() then
		ApplyDamage({ victim = attacker, attacker = caster, damage = attacker_damage, damage_type = damageType })
		print("done "..attacker_damage/divided_damage)
	end
end
