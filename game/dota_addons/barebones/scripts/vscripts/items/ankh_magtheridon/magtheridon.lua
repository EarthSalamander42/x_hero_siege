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
			CreateUnitByName("npc_dota_hero_magtheridon_medium",point,true,nil,nil,DOTA_TEAM_BADGUYS)
		end
	end
end

function respawnMagtheridon()
	-- body
	local mag = CreateUnitByName("npc_dota_hero_magtheridon",point,true,nil,nil,DOTA_TEAM_BADGUYS)
  	local ankh = CreateItem("item_magtheridon_ankh", mag, mag)
	  	
	ankh:SetCurrentCharges(itemCharges-1)
	
	if itemCharges-1 ~= 0 then
		mag:AddItem(ankh)
--	else
--		ankh:ApplyDataDrivenModifier(mag, mag, "modifier_delete_door", {})
	end
	

end

function respawnMagtheridonMedium()
	-- body
	for i = 1,2 do
		CreateUnitByName("npc_dota_hero_magtheridon_small",point,true,nil,nil,DOTA_TEAM_BADGUYS)
	end
end

--[[
function delete_door( event)
	-- body
	local door = Entities:FindByName(nil, "door_magtheridon")
	door:Kill()

	local gridobs = Entities:FindAllByName("obstruction_magtheridon")
	for _,obs in pairs(gridobs) do 
		obs:SetEnabled(false, true)
	end
	local trigger = Entities:FindByName(nil, "trigger_top_waves_1")
	trigger:Enable()
end
--]]