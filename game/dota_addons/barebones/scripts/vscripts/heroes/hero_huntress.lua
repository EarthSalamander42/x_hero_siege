function lightning_storm_start( keys )
local target = keys.target
local caster = keys.caster
local ability = keys.ability

	ability.jump_count = ability:GetLevelSpecialValueFor("jump_count", ability:GetLevel() - 1)
	ability.radius = ability:GetLevelSpecialValueFor("radius", ability:GetLevel() - 1)
	ability.jump_delay = ability:GetLevelSpecialValueFor("jump_delay", ability:GetLevel() - 1)
	ability.damage = ability:GetAbilityDamage()

	lightning_storm_repeat({ caster=caster,
		initial_target=target, 
		jump_count=ability.jump_count, 
		radius=ability.radius,
		jump_delay=ability.jump_delay,
		damage=ability.damage,
		ability=ability,
		bounceTable={}
	})
end

function lightning_storm_repeat( params )
	if params.jump_count == 0 or params.initial_target == nil then
		return
	end

	-- hit initial target
	local lightning = ParticleManager:CreateParticle("particles/econ/items/luna/luna_lucent_ti5_gold/luna_eclipse_impact_moonfall_gold.vpcf", PATTACH_WORLDORIGIN, params.initial_target)
	local loc = params.initial_target:GetAbsOrigin()
	ParticleManager:SetParticleControl(lightning, 0, loc + Vector(0, 0, 1000))
	ParticleManager:SetParticleControl(lightning, 1, loc)
	ParticleManager:SetParticleControl(lightning, 2, loc)
	EmitSoundOn("Hero_Leshrac.Lightning_Storm", params.initial_target)

	local damageTable = {
		attacker = params.caster,
		victim = params.initial_target,
		damage = params.damage,
		damage_type = DAMAGE_TYPE_MAGICAL,
		ability = params.ability}
	ApplyDamage(damageTable)

	params.bounceTable[params.initial_target] = 1

	-- find next target (closest one to previous one)
	unitsInRange = FindUnitsInRadius(params.initial_target:GetTeamNumber(),
		params.initial_target:GetAbsOrigin(),
		nil,
		params.radius,
		DOTA_UNIT_TARGET_TEAM_FRIENDLY,
		DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO,
		DOTA_UNIT_TARGET_FLAG_NONE,
		FIND_CLOSEST,
		false)

	params.initial_target = nil
	for k,v in pairs(unitsInRange) do
		if params.bounceTable[v] == nil then
			params.initial_target = v
			break
		end
	end

	params.jump_count = params.jump_count - 1

	-- run the function again in jump_delay seconds
	Timers:CreateTimer(params.jump_delay, 
		function()
			lightning_storm_repeat( params )
		end
	)
end

function Shock( event )
local caster = event.caster
local target = event.target
local ability = event.ability
local level = ability:GetLevel() - 1
local start_radius = ability:GetLevelSpecialValueFor("start_radius", level )
local end_radius = ability:GetLevelSpecialValueFor("end_radius", level )
local end_distance = ability:GetLevelSpecialValueFor("end_distance", level )
local targets = ability:GetLevelSpecialValueFor("targets", level )
local damage = ability:GetLevelSpecialValueFor("damage", level )
local AbilityDamageType = ability:GetAbilityDamageType()
local particleName = "particles/units/heroes/hero_shadowshaman/shadowshaman_ether_shock.vpcf"

	-- Make sure the main target is damaged
	local lightningBolt = ParticleManager:CreateParticle(particleName, PATTACH_WORLDORIGIN, caster)
	ParticleManager:SetParticleControl(lightningBolt,0,Vector(caster:GetAbsOrigin().x,caster:GetAbsOrigin().y,caster:GetAbsOrigin().z + caster:GetBoundingMaxs().z ))   
	ParticleManager:SetParticleControl(lightningBolt,1,Vector(target:GetAbsOrigin().x,target:GetAbsOrigin().y,target:GetAbsOrigin().z + target:GetBoundingMaxs().z ))
	ApplyDamage({ victim = target, attacker = caster, damage = damage, damage_type = AbilityDamageType})
	target:EmitSound("Hero_ShadowShaman.EtherShock.Target")

	local cone_units = GetEnemiesInCone( caster, start_radius, end_radius, end_distance )
	local targets_shocked = 1 --Is targets=extra targets or total?
	for _,unit in pairs(cone_units) do
		if targets_shocked < targets then
			if unit ~= target then
				-- Particle
				local origin = unit:GetAbsOrigin()
				local lightningBolt = ParticleManager:CreateParticle(particleName, PATTACH_WORLDORIGIN, caster)
				ParticleManager:SetParticleControl(lightningBolt,0,Vector(caster:GetAbsOrigin().x,caster:GetAbsOrigin().y,caster:GetAbsOrigin().z + caster:GetBoundingMaxs().z ))   
				ParticleManager:SetParticleControl(lightningBolt,1,Vector(origin.x,origin.y,origin.z + unit:GetBoundingMaxs().z ))
			
				-- Damage
				ApplyDamage({ victim = unit, attacker = caster, damage = damage, damage_type = AbilityDamageType})

				-- Increment counter
				targets_shocked = targets_shocked + 1
			end
		else
			break
		end
	end
end

function GetEnemiesInCone( unit, start_radius, end_radius, end_distance)
	local DEBUG = false
	
	-- Positions
	local fv = unit:GetForwardVector()
	local origin = unit:GetAbsOrigin()

	local start_point = origin + fv * start_radius -- Position to find units with start_radius
	local end_point = origin + fv * (start_radius + end_distance) -- Position to find units with end_radius

	if DEBUG then
		DebugDrawCircle(start_point, Vector(255,0,0), 100, start_radius, true, 3)
		DebugDrawCircle(end_point, Vector(255,0,0), 100, end_radius, true, 3)
	end

	-- 1 medium circle should be enough as long as the mid_interval isn't too large
	local mid_interval = end_distance - start_radius - end_radius
	local mid_radius = (start_radius + end_radius) / 2
	local mid_point = origin + fv * mid_radius * 2
	
	if DEBUG then
		--print("There's a space of "..mid_interval.." between the circles at the cone edges")
		DebugDrawCircle(mid_point, Vector(0,255,0), 100, mid_radius, true, 3)
	end

	-- Find the units
	local team = unit:GetTeamNumber()
	local iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
	local iType = DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO
	local iFlag = DOTA_UNIT_TARGET_FLAG_NONE
	local iOrder = FIND_ANY_ORDER

	local start_units = FindUnitsInRadius(team, start_point, nil, start_radius, iTeam, iType, iFlag, iOrder, false)
	local end_units = FindUnitsInRadius(team, end_point, nil, end_radius, iTeam, iType, iFlag, iOrder, false)
	local mid_units = FindUnitsInRadius(team, mid_point, nil, mid_radius, iTeam, iType, iFlag, iOrder, false)

	-- Join the tables
	local cone_units = {}
	for k,v in pairs(end_units) do
		table.insert(cone_units, v)
	end

	for k,v in pairs(start_units) do
		if not tableContains(cone_units, k) then
			table.insert(cone_units, v)
		end
	end 

	for k,v in pairs(mid_units) do
		if not tableContains(cone_units, k) then
			table.insert(cone_units, v)
		end
	end

--	DeepPrintTable(cone_units)
	return cone_units

end

-- Returns true if the element can be found on the list, false otherwise
function tableContains(list, element)
	if list == nil then return false end
	for i=1,#list do
		if list[i] == element then
			return true
		end
	end
	return false
end

time_of_day_reset = nil

function eclipse_start(keys)
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability

	ability.bounceTable = {}

	ability.damage = ability:GetLevelSpecialValueFor("damage", ability:GetLevel() - 1)
	ability.radius = ability:GetLevelSpecialValueFor("radius", ability:GetLevel() - 1)
	ability.beam_interval = ability:GetLevelSpecialValueFor("beam_interval", ability:GetLevel() - 1)
	ability.night_duration = ability:GetLevelSpecialValueFor("night_duration", ability:GetLevel() - 1)

	-- if not scepter
	ability.beams = ability:GetLevelSpecialValueFor("beams", ability:GetLevel() - 1) 
	ability.max_hit_count = ability:GetLevelSpecialValueFor("hit_count", ability:GetLevel() - 1)
	-- else
	--ability.beams = ability:GetLevelSpecialValueFor("beams_scepter", ability:GetLevel() - 1) 
	--ability.max_hit_count = ability:GetLevelSpecialValueFor("hit_count_scepter", ability:GetLevel() - 1) 

	if time_of_day_reset == nil then
		time_of_day_reset = GameRules:GetTimeOfDay()
	end
	GameRules:SetTimeOfDay(0)

	Timers:CreateTimer(ability.night_duration, function()
			if time_of_day_reset ~= nil then
				GameRules:SetTimeOfDay(time_of_day_reset)
			end
			time_of_day_reset = nil
		end)

	for delay = 0, (ability.beams-1) * ability.beam_interval, ability.beam_interval do
		Timers:CreateTimer(delay, function ()
				-- i'm assuming it returns these in random order, might have to fix later
				if caster:IsAlive() == false then
					return
				end

				local unitsNearTarget = FindUnitsInRadius(caster:GetTeamNumber(),
										caster:GetAbsOrigin(),
										nil,
										ability.radius,
										DOTA_UNIT_TARGET_TEAM_ENEMY,
										DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO,
										DOTA_UNIT_TARGET_FLAG_NONE,
										FIND_ANY_ORDER,
										false)

				-- finds the first target with < max_hit_count
				target = nil
				for k, v in pairs(unitsNearTarget) do
					if ability.bounceTable[v] == nil or ability.bounceTable[v] < ability.max_hit_count then
						target = v
						break
					end
				end

				-- if it finds a target, deals damage and then adds it to the bounceTable
				if target ~= nil then
					beam = ParticleManager:CreateParticle("particles/econ/items/luna/luna_lucent_ti5/luna_eclipse_impact_moonfall.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
					ParticleManager:SetParticleControlEnt(beam, 0, caster, PATTACH_ABSORIGIN_FOLLOW, "follow_origin", caster:GetAbsOrigin(), true )
					ParticleManager:SetParticleControlEnt(beam, 1, target, PATTACH_ABSORIGIN_FOLLOW, "follow_origin", target:GetAbsOrigin(), true )
					ParticleManager:SetParticleControlEnt(beam, 5, target, PATTACH_ABSORIGIN_FOLLOW, "follow_origin", target:GetAbsOrigin(), true )

					EmitSoundOn("Hero_Luna.Eclipse.Target", target)

					local damageTable = {
							victim = target,
							attacker = caster,
							damage = ability.damage,
							damage_type = DAMAGE_TYPE_MAGICAL} 
					ApplyDamage(damageTable)

					ability.bounceTable[target] = ((ability.bounceTable[target] or 0) + 1)
				end
			end)
	end 
end