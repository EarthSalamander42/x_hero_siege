require('libraries/timers')

function SpecialEventTPEnabled(event)
local hero = event.activator
	hero:AddNewModifier(nil, nil, "modifier_boss_stun", nil)
	hero:AddNewModifier(nil, nil, "modifier_invulnerable", nil)
	CustomGameEventManager:Send_ServerToPlayer(hero:GetPlayerOwner(), "show_events", {})
	Entities:FindByName(nil, "trigger_special_event"):Disable()
end

function SpecialEventTPDisabled(event)
local hero = event.activator
local msg = "This section will be activated after Muradin Event! (14 Minutes)"
	Notifications:Bottom(hero:GetPlayerOwnerID(), {text = msg, duration = 6.0})
end

function SpecialEventBack(event)
local hero = event.activator
local point = Entities:FindByName(nil, "base_spawn"):GetAbsOrigin()

	if hero:GetTeam() == DOTA_TEAM_GOODGUYS then
		if hero:GetUnitName() == "npc_dota_hero_meepo" then
			local meepo_table = Entities:FindAllByName("npc_dota_hero_meepo")
			if meepo_table then
				for i = 1, #meepo_table do
					FindClearSpaceForUnit(meepo_table[i], point, false)
					meepo_table[i]:Stop()
					PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(), hero)
					Timers:CreateTimer(0.1, function()
						PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(), nil) 
					end)
				end
			end
		else
			FindClearSpaceForUnit(hero, point, true)
			hero:Stop()
			PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(),hero)
			Timers:CreateTimer(0.1, function()
				PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(),nil) 
			end)
		end
	end
end

function SpiritBeastBack(event)
local hero = event.activator

	SpecialEventsTimerEnd()
	SpecialEventBack(event)
	Timers:RemoveTimer(timers.SpiritBeast)
	GameMode.SpiritBeast_occuring = 0

	if not GameMode.spirit_beast:IsNull() then
		GameMode.spirit_beast:RemoveSelf()
	end
end

function SpiritBeastDead(event)
local hero = event.activator
SpecialEventsTimerEnd()

	DoEntFire("trigger_spirit_beast_duration", "Kill", nil ,0 ,nil ,nil)
	GameMode.SpiritBeast_killed = 1

	Timers:CreateTimer(0.5, function()
		local item = CreateItem("item_shield_of_invincibility", nil, nil)
		local pos = GameMode.spirit_beast:GetAbsOrigin()
		local drop = CreateItemOnPositionSync( pos, item )
		local pos_launch = pos + RandomVector(RandomFloat(150, 200))
		item:LaunchLoot(false, 300, 0.5, pos)
	end)
end

function FrostInfernalBack(event)
local hero = event.activator
local point = Entities:FindByName(nil, "base_spawn"):GetAbsOrigin()

	SpecialEventsTimerEnd()
	SpecialEventBack(event)
	Timers:RemoveTimer(timers.FrostInfernal)
	GameMode.FrostInfernal_occuring = 0

	if not GameMode.frost_infernal:IsNull() then
		GameMode.frost_infernal:RemoveSelf()
	end
end

function FrostInfernalDead(event)
local hero = event.activator

	SpecialEventsTimerEnd()
	DoEntFire("trigger_frost_infernal_duration", "Kill", nil ,0 ,nil ,nil)
	GameMode.FrostInfernal_killed = 1

	Timers:CreateTimer(0.5,function ()
		local item = CreateItem("item_key_of_the_three_moons", nil, nil)
		local pos = GameMode.frost_infernal:GetAbsOrigin()
		local drop = CreateItemOnPositionSync( pos, item )
		local pos_launch = pos+RandomVector(RandomFloat(150,200))
		item:LaunchLoot(false, 300, 0.5, pos)
	end)
end

function HeroImageBack(event)
local hero = event.activator
local point = Entities:FindByName(nil, "base_spawn"):GetAbsOrigin()

	SpecialEventsTimerEnd()
	SpecialEventBack(event)
	Timers:RemoveTimer(timers.HeroImage)
	GameMode.HeroImage_occuring = 0

	if not GameMode.HeroImage:IsNull() then
		GameMode.HeroImage:RemoveSelf()
	else
		hero.hero_image = true
		Notifications:Bottom(hero:GetPlayerOwnerID(), {text = "You can do this event only 1 time!", duration = 5.0})
	end
end

function HeroImageDead(event)
local caster = event.caster
local point_beast = Entities:FindByName(nil, "hero_image_boss"):GetAbsOrigin()

	if caster:GetHealth() == 0 then
		SpecialEventsTimerEnd()
		Timers:CreateTimer(0.5, function()
			local item = CreateItem("item_tome_big", nil, nil)
			local pos = point_beast
			local drop = CreateItemOnPositionSync( pos, item )
			local pos_launch = pos + RandomVector(RandomFloat(150, 200))
			item:LaunchLoot(false, 300, 0.5, pos)
		end)
	end
end

function AllHeroImageBack(event)
local hero = event.activator
local point = Entities:FindByName(nil, "base_spawn"):GetAbsOrigin()
local point_hero = Entities:FindByName(nil, "all_hero_image_player"):GetAbsOrigin()
ALL_HERO_IMAGE_DEAD = 0

	SpecialEventsTimerEnd()
	Timers:RemoveTimer(timers.AllHeroImage)
	GameMode.AllHeroImages_occuring = 0
	SpecialEventBack(event)

	local units = FindUnitsInRadius( DOTA_TEAM_CUSTOM_1, point_hero, nil, 2000, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_NONE , FIND_ANY_ORDER, false )
	for _, v in pairs(units) do
		UTIL_Remove(v)
	end
end

function AllHeroImageDead(event)
local caster = event.caster
local point_beast = Entities:FindByName(nil, "all_hero_image_player"):GetAbsOrigin()

	if caster:GetHealth() == 0 then
		SpecialEventsTimerEnd()
		ALL_HERO_IMAGE_DEAD = ALL_HERO_IMAGE_DEAD + 1

		if ALL_HERO_IMAGE_DEAD == 8 then
			GameMode.AllHeroImagesDead = 1
			DoEntFire("trigger_all_hero_image_duration", "Kill", nil ,0 ,nil ,nil)

			Timers:CreateTimer(0.5, function()
				local item = CreateItem("item_necklace_of_spell_immunity", nil, nil)
				local pos = point_beast
				local drop = CreateItemOnPositionSync( pos, item )
				local pos_launch = pos + RandomVector(RandomFloat(150, 200))
				item:LaunchLoot(false, 300, 0.5, pos)
			end)
		end
	end
end
