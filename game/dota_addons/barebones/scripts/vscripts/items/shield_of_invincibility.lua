function Return(event)
local caster = event.caster
local attacker = event.attacker
local ability = event.ability
local damageType = DAMAGE_TYPE_PHYSICAL
local return_damage = ability:GetSpecialValueFor("damage_return_pct")
local attacker_damage = attacker:GetBaseDamageMin()
local divided_damage = attacker_damage / 100
local total_damage = divided_damage * return_damage

	if attacker:GetTeamNumber() ~= caster:GetTeamNumber() and not attacker:IsBuilding() then
		ApplyDamage({victim = attacker, attacker = caster, damage = total_damage, damage_type = damageType})
	end
end
