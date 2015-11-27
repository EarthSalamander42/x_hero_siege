require('libraries/timers')

function spawn_deathghost( event )
	-- body
	local caller = event.caller
	Timers:CreateTimer(function()
		local unit = CreateUnitByName("npc_death_ghost_tower", caller:GetAbsOrigin(), true, nil, nil, DOTA_TEAM_BADGUYS)
		end)
end

function spawn_magnataur( event )
	-- body
	local caller = event.caller
	Timers:CreateTimer(function()
		local unit = CreateUnitByName("npc_magnataur_destroyer_crypt", caller:GetAbsOrigin(), true, nil, nil, DOTA_TEAM_BADGUYS)
	end)
end