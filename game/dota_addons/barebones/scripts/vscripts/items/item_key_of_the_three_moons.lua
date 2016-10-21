function ItemCheck( event )
	local itemName = event.ability:GetAbilityName()
	local hero = EntIndexToHScript( event.caster_entindex )
	print("Checking Restrictions for "..itemName)

	-- This timer is needed because OnEquip triggers before the item actually being in inventory
	Timers:CreateTimer(0.1,function()
		-- Go through every item slot
		for itemSlot = 0, 5, 1 do 
			local Item = hero:GetItemInSlot( itemSlot )
			-- When we find the item we want to check
			if Item ~= nil and itemName == Item:GetName() then
				DeepPrintTable(Item)

				-- Check Level Restriction
--				if itemTable.levelRequired then
--					print("Name","Level Req","Hero Level")
					-- If the hero doesn't met the level required, show message and call DropItem
--					if itemTable.levelRequired > hero:GetLevel() then
						FireGameEvent( 'custom_error_show', { player_ID = pID, _error = "You can carry only 1 Key of the 3 Moons!" } )
						DropItem(Item, hero)
--					end 
--				end
			end
		end
	end)
end

function DropItem( item, hero )
	-- Error Sound
	EmitSoundOnClient("General.CastFail_InvalidTarget_Hero", hero:GetPlayerOwner())

	-- Create a new empty item
	local newItem = CreateItem( item:GetName(), nil, nil )
	newItem:SetPurchaseTime( 0 )

	-- This is needed if you are working with items with charges, uncomment it if so.
	-- newItem:SetCurrentCharges( goldToDrop )

	-- Make a new item and launch it near the hero
	local spawnPoint = Vector( 0, 0, 0 )
	spawnPoint = hero:GetAbsOrigin()
	local drop = CreateItemOnPositionSync( spawnPoint, newItem )
	newItem:LaunchLoot( false, 200, 0.75, spawnPoint + RandomVector( RandomFloat( 50, 150 ) ) )

	--finally, remove the item
	hero:RemoveItem(item)
end
