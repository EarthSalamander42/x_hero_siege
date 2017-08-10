function GetReductionFromArmor(armor)
	local m = 0.06 * armor
	return 100 * (1 - m/(1+math.abs(m)))
end

-- Autoattack lifesteal
function CDOTA_BaseNPC:GetLifesteal()
	local lifesteal = 0
	for _, parent_modifier in pairs(self:FindAllModifiers()) do
		if parent_modifier.GetModifierLifesteal then
			lifesteal = lifesteal + parent_modifier:GetModifierLifesteal()
		end
	end
	return lifesteal
end
