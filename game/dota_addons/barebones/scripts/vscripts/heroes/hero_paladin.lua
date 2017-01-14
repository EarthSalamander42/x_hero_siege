--[[Author: Pizzalol
	Date: 09.02.2015.
	Chains from target to target, healing them and dealing damage to enemies in a small
	radius around them

	Jump priority is
	1. Hurt heroes
	2. Hurt units
	3. Heroes
	4. Units]]
function ShadowWave( keys )
	local caster = keys.caster
	local caster_location = caster:GetAbsOrigin()
	local target = keys.target
	local target_location = target:GetAbsOrigin()
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1

	-- Ability variables
	local bounce_radius = ability:GetLevelSpecialValueFor("bounce_radius", ability_level)
	local damage_radius = ability:GetLevelSpecialValueFor("damage_radius", ability_level)
	local max_targets = ability:GetLevelSpecialValueFor("max_targets", ability_level)
	local damage = ability:GetLevelSpecialValueFor("damage", ability_level)
	local heal = damage
	local unit_healed = false

	-- Particles
	local shadow_wave_particle = keys.shadow_wave_particle
	local shadow_wave_damage_particle = keys.damage_particle

	-- Setting up the damage and hit tables
	local hit_table = {}
	local damage_table = {}
	damage_table.attacker = caster
	damage_table.damage_type = ability:GetAbilityDamageType()
	damage_table.ability = ability
	damage_table.damage = damage

	-- If the target is not the caster then do the extra bounce for the caster
	if target ~= caster then
		-- Insert the caster into the hit table
		table.insert(hit_table, caster)
		-- Heal the caster and do damage to the units around it
		caster:Heal(heal, caster)

		local units_to_damage = FindUnitsInRadius(caster:GetTeam(), caster_location, nil, damage_radius, DOTA_UNIT_TARGET_TEAM_ENEMY, ability:GetAbilityTargetType(), 0, 0, false)

		for _,v in pairs(units_to_damage) do
			-- Play the particle
			local damage_particle = ParticleManager:CreateParticle(shadow_wave_damage_particle, PATTACH_CUSTOMORIGIN, caster)
			ParticleManager:SetParticleControlEnt(damage_particle, 0, v, PATTACH_POINT_FOLLOW, "attach_hitloc", v:GetAbsOrigin(), true)
			ParticleManager:ReleaseParticleIndex(damage_particle)
			damage_table.victim = v
			ApplyDamage(damage_table)
		end
	end

	-- Mark the target as already hit
	table.insert(hit_table, target)
	-- Heal the initial target and do the damage to the units around it
	target:Heal(heal, caster)
	local units_to_damage = FindUnitsInRadius(caster:GetTeam(), target_location, nil, damage_radius, DOTA_UNIT_TARGET_TEAM_ENEMY, ability:GetAbilityTargetType(), 0, 0, false)

	for _,v in pairs(units_to_damage) do
		-- Play the particle
		local damage_particle = ParticleManager:CreateParticle(shadow_wave_damage_particle, PATTACH_CUSTOMORIGIN, caster)
		ParticleManager:SetParticleControlEnt(damage_particle, 0, v, PATTACH_POINT_FOLLOW, "attach_hitloc", v:GetAbsOrigin(), true)
		ParticleManager:ReleaseParticleIndex(damage_particle)

		damage_table.victim = v
		ApplyDamage(damage_table)
	end
	
	
	-- Priority is Hurt Heroes > Hurt Units > Heroes > Units
	-- we start from 2 first because we healed 1 target already
	for i = 2, max_targets do
		-- Helper variable to keep track if we healed a unit already
		unit_healed = false

		-- Find all the heroes in bounce radius
		local heroes = FindUnitsInRadius(caster:GetTeam(), target_location, nil, bounce_radius, ability:GetAbilityTargetTeam(), DOTA_UNIT_TARGET_HERO, 0, FIND_CLOSEST, false)
		
		-- HURT HEROES --
		-- First we check for hurt heroes
		for _,unit in pairs(heroes) do
			local check_unit = 0    -- Helper variable to determine if a unit has been hit or not

			-- Checking the hit table to see if the unit is hit
			for c = 0, #hit_table do
				if hit_table[c] == unit then
					check_unit = 1
				end
			end

			-- If its not hit then check if the unit is hurt
			if check_unit == 0 then
				if unit:GetHealth() ~= unit:GetMaxHealth() then
					-- After we find the hurt hero unit then we insert it into the hit table to keep track of it
					-- and we also get the unit position
					table.insert(hit_table, unit)
					local unit_location = unit:GetAbsOrigin()

					-- Create the particle for the visual effect
					local particle = ParticleManager:CreateParticle(shadow_wave_particle, PATTACH_CUSTOMORIGIN, caster)
					ParticleManager:SetParticleControlEnt(particle, 0, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target_location, true)
					ParticleManager:SetParticleControlEnt(particle, 1, unit, PATTACH_POINT_FOLLOW, "attach_hitloc", unit_location, true)

					-- Set the unit as the new target
					target = unit
					target_location = unit_location

					-- Heal it and deal damage to enemy units around it
					target:Heal(heal, caster)
					local units_to_damage = FindUnitsInRadius(caster:GetTeam(), target_location, nil, damage_radius, DOTA_UNIT_TARGET_TEAM_ENEMY, ability:GetAbilityTargetType(), 0, 0, false)

					for _,v in pairs(units_to_damage) do
						-- Play the particle
						local damage_particle = ParticleManager:CreateParticle(shadow_wave_damage_particle, PATTACH_CUSTOMORIGIN, caster)
						ParticleManager:SetParticleControlEnt(damage_particle, 0, v, PATTACH_POINT_FOLLOW, "attach_hitloc", v:GetAbsOrigin(), true)
						ParticleManager:ReleaseParticleIndex(damage_particle)

						damage_table.victim = v
						ApplyDamage(damage_table)
					end

					-- Set the helper variable to true
					unit_healed = true

					-- Exit the loop for finding hurt heroes
					break
				end
			end
		end

		-- Find all the units in bounce radius
		local units = FindUnitsInRadius(caster:GetTeam(), target_location, nil, bounce_radius, ability:GetAbilityTargetTeam(), DOTA_UNIT_TARGET_BASIC, 0, FIND_CLOSEST, false)
		
		-- HURT UNITS --
		-- check for hurt units if we havent healed a unit yet
		if not unit_healed then
			for _,unit in pairs(units) do
				local check_unit = 0    -- Helper variable to determine if the unit has been hit or not

				-- Checking the hit table to see if the unit is hit
				for c = 0, #hit_table do
					if hit_table[c] == unit then
						check_unit = 1
					end
				end

				-- If its not hit then check if the unit is hurt
				if check_unit == 0 then
					if unit:GetHealth() ~= unit:GetMaxHealth() then
						-- After we find the hurt hero unit then we insert it into the hit table to keep track of it
						-- and we also get the unit position
						table.insert(hit_table, unit)
						local unit_location = unit:GetAbsOrigin()

						-- Create the particle for the visual effect
						local particle = ParticleManager:CreateParticle(shadow_wave_particle, PATTACH_CUSTOMORIGIN, caster)
						ParticleManager:SetParticleControlEnt(particle, 0, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target_location, true)
						ParticleManager:SetParticleControlEnt(particle, 1, unit, PATTACH_POINT_FOLLOW, "attach_hitloc", unit_location, true)

						-- Set the unit as the new target
						target = unit
						target_location = unit_location

						-- Heal it and deal damage to enemy units around it
						target:Heal(heal, caster)
						local units_to_damage = FindUnitsInRadius(caster:GetTeam(), target_location, nil, damage_radius, DOTA_UNIT_TARGET_TEAM_ENEMY, ability:GetAbilityTargetType(), 0, 0, false)

						for _,v in pairs(units_to_damage) do
							-- Play the particle
							local damage_particle = ParticleManager:CreateParticle(shadow_wave_damage_particle, PATTACH_CUSTOMORIGIN, caster)
							ParticleManager:SetParticleControlEnt(damage_particle, 0, v, PATTACH_POINT_FOLLOW, "attach_hitloc", v:GetAbsOrigin(), true)
							ParticleManager:ReleaseParticleIndex(damage_particle)

							damage_table.victim = v
							ApplyDamage(damage_table)
						end

						-- Set the helper variable to true
						unit_healed = true

						-- Exit the loop for finding hurt heroes
						break
					end
				end
			end
		end

		-- HEROES --
		-- In this loop we search for valid heroes regardless if it is hurt or not
		-- Search only if we havent healed a unit yet
		if not unit_healed then
			for _,unit in pairs(heroes) do
				local check_unit = 0    -- Helper variable to determine if a unit has been hit or not

				-- Checking the hit table to see if the unit is hit
				for c = 0, #hit_table do
					if hit_table[c] == unit then
						check_unit = 1
					end
				end

				-- If its not hit then do the bounce
				if check_unit == 0 then
					-- Insert the found unit into the hit table
					-- and we also get the unit position
					table.insert(hit_table, unit)
					local unit_location = unit:GetAbsOrigin()

					-- Create the particle for the visual effect
					local particle = ParticleManager:CreateParticle(shadow_wave_particle, PATTACH_CUSTOMORIGIN, caster)
					ParticleManager:SetParticleControlEnt(particle, 0, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target_location, true)
					ParticleManager:SetParticleControlEnt(particle, 1, unit, PATTACH_POINT_FOLLOW, "attach_hitloc", unit_location, true)

					-- Set the unit as the new target
					target = unit
					target_location = unit_location

					-- Heal it and deal damage to enemy units around it
					target:Heal(heal, caster)
					local units_to_damage = FindUnitsInRadius(caster:GetTeam(), target_location, nil, damage_radius, DOTA_UNIT_TARGET_TEAM_ENEMY, ability:GetAbilityTargetType(), 0, 0, false)

					for _,v in pairs(units_to_damage) do
						-- Play the particle
						local damage_particle = ParticleManager:CreateParticle(shadow_wave_damage_particle, PATTACH_CUSTOMORIGIN, caster)
						ParticleManager:SetParticleControlEnt(damage_particle, 0, v, PATTACH_POINT_FOLLOW, "attach_hitloc", v:GetAbsOrigin(), true)
						ParticleManager:ReleaseParticleIndex(damage_particle)

						damage_table.victim = v
						ApplyDamage(damage_table)
					end

					-- Set the helper variable to true
					unit_healed = true

					-- Exit the loop
					break               
				end
			end
		end

		-- UNITS --
		-- Search for units regardless if it is hurt or not
		-- Search only if we havent healed a unit yet
		if not unit_healed then
			for _,unit in pairs(units) do
				local check_unit = 0    -- Helper variable to determine if a unit has been hit or not

				-- Checking the hit table to see if the unit is hit
				for c = 0, #hit_table do
					if hit_table[c] == unit then
						check_unit = 1
					end
				end

				-- If its not hit then do the bounce
				if check_unit == 0 then
					-- Insert the found unit into the hit table
					-- and we also get the unit position
					table.insert(hit_table, unit)
					local unit_location = unit:GetAbsOrigin()

					-- Create the particle for the visual effect
					local particle = ParticleManager:CreateParticle(shadow_wave_particle, PATTACH_CUSTOMORIGIN, caster)
					ParticleManager:SetParticleControlEnt(particle, 0, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target_location, true)
					ParticleManager:SetParticleControlEnt(particle, 1, unit, PATTACH_POINT_FOLLOW, "attach_hitloc", unit_location, true)

					-- Set the unit as the new target
					target = unit
					target_location = unit_location

					-- Heal it and deal damage to enemy units around it
					target:Heal(heal, caster)
					local units_to_damage = FindUnitsInRadius(caster:GetTeam(), target_location, nil, damage_radius, DOTA_UNIT_TARGET_TEAM_ENEMY, ability:GetAbilityTargetType(), 0, 0, false)

					for _,v in pairs(units_to_damage) do
						-- Play the particle
						local damage_particle = ParticleManager:CreateParticle(shadow_wave_damage_particle, PATTACH_CUSTOMORIGIN, caster)
						ParticleManager:SetParticleControlEnt(damage_particle, 0, v, PATTACH_POINT_FOLLOW, "attach_hitloc", v:GetAbsOrigin(), true)
						ParticleManager:ReleaseParticleIndex(damage_particle)

						damage_table.victim = v
						ApplyDamage(damage_table)
					end

					-- Set the helper variable to true
					unit_healed = true

					-- Exit the loop for finding hurt heroes
					break               
				end
			end
		end
	end
end

function WaveOfTerrorVision( keys )
	local caster = keys.caster
	local caster_location = caster:GetAbsOrigin()
	local ability = keys.ability
	local target_point = keys.target_points[1]
	local forwardVec = (target_point - caster_location):Normalized()

	-- Projectile variables
	local wave_speed = ability:GetLevelSpecialValueFor("wave_speed", (ability:GetLevel() - 1))
	local wave_width = ability:GetLevelSpecialValueFor("wave_width", (ability:GetLevel() - 1))
	local wave_range = ability:GetLevelSpecialValueFor("wave_range", (ability:GetLevel() - 1))
	local wave_location = caster_location
	local wave_particle = keys.wave_particle

	-- Vision variables
	local vision_aoe = ability:GetLevelSpecialValueFor("vision_aoe", (ability:GetLevel() - 1))
	local vision_duration = ability:GetLevelSpecialValueFor("vision_duration", (ability:GetLevel() - 1))

	-- Creating the projectile
	local projectileTable =
	{
		EffectName = wave_particle,
		Ability = ability,
		vSpawnOrigin = caster_location,
		vVelocity = Vector( forwardVec.x * wave_speed, forwardVec.y * wave_speed, 0 ),
		fDistance = wave_range,
		fStartRadius = wave_width,
		fEndRadius = wave_width,
		Source = caster,
		bHasFrontalCone = false,
		bReplaceExisting = false,
		iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
		iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
		iUnitTargetType = DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO
	}
	-- Saving the projectile ID so that we can destroy it later
	projectile_id = ProjectileManager:CreateLinearProjectile( projectileTable )

	-- Timer to provide vision
	Timers:CreateTimer( function()
		-- Calculating the distance traveled
		wave_location = wave_location + forwardVec * (wave_speed * 1/30)

		-- Reveal the area after the projectile passes through it
		AddFOWViewer(caster:GetTeamNumber(), wave_location, vision_aoe, vision_duration, false)

		local distance = (wave_location - caster_location):Length2D()

		-- Checking if we traveled far enough, if yes then destroy the timer
		if distance >= wave_range then
			return nil
		else
			return 1/30
		end
	end)
end

function Taunt( event )
	local caster = event.caster
	local ability = event.ability
	local radius = ability:GetSpecialValueFor("radius")
	local max_units = ability:GetSpecialValueFor("max_units")

	caster:StartGesture(ACT_TINY_GROWL)
	
	local count = 0
	local targets = FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_CLOSEST, false)
	for _,unit in pairs(targets) do
		if not IsCustomBuilding(unit) and unit:HasAttackCapability() and not IsChanneling(unit) and not unit:HasModifier("modifier_repairing") then
			count = count + 1
			unit:MoveToTargetToAttack(caster)
		end
		if count == max_units then return end
	end
end

function LightFrenzy(keys)
	--Refresh all abilities on the target.
	for i = 0, 16, 1 do --The maximum number of abilities a unit can have is currently 17.
		local current_ability = keys.target:GetAbilityByIndex(i)
		if current_ability ~= nil then
			if current_ability:GetName() ~= "holdout_light_frenzy" then
				current_ability:EndCooldown()
			end
		end
	end
	
	--Refresh all items the target has.
	for i=0, 5, 1 do
		local current_item = keys.target:GetItemInSlot(i)
		if current_item ~= nil then
			current_item:EndCooldown()
		end
	end
end