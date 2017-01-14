require('libraries/timers')
require('phases/phase2')

local itemCharges = 0
local point

function reincarnation( event )
local unit = event.caster

	if unit:GetHealth() == 0 then
		point = unit:GetAbsOrigin()
		local ability = event.ability
		itemCharges = ability:GetCurrentCharges()
		local respawntime = ability:GetSpecialValueFor("reincarnation_time")
		Timers:CreateTimer(respawntime,respawnMagtheridon)

		for i = 1,6 do
			CreateUnitByName("npc_dota_hero_magtheridon_medium", point, true, nil, nil, DOTA_TEAM_BADGUYS)
		end
	end
end

function respawnMagtheridon()
local mag = CreateUnitByName("npc_dota_hero_magtheridon", point, true, nil, nil, DOTA_TEAM_BADGUYS)
local ankh = CreateItem("item_magtheridon_ankh", mag, mag)

	if itemCharges-1 ~= 0 then
		mag:AddItem(ankh)
	end

	ankh:SetCurrentCharges(itemCharges-1)
	mag:EmitSound("Ability.Reincarnation")
end

function respawnMagtheridonMedium()
	for i = 1,2 do
		CreateUnitByName("npc_dota_hero_magtheridon_small", point, true, nil, nil, DOTA_TEAM_BADGUYS)
	end
end
