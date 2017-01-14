require('libraries/timers')

function WarClub( event )
local caster = event.caster
local target = event.target
local ability = event.ability

--	caster:StartGesture(ACT_DOTA_ATTACK)
	caster:RemoveModifierByName("modifier_item_ultimate_scepter_consumed")
	target:CutDown(caster:GetTeamNumber())

	Timers:CreateTimer(0.1, function()
		caster:AddNewModifier(caster, nil, "modifier_animation_translate", {translate="tree"})
		caster:SetModifierStackCount("modifier_animation_translate", caster, 310)
		ability:ApplyDataDrivenModifier(caster, caster, "modifier_war_club", {})
		ability:ApplyDataDrivenModifier(caster, caster, "modifier_war_club_strikes", {})
		caster:AddNewModifier(caster, ability, "modifier_item_ultimate_scepter_consumed", {})
		local strikes = ability:GetSpecialValueFor("strikes")
		caster:SetModifierStackCount("modifier_war_club_strikes", caster, strikes)
	end)
end

function WarClubStrike( event )
local caster = event.caster
local ability = event.ability
local target = event.target
local damage = event.Damage
local strikes = ability:GetSpecialValueFor("strikes")
local stack_count = caster:GetModifierStackCount("modifier_war_club_strikes", caster)

--	if target:IsBuilding() then
--		local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_tiny/tiny_grow_cleave.vpcf", PATTACH_OVERHEAD_FOLLOW, target)
--	end

	if stack_count > 1 then
		caster:SetModifierStackCount("modifier_war_club_strikes", caster, stack_count - 1)
	else
		caster:RemoveModifierByName("modifier_war_club")
		caster:RemoveModifierByName("modifier_war_club_strikes")
		caster:RemoveModifierByName("modifier_animation_translate")
		Timers:CreateTimer(0.1, function()
			caster:RemoveModifierByName("modifier_item_ultimate_scepter_consumed")
		end)
	end 
end

function DwarfToss( keys )
local caster = keys.caster
local ability = keys.ability
local target_pos = keys.target_points[1]
local ability_level = ability:GetLevel() - 1
local root_modifier = keys.root_modifier
local buff_modifier = keys.buff_modifier
local sound_cast = keys.sound_cast
local caster_pos = caster:GetAbsOrigin()
local min_speed = ability:GetLevelSpecialValueFor("min_speed", ability_level)
local base_distance = ability:GetLevelSpecialValueFor("base_distance", ability_level)
local max_time = ability:GetLevelSpecialValueFor("max_time", ability_level)
local buff_radius = ability:GetLevelSpecialValueFor("buff_radius", ability_level)
local cooldown_increase = ability:GetLevelSpecialValueFor("cooldown_increase", ability_level)
local base_height = ability:GetLevelSpecialValueFor("base_height", ability_level)
local height_step = ability:GetLevelSpecialValueFor("height_step", ability_level)
local max_height = ability:GetLevelSpecialValueFor("max_height", ability_level)
local is_night = false

	-- Clears any current command
	caster:Stop()

	-- Disjoint projectiles
	ProjectileManager:ProjectileDodge(caster)

	-- Calculate leap geometry
	local direction = (target_pos - caster_pos):Normalized()
	local distance = (target_pos - caster_pos):Length2D()
	local height = base_height

	-- Cap distance during the day
	if not is_night then
		distance = math.min(distance, base_distance)
		target_pos = caster_pos + direction * distance

	-- Adjust height during long nighttime jumps
	else
		height = math.min( (distance - base_distance) / base_distance * height_step + base_height, max_height)
	end

	-- Calculate leap speed and duration
	local leap_speed = max_time
	local leap_time = leap_speed

	-- Root the caster during the jump
	ability:ApplyDataDrivenModifier(caster, caster, root_modifier, {})

	-- Perform movement loop
	local current_time = 0
	Timers:CreateTimer(0.03, function()

		-- Update time
		current_time = current_time + 0.03

		-- Calculate height
		local current_height
		if current_time <= (leap_time / 2) then
			current_height = height * current_time / leap_time * 2
		else
			current_height = height * (1 - current_time / leap_time) * 2
		end

		-- Calculate position
		local current_position = caster_pos + direction * distance * current_time / leap_time

		-- Update position
		caster:SetAbsOrigin(Vector(current_position.x, current_position.y, GetGroundHeight(current_position, caster) + current_height))
		
		-- If the jump time hasn't elapsed yet, keep going
		if current_time < leap_time then
			return 0.03

		-- Else, finalize the jump
		else

			-- Unroot the caster
			caster:RemoveModifierByName(root_modifier)

			-- Prevent the caster from getting stuck
			FindClearSpaceForUnit(caster, target_pos, true)

			-- Buff nearby allies
			local nearby_allies = FindUnitsInRadius(caster:GetTeamNumber(), target_pos, nil, buff_radius, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
			for _,ally in pairs(nearby_allies) do
				ability:ApplyDataDrivenModifier(caster, ally, buff_modifier, {})
			end
		end
	end)
end

function SecondWindDamage( keys )
local caster = keys.caster
local attacker = keys.attacker
local ability = keys.ability
local ability_level = ability:GetLevel() - 1
local modifier_regen = keys.modifier_regen
local cooldown = ability:GetLevelSpecialValueFor("regen_cooldown", ability_level)

	caster:RemoveModifierByName(modifier_regen)
	ability:StartCooldown(cooldown)
end

function SecondWindRegen( keys )
local caster = keys.caster
local ability = keys.ability
local modifier_regen = keys.modifier_regen

	if ability:IsCooldownReady() then
		ability:ApplyDataDrivenModifier(caster, caster, modifier_regen, {})
	else
		caster:RemoveModifierByName(modifier_regen)
	end
end

function ToggleOff( keys )
local caster = keys.caster
local ability = keys.ability
local BAT_alt = caster:GetBaseAttackTime()
local BAT_Dec = ability:GetLevelSpecialValueFor("bat_reduction", ability:GetLevel() -1)

	caster:AddAbility("tiny_grow")
	grow = caster:FindAbilityByName("tiny_grow")
	grow:SetLevel(0)
	caster:SetModelScale( 1.0 )
	caster:SetBaseAttackTime( BAT_alt - BAT_Dec )
	ability:StartCooldown(10.0)
	Timers:CreateTimer(0.4, function()
		caster:RemoveAbility("tiny_grow")
	end)
end

function ToggleOn( keys )
local caster = keys.caster
local ability = keys.ability
local BAT_alt = caster:GetBaseAttackTime()
local BAT_Dec = ability:GetLevelSpecialValueFor("bat_reduction", ability:GetLevel() -1)

	caster:AddAbility("tiny_grow")
	grow = caster:FindAbilityByName("tiny_grow")
	grow:SetLevel(2)
	caster:SetModelScale( 1.25 )
	caster:SetBaseAttackTime( BAT_alt + BAT_Dec )
	Timers:CreateTimer(0.4, function()
		caster:RemoveAbility("tiny_grow")
	end)
end

function Taunt( event )
local caster = event.caster

	caster:StartGesture(ACT_TINY_GROWL)
end
