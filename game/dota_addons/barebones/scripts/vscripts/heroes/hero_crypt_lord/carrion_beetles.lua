require('mechanics/corpses')

-- Spawns a beetle near a corpse, consuming it in the process.
function CarrionBeetleSpawn( event )
	local caster = event.caster
	local playerID = caster:GetPlayerOwnerID()
	local ability = event.ability
	local level = ability:GetLevel()
	local beetle_limit = ability:GetLevelSpecialValueFor( "beetle_limit", ability:GetLevel() - 1 )

	-- Initialize the table of beetles
	if caster.beetles == nil then
		caster.beetles = {}
	end

	-- If the caster has already hit the limit of beetles, kill the oldest, then continue
	if #caster.beetles >= beetle_limit then
		for k,v in pairs(caster.beetles) do
			if v and IsValidEntity(v) and v:IsAlive() then
				v:ForceKill(false)
				break
			end
		end
	end

	-- Create the beetle
	local beetle = CreateUnitByName("undead_carrion_beetle_"..level, caster:GetAbsOrigin(), true, caster, caster, caster:GetTeamNumber())
	beetle:SetControllableByPlayer(playerID, true)
	beetle:AddNewModifier(caster, ability, "modifier_carrion_beetle", {})
	beetle:AddNewModifier(caster, ability, "modifier_phased", {duration = 0.05})
	table.insert(caster.beetles, beetle)
end

-- Remove the units from the table when they die to allow for new ones to spawn
function RemoveDeadBeetle( event )
	local caster = event.caster
	local unit = event.unit
	local targets = caster.beetles

	for k,beetle in pairs(targets) do       
		if beetle and IsValidEntity(beetle) and beetle == unit then
			table.remove(caster.beetles,k)
		end
	end
end
