ListenToGameEvent('game_rules_state_change', function(keys)
	if GameRules:State_Get() == DOTA_GAMERULES_STATE_CUSTOM_GAME_SETUP then
		if _G.INIT_CHOOSE_HERO == false then
			_G.INIT_CHOOSE_HERO = true

			-- Need a timer else Battlepass is nil when first dummy hero spawn
			Timers:CreateTimer(1.0, function()
				SpawnHeroesBis()
				SpawnBosses()
			end)
		end
	end
end, nil)

local HERO_SELECTION_SOURCE_PARTICLE = "particles/items2_fx/teleport_start.vpcf"
local HERO_SELECTION_DESTINATION_PARTICLE = "particles/items2_fx/teleport_end.vpcf"
local HERO_SELECTION_ARRIVAL_PARTICLE = "particles/items2_fx/teleport_start.vpcf"
local HERO_SELECTION_SOURCE_HOLD = 0.90
local HERO_SELECTION_CAMERA_SPEED = 1.25
local HERO_SELECTION_CAMERA_SETTLE = 0.20
local HERO_SELECTION_TELEPORT_DURATION =
	HERO_SELECTION_SOURCE_HOLD + HERO_SELECTION_CAMERA_SPEED + HERO_SELECTION_CAMERA_SETTLE
local HERO_SELECTION_ARRIVAL_DURATION = 0.65
local HERO_SELECTION_DISPLAYS = {
	standard = {},
	vip = {},
}

local function IsValidSelectionUnit(unit)
	return unit ~= nil and IsValidEntity(unit) and not unit:IsNull()
end

local function RegisterSelectionDisplay(group, index, unit)
	if not IsValidSelectionUnit(unit) then return end
	HERO_SELECTION_DISPLAYS[group][index] = HERO_SELECTION_DISPLAYS[group][index] or {}
	table.insert(HERO_SELECTION_DISPLAYS[group][index], unit)
end

local function GetSelectionDisplays(group, index, point)
	local displays = {}
	for _, unit in pairs(HERO_SELECTION_DISPLAYS[group][index] or {}) do
		if IsValidSelectionUnit(unit) then
			table.insert(displays, unit)
		end
	end

	if #displays == 0 and point ~= nil then
		local nearby = FindUnitsInRadius(
			DOTA_TEAM_GOODGUYS,
			point:GetAbsOrigin(),
			nil,
			260,
			DOTA_UNIT_TARGET_TEAM_FRIENDLY,
			DOTA_UNIT_TARGET_HERO,
			DOTA_UNIT_TARGET_FLAG_NONE,
			FIND_CLOSEST,
			false
		)
		for _, unit in pairs(nearby) do
			if unit.is_fake_hero == true then
				table.insert(displays, unit)
			end
		end
	end

	return displays
end

local function GetSelectionTransform(group, index, pickedHeroName)
	local pointName = group == "vip" and ("choose_vip_" .. index .. "_point") or ("choose_" .. index .. "_point")
	local point = Entities:FindByName(nil, pointName)
	local displays = GetSelectionDisplays(group, index, point)
	local primary = nil

	for _, unit in pairs(displays) do
		if unit:GetUnitName() == pickedHeroName then
			primary = unit
			break
		end
	end
	primary = primary or displays[1]

	if IsValidSelectionUnit(primary) then
		return {
			position = primary:GetAbsOrigin(),
			display = primary,
			displays = displays,
		}
	end

	return {
		position = point ~= nil and point:GetAbsOrigin() or nil,
		display = nil,
		displays = displays,
	}
end

local function DestroyHeroSelectionParticle(particle, immediate)
	if particle == nil then return end
	ParticleManager:DestroyParticle(particle, immediate == true)
	ParticleManager:ReleaseParticleIndex(particle)
end

local function GetHeroSelectionBaseTransform(playerID)
	local base = BASE_GOOD
	if not IsValidSelectionUnit(base) then
		base = Entities:FindByName(nil, "base_spawn")
	end
	if not IsValidSelectionUnit(base) then return nil end

	local basePosition = XHSGetPlayerBaseSpawnPosition ~= nil
		and XHSGetPlayerBaseSpawnPosition(playerID, base)
		or base:GetAbsOrigin()
	local baseAngles = base:GetAnglesAsVector()
	return {
		position = basePosition,
		angles = baseAngles,
	}
end

local function StartHeroSelectionSourceTeleport(transform)
	local particles = {}
	local display = transform.display
	if IsValidSelectionUnit(display) then
		display:AddNewModifier(display, nil, "modifier_xhs_cinematic_hide_health_bars", {
			duration = HERO_SELECTION_TELEPORT_DURATION,
		})
		StartAnimation(display, {
			duration = HERO_SELECTION_TELEPORT_DURATION,
			activity = ACT_DOTA_TELEPORT,
			rate = 1.0,
		})
		local particle = ParticleManager:CreateParticle(
			HERO_SELECTION_SOURCE_PARTICLE,
			PATTACH_ABSORIGIN_FOLLOW,
			display,
			display
		)
		ParticleManager:SetParticleControlEnt(
			particle,
			0,
			display,
			PATTACH_ABSORIGIN_FOLLOW,
			"attach_hitloc",
			display:GetAbsOrigin(),
			true
		)
		table.insert(particles, particle)
		display:EmitSound("Portal.Loop_Appear")
	end

	if #particles == 0 and transform.position ~= nil then
		local particle = ParticleManager:CreateParticle(
			HERO_SELECTION_SOURCE_PARTICLE,
			PATTACH_WORLDORIGIN,
			nil
		)
		ParticleManager:SetParticleControl(particle, 0, transform.position)
		table.insert(particles, particle)
	end

	return particles
end

local function FinishHeroSelectionSourceTeleport(transform, particles)
	for _, particle in pairs(particles or {}) do
		DestroyHeroSelectionParticle(particle, false)
	end
	local display = transform.display
	if IsValidSelectionUnit(display) then
		display:StopSound("Portal.Loop_Appear")
		EmitSoundOnLocationWithCaster(display:GetAbsOrigin(), "Portal.Hero_Disappear", display)
		UTIL_Remove(display)
	end
end

local function SetHeroSelectionHealthFrameHidden(player, hidden)
	if player == nil then return end
	CustomGameEventManager:Send_ServerToPlayer(player, "xhs_hero_selection_transition", {
		active = hidden == true and 1 or 0,
	})
end

local function StartHeroSelectionDestinationTeleport(position)
	local particle = ParticleManager:CreateParticle(
		HERO_SELECTION_DESTINATION_PARTICLE,
		PATTACH_WORLDORIGIN,
		nil
	)
	ParticleManager:SetParticleControl(particle, 0, position)
	ParticleManager:SetParticleControl(particle, 1, position)
	return particle
end

local function AwakenSelectedHero(newHero, baseTransform, destinationParticle, player)
	DestroyHeroSelectionParticle(destinationParticle, false)
	if newHero == nil or newHero:IsNull() then
		SetHeroSelectionHealthFrameHidden(player, false)
		return
	end

	newHero:AddNoDraw()
	local basePosition = baseTransform.position
	FindClearSpaceForUnit(newHero, basePosition, true)
	basePosition = newHero:GetAbsOrigin()
	newHero:SetRespawnPosition(basePosition)
	newHero.xhs_base_respawn_position = basePosition
	local baseAngles = baseTransform.angles
	newHero:SetAngles(baseAngles.x, baseAngles.y, baseAngles.z)
	newHero:Stop()
	newHero:AddNewModifier(newHero, nil, "modifier_command_restricted", {
		duration = HERO_SELECTION_ARRIVAL_DURATION,
	})
	StartAnimation(newHero, {
		duration = HERO_SELECTION_ARRIVAL_DURATION,
		activity = ACT_DOTA_TELEPORT,
		rate = 1.0,
	})

	local arrivalParticle = ParticleManager:CreateParticle(
		HERO_SELECTION_ARRIVAL_PARTICLE,
		PATTACH_ABSORIGIN_FOLLOW,
		newHero,
		newHero
	)
	EmitSoundOnLocationWithCaster(basePosition, "Portal.Hero_Appear", newHero)
	newHero:RemoveNoDraw()
	SetHeroSelectionHealthFrameHidden(player, false)

	Timers:CreateTimer(HERO_SELECTION_ARRIVAL_DURATION, function()
		DestroyHeroSelectionParticle(arrivalParticle, false)
		return nil
	end)
end

function XHSBeginHeroSelectionTransition(id, pickedHeroName, oldHero, startingGold, group, index)
	if not IsValidSelectionUnit(oldHero) or oldHero.xhs_hero_selection_transition == true then return end

	local transform = GetSelectionTransform(group, index, pickedHeroName)
	local baseTransform = GetHeroSelectionBaseTransform(id)
	if baseTransform == nil then return end

	if XHSBots ~= nil and XHSBots.OnHumanHeroSelected ~= nil then
		XHSBots:OnHumanHeroSelected(id, pickedHeroName)
	end

	-- Begin loading immediately, but do not create the real hero until the
	-- source teleport and camera travel have both completed.
	XHSPrecache:PrecacheUnit(pickedHeroName, nil, id)

	oldHero.xhs_hero_selection_transition = true
	oldHero:AddNewModifier(oldHero, nil, "modifier_command_restricted", {
		duration = HERO_SELECTION_TELEPORT_DURATION + 2.0,
	})
	oldHero:AddNewModifier(oldHero, nil, "modifier_xhs_cinematic_hide_health_bars", {
		duration = HERO_SELECTION_TELEPORT_DURATION + 2.0,
	})
	oldHero:AddNoDraw()

	local player = PlayerResource:GetPlayer(id)
	SetHeroSelectionHealthFrameHidden(player, true)
	local sourceParticles = StartHeroSelectionSourceTeleport(transform)
	local destinationParticle = nil

	Timers:CreateTimer(HERO_SELECTION_SOURCE_HOLD, function()
		destinationParticle = StartHeroSelectionDestinationTeleport(baseTransform.position)
		if player ~= nil then
			CustomGameEventManager:Send_ServerToPlayer(player, "set_player_camera", {
				hPosition = baseTransform.position,
				iSpeed = HERO_SELECTION_CAMERA_SPEED,
			})
		end
		return nil
	end)

	Timers:CreateTimer(HERO_SELECTION_TELEPORT_DURATION, function()
		FinishHeroSelectionSourceTeleport(transform, sourceParticles)

		XHSPrecache:ReplaceHeroWith(id, pickedHeroName, startingGold, 0, oldHero, {
			startingItems = true,
			cleanupDelay = 0,
			teleportToBase = false,
			deferOldHeroCleanup = true,
		}, function(newHero)
			if newHero == nil or newHero:IsNull() then
				DestroyHeroSelectionParticle(destinationParticle, true)
				SetHeroSelectionHealthFrameHidden(player, false)
				if IsValidSelectionUnit(oldHero) then
					oldHero.xhs_hero_selection_transition = nil
					oldHero:RemoveNoDraw()
				end
				return
			end

			AwakenSelectedHero(newHero, baseTransform, destinationParticle, player)
		end)
		return nil
	end)
end

local function ReplaceSelectedHero(id, pickedHeroName, oldHero, difficulty, group, index)
	XHSBeginHeroSelectionTransition(
		id,
		pickedHeroName,
		oldHero,
		XHS_STARTING_GOLD[difficulty],
		group,
		index
	)
end

function SpawnHeroLoadout(hero_count)
	local left_angle = { 4, 5, 6, 7, 8, 14, 15, 16 }
	local top_angle = { 11, 12, 13, 22, 23, 24, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39 }
	local bot_angle = { 9, 10, 25, 26, 27 }

	local hero = CreateUnitByName("npc_dota_hero_" .. HEROLIST[hero_count], Entities:FindByName(nil, "choose_" .. hero_count .. "_point"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_GOODGUYS)
	hero:AddAbility("dummy_passive_vulnerable"):SetLevel(1)
	hero.is_fake_hero = true
	RegisterSelectionDisplay("standard", hero_count, hero)

	for _, angle in pairs(left_angle) do
		if angle == hero_count then
			hero:SetAngles(0, 180, 0)
		end
	end

	for _, angle in pairs(top_angle) do
		if angle == hero_count then
			hero:SetAngles(0, 90, 0)
		end
	end

	for _, angle in pairs(bot_angle) do
		if angle == hero_count then
			hero:SetAngles(0, 270, 0)
		end
	end
end

function SpawnHeroesBis()
	local hero_count = 1
	local hero_vip_count = 1

	Timers:CreateTimer(function()
		SpawnHeroLoadout(hero_count)
		if hero_count < #HEROLIST then
			hero_count = hero_count + 1
			return 0.3
		else
			return nil
		end
	end)

	Timers:CreateTimer(5.0, function()
		if hero_vip_count == 4 then
			local dummy_hero = CreateUnitByName("npc_dota_hero_chaos_knight", Entities:FindByName(nil, "choose_vip_4_point"):GetAbsOrigin() + Vector(-100, 0, 0), true, nil, nil, DOTA_TEAM_GOODGUYS)
			dummy_hero:SetAngles(0, 270, 0)
			dummy_hero:AddAbility("dummy_passive_vulnerable"):SetLevel(1)
			dummy_hero.is_fake_hero = true
			RegisterSelectionDisplay("vip", hero_vip_count, dummy_hero)
			local dummy_hero = CreateUnitByName("npc_dota_hero_keeper_of_the_light", Entities:FindByName(nil, "choose_vip_4_point"):GetAbsOrigin() + Vector(100, 0, 0), true, nil, nil, DOTA_TEAM_GOODGUYS)
			dummy_hero:SetAngles(0, 270, 0)
			dummy_hero:AddAbility("dummy_passive_vulnerable"):SetLevel(1)
			dummy_hero.is_fake_hero = true
			RegisterSelectionDisplay("vip", hero_vip_count, dummy_hero)
		elseif hero_vip_count == 8 then
			local dummy_hero = CreateUnitByName("npc_dota_hero_storm_spirit", Entities:FindByName(nil, "choose_vip_8_point"):GetAbsOrigin() + Vector(0, 100, 0), true, nil, nil, DOTA_TEAM_GOODGUYS)
			dummy_hero:SetAngles(0, 270, 0)
			dummy_hero:AddAbility("dummy_passive_vulnerable"):SetLevel(1)
			dummy_hero.is_fake_hero = true
			RegisterSelectionDisplay("vip", hero_vip_count, dummy_hero)
			local dummy_hero = CreateUnitByName("npc_dota_hero_ember_spirit", Entities:FindByName(nil, "choose_vip_8_point"):GetAbsOrigin() + Vector(-100, 0, 0), true, nil, nil, DOTA_TEAM_GOODGUYS)
			dummy_hero:SetAngles(0, 270, 0)
			dummy_hero:AddAbility("dummy_passive_vulnerable"):SetLevel(1)
			dummy_hero.is_fake_hero = true
			RegisterSelectionDisplay("vip", hero_vip_count, dummy_hero)
			local dummy_hero = CreateUnitByName("npc_dota_hero_earth_spirit", Entities:FindByName(nil, "choose_vip_8_point"):GetAbsOrigin() + Vector(100, 0, 0), true, nil, nil, DOTA_TEAM_GOODGUYS)
			dummy_hero:SetAngles(0, 270, 0)
			dummy_hero:AddAbility("dummy_passive_vulnerable"):SetLevel(1)
			dummy_hero.is_fake_hero = true
			RegisterSelectionDisplay("vip", hero_vip_count, dummy_hero)
		else
			local dummy_hero = CreateUnitByName("npc_dota_hero_" .. HEROLIST_VIP[hero_vip_count], Entities:FindByName(nil, "choose_vip_" .. hero_vip_count .. "_point"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_GOODGUYS)
			dummy_hero:AddAbility("dummy_passive_vulnerable"):SetLevel(1)
			dummy_hero:SetAngles(0, 270, 0)
			dummy_hero.is_fake_hero = true
			RegisterSelectionDisplay("vip", hero_vip_count, dummy_hero)
		end

		if hero_vip_count < #HEROLIST_VIP then
			hero_vip_count = hero_vip_count + 1
			return 0.3
		else
			return nil
		end
	end)
end

function SpawnBosses()
	_G.RAMERO_DUMMY = CreateUnitByName("npc_ramero", Entities:FindByName(nil, "point_special_arena_1"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_GOODGUYS)
	_G.RAMERO_DUMMY:SetAngles(0, 270, 0)
	_G.RAMERO_DUMMY:AddNewModifier(_G.RAMERO_DUMMY, nil, "modifier_command_restricted", {})
	_G.BARISTOL_DUMMY = CreateUnitByName("npc_baristol", Entities:FindByName(nil, "point_special_arena_2"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_GOODGUYS)
	_G.BARISTOL_DUMMY:SetAngles(0, 270, 0)
	_G.BARISTOL_DUMMY:AddNewModifier(_G.BARISTOL_DUMMY, nil, "modifier_command_restricted", {})
	_G.RAMERO_BIS_DUMMY = CreateUnitByName("npc_ramero_2", Entities:FindByName(nil, "point_special_arena_3"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_GOODGUYS)
	_G.RAMERO_BIS_DUMMY:SetAngles(0, 270, 0)
	_G.RAMERO_BIS_DUMMY:AddNewModifier(_G.RAMERO_BIS_DUMMY, nil, "modifier_command_restricted", {})

	-- Special events
	local lich_king_boss = CreateUnitByName("npc_dota_boss_lich_king", Entities:FindByName(nil, "npc_dota_spawner_lich_king"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_CUSTOM_2)
	lich_king_boss:SetAngles(0, 90, 0)
	CustomGameEventManager:Send_ServerToAllClients("hide_boss_hp", { boss_count = 1 })

	-- Suddenly non-vanilla modifiers are not working on Lich King
	lich_king_boss:AddNewModifier(lich_king_boss, nil, "modifier_invulnerable", {})
	lich_king_boss:AddNewModifier(lich_king_boss, nil, "modifier_stunned", {})
end

function ChooseHero(event)
	local hero = event.activator
	if hero == nil or hero.GetPlayerID == nil or hero:GetPlayerID() == nil then return end
	local caller = event.caller
	local id = hero:GetPlayerID()
	local difficulty = GameRules:GetCustomGameDifficulty()

	if PlayerResource:IsValidPlayer(id) and hero:GetUnitName() == "npc_dota_hero_wisp" then
		for i = 1, #HEROLIST do -- 12 = POTM.
			if caller:GetName() == "trigger_hero_" .. i then
				UTIL_Remove(Entities:FindByName(nil, "trigger_hero_" .. i))
				EmitSoundOnClient("ui.trophy_levelup", PlayerResource:GetPlayer(id))
				hero:AddNewModifier(hero, nil, "modifier_command_restricted", {})
				local picked_hero_name = "npc_dota_hero_" .. HEROLIST[i]
				Notifications:Bottom(hero:GetPlayerOwnerID(), {
					duration = 5.0,
					segments = {
						{ hero = picked_hero_name },
						{ text = "HERO: ", style = { color = "white" } },
						{ text = "#" .. picked_hero_name, style = { color = "white" } },
					},
				})

				ReplaceSelectedHero(id, picked_hero_name, hero, difficulty, "standard", i)

				return
			end
		end
	end
end

function ChooseHeroVIP(event)
	local hero = event.activator
	if hero == nil or hero.GetPlayerID == nil or hero:GetPlayerID() == nil then return end
	local caller = event.caller
	local id = hero:GetPlayerID()
	local difficulty = GameRules:GetCustomGameDifficulty()

	if PlayerResource:IsValidPlayer(id) and hero:GetUnitName() == "npc_dota_hero_wisp" then
		for i = 1, #HEROLIST_VIP do
			if caller:GetName() == "trigger_hero_vip_" .. i then
				local picked_hero_name = "npc_dota_hero_" .. HEROLIST_VIP[i]
				UTIL_Remove(Entities:FindByName(nil, "trigger_hero_vip_" .. i))
				EmitSoundOnClient("ui.trophy_levelup", PlayerResource:GetPlayer(id))
				hero:AddNewModifier(hero, nil, "modifier_command_restricted", {})
				Notifications:Bottom(hero:GetPlayerOwnerID(), {
					duration = 5.0,
					segments = {
						{ hero = picked_hero_name },
						{ text = "HERO: ", style = { color = "white" } },
						{ text = "#npc_dota_hero_" .. HEROLIST_VIP[i], style = { color = "white" } },
					},
				})

				ReplaceSelectedHero(id, picked_hero_name, hero, difficulty, "vip", i)

				if picked_hero_name == "npc_dota_hero_storm_spirit" then
					XHSPrecache:PrecacheUnit("npc_dota_hero_ember_spirit", nil, id)
					XHSPrecache:PrecacheUnit("npc_dota_hero_earth_spirit", nil, id)
				end

				return
			end
		end
	end
end
