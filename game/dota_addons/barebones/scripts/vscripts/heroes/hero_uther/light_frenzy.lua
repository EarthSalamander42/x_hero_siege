--[[ ============================================================================================================
	Author: Rook
	Date: January 26, 2015
	Called when Refresher Orb is cast.  Takes the player's abilities and items off cooldown.
================================================================================================================= ]]
function LightFrenzy(keys)
	--Refresh all abilities on the target.
	for i=0, 15, 1 do  --The maximum number of abilities a unit can have is currently 16.
		local current_ability = keys.target:GetAbilityByIndex(i)
		if current_ability ~= nil then
			if current_ability:GetName() ~= "holdout_light_frenzy" then
				current_ability:EndCooldown()
			end
		end
	end
	
	--Refresh all items the target has.
	for i=0, 5, 1 do
		local current_item = keys.target:GetItemInSlot(i)
		if current_item ~= nil then
			current_item:EndCooldown()
		end
	end
end