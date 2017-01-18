function FanOfRockets( keys )
local caster			= keys.caster
local ability			= keys.ability
local particleName		= "particles/econ/items/clockwerk/clockwerk_paraflare/clockwerk_para_rocket_flare.vpcf"
local modifierDudName	= "modifier_fan_of_rockets_dud"
local projectileSpeed	= 850
local radius			= ability:GetLevelSpecialValueFor("radius", ability:GetLevel() - 1)
local max_targets		= ability:GetLevelSpecialValueFor("targets", ability:GetLevel() - 1)
local targetTeam		= ability:GetAbilityTargetTeam()
local targetType		= ability:GetAbilityTargetType()
local targetFlag		= ability:GetAbilityTargetFlags() -- DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_NO_INVIS + DOTA_UNIT_TARGET_FLAG_NOT_ILLUSIONS
local projectileDodgable = false
local projectileProvidesVision = false

	-- pick up x nearest target heroes and create tracking projectile targeting the number of targets
	local units = FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), caster, radius, targetTeam, targetType, targetFlag, FIND_CLOSEST, false)

	-- Seek out target
	local count = 0
	for k, v in pairs( units ) do
		if count < max_targets then
			local projTable = {
				Target = v,
				Source = caster,
				Ability = ability,
				EffectName = particleName,
				bDodgeable = projectileDodgable,
				bProvidesVision = projectileProvidesVision,
				iMoveSpeed = projectileSpeed, 
				vSpawnOrigin = caster:GetAbsOrigin()
			}
			ProjectileManager:CreateTrackingProjectile( projTable )
			count = count + 1
		else
			break
		end
	end

	-- If no unit is found, fire dud
	if count == 0 then
		ability:ApplyDataDrivenModifier( caster, caster, modifierDudName, {} )
	end
end

function FanOfRocketsExplode( keys )
local caster = keys.target
local ability = keys.ability
local radius = ability:GetLevelSpecialValueFor("radius", ability:GetLevel() - 1)
local point = caster:GetAbsOrigin() + RandomInt(1, radius - (math.floor(400 / 2.0))) * RandomVector(1)

	local rocket = ParticleManager:CreateParticle("particles/econ/items/clockwerk/clockwerk_paraflare/clockwerk_para_rocket_flare_explosion.vpcf", PATTACH_CUSTOMORIGIN, caster)
	ParticleManager:SetParticleControl(rocket, 3, point + Vector(0, 0, 128))
end

function Clone( keys )
local caster = keys.caster
local target = keys.target
local player = caster:GetPlayerOwnerID()
local ability = keys.ability
local ability_level = ability:GetLevel() - 1
local unit_name = target:GetUnitName()
local duration = ability:GetLevelSpecialValueFor( "illusion_duration", ability_level )
local outgoingDamage = ability:GetLevelSpecialValueFor( "outgoing_damage", ability_level )
local incomingDamage = ability:GetLevelSpecialValueFor( "incoming_damage", ability_level )

	-- Initialize the illusion table to keep track of the units created by the spell
	if not caster.clones then
		caster.clones = {}
	end

	-- Kill the old images
	for k,v in pairs(caster.clones) do
		if v and IsValidEntity(v) then 
			v:ForceKill(false)
		end
	end

	-- Start a clean illusion table
	caster.clones = {}

	-- handle_UnitOwner needs to be nil, else it will crash the game.
	local illusion = CreateUnitByName(unit_name, caster:GetAbsOrigin()+150*caster:GetForwardVector()+RandomVector(RandomInt(0, 50)), true, caster, nil, caster:GetTeamNumber())
	illusion:SetControllableByPlayer(player, true)

		-- Level Up the unit to the casters level
	local casterLevel = target:GetLevel()
	for i=1,casterLevel-1 do
		illusion:HeroLevelUp(false)
	end

	illusion:SetBaseStrength(target:GetBaseStrength())
	illusion:SetBaseIntellect(target:GetBaseIntellect())
	illusion:SetBaseAgility(target:GetBaseAgility())

	-- Set the skill points to 0 and learn the skills of the caster
	illusion:SetAbilityPoints(0)
	for abilitySlot=0,15 do
		local ability = target:GetAbilityByIndex(abilitySlot)
		if ability ~= nil then 
			local abilityLevel = ability:GetLevel()
			local abilityName = ability:GetAbilityName()
			local illusionAbility = illusion:FindAbilityByName(abilityName)
			if IsValidEntity(illusionAbility) then
				illusionAbility:SetLevel(abilityLevel)
			end
		end
	end

	-- Recreate the items of the caster
	for itemSlot=0,5 do
		local item = target:GetItemInSlot(itemSlot)
		if item ~= nil and item:GetName() ~= "item_cloak_of_immolation" then
			local itemName = item:GetName()
			local newItem = CreateItem(itemName, illusion, illusion)
			illusion:AddItem(newItem)
		end
	end

	illusion:AddNewModifier(caster, ability, "modifier_illusion", { duration = duration, outgoing_damage = outgoingDamage, incoming_damage = incomingDamage })
	illusion:MakeIllusion()
	illusion:SetHealth(target:GetHealth())
	illusion:SetPlayerID(caster:GetPlayerOwnerID())
	-- Add the illusion created to a table within the caster handle, to remove the illusions on the next cast if necessary
	table.insert(caster.clones, illusion)
end

function ClusterRockets(keys)
local caster = keys.caster
local target = keys.target
local ability = keys.ability
local radius = ability:GetLevelSpecialValueFor("radius", ability:GetLevel() -1)
local radius_explosion = ability:GetLevelSpecialValueFor("radius_explosion", ability:GetLevel() -1)
local damage_per_unit = ability:GetLevelSpecialValueFor("damage_per_unit", ability:GetLevel() -1)
local stun_duration = ability:GetLevelSpecialValueFor("stun_duration", ability:GetLevel() -1)
local explosions_per_tick = ability:GetLevelSpecialValueFor("explosions_per_tick", ability:GetLevel() -1)
local delay = ability:GetLevelSpecialValueFor("delay", ability:GetLevel() -1)
local particleEffect = keys.particleEffect

	for i = 1, explosions_per_tick do
		local point = target:GetAbsOrigin() + RandomInt(1, radius - (math.floor(radius_explosion / 2.0))) * RandomVector(1)
		Timers:CreateTimer(delay, function()
			local units = FindUnitsInRadius(target:GetTeam(), point, nil, radius_explosion, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO , DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_CLOSEST, false)
			for _,unit in pairs(units) do
				ApplyDamage({victim = unit, attacker = target, damage = damage_per_unit, damage_type = DAMAGE_TYPE_MAGICAL})
				unit:AddNewModifier(target, nil, "modifier_stunned", {duration = stun_duration})
			end
		end)

		local rockets = ParticleManager:CreateParticle(particleEffect, PATTACH_CUSTOMORIGIN, caster)
		local distance = caster:GetAbsOrigin() - point
		distance = distance:Length2D()
		distance = math.min(distance, 800)
		distance = math.max(distance, 100)
		local factor = (distance -100) / 700.0
		ParticleManager:SetParticleControl(rockets, 0, caster:GetAbsOrigin() + Vector(0,0,64))
		ParticleManager:SetParticleControl(rockets, 1, point)
		ParticleManager:SetParticleControl(rockets, 3, Vector(delay + factor * 0.7, 0, 0))
	end
end
