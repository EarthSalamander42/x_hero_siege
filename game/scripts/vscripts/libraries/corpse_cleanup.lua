local CORPSE_CLEANUP_DELAY = 3.0

local function RemoveLegacyCustomCorpses()
	for _, corpse in pairs(Entities:FindAllByName("dotacraft_corpse")) do
		if IsValidEntity(corpse) and not corpse:IsNull() then
			UTIL_Remove(corpse)
		end
	end
end

-- Keep creep death animations readable without retaining gameplay corpses long
-- enough to accumulate. Entity-killed listeners can safely consume the handle
-- during the same grace period.
ListenToGameEvent("entity_killed", function(keys)
	local entityIndex = keys and tonumber(keys.entindex_killed) or nil
	if entityIndex == nil then return end

	local killed = EntIndexToHScript(entityIndex)
	if killed == nil
		or not IsValidEntity(killed)
		or killed:IsNull()
		or killed.IsHero == nil
		or killed.IsBuilding == nil
		or killed.IsAlive == nil
		or killed:IsHero()
		or killed:IsBuilding()
		or (killed.FindModifierByName ~= nil and killed:FindModifierByName("modifier_breakable_container") ~= nil)
	then
		return
	end

	Timers:CreateTimer(CORPSE_CLEANUP_DELAY, function()
		if killed ~= nil and IsValidEntity(killed) and not killed:IsNull() and not killed:IsAlive() then
			UTIL_Remove(killed)
		end
	end)
end, nil)

Timers:CreateTimer(0.0, RemoveLegacyCustomCorpses)
