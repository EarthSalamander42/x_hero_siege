local stored_companions = {}
local companion_spawn_tokens = {}
local companion_error_notifications = {}
local stored_statues = {}
local statue_slots = {}
local COMPANION_SPAWN_UNIT = "npc_donator_companion"

local function CompanionLog(message, ...)
	-- Intentionally silent: companion diagnostics must not spam the server.
end

local function IsTruthyKV(value)
	return value == true or value == 1 or value == "1" or value == "true"
end

local function GetCompanionDefinition(unit_name)
	local companions = LoadKeyValues("scripts/npc/units/companions.txt") or {}
	local definition = companions[unit_name]
	if type(definition) == "table" then
		return definition
	end

	return nil
end

local function ResolveCompanionCatalogUnitName(requested)
	local requestedID = tostring(requested or "")
	if requestedID == "" or api == nil or type(api.companions) ~= "table" then
		return nil
	end

	for catalogKey, catalogEntry in pairs(api.companions) do
		if type(catalogEntry) == "table" then
			local identifiers = {
				catalogKey,
				catalogEntry.id,
				catalogEntry.item_id,
				catalogEntry.entitlement_id,
				catalogEntry.catalog_item_id,
				catalogEntry.reward_item_id,
			}
			local matches = false
			for _, identifier in pairs(identifiers) do
				if identifier ~= nil and tostring(identifier) == requestedID then
					matches = true
					break
				end
			end

			if matches then
				local unitName = catalogEntry.unit
					or catalogEntry.unit_name
					or catalogEntry.file
					or catalogEntry.npc_name
				if type(unitName) == "string" and GetCompanionDefinition(unitName) ~= nil then
					return unitName
				end
			end
		end
	end

	return nil
end

local function NotifyUnavailableCompanion(playerID, requested)
	local requestedID = tostring(requested or "")
	local now = GameRules and GameRules.GetGameTime and GameRules:GetGameTime() or 0
	local previous = companion_error_notifications[playerID]
	if previous ~= nil and previous.requested == requestedID and now - previous.time < 8 then
		return
	end

	companion_error_notifications[playerID] = {
		requested = requestedID,
		time = now,
	}

	local payload = {
		text = "#xhs_sp_companion_runtime_unavailable",
		duration = 5,
		severity = "system",
	}
	if Notifications ~= nil and Notifications.Bottom ~= nil then
		Notifications:Bottom(playerID, payload)
		return
	end

	local player = PlayerResource:GetPlayer(playerID)
	if player ~= nil then
		CustomGameEventManager:Send_ServerToPlayer(player, "bottom_notification", payload)
	end
end

local function AttachCompanionAmbientEffect(companion, definition)
	if companion == nil or companion:IsNull() or type(definition) ~= "table" then return end

	local particleName = definition.AmbientParticle
	if type(particleName) ~= "string" or particleName == "" then return end

	local particle = ParticleManager:CreateParticle(particleName, PATTACH_ABSORIGIN_FOLLOW, companion)
	local attachment = definition.AmbientAttachment
	if type(attachment) == "string" and attachment ~= "" then
		ParticleManager:SetParticleControlEnt(particle, 0, companion, PATTACH_POINT_FOLLOW, attachment, companion:GetAbsOrigin(), true)
	end
	ParticleManager:ReleaseParticleIndex(particle)

	companion.xhs_companion_ambient_particle = particleName
	CompanionLog("ambient attached ent=%s particle=%s attachment=%s", tostring(companion:entindex()), particleName, tostring(attachment or "origin"))
end

function Battlepass:DonatorCompanion(ID, unit_name, js)
	CompanionLog("request player=%s unit=%s js=%s", tostring(ID), tostring(unit_name), tostring(js))
	local player = PlayerResource:GetPlayer(ID)
	if player == nil then
		CompanionLog("abort player=%s: PlayerResource:GetPlayer returned nil", tostring(ID))
		return
	end

	local hero = player:GetAssignedHero()
	if hero == nil or hero:IsNull() then
		CompanionLog("abort player=%s: assigned hero is unavailable", tostring(ID))
		return
	end
	CompanionLog("hero player=%s ent=%s unit=%s origin=%s", tostring(ID), tostring(hero:entindex()), tostring(hero:GetUnitName()), tostring(hero:GetAbsOrigin()))

	if stored_companions[ID] then
		CompanionLog("removing previous companion player=%s ent=%s model=%s", tostring(ID), tostring(stored_companions[ID]:entindex()), tostring(stored_companions[ID]:GetModelName()))
		-- ForceKill on roshan companions results in global death sound which is annoying

		--stored_companions[ID]:ForceKill(false)

		if stored_companions[ID].RemoveSelf then
			stored_companions[ID]:RemoveSelf()
		end
	end

	-- Invalidate any asynchronous precache callback before disabling or replacing
	-- the current companion, otherwise an older preview can respawn after cleanup.
	companion_spawn_tokens[ID] = (companion_spawn_tokens[ID] or 0) + 1
	local spawnToken = companion_spawn_tokens[ID]

	-- Disabled companion
	if unit_name == "" then
		CompanionLog("disabled player=%s", tostring(ID))
		stored_companions[ID] = nil
		hero.companion = nil
		return
	end

	if UNIQUE_DONATOR_COMPANION[tostring(PlayerResource:GetSteamID(ID))] and not js then
		unit_name = UNIQUE_DONATOR_COMPANION[tostring(PlayerResource:GetSteamID(ID))]
	end

	if unit_name ~= nil and unit_name ~= "" and api ~= nil and api.GetPlayerCompanionShown ~= nil and not api:GetPlayerCompanionShown(ID) then
		CompanionLog("suppressed player=%s: show_companion setting is disabled", tostring(ID))
		stored_companions[ID] = nil
		hero.companion = nil
		return
	end

	-- A missing companion means disabled. Never replace an invalid or incomplete
	-- backend mapping with an unrelated cosmetic.
	if unit_name == nil or unit_name == false then
		CompanionLog("disabled player=%s: no companion mapping", tostring(ID))
		stored_companions[ID] = nil
		hero.companion = nil
		return
	end

	local companionDefinition = GetCompanionDefinition(unit_name)
	if companionDefinition == nil then
		local catalogUnitName = ResolveCompanionCatalogUnitName(unit_name)
		if catalogUnitName ~= nil then
			CompanionLog("catalog resolved player=%s item=%s unit=%s", tostring(ID), tostring(unit_name), catalogUnitName)
			unit_name = catalogUnitName
			companionDefinition = GetCompanionDefinition(unit_name)
		end
	end
	if companionDefinition == nil then
		CompanionLog("rejected player=%s: unknown or incomplete companion mapping '%s'", tostring(ID), tostring(unit_name))
		stored_companions[ID] = nil
		hero.companion = nil
		NotifyUnavailableCompanion(ID, unit_name)
		return
	end

	local model = companionDefinition["Model"]
	local model_scale = companionDefinition["ModelScale"]
	CompanionLog("resolved player=%s unit=%s model=%s scale=%s ambient=%s attachment=%s flying=%s token=%s", tostring(ID), tostring(unit_name), tostring(model), tostring(model_scale), tostring(companionDefinition.AmbientParticle), tostring(companionDefinition.AmbientAttachment), tostring(companionDefinition.IsFlying), tostring(spawnToken))

	CompanionLog("precache begin player=%s unit=%s", tostring(ID), tostring(unit_name))
	XHSPrecache:PrecacheCompanion(unit_name, function()
		if companion_spawn_tokens[ID] ~= spawnToken then
			CompanionLog("precache callback ignored player=%s unit=%s stale_token=%s current_token=%s", tostring(ID), tostring(unit_name), tostring(spawnToken), tostring(companion_spawn_tokens[ID]))
			return
		end
		CompanionLog("precache complete player=%s unit=%s token=%s", tostring(ID), tostring(unit_name), tostring(spawnToken))
		Battlepass:SpawnDonatorCompanion(ID, unit_name, companionDefinition)
	end, ID)
end

function Battlepass:SpawnDonatorCompanion(ID, unit_name, companionDefinition)
	companionDefinition = companionDefinition or {}
	local model = companionDefinition.Model
	local model_scale = companionDefinition.ModelScale
	CompanionLog("spawn begin player=%s unit=%s model=%s scale=%s", tostring(ID), tostring(unit_name), tostring(model), tostring(model_scale))
	local player = PlayerResource:GetPlayer(ID)
	if player == nil then
		CompanionLog("spawn abort player=%s: player missing", tostring(ID))
		return
	end

	local hero = player:GetAssignedHero()
	if hero == nil or hero:IsNull() then
		CompanionLog("spawn abort player=%s: hero missing", tostring(ID))
		return
	end

	local spawnOrigin = hero:GetAbsOrigin() + RandomVector(200)
	-- The catalog entries use npc_donator_companion as a KV template name, but
	-- Source 2 does not instantiate those names as entity classes. Spawn the
	-- concrete base unit and apply the selected model/cosmetics below.
	local companion = CreateUnitByName(COMPANION_SPAWN_UNIT, spawnOrigin, true, hero, hero, hero:GetTeamNumber())
	if companion == nil then
		CompanionLog("spawn failed player=%s requested_unit=%s spawn_unit=%s", tostring(ID), tostring(unit_name), COMPANION_SPAWN_UNIT)
		return
	end

	companion:SetOwner(hero)
	companion.xhs_companion_unit_name = unit_name
	companion.xhs_companion_is_flying = IsTruthyKV(companionDefinition.IsFlying)

	if model then
		companion:SetModel(model)
		companion:SetOriginalModel(model)
	end

	companion:RemoveNoDraw()
	local modifier = companion:AddNewModifier(companion, nil, "modifier_companion", {})

	stored_companions[ID] = companion
	hero.companion = companion
	CompanionLog("spawned player=%s ent=%s requested_unit=%s actual_unit=%s model=%s modifier=%s origin=%s hero_origin=%s", tostring(ID), tostring(companion:entindex()), tostring(unit_name), tostring(companion:GetUnitName()), tostring(companion:GetModelName()), tostring(modifier ~= nil), tostring(companion:GetAbsOrigin()), tostring(hero:GetAbsOrigin()))

	if model == "models/courier/baby_rosh/babyroshan.vmdl" then
		local particle_name = {}
		particle_name[0] = "particles/econ/courier/courier_donkey_ti7/courier_donkey_ti7_ambient.vpcf"
		particle_name[1] = "particles/econ/courier/courier_golden_roshan/golden_roshan_ambient.vpcf"
		particle_name[2] = "particles/econ/courier/courier_platinum_roshan/platinum_roshan_ambient.vpcf"
		particle_name[3] = "particles/econ/courier/courier_roshan_darkmoon/courier_roshan_darkmoon.vpcf" -- particles/econ/courier/courier_roshan_darkmoon/courier_roshan_darkmoon_flying.vpcf
		particle_name[4] = "particles/econ/courier/courier_roshan_desert_sands/baby_roshan_desert_sands_ambient.vpcf"
		particle_name[5] = "particles/econ/courier/courier_roshan_ti8/courier_roshan_ti8.vpcf"
		particle_name[6] = "particles/econ/courier/courier_roshan_lava/courier_roshan_lava.vpcf"
		particle_name[7] = "particles/econ/courier/courier_roshan_frost/courier_roshan_frost_ambient.vpcf"
		particle_name[8] = "particles/econ/courier/courier_babyroshan_winter18/courier_babyroshan_winter18_ambient.vpcf"
		particle_name[9] = "particles/econ/courier/courier_babyroshan_ti9/courier_babyroshan_ti9_ambient.vpcf"

		--		if RandomInt(1, 2) == 2 then
		--			model = model.."_flying"
		--		end

		-- also attach eyes effect later
		local random_int = RandomInt(0, #particle_name)

		local particle = ParticleManager:CreateParticle(particle_name[random_int], PATTACH_ABSORIGIN_FOLLOW, companion)
		if random_int <= 5 then
			companion:SetMaterialGroup(tostring(random_int))
		elseif random_int == 6 or random_int == 7 then
			companion:SetModel("models/courier/baby_rosh/babyroshan_elemental.vmdl")
			companion:SetOriginalModel("models/courier/baby_rosh/babyroshan_elemental.vmdl")
			companion:SetMaterialGroup(tostring(random_int - 5))
		elseif random_int == 8 then
			companion:SetModel("models/courier/baby_rosh/babyroshan_winter18.vmdl")
			companion:SetOriginalModel("models/courier/baby_rosh/babyroshan_winter18.vmdl")
		elseif random_int == 9 then
			companion:SetModel("models/courier/baby_rosh/babyroshan_ti9.vmdl")
			companion:SetOriginalModel("models/courier/baby_rosh/babyroshan_ti9.vmdl")
		end
	elseif unit_name == "npc_donator_companion_suthernfriend" then
		companion:SetMaterialGroup("1")
	elseif unit_name == "npc_donator_companion_golden_venoling" then
		companion:SetMaterialGroup("1")
	end

	companion:SetModelScale(tonumber(model_scale) or 1.0)

	AttachCompanionAmbientEffect(companion, companionDefinition)

	-- Cosmetics
	CompanionCosmetics(companion, unit_name)

	Timers:CreateTimer(0.25, function()
		if companion == nil or companion:IsNull() then
			CompanionLog("post-spawn player=%s: companion disappeared", tostring(ID))
			return nil
		end
		local currentHero = player:GetAssignedHero()
		local heroOrigin = currentHero and not currentHero:IsNull() and currentHero:GetAbsOrigin() or Vector(0, 0, 0)
		CompanionLog("post-spawn player=%s ent=%s alive=%s model=%s scale=%.2f ambient=%s flying=%s origin=%s distance=%.1f modifier=%s invisible=%s", tostring(ID), tostring(companion:entindex()), tostring(companion:IsAlive()), tostring(companion:GetModelName()), tonumber(companion:GetModelScale()) or -1, tostring(companion.xhs_companion_ambient_particle), tostring(companion.xhs_companion_is_flying), tostring(companion:GetAbsOrigin()), (companion:GetAbsOrigin() - heroOrigin):Length2D(), tostring(companion:HasModifier("modifier_companion")), tostring(companion:HasModifier("modifier_invisible")))
		return nil
	end)
end

function CompanionCosmetics(unit, unit_name)
	if unit ~= nil and not unit:IsNull() and UNIT_EQUIPMENT and UNIT_EQUIPMENT[unit_name] then
		for _, wearable in pairs(UNIT_EQUIPMENT[unit_name]) do
			local cosmetic = CreateUnitByName("wearable_dummy", unit:GetAbsOrigin(), false, nil, nil, unit:GetTeam())
			if cosmetic ~= nil and not cosmetic:IsNull() then
				cosmetic:SetOriginalModel(wearable)
				cosmetic:SetModel(wearable)
				cosmetic:AddNewModifier(cosmetic, nil, "modifier_wearable", {})
				cosmetic:SetParent(unit, nil)
				cosmetic:FollowEntity(unit, true)

				if wearable == "models/items/pudge/scorching_talon/scorching_talon.vmdl" then
					local particle = ParticleManager:CreateParticle("particles/econ/items/pudge/pudge_scorching_talon/pudge_scorching_talon_ambient.vpcf", PATTACH_ABSORIGIN_FOLLOW, unit)
					ParticleManager:ReleaseParticleIndex(particle)
				elseif wearable == "models/items/pudge/immortal_arm/immortal_arm.vmdl" then
					cosmetic:SetMaterialGroup("1")
				elseif wearable == "models/items/pudge/arcana/pudge_arcana_back.vmdl" then
					unit:SetMaterialGroup("1") -- zonnoz pet
					cosmetic:SetMaterialGroup("1") -- zonnoz pet

					ParticleManager:CreateParticle("particles/econ/items/pudge/pudge_arcana/pudge_arcana_back_ambient.vpcf", PATTACH_ABSORIGIN_FOLLOW, cosmetic)
					ParticleManager:CreateParticle("particles/econ/items/pudge/pudge_arcana/pudge_arcana_back_ambient_beam.vpcf", PATTACH_ABSORIGIN_FOLLOW, cosmetic)
					ParticleManager:CreateParticle("particles/econ/items/pudge/pudge_arcana/pudge_arcana_ambient_flies.vpcf", PATTACH_ABSORIGIN_FOLLOW, unit)
				elseif wearable == "models/items/rubick/rubick_arcana/rubick_arcana_back.vmdl" then
					ParticleManager:CreateParticle("particles/econ/items/rubick/rubick_arcana/rubick_arc_ambient_default.vpcf", PATTACH_ABSORIGIN_FOLLOW, cosmetic)
					--			elseif wearable == "models/items/juggernaut/arcana/juggernaut_arcana_mask.vmdl" then
					--				ParticleManager:CreateParticle("particles/econ/items/juggernaut/jugg_arcana/juggernaut_arcana_ambient.vpcf", PATTACH_ABSORIGIN_FOLLOW, cosmetic)
				elseif wearable == "models/items/juggernaut/jugg_ti8/jugg_ti8_sword.vmdl" then
					ParticleManager:CreateParticle("particles/econ/items/juggernaut/jugg_ti8_sword/jugg_ti8_crimson_sword_ambient.vpcf", PATTACH_ABSORIGIN_FOLLOW, cosmetic)
				elseif wearable == "models/heroes/phantom_assassin/pa_arcana_weapons.vmdl" then
					-- swords effects
					local left_sword = ParticleManager:CreateParticle("particles/econ/items/phantom_assassin/phantom_assassin_arcana_elder_smith/pa_arcana_blade_ambient_a.vpcf", PATTACH_ABSORIGIN_FOLLOW, unit)
					ParticleManager:SetParticleControl(left_sword, 26, Vector(40, 0, 0))

					local right_sword = ParticleManager:CreateParticle("particles/econ/items/phantom_assassin/phantom_assassin_arcana_elder_smith/pa_arcana_blade_ambient_b.vpcf", PATTACH_ABSORIGIN_FOLLOW, unit)
					ParticleManager:SetParticleControl(right_sword, 26, Vector(40, 0, 0))
					--				"control_point_number"		"26"
					--				"cp_position"		"40 0 0"
					--				"style"		"1"

					-- Ambient Body
					ParticleManager:CreateParticle("particles/econ/items/phantom_assassin/phantom_assassin_arcana_elder_smith/pa_arcana_elder_ambient.vpcf", PATTACH_ABSORIGIN_FOLLOW, unit)

					-- Eyes
					ParticleManager:CreateParticle("particles/econ/items/phantom_assassin/phantom_assassin_arcana_elder_smith/pa_arcana_elder_eyes_l.vpcf", PATTACH_ABSORIGIN_FOLLOW, unit)
					ParticleManager:CreateParticle("particles/econ/items/phantom_assassin/phantom_assassin_arcana_elder_smith/pa_arcana_elder_eyes_r.vpcf", PATTACH_ABSORIGIN_FOLLOW, unit)
				end
			elseif IsInToolsMode() then
				print("[Battlepass] Failed to create wearable_dummy for companion cosmetic " .. tostring(wearable))
			end
		end
	end
end

function DonatorCompanionSkin(id, unit, skin)
	local companion = stored_companions[id]

	--	print("Material Group:", skin)
	--	print(companion, companion:GetUnitName(), unit)
	if companion ~= nil and not companion:IsNull() and (companion:GetUnitName() == unit or companion.xhs_companion_unit_name == unit) then
		companion:SetMaterialGroup(tostring(skin))
	end
end

function Battlepass:RemoveDonatorStatue(ID)
	local stored = stored_statues[ID]
	if stored then
		if stored.unit and not stored.unit:IsNull() then
			stored.unit:RemoveSelf()
		end
		if stored.pedestal and not stored.pedestal:IsNull() then
			stored.pedestal:RemoveSelf()
		end
	end
	stored_statues[ID] = nil

	local player = PlayerResource:GetPlayer(ID)
	local hero = player and player:GetAssignedHero() or nil
	if hero and not hero:IsNull() then
		hero.donator_statue = nil
	end
end

function Battlepass:DonatorStatue(ID, statue_unit, js, preview_origin)
	if not PlayerResource:IsValidPlayerID(ID) then return end
	local player = PlayerResource:GetPlayer(ID)
	if player == nil or statue_unit == nil or statue_unit == "" then return end

	if UNIQUE_DONATOR_STATUE[tostring(PlayerResource:GetSteamID(ID))] and not js then
		statue_unit = UNIQUE_DONATOR_STATUE[tostring(PlayerResource:GetSteamID(ID))]
	end

	local pedestal_name = "npc_donator_pedestal"
	local hero = PlayerResource:GetSelectedHeroEntity(ID)
	if hero == nil or hero:IsNull() then return end

	local team = "good"
	if player:GetTeam() == DOTA_TEAM_BADGUYS then
		team = "bad"
	end

	local fillers = {
		team .. "_filler_2",
		team .. "_filler_4",
		team .. "_filler_6",
		team .. "_filler_7",
	}

	local definitions = LoadKeyValues("scripts/npc/units/statues.txt") or {}
	local definition = definitions[statue_unit]
	if type(definition) ~= "table" then return end
	local model_scale = tonumber(definition.ModelScale) or 1.0

	local abs = preview_origin
	if abs == nil then
		abs = statue_slots[ID]
	end
	if abs == nil then
		for _, ent_name in pairs(fillers) do
			local filler = Entities:FindByName(nil, ent_name)
			if filler then
				abs = filler:GetAbsOrigin()
				statue_slots[ID] = abs
				filler:RemoveSelf()
				break
			end
		end
	end
	if abs == nil then return end
	if preview_origin ~= nil then
		abs = GetGroundPosition(abs, hero)
	end

	self:RemoveDonatorStatue(ID)
	local unit = CreateUnitByName(statue_unit, abs, true, nil, nil, player:GetTeam())
	if unit == nil then return end
	unit:SetModelScale(model_scale)
	unit:SetAbsOrigin(abs + Vector(0, 0, 45))
	unit:AddNewModifier(unit, nil, "modifier_invulnerable", {})
	hero.donator_statue = unit

	-- Custom health labels are server-global and cannot honor a per-client
	-- name setting. Keep the statue label anonymous so hero/none modes can
	-- never expose the owner's Steam persona name.
	local name = ""
	local donator_status = api:GetDonatorStatus(ID)
	if GetDonatorVisualStatus ~= nil then
		donator_status = GetDonatorVisualStatus(donator_status)
	end

	if donator_status == 1 then
		unit:SetCustomHealthLabel(name, 160, 20, 20)
		pedestal_name = "npc_donator_pedestal_cookies"
	elseif donator_status == 2 then
		unit:SetCustomHealthLabel(name, 0, 204, 255)
		pedestal_name = "npc_donator_pedestal_developer_" .. team
	elseif donator_status == 3 then
		unit:SetCustomHealthLabel(name, 160, 20, 20)
	elseif donator_status == 4 then
		unit:SetCustomHealthLabel(name, 240, 50, 50)
		pedestal_name = "npc_donator_pedestal_ember_" .. team
	elseif donator_status == 5 then
		unit:SetCustomHealthLabel(name, 218, 165, 32)
		pedestal_name = "npc_donator_pedestal_golden_" .. team
	elseif donator_status == 7 then
		unit:SetCustomHealthLabel(name, 47, 91, 151)
		pedestal_name = "npc_donator_pedestal_salamander_" .. team
	elseif donator_status == 8 then
		unit:SetCustomHealthLabel(name, 153, 51, 153)
		pedestal_name = "npc_donator_pedestal_icefrog"
	elseif donator_status and donator_status > 0 then
		unit:SetCustomHealthLabel(name, 45, 200, 45)
	end

	if statue_unit == "npc_donator_statue_suthernfriend" then
		unit:SetMaterialGroup("1")
	elseif statue_unit == "npc_donator_statue_tabisama" then
		unit:SetAbsOrigin(unit:GetAbsOrigin() + Vector(0, 0, 40))
	elseif statue_unit == "npc_donator_statue_zonnoz" then
		pedestal_name = "npc_donator_pedestal_pudge_arcana"
	elseif statue_unit == "npc_donator_statue_crystal_maiden_arcana" then
		local particle = ParticleManager:CreateParticle("particles/econ/items/crystal_maiden/crystal_maiden_maiden_of_icewrack/maiden_arcana_base_ambient.vpcf", PATTACH_ABSORIGIN_FOLLOW, unit)
		ParticleManager:ReleaseParticleIndex(particle)
	end

	local pedestal = CreateUnitByName(pedestal_name, abs, true, nil, nil, player:GetTeam())
	if pedestal then
		pedestal:AddNewModifier(pedestal, nil, "modifier_contributor_statue", {})
		pedestal:SetAbsOrigin(abs + Vector(0, 0, 45))
		if statue_unit == "npc_donator_statue_zonnoz" then
			pedestal:SetMaterialGroup("1")
		end
	end
	unit.pedestal = pedestal
	stored_statues[ID] = { unit = unit, pedestal = pedestal }
end

function Battlepass:DebugDonatorCompanion(ID)
	local companion = stored_companions[tonumber(ID) or -1]
	if companion == nil or companion:IsNull() then
		CompanionLog("debug player=%s: no stored companion", tostring(ID))
		return nil
	end
	local modifier = companion:FindModifierByName("modifier_companion")
	CompanionLog("debug player=%s ent=%s unit=%s requested_unit=%s model=%s scale=%.2f alive=%s origin=%s modifier=%s state=%s combat_hidden=%s invisible=%s", tostring(ID), tostring(companion:entindex()), tostring(companion:GetUnitName()), tostring(companion.xhs_companion_unit_name), tostring(companion:GetModelName()), tonumber(companion:GetModelScale()) or -1, tostring(companion:IsAlive()), tostring(companion:GetAbsOrigin()), tostring(modifier ~= nil), tostring(modifier and modifier.companion_state), tostring(modifier and modifier.hidden_by_combat), tostring(companion:HasModifier("modifier_invisible")))
	return companion
end

if IsServer() and Convars ~= nil then
	Convars:RegisterCommand("xhs_companion_debug", function(_, playerID, unitName)
		local id = tonumber(playerID) or 0
		if unitName ~= nil and tostring(unitName) ~= "" then
			Battlepass:DonatorCompanion(id, tostring(unitName), true)
			return
		end
		Battlepass:DebugDonatorCompanion(id)
	end, "Print or spawn the XHS companion for a player: xhs_companion_debug <player_id> [unit_name]", 0)
end
