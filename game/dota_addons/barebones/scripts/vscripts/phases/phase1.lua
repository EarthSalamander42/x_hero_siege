require('libraries/timers')
require('gamemode')

function spawn_deathghost(event)
local caller = event.caller
	local unit = CreateUnitByName("npc_death_ghost_tower", caller:GetAbsOrigin(), true, nil, nil, DOTA_TEAM_BADGUYS)
end

function spawn_magnataur(event)
local caller = event.caller
local trigger_left = Entities:FindAllByName("trigger_phase2_left")
local trigger_right = Entities:FindAllByName("trigger_phase2_right")
print( "Barrack Destroyed!" )

Notifications:TopToAll({text="Phase 2 creeps can now be triggered!", duration = 11.0})
local unit = CreateUnitByName("npc_magnataur_destroyer_crypt", caller:GetAbsOrigin(), true, nil, nil, DOTA_TEAM_BADGUYS)

	for _,v in pairs(trigger_left) do
		v:Enable()
	end

	for _,v in pairs(trigger_right) do
		v:Enable()
	end
end

function SpecialEventTP(event)
local hero = event.activator
print("Entering Special Event Choice")

local triggers_choice = Entities:FindAllByName("trigger_special_event_choice")
local triggers_events = Entities:FindAllByName("trigger_special_event_frost_infernal")
local triggers_back = Entities:FindAllByName("trigger_special_event_back")

	for _,v in pairs(triggers_choice) do
		v:Disable()
	end

	for _,v in pairs(triggers_back) do
		v:Enable()
	end

	for _,v in pairs(triggers_events) do
		v:Enable()
	end

	local point = Entities:FindByName(nil,"point_teleport_special_events"):GetAbsOrigin()
	FindClearSpaceForUnit(hero, point, true)
	hero:Stop()
	PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(),hero)
	Timers:CreateTimer(0.5,function () PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(),nil) 
	end)
end

function SpecialEventBack(event)
local hero = event.activator
print("Leaving Special Event Choice")
local triggers_choice = Entities:FindAllByName("trigger_special_event_choice")
local triggers_events = Entities:FindAllByName("trigger_special_event_frost_infernal")

	for _,v in pairs(triggers_choice) do
		v:Enable()
	end

	for _,v in pairs(triggers_events) do
		v:Disable()
	end

	local point = Entities:FindByName(nil, "base_spawn"):GetAbsOrigin()
	FindClearSpaceForUnit(hero, point, true)
	hero:Stop()
	PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(),hero)
	Timers:CreateTimer(0.5,function () PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(),nil) 
	end)
end

function FrostInfernalEvent(event)
local hero = event.activator
print("Entering Frost Infernal")
local triggers_choice = Entities:FindAllByName("trigger_special_event_choice")
local triggers_events = Entities:FindAllByName("trigger_special_event")
local triggers_back = Entities:FindAllByName("trigger_special_event_back")
local triggers_back2 = Entities:FindAllByName("trigger_special_event_back2")
local triggers_frost_infernal_duration = Entities:FindAllByName("trigger_frost_infernal_duration")
local point_hero = Entities:FindByName(nil, "special_event_player_point"):GetAbsOrigin()
local point_beast = Entities:FindByName(nil, "special_event_boss_point"):GetAbsOrigin()
FrostInfernalTimer()

	for _,v in pairs(triggers_events) do
		v:Disable()
	end

	for _,v in pairs(triggers_back) do
		v:Disable()
	end

	for _,v in pairs(triggers_back2) do
		v:Enable()
	end

	for _,v in pairs(triggers_choice) do
		v:Disable()
	end

	for _,v in pairs(triggers_frost_infernal_duration) do
		v:Enable()
	end

	PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(),hero)
	Timers:CreateTimer(0.5,function () PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(),nil) 
	end)

	Timers:CreateTimer(120.0,function ()
		GameMode.frost_infernal:RemoveSelf()
		for _,v in pairs(triggers_choice) do
			v:Enable()
		end
	end)

	GameMode.frost_infernal = CreateUnitByName("npc_frost_infernal", point_beast, true, nil, nil, DOTA_TEAM_CUSTOM_1)
	GameMode.frost_infernal:SetAngles(0, 210, 0)
	GameMode.frost_infernal:AddNewModifier(nil, nil, "modifier_animation_freeze_stun", {Duration = 5,IsHidden = true})
	GameMode.frost_infernal:AddNewModifier(nil, nil, "modifier_invulnerable", {Duration = 5,IsHidden = true})

	if IsValidEntity(hero) then
		--Fire the game event to teleport hero to the event
		PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(),hero)
		Timers:CreateTimer(0.5,function () PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(),nil) 
		end)
		FindClearSpaceForUnit(hero ,point_hero, true)
		hero:Stop()
		local msg = "Special Event: Kill Frost Infernal for a powerful item. You have 2 minutes."
		Notifications:Top(hero:GetPlayerOwnerID(),{text=msg, duration=5.0})
	end
end

function FrostInfernalDead(event)
local hero = event.activator
print("Frost Infernal Dead")
FrostInfernalTimerEnd()

	Timers:CreateTimer(0.5,function ()
		-- Create the item
		local item = CreateItem("item_key_of_the_three_moons", nil, nil)
		local pos = GameMode.frost_infernal:GetAbsOrigin()
		local drop = CreateItemOnPositionSync( pos, item )
		local pos_launch = pos+RandomVector(RandomFloat(150,200))
		item:LaunchLoot(false, 300, 0.5, pos)
		print("Frost Infernal dead")
	end)
end

function SpecialEventFrostInfernalBack(event)
local hero = event.activator
print("Leaving Frost Infernal")
local triggers_choice = Entities:FindAllByName("trigger_special_event_choice")
local triggers_events = Entities:FindAllByName("trigger_special_event_frost_infernal")
FrostInfernalTimerEnd()

	if not GameMode.frost_infernal:IsNull() then
		GameMode.frost_infernal:RemoveSelf()
	end

	for _,v in pairs(triggers_choice) do
		v:Enable()
	end

	for _,v in pairs(triggers_events) do
		v:Disable()
	end

	local point = Entities:FindByName(nil, "base_spawn"):GetAbsOrigin()
	FindClearSpaceForUnit(hero, point, true)
	hero:Stop()
	PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(),hero)
	Timers:CreateTimer(0.5,function () PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(),nil) 
	end)
end
