--[[Author: Pizzalol, Noya, Ractidous
	Date: 08.04.2015.
	Creates illusions while shuffling the positions]]
function Phantasm( keys )
	local caster = keys.caster
	local player = caster:GetPlayerOwnerID()
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1

	-- Ability variables
	local unit_name = caster:GetUnitName()
	local images_count = ability:GetLevelSpecialValueFor( "images_count", ability_level )
	local duration = ability:GetLevelSpecialValueFor( "illusion_duration", ability_level )
	local outgoingDamage = ability:GetLevelSpecialValueFor( "outgoing_damage", ability_level )
	local incomingDamage = ability:GetLevelSpecialValueFor( "incoming_damage", ability_level )
	local extra_illusion_chance = ability:GetLevelSpecialValueFor("extra_phantasm_chance_pct_tooltip", ability_level)
	local extra_illusion_sound = keys.sound

	local chance = RandomInt(1, 100)
	local casterOrigin = caster:GetAbsOrigin()
	local casterAngles = caster:GetAngles()

	-- Stop any actions of the caster otherwise its obvious which unit is real
	caster:Stop()

	-- Initialize the illusion table to keep track of the units created by the spell
	if not caster.phantasm_illusions then
		caster.phantasm_illusions = {}
	end

	-- Kill the old images
	for k,v in pairs(caster.phantasm_illusions) do
		if v and IsValidEntity(v) then 
			v:ForceKill(false)
		end
	end

	-- Start a clean illusion table
	caster.phantasm_illusions = {}

	-- Setup a table of potential spawn positions
	local vRandomSpawnPos = {
		Vector( 72, 0, 0 ),		-- North
		Vector( 0, 72, 0 ),		-- East
		Vector( -72, 0, 0 ),	-- South
		Vector( 72, -72, 0 ),	-- West
		Vector( -72, -72, 0 ),	-- West
		Vector( -72, 0, 72 ),	-- West
		Vector( 72, 0, 0 ),		-- North
		Vector( 0, 72, 0 ),		-- East
		Vector( -72, 0, 0 ),	-- South
		Vector( 72, -72, 0 ),	-- West
		Vector( -72, -72, 0 ),	-- West
		Vector( -72, 0, 72 ),	-- West
		Vector( 72, 0, 0 ),		-- North
		Vector( 0, 72, 0 ),		-- East
		Vector( -72, 0, 0 ),	-- South
		Vector( 72, -72, 0 ),	-- West
		Vector( -72, -72, 0 ),	-- West
		Vector( -72, 0, 72 ),	-- West
		Vector( 72, 0, 0 ),		-- North
		Vector( 0, 72, 0 ),		-- East
		Vector( -72, 0, 0 ),	-- South
		Vector( 72, -72, 0 ),	-- West
		Vector( -72, -72, 0 ),	-- West
		Vector( -72, 0, 72 ),	-- West
		Vector( 72, 0, 0 ),		-- North
		Vector( 0, 72, 0 ),		-- East
		Vector( -72, 0, 0 ),	-- South
		Vector( 72, -72, 0 ),	-- West
		Vector( -72, -72, 0 ),	-- West
		Vector( -72, 0, 72 ),	-- West
	}

	for i=#vRandomSpawnPos, 2, -1 do	-- Simply shuffle them
		local j = RandomInt( 1, i )
		vRandomSpawnPos[i], vRandomSpawnPos[j] = vRandomSpawnPos[j], vRandomSpawnPos[i]
	end

	-- Insert the center position and make sure that at least one of the units will be spawned on there.
	table.insert( vRandomSpawnPos, RandomInt( 1, images_count+1 ), Vector( 0, 0, 0 ) )

	-- At first, move the main hero to one of the random spawn positions.
	FindClearSpaceForUnit( caster, casterOrigin + table.remove( vRandomSpawnPos, 1 ), true )

	-- Spawn illusions
	for i=1, images_count do

		local origin = casterOrigin + table.remove( vRandomSpawnPos, 1 )

		-- handle_UnitOwner needs to be nil, else it will crash the game.
		local illusion = CreateUnitByName(unit_name, origin, true, caster, nil, caster:GetTeamNumber())
		illusion:SetControllableByPlayer(player, true)

		illusion:SetAngles( casterAngles.x, casterAngles.y, casterAngles.z )
	--NOT working since grom is not a hero	
		-- Level Up the unit to the casters level
		--local casterLevel = caster:GetLevel()
		--for i=1,casterLevel-1 do
	--		illusion:HeroLevelUp(false)
	--	end

		for abilitySlot=0,15 do
		local ability = caster:GetAbilityByIndex(abilitySlot)
			if ability then
				local abilityLevel = ability:GetLevel()
				local abilityName = ability:GetAbilityName()
				local illusionAbility = illusion:FindAbilityByName(abilityName)

				if IsValidEntity(illusionAbility) then
					illusionAbility:SetLevel(abilityLevel)
				end

				if ability:GetName() == "grom_hellscream_mirror_image" then
					ability:SetActivated(false)
				end
			end
		end

		-- Recreate the items of the caster
		for itemSlot=0,5 do
			local item = caster:GetItemInSlot(itemSlot)
			if item ~= nil then
				local itemName = item:GetName()
				local newItem = CreateItem(itemName, illusion, illusion)
				illusion:AddItem(newItem)
			end
		end

		illusion:AddNewModifier(caster, ability, "modifier_illusion", { duration = duration, outgoing_damage = outgoingDamage, incoming_damage = incomingDamage })
		illusion:MakeIllusion()
		illusion:SetHealth(caster:GetHealth())
		table.insert(caster.phantasm_illusions, illusion)
		illusion:RemoveAbility("boss_health")
		illusion:RemoveAbility("cant_die_generic")
		illusion:RemoveModifierByName("modifier_cant_die_generic")
	end
end
