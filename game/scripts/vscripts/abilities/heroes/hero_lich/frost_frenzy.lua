function FrostFrenzy( event )
local caster = event.caster
local target = event.target
local health_per_second = 10

	ApplyDamage({ victim = target, attacker = caster, damage = 10, damage_type = DAMAGE_TYPE_MAGICAL })
end
