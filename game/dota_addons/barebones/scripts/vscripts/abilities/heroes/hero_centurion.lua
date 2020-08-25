function Purge(keys)
local caster = keys.caster
local index = ParticleManager:CreateParticle("particles/units/heroes/hero_slark/slark_dark_pact_start.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)

	ParticleManager:SetParticleControlEnt(index, 1, caster, PATTACH_ABSORIGIN_FOLLOW, nil, caster:GetAbsOrigin(), true)
	ParticleManager:ReleaseParticleIndex(index)

	Timers:CreateTimer(1.5, function()
	local index = ParticleManager:CreateParticle("particles/units/heroes/hero_slark/slark_dark_pact_pulses.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
		ParticleManager:SetParticleControlEnt(index, 1, caster, PATTACH_ABSORIGIN_FOLLOW, nil, caster:GetAbsOrigin(), true)
		ParticleManager:SetParticleControl(index, 2, Vector(300, 0, 0))
		caster:Purge( true, true, false, true, false)
	end)
end

function Transform( keys )
	local caster = keys.caster
	local ability = keys.ability
	local level = ability:GetLevel()
	local modifier_one = keys.modifier_one
	local modifier_two = keys.modifier_two
	local modifier_three = keys.modifier_three

	local modifier
	if level == 1 then
		modifier = modifier_one
	elseif level == 2 then
		modifier = modifier_two
	else
		modifier = modifier_three
	end

	ability:ApplyDataDrivenModifier(caster, caster, modifier, {})
end

function ModelSwapStart( keys )
	local caster = keys.caster
	local model = keys.model
	local projectile_model = keys.projectile_model
	local ability = keys.ability
	local vision_fow = ability:GetLevelSpecialValueFor("vision_fow", (ability:GetLevel() - 1))
	local vision_fow_duration = ability:GetLevelSpecialValueFor("duration", (ability:GetLevel() - 1))
	local caster_location = caster:GetAbsOrigin()

	if caster.caster_model == nil then
		caster.caster_model = caster:GetModelName()
	end
	caster.caster_attack = caster:GetAttackCapability()

	caster:SetOriginalModel(model)
	caster:SetRangedProjectileName(projectile_model)

	caster:SetAttackCapability(DOTA_UNIT_CAP_RANGED_ATTACK)
end

function ModelSwapEnd( keys )
local caster = keys.caster

	caster:SetModel(caster.caster_model)
	caster:SetOriginalModel(caster.caster_model)
	caster:SetAttackCapability(caster.caster_attack)
end

function DarkDimension(keys)
local caster = keys.caster
local ability = keys.ability
local radius = ability:GetLevelSpecialValueFor("radius", (ability:GetLevel() - 1))
local damage_pct = ability:GetLevelSpecialValueFor("self_damage_percent", (ability:GetLevel() - 1))
local damage = caster:GetMaxHealth() / 4

	ApplyDamage({victim = caster, attacker = caster, damage = damage, damage_type = DAMAGE_TYPE_MAGICAL, ability = ability})

	local eclipse = ParticleManager:CreateParticle("particles/units/heroes/hero_obsidian_destroyer/obsidian_destroyer_sanity_eclipse_area.vpcf", PATTACH_ABSORIGIN, caster)
	ParticleManager:SetParticleControl(eclipse, 0, caster:GetAbsOrigin())
	ParticleManager:SetParticleControl(eclipse, 1, Vector(radius, 0, 0))
	ParticleManager:SetParticleControl(eclipse, 2, Vector(radius, 0, 0))
	ParticleManager:SetParticleControl(eclipse, 3, Vector(radius, 0, 0))
	ParticleManager:ReleaseParticleIndex(eclipse)
end
