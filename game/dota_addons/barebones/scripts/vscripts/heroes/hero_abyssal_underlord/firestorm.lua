local dummy = nil

function modifier_start( event )
	-- body
	dummy = event.target
end

function firestorm( event )
	-- body
	local caster = event.caster
	local ability = event.ability
	--FindUnitsInRadius( iTeamNumber, vPosition, hCacheUnit, flRadius, iTeamFilter, iTypeFilter, iFlagFilter, iOrder, bCanGrowCache )
	local units = FindUnitsInRadius(caster:GetTeamNumber(), dummy:GetAbsOrigin(), nil, ability:GetSpecialValueFor("radius"), DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO+DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)		
	
	for _,v in pairs(units) do
		local damageTable = {
							victim = v,
							attacker = caster,
							damage = ability:GetSpecialValueFor("damage_per_tick"),
							damage_type = DAMAGE_TYPE_MAGICAL,
							}
 	
		ApplyDamage(damageTable)
		ability:ApplyDataDrivenModifier(caster, v, "modifier_firestorm_afterburn", nil)
	end
end


function channel_end( event )
	-- body
	
	if dummy ~= nil then
		dummy:RemoveSelf()
		dummy = nil
	end
end