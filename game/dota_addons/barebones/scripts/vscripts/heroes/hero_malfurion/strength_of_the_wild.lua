function StrengthOfTheWild( keys )
local caster = keys.caster
local target = keys.target
local ability = keys.ability
local ability_level = ability:GetLevel() - 1
local hero_damage = caster:GetAttackDamage() * 2
local creep_damage = caster:GetAttackDamage() * 3

	if target:IsConsideredHero() then
		ApplyDamage({ victim = target, attacker = caster, damage = hero_damage,	damage_type = DAMAGE_TYPE_PHYSICAL })
	elseif target:IsCreep() then
		ApplyDamage({ victim = target, attacker = caster, damage = creep_damage, damage_type = DAMAGE_TYPE_PHYSICAL })
	end
end