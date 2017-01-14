function JinguMastery( keys )
	local caster = keys.caster
	local caster_pos = keys.caster:GetAbsOrigin()
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1
	local max_stacks = ability:GetLevelSpecialValueFor("required_hits", ability_level)
	local modifier_stack = keys.modifier_stack

	local stacks = caster:GetModifierStackCount(modifier_stack, ability)
	if not caster:HasModifier("modifier_jingu_mastery_passive") then
		local quad_particle = ParticleManager:CreateParticle( "particles/units/heroes/hero_monkey_king/monkey_king_quad_tap_stack.vpcf", PATTACH_ABSORIGIN, caster )
		ParticleManager:SetParticleControl(quad_particle, 1, Vector(0, 1, 0))
		caster:AddNewModifier( caster, ability, modifier_stack, {})
		caster:SetModifierStackCount(modifier_stack, ability, 1)
		print("Jingu Mastery Hits: "..stacks)
	elseif stacks >= 1 and stacks < 4 then
--		ParticleManager:SetParticleControl(quad_particle, 1, Vector(0, stacks + 1, 0))
		caster:SetModifierStackCount(modifier_stack, ability, stacks + 1)
		print("Jingu Mastery Hits: "..stacks)
	elseif stacks == 4 then
		caster:RemoveModifierByName(modifier_stack)
		caster:AddNewModifier(caster, ability, "modifier_jingu_mastery_active", {})
		caster:SetModifierStackCount("modifier_jingu_mastery_active", ability, 4)
	end
end
