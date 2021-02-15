require("libraries/timers")

function LifeSteal( keys )
local caster = keys.caster
local ability = keys.ability
local ability_level = ability:GetLevel() - 1
local cooldown = ability:GetCooldown(ability_level)

	if ability:IsCooldownReady() then
		ability:StartCooldown(cooldown)
		caster:EmitSound("Hero_LifeStealer.OpenWounds.Cast")
		caster:Heal(caster:GetAttackDamage() * ability:GetSpecialValueFor("lifesteal") / 100, caster)
		SendOverheadEventMessage(nil, OVERHEAD_ALERT_HEAL, caster, caster:GetAttackDamage() * ability:GetSpecialValueFor("lifesteal") / 100, nil)

		local lifesteal_pfx = ParticleManager:CreateParticle("particles/generic_gameplay/generic_lifesteal.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
		ParticleManager:SetParticleControl(lifesteal_pfx, 0, caster:GetAbsOrigin())
		ParticleManager:ReleaseParticleIndex(lifesteal_pfx)
	end
end

function KoboldArmy( keys )
local caster = keys.caster
local player = caster:GetPlayerOwnerID()
local ability = keys.ability
local unit_name = caster:GetUnitName()
local kobold_count = ability:GetLevelSpecialValueFor("kobold_count", (ability:GetLevel() - 1))
local duration = ability:GetLevelSpecialValueFor("duration", (ability:GetLevel() - 1))
local casterOrigin = caster:GetAbsOrigin()
local casterAngles = caster:GetAngles()

	-- Stop any actions of the caster otherwise its obvious which unit is real
	caster:Stop()

	-- Initialize the illusion table to keep track of the units created by the spell
	if not caster.kobold_super_illusions then
		caster.kobold_super_illusions = {}
	end

	-- Kill the old images
	for k,v in pairs(caster.kobold_super_illusions) do
		if v and IsValidEntity(v) then 
			v:ForceKill(false)
		end
	end

	-- Start a clean illusion table
	caster.kobold_super_illusions = {}

	-- Setup a table of potential spawn positions
	local vRandomSpawnPos = {
		Vector( 72, 0, 0 ),		-- North
		Vector( 0, 72, 0 ),		-- East
		Vector( -72, 0, 0 ),	-- South
		Vector( 72, -72, 0 ),	-- West
		Vector( -72, -72, 0 ),	-- West
		Vector( -72, 0, 72 ),	-- West
	}

	for i = #vRandomSpawnPos, 2, -1 do	-- Simply shuffle them
		local j = RandomInt( 1, i )
		vRandomSpawnPos[i], vRandomSpawnPos[j] = vRandomSpawnPos[j], vRandomSpawnPos[i]
	end

	-- Insert the center position and make sure that at least one of the units will be spawned on there.
	table.insert( vRandomSpawnPos, RandomInt( 1, kobold_count ), Vector( 0, 0, 0 ) )

	-- At first, move the main hero to one of the random spawn positions.
	FindClearSpaceForUnit( caster, casterOrigin + table.remove( vRandomSpawnPos, 1 ), true )

	-- Spawn illusions
	for i = 1, kobold_count do
		local origin = casterOrigin + table.remove( vRandomSpawnPos, 1 )

		-- handle_UnitOwner needs to be nil, else it will crash the game.
		local double = CreateUnitByName(unit_name, origin, true, caster, nil, caster:GetTeamNumber())
		double:SetOwner(caster)
		double:SetControllableByPlayer(player, true)
		double:SetAngles( casterAngles.x, casterAngles.y, casterAngles.z )

		local double_particle = ParticleManager:CreateParticle("particles/units/heroes/hero_arc_warden/arc_warden_tempest_buff.vpcf", PATTACH_CUSTOMORIGIN, double)
		ParticleManager:SetParticleControl(double_particle, 0, double:GetAbsOrigin())
		ParticleManager:SetParticleControl(double_particle, 1, double:GetAbsOrigin())
		ParticleManager:SetParticleControl(double_particle, 2, double:GetAbsOrigin())

		-- Level Up the unit to the casters level
		local casterLevel = caster:GetLevel()

		for i=1,casterLevel-1 do
			double:HeroLevelUp(false)
		end

		double:SetBaseStrength(caster:GetBaseStrength())
  		double:SetBaseIntellect(caster:GetBaseIntellect())
  		double:SetBaseAgility(caster:GetBaseAgility())
  		double:SetMaximumGoldBounty(0)
		double:SetMinimumGoldBounty(0)
		double:SetDeathXP(0)
		double:SetAbilityPoints(0)

		double:SetHasInventory(true)
		double:SetCanSellItems(false)

		Timers:CreateTimer(duration - 0.1, function()
			UTIL_Remove(double)
		end)

		-- Useless since they are removed before, just shows duration of the illusions
		ability:ApplyDataDrivenModifier(caster, double, "modifier_kill", {duration = duration})

		-- Learn the skills of the caster
		for abilitySlot = 0, 15 do
			local ability = caster:GetAbilityByIndex(abilitySlot)
			if ability then 
				local abilityLevel = ability:GetLevel()
				local abilityName = ability:GetAbilityName()
				local doubleAbility = double:FindAbilityByName(abilityName)

				if IsValidEntity(doubleAbility) then
					doubleAbility:SetLevel(abilityLevel)
				end

				if ability:GetName() == "holdout_kobold_army" then
					doubleAbility:SetActivated(false)
					double:RemoveModifierByName("modifier_reincarnation")
					double:SetRespawnsDisabled(true)
				end
			end
		end

		-- Recreate the items of the caster
		for itemSlot = 0, 5 do
			local item = caster:GetItemInSlot(itemSlot)
			if item and item:GetName() ~= "item_ankh_of_reincarnation" and item:GetName() ~= "item_shield_of_invincibility" and item:GetName() ~= "item_xhs_cloak_of_flames" and item:GetName() ~= "item_orb_of_fire" and item:GetName() ~= "item_orb_of_fire2" and item:GetName() ~= "item_searing_blade" then
				local newItem = CreateItem(item:GetName(), double, double)
				double:AddItem(newItem)
			end
		end

		-- Set the illusion hp to be the same as the caster
		double:SetHealth(caster:GetHealth())
		double:SetMana(caster:GetMana())
		double:SetPlayerID(caster:GetPlayerOwnerID())
		-- Add the illusion created to a table within the caster handle, to remove the illusions on the next cast if necessary
		table.insert(caster.kobold_super_illusions, double)
	end
end
