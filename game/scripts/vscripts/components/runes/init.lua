if Runes == nil then
	Runes = class({})
end

require("components/runes/modifiers")

local XHS_RUNE_MODIFIER_SCRIPT = "components/runes/modifiers.lua"
LinkLuaModifier("modifier_xhs_rune_healing", XHS_RUNE_MODIFIER_SCRIPT, LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_xhs_rune_revitalization", XHS_RUNE_MODIFIER_SCRIPT, LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_xhs_rune_restoration", XHS_RUNE_MODIFIER_SCRIPT, LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_xhs_rune_second_wind", XHS_RUNE_MODIFIER_SCRIPT, LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_xhs_rune_second_wind_heal", XHS_RUNE_MODIFIER_SCRIPT, LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_xhs_rune_second_wind_guard", XHS_RUNE_MODIFIER_SCRIPT, LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_xhs_rune_barrier", XHS_RUNE_MODIFIER_SCRIPT, LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_xhs_rune_retaliation", XHS_RUNE_MODIFIER_SCRIPT, LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_xhs_rune_bulwark", XHS_RUNE_MODIFIER_SCRIPT, LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_xhs_rune_fortitude", XHS_RUNE_MODIFIER_SCRIPT, LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_xhs_rune_titan", XHS_RUNE_MODIFIER_SCRIPT, LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_xhs_rune_fury", XHS_RUNE_MODIFIER_SCRIPT, LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_xhs_rune_siegebreaker", XHS_RUNE_MODIFIER_SCRIPT, LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_xhs_rune_storm", XHS_RUNE_MODIFIER_SCRIPT, LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_xhs_rune_bounty_surge", XHS_RUNE_MODIFIER_SCRIPT, LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_xhs_rune_momentum", XHS_RUNE_MODIFIER_SCRIPT, LUA_MODIFIER_MOTION_NONE)

Runes.PICKUP_RADIUS = 170
Runes.VISION_RADIUS = 450
Runes.VISION_DURATION = 999999
Runes.FRAGMENT_AMOUNT = 50
Runes.FRAGMENT_WAVES = { 2, 4, 5, 6, 7, 8 }
Runes.FINAL_WAVE_INDEX = 9
Runes.MAX_RUNES_PER_BATCH = 8
Runes.EXTRA_RUNE_SPACING = 150
Runes.VISUAL_MODELS = {
	Recovery = "models/custom_game/runes/xhs_rune_recovery.vmdl",
	Defense = "models/custom_game/runes/xhs_rune_defense.vmdl",
	Offense = "models/custom_game/runes/xhs_rune_offense.vmdl",
	Misc = "models/custom_game/runes/xhs_rune_misc.vmdl",
}

Runes.RUNE_PARTICLES = {
	healing = "particles/generic_gameplay/rune_regeneration.vpcf",
	revitalization = "particles/generic_gameplay/rune_arcane.vpcf",
	restoration = "particles/generic_gameplay/rune_water.vpcf",
	second_wind = "particles/generic_gameplay/rune_shield.vpcf",
	barrier = "particles/generic_gameplay/rune_shield.vpcf",
	retaliation = "particles/generic_gameplay/rune_doubledamage.vpcf",
	bulwark = "particles/generic_gameplay/rune_shield.vpcf",
	fortitude = "particles/generic_gameplay/rune_shield.vpcf",
	titan = "particles/generic_gameplay/rune_doubledamage.vpcf",
	fury = "particles/generic_gameplay/rune_haste.vpcf",
	siegebreaker = "particles/generic_gameplay/rune_doubledamage.vpcf",
	storm = "particles/generic_gameplay/rune_arcane.vpcf",
	fragment = "particles/generic_gameplay/rune_bounty.vpcf",
	tome = "particles/generic_gameplay/rune_wisdom.vpcf",
	bounty_surge = "particles/generic_gameplay/rune_bounty.vpcf",
	momentum = "particles/generic_gameplay/rune_haste.vpcf",
}

Runes.CATEGORY_PARTICLES = {
	Recovery = "particles/generic_gameplay/rune_regeneration.vpcf",
	Defense = "particles/generic_gameplay/rune_shield.vpcf",
	Offense = "particles/generic_gameplay/rune_doubledamage.vpcf",
	Misc = "particles/generic_gameplay/rune_wisdom.vpcf",
}

Runes.DEFINITIONS = {
	healing = {
		name = "Healing Rune",
		category = "Recovery",
		scope = "picker",
		modifier = "modifier_xhs_rune_healing",
		duration = 30,
		values = { hp_regen_pct = 5, mana_regen_pct = 8 },
	},
	revitalization = {
		name = "Revitalization Rune",
		category = "Recovery",
		scope = "picker",
		modifier = "modifier_xhs_rune_revitalization",
		duration = 20,
		values = { cooldown_reduction_pct = 30 },
	},
	restoration = {
		name = "Restoration Rune",
		category = "Recovery",
		scope = "picker",
		instant = "restoration",
		values = { missing_pct = 35 },
	},
	second_wind = {
		name = "Second Wind Rune",
		category = "Recovery",
		scope = "picker",
		modifier = "modifier_xhs_rune_second_wind",
		duration = 60,
		values = { threshold_pct = 30, heal_pct = 30, mana_pct = 30, recovery_duration = 3, guard_duration = 4, guard_reduction = 20 },
	},
	barrier = {
		name = "Barrier Rune",
		category = "Defense",
		scope = "picker",
		modifier = "modifier_xhs_rune_barrier",
		duration = 30,
		values = { shield_pct = 25, health_regen_pct = 4 },
	},
	retaliation = {
		name = "Retaliation Rune",
		category = "Defense",
		scope = "picker",
		modifier = "modifier_xhs_rune_retaliation",
		duration = 25,
		values = { reflect_pct = 25 },
	},
	bulwark = {
		name = "Bulwark Rune",
		category = "Defense",
		scope = "picker",
		modifier = "modifier_xhs_rune_bulwark",
		duration = 35,
		values = { armor = 35, magic_resist = 25 },
	},
	fortitude = {
		name = "Fortitude Rune",
		category = "Defense",
		scope = "picker",
		modifier = "modifier_xhs_rune_fortitude",
		duration = 25,
		values = { status_resist = 35, damage_reduction = 20 },
	},
	titan = {
		name = "Titan Rune",
		category = "Offense",
		scope = "picker",
		modifier = "modifier_xhs_rune_titan",
		duration = 35,
		values = { model_scale = 18, max_hp_pct = 30, outgoing_damage = 25 },
	},
	fury = {
		name = "Fury Rune",
		category = "Offense",
		scope = "picker",
		modifier = "modifier_xhs_rune_fury",
		duration = 30,
		values = { attack_speed = 160, spell_amp = 25 },
	},
	siegebreaker = {
		name = "Siegebreaker Rune",
		category = "Offense",
		scope = "picker",
		modifier = "modifier_xhs_rune_siegebreaker",
		duration = 35,
		values = { bonus_damage = 45 },
	},
	storm = {
		name = "Storm Rune",
		category = "Offense",
		scope = "picker",
		modifier = "modifier_xhs_rune_storm",
		duration = 30,
		values = { interval = 1.2, radius = 650, targets = 4, damage = 550 },
	},
	fragment = {
		name = "Fragment Rune",
		category = "Misc",
		scope = "picker",
		instant = "fragment",
	},
	tome = {
		name = "Tome Rune",
		category = "Misc",
		scope = "picker",
		instant = "tome",
		values = { stats = 50 },
	},
	bounty_surge = {
		name = "Bounty Surge Rune",
		category = "Misc",
		scope = "picker",
		modifier = "modifier_xhs_rune_bounty_surge",
		duration = 45,
		values = { bounty_pct = 25 },
	},
	momentum = {
		name = "Momentum Rune",
		category = "Misc",
		scope = "picker",
		modifier = "modifier_xhs_rune_momentum",
		duration = 45,
		values = { move_speed = 18, gold_pct = 20, xp_pct = 20 },
	},
}

Runes.CATEGORY_RUNE_TYPES = {
	Recovery = { "healing", "revitalization", "restoration", "second_wind" },
	Defense = { "barrier", "retaliation", "bulwark", "fortitude" },
	Offense = { "titan", "fury", "siegebreaker", "storm" },
	Misc = { "tome", "bounty_surge", "momentum" },
}

Runes.EFFECT_SUMMARIES = {
	healing = "+5% health regen, +8% mana regen",
	revitalization = "-30% cooldowns",
	restoration = "Restores 35% missing health and mana",
	second_wind = "Emergency heal and damage guard below 30% HP",
	barrier = "Shield for 25% max HP plus health regeneration",
	retaliation = "Reflects 25% incoming damage",
	bulwark = "+35 armor, +25% magic resistance",
	fortitude = "+35% status resistance, -20% incoming damage",
	titan = "+30% max HP, +25% outgoing damage",
	fury = "+160 attack speed, +25% spell amplification",
	siegebreaker = "+45% damage against creeps and summons",
	storm = "Strikes up to 4 nearby enemies every 1.2s",
	tome = "+50 all stats",
	bounty_surge = "+25% creep bounty",
	momentum = "+18% move speed, +20% creep gold and XP",
}

function Runes:Init()
	if self.initialized then return end

	self.initialized = true
	self.activeRune = nil
	self.activeRunes = {}
	self.nextRuneId = 1
	self.nextRuneBatchId = 1
	self.runeBatches = {}
	self.pickupBlockedNotices = {}
	self.fragmentWaveIndex = self.FRAGMENT_WAVES[RandomInt(1, #self.FRAGMENT_WAVES)]
	self.fragmentSpawned = false
	self.fragmentGrantAttempts = {}
	self.categoryBag = {}
	self.typeBags = {}

end

function Runes:IsReborn()
	local gamemode = XHS_GAMEMODE_ACTIVE
	if api and api.GetCustomGamemode then
		gamemode = api:GetCustomGamemode() or gamemode
	end

	return tonumber(gamemode) == XHS_GAMEMODE_REBORN
end

function Runes:OnSpecialWaveWarning(waveIndex, direction)
	if not IsServer() then return end

	self:Init()

	waveIndex = tonumber(waveIndex) or 0
	if waveIndex < 1 or (waveIndex > 8 and waveIndex ~= self.FINAL_WAVE_INDEX) then return end
	if not self:IsReborn() then return end

	local runeType = self:SelectRuneType(waveIndex)
	local definition = self.DEFINITIONS[runeType]
	if definition == nil then return end

	local spawnCount = self:GetRuneSpawnCount()

	local spawnOrigins = self:FindSpawnOrigins(direction, spawnCount)
	if spawnOrigins == nil or #spawnOrigins == 0 then return end

	if self:HasActiveRunes() then
		self:CleanupAllActiveRunes("removed")
	else
		self.activeRune = nil
		self.activeRunes = self.activeRunes or {}
	end
	self.runeBatches = {}
	self.pickupBlockedNotices = {}

	if runeType == "fragment" then
		self.fragmentSpawned = true
	end

	local batchId = self.nextRuneBatchId
	self.nextRuneBatchId = self.nextRuneBatchId + 1
	self.runeBatches[batchId] = {
		id = batchId,
		total = #spawnOrigins,
		pickedPlayers = {},
	}

	for _, spawnOrigin in pairs(spawnOrigins) do
		self:SpawnRuneInstance(runeType, definition, waveIndex, direction, spawnOrigin, batchId, #spawnOrigins)
	end

	self:BroadcastRuneState("spawned")
end

function Runes:OnFinalWaveTeleport()
	self:OnSpecialWaveWarning(self.FINAL_WAVE_INDEX, nil)
end

function Runes:GetRuneSpawnCount()
	local participantIDs = GetXHSCombatParticipantPlayerIDs ~= nil
		and GetXHSCombatParticipantPlayerIDs() or {}
	if #participantIDs > 0 then
		return math.max(1, math.min(self.MAX_RUNES_PER_BATCH, #participantIDs))
	end

	local countedPlayers = {}
	for _, hero in pairs(HeroList:GetAllHeroes()) do
		if hero ~= nil and not hero:IsNull() and hero:GetTeamNumber() == DOTA_TEAM_GOODGUYS and hero:IsRealHero() and not hero:IsIllusion() then
			local playerID = hero:GetPlayerID()
			if playerID ~= nil and playerID >= 0 and PlayerResource:IsValidPlayerID(playerID) and countedPlayers[playerID] ~= true then
				countedPlayers[playerID] = true
			end
		end
	end

	local count = 0
	for _, _ in pairs(countedPlayers) do
		count = count + 1
	end
	return math.max(1, math.min(self.MAX_RUNES_PER_BATCH, count))
end

function Runes:SpawnRuneInstance(runeType, definition, waveIndex, direction, spawnOrigin, batchId, batchTotal)
	local dummy = CreateUnitByName("dummy_unit_invulnerable", spawnOrigin, false, nil, nil, DOTA_TEAM_GOODGUYS)
	if dummy == nil then return nil end

	dummy.xhs_is_rune = true
	dummy:AddNewModifier(dummy, nil, "modifier_invulnerable", {})
	dummy:AddNewModifier(dummy, nil, "modifier_phased", {})
	local visualModel = self.VISUAL_MODELS[definition.category] or self.VISUAL_MODELS.Misc
	if dummy.SetModel then
		dummy:SetModel(visualModel)
	end
	if dummy.SetOriginalModel then
		dummy:SetOriginalModel(visualModel)
	end
	if dummy.SetRenderColor then
		local color = self:GetCategoryColor(definition.category)
		dummy:SetRenderColor(color.x, color.y, color.z)
	end
	if dummy.SetModelScale then
		dummy:SetModelScale(1.05)
	end
	if dummy.StartGesture then
		dummy:StartGesture(ACT_DOTA_IDLE)
	end
	dummy:SetAbsOrigin(spawnOrigin)

	local id = self.nextRuneId
	self.nextRuneId = self.nextRuneId + 1

	local particleIds = self:CreateRuneParticles(dummy, spawnOrigin, definition.category, runeType)
	local token = tostring(RandomInt(100000, 999999)) .. ":" .. tostring(id) .. ":" .. tostring(waveIndex)

	local rune = {
		id = id,
		type = runeType,
		name = definition.name,
		category = definition.category,
		spawnedByWave = waveIndex,
		batchId = batchId,
		batchTotal = batchTotal or 1,
		direction = direction or "",
		baseOrigin = spawnOrigin,
		animationPhase = RandomFloat(0, math.pi * 2),
		entityIndex = dummy:entindex(),
		particleIds = particleIds,
		secureToken = token,
	}

	self.activeRunes[id] = rune
	if self.activeRune == nil then
		self.activeRune = rune
	end

	AddFOWViewer(DOTA_TEAM_GOODGUYS, spawnOrigin, self.VISION_RADIUS, self.VISION_DURATION, false)
	self:StartRuneIdleThink(id, token)
	self:StartRuneAnimationThink(id, token)
	self:StartPickupThink(id, token)

	return rune
end

function Runes:StartRuneIdleThink(id, token)
	Timers:CreateTimer(0.03, function()
		local active = self:GetActiveRune(id, token)
		if active == nil then return nil end

		local dummy = EntIndexToHScript(active.entityIndex)
		if dummy == nil or dummy:IsNull() then return nil end

		if dummy.FadeGesture then
			dummy:FadeGesture(ACT_DOTA_IDLE)
		end
		if dummy.StartGestureWithPlaybackRate then
			dummy:StartGestureWithPlaybackRate(ACT_DOTA_IDLE, 1.0)
		elseif dummy.StartGesture then
			dummy:StartGesture(ACT_DOTA_IDLE)
		end

		return 2.5
	end)
end

function Runes:StartRuneAnimationThink(id, token)
	Timers:CreateTimer(0.03, function()
		local active = self:GetActiveRune(id, token)
		if active == nil then return nil end

		local dummy = EntIndexToHScript(active.entityIndex)
		if dummy == nil or dummy:IsNull() then return nil end

		local baseOrigin = active.baseOrigin or dummy:GetAbsOrigin()
		local elapsed = GameRules:GetGameTime() + (active.animationPhase or 0)
		local heightOffset = math.sin(elapsed * 2.8) * 10
		local yaw = (elapsed * 75) % 360

		dummy:SetAbsOrigin(baseOrigin + Vector(0, 0, heightOffset))
		dummy:SetAngles(0, yaw, 0)
		for _, particle in pairs(active.particleIds or {}) do
			ParticleManager:SetParticleControl(particle, 0, baseOrigin + Vector(0, 0, heightOffset))
		end

		return 0.03
	end)
end

function Runes:StartStateThink(id, token)
	Timers:CreateTimer(1.0, function()
		local active = self:GetActiveRune(id, token)
		if active == nil then
			return nil
		end

		self:BroadcastRuneState("spawned", nil, active)
		return 1.0
	end)
end

function Runes:SelectRuneType(waveIndex)
	if waveIndex == self.fragmentWaveIndex and self.fragmentSpawned ~= true then
		return "fragment"
	end

	local category = self:DrawCategory()
	local bag = self.typeBags[category]
	if bag == nil or #bag == 0 then
		bag = self:ShuffledCopy(self.CATEGORY_RUNE_TYPES[category])
		self.typeBags[category] = bag
	end

	return table.remove(bag, 1)
end

function Runes:DrawCategory()
	if self.categoryBag == nil or #self.categoryBag == 0 then
		self.categoryBag = self:ShuffledCopy({ "Recovery", "Defense", "Offense", "Misc" })
	end

	return table.remove(self.categoryBag, 1)
end

function Runes:ShuffledCopy(source)
	local copy = {}
	for _, value in pairs(source or {}) do
		table.insert(copy, value)
	end

	for i = #copy, 2, -1 do
		local j = RandomInt(1, i)
		copy[i], copy[j] = copy[j], copy[i]
	end

	return copy
end

function Runes:FindSpawnOrigins(direction, count)
	local runeSpawners = Entities:FindAllByName("dota_item_rune_spawner_custom")
	if runeSpawners == nil or #runeSpawners == 0 then return nil end
	count = math.max(1, math.min(self.MAX_RUNES_PER_BATCH, tonumber(count) or 1))

	local laneSpawner = nil
	if direction ~= nil and direction ~= "" then
		laneSpawner = Entities:FindByName(nil, "npc_dota_spawner_" .. tostring(direction) .. "_event")
	end

	local sorted = {}
	if laneSpawner ~= nil then
		local laneOrigin = laneSpawner:GetAbsOrigin()
		for _, spawner in pairs(runeSpawners) do
			if spawner ~= nil and not spawner:IsNull() then
				table.insert(sorted, {
					spawner = spawner,
					distance = (spawner:GetAbsOrigin() - laneOrigin):Length2D(),
				})
			end
		end
		table.sort(sorted, function(a, b) return a.distance < b.distance end)
	end

	if #sorted == 0 then
		local shuffled = self:ShuffledCopy(runeSpawners)
		for _, spawner in pairs(shuffled) do
			if spawner ~= nil and not spawner:IsNull() then
				table.insert(sorted, { spawner = spawner, distance = 0 })
			end
		end
	end
	if #sorted == 0 then return nil end

	local origins = {}
	local baseCount = #sorted
	for slot = 1, count do
		local baseIndex = ((slot - 1) % baseCount) + 1
		local entry = sorted[baseIndex]
		if entry ~= nil and entry.spawner ~= nil and not entry.spawner:IsNull() then
			local baseOrigin = entry.spawner:GetAbsOrigin()
			local layer = math.floor((slot - 1) / baseCount)
			local offset = Vector(0, 0, 0)
			if layer > 0 then
				local angle = math.rad(((baseIndex - 1) * (360 / baseCount)) + ((layer - 1) * 60))
				local radius = self.EXTRA_RUNE_SPACING + (math.floor((layer - 1) / 6) * self.EXTRA_RUNE_SPACING)
				offset = Vector(math.cos(angle) * radius, math.sin(angle) * radius, 0)
			end

			local origin = GetGroundPosition(baseOrigin + offset, nil) + Vector(0, 0, 40)
			table.insert(origins, origin)
		end
	end

	return origins
end

function Runes:CreateRuneParticles(dummy, origin, category, runeType)
	local particleIds = {}

	local particlePath = self.RUNE_PARTICLES[runeType] or self.CATEGORY_PARTICLES[category] or self.CATEGORY_PARTICLES.Misc
	local particle = ParticleManager:CreateParticle(particlePath, PATTACH_ABSORIGIN_FOLLOW, dummy)
	ParticleManager:SetParticleControl(particle, 0, origin)
	table.insert(particleIds, particle)

	return particleIds
end

function Runes:GetCategoryColor(category)
	local colors = {
		Recovery = Vector(80, 220, 140),
		Defense = Vector(100, 170, 255),
		Offense = Vector(255, 105, 75),
		Misc = Vector(220, 170, 255),
	}

	return colors[category] or Vector(160, 220, 255)
end

function Runes:StartPickupThink(id, token)
	Timers:CreateTimer(0.2, function()
		local active = self:GetActiveRune(id, token)
		if active == nil then
			return nil
		end

		local dummy = EntIndexToHScript(active.entityIndex)
		if dummy == nil or dummy:IsNull() then
			self:CleanupActiveRune("removed", nil, active)
			return nil
		end

		local origin = dummy:GetAbsOrigin()
		for _, hero in pairs(HeroList:GetAllHeroes()) do
			if self:IsEligiblePicker(hero) and (hero:GetAbsOrigin() - origin):Length2D() <= self.PICKUP_RADIUS then
				if self:HasHeroPickedRuneBatch(active, hero) then
					self:NotifyRuneBatchPickupBlocked(hero, active)
				else
					self:PickupRune(hero, id, token)
					return nil
				end
			end
		end

		return 0.2
	end)
end

function Runes:GetActiveRune(id, token)
	local active = self.activeRunes and self.activeRunes[id] or nil
	if active == nil or active.secureToken ~= token then return nil end
	return active
end

function Runes:HasActiveRunes()
	for _, _ in pairs(self.activeRunes or {}) do
		return true
	end

	return false
end

function Runes:IsEligiblePicker(hero)
	return hero ~= nil
		and not hero:IsNull()
		and hero:GetTeamNumber() == DOTA_TEAM_GOODGUYS
		and hero:IsRealHero()
		and not hero:IsIllusion()
		and hero:IsAlive()
end

function Runes:GetHeroPlayerID(hero)
	if hero == nil or hero:IsNull() then return nil end

	local playerID = hero:GetPlayerID()
	if playerID == nil or playerID < 0 or not PlayerResource:IsValidPlayerID(playerID) then
		return nil
	end

	return playerID
end

function Runes:HasHeroPickedRuneBatch(active, hero)
	if active == nil then return false end
	if active.batchId == nil then return false end

	local playerID = self:GetHeroPlayerID(hero)
	if playerID == nil then return true end

	local batch = self.runeBatches and self.runeBatches[active.batchId] or nil
	if batch == nil or batch.pickedPlayers == nil then return false end

	return batch.pickedPlayers[playerID] == true
end

function Runes:MarkHeroPickedRuneBatch(active, hero)
	if active == nil then return end

	local playerID = self:GetHeroPlayerID(hero)
	if playerID == nil then return end

	if self.runeBatches == nil then
		self.runeBatches = {}
	end

	local batchId = active.batchId
	if batchId == nil then return end

	if self.runeBatches[batchId] == nil then
		self.runeBatches[batchId] = {
			id = batchId,
			total = active.batchTotal or 1,
			pickedPlayers = {},
		}
	end

	self.runeBatches[batchId].pickedPlayers[playerID] = true
end

function Runes:NotifyRuneBatchPickupBlocked(hero, active)
	local playerID = self:GetHeroPlayerID(hero)
	if playerID == nil or hero.GetPlayerOwner == nil then return end

	local player = hero:GetPlayerOwner()
	if player == nil then return end

	self.pickupBlockedNotices = self.pickupBlockedNotices or {}
	local noticeKey = tostring(active and active.batchId or 0) .. ":" .. tostring(playerID)
	if self.pickupBlockedNotices[noticeKey] == true then return end

	self.pickupBlockedNotices[noticeKey] = true
	Notifications:Bottom(player, {
		text = "You already picked up a rune from this batch.",
		duration = 3.0,
		severity = "warning",
	})
end

function Runes:PickupRune(hero, id, token)
	local active = self:GetActiveRune(id, token)
	if active == nil then return end
	if self:HasHeroPickedRuneBatch(active, hero) then return end

	local definition = self.DEFINITIONS[active.type]
	if definition == nil then return end

	self:MarkHeroPickedRuneBatch(active, hero)
	self:ApplyRune(definition, hero)

	self:CleanupActiveRune("picked", hero, active)
end

function Runes:ApplyRune(definition, picker)
	if definition.instant == "fragment" then
		self:GrantFragmentRune(picker)
		self:PlayRunePickupSound(picker)
		return
	elseif definition.instant == "tome" then
		if GrantTomeStatsToHero(picker, definition.values.stats or 50, nil, nil, { play_sound = false }) ~= nil then
			self:NotifyRuneApplied(picker, definition)
		end
		self:PlayHeroRuneEffect(picker, definition.category, false)
		self:PlayRunePickupSound(picker)
		return
	elseif definition.instant == "restoration" then
		local missingHealth = picker:GetMaxHealth() - picker:GetHealth()
		local missingMana = picker:GetMaxMana() - picker:GetMana()
		local restoredPct = definition.values.missing_pct or 35
		picker:Heal(missingHealth * restoredPct * 0.01, picker)
		picker:GiveMana(missingMana * restoredPct * 0.01)
		picker:AddNewModifier(picker, nil, "modifier_xhs_rune_restoration", { duration = 3, restored_pct = restoredPct })
		self:PlayHeroRuneEffect(picker, definition.category, false)
		self:NotifyRuneApplied(picker, definition)
		self:PlayRunePickupSound(picker)
		return
	end

	if definition.values and definition.values.cooldown_pct then
		self:ReduceCooldowns(picker, definition.values.cooldown_pct, definition.values.cooldown_cap)
	end
	picker:AddNewModifier(picker, nil, definition.modifier, self:BuildModifierKv(definition))
	self:PlayHeroRuneEffect(picker, definition.category, false)
	self:NotifyRuneApplied(picker, definition)
	self:PlayRunePickupSound(picker)
end

function Runes:GetEffectSummary(definition)
	if definition == nil then return "" end

	for runeType, runeDefinition in pairs(self.DEFINITIONS or {}) do
		if runeDefinition == definition then
			return self.EFFECT_SUMMARIES[runeType] or ""
		end
	end

	return ""
end

function Runes:NotifyRuneApplied(hero, definition)
	if hero == nil or hero:IsNull() or not hero.GetPlayerOwner then return end

	local player = hero:GetPlayerOwner()
	if player == nil then return end

	local summary = self:GetEffectSummary(definition)
	local name = definition.name or "Rune"
	local duration = tonumber(definition.duration) or 0
	local text = summary ~= "" and (name .. ": " .. summary) or (name .. " applied")
	if duration > 0 then
		text = text .. " for " .. tostring(duration) .. "s"
	end

	Notifications:Bottom(player, {
		text = text,
		duration = 4.5,
		severity = "success",
	})
end

function Runes:ReduceCooldowns(hero, percent, cap)
	percent = tonumber(percent) or 25
	cap = tonumber(cap) or 20

	ForEachUnitAbility(hero, function(ability)
		if ability ~= nil and not ability:IsNull() and ability.GetCooldownTimeRemaining then
			local remaining = ability:GetCooldownTimeRemaining()
			if remaining ~= nil and remaining > 0 then
				local reduction = math.min(cap, remaining * percent * 0.01)
				ability:EndCooldown()
				local newRemaining = math.max(0, remaining - reduction)
				if newRemaining > 0 then
					ability:StartCooldown(newRemaining)
				end
			end
		end
	end)

	for index = 0, 8 do
		local item = hero:GetItemInSlot(index)
		if item ~= nil and not item:IsNull() and item.GetCooldownTimeRemaining then
			local remaining = item:GetCooldownTimeRemaining()
			if remaining ~= nil and remaining > 0 then
				local reduction = math.min(cap, remaining * percent * 0.01)
				item:EndCooldown()
				local newRemaining = math.max(0, remaining - reduction)
				if newRemaining > 0 then
					item:StartCooldown(newRemaining)
				end
			end
		end
	end
end

function Runes:BuildModifierKv(definition)
	local kv = { duration = definition.duration or 0 }
	for key, value in pairs(definition.values or {}) do
		kv[key] = value
	end
	return kv
end

function Runes:GrantFragmentRune(hero)
	local playerID = self:GetHeroPlayerID(hero)
	if playerID == nil then return end
	self.fragmentGrantAttempts = self.fragmentGrantAttempts or {}
	if self.fragmentGrantAttempts[playerID] == true then return end
	self.fragmentGrantAttempts[playerID] = true

	local player = hero:GetPlayerOwner()
	local idempotencyKey = "xhs-fragment-rune:"
		.. tostring(api and api:GetApiGameId() or GameRules:Script_GetMatchID())
		.. ":" .. tostring(self.fragmentWaveIndex)
		.. ":" .. tostring(playerID)

	if api == nil or api.GrantSupporterFragments == nil then
		if player ~= nil then
			Notifications:Bottom(player, {
				text = "Fragment Rune backend is unavailable. Grant was not applied.",
				duration = 5.0,
				severity = "warning",
			})
		end
		return
	end

	api:GrantSupporterFragments(playerID, self.FRAGMENT_AMOUNT, "fragment_rune", idempotencyKey, function(success)
		if player ~= nil then
			Notifications:Bottom(player, {
				text = success
					and ("Fragment Rune granted +" .. tostring(self.FRAGMENT_AMOUNT) .. " supporter fragments.")
					or "Fragment Rune grant failed backend validation.",
				duration = 5.0,
				severity = success and "success" or "warning",
			})
		end
	end)
end

function Runes:CleanupActiveRune(state, picker, active)
	active = active or self.activeRune
	if active == nil then return end

	local dummy = EntIndexToHScript(active.entityIndex)
	if dummy ~= nil and not dummy:IsNull() then
		UTIL_Remove(dummy)
	end

	for _, particle in pairs(active.particleIds or {}) do
		if particle ~= nil then
			ParticleManager:DestroyParticle(particle, false)
			ParticleManager:ReleaseParticleIndex(particle)
		end
	end

	if self.activeRunes ~= nil then
		self.activeRunes[active.id] = nil
	end

	if self.activeRune ~= nil and self.activeRune.id == active.id then
		self.activeRune = nil
		for _, rune in pairs(self.activeRunes or {}) do
			self.activeRune = rune
			break
		end
	end

	self:BroadcastRuneState(state or "removed", picker, active)

	if active.batchId ~= nil and self:CountRunesInBatch(active.batchId) <= 0 and self.runeBatches ~= nil then
		self.runeBatches[active.batchId] = nil
	end
end

function Runes:CleanupAllActiveRunes(state)
	local activeRunes = {}
	for _, active in pairs(self.activeRunes or {}) do
		table.insert(activeRunes, active)
	end

	for _, active in pairs(activeRunes) do
		self:CleanupActiveRune(state or "removed", nil, active)
	end

	self.activeRune = nil
	self.activeRunes = {}
end

function Runes:CountRunesInBatch(batchId)
	local count = 0
	for _, rune in pairs(self.activeRunes or {}) do
		if rune.batchId == batchId then
			count = count + 1
		end
	end

	return count
end

function Runes:GetRuneBatchTotal(active)
	if active == nil then return 1 end

	local batch = self.runeBatches and self.runeBatches[active.batchId] or nil
	if batch ~= nil and batch.total ~= nil then
		return batch.total
	end

	return active.batchTotal or 1
end

function Runes:BroadcastRuneState(state, picker, active)
	active = active or self.activeRune
	if active == nil then return end

	local runeCount = self:CountRunesInBatch(active.batchId)
	local runeTotal = self:GetRuneBatchTotal(active)

	CustomGameEventManager:Send_ServerToAllClients("xhs_rune_state_update", {
		id = active.id,
		batch_id = active.batchId or 0,
		type = active.type,
		name = active.name,
		category = active.category,
		state = state,
		wave_index = active.spawnedByWave,
		direction = active.direction,
		remaining = -1,
		rune_count = runeCount,
		rune_remaining = runeCount,
		rune_total = runeTotal,
		picker_player_id = picker and picker:GetPlayerID() or -1,
		picker_hero_name = picker and picker:GetUnitName() or "",
	})
end

function Runes:DirectionLabel(direction)
	if direction == nil or direction == "" then return "rune" end
	return tostring(direction)
end

function Runes:PlayRunePickupSound(hero)
	if hero == nil or hero:IsNull() then return end

	if hero.EmitSoundParams ~= nil then
		hero:EmitSoundParams("Rune.Regen", 0, 0.35, 0)
	else
		hero:EmitSound("Rune.Regen")
	end
end

function Runes:PlayHeroRuneEffect(hero, category, playSound)
	local levelupParticle = XHSGetBattlepassParticle ~= nil
		and XHSGetBattlepassParticle(hero, "levelup_pfx", "particles/generic_hero_status/hero_levelup.vpcf")
		or "particles/generic_hero_status/hero_levelup.vpcf"
	local particle = ParticleManager:CreateParticle(levelupParticle, PATTACH_ABSORIGIN_FOLLOW, hero)
	ParticleManager:SetParticleControl(particle, 0, hero:GetAbsOrigin())
	ParticleManager:ReleaseParticleIndex(particle)
	if playSound == true then
		self:PlayRunePickupSound(hero)
	end
end

function Runes:OnDamageFilter(filterTable)
	return true
end

function Runes:OnGoldFilter(filterTable)
	if filterTable == nil then return true end
	if filterTable.gold == nil or filterTable.gold <= 0 then return true end

	local playerID = filterTable.player_id_const
	local hero = playerID ~= nil and PlayerResource:GetSelectedHeroEntity(playerID) or nil
	if hero == nil or hero:IsNull() then return true end
	if DOTA_ModifyGold_CreepKill ~= nil and filterTable.reason_const ~= DOTA_ModifyGold_CreepKill then return true end

	local bonusPct = 0
	local momentum = hero:FindModifierByName("modifier_xhs_rune_momentum")
	if momentum ~= nil then
		bonusPct = bonusPct + (momentum.gold_pct or 20)
	end

	local bountySurge = hero:FindModifierByName("modifier_xhs_rune_bounty_surge")
	if bountySurge ~= nil then
		bonusPct = bonusPct + (bountySurge.bounty_pct or 25)
	end

	if bonusPct > 0 then
		filterTable.gold = filterTable.gold + math.floor(filterTable.gold * bonusPct * 0.01)
	end
	return true
end

function Runes:OnExperienceFilter(filterTable)
	if filterTable == nil then return true end
	if filterTable.experience == nil or filterTable.experience <= 0 then return true end

	local playerID = filterTable.player_id_const
	local hero = playerID ~= nil and PlayerResource:GetSelectedHeroEntity(playerID) or nil
	if hero == nil or hero:IsNull() or not hero:HasModifier("modifier_xhs_rune_momentum") then return true end

	if DOTA_ModifyXP_CreepKill ~= nil and filterTable.reason_const ~= DOTA_ModifyXP_CreepKill then return true end

	local modifier = hero:FindModifierByName("modifier_xhs_rune_momentum")
	local bonusPct = modifier and modifier.xp_pct or 20
	filterTable.experience = filterTable.experience + math.floor(filterTable.experience * bonusPct * 0.01)
	return true
end

Runes:Init()
