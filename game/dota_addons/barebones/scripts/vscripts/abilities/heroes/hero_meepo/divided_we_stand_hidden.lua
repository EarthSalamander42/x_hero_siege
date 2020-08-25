function OnTakeDamageCount(keys)
print("Divided We Stand: Damage Taken")
local caster = keys.caster
local ability = keys.ability
local damage_taken = keys.damage_taken
local Meepo = Entities:FindByModel( nil, "models/heroes/meepo/meepo.vmdl" )
--local units = FindUnitsInRadius( DOTA_TEAM_GOODGUYS, Vector(0, 0, 0), nil, FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_FLAG_NONE , FIND_ANY_ORDER, false )

--	for _,v in pairs(units) do
--		if v:HasModifier("modifier_divided_we_stand_hidden") then
			print("Divided We Stand: Damage Applied")
			ApplyDamage({attacker = caster, victim = Meepo, ability = ability, damage = damage_taken, damage_type = ability:GetAbilityDamageType()})
--		end
--	end
end
