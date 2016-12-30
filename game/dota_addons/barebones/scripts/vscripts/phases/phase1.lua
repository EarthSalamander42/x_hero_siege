require('libraries/timers')

function SpecialEventTP(event)
local hero = event.activator
local point = Entities:FindByName(nil,"point_teleport_special_events"):GetAbsOrigin()

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

	SpecialEventsTimer()
	Entities:FindByName(nil, "trigger_special_event_frost_infernal"):Disable()
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
				Entities:FindByName(nil, "trigger_special_event_frost_infernal"):Enable()
			end)
		end
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

	timers.disabled_items = Timers:CreateTimer(0.0, function()
	local ability = hero:FindAbilityByName("holdout_blink")
		ability:StartCooldown(3.0)
		for itemSlot = 0, 5 do
		local item = hero:GetItemInSlot(itemSlot)
			if item ~= nil and item:GetName() == "item_tome_small" then
				item:StartCooldown(3.0)
			end
			if item ~= nil and item:GetName() == "item_tome_big" then
				item:StartCooldown(3.0)
			end
			if item ~= nil and item:GetName() == "item_boots_of_speed" then
				item:StartCooldown(3.0)
			end
			if item ~= nil and item:GetName() == "item_tpscroll" then
				item:StartCooldown(3.0)
			end
		end
		return 1
	end)

end

function FrostInfernalBack(event)
local hero = event.activator
--	SpecialEventsTimerEnd()

	if not GameMode.frost_infernal:IsNull() then
		GameMode.frost_infernal:RemoveSelf()
	end

	local point = Entities:FindByName(nil, "base_spawn"):GetAbsOrigin()
	FindClearSpaceForUnit(hero, point, true)
	Timers:RemoveTimer(timers.disabled_items)
	hero:Stop()
	PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(),hero)
	Timers:CreateTimer(0.1, function()
		PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(),nil) 
	end)
end

function FrostInfernalDead(event)
local hero = event.activator
SpecialEventsTimerEnd()

	DoEntFire("trigger_special_event_frost_infernal", "Kill", nil ,0 ,nil ,nil)
	DoEntFire("trigger_frost_infernal_duration", "Kill", nil ,0 ,nil ,nil)
	Entities:FindByName(nil, "trigger_special_event_frost_infernal_killed"):Enable()
	GameMode.FrostInfernal_killed = 1
	Timers:RemoveTimer(timers.disabled_items)

	Timers:CreateTimer(0.5,function ()
		-- Create the item
		local item = CreateItem("item_key_of_the_three_moons", nil, nil)
		local pos = GameMode.frost_infernal:GetAbsOrigin()
		local drop = CreateItemOnPositionSync( pos, item )
		local pos_launch = pos+RandomVector(RandomFloat(150,200))
		item:LaunchLoot(false, 300, 0.5, pos)
	end)
end

function FrostInfernalKilled(event)
local hero = event.activator
local msg = "Frost Infernal has already been killed!"

	Notifications:Top(hero:GetPlayerOwnerID(), {text = msg, duration = 5.0})
end

function SpiritBeastEvent(event)
local hero = event.activator
local point_hero = Entities:FindByName(nil, "special_event_player_point2"):GetAbsOrigin()
local point_beast = Entities:FindByName(nil, "special_event_boss_point2"):GetAbsOrigin()

	SpecialEventsTimer()
	Entities:FindByName(nil, "trigger_special_event_spirit_beast"):Disable()
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
				Entities:FindByName(nil, "trigger_special_event_spirit_beast"):Enable()
			end)
		end
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

	timers.disabled_items = Timers:CreateTimer(0.0, function()
	local ability = hero:FindAbilityByName("holdout_blink")
		ability:StartCooldown(3.0)
		for itemSlot = 0, 5 do
		local item = hero:GetItemInSlot(itemSlot)
			if item ~= nil and item:GetName() == "item_tome_small" then
				item:StartCooldown(3.0)
			end
			if item ~= nil and item:GetName() == "item_tome_big" then
				item:StartCooldown(3.0)
			end
			if item ~= nil and item:GetName() == "item_boots_of_speed" then
				item:StartCooldown(3.0)
			end
			if item ~= nil and item:GetName() == "item_tpscroll" then
				item:StartCooldown(3.0)
			end
		end
		return 1
	end)
end

function SpiritBeastBack(event)
local hero = event.activator
--	SpecialEventsTimerEnd()

	if not GameMode.spirit_beast:IsNull() then
		GameMode.spirit_beast:RemoveSelf()
	end

	local point = Entities:FindByName(nil, "base_spawn"):GetAbsOrigin()
	FindClearSpaceForUnit(hero, point, true)
	Timers:RemoveTimer(timers.disabled_items)
	hero:Stop()
	PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(),hero)
	Timers:CreateTimer(0.1, function()
		PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(),nil) 
	end)
end

function SpiritBeastDead(event)
local hero = event.activator
SpecialEventsTimerEnd()

	DoEntFire("trigger_special_event_spirit_beast", "Kill", nil ,0 ,nil ,nil)
	DoEntFire("trigger_spirit_beast_duration", "Kill", nil ,0 ,nil ,nil)
	Entities:FindByName(nil, "trigger_special_event_spirit_beast_killed"):Enable()
	GameMode.SpiritBeast_killed = 1
	Timers:RemoveTimer(timers.disabled_items)

	Timers:CreateTimer(0.5, function()
		-- Create the item
		local item = CreateItem("item_shield_of_invincibility", nil, nil)
		local pos = GameMode.spirit_beast:GetAbsOrigin()
		local drop = CreateItemOnPositionSync( pos, item )
		local pos_launch = pos + RandomVector(RandomFloat(150, 200))
		item:LaunchLoot(false, 300, 0.5, pos)
	end)
end

function SpiritBeastKilled(event)
local hero = event.activator
local msg = "Spirit Beast has already been killed!"
	Notifications:Top(hero:GetPlayerOwnerID(), {text = msg, duration = 5.0})
end

function HeroImageEvent(event)
local hero = event.activator
local point_hero = Entities:FindByName(nil, "special_event_player_point3"):GetAbsOrigin()
local point_beast = Entities:FindByName(nil, "special_event_boss_point3"):GetAbsOrigin()

	SpecialEventsTimer()
	Entities:FindByName(nil, "trigger_special_event_hero_image"):Disable()
	Entities:FindByName(nil, "trigger_special_event_back4"):Enable()

	PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(),hero)
	Timers:CreateTimer(0.1, function()
		PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(),nil) 
	end)

	Timers:CreateTimer(120.0,function()
		if GameMode.HeroImage_killed == 0 then
			Entities:FindByName(nil, "trigger_hero_image_duration"):Enable()

			Timers:CreateTimer(3.5, function() --Debug time in case Frost Infernal kills the player at the very last second
				Entities:FindByName(nil, "trigger_hero_image_duration"):Disable()
				Entities:FindByName(nil, "trigger_special_event_hero_image"):Enable()
			end)
		end
	end)

	GameMode.HeroImage = CreateUnitByName(hero:GetUnitName(), point_beast, true, nil, nil, DOTA_TEAM_CUSTOM_1)
	GameMode.HeroImage:SetAngles(0, 210, 0)
	GameMode.HeroImage:SetBaseStrength(hero:GetBaseStrength()*4)
	GameMode.HeroImage:SetBaseIntellect(hero:GetBaseIntellect()*4)
	GameMode.HeroImage:SetBaseAgility(hero:GetBaseAgility()*4)
	GameMode.HeroImage:AddNewModifier(nil, nil, "modifier_boss_stun", {Duration = 5,IsHidden = true})
	GameMode.HeroImage:AddNewModifier(nil, nil, "modifier_invulnerable", {Duration = 5,IsHidden = true})
	GameMode.HeroImage:AddNewModifier(GameMode.HeroImage, nil, "modifier_illusion", { outgoing_damage = 100, incoming_damage = 100})
	GameMode.HeroImage:MakeIllusion()
	GameMode.HeroImage:AddAbility("hero_image_death")
	local ability = GameMode.HeroImage:FindAbilityByName("hero_image_death")
	ability:ApplyDataDrivenModifier(GameMode.HeroImage, GameMode.HeroImage, "modifier_hero_image", {})

	if IsValidEntity(hero) then
		--Fire the game event to teleport hero to the event
		PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(),hero)
		Timers:CreateTimer(0.1, function()
			PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(),nil) 
		end)
		FindClearSpaceForUnit(hero , point_hero, true)
		hero:Stop()
		local msg = "Special Event: Kill Hero Image for +250 Stats. You have 2 minutes."
		Notifications:Top(hero:GetPlayerOwnerID(), {text = msg, duration = 5.0})
	end

	timers.disabled_items = Timers:CreateTimer(0.0, function()
	local ability = hero:FindAbilityByName("holdout_blink")
		ability:StartCooldown(3.0)
		for itemSlot = 0, 5 do
		local item = hero:GetItemInSlot(itemSlot)
			if item ~= nil and item:GetName() == "item_tome_small" then
				item:StartCooldown(3.0)
			end
			if item ~= nil and item:GetName() == "item_tome_big" then
				item:StartCooldown(3.0)
			end
			if item ~= nil and item:GetName() == "item_boots_of_speed" then
				item:StartCooldown(3.0)
			end
			if item ~= nil and item:GetName() == "item_tpscroll" then
				item:StartCooldown(3.0)
			end
		end
		return 1
	end)
end

function HeroImageBack(event)
local hero = event.activator
--	SpecialEventsTimerEnd()

	local point = Entities:FindByName(nil, "base_spawn"):GetAbsOrigin()
	FindClearSpaceForUnit(hero, point, true)
	hero:Stop()
	Timers:RemoveTimer(timers.disabled_items)
	PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(),hero)
	Timers:CreateTimer(0.1, function()
		PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(),nil) 
	end)

	if not GameMode.HeroImage:IsNull() then
		GameMode.HeroImage:RemoveSelf()
	end
end

function HeroImageDead(event)
local caster = event.caster
local point_beast = Entities:FindByName(nil, "special_event_boss_point3"):GetAbsOrigin()

	if caster:GetHealth() == 0 then
		SpecialEventsTimerEnd()
		DoEntFire("trigger_special_event_hero_image", "Kill", nil ,0 ,nil ,nil)
		DoEntFire("trigger_hero_image_duration", "Kill", nil ,0 ,nil ,nil)
		Entities:FindByName(nil, "trigger_special_event_hero_image_killed"):Enable()
		GameMode.HeroImage_killed = 1
		Timers:RemoveTimer(timers.disabled_items)

		Timers:CreateTimer(0.5, function()
			-- Create the item
			local item = CreateItem("item_tome_big", nil, nil)
			local pos = point_beast
			local drop = CreateItemOnPositionSync( pos, item )
			local pos_launch = pos + RandomVector(RandomFloat(150, 200))
			item:LaunchLoot(false, 300, 0.5, pos)
		end)
	end
end

function HeroImageKilled(event)
local hero = event.activator
local msg = "Hero Image has already been done!"
	Notifications:Top(hero:GetPlayerOwnerID(), {text = msg, duration = 5.0})
end
