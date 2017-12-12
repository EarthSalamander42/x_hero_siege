require("libraries/timers")

function HowlingBlast( keys )
local caster = keys.caster
local attacker = keys.attacker
local attacker_position = keys.attacker:GetAbsOrigin()
local ability = keys.ability
local damage = ability:GetLevelSpecialValueFor("ensnare_damage", ability:GetLevel() - 1)
local duration = ability:GetLevelSpecialValueFor("ensnare_duration", ability:GetLevel() - 1)
local cooldown = 1.0
local Modifier = keys.modifier

	if not attacker:IsBuilding() and ability:IsActivated() then
		local particle1 = ParticleManager:CreateParticle("particles/units/heroes/heroes_underlord/abyssal_underlord_pitofmalice_stun.vpcf", PATTACH_ABSORIGIN_FOLLOW, attacker)
		ParticleManager:SetParticleControl( particle1, 0, attacker_position )
		Timers:CreateTimer( duration ,function()
			ParticleManager:DestroyParticle(particle1, true)
		end)

		attacker:EmitSound("Hero_AbyssalUnderlord.Pit.TargetHero")
		ability:ApplyDataDrivenModifier(caster, attacker, "modifier_rooted", {duration = duration})
		ability:ApplyDataDrivenModifier(caster, attacker, Modifier, {duration = duration})
		caster:RemoveModifierByName('modifier_howling_blast')
		ability:StartCooldown(cooldown)
		ApplyDamage({victim = attacker, attacker = caster, damage = damage, ability = ability, damage_type = ability:GetAbilityDamageType()})
		Timers:CreateTimer(cooldown, function()
			ability:ApplyDataDrivenModifier(caster, caster, "modifier_howling_blast", {})
		end)
	end
end
