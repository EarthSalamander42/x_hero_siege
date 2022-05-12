corpse_baseclass = corpse_baseclass or {}

-- Careful! These functions are being overriden if one exists in hero scripts
function corpse_baseclass:CastFilterResultTarget( target )
	if not IsServer() then return end

	local caster = self:GetCaster()
	local corpseRadius = ability:GetKeyValue("RequiresCorpsesAround")

	if corpseRadius then
		local corpseFlag = ability:GetKeyValue("CorpseFlag")

		if corpseFlag then
			if corpseFlag == "NotMeatWagon" then
				if not Corpses:AreAnyOutsideInRadius(playerID, unit:GetAbsOrigin(), corpseRadius) then
					SendErrorMessage(caster:GetPlayerID(), "#error_no_usable_corpses")
					return false
				end
			end
		elseif not Corpses:AreAnyInRadius(playerID, unit:GetAbsOrigin(), corpseRadius) then
			SendErrorMessage(caster:GetPlayerID(), "#error_no_usable_corpses")
			Notifications:Bottom(playerID, {text="No corpses near!", duration=5.0, style={color="white"}})
			return false
		end
	end

	return UnitFilter(target, self:GetAbilityTargetTeam(), self:GetAbilityTargetType(), self:GetAbilityTargetFlags(), caster:GetTeamNumber())
end

function corpse_baseclass:GetCustomCastErrorTarget(target)
	return "dota_hud_error_cant_cast_on_self"
end

return corpse_baseclass
