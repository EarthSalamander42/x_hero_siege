require('libraries/timers')

function FrostmourneHungers( keys )
local caster = keys.caster
local target = keys.target
local ability = keys.ability
local ability_level = ability:GetLevel() - 1
local modifier_stack = keys.modifier_stack
local max_stacks = caster:GetLevel()

	target:SetModifierStackCount(modifier_stack, ability, max_stacks)
end

function GiveMana( keys )
local caster = keys.caster
local target = keys.target
local ability = keys.ability
local ability_level = ability:GetLevel() - 1
local particle_burn = keys.particle_burn
local sound_burn = keys.sound_burn
local modifier_stack = keys.modifier_stack

-- Parameters
local current_stack = caster:GetModifierStackCount(modifier_stack, ability)
local mana_restore = ability:GetLevelSpecialValueFor("mana_restore", ability_level)

	if current_stack < 1 then
		caster:RemoveModifierByNameAndCaster(modifier_stack, caster)
	else
		caster:SetModifierStackCount(modifier_stack, ability, current_stack - 1)
		caster:EmitSound(sound_burn)
		caster:GiveMana( mana_restore )
		local mana_burn_pfx = ParticleManager:CreateParticle(particle_burn, PATTACH_ABSORIGIN, caster)
		ParticleManager:SetParticleControl(mana_burn_pfx, 0, caster:GetAbsOrigin())
	end
end
