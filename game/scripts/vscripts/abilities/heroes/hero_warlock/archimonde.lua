--[[Author: Pizzalol
	Date: 10.01.2015.
	It transforms the caster into a different dragon depending on the ability level]]
function Transform( keys )
	local caster = keys.caster
	local ability = keys.ability
	local level = ability:GetLevel()
	local modifier_one = keys.modifier_one
	local modifier_two = keys.modifier_two

	-- Deciding the transformation level
	local modifier
	if level == 1 then modifier = modifier_one
	else modifier = modifier_two

	end

	ability:ApplyDataDrivenModifier(caster, caster, modifier, {})
end

--[[Author: Pizzalol/Noya
	Date: 12.01.2015.
	Swaps the auto attack projectile and the caster model]]
function ModelSwapStart( keys )
	local caster = keys.caster
	local model = keys.model
	local projectile_model = keys.projectile_model
	local ability = keys.ability
	local vision_fow = ability:GetLevelSpecialValueFor("vision_fow", (ability:GetLevel() - 1))
	local vision_fow_duration = ability:GetLevelSpecialValueFor("duration", (ability:GetLevel() - 1))
	local caster_location = caster:GetAbsOrigin()

	-- Saves the original model and attack capability
	if caster.caster_model == nil then
		caster.caster_model = caster:GetModelName()
	end
	caster.caster_attack = caster:GetAttackCapability()

	-- Sets the new model and projectile
	caster:SetOriginalModel(model)
	caster:SetRangedProjectileName(projectile_model)

	-- Sets the new attack type
	caster:SetAttackCapability(DOTA_UNIT_CAP_RANGED_ATTACK)
end

--[[Author: Pizzalol/Noya
	Date: 12.01.2015.
	Reverts back to the original model and attack type]]
function ModelSwapEnd( keys )
	local caster = keys.caster

	caster:SetModel(caster.caster_model)
	caster:SetOriginalModel(caster.caster_model)
	caster:SetAttackCapability(caster.caster_attack)
end
