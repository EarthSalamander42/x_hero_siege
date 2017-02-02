function PhaseEntrench(keys)
local caster = keys.caster

	StartAnimation(caster, {duration = 0.55, activity = ACT_DOTA_SAND_KING_BURROW_IN, rate = 0.4})
	caster:SetAttackCapability(DOTA_UNIT_CAP_NO_ATTACK)
	caster:SetMoveCapability(DOTA_UNIT_CAP_MOVE_NONE)
end

function Entrench(keys)
local caster = keys.caster
local point = caster:GetAbsOrigin()
local ability = keys.ability
local sub_ability_name = keys.sub_ability_name
local main_ability_name = ability:GetAbilityName()

	caster:SwapAbilities(main_ability_name, sub_ability_name, false, true)
end

function PhaseUnEntrench(keys)
local caster = keys.caster

	StartAnimation(caster, {duration = 1.25, activity = ACT_DOTA_SAND_KING_BURROW_OUT, rate = 0.4})
end

function UnEntrench(keys)
local caster = keys.caster
local ability = keys.ability
local sub_ability_name = keys.sub_ability_name
local main_ability_name = ability:GetAbilityName()
local ability_main = caster:FindAbilityByName("holdout_entrench")

	caster:SetAttackCapability(DOTA_UNIT_CAP_MELEE_ATTACK)
	caster:SetMoveCapability(DOTA_UNIT_CAP_MOVE_GROUND)
	caster:SwapAbilities(main_ability_name, sub_ability_name, false, true)
	ability_main:StartCooldown(14.0)
end

function invoker_tornado_datadriven_on_spell_start(keys)
local caster = keys.caster
local caster_origin = keys.caster:GetAbsOrigin()
local ability = keys.ability
local ability_level = ability:GetLevel() -1
local AreaOfEffect = keys.AreaOfEffect
local TravelSpeed = keys.TravelSpeed
local VisionDistance = keys.VisionDistance
tornado_travel_distance = ability:GetLevelSpecialValueFor("travel_distance", ability_level)
tornado_lift_duration = ability:GetLevelSpecialValueFor("lift_duration", ability_level)

	--Create a dummy unit that will follow the path of the tornado, providing flying vision and sound.
	--Its holdout_tornado_tempest ability also applies the cyclone modifier to hit enemy units, since if Invoker uninvokes Tornado,
	--existing modifiers linked to that ability can cause errors.
	local tornado_dummy_unit = CreateUnitByName("npc_dummy_unit", caster_origin, false, nil, nil, caster:GetTeam())
	tornado_dummy_unit:SetOwner(caster)
	tornado_dummy_unit:AddAbility("holdout_tornado_tempest")
	local emp_unit_ability = tornado_dummy_unit:FindAbilityByName("holdout_tornado_tempest")
	if emp_unit_ability ~= nil then
		emp_unit_ability:SetLevel(ability:GetLevel())
		emp_unit_ability:ApplyDataDrivenModifier(tornado_dummy_unit, tornado_dummy_unit, "modifier_invoker_tornado_datadriven_unit_ability", {duration = -1})
	end
	
	tornado_dummy_unit:EmitSound("Hero_Invoker.Tornado")  --Emit a sound that will follow the tornado.
	tornado_dummy_unit:SetDayTimeVisionRange(keys.VisionDistance)
	tornado_dummy_unit:SetNightTimeVisionRange(keys.VisionDistance)
	
	local projectile_information =  
	{
		EffectName = "particles/units/heroes/hero_invoker/invoker_tornado.vpcf",
		Ability = emp_unit_ability,
		vSpawnOrigin = caster_origin,
		fDistance = tornado_travel_distance,
		fStartRadius = AreaOfEffect,
		fEndRadius = AreaOfEffect,
		Source = tornado_dummy_unit,
		bHasFrontalCone = false,
		iMoveSpeed = TravelSpeed,
		bReplaceExisting = false,
		bProvidesVision = true,
		iVisionTeamNumber = caster:GetTeam(),
		iVisionRadius = kVisionDistance,
		bDrawsOnMinimap = false,
		bVisibleToEnemies = true, 
		iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
		iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
		iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_CREEP,
		fExpireTime = GameRules:GetGameTime() + 20.0,
	}

	local target_point = keys.target_points[1]
	target_point.z = 0
	local caster_point = caster:GetAbsOrigin()
	caster_point.z = 0
	local point_difference_normalized = (target_point - caster_point):Normalized()
	projectile_information.vVelocity = point_difference_normalized * TravelSpeed
	
	local tornado_projectile = ProjectileManager:CreateLinearProjectile(projectile_information)
	
	--When the projectile ID can be passed into a OnProjectileHitUnit block, an array like this can be used to store the stats associated with the projectile.
	--[[
	--Store the lift duration and bonus landing damage associated with the projectile, using the Quas/Exort levels from when Tornado was cast.
	if keys.caster.tornado_projectile_information == nil then
		keys.caster.tornado_projectile_information = {}
	end
	local tornado_projectile_information = {}
	tornado_projectile_information["tornado_lift_duration"] = tornado_lift_duration
	tornado_projectile_information[tornado_projectile])["tornado_landing_damage_bonus"] = tornado_landing_damage_bonus
	keys.caster.tornado_projectile_information[tornado_projectile] = tornado_projectile_information
	]]
	
	tornado_dummy_unit.invoker_tornado_lift_duration = tornado_lift_duration
	tornado_dummy_unit.invoker_tornado_landing_damage_bonus = tornado_landing_damage_bonus
	
	--Calculate where and when the Tornado projectile will end up.
	local tornado_duration = tornado_travel_distance / TravelSpeed
	local tornado_final_position = caster_origin + (projectile_information.vVelocity * tornado_duration)
	local tornado_velocity_per_frame = projectile_information.vVelocity * .03
	
	--Adjust the dummy unit's position every frame to match that of the tornado particle effect.
	local endTime = GameRules:GetGameTime() + tornado_duration
	Timers:CreateTimer({
		endTime = .03,
		callback = function()
			tornado_dummy_unit:SetAbsOrigin(tornado_dummy_unit:GetAbsOrigin() + tornado_velocity_per_frame)
			if GameRules:GetGameTime() > endTime then
				tornado_dummy_unit:StopSound("Hero_Invoker.Tornado")
				
				--Have the dummy unit linger in the position the tornado ended up in, in order to provide vision.
				Timers:CreateTimer({
					endTime = keys.EndVisionDuration,
					callback = function()
						tornado_dummy_unit:RemoveSelf()
					end
				})
				
				return 
			else 
				return .03
			end
		end
	})
end

function invoker_tornado_datadriven_on_projectile_hit_unit(keys)
local caster = keys.caster
local target = keys.target
local ability = keys.ability
	if keys.caster.invoker_tornado_lift_duration ~= nil then
		--Store the target's forward vector so they can be left facing in the same direction when they land.
		target.invoker_tornado_forward_vector = target:GetForwardVector()
		
		ability:ApplyDataDrivenModifier(caster, target, "modifier_invoker_tornado_datadriven_cyclone", {duration = caster.invoker_tornado_lift_duration})
		
		target:EmitSound("Hero_Invoker.Tornado.Target")
		
		--Stop the sound when the cycloning ends.
		Timers:CreateTimer({
			endTime = caster.invoker_tornado_lift_duration,
			callback = function()
				target:StopSound("Hero_Invoker.Tornado.Target")
			end
		})
	end
end

function modifier_invoker_tornado_datadriven_cyclone_on_destroy(keys)
local target = keys.target
	target:EmitSound("Hero_Invoker.Tornado.LandDamage")
	
	--Set it so the target is facing the same direction as they were when they were hit by the tornado.
	if target.invoker_tornado_forward_vector ~= nil then
		target:SetForwardVector(target.invoker_tornado_forward_vector)
	end

	ApplyDamage({victim = target, attacker = keys.caster, damage = keys.BaseDamage, damage_type = DAMAGE_TYPE_MAGICAL})

	target.invoker_tornado_degrees_to_spin = nil
end

function modifier_invoker_tornado_datadriven_cyclone_on_interval_think(keys)
local caster = keys.caster
local target = keys.target
local total_degrees = 20
	
	--Rotate as close to 20 degrees per .03 seconds (666.666 degrees per second) as possible, but such that the target lands facing their initial direction.
	if keys.target.invoker_tornado_degrees_to_spin == nil and caster.invoker_tornado_lift_duration ~= nil then
		local ideal_degrees_per_second = 666.666
		local ideal_full_spins = (ideal_degrees_per_second / 360) * caster.invoker_tornado_lift_duration
		ideal_full_spins = math.floor(ideal_full_spins + .5)  --Round the number of spins to aim for to the closest integer.
		local degrees_per_second_ending_in_same_forward_vector = (360 * ideal_full_spins) / keys.caster.invoker_tornado_lift_duration
		
		target.invoker_tornado_degrees_to_spin = degrees_per_second_ending_in_same_forward_vector * .03
	end
	
	target:SetForwardVector(RotatePosition(Vector(0,0,0), QAngle(0, target.invoker_tornado_degrees_to_spin, 0), target:GetForwardVector()))
end

function modifier_invoker_tornado_datadriven_cyclone_on_created(keys)
local caster = keys.caster
local target = keys.target
local ability = keys.ability

-- Position variables
local target_origin = target:GetAbsOrigin()
local target_initial_x = target_origin.x
local target_initial_y = target_origin.y
local target_initial_z = target_origin.z
local position = Vector(target_initial_x, target_initial_y, target_initial_z)  --This is updated whenever the target has their position changed.

local duration = 0
if keys.caster.invoker_tornado_lift_duration ~= nil then
	duration = keys.caster.invoker_tornado_lift_duration
else
	local quas_ability = keys.caster:FindAbilityByName("quas_datadriven")
	if quas_ability ~= nil then
		duration = keys.ability:GetLevelSpecialValueFor("duration", quas_ability:GetLevel() - 1)
	end
end

local ground_position = GetGroundPosition(position, target)
local cyclone_initial_height = keys.CycloneInitialHeight + ground_position.z
local cyclone_min_height = keys.CycloneMinHeight + ground_position.z
local cyclone_max_height = keys.CycloneMaxHeight + ground_position.z
local tornado_start = GameRules:GetGameTime()

-- Height per time calculation
local time_to_reach_initial_height = duration / 10  --1/10th of the total cyclone duration will be spent ascending and descending to and from the initial height.
local initial_ascent_height_per_frame = ((cyclone_initial_height - position.z) / time_to_reach_initial_height) * .03  --This is the height to add every frame when the unit is first cycloned, and applies until the caster reaches their max height.

local up_down_cycle_height_per_frame = initial_ascent_height_per_frame / 3  --This is the height to add or remove every frame while the caster is in up/down cycle mode.
if up_down_cycle_height_per_frame > 7.5 then  --Cap this value so the unit doesn't jerk up and down for short-duration cyclones.
	up_down_cycle_height_per_frame = 7.5
end

local final_descent_height_per_frame = nil  --This is calculated when the unit begins descending.

-- Time to go down
local time_to_stop_fly = duration - time_to_reach_initial_height

-- Loop up and down
local going_up = true

	-- Loop every frame for the duration
	Timers:CreateTimer(function()
		local time_in_air = GameRules:GetGameTime() - tornado_start
		
		-- First send the target to the cyclone's initial height.
		if position.z < cyclone_initial_height and time_in_air <= time_to_reach_initial_height then
			--print("+",initial_ascent_height_per_frame,position.z)
			position.z = position.z + initial_ascent_height_per_frame
			target:SetAbsOrigin(position)
			return 0.03

		-- Go down until the target reaches the ground.
		elseif time_in_air > time_to_stop_fly and time_in_air <= duration then
			--Since the unit may be anywhere between the cyclone's min and max height values when they start descending to the ground,
			--the descending height per frame must be calculated when that begins, so the unit will end up right on the ground when the duration is supposed to end.
			if final_descent_height_per_frame == nil then
				local descent_initial_height_above_ground = position.z - ground_position.z
				--print("ground position: " .. GetGroundPosition(position, target).z)
				--print("position.z : " .. position.z)
				final_descent_height_per_frame = (descent_initial_height_above_ground / time_to_reach_initial_height) * .03
			end
			
			--print("-",final_descent_height_per_frame,position.z)
			position.z = position.z - final_descent_height_per_frame
			target:SetAbsOrigin(position)
			return 0.03

		-- Do Up and down cycles
		elseif time_in_air <= duration then
			-- Up
			if position.z < cyclone_max_height and going_up then 
				--print("going up")
				position.z = position.z + up_down_cycle_height_per_frame
				target:SetAbsOrigin(position)
				return 0.03

			-- Down
			elseif position.z >= cyclone_min_height then
				going_up = false
				--print("going down")
				position.z = position.z - up_down_cycle_height_per_frame
				target:SetAbsOrigin(position)
				return 0.03

			-- Go up again
			else
				--print("going up again")
				going_up = true
				return 0.03
			end

		-- End
		else
			--print(GetGroundPosition(target:GetAbsOrigin(), target))
			--print("End TornadoHeight")
		end
	end)
end

function SkinChangerDragon( keys )
local caster = keys.caster
local ability = keys.ability
local ability_level = ability:GetLevel()
local PlayerID = caster:GetPlayerID()
local gold = caster:GetGold()
local loc = caster:GetAbsOrigin()
local Strength = caster:GetBaseStrength()
local Intellect = caster:GetBaseIntellect()
local Agility = caster:GetBaseAgility()
local HP = caster:GetHealth()
local Mana = caster:GetMana()
local CURRENT_XP = caster:GetCurrentXP()
local duration = ability:GetLevelSpecialValueFor("duration", ability:GetLevel() -1)

	local hero = PlayerResource:ReplaceHeroWith( PlayerID, "npc_dota_hero_viper", gold, 0)
	hero:AddExperience(CURRENT_XP, false, false)
	local NewAbility = hero:FindAbilityByName("holdout_desert_dragon_form")
	NewAbility:SetLevel(ability_level)
	NewAbility:StartCooldown(120.0)

	local items = {}
	for i = 0, 5 do
		if caster:GetItemInSlot(i) ~= nil and caster:GetItemInSlot(i):GetName() ~= "item_classchange_reset" then
			itemCopy = CreateItem(caster:GetItemInSlot(i):GetName(), nil, nil)
			items[i] = itemCopy
		end
	end
	for i = 0, 5 do
		if items[i] ~= nil then
			hero:AddItem(items[i])
			items[i]:SetCurrentCharges(caster:GetItemInSlot(i):GetCurrentCharges())
		end
	end

	hero:SetAbsOrigin(loc)
	hero:SetBaseStrength(Strength)
	hero:SetBaseIntellect(Intellect)
	hero:SetBaseAgility(Agility)
	hero:SetHealth(HP)
	hero:SetMana(Mana)

	Timers:CreateTimer(1.0, function()
		if not caster:IsNull() then
			UTIL_Remove(caster)
		end
	end)

	Timers:CreateTimer(duration, function()
		local Newhero = PlayerResource:ReplaceHeroWith( PlayerID, "npc_dota_hero_sand_king", gold, 0)
		hero:AddExperience(CURRENT_XP, false, false)
		NewAbility:SetLevel(ability_level)

		local items = {}
		for i = 0, 5 do
			if Newhero:GetItemInSlot(i) ~= nil and Newhero:GetItemInSlot(i):GetName() ~= "item_classchange_reset" then
				itemCopy = CreateItem(Newhero:GetItemInSlot(i):GetName(), nil, nil)
				items[i] = itemCopy
			end
		end

		for i = 0, 5 do
			if items[i] ~= nil then
				hero:AddItem(items[i])
				items[i]:SetCurrentCharges(Newhero:GetItemInSlot(i):GetCurrentCharges())
			end
		end
		hero:SetAbsOrigin(loc)
		hero:SetBaseStrength(Strength)
		hero:SetBaseIntellect(Intellect)
		hero:SetBaseAgility(Agility)
		hero:SetHealth(HP)
		hero:SetMana(Mana)

		Timers:CreateTimer(1.0, function()
			if not Newhero:IsNull() then
				UTIL_Remove(Newhero)
			end
		end)
	end)
end

function LevelUpAbility(keys)
	local caster = keys.caster
	local this_ability = keys.ability		
	local this_abilityName = this_ability:GetAbilityName()
	local this_abilityLevel = this_ability:GetLevel()

	-- The ability to level up
	local ability_name = keys.ability_name
	local ability_handle = caster:FindAbilityByName(ability_name)	
	local ability_level = ability_handle:GetLevel()

	-- Check to not enter a level up loop
	if ability_level ~= this_abilityLevel then
		ability_handle:SetLevel(this_abilityLevel)
	end
end
