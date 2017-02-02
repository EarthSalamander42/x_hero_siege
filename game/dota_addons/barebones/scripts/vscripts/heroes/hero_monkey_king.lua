function JinguMasteryInitialize( keys )
local caster = keys.caster
local ability = keys.ability
local ability_level = ability:GetLevel() - 1
local max_stacks = ability:GetLevelSpecialValueFor("charges", ability_level)
local modifier_stack = keys.modifier_stack

	caster:SetModifierStackCount(modifier_stack, ability, max_stacks)
end

function JinguMastery( keys )
local caster = keys.caster
local ability = keys.ability
local ability_level = ability:GetLevel() - 1
local modifier_stack = keys.modifier_stack
local stacks = caster:GetModifierStackCount(modifier_stack, ability)

	if stacks < 1 then
		caster:RemoveModifierByName(modifier_stack)
	end
	caster:SetModifierStackCount(modifier_stack, ability, stacks -1)
end
