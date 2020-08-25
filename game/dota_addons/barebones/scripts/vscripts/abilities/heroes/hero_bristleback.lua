function bristleback_takedamage(params)
	-- Create the threshold counter on the unit if it doesn't exist.
	if params.unit.quill_threshold_counter == nil then
		params.unit.quill_threshold_counter = 0.0
	end

	local ability = params.ability
	local back_reduction_percentage = ability:GetLevelSpecialValueFor("back_damage_reduction", ability:GetLevel() - 1) / 100
	local side_reduction_percentage = ability:GetLevelSpecialValueFor("side_damage_reduction", ability:GetLevel() - 1) / 100

	-- The y value of the angles vector contains the angle we actually want: where units are directionally facing in the world.
	local victim_angle = params.unit:GetAnglesAsVector().y
	local origin_difference = params.unit:GetAbsOrigin() - params.attacker:GetAbsOrigin()
	-- Get the radian of the origin difference between the attacker and Bristleback. We use this to figure out at what angle the attacker is at relative to Bristleback.
	local origin_difference_radian = math.atan2(origin_difference.y, origin_difference.x)
	-- Convert the radian to degrees.
	origin_difference_radian = origin_difference_radian * 180
	local attacker_angle = origin_difference_radian / math.pi
	-- See the opening block comment for why I do this. Basically it's to turn negative angles into positive ones and make the math simpler.
	attacker_angle = attacker_angle + 180.0
	-- Finally, get the angle at which Bristleback is facing the attacker.
	local result_angle = attacker_angle - victim_angle
	result_angle = math.abs(result_angle)

	-- Check for the side angle first. If the attack doesn't pass this check, we don't have to do back angle calculations.
	if result_angle >= (180 - (ability:GetSpecialValueFor("side_angle") / 2)) and result_angle <= (180 + (ability:GetSpecialValueFor("side_angle") / 2)) then 
		-- Check for back angle. If this check doesn't pass, then do side angle "damage reduction".
		if result_angle >= (180 - (ability:GetSpecialValueFor("back_angle") / 2)) and result_angle <= (180 + (ability:GetSpecialValueFor("back_angle") / 2)) then 
			-- Check if the reduced damage is lethal
			if((params.unit:GetHealth() - (params.Damage * (1 - back_reduction_percentage))) >= 1) then
				-- This is the actual "damage reduction".
				params.unit:SetHealth((params.Damage * back_reduction_percentage) + params.unit:GetHealth())
				-- Play the sound on Bristleback.
				EmitSoundOn(params.sound, params.unit)
				-- Create the back particle effect.
				local back_damage_particle = ParticleManager:CreateParticle(params.back_particle, PATTACH_ABSORIGIN_FOLLOW, params.unit) 
				-- Set Control Point 1 for the back damage particle; this controls where it's positioned in the world. In this case, it should be positioned on Bristleback.
				ParticleManager:SetParticleControlEnt(back_damage_particle, 1, params.unit, PATTACH_POINT_FOLLOW, "attach_hitloc", params.unit:GetAbsOrigin(), true) 
				-- Increase the Quill Spray damage counter based on how much damage was done *post-Bristleback mitigation*.
				params.unit.quill_threshold_counter = params.unit.quill_threshold_counter + (params.Damage - (params.Damage * back_reduction_percentage))
			end
		else
			-- Check if the reduced damage is lethal
			if((params.unit:GetHealth() - (params.Damage * (1 - side_reduction_percentage))) >= 1) then
				-- This is the actual "damage reduction".
				params.unit:SetHealth((params.Damage * side_reduction_percentage) + params.unit:GetHealth())
				-- Play the sound on Bristleback.
				EmitSoundOn(params.sound, params.unit)
				-- Create the side particle effect.
				local side_damage_particle = ParticleManager:CreateParticle(params.side_particle, PATTACH_ABSORIGIN_FOLLOW, params.unit) 
				-- Set Control Point 1 for the side damage particle; same stuff as the back damage particle.
				ParticleManager:SetParticleControlEnt(side_damage_particle, 1, params.unit, PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", params.unit:GetAbsOrigin(), true) 
				ParticleManager:SetParticleControlEnt(side_damage_particle, 2, params.unit, PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", Vector(0, result_angle, 0), true)
				-- Increase the Quill Spray damage counter based on how much damage was done *post-Bristleback mitigation*.
				params.unit.quill_threshold_counter = params.unit.quill_threshold_counter + (params.Damage - (params.Damage * side_reduction_percentage))
			end
		end
	end

	-- If the amount of damage taken since the last Quill Spray proc is equal to or exceeds what's defined as the threshold, release a Quill Spray.
	if params.unit.quill_threshold_counter >= ability:GetSpecialValueFor("quill_release_threshold") then
		-- This should be Quill Spray, but in case something weird like AD is going on, we'll check anyway.
		local ability_index_1 = params.unit:GetAbilityByIndex(1) 

		-- Just in case GetAbilityByIndex fails or something.
		if ability_index_1 ~= nil then 
			if ability_index_1:GetAbilityName() == "quill_spray_datadriven" or ability_index_1:GetAbilityName() == "bristleback_quill_spray" then
				ability_index_1:CastAbility()
			end
		end

		-- I'm not entirely sure if this is how Bristleback actually works, but this seems like a safe bet.
		params.unit.quill_threshold_counter = params.unit.quill_threshold_counter - 250.0 
	end
end

--[[	Author: Firetoad
		Date: 04.08.2015	]]

function StormBoltLaunch( keys )
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1
	local modifier_caster = keys.modifier_caster
	local modifier_god_str = keys.modifier_god_str
	local particle_bolt = keys.particle_bolt
	local particle_ult = keys.particle_ult
	local sound_cast = keys.sound_cast

	-- Parameters
	local speed = ability:GetLevelSpecialValueFor("speed", ability_level)
	local vision_radius = ability:GetLevelSpecialValueFor("vision_radius", ability_level)

	-- Play sound
	caster:EmitSound(sound_cast)

	-- Randomly play a cast line
	if RandomInt(1, 100) <= 50 then
		caster:EmitSound("sven_sven_ability_stormbolt_0"..RandomInt(1,9))
	end

	-- Remove caster from the world
	ability:ApplyDataDrivenModifier(caster, caster, modifier_caster, {})
	caster:AddNoDraw()

	-- Create tracking projectile
	local bolt_projectile = {
		Target = target,
		Source = caster,
		Ability = ability,
		EffectName = particle_bolt,
		bDodgeable = true,
		bProvidesVision = true,
		iMoveSpeed = speed,
		iVisionRadius = vision_radius,
		iVisionTeamNumber = caster:GetTeamNumber(),
		iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_ATTACK_1
	}

	-- Change projectile if God's strength is active
	if caster:HasModifier(modifier_god_str) then
		bolt_projectile = {
			Target = target,
			Source = caster,
			Ability = ability,
			EffectName = particle_ult,
			bDodgeable = true,
			bProvidesVision = true,
			iMoveSpeed = speed,
			iVisionRadius = vision_radius,
			iVisionTeamNumber = caster:GetTeamNumber(),
			iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_ATTACK_1
		}
	end

	ProjectileManager:CreateTrackingProjectile(bolt_projectile)
end

function StormBoltEnd( keys )
	local caster = keys.caster
	local modifier_caster = keys.modifier_caster

	-- Return caster to the world
	caster:RemoveModifierByName(modifier_caster)
	caster:RemoveNoDraw()
end

function StormBoltHit( keys )
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1
	local modifier_caster = keys.modifier_caster
	local modifier_god_str = keys.modifier_god_str
	local ability_god_str = caster:FindAbilityByName(keys.ability_god_str)
	local sound_impact = keys.sound_impact
	local particle_impact = keys.particle_impact

	-- Parameters
	local damage = ability:GetLevelSpecialValueFor("damage", ability_level)
	local radius = ability:GetLevelSpecialValueFor("radius", ability_level)
	local duration = ability:GetLevelSpecialValueFor("duration", ability_level)
	
	-- If God's strength is active, update damage
	if ability_god_str and caster:HasModifier(modifier_god_str) then
		local bonus_damage = ability_god_str:GetLevelSpecialValueFor("storm_bolt_damage", ability_god_str:GetLevel() - 1)
		local bonus_radius = ability_god_str:GetLevelSpecialValueFor("storm_bolt_radius", ability_god_str:GetLevel() - 1)
		damage = damage + bonus_damage
		radius = radius + bonus_radius
	end

	-- Play sound
	target:EmitSound(sound_impact)

	-- Return caster to the world
	caster:RemoveModifierByName(modifier_caster)
	caster:RemoveNoDraw()

	-- Teleport the caster to the target
	local target_pos = target:GetAbsOrigin()
	local caster_pos = caster:GetAbsOrigin()
	local blink_pos = target_pos + ( caster_pos - target_pos ):Normalized() * 100
	FindClearSpaceForUnit(caster, blink_pos, true)

	-- Randomly play a cast line
	if ( target_pos - caster_pos ):Length2D() > 600 and RandomInt(1, 100) <= 20 then
		caster:EmitSound("sven_sven_ability_teleport_0"..RandomInt(1,3))
	end
	
	-- Start attacking the target
	caster:SetAttacking(target)

	-- If the target possesses a ready Linken's Sphere, do nothing
	if target:GetTeam() ~= caster:GetTeam() then
		if target:TriggerSpellAbsorb(ability) then
			return nil
		end
	end
	
	-- Find enemies in effect area
	local enemies = FindUnitsInRadius(caster:GetTeamNumber(), target:GetAbsOrigin(), nil, radius, ability:GetAbilityTargetTeam(), ability:GetAbilityTargetType(), 0, FIND_ANY_ORDER, false)
	for _,enemy in pairs(enemies) do
		
		-- Fire impact particle
		local enemy_loc = enemy:GetAbsOrigin()
		local impact_pfx = ParticleManager:CreateParticle(particle_impact, PATTACH_ABSORIGIN, enemy)
		ParticleManager:SetParticleControl(impact_pfx, 0, enemy_loc)
		ParticleManager:SetParticleControlEnt(impact_pfx, 3, enemy, PATTACH_ABSORIGIN, "attach_origin", enemy_loc, true)

		-- Stun
		enemy:AddNewModifier(caster, ability, "modifier_stunned", {duration = duration})

		-- Apply damage
		ApplyDamage({attacker = caster, victim = enemy, ability = ability, damage = damage, damage_type = ability:GetAbilityDamageType()})
	end
end