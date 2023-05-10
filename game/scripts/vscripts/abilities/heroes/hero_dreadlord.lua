function invoker_chaos_meteor_datadriven_on_spell_start(keys)
local caster = keys.caster
local caster_point = caster:GetAbsOrigin()
local target_point = keys.target_points[1]
local caster_point_temp = Vector(caster_point.x, caster_point.y, 0)
local target_point_temp = Vector(target_point.x, target_point.y, 0)
local point_difference_normalized = (target_point_temp - caster_point_temp):Normalized()
local velocity_per_second = point_difference_normalized * keys.TravelSpeed

	caster:EmitSound("Hero_Invoker.ChaosMeteor.Cast")
	caster:EmitSound("Hero_Invoker.ChaosMeteor.Loop")
	local meteor_fly_original_point = (target_point - (velocity_per_second * keys.LandTime)) + Vector (0, 0, 1000)  --Start the meteor in the air in a place where it'll be moving the same speed when flying and when rolling.
	local chaos_meteor_fly_particle_effect = ParticleManager:CreateParticle("particles/units/heroes/hero_dreadlord/chaos_2_fly.vpcf", PATTACH_ABSORIGIN, caster)
	ParticleManager:SetParticleControl(chaos_meteor_fly_particle_effect, 0, meteor_fly_original_point)
	ParticleManager:SetParticleControl(chaos_meteor_fly_particle_effect, 1, target_point)
	ParticleManager:SetParticleControl(chaos_meteor_fly_particle_effect, 2, Vector(1.3, 0, 0))

	local exort_ability = caster:FindAbilityByName("holdout_chaos")
	local main_damage = 0
	local burn_dps = 0
	if exort_ability then
		local exort_level = exort_ability:GetLevel()
		main_damage = keys.ability:GetLevelSpecialValueFor("main_damage", exort_level - 1)
		burn_dps = keys.ability:GetLevelSpecialValueFor("burn_dps", exort_level - 1)
	end

	local wex_ability = caster:FindAbilityByName("holdout_chaos")
	local travel_distance = 0
	if wex_ability ~= nil then
		travel_distance = keys.ability:GetLevelSpecialValueFor("travel_distance", wex_ability:GetLevel() - 1)
	end

	Timers:CreateTimer({
		endTime = keys.LandTime,
		callback = function()
			--Create a dummy unit will follow the path of the meteor, providing flying vision, sound, damage, etc.          
			local chaos_meteor_dummy_unit = CreateUnitByName("npc_dummy_unit", target_point, false, nil, nil, caster:GetTeam())
			chaos_meteor_dummy_unit:AddAbility("holdout_chaos")
			local chaos_meteor_unit_ability = chaos_meteor_dummy_unit:FindAbilityByName("holdout_chaos")
			if chaos_meteor_unit_ability ~= nil then
				chaos_meteor_unit_ability:SetLevel(1)
				chaos_meteor_unit_ability:ApplyDataDrivenModifier(chaos_meteor_dummy_unit, chaos_meteor_dummy_unit, "modifier_invoker_chaos_meteor_datadriven_unit_ability", {duration = -1})
			end

			caster:StopSound("Hero_Invoker.ChaosMeteor.Loop")
			chaos_meteor_dummy_unit:EmitSound("Hero_Invoker.ChaosMeteor.Impact")
			chaos_meteor_dummy_unit:EmitSound("Hero_Invoker.ChaosMeteor.Loop")  --Emit a sound that will follow the meteor.
			
			chaos_meteor_dummy_unit:SetDayTimeVisionRange(keys.VisionDistance)
			chaos_meteor_dummy_unit:SetNightTimeVisionRange(keys.VisionDistance)
			
			--Store the damage to deal in a variable attached to the dummy unit, so leveling Exort after Meteor is cast will have no effect.
			chaos_meteor_dummy_unit.invoker_chaos_meteor_main_damage = main_damage
			chaos_meteor_dummy_unit.invoker_chaos_meteor_burn_dps = burn_dps
			chaos_meteor_dummy_unit.invoker_chaos_meteor_parent_caster = caster
		
			local chaos_meteor_duration = travel_distance / keys.TravelSpeed
			local chaos_meteor_velocity_per_frame = velocity_per_second * .03
			
			--It would seem that the Chaos Meteor projectile needs to be attached to a particle in order to move and roll and such.
			local projectile_information =  
			{
				EffectName = "particles/units/heroes/hero_dreadlord/chaos.vpcf",
				Ability = chaos_meteor_unit_ability,
				vSpawnOrigin = target_point,
				fDistance = travel_distance,
				fStartRadius = 0,
				fEndRadius = 0,
				Source = chaos_meteor_dummy_unit,
				bHasFrontalCone = false,
				iMoveSpeed = keys.TravelSpeed,
				bReplaceExisting = false,
				bProvidesVision = true,
				iVisionTeamNumber = caster:GetTeam(),
				iVisionRadius = keys.VisionDistance,
				bDrawsOnMinimap = false,
				bVisibleToEnemies = true, 
				iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_NONE,
				iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
				iUnitTargetType = DOTA_UNIT_TARGET_NONE ,
				fExpireTime = GameRules:GetGameTime() + chaos_meteor_duration + keys.EndVisionDuration,
			}

			projectile_information.vVelocity = velocity_per_second
			local chaos_meteor_projectile = ProjectileManager:CreateLinearProjectile(projectile_information)

			chaos_meteor_unit_ability:ApplyDataDrivenModifier(chaos_meteor_dummy_unit, chaos_meteor_dummy_unit, "modifier_invoker_chaos_meteor_datadriven_main_damage", nil)
			
			--Adjust the dummy unit's position every frame.
			local endTime = GameRules:GetGameTime() + chaos_meteor_duration
			Timers:CreateTimer({
				callback = function()
					chaos_meteor_dummy_unit:SetAbsOrigin(chaos_meteor_dummy_unit:GetAbsOrigin() + chaos_meteor_velocity_per_frame)
					if GameRules:GetGameTime() > endTime then
						--Stop the sound, particle, and damage when the meteor disappears.
						chaos_meteor_dummy_unit:StopSound("Hero_Invoker.ChaosMeteor.Loop")
						chaos_meteor_dummy_unit:StopSound("Hero_Invoker.ChaosMeteor.Destroy")
						chaos_meteor_dummy_unit:RemoveModifierByName("modifier_invoker_chaos_meteor_datadriven_main_damage")
					
						--Have the dummy unit linger in the position the meteor ended up in, in order to provide vision.
						Timers:CreateTimer({
							endTime = keys.EndVisionDuration,
							callback = function()
								chaos_meteor_dummy_unit:SetDayTimeVisionRange(0)
								chaos_meteor_dummy_unit:SetNightTimeVisionRange(0)
								
								--Remove the dummy unit after the burn damage modifiers are guaranteed to have all expired.
								Timers:CreateTimer({
									endTime = keys.BurnDuration,
									callback = function()
										chaos_meteor_dummy_unit:RemoveSelf()
									end
								})
							end
						})
						return 
					else 
						return .03
					end
				end
			})
		end
	})
end

function modifier_invoker_chaos_meteor_datadriven_main_damage_on_interval_think(keys)
local caster = keys.caster
local nearby_enemy_units = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, keys.AreaOfEffect, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)

	if caster.invoker_chaos_meteor_parent_caster ~= nil then
		for i, individual_unit in ipairs(nearby_enemy_units) do
			individual_unit:EmitSound("Hero_Invoker.ChaosMeteor.Damage")
			
			if caster.invoker_chaos_meteor_main_damage == nil then
				caster.invoker_chaos_meteor_main_damage = 0
			end
			
			ApplyDamage({victim = individual_unit, attacker = caster.invoker_chaos_meteor_parent_caster, damage = caster.invoker_chaos_meteor_main_damage, damage_type = DAMAGE_TYPE_MAGICAL,})
			
			keys.ability:ApplyDataDrivenModifier(caster, individual_unit, "modifier_invoker_chaos_meteor_datadriven_burn_damage", nil)
		end
	end
end

function modifier_invoker_chaos_meteor_datadriven_burn_damage_on_interval_think(keys)
local caster = keys.caster

	if caster.invoker_chaos_meteor_parent_caster ~= nil and caster.invoker_chaos_meteor_burn_dps ~= nil then
		ApplyDamage({victim = keys.target, attacker = caster.invoker_chaos_meteor_parent_caster, damage = caster.invoker_chaos_meteor_burn_dps * keys.BurnDPSInterval, damage_type = DAMAGE_TYPE_MAGICAL,})
	end
end

function NightmareDamage( keys )
	local caster = keys.caster
	local ability = keys.ability
	local target = keys.target

	local target_health = target:GetHealth()
	local damage = ability:GetLevelSpecialValueFor("damage_per_second", ability:GetLevel() - 1)

	-- Check if the damage would be lethal.
	if target_health <= damage then
		
		-- If that's the case, deal pure damage.
		ApplyDamage({attacker = caster, victim = target, ability = ability, damage = damage, damage_type = DAMAGE_TYPE_PURE})
	else
		-- Otherwise, just set the health to be lower
		target:SetHealth(target_health - damage)
	end
end

function NightmareSpread( keys )
	local caster = keys.caster
	local target = keys.target
	local attacker = keys.attacker
	local ability = keys.ability
	local nightmare_modifier = keys.nightmare_modifier

	-- Check if it has the Nightmare debuff
	if target:HasModifier(nightmare_modifier) then

		-- If it does then apply it to the attacker
		ability:ApplyDataDrivenModifier(caster, attacker, nightmare_modifier, {})
	end
end

function NightmareEnd( keys )
	local target = keys.target
	local loop_sound = keys.loop_sound

	-- Stops playing sound
	StopSoundEvent(loop_sound, target)
end

function NightmareEndCast( keys )
	local ability = keys.ability
	local target = keys.target
	local modifier_nightmare = keys.modifier_nightmare
	local modifier_invul = keys.modifier_invul

	-- Remove Nightmare modifiers
	target:RemoveModifierByName(modifier_nightmare)
	target:RemoveModifierByName(modifier_invul)
end

function target_modifier_remove(keys)
local target = keys.target
local caster = keys.caster

	local soil = ParticleManager:CreateParticle("particles/units/heroes/hero_invoker/invoker_chaos_meteor_land_soil.vpcf", PATTACH_CUSTOMORIGIN, caster)
	ParticleManager:SetParticleControl(soil, 3, target:GetAbsOrigin()+Vector(0,0,40))
	local crumble = ParticleManager:CreateParticle("particles/units/heroes/hero_invoker/invoker_chaos_meteor_crumble.vpcf", PATTACH_CUSTOMORIGIN, caster)
	ParticleManager:SetParticleControl(crumble, 3, target:GetAbsOrigin())
	target:StopSound("Hero_Invoker.ChaosMeteor.Loop")
	target:RemoveSelf()
end

-- Changes the color of the summoned unit
function RenderInferno(event)
	event.target:SetRenderColor(128, 255, 0)
	event.target:AddNewModifier(event.target, nil, "modifier_phased", { duration = 0.05 })
end

function rain_of_chaos( event )
local caster = event.caster
local ability = event.ability
local time_to_damage = 2.0
local radius = ability:GetLevelSpecialValueFor("radius", ability:GetLevel()-1)
local meteors_per_tick = ability:GetLevelSpecialValueFor("meteors_per_tick", ability:GetLevel()-1)

	for i = 1, meteors_per_tick do
		local point = event.target_points[1] + RandomInt(1, radius) * RandomVector(1)
		local meteor = ParticleManager:CreateParticle("particles/units/heroes/hero_invoker/invoker_chaos_meteor_fly.vpcf", PATTACH_CUSTOMORIGIN, caster)
		ParticleManager:SetParticleControl(meteor, 0, point + Vector(0,0,500))
		ParticleManager:SetParticleControl(meteor, 1, point)
		ParticleManager:SetParticleControl(meteor, 2, Vector(1.2,0,0))
		local unit = CreateUnitByName("dummy_unit_invulnerable", point, true, nil, nil, caster:GetTeamNumber())
		unit:EmitSound("Hero_Invoker.ChaosMeteor.Loop")
		ability:ApplyDataDrivenModifier(caster, unit, "modifier_dummy_target", {duration = 1.1})
		Timers:CreateTimer(1.1, function()
			unit:EmitSound("Hero_Invoker.ChaosMeteor.Impact")
		end)
	end
end