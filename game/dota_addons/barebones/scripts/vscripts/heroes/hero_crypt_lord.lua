require("libraries/timers")

function BurrowImpale(keys)
local caster = keys.caster
local target = keys.target

	local impale = ParticleManager:CreateParticle("particles/units/heroes/hero_nyx_assassin/nyx_assassin_impale.vpcf", PATTACH_CUSTOMORIGIN, nil)
	ParticleManager:SetParticleControl(impale, 0, target:GetAbsOrigin())

	Timers:CreateTimer(0.49, function()
		ParticleManager:DestroyParticle(impale, true)
	end)
end

function BurrowImpaleAnimation(keys)
local caster = keys.caster

	StartAnimation(caster, {duration = 0.49, activity = ACT_DOTA_CAST_ABILITY_1, rate = 1.25})
end

function BurrowImpaleChannelEnd(keys)
local caster = keys.caster
	EndAnimation(caster)
end

function Return( event )
local caster = event.caster
local attacker = event.attacker
local ability = event.ability
local damageType = ability:GetAbilityDamageType()
local hero_damage = ability:GetLevelSpecialValueFor( "hero_return_percent" , ability:GetLevel() - 1  )
local creep_damage = ability:GetLevelSpecialValueFor( "creep_return_percent" , ability:GetLevel() - 1  )
local attacker_damage = attacker:GetBaseDamageMin()
local divided_damage = attacker_damage / 100

	if attacker:GetTeamNumber() ~= caster:GetTeamNumber() and attacker:IsHero() then
		ApplyDamage({ victim = attacker, attacker = caster, damage = divided_damage * hero_damage, damage_type = damageType })
	elseif attacker:GetTeamNumber() ~= caster:GetTeamNumber() and attacker:IsCreep() then
		ApplyDamage({ victim = attacker, attacker = caster, damage = divided_damage * creep_damage, damage_type = damageType })
	end
end
