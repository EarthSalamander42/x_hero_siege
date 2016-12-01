function FrostMourne( keys )
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1
	local max_stacks = ability:GetLevelSpecialValueFor("max_stacks", ability_level)
	local modifier_buff_base = "modifier_imba_frostmourne_buff_base"
	local modifier_buff = "modifier_imba_frostmourne_buff"


	if caster:HasModifier(modifier_buff_base) then
		local stack_count = caster:GetModifierStackCount(modifier_buff, ability)

		if stack_count < max_stacks then
			ability:ApplyDataDrivenModifier(caster, caster, modifier_buff_base, {})
			ability:ApplyDataDrivenModifier(caster, caster, modifier_buff, {})
			caster:SetModifierStackCount(modifier_buff, ability, stack_count + 1)
		else
			ability:ApplyDataDrivenModifier(caster, caster, modifier_buff_base, {})
			ability:ApplyDataDrivenModifier(caster, caster, modifier_buff, {})
		end
	else
		ability:ApplyDataDrivenModifier(caster, caster, modifier_buff_base, {})
		ability:ApplyDataDrivenModifier(caster, caster, modifier_buff, {})
		caster:SetModifierStackCount(modifier_buff, ability, 1)
	end
end