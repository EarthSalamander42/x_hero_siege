require("libraries/timers")

-- IMBA Shadowraze Function!
function ShadowrazeCreateRaze(keys, point, radius, particle_raze)
local caster = keys.caster
local ability = keys.ability
local ability_level = ability:GetLevel() - 1
local sound_raze = keys.sound_raze
local damage = ability:GetLevelSpecialValueFor("raze_damage", ability_level)
local damage_type = ability:GetAbilityDamageType()

	-- Raze particle
	local raze_pfx = ParticleManager:CreateParticle(particle_raze, PATTACH_CUSTOMORIGIN, nil)
	ParticleManager:SetParticleControl(raze_pfx, 0, point)
	ParticleManager:SetParticleControl(raze_pfx, 1, point)
	ParticleManager:ReleaseParticleIndex(raze_pfx)

	-- Raze sound (on dummy)
	local dummy = CreateUnitByName("npc_dummy_unit", point, false, nil, nil, caster:GetTeamNumber())
	dummy:EmitSound(sound_raze)
	dummy:Destroy()

	-- Find raze targets hit
	local enemies = FindUnitsInRadius(caster:GetTeam(), point, nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
	for _, enemy in pairs(enemies) do

		-- Apply damage AFTER combo check to allow combos on heroes that die from the raze damage
		ApplyDamage({attacker = caster, victim = enemy, ability = ability, damage = damage, damage_type = damage_type})
	end
end

function Shadowraze3Cast(keys)
local caster = keys.caster
local ability = keys.ability
local ability_level = ability:GetLevel() - 1
local radius = ability:GetLevelSpecialValueFor("shadowraze_radius", ability_level)
local distance1 = ability:GetLevelSpecialValueFor("shadowraze_range1", ability_level)
local distance2 = ability:GetLevelSpecialValueFor("shadowraze_range2", ability_level)
local distance3 = ability:GetLevelSpecialValueFor("shadowraze_range3", ability_level)
local raze_amount = ability:GetLevelSpecialValueFor("raze_amount", ability_level)
local raze_particles = "particles/econ/items/shadow_fiend/sf_fire_arcana/sf_fire_arcana_shadowraze.vpcf"	--particles/hero/nevermore/nevermore_shadowraze_150.vpcf

	local caster_loc = caster:GetAbsOrigin()
	local forward_vector = caster:GetForwardVector()
	local hero_hit = true
	raze_point1 = caster_loc + forward_vector * distance1
	raze_point2 = caster_loc + forward_vector * distance2
	raze_point3 = caster_loc + forward_vector * distance3

	hero_hit = ShadowrazeCreateRaze(keys, raze_point1, radius, raze_particles) or hero_hit
	Timers:CreateTimer(0.2, function()
		hero_hit = ShadowrazeCreateRaze(keys, raze_point2, radius, raze_particles) or hero_hit
	end)
	Timers:CreateTimer(0.4, function()
		hero_hit = ShadowrazeCreateRaze(keys, raze_point3, radius, raze_particles) or hero_hit
	end)
end

-- IMBA Octarine Core
function ConsumingFlame(keys)
local caster = keys.caster
local target = keys.unit
local ability = keys.ability
local ability_level = ability:GetLevel() - 1
local damage = keys.damage
local particle_lifesteal = keys.particle_lifesteal
local modifier_prevent = keys.modifier_prevent
local hero_lifesteal = ability:GetLevelSpecialValueFor("hero_lifesteal", ability_level)
local creep_lifesteal = ability:GetLevelSpecialValueFor("creep_lifesteal", ability_level)

	-- If there's no valid target, do nothing
	if target:IsBuilding() or target:IsTower() or target == caster or target:HasModifier(modifier_prevent) or target:IsIllusion() then
		return nil
	end

	-- Play the particle
	local lifesteal_fx = ParticleManager:CreateParticle(particle_lifesteal, PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleControl(lifesteal_fx, 0, caster:GetAbsOrigin())
	ParticleManager:ReleaseParticleIndex(lifesteal_fx)

	-- Delay the lifesteal for one game tick to prevent blademail/octarine interaction
	Timers:CreateTimer(0.01, function()
		
		-- If the target is a real hero, heal for the full value
		if target:IsRealHero() or target:IsConsideredHero() then
			caster:Heal(damage * hero_lifesteal / 100, caster)
		-- else, heal for the reduced value
		else
			caster:Heal(damage * creep_lifesteal / 100, caster)
		end
	end)
end

function ConsumingFlameAttack(keys)
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability
	local modifier_prevent = keys.modifier_prevent

	-- Applies the lifesteal-prevention modifier
	ability:ApplyDataDrivenModifier(caster, target, modifier_prevent, {})
end

function Stitch(event)
	local caster = event.caster
	local ability = event.ability
	local playerID = caster:GetPlayerOwnerID()
	local hero = PlayerResource:GetSelectedHeroEntity(playerID)
	local team = caster:GetTeamNumber()
	local duration = ability:GetLevelSpecialValueFor("duration", ability:GetLevel() -1)
	local radius = ability:GetLevelSpecialValueFor("radius", ability:GetLevel() -1)
	local max_units_resurrected = ability:GetLevelSpecialValueFor("max_units_resurrected", ability:GetLevel() - 1)

	-- Find all corpse entities in the radius and start the counter of units resurrected.
	local corpses = Corpses:FindInRadius(playerID, caster:GetAbsOrigin(), radius)
	local units_resurrected = 0

	-- Go through the units
	for _, corpse in pairs(corpses) do
		if units_resurrected < max_units_resurrected then
			-- The corpse has a unit_name associated.
			local unit = CreateUnitByName(corpse.unit_name, corpse:GetAbsOrigin(), true, caster, caster, team)
			unit:SetControllableByPlayer(playerID, true)
			unit:SetOwner(hero)
			unit:SetForwardVector(corpse:GetForwardVector())
			FindClearSpaceForUnit(corpse, corpse:GetAbsOrigin(), true)

			-- Apply modifiers for the summon properties
			unit:AddNewModifier(caster, ability, "modifier_kill", {duration = duration})
			unit:AddNewModifier(unit, nil, "modifier_phased", {})

			-- Remove non-passive abilities
			for i = 0, 15 do
				local a = unit:GetAbilityByIndex(i)
				if a and not a:IsPassive() then
--					UTIL_Remove(a)
					a:SetActivated(false)
				end
			end

			-- Leave no corpses
			unit:SetNoCorpse()
			corpse:RemoveCorpse()

			-- Increase the counter of units resurrected
			units_resurrected = units_resurrected + 1
		end
	end
end
