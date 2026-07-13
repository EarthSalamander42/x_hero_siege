require('libraries/timers')

function SpecialEventTPDisabled(event)
	local hero = event.activator
	local msg = "This section will be activated after Muradin Event! (14 Minutes)"

	Notifications:Bottom(hero:GetPlayerOwnerID(), { text = msg, duration = 6.0 })
end

function SpecialEventTPEnabled(event)
	local hero = event.activator
	local point = Entities:FindByName(nil, "event_tp_fix"):GetAbsOrigin()
	if PlayerResource:GetConnectionState(hero:GetPlayerID()) ~= 2 then return end
	local heroImageUsed = GameMode.IsHeroImageCompleted ~= nil
		and GameMode:IsHeroImageCompleted(hero:GetPlayerID(), hero)
		or hero.hero_image == true

	CustomGameEventManager:Send_ServerToPlayer(hero:GetPlayerOwner(), "show_events", {
		hero_image_used = heroImageUsed,
		hero_image_busy = GameMode.HeroImage_occuring == true,
		all_hero_images_used = GameMode.AllHeroImagesDead == true,
		all_hero_images_busy = GameMode.AllHeroImages_occuring == true,
	})
	Entities:FindByName(nil, "trigger_special_event"):Disable()
	TeleportHero(hero, point)
	hero:AddNewModifier(hero, nil, "modifier_pause_creeps", { IsHidden = true })
	hero:AddNewModifier(hero, nil, "modifier_invulnerable", { IsHidden = true })
	DoEntFire("special_event_piedestal", "SetAnimation", "ancient_trigger001_down_up", 0, nil, nil)
end

function HeroImageBack(event)
	local hero = event.activator

	if hero == nil or hero:IsNull() then return end

	local heroImageCompleted = GameMode.IsHeroImageCompleted ~= nil
		and GameMode:IsHeroImageCompleted(hero:GetPlayerID(), hero)
		or hero.hero_image == true
	local heroImageUnitMissing = GameMode.HeroImageUnit == nil or not IsValidEntity(GameMode.HeroImageUnit) or GameMode.HeroImageUnit:IsNull()
	if heroImageCompleted or heroImageUnitMissing then
		if FragmentQuests ~= nil then
			FragmentQuests:OnOptionalEventEnd("hero_image", heroImageCompleted)
		end
		SetHeroOptionalEventTomeLock(hero, "hero_image", false)
		GameMode.HeroImage_occuring = false
		GameMode.HeroImageUnit = nil
		CustomGameEventManager:Send_ServerToPlayer(hero:GetPlayerOwner(), "xhs_event_usage_update", {
			hero_image_used = heroImageCompleted,
			hero_image_busy = false,
		})
		CustomGameEventManager:Send_ServerToAllClients("xhs_event_usage_update", {
			hero_image_busy = false,
		})
		GameMode:ReturnHeroFromOptionalEvent(hero, "hero_image")
		return
	end

	SpecialEventBack(event)
	Timers:RemoveTimer(timers.HeroImage)
	GameMode.HeroImage_occuring = false
	if FragmentQuests ~= nil then
		FragmentQuests:OnOptionalEventEnd("hero_image", false)
	end

	if GameMode.HeroImageUnit ~= nil and IsValidEntity(GameMode.HeroImageUnit) and not GameMode.HeroImageUnit:IsNull() then
		UTIL_Remove(GameMode.HeroImageUnit)
	end
	GameMode.HeroImageUnit = nil

	CustomGameEventManager:Send_ServerToPlayer(hero:GetPlayerOwner(), "xhs_event_usage_update", {
		hero_image_used = false,
		hero_image_busy = false,
	})
	CustomGameEventManager:Send_ServerToAllClients("xhs_event_usage_update", {
		hero_image_busy = false,
	})
	Notifications:Bottom(hero:GetPlayerOwnerID(), { text = "Hero Image failed. You can try again.", duration = 5.0 })
	CustomGameEventManager:Send_ServerToAllClients("hide_timer_hero_image", {})
end

function HeroImageDead(event)
	local hero = GetPlayerHeroFromUnit(event.attacker) or event.attacker

	if timers.HeroImage then
		Timers:RemoveTimer(timers.HeroImage)
	end

	SetHeroOptionalEventTomeLock(hero, "hero_image", false)
	GameMode.HeroImage_occuring = false
	GameMode.HeroImageUnit = nil
	CustomGameEventManager:Send_ServerToAllClients("hide_timer_hero_image", {})
	if GameMode.MarkHeroImageCompleted ~= nil then
		GameMode:MarkHeroImageCompleted(hero)
	else
		hero.hero_image = true
	end
	if FragmentQuests ~= nil then
		FragmentQuests:OnOptionalEventEnd("hero_image", true)
	end
	CustomGameEventManager:Send_ServerToPlayer(hero:GetPlayerOwner(), "xhs_event_usage_update", {
		hero_image_used = true,
		hero_image_busy = false,
	})
	CustomGameEventManager:Send_ServerToAllClients("xhs_event_usage_update", {
		hero_image_busy = false,
	})

	Timers:CreateTimer(0.5, function()
		GrantTomeStatsToHero(hero, 250, "Tome Granted", "+250 all stats")
	end)
end

function SpecialEventBack(event)
	local caller = event.caller
	local hero = event.activator

	SetHeroOptionalEventTomeLock(hero, nil, false)

	if hero:GetTeamNumber() == 2 then
		TeleportHero(hero, BASE_GOOD:GetAbsOrigin())
		-- elseif hero:GetTeamNumber() == 3 then
		-- TeleportHero(hero, base_bad:GetAbsOrigin())
	end

	Entities:FindByName(nil, "trigger_special_event"):Enable()

	if caller:GetName() == "trigger_hero_image_duration" then
		CustomGameEventManager:Send_ServerToAllClients("hide_timer_hero_image", {})
	elseif caller:GetName() == "trigger_spirit_beast_duration" then
		CustomGameEventManager:Send_ServerToAllClients("hide_timer_spirit_beast", {})
	elseif caller:GetName() == "trigger_frost_infernal_duration" then
		CustomGameEventManager:Send_ServerToAllClients("hide_timer_frost_infernal", {})
	elseif caller:GetName() == "trigger_all_hero_image_duration" then
		CustomGameEventManager:Send_ServerToAllClients("hide_timer_all_hero_image", {})
	end
end

function SpiritBeastBack(event)
	local hero = event.activator

	SpecialEventBack(event)
	Timers:RemoveTimer(timers.SpiritBeast)
	GameMode.SpiritBeast_occuring = false
	if FragmentQuests ~= nil then
		FragmentQuests:OnOptionalEventEnd("spirit_beast", false)
	end

	if GameMode.spirit_beast ~= nil and IsValidEntity(GameMode.spirit_beast) and not GameMode.spirit_beast:IsNull() then
		GameMode:HideOptionalEventBossBar("spirit_beast", GameMode.spirit_beast)
		GameMode.spirit_beast:RemoveSelf()
	end
	GameMode.spirit_beast = nil
	CustomGameEventManager:Send_ServerToAllClients("hide_timer_spirit_beast", {})
end

function SpiritBeastDead(event)
	local hero = GetPlayerHeroFromUnit(event.attacker) or event.attacker

	SetHeroOptionalEventTomeLock(hero, "spirit_beast", false)
	DoEntFire("trigger_spirit_beast_duration", "Kill", nil, 0, nil, nil)
	GameMode.SpiritBeast_killed = true
	CustomGameEventManager:Send_ServerToAllClients("hide_timer_spirit_beast", {})
	if GameMode.spirit_beast ~= nil and IsValidEntity(GameMode.spirit_beast) and not GameMode.spirit_beast:IsNull() then
		GameMode:HideOptionalEventBossBar("spirit_beast", GameMode.spirit_beast)
	end
	if FragmentQuests ~= nil then
		FragmentQuests:OnOptionalEventEnd("spirit_beast", true)
	end

	local pos = GameMode.spirit_beast:GetAbsOrigin()
	DropNeutralItemAtPositionForHero("item_shield_of_invincibility", pos, hero, hero:GetTeam(), true)
	if GameMode.CreateShieldOfInvincibilityDropEffect ~= nil then
		GameMode:CreateShieldOfInvincibilityDropEffect(pos)
	end
end

function FrostInfernalBack(event)
	local hero = event.activator

	SpecialEventBack(event)
	Timers:RemoveTimer(timers.FrostInfernal)
	GameMode.FrostInfernal_occuring = false
	if FragmentQuests ~= nil then
		FragmentQuests:OnOptionalEventEnd("frost_infernal", false)
	end

	if GameMode.frost_infernal ~= nil and IsValidEntity(GameMode.frost_infernal) and not GameMode.frost_infernal:IsNull() then
		GameMode:HideOptionalEventBossBar("frost_infernal", GameMode.frost_infernal)
		GameMode.frost_infernal:RemoveSelf()
	end
	GameMode.frost_infernal = nil

	CustomGameEventManager:Send_ServerToAllClients("hide_timer_frost_infernal", {})
end

function FrostInfernalDead(event)
	local hero = GetPlayerHeroFromUnit(event.attacker) or event.attacker

	SetHeroOptionalEventTomeLock(hero, "frost_infernal", false)
	DoEntFire("trigger_frost_infernal_duration", "Kill", nil, 0, nil, nil)
	GameMode.FrostInfernal_killed = 1
	CustomGameEventManager:Send_ServerToAllClients("hide_timer_frost_infernal", {})
	if GameMode.frost_infernal ~= nil and IsValidEntity(GameMode.frost_infernal) and not GameMode.frost_infernal:IsNull() then
		GameMode:HideOptionalEventBossBar("frost_infernal", GameMode.frost_infernal)
	end
	if FragmentQuests ~= nil then
		FragmentQuests:OnOptionalEventEnd("frost_infernal", true)
	end

	local pos = GameMode.frost_infernal:GetAbsOrigin()
	DropNeutralItemAtPositionForHero("item_key_of_the_three_moons", pos, hero, hero:GetTeam(), true)
end

function AllHeroImageBack(event)
	local point = Entities:FindByName(nil, "all_hero_image_player"):GetAbsOrigin()
	if timers.AllHeroImage then Timers:RemoveTimer(timers.AllHeroImage) end
	if timers.AllHeroImage2 then Timers:RemoveTimer(timers.AllHeroImage2) end

	CustomGameEventManager:Send_ServerToAllClients("hide_timer_all_hero_image", {})
	GameMode.AllHeroImages_occuring = false
	CustomGameEventManager:Send_ServerToAllClients("xhs_event_usage_update", {
		all_hero_images_busy = false,
	})
	if FragmentQuests ~= nil then
		FragmentQuests:OnOptionalEventEnd("all_hero_images", false)
	end
	SpecialEventBack(event)

	local units = FindUnitsInRadius(DOTA_TEAM_CUSTOM_2, point, nil, 2500, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_INVULNERABLE, FIND_ANY_ORDER, false)

	for _, v in pairs(units) do
		UTIL_Remove(v)
	end
end
