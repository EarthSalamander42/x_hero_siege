function DragonSlave( keys )
	local caster = keys.caster
	local ability = keys.ability
	local ability_aux = caster:FindAbilityByName(keys.ability_aux)
	local ability_level = ability:GetLevel() - 1
	local particle_projectile = keys.particle_projectile
	local sound_cast = keys.sound_cast

	-- Parameters
	local speed = ability:GetLevelSpecialValueFor("speed", ability_level)
	local start_width = ability:GetLevelSpecialValueFor("start_width", ability_level)
	local end_width = ability:GetLevelSpecialValueFor("end_width", ability_level)
	local distance = ability:GetLevelSpecialValueFor("distance", ability_level)
	local target_loc = keys.target_points[1]
	local caster_loc = caster:GetAbsOrigin()

	-- Play cast sound
	caster:EmitSound(sound_cast)

	-- Launch primary projectile
	local direction_center = caster:GetForwardVector()
	local projectile = {
		Ability				= ability,
		EffectName			= particle_projectile,
		vSpawnOrigin		= caster_loc,
		fDistance			= distance,
		fStartRadius		= start_width,
		fEndRadius			= end_width,
		Source				= caster,
		bHasFrontalCone		= true,
		bReplaceExisting	= false,
		iUnitTargetTeam		= DOTA_UNIT_TARGET_TEAM_ENEMY,
		iUnitTargetFlags	= DOTA_UNIT_TARGET_FLAG_NONE,
		iUnitTargetType		= DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		bDeleteOnHit		= false,
		vVelocity			= direction_center * speed,
		bProvidesVision		= false,
	}
	ProjectileManager:CreateLinearProjectile(projectile)
end