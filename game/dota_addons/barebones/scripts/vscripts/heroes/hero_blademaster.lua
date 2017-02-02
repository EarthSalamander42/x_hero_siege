function MirrorImage( event )
	local caster = event.caster
	local player = caster:GetPlayerID()
	local ability = event.ability
	local unit_name = caster:GetUnitName()
	local images_count = ability:GetLevelSpecialValueFor( "images_count", ability:GetLevel() - 1 )
	local duration = ability:GetLevelSpecialValueFor( "illusion_duration", ability:GetLevel() - 1 )
	local outgoingDamage = ability:GetLevelSpecialValueFor( "illusion_outgoing_damage", ability:GetLevel() - 1 )
	local incomingDamage = ability:GetLevelSpecialValueFor( "illusion_incoming_damage", ability:GetLevel() - 1 )

	-- Initialize the illusion table to keep track of the units created by the spell
	if not caster.illusions then
		caster.illusions = {}
	end

	-- Kill the old images
	for k,v in pairs(caster.illusions) do
		if v and IsValidEntity(v) then 
			v:ForceKill(false)
		end
	end

	-- Start a clean illusion table
	caster.illusions = {}

	-- Repositionate the main hero
	local fv = caster:GetForwardVector()
	local positions = ShuffledList(GenerateNumPointsAround(images_count+1, caster:GetAbsOrigin()-fv*100, 100))
	FindClearSpaceForUnit(caster, positions[1], true)
	caster:Stop()

	-- Spawn many illusions
	for i = 1, images_count do
		-- handle_UnitOwner needs to be nil, else it will crash the game.
		local illusion = CreateUnitByName(unit_name, positions[i+1], true, caster, nil, caster:GetTeamNumber())
		illusion:SetPlayerID(caster:GetPlayerID())
		illusion:SetControllableByPlayer(player, true)
		illusion:Stop()
		illusion:SetForwardVector(fv)

		-- Level Up the unit to the casters level
		local casterLevel = caster:GetLevel()
		for i = 1, casterLevel -1 do
			illusion:HeroLevelUp(false)
		end

		-- Set the skill points to 0 and learn the skills of the caster
		illusion:SetAbilityPoints(0)
		for abilitySlot = 0, 15 do
			local ability = caster:GetAbilityByIndex(abilitySlot)
		end

		-- Recreate the items of the caster
		for itemSlot = 0, 5 do
			local item = caster:GetItemInSlot(itemSlot)
			if item ~= nil and item:GetName() ~= "item_orb_of_fire" and item:GetName() ~= "item_cloak_of_flames" then
				local itemName = item:GetName()
				local newItem = CreateItem(itemName, illusion, illusion)
				illusion:AddItem(newItem)
			end
		end

		illusion:AddNewModifier(caster, ability, "modifier_illusion", { duration = duration, outgoing_damage = outgoingDamage, incoming_damage = incomingDamage })
		illusion:MakeIllusion()
		table.insert(caster.illusions, illusion)
	end
end