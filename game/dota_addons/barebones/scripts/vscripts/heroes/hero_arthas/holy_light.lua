function Purification( keys )
	local caster = keys.caster
	local ability = keys.ability
	local sound_cast = keys.sound_cast
	local particle_blast = keys.particle_blast
	local particle_hit = keys.particle_hit

	-- Parameters
	local radius = ability:GetSpecialValueFor("radius")
	local blast_speed = ability:GetSpecialValueFor("blast_speed")
	local heal = ability:GetSpecialValueFor("heal")
	local damage = ability:GetSpecialValueFor("damage")
	local current_loc = caster:GetAbsOrigin()

	-- Play cast sound
	caster:EmitSound(sound_cast)

	-- Initialize targets hit table
	local targets_hit = {}

	-- Main blasting loop
	local current_radius = 0
	local tick_interval = 0.1
	Timers:CreateTimer(tick_interval, function()
		
		-- Update current radius and location
		current_radius = current_radius + blast_speed * tick_interval
		current_loc = caster:GetAbsOrigin()

		-- Iterate through allies in the radius
		local nearby_allies = FindUnitsInRadius(caster:GetTeamNumber(), current_loc, nil, current_radius, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_INVULNERABLE, FIND_ANY_ORDER, false)
		for _,ally in pairs(nearby_allies) do
			
			-- Check if this ally was already hit
			local ally_has_been_hit = false
			for _,ally_hit in pairs(targets_hit) do
				if ally == ally_hit then ally_has_been_hit = true end
			end

			-- If not, blast it
			if not ally_has_been_hit then
				
				-- Play hit particle
				local hit_pfx = ParticleManager:CreateParticle(particle_hit, PATTACH_ABSORIGIN_FOLLOW, ally)
				ParticleManager:SetParticleControl(hit_pfx, 0, ally:GetAbsOrigin())
				ParticleManager:SetParticleControl(hit_pfx, 1, ally:GetAbsOrigin())
				ParticleManager:ReleaseParticleIndex(hit_pfx)

				-- Deal damage
				ally:Heal(heal, ally)
				SendOverheadEventMessage(nil, OVERHEAD_ALERT_HEAL, ally, heal, nil)

				-- Add ally to the targets hit table
				targets_hit[#targets_hit + 1] = ally
			end
		end

		-- Iterate through enemies in the radius
		local nearby_enemies = FindUnitsInRadius(caster:GetTeamNumber(), current_loc, nil, current_radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
		for _,enemy in pairs(nearby_enemies) do
			
			-- Check if this enemy was already hit
			local enemy_has_been_hit = false
			for _,enemy_hit in pairs(targets_hit) do
				if enemy == enemy_hit then enemy_has_been_hit = true end
			end

			-- If not, blast it
			if not enemy_has_been_hit then
				
				-- Play hit particle
				local hit_pfx = ParticleManager:CreateParticle(particle_hit, PATTACH_ABSORIGIN_FOLLOW, enemy)
				ParticleManager:SetParticleControl(hit_pfx, 0, enemy:GetAbsOrigin())
				ParticleManager:SetParticleControl(hit_pfx, 1, enemy:GetAbsOrigin())
				ParticleManager:ReleaseParticleIndex(hit_pfx)

				-- Deal damage
				ApplyDamage({attacker = caster, victim = enemy, ability = ability, damage = damage, damage_type = DAMAGE_TYPE_MAGICAL})

				-- Add enemy to the targets hit table
				targets_hit[#targets_hit + 1] = enemy
			end
		end

		-- If the current radius is smaller than the maximum radius, keep going
		if current_radius < radius then
			return tick_interval
		else
		end
	end)
end
