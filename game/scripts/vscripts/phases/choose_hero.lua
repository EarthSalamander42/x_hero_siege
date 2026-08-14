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
local HERO_SELECTION_FOCUS_CAMERA_SPEED = 0.30
local HERO_SELECTION_CAMERA_SPEED = 2.25
local HERO_SELECTION_CAMERA_SETTLE = 0.20
local HERO_SELECTION_TELEPORT_DURATION =
	HERO_SELECTION_SOURCE_HOLD + HERO_SELECTION_CAMERA_SPEED + HERO_SELECTION_CAMERA_SETTLE
-- This is only a hard recovery path. It must never race the normal
-- CameraMotion on_arrive callback, especially while the client-origin
-- handshake or slow motion makes the rendered trip longer than its nominal
-- duration.
local HERO_SELECTION_FAILSAFE_DELAY = 2.0
local HERO_SELECTION_FAILSAFE_MAX_WAIT = 9.0
local HERO_SELECTION_ARRIVAL_DURATION = 0.65
local HERO_SELECTION_DISPLAYS = {
	standard = {},
	vip = {},
}
local HERO_SELECTION_MARKERS = {
	standard = {},
	vip = {},
}
local HERO_SELECTION_MARKER_EFFECT =
	"particles/econ/items/tinker/boots_of_travel/teleport_start_bots_cog.vpcf"
local HERO_SELECTION_MARKER_SEARCH_RADIUS = 224
local HERO_SELECTION_CLEANED_UP = false

local function IsValidSelectionUnit(unit)
	return unit ~= nil and IsValidEntity(unit) and not unit:IsNull()
end

local function GetHeroSelectionPoint(group, index)
	local pointName = group == "vip"
		and ("choose_vip_" .. tostring(index) .. "_point")
		or ("choose_" .. tostring(index) .. "_point")
	return Entities:FindByName(nil, pointName)
end

local function IndexHeroSelectionMarkers()
	if Entities.FindAllByClassname == nil then return 0 end
	local particles = Entities:FindAllByClassname("info_particle_system") or {}
	local claimed = {}
	local indexed = 0

	for group, maximum in pairs({
		standard = #HEROLIST,
		vip = #HEROLIST_VIP,
	}) do
		HERO_SELECTION_MARKERS[group] = HERO_SELECTION_MARKERS[group] or {}
		for index = 1, maximum do
			local current = HERO_SELECTION_MARKERS[group][index]
			if IsValidSelectionUnit(current) then
				claimed[current:entindex()] = true
				indexed = indexed + 1
			else
				HERO_SELECTION_MARKERS[group][index] = nil
				local point = GetHeroSelectionPoint(group, index)
				local nearest = nil
				local nearestDistance = HERO_SELECTION_MARKER_SEARCH_RADIUS + 0.01
				if IsValidSelectionUnit(point) then
					for _, particle in pairs(particles) do
						if IsValidSelectionUnit(particle)
							and particle.xhs_hero_selection_marker_removed ~= true
							and claimed[particle:entindex()] ~= true then
							local distance = (
								particle:GetAbsOrigin() - point:GetAbsOrigin()
							):Length2D()
							if distance < nearestDistance then
								nearest = particle
								nearestDistance = distance
							end
						end
					end
				end
				if IsValidSelectionUnit(nearest) then
					HERO_SELECTION_MARKERS[group][index] = nearest
					claimed[nearest:entindex()] = true
					indexed = indexed + 1
				end
			end
		end
	end
	return indexed
end

local function RemoveHeroSelectionMarker(group, index, removed)
	local marker = HERO_SELECTION_MARKERS[group]
		and HERO_SELECTION_MARKERS[group][index]
		or nil
	if not IsValidSelectionUnit(marker) and removed == nil then
		IndexHeroSelectionMarkers()
		marker = HERO_SELECTION_MARKERS[group]
			and HERO_SELECTION_MARKERS[group][index]
			or nil
	end
	if not IsValidSelectionUnit(marker) then return 0 end
	local entindex = marker:entindex()
	if removed ~= nil and removed[entindex] then return 0 end
	if removed ~= nil then removed[entindex] = true end
	marker.xhs_hero_selection_marker_removed = true
	if marker.Stop ~= nil then pcall(function() marker:Stop() end) end
	UTIL_Remove(marker)
	HERO_SELECTION_MARKERS[group][index] = nil
	return 1
end

local function RegisterSelectionDisplay(group, index, unit)
	if not IsValidSelectionUnit(unit) then return end
	if HERO_SELECTION_CLEANED_UP then
		UTIL_Remove(unit)
		return
	end
	HERO_SELECTION_DISPLAYS[group][index] = HERO_SELECTION_DISPLAYS[group][index] or {}
	table.insert(HERO_SELECTION_DISPLAYS[group][index], unit)
	if XHSDevTools ~= nil and XHSDevTools.selection_health_bars_enabled == true
		and XHSCreepHealthBars ~= nil and XHSCreepHealthBars.Apply ~= nil then
		unit.xhs_custom_health_bar_kind = "creep_hero"
		XHSCreepHealthBars:Apply(unit)
	end
end

local function RemoveHeroSelectionDisplay(unit, removed)
	if not IsValidSelectionUnit(unit) then return 0 end
	local entindex = unit:entindex()
	if removed[entindex] then return 0 end
	removed[entindex] = true
	unit:StopSound("Portal.Loop_Appear")
	if unit.FadeGesture ~= nil then
		unit:FadeGesture(ACT_DOTA_TELEPORT)
	end
	UTIL_Remove(unit)
	return 1
end

-- Retire every pick-screen model and map-authored floor marker in one
-- idempotent pass. This is the universal end-of-selection fail-safe, including
-- mixed human/bot rosters and Lua reloads.
function XHSCleanupHeroSelectionShowcase(reason)
	if HERO_SELECTION_CLEANED_UP then return 0, "already_cleaned" end
	HERO_SELECTION_CLEANED_UP = true

	local removed = {}
	local removedCount = 0
	local removedMarkerCount = 0
	IndexHeroSelectionMarkers()
	for group, maximum in pairs({
		standard = #HEROLIST,
		vip = #HEROLIST_VIP,
	}) do
		for index = 1, maximum do
			removedMarkerCount = removedMarkerCount
				+ RemoveHeroSelectionMarker(group, index, removed)
		end
	end
	for _, group in pairs(HERO_SELECTION_DISPLAYS) do
		for _, displays in pairs(group) do
			for _, unit in pairs(displays) do
				removedCount = removedCount
					+ RemoveHeroSelectionDisplay(unit, removed)
			end
		end
	end

	-- Lua reloads clear the local registry while engine entities remain. The
	-- marker is authoritative and excludes real player/bot heroes.
	if Entities.FindAllByClassname ~= nil then
		for _, unit in pairs(
			Entities:FindAllByClassname("npc_dota_hero") or {}
		) do
			if IsValidSelectionUnit(unit) and unit.is_fake_hero == true then
				removedCount = removedCount
					+ RemoveHeroSelectionDisplay(unit, removed)
			end
		end
	end

	HERO_SELECTION_DISPLAYS = { standard = {}, vip = {} }
	HERO_SELECTION_MARKERS = { standard = {}, vip = {} }
	print(
		"[XHS][SelectionCleanup] reason="
			.. tostring(reason or "bot_only_roster_complete")
			.. " models=" .. tostring(removedCount)
			.. " markers=" .. tostring(removedMarkerCount)
	)
	return removedCount, "cleaned", removedMarkerCount
end

-- Bot picks bypass XHSBeginHeroSelectionTransition. Expose the same immediate
-- marker cleanup without making the bot provisioner depend on local tables.
function XHSRemoveHeroSelectionMarkerForHero(heroName)
	local shortName = tostring(heroName or ""):gsub("^npc_dota_hero_", "")
	for index, candidate in ipairs(HEROLIST) do
		if candidate == shortName then
			return RemoveHeroSelectionMarker("standard", index)
		end
	end
	for index, candidate in ipairs(HEROLIST_VIP) do
		if candidate == shortName then
			return RemoveHeroSelectionMarker("vip", index)
		end
	end
	return 0
end

-- The Random pedestal is not one of the standard/VIP hero slots, so its
-- map-authored info_particle_system is intentionally absent from
-- HERO_SELECTION_MARKERS. Remove the nearest unclaimed selection marker while
-- the Wisp is still standing on the pedestal, before the transition moves it.
function XHSRemoveRandomHeroSelectionMarker(position)
	if position == nil or Entities.FindAllByClassname == nil then return 0 end

	IndexHeroSelectionMarkers()
	local claimed = {}
	for _, group in pairs(HERO_SELECTION_MARKERS) do
		for _, marker in pairs(group) do
			if IsValidSelectionUnit(marker) then
				claimed[marker:entindex()] = true
			end
		end
	end

	local nearest = nil
	local nearestDistance = HERO_SELECTION_MARKER_SEARCH_RADIUS + 0.01
	for _, particle in pairs(Entities:FindAllByClassname("info_particle_system") or {}) do
		if IsValidSelectionUnit(particle)
			and particle.xhs_hero_selection_marker_removed ~= true
			and claimed[particle:entindex()] ~= true then
			local distance = (particle:GetAbsOrigin() - position):Length2D()
			if distance < nearestDistance then
				nearest = particle
				nearestDistance = distance
			end
		end
	end

	if not IsValidSelectionUnit(nearest) then return 0 end
	nearest.xhs_hero_selection_marker_removed = true
	if nearest.Stop ~= nil then pcall(function() nearest:Stop() end) end
	UTIL_Remove(nearest)
	return 1
end

-- Most selection circles are authored directly in the map. Keep a runtime
-- fallback for valid hero pedestals whose info_particle_system is missing
-- (notably Priestess of the Moon) so every selectable hero has the same
-- visual marker and the normal marker cleanup can still remove it.
local function EnsureHeroSelectionMarkers()
	local created = 0
	for group, heroes in pairs({
		standard = HEROLIST,
		vip = HEROLIST_VIP,
	}) do
		HERO_SELECTION_MARKERS[group] = HERO_SELECTION_MARKERS[group] or {}
		for index in ipairs(heroes) do
			local marker = HERO_SELECTION_MARKERS[group][index]
			local point = GetHeroSelectionPoint(group, index)
			local triggerName = group == "vip"
				and ("trigger_hero_vip_" .. tostring(index))
				or ("trigger_hero_" .. tostring(index))
			local trigger = Entities:FindByName(nil, triggerName)

			if not IsValidSelectionUnit(marker)
				and IsValidSelectionUnit(point)
				and IsValidSelectionUnit(trigger) then
				marker = SpawnEntityFromTableSynchronous("info_particle_system", {
					effect_name = HERO_SELECTION_MARKER_EFFECT,
					origin = point:GetAbsOrigin(),
					start_active = "0",
				})
				if IsValidSelectionUnit(marker) then
					marker:SetAbsOrigin(point:GetAbsOrigin())
					marker.xhs_hero_selection_marker_fallback = true
					HERO_SELECTION_MARKERS[group][index] = marker
					if marker.Start ~= nil then
						pcall(function() marker:Start() end)
					end
					created = created + 1
				end
			end
		end
	end
	return created
end

-- XHS performs its physical pick screen during PRE_GAME, so the engine state
-- cannot tell us when selection is over. The phase is complete only once every
-- connected Radiant participant (humans and bots, never spectators) owns a
-- real hero other than the temporary Wisp.
function XHSTryCleanupHeroSelectionShowcase(reason)
	if HERO_SELECTION_CLEANED_UP then return false, "already_cleaned" end
	local participants = 0
	for playerID = 0, DOTA_MAX_TEAM_PLAYERS - 1 do
		local isParticipant = PlayerResource:IsValidPlayerID(playerID)
			and PlayerResource:GetPlayer(playerID) ~= nil
			and PlayerResource:GetTeam(playerID) == DOTA_TEAM_GOODGUYS
		if isParticipant then
			participants = participants + 1
			local hero = PlayerResource:GetSelectedHeroEntity(playerID)
			if not IsValidSelectionUnit(hero)
				or hero:GetUnitName() == "npc_dota_hero_wisp" then
				return false, "waiting_for_player_" .. tostring(playerID)
			end
		end
	end
	if participants == 0 then return false, "no_participants" end
	XHSCleanupHeroSelectionShowcase(reason or "all_participants_selected")
	return true, "cleaned"
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

	-- Lua can be reloaded after the showcase units have spawned, which clears
	-- the local registry above. All hero displays share the engine classname
	-- "npc_dota_hero"; GetUnitName is the field that identifies the picked hero.
	if not IsValidSelectionUnit(primary) and Entities.FindAllByClassname ~= nil then
		local nearestDistance = nil
		for _, unit in pairs(Entities:FindAllByClassname("npc_dota_hero") or {}) do
			local validUnit = IsValidSelectionUnit(unit)
			local ownerID = validUnit and unit.GetPlayerOwnerID ~= nil
				and unit:GetPlayerOwnerID() or -1
			if validUnit
				and unit:GetUnitName() == pickedHeroName
				and (unit.is_fake_hero == true or ownerID < 0)
			then
				local distance = point ~= nil
					and (unit:GetAbsOrigin() - point:GetAbsOrigin()):Length2D()
					or 0
				if distance <= 600
					and (nearestDistance == nil or distance < nearestDistance) then
					primary = unit
					nearestDistance = distance
				end
			end
		end
		if IsValidSelectionUnit(primary) then
			table.insert(displays, primary)
		end
	end

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

local function StartHeroSelectionDisplayTeleport(display)
	if not IsValidSelectionUnit(display) then return end

	-- Selection displays are kept motionless by dummy_passive_vulnerable,
	-- whose data-driven modifier applies MODIFIER_STATE_STUNNED. That state
	-- wins over ACT_DOTA_TELEPORT on several hero models. The display has
	-- already been consumed at this point, so retire the clickable passive
	-- and keep it safe through explicit cinematic states instead.
	if display.RemoveAbility ~= nil then
		display:RemoveAbility("dummy_passive_vulnerable")
	end
	display:RemoveModifierByName("modifier_dummy_vulnerable")
	display:AddNewModifier(display, nil, "modifier_invulnerable", {
		duration = HERO_SELECTION_TELEPORT_DURATION,
	})
	display:AddNewModifier(display, nil, "modifier_command_restricted", {
		duration = HERO_SELECTION_TELEPORT_DURATION,
	})

	-- Showcase heroes are unowned. Native gestures can remain server-only on
	-- those entities, so use XHS' replicated animation modifier first.
	if type(StartAnimation) == "function" then
		StartAnimation(display, {
			duration = HERO_SELECTION_TELEPORT_DURATION,
			activity = ACT_DOTA_TELEPORT,
			rate = 1.0,
		})
	end
	if display.StartGestureWithPlaybackRate ~= nil then
		display:StartGestureWithPlaybackRate(ACT_DOTA_TELEPORT, 1.0)
	elseif display.StartGesture ~= nil then
		display:StartGesture(ACT_DOTA_TELEPORT)
	end
end

local function StopHeroSelectionDisplayTeleport(display)
	if not IsValidSelectionUnit(display) then return end
	if type(EndAnimation) == "function" then EndAnimation(display) end
	if display.FadeGesture ~= nil then
		display:FadeGesture(ACT_DOTA_TELEPORT)
	elseif display.RemoveGesture ~= nil then
		display:RemoveGesture(ACT_DOTA_TELEPORT)
	end
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

local function StartHeroSelectionSourceTeleport(transform, playerID, particleOwner)
	local particles = {}
	local display = transform.display
	-- Force the current vanilla particle while validating its modern control
	-- point contract. Cosmetic replacements can be restored after this test.
	local sourceParticle = HERO_SELECTION_SOURCE_PARTICLE
	if IsValidSelectionUnit(display) then
		display:AddNewModifier(display, nil, "modifier_xhs_cinematic_hide_health_bars", {
			duration = HERO_SELECTION_TELEPORT_DURATION,
		})
		StartHeroSelectionDisplayTeleport(display)
		local sourcePosition = display:GetAbsOrigin()
		local networkOwner = IsValidSelectionUnit(particleOwner)
			and particleOwner or display
		local particle = ParticleManager:CreateParticle(
			sourceParticle,
			PATTACH_ABSORIGIN,
			networkOwner
		)
		ParticleManager:SetParticleControlEnt(
			particle,
			0,
			networkOwner,
			PATTACH_ABSORIGIN,
			nil,
			sourcePosition,
			true
		)
		ParticleManager:SetParticleControl(particle, 2, Vector(1, 1, 1))
		ParticleManager:SetParticleControl(
			particle,
			7,
			Vector(HERO_SELECTION_TELEPORT_DURATION, 0, 0)
		)
		table.insert(particles, particle)
		display:EmitSound("Portal.Loop_Appear")
	end

	if #particles == 0 and transform.position ~= nil then
		local particle = ParticleManager:CreateParticle(
			sourceParticle,
			PATTACH_WORLDORIGIN,
			nil
		)
		ParticleManager:SetParticleControl(particle, 0, transform.position)
		ParticleManager:SetParticleControl(
			particle,
			7,
			Vector(HERO_SELECTION_TELEPORT_DURATION, 0, 0)
		)
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
		StopHeroSelectionDisplayTeleport(display)
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

local function StartHeroSelectionDestinationTeleport(position, playerID)
	local destinationParticle = XHSGetBattlepassParticle ~= nil
		and XHSGetBattlepassParticle(playerID, "teleport_end_pfx", HERO_SELECTION_DESTINATION_PARTICLE)
		or HERO_SELECTION_DESTINATION_PARTICLE
	local particle = ParticleManager:CreateParticle(
		destinationParticle,
		PATTACH_WORLDORIGIN,
		nil
	)
	ParticleManager:SetParticleControl(particle, 0, position)
	ParticleManager:SetParticleControl(particle, 1, position)
	return particle
end

local function AwakenSelectedHero(newHero, baseTransform, destinationParticle, player, playerID)
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

	local arrivalParticlePath = XHSGetBattlepassParticle ~= nil
		and XHSGetBattlepassParticle(newHero, "teleport_start_pfx", HERO_SELECTION_ARRIVAL_PARTICLE)
		or HERO_SELECTION_ARRIVAL_PARTICLE
	local arrivalParticle = ParticleManager:CreateParticle(
		arrivalParticlePath,
		PATTACH_ABSORIGIN_FOLLOW,
		newHero
	)
	ParticleManager:SetParticleControl(
		arrivalParticle,
		7,
		Vector(HERO_SELECTION_ARRIVAL_DURATION, 0, 0)
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

	-- The map-placed Boots of Travel marker is an independent
	-- info_particle_system, not a child of the showcase hero. Retire it as soon
	-- as this slot is consumed instead of keeping its client particle alive.
	RemoveHeroSelectionMarker(group, index)

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
	local selectionCameraOrigin = oldHero:GetAbsOrigin()

	local player = PlayerResource:GetPlayer(id)
	SetHeroSelectionHealthFrameHidden(player, true)
	if player ~= nil and transform.position ~= nil then
		-- First frame of the transition belongs to the selected showcase unit.
		-- The existing delayed move to the base remains the second camera beat.
		CameraMotion:Move(id, transform.position, {
			from = selectionCameraOrigin,
			duration = HERO_SELECTION_FOCUS_CAMERA_SPEED,
			easing = "smootherstep",
			owner = "hero_selection",
			priority = 70,
			policy = "replace",
			persistent = true,
		})
	end
	local sourceParticles = {}
	local sourcePosition = IsValidSelectionUnit(transform.display)
		and transform.display:GetAbsOrigin() or transform.position
	if sourcePosition ~= nil then
		oldHero:SetAbsOrigin(sourcePosition)
		oldHero:Stop()
	end
	-- Particle ownership is resolved client-side from the networked Wisp
	-- transform. Give that transform two server frames to replicate before the
	-- vanilla hierarchy is created, otherwise it starts at the Wisp's old spot.
	Timers:CreateTimer(0.06, function()
		local createdParticles = StartHeroSelectionSourceTeleport(transform, id, oldHero)
		for _, particle in pairs(createdParticles) do
			table.insert(sourceParticles, particle)
		end
		return nil
	end)
	local destinationParticle = nil
	local transitionCompleted = false
	local travelHandle = nil

	local function CompleteSelectionTransition()
		if transitionCompleted then return end
		transitionCompleted = true
		FinishHeroSelectionSourceTeleport(transform, sourceParticles)

		XHSPrecache:ReplaceHeroWith(id, pickedHeroName, startingGold, 0, oldHero, {
			startingItems = true,
			cleanupDelay = 0,
			teleportToBase = false,
			deferOldHeroCleanup = true,
		}, function(newHero)
			-- ReplaceHeroWith changes the selected unit and can reset the client
			-- camera target. Restore the already-arrived camera dummy before
			-- revealing the new hero and keep it locked for the full TP arrival.
			if CameraMotion ~= nil and CameraMotion.RefreshTarget ~= nil then
				CameraMotion:RefreshTarget(id, "hero_selection")
			end
			if newHero == nil or newHero:IsNull() then
				DestroyHeroSelectionParticle(destinationParticle, true)
				SetHeroSelectionHealthFrameHidden(player, false)
				if IsValidSelectionUnit(oldHero) then
					oldHero.xhs_hero_selection_transition = nil
					oldHero:RemoveNoDraw()
				end
				return
			end

			AwakenSelectedHero(newHero, baseTransform, destinationParticle, player, id)
			Timers:CreateTimer(HERO_SELECTION_ARRIVAL_DURATION, function()
				if XHSTryCleanupHeroSelectionShowcase ~= nil then
					XHSTryCleanupHeroSelectionShowcase("all_participants_selected")
				end
				return nil
			end)
		end)
	end

	Timers:CreateTimer(HERO_SELECTION_SOURCE_HOLD, function()
		destinationParticle = StartHeroSelectionDestinationTeleport(baseTransform.position, id)
		if player ~= nil then
			travelHandle = CameraMotion:Move(id, baseTransform.position, {
				duration = HERO_SELECTION_CAMERA_SPEED,
				easing = "smootherstep",
				-- Dummy arrival is not rendered-camera arrival: Dota keeps
				-- smoothing the view after SetCameraTarget reaches its endpoint.
				-- Require two client position samples at the destination before
				-- ReplaceHeroWith is allowed to reset the camera target.
				confirm_rendered_arrival = true,
				rendered_arrival_epsilon = 96,
				rendered_arrival_samples = 2,
				rendered_arrival_interval = 0.10,
				rendered_arrival_timeout = 8.0,
				owner = "hero_selection",
				priority = 70,
				policy = "replace",
				hold = HERO_SELECTION_CAMERA_SETTLE + HERO_SELECTION_ARRIVAL_DURATION,
				release = "free",
				on_arrive = function()
					-- Dummy arrival is server-authoritative, but the rendered
					-- camera needs a short settling window to catch the moving
					-- target. Replacing the hero immediately here visibly cuts
					-- the final part of the travelling.
					Timers:CreateTimer(HERO_SELECTION_CAMERA_SETTLE, function()
						CompleteSelectionTransition()
						return nil
					end)
				end,
			})
		end
		return nil
	end)

	-- Hard recovery for a missing/rejected/cancelled request. A live request is
	-- allowed to finish: replacing the Wisp while its camera dummy is still
	-- travelling resets SetCameraTarget and visibly cuts the trip.
	local failsafeDeadline = GameRules:GetGameTime()
		+ HERO_SELECTION_TELEPORT_DURATION
		+ HERO_SELECTION_FAILSAFE_DELAY
		+ HERO_SELECTION_FAILSAFE_MAX_WAIT
	Timers:CreateTimer(HERO_SELECTION_TELEPORT_DURATION + HERO_SELECTION_FAILSAFE_DELAY, function()
		if transitionCompleted then return nil end
		if travelHandle ~= nil
			and travelHandle.IsActive ~= nil
			and travelHandle:IsActive()
			and travelHandle.HasArrived ~= nil
			and not travelHandle:HasArrived()
			and GameRules:GetGameTime() < failsafeDeadline then
			return 0.10
		end
		CompleteSelectionTransition()
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
	if HERO_SELECTION_CLEANED_UP then return end
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

local function RemoveUnavailableHeroSelectionMarkers()
	local removed = 0
	for group, heroes in pairs({
		standard = HEROLIST,
		vip = HEROLIST_VIP,
	}) do
		for index in ipairs(heroes) do
			local triggerName = group == "vip"
				and ("trigger_hero_vip_" .. tostring(index))
				or ("trigger_hero_" .. tostring(index))
			if Entities:FindByName(nil, triggerName) == nil then
				removed = removed + RemoveHeroSelectionMarker(group, index)
			end
		end
	end
	if removed > 0 then
		print("[XHS][SelectionCleanup] unavailable_hero_markers=" .. tostring(removed))
	end
	return removed
end

function SpawnHeroesBis()
	IndexHeroSelectionMarkers()
	RemoveUnavailableHeroSelectionMarkers()
	EnsureHeroSelectionMarkers()
	local hero_count = 1
	local hero_vip_count = 1

	Timers:CreateTimer(function()
		if HERO_SELECTION_CLEANED_UP then return nil end
		SpawnHeroLoadout(hero_count)
		if hero_count < #HEROLIST then
			hero_count = hero_count + 1
			return 0.3
		else
			return nil
		end
	end)

	Timers:CreateTimer(5.0, function()
		if HERO_SELECTION_CLEANED_UP then return nil end
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
	_G.RAMERO_DUMMY:SetMoveCapability(DOTA_UNIT_CAP_MOVE_NONE)
	_G.RAMERO_DUMMY:AddNewModifier(_G.RAMERO_DUMMY, nil, "modifier_command_restricted", {})
	_G.BARISTOL_DUMMY = CreateUnitByName("npc_baristol", Entities:FindByName(nil, "point_special_arena_2"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_GOODGUYS)
	_G.BARISTOL_DUMMY:SetAngles(0, 270, 0)
	_G.BARISTOL_DUMMY:SetMoveCapability(DOTA_UNIT_CAP_MOVE_NONE)
	_G.BARISTOL_DUMMY:AddNewModifier(_G.BARISTOL_DUMMY, nil, "modifier_command_restricted", {})
	_G.RAMERO_BIS_DUMMY = CreateUnitByName("npc_ramero_2", Entities:FindByName(nil, "point_special_arena_3"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_GOODGUYS)
	_G.RAMERO_BIS_DUMMY:SetAngles(0, 270, 0)
	_G.RAMERO_BIS_DUMMY:SetMoveCapability(DOTA_UNIT_CAP_MOVE_NONE)
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
