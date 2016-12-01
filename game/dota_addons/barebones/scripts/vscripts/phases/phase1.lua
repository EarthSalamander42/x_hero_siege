require('libraries/timers')

function SpecialEventTP(event)
local hero = event.activator
local point = Entities:FindByName(nil,"point_teleport_special_events"):GetAbsOrigin()
print("Entering Special Event Choice")

	Entities:FindByName(nil, "trigger_special_event_choice"):Disable()
	Entities:FindByName(nil, "trigger_special_event_back"):Enable()

--	if hero:GetUnitName() == "npc_dota_hero_meepo" then
--		local meepo_table = Entities:FindAllByName("npc_dota_hero_meepo")
--		if meepo_table then
--			for i = 1, #meepo_table do
--				FindClearSpaceForUnit(meepo_table[i], point, false)
--				meepo_table[i]:Stop()
--				PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(),hero)
--				Timers:CreateTimer(0.1, function()
--					PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(),nil) 
--				end)
--			end
--		end
--	else
	FindClearSpaceForUnit(hero, point, true)
	hero:Stop()
	PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(),hero)
		Timers:CreateTimer(0.1, function()
			PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(),nil) 
		end)
--	end
end

function SpecialEventBack(event)
local hero = event.activator
print("Leaving Special Event Choice")

	Entities:FindByName(nil, "trigger_special_event_choice"):Enable()

	local point = Entities:FindByName(nil, "base_spawn"):GetAbsOrigin()
	FindClearSpaceForUnit(hero, point, true)
	hero:Stop()
	PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(),hero)
	Timers:CreateTimer(0.1,function()
		PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(),nil) 
	end)
end

function FrostInfernalEvent(event)
local hero = event.activator
local point_hero = Entities:FindByName(nil, "special_event_player_point"):GetAbsOrigin()
local point_beast = Entities:FindByName(nil, "special_event_boss_point"):GetAbsOrigin()
print("Entering Frost Infernal")

	SpecialEventsTimer()
	Entities:FindByName(nil, "trigger_special_event_back"):Disable()
	Entities:FindByName(nil, "trigger_special_event_back2"):Enable()

	PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(),hero)
	Timers:CreateTimer(0.1, function()
		PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(),nil) 
	end)

	Timers:CreateTimer(120.0,function()
		if GameMode.FrostInfernal_killed == 0 then
			Entities:FindByName(nil, "trigger_frost_infernal_duration"):Enable()

			Timers:CreateTimer(3.5, function() --Debug time in case Frost Infernal kills the player at the very last second
				Entities:FindByName(nil, "trigger_frost_infernal_duration"):Disable()
			end)
		end
	end)

	Timers:CreateTimer(125.0,function()
		Entities:FindByName(nil, "trigger_special_event_choice"):Enable()
	end)

	GameMode.frost_infernal = CreateUnitByName("npc_frost_infernal", point_beast, true, nil, nil, DOTA_TEAM_CUSTOM_1)
	GameMode.frost_infernal:SetAngles(0, 210, 0)
	GameMode.frost_infernal:AddNewModifier(nil, nil, "modifier_animation_freeze_stun", {Duration = 5,IsHidden = true})
	GameMode.frost_infernal:AddNewModifier(nil, nil, "modifier_invulnerable", {Duration = 5,IsHidden = true})

	if IsValidEntity(hero) then
		--Fire the game event to teleport hero to the event
		PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(),hero)
		Timers:CreateTimer(0.1, function()
			PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(),nil) 
		end)
		FindClearSpaceForUnit(hero ,point_hero, true)
		hero:Stop()
		local msg = "Special Event: Kill Frost Infernal for the Key of the 3 Moons. You have 2 minutes."
		Notifications:Top(hero:GetPlayerOwnerID(),{text=msg, duration=5.0})
	end
end

function FrostInfernalBack(event)
local hero = event.activator
print("Leaving Frost Infernal")
--	SpecialEventsTimerEnd()

	if not GameMode.frost_infernal:IsNull() then
		GameMode.frost_infernal:RemoveSelf()
	end

--	Entities:FindByName(nil, "trigger_special_event_choice"):Enable()

	local point = Entities:FindByName(nil, "base_spawn"):GetAbsOrigin()
	FindClearSpaceForUnit(hero, point, true)
	hero:Stop()
	PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(),hero)
	Timers:CreateTimer(0.1, function()
		PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(),nil) 
	end)
end

function FrostInfernalDead(event)
local hero = event.activator
print("Frost Infernal Dead")
SpecialEventsTimerEnd()

	DoEntFire("trigger_special_event_frost_infernal", "Kill", nil ,0 ,nil ,nil)
	DoEntFire("trigger_frost_infernal_duration", "Kill", nil ,0 ,nil ,nil)
	Entities:FindByName(nil, "trigger_special_event_frost_infernal_killed"):Enable()
	GameMode.FrostInfernal_killed = 1

	Timers:CreateTimer(0.5,function ()
		-- Create the item
		local item = CreateItem("item_key_of_the_three_moons", nil, nil)
		local pos = GameMode.frost_infernal:GetAbsOrigin()
		local drop = CreateItemOnPositionSync( pos, item )
		local pos_launch = pos+RandomVector(RandomFloat(150,200))
		item:LaunchLoot(false, 300, 0.5, pos)
	end)

	Timers:CreateTimer(5.0, function()
		Entities:FindByName(nil, "trigger_special_event_choice"):Enable()
	end)
end

function FrostInfernalKilled(event)
local hero = event.activator
local msg = "Frost Infernal has already been killed!"

	Notifications:Top(hero:GetPlayerOwnerID(), {text = msg, duration = 5.0})
end

function SpiritBeastEvent(event)
local hero = event.activator
print("Entering Spirit Beast")
local point_hero = Entities:FindByName(nil, "special_event_player_point2"):GetAbsOrigin()
local point_beast = Entities:FindByName(nil, "special_event_boss_point2"):GetAbsOrigin()

	SpecialEventsTimer()
	Entities:FindByName(nil, "trigger_special_event_back"):Disable()
	Entities:FindByName(nil, "trigger_special_event_back3"):Enable()

	PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(),hero)
	Timers:CreateTimer(0.1, function()
		PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(),nil) 
	end)

	Timers:CreateTimer(120.0,function()
		if GameMode.SpiritBeast_killed == 0 then
			Entities:FindByName(nil, "trigger_spirit_beast_duration"):Enable()

			Timers:CreateTimer(3.5, function() --Debug time in case Frost Infernal kills the player at the very last second
				Entities:FindByName(nil, "trigger_spirit_beast_duration"):Disable()
			end)
		end
	end)

	Timers:CreateTimer(125.0,function()
		Entities:FindByName(nil, "trigger_special_event_choice"):Enable()
	end)

	GameMode.spirit_beast = CreateUnitByName("npc_spirit_beast", point_beast, true, nil, nil, DOTA_TEAM_CUSTOM_1)
	GameMode.spirit_beast:SetAngles(0, 210, 0)
	GameMode.spirit_beast:AddNewModifier(nil, nil, "modifier_animation_freeze_stun", {Duration = 5,IsHidden = true})
	GameMode.spirit_beast:AddNewModifier(nil, nil, "modifier_invulnerable", {Duration = 5,IsHidden = true})

	if IsValidEntity(hero) then
		--Fire the game event to teleport hero to the event
		PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(),hero)
		Timers:CreateTimer(0.1, function()
			PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(),nil) 
		end)
		FindClearSpaceForUnit(hero ,point_hero, true)
		hero:Stop()
		local msg = "Special Event: Kill Spirit Beast for the Shield of Invincibility. You have 2 minutes."
		Notifications:Top(hero:GetPlayerOwnerID(), {text = msg, duration = 5.0})
	end
end

function SpiritBeastBack(event)
local hero = event.activator
print("Leaving Spirit Beast")
--	SpecialEventsTimerEnd()

	if not GameMode.spirit_beast:IsNull() then
		GameMode.spirit_beast:RemoveSelf()
	end

--	Entities:FindByName(nil, "trigger_special_event_choice"):Enable()

	local point = Entities:FindByName(nil, "base_spawn"):GetAbsOrigin()
	FindClearSpaceForUnit(hero, point, true)
	hero:Stop()
	PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(),hero)
	Timers:CreateTimer(0.1, function()
		PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(),nil) 
	end)
end

function SpiritBeastDead(event)
local hero = event.activator
print("Spirit Beast Dead")
SpecialEventsTimerEnd()

	DoEntFire("trigger_special_event_spirit_beast", "Kill", nil ,0 ,nil ,nil)
	DoEntFire("trigger_spirit_beast_duration", "Kill", nil ,0 ,nil ,nil)
	Entities:FindByName(nil, "trigger_special_event_spirit_beast_killed"):Enable()
	GameMode.SpiritBeast_killed = 1

	Timers:CreateTimer(0.5, function()
		-- Create the item
		local item = CreateItem("item_shield_of_invincibility", nil, nil)
		local pos = GameMode.spirit_beast:GetAbsOrigin()
		local drop = CreateItemOnPositionSync( pos, item )
		local pos_launch = pos + RandomVector(RandomFloat(150, 200))
		item:LaunchLoot(false, 300, 0.5, pos)
	end)

	Timers:CreateTimer(5.0, function()
		Entities:FindByName(nil, "trigger_special_event_choice"):Enable()
	end)
end

function SpiritBeastKilled(event)
local hero = event.activator
local msg = "Spirit Beast has already been killed!"
	Notifications:Top(hero:GetPlayerOwnerID(), {text = msg, duration = 5.0})
end
