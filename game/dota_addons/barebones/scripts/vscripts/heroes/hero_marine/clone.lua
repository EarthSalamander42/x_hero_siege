--[[Author: Pizzalol, Noya, Ractidous
	Date: 08.04.2015.
	Creates illusions while shuffling the positions]]

function Clone( keys )
local caster = keys.caster
local target = keys.target
local player = caster:GetPlayerOwnerID()
local ability = keys.ability
local ability_level = ability:GetLevel() - 1

-- Ability variables
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
