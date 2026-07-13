local MONSOON_CAST_GESTURE = ACT_DOTA_CAST_ABILITY_4

local function IsValidMonsoonEntity(entity)
	return entity ~= nil and IsValidEntity(entity)
end

local function DestroyMonsoonParticle(caster, immediate)
	if caster.freezing_field_particle == nil then
		return
	end

	ParticleManager:DestroyParticle(caster.freezing_field_particle, immediate == true)
	ParticleManager:ReleaseParticleIndex(caster.freezing_field_particle)
	caster.freezing_field_particle = nil
end

local function CleanupFreezingField(caster, immediate)
	if not IsValidMonsoonEntity(caster) then
		return
	end

	local center = caster.freezing_field_center
	if IsValidMonsoonEntity(center) then
		center:StopSound("Hero_Razor.Storm.Cast")
		center:StopSound("Hero_Razor.Storm.Loop")
		center:StopSound("Hero_Zuus.LightningBolt.Cast.Righteous")
		UTIL_Remove(center)
	end

	DestroyMonsoonParticle(caster, immediate)
	caster.freezing_field_center = nil
	caster:FadeGesture(MONSOON_CAST_GESTURE)
end

local function IsCurrentFreezingField(caster, center, ability)
	return IsValidMonsoonEntity(caster)
		and IsValidMonsoonEntity(center)
		and ability ~= nil
		and not ability:IsNull()
		and caster.freezing_field_center == center
end

function FreezingFieldCast(keys)
	local caster = keys.caster
	local ability = keys.ability
	local modifier_aura = keys.modifier_aura
	local modifier_sector_0 = keys.modifier_sector_0
	local modifier_sector_1 = keys.modifier_sector_1
	local modifier_sector_2 = keys.modifier_sector_2
	local modifier_sector_3 = keys.modifier_sector_3

	caster:StartGesture(MONSOON_CAST_GESTURE)

	-- Defines the center point (caster or dummy unit)
	caster.freezing_field_center = CreateUnitByName("dummy_unit_invulnerable", keys.target_points[1], false, nil, nil, caster:GetTeamNumber())
	caster.freezing_field_center:AddNewModifier(caster.freezing_field_center, nil, "modifier_invulnerable", {})
	caster.freezing_field_particle = ParticleManager:CreateParticle("particles/units/heroes/hero_razor_reduced_flash/razor_rain_storm_reduced_flash.vpcf", PATTACH_CUSTOMORIGIN, caster.freezing_field_center)
	ParticleManager:SetParticleControl(caster.freezing_field_particle, 0, keys.target_points[1])
	ParticleManager:SetParticleControl(caster.freezing_field_particle, 1, Vector(1000, 0, 0))
	ParticleManager:SetParticleControl(caster.freezing_field_particle, 5, Vector(1000, 0, 0))

	--	StartAnimation(caster, {activity = ACT_DOTA_CAST_ABILITY_4, rate = 0.7})

	caster.freezing_field_center:EmitSound("Hero_Razor.Storm.Cast")

	-- Grants the slowing aura to the center unit
	ability:ApplyDataDrivenModifier(caster, caster.freezing_field_center, modifier_aura, {})

	local center = caster.freezing_field_center

	-- Initializes each sector's thinkers
	Timers:CreateTimer(0.1, function()
		if IsCurrentFreezingField(caster, center, ability) then
			ability:ApplyDataDrivenModifier(caster, center, modifier_sector_0, {})
		end
	end)

	Timers:CreateTimer(0.2, function()
		if IsCurrentFreezingField(caster, center, ability) then
			ability:ApplyDataDrivenModifier(caster, center, modifier_sector_1, {})
		end
	end)

	Timers:CreateTimer(0.3, function()
		if IsCurrentFreezingField(caster, center, ability) then
			ability:ApplyDataDrivenModifier(caster, center, modifier_sector_2, {})
		end
	end)

	Timers:CreateTimer(0.4, function()
		if IsCurrentFreezingField(caster, center, ability) then
			ability:ApplyDataDrivenModifier(caster, center, modifier_sector_3, {})
		end
	end)

	Timers:CreateTimer(20.0, function()
		if IsValidMonsoonEntity(caster) and caster.freezing_field_center == center then
			CleanupFreezingField(caster, false)
		elseif IsValidMonsoonEntity(center) then
			UTIL_Remove(center)
		end
	end)
end

function FreezingFieldExplode(keys)
	if not keys or not IsValidMonsoonEntity(keys.caster) then
		return
	end

	if not IsValidMonsoonEntity(keys.caster.freezing_field_center) then
		return
	end

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
	local castDistance = RandomInt(min_distance, max_distance)
	local angle = RandomInt(0, 90)
	local dy = castDistance * math.sin(angle)
	local dx = castDistance * math.cos(angle)
	local attackPoint = Vector(0, 0, 0)

	if direction_constraint == 0 then  -- NW
		attackPoint = Vector(target_loc.x - dx, target_loc.y + dy, target_loc.z)
	elseif direction_constraint == 1 then -- NE
		attackPoint = Vector(target_loc.x + dx, target_loc.y + dy, target_loc.z)
	elseif direction_constraint == 2 then -- SE
		attackPoint = Vector(target_loc.x + dx, target_loc.y - dy, target_loc.z)
	else                               -- SW
		attackPoint = Vector(target_loc.x - dx, target_loc.y - dy, target_loc.z)
	end

	-- Loop through units
	local units = FindUnitsInRadius(caster:GetTeam(), attackPoint, nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, 0, 0, false)

	for _, v in pairs(units) do
		ApplyDamage({ victim = v, attacker = caster, ability = ability, damage = damage, damage_type = ability:GetAbilityDamageType() })
	end

	-- Create particle/sound dummy unit
	local explosion_dummy = CreateUnitByName("dummy_unit_invulnerable", attackPoint, false, nil, nil, caster:GetTeamNumber())

	-- Fire effect
	local fxIndex = ParticleManager:CreateParticle(particle_name, PATTACH_CUSTOMORIGIN, explosion_dummy)
	ParticleManager:SetParticleControl(fxIndex, 0, attackPoint)

	-- Fire sound at the center position
	explosion_dummy:EmitSound(sound_name)

	ParticleManager:ReleaseParticleIndex(fxIndex)

	Timers:CreateTimer(9.0, function()
		if IsValidMonsoonEntity(explosion_dummy) then
			UTIL_Remove(explosion_dummy)
		end
	end)
end

function FreezingFieldStopSound(keys)
	if not keys or not IsValidMonsoonEntity(keys.caster) then return end
	local caster = keys.caster
	local ability = keys.ability
	local modifier_aura = keys.modifier_aura
	local modifier_caster = keys.modifier_caster
	local modifier_NE = keys.modifier_NE
	local modifier_NW = keys.modifier_NW
	local modifier_SW = keys.modifier_SW
	local modifier_SE = keys.modifier_SE

	-- Removes auras and modifiers
	caster:RemoveModifierByName(modifier_caster)
	caster:RemoveModifierByName(modifier_aura)
	caster:RemoveModifierByName(modifier_NE)
	caster:RemoveModifierByName(modifier_NW)
	caster:RemoveModifierByName(modifier_SW)
	caster:RemoveModifierByName(modifier_SE)

	CleanupFreezingField(caster, true)
end

function FreezingFieldEnd(keys)
	if not keys or not IsValidMonsoonEntity(keys.caster) then return end
	local caster = keys.caster
	local ability = keys.ability
	local modifier_aura = keys.modifier_aura
	local modifier_caster = keys.modifier_caster
	local modifier_NE = keys.modifier_NE
	local modifier_NW = keys.modifier_NW
	local modifier_SW = keys.modifier_SW
	local modifier_SE = keys.modifier_SE

	-- Removes auras and modifiers
	caster:RemoveModifierByName(modifier_caster)
	caster:RemoveModifierByName(modifier_aura)
	caster:RemoveModifierByName(modifier_NE)
	caster:RemoveModifierByName(modifier_NW)
	caster:RemoveModifierByName(modifier_SW)
	caster:RemoveModifierByName(modifier_SE)

	CleanupFreezingField(caster, false)
end
