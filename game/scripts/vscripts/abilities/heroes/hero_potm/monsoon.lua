function FreezingFieldCast( keys )
local caster = keys.caster
local ability = keys.ability
local modifier_aura = keys.modifier_aura
local modifier_sector_0 = keys.modifier_sector_0
local modifier_sector_1 = keys.modifier_sector_1
local modifier_sector_2 = keys.modifier_sector_2
local modifier_sector_3 = keys.modifier_sector_3

	caster:StartGesture(ACT_DOTA_TELEPORT)

	-- Defines the center point (caster or dummy unit)
	caster.freezing_field_center = CreateUnitByName("dummy_unit_invulnerable", keys.target_points[1], false, nil, nil, caster:GetTeamNumber())
	caster.freezing_field_center:AddNewModifier(nil, nil, "modifier_invulnerable", {})
	caster.freezing_field_particle = ParticleManager:CreateParticle("particles/units/heroes/hero_razor_reduced_flash/razor_rain_storm_reduced_flash.vpcf", PATTACH_CUSTOMORIGIN, caster.freezing_field_center)
	ParticleManager:SetParticleControl(caster.freezing_field_particle, 0, keys.target_points[1])
	ParticleManager:SetParticleControl(caster.freezing_field_particle, 1, Vector (1000, 0, 0))
	ParticleManager:SetParticleControl(caster.freezing_field_particle, 5, Vector (1000, 0, 0))

--	StartAnimation(caster, {activity = ACT_DOTA_CAST_ABILITY_4, rate = 0.7})

	caster.freezing_field_center:EmitSound("Hero_Razor.Storm.Cast")

	-- Grants the slowing aura to the center unit
	ability:ApplyDataDrivenModifier(caster, caster.freezing_field_center, modifier_aura, {})

	-- Initializes each sector's thinkers
	Timers:CreateTimer(0.1, function()
		ability:ApplyDataDrivenModifier(caster, caster.freezing_field_center, modifier_sector_0, {} )
	end)
		
	Timers:CreateTimer(0.2, function()
		ability:ApplyDataDrivenModifier(caster, caster.freezing_field_center, modifier_sector_1, {} )
	end)
	
	Timers:CreateTimer(0.3, function()
		ability:ApplyDataDrivenModifier(caster, caster.freezing_field_center, modifier_sector_2, {} )
	end)
	
	Timers:CreateTimer(0.4, function()
		ability:ApplyDataDrivenModifier(caster, caster.freezing_field_center, modifier_sector_3, {} )
	end)

	Timers:CreateTimer(20.0, function()
		UTIL_Remove(caster.freezing_field_center)
	end)
end

function FreezingFieldExplode( keys )
	if not keys.caster or not keys.caster.freezing_field_center or keys.caster.freezing_field_center and not IsValidEntity(keys.caster.freezing_field_center) then return end

	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1
	local caster = keys.caster
	local target_loc = caster.freezing_field_center:GetAbsOrigin()
	local min_distance = ability:GetLevelSpecialValueFor("explosion_min_dist", ability_level)
	local max_distance = ability:GetLevelSpecialValueFor("explosion_max_dist", ability_level)
	local radius = ability:GetLevelSpecialValueFor("explosion_radius", ability_level)
	local direction_constraint = keys.section
	local particle_name = "particles/econ/items/mirana/mirana_starstorm_bow/mirana_starstorm_starfall_attack.vpcf"
	local sound_name = "Hero_Zuus.LightningBolt.Cast.Righteous"
	local damage = ability:GetLevelSpecialValueFor("damage", ability_level)

	-- Get random point
	local castDistance = RandomInt( min_distance, max_distance )
	local angle = RandomInt( 0, 90 )
	local dy = castDistance * math.sin( angle )
	local dx = castDistance * math.cos( angle )
	local attackPoint = Vector( 0, 0, 0 )

	if direction_constraint == 0 then			-- NW
		attackPoint = Vector( target_loc.x - dx, target_loc.y + dy, target_loc.z )
	elseif direction_constraint == 1 then		-- NE
		attackPoint = Vector( target_loc.x + dx, target_loc.y + dy, target_loc.z )
	elseif direction_constraint == 2 then		-- SE
		attackPoint = Vector( target_loc.x + dx, target_loc.y - dy, target_loc.z )
	else										-- SW
		attackPoint = Vector( target_loc.x - dx, target_loc.y - dy, target_loc.z )
	end
	
	-- Loop through units
	local units = FindUnitsInRadius(caster:GetTeam(), attackPoint, nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, 0, 0, false)

	for _,v in pairs( units ) do
		ApplyDamage({victim = v, attacker = caster, ability = ability, damage = damage, damage_type = ability:GetAbilityDamageType()})
	end

	-- Create particle/sound dummy unit
	local explosion_dummy = CreateUnitByName("dummy_unit_invulnerable", attackPoint, false, nil, nil, caster:GetTeamNumber())
	
	-- Fire effect
	local fxIndex = ParticleManager:CreateParticle(particle_name, PATTACH_CUSTOMORIGIN, explosion_dummy)
	ParticleManager:SetParticleControl(fxIndex, 0, attackPoint)
	
	-- Fire sound at the center position
	explosion_dummy:EmitSound(sound_name)

	-- Destroy dummy
	explosion_dummy:IsNull()

	Timers:CreateTimer(9.0, function()
		for _,v in pairs(explosion_dummy) do
			UTIL_Remove(explosion_dummy)
		end
	end)
end

function FreezingFieldStopSound( keys )
	if not keys.caster or not keys.caster.freezing_field_center then return end
	local caster = keys.caster
	local ability = keys.ability
	local modifier_aura = keys.modifier_aura
	local modifier_caster = keys.modifier_caster
	local modifier_NE = keys.modifier_NE
	local modifier_NW = keys.modifier_NW
	local modifier_SW = keys.modifier_SW
	local modifier_SE = keys.modifier_SE

	-- Stop playing sounds
	caster.freezing_field_center:StopSound("Hero_Razor.Storm.Cast")
	caster.freezing_field_center:StopSound("Hero_Razor.Storm.Loop")
	caster.freezing_field_center:StopSound("Hero_Zuus.LightningBolt.Cast.Righteous")

	-- Stop animation
	--EndAnimation(caster)

	-- Removes auras and modifiers
	caster:RemoveModifierByName(modifier_caster)
	caster:RemoveModifierByName(modifier_aura)
	caster:RemoveModifierByName(modifier_NE)
	caster:RemoveModifierByName(modifier_NW)
	caster:RemoveModifierByName(modifier_SW)
	caster:RemoveModifierByName(modifier_SE)

	-- Destroy center particle
	ParticleManager:DestroyParticle(caster.freezing_field_particle, true)

	-- Resets the center position
	caster.freezing_field_center = nil
	caster.freezing_field_particle = nil

	caster:FadeGesture(ACT_DOTA_TELEPORT)
end

function FreezingFieldEnd( keys )
	local caster = keys.caster
	local ability = keys.ability
	local modifier_aura = keys.modifier_aura
	local modifier_caster = keys.modifier_caster
	local modifier_NE = keys.modifier_NE
	local modifier_NW = keys.modifier_NW
	local modifier_SW = keys.modifier_SW
	local modifier_SE = keys.modifier_SE
	
	-- Removes auras and modifiers
	caster.freezing_field_center:IsNull()
	caster:RemoveModifierByName(modifier_caster)
	caster:RemoveModifierByName(modifier_aura)
	caster:RemoveModifierByName(modifier_NE)
	caster:RemoveModifierByName(modifier_NW)
	caster:RemoveModifierByName(modifier_SW)
	caster:RemoveModifierByName(modifier_SE)
	
	-- Destroy center particle
	ParticleManager:DestroyParticle(caster.freezing_field_particle, false)
	
	-- Resets the center position
	caster.freezing_field_center = nil
	caster.freezing_field_particle = nil

	caster:FadeGesture(ACT_DOTA_TELEPORT)
end
