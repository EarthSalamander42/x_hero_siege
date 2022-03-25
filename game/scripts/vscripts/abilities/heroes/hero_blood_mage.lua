function PointOrbThrow(event)
local caster = event.caster
local ability = event.ability
local point = event.target_points[1]

	if caster:GetUnitName() == "npc_dota_hero_invoker" then
		-- Remove first orb
		local orbNumber
		for i = 1, 3 do
			if caster.orbs[i] then
				ParticleManager:DestroyParticle(caster.orbs[i], true)
				caster.orbs[i] = nil
				orbNumber = i
				break
			end
		end

		-- Launch orb
		local speed = 900
		local orb = ParticleManager:CreateParticle("particles/units/heroes/hero_rubick/rubick_base_attack.vpcf", PATTACH_CUSTOMORIGIN, caster)
		ParticleManager:SetParticleControl(orb, 0, caster:GetAttachmentOrigin(caster:ScriptLookupAttachment("attach_attack1")))
		ParticleManager:SetParticleControl(orb, 1, point)
		ParticleManager:SetParticleControl(orb, 2, Vector(speed, 0, 0))
		ParticleManager:SetParticleControl(orb, 3, point)

		local distanceToTarget = (caster:GetAbsOrigin() - point):Length2D()
		Timers:CreateTimer(distanceToTarget/speed, function()
			ParticleManager:DestroyParticle(orb, false)
		end)

		-- Restore orb
		Timers:CreateTimer(1, function() 
			if orbNumber then
				caster.orbs[orbNumber] = ParticleManager:CreateParticle("particles/custom/human/blood_mage/exort_orb.vpcf", PATTACH_OVERHEAD_FOLLOW, caster)
				ParticleManager:SetParticleControlEnt(caster.orbs[orbNumber], 1, caster, PATTACH_POINT_FOLLOW, "attach_orb"..orbNumber, caster:GetAbsOrigin(), false)
			else
				for i=1,3 do
					caster.orbs[i] = ParticleManager:CreateParticle("particles/custom/human/blood_mage/exort_orb.vpcf", PATTACH_OVERHEAD_FOLLOW, caster)
					ParticleManager:SetParticleControlEnt(caster.orbs[i], 1, caster, PATTACH_POINT_FOLLOW, "attach_orb"..i, caster:GetAbsOrigin(), false)
				end
			end
		end)
	end
end

function NoPointOrbThrow(event)
local caster = event.caster
local ability = event.ability
local point = caster:GetAbsOrigin() + Vector(0, 0, 1000)

	-- Remove first orb
	local orbNumber
	for i = 1, 3 do
		if caster.orbs[i] then
			ParticleManager:DestroyParticle(caster.orbs[i], true)
			caster.orbs[i] = nil
			orbNumber = i
			break
		end
	end

	-- Launch orb
	local speed = 900
	local orb = ParticleManager:CreateParticle("particles/units/heroes/hero_rubick/rubick_base_attack.vpcf", PATTACH_CUSTOMORIGIN, caster)
	ParticleManager:SetParticleControl(orb, 0, caster:GetAttachmentOrigin(caster:ScriptLookupAttachment("attach_attack1")))
	ParticleManager:SetParticleControl(orb, 1, point)
	ParticleManager:SetParticleControl(orb, 2, Vector(speed, 0, 0))
	ParticleManager:SetParticleControl(orb, 3, point)

	local distanceToTarget = (caster:GetAbsOrigin() - point):Length2D()
	Timers:CreateTimer(distanceToTarget/speed, function()
		ParticleManager:DestroyParticle(orb, false)
	end)

	-- Restore orb
	Timers:CreateTimer(1, function() 
		if orbNumber then
			caster.orbs[orbNumber] = ParticleManager:CreateParticle("particles/custom/human/blood_mage/exort_orb.vpcf", PATTACH_OVERHEAD_FOLLOW, caster)
			ParticleManager:SetParticleControlEnt(caster.orbs[orbNumber], 1, caster, PATTACH_POINT_FOLLOW, "attach_orb"..orbNumber, caster:GetAbsOrigin(), false)
		else
			for i=1,3 do
				caster.orbs[i] = ParticleManager:CreateParticle("particles/custom/human/blood_mage/exort_orb.vpcf", PATTACH_OVERHEAD_FOLLOW, caster)
				ParticleManager:SetParticleControlEnt(caster.orbs[i], 1, caster, PATTACH_POINT_FOLLOW, "attach_orb"..i, caster:GetAbsOrigin(), false)
			end
		end
	end)
end

function FlameStrikeStart(event)
local caster = event.caster
local point = event.target_points[1]
local ability = event.ability
local delay = ability:GetSpecialValueFor("delay")

	StartAnimation(caster, {duration = 1.0, activity = ACT_DOTA_CAST_TORNADO, rate = 1.0})

	local particle1 = ParticleManager:CreateParticle("particles/custom/human/blood_mage/invoker_sun_strike_team_immortal1.vpcf",PATTACH_CUSTOMORIGIN,caster)
	ParticleManager:SetParticleControl(particle1, 0, point)

	local particle2 = ParticleManager:CreateParticle("particles/econ/items/shadow_fiend/sf_fire_arcana/sf_fire_arcana_requiemofsouls_line_ground.vpcf",PATTACH_CUSTOMORIGIN,caster)
	ParticleManager:SetParticleControl(particle2, 0, point)

	local particle3 = ParticleManager:CreateParticle("particles/neutral_fx/black_dragon_fireball_lava_scorch.vpcf", PATTACH_CUSTOMORIGIN, nil)
	ParticleManager:SetParticleControl(particle3, 0, point)
	ParticleManager:SetParticleControl(particle3, 2, Vector(11,0,0))

	Timers:CreateTimer(delay, function()
		local flame_strike = CreateUnitByName("dummy_unit_invulnerable", point, false, caster, caster, caster:GetTeam())
		event.ability:ApplyDataDrivenModifier(caster, flame_strike, "modifier_flame_strike_thinker1", nil)
		Timers:CreateTimer(2.1, function()
			if IsValidEntity(flame_strike) then flame_strike:ForceKill(true) end
		end)
	end)
end

function FlameStrikeSecond(event)
local caster = event.caster
local origin = event.target:GetAbsOrigin()
local flame_strike = CreateUnitByName("dummy_unit_invulnerable", origin, false, caster, caster, caster:GetTeam())

	event.ability:ApplyDataDrivenModifier(caster, flame_strike, "modifier_flame_strike_thinker2", nil)
	Timers:CreateTimer(6.0, function()
		if IsValidEntity(flame_strike) then flame_strike:ForceKill(true) end
	end)
end

function FlameStrikeDamage(event)
local ability = event.ability
local caster = event.caster
local targets = event.target_entities
local damage = event.Damage

	if targets then
		for k,target in pairs(targets) do
			local damageDone = damage
			ApplyDamage({ victim = target, attacker = caster, damage = damageDone, ability = ability, damage_type = ability:GetAbilityDamageType() })
		end
	elseif event.target then
		local target = event.target
		local damageDone = damage
			ApplyDamage({ victim = target, attacker = caster, damage = damageDone, ability = ability, damage_type = ability:GetAbilityDamageType() })
	end 
end

function DragonSlave(keys)
local caster = keys.caster
local ability = keys.ability
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

	-- Launch projectile
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

function Incinerate(keys)
	if not keys.target:IsAlive() then
		local particleName = "particles/units/heroes/hero_sandking/sandking_caustic_finale_explode.vpcf"
		local soundEventName = "Ability.SandKing_CausticFinale"
		
		local fxIndex = ParticleManager:CreateParticle( particleName, PATTACH_ABSORIGIN, keys.target )
		StartSoundEvent( soundEventName, keys.target )
	end
end

function Phoenix( event )
	local caster = event.caster
	local fv = caster:GetForwardVector()
	local origin = caster:GetAbsOrigin()
	
	-- Gets the vector facing 200 units away from the caster origin
	local front_position = origin + fv * 200

	local result = { }
	table.insert(result, front_position)

	return result
end

-- Set the units looking at the same point of the caster
function SetPhoenixMoveForward( event )
local caster = event.caster -- The Blood Mage
local target = event.target -- The Phoenix
local fv = caster:GetForwardVector()
local origin = caster:GetAbsOrigin()
	
	target:SetForwardVector(fv)

	-- Keep reference to the phoenix
	caster.phoenix = target
	target:SetOwner(caster) --The Blood Mage has ownership over this, not the main hero
end

-- Kills the summoned units after a new spell start
function KillPhoenix( event )
local caster = event.caster
local phoenixes = FindUnitsInRadius(caster:GetTeamNumber(), Vector(0, 0, 0), nil, FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, 0, false)

	for _, v in pairs(phoenixes) do
		if v:GetUnitName() == "npc_dota_creature_phoenix" or v:GetUnitName() == "human_phoenix_egg" then
			v:RemoveSelf()
		end
	end
end

-- Deal self damage over time, through magic immunity. This is needed because negative HP regen is not working.
function PhoenixDegen(event)
local caster = event.caster
local ability = event.ability
local phoenix_damage_per_second = ability:GetLevelSpecialValueFor("phoenix_damage_per_second", ability:GetLevel() - 1)
local phoenixHP = caster:GetHealth()

	caster:SetHealth(phoenixHP - phoenix_damage_per_second)

	-- On Health 0 spawn an Egg (same as OnDeath)
	if caster:GetHealth() == 0 then
		PhoenixEgg(event)
	end
end

-- Removes the phoenix and spawns the egg with a timer
function PhoenixEgg( event )
	local caster = event.caster --the phoenix
	local ability = event.ability
	local hero = caster:GetOwner()
	local phoenix_egg_duration = ability:GetLevelSpecialValueFor( "phoenix_egg_duration", ability:GetLevel() - 1 )

	-- Set the position, a bit floating over the ground
	local origin = caster:GetAbsOrigin()
	local position = Vector(origin.x, origin.y, origin.z+50)

	local egg = CreateUnitByName("human_phoenix_egg", origin, true, hero, hero, hero:GetTeamNumber())
	egg:SetAbsOrigin(position)

	-- Keep reference to the egg
	hero.egg = egg

	-- Apply modifiers for the summon properties
	egg:AddNewModifier(hero, ability, "modifier_kill", {duration = phoenix_egg_duration})

	-- Remove the phoenix
	caster:RemoveSelf()
end

-- Check if the egg died from an attacker other than the time-out
function PhoenixEggCheckReborn( event )
	local unit = event.unit --the egg
	local attacker = event.attacker
	local ability = event.ability
	local hero = unit:GetOwner()
	local player = hero:GetPlayerOwner()
	local playerID = hero:GetPlayerID()

	if unit == attacker then
		local phoenix = CreateUnitByName("npc_dota_creature_phoenix", unit:GetAbsOrigin(), true, player, hero, hero:GetTeamNumber())
		phoenix:SetControllableByPlayer(playerID, true)

		-- Keep reference
		hero.egg = egg
	else
		local particleName = "particles/units/heroes/hero_phoenix/phoenix_supernova_death.vpcf"
		local particle = ParticleManager:CreateParticle(particleName, PATTACH_CUSTOMORIGIN, unit)
		ParticleManager:SetParticleControl(particle, 0, unit:GetAbsOrigin())
		ParticleManager:SetParticleControl(particle, 1, unit:GetAbsOrigin())
		ParticleManager:SetParticleControl(particle, 3, unit:GetAbsOrigin())
	end

	-- Remove the egg
	unit:RemoveSelf()
end

function RainOfFire(keys)
local caster = keys.caster
local ability = keys.ability
local radius = ability:GetLevelSpecialValueFor("radius", ability:GetLevel()-1)
local radius_explosion = ability:GetLevelSpecialValueFor("radius_explosion", ability:GetLevel() -1)
local damage_per_unit = ability:GetLevelSpecialValueFor("damage_per_unit", ability:GetLevel()-1)
local stun_duration = ability:GetLevelSpecialValueFor("stun_duration", ability:GetLevel()-1)
local delay = ability:GetLevelSpecialValueFor("delay", ability:GetLevel()-1)
local explode_time = ability:GetLevelSpecialValueFor("time_between_explosions", ability:GetLevel()-1)
local sunstrike_number = ability:GetLevelSpecialValueFor("number_of_unit", ability:GetLevel()-1)
local sunstrikes = 1

	StartAnimation(caster, {duration = 1.0, activity = ACT_DOTA_CAST_TORNADO, rate = 1.0})

	Timers:CreateTimer(0.0, function()
		caster:EmitSound("Hero_Invoker.SunStrike.Charge")
		local point = caster:GetAbsOrigin() + RandomInt(1,radius-(math.floor(radius_explosion/2.0)))*RandomVector(1)
		local units = FindUnitsInRadius(caster:GetTeam(), point, nil, radius_explosion, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO , DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_CLOSEST, false)

		local sunstrike = ParticleManager:CreateParticle("particles/custom/human/blood_mage/invoker_sun_strike_team_immortal1.vpcf",PATTACH_CUSTOMORIGIN,caster)
		ParticleManager:SetParticleControl(sunstrike, 0, point)
		local suntrike_inner = ParticleManager:CreateParticle("particles/econ/items/shadow_fiend/sf_fire_arcana/sf_fire_arcana_requiemofsouls_line_ground.vpcf",PATTACH_CUSTOMORIGIN,caster)
		ParticleManager:SetParticleControl(suntrike_inner, 0, point)
		local sunstrike_outer = ParticleManager:CreateParticle("particles/neutral_fx/black_dragon_fireball_lava_scorch.vpcf", PATTACH_CUSTOMORIGIN, nil)
		ParticleManager:SetParticleControl(sunstrike_outer, 0, point)
		ParticleManager:SetParticleControl(sunstrike_outer, 2, Vector(11,0,0))

		Timers:CreateTimer(delay, function()
			local sunstrike = ParticleManager:CreateParticle("particles/econ/items/invoker/invoker_apex/invoker_sun_strike_immortal1.vpcf", PATTACH_CUSTOMORIGIN, caster)
			ParticleManager:SetParticleControl(sunstrike, 0, point)
			caster:EmitSound("Hero_Invoker.SunStrike.Ignite")
		end)

		for _, unit in pairs(units) do
			Timers:CreateTimer(delay, function()
				ApplyDamage({victim = unit, attacker = caster, damage = damage_per_unit, damage_type = DAMAGE_TYPE_MAGICAL})
				unit:AddNewModifier(caster, nil, "modifier_stunned", {duration = stun_duration})
			end)
		end

		if sunstrikes < sunstrike_number then
			sunstrikes = sunstrikes +1
			return explode_time
		else
			return nil
		end
	end)
end

function AttachOrbs( event )
	local hero = event.caster
	local origin = hero:GetAbsOrigin()
	local particleName = "particles/custom/human/blood_mage/exort_orb.vpcf"

	hero.orbs = {}

	for i = 1, 3 do
		hero.orbs[i] = ParticleManager:CreateParticle(particleName, PATTACH_OVERHEAD_FOLLOW, hero)
		ParticleManager:SetParticleControlEnt(hero.orbs[i], 1, hero, PATTACH_POINT_FOLLOW, "attach_orb"..i, origin, false)
	end
end

function RemoveOrbs(event)
	local hero = event.caster

	if hero and IsValidEntity(hero) and not hero:IsNull() then
		for i = 1, 3 do
			if hero.orbs and hero.orbs[i] then
				ParticleManager:DestroyParticle(hero.orbs[i], false)
			end
		end

		hero.orbs = {}
	end
end
