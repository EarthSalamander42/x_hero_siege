if IsServer() and CDOTA_PlayerResource ~= nil
	and CDOTA_PlayerResource.HasSelectedHero ~= nil
	and _G.XHS_NATIVE_HAS_SELECTED_HERO == nil then
	_G.XHS_NATIVE_HAS_SELECTED_HERO = CDOTA_PlayerResource.HasSelectedHero

	-- ReplaceHeroWith can briefly leave a player slot flagged as selected while
	-- its new hero entity does not exist yet. Preserve the useful vanilla
	-- contract globally: a positive result always has a usable hero handle.
	CDOTA_PlayerResource.HasSelectedHero = function(self, playerID)
		if not _G.XHS_NATIVE_HAS_SELECTED_HERO(self, playerID) then
			return false
		end

		local hero = self:GetSelectedHeroEntity(playerID)
		if hero == nil then return false end
		if IsValidEntity ~= nil and not IsValidEntity(hero) then return false end
		if hero.IsNull ~= nil and hero:IsNull() then return false end
		return true
	end
end

-- Keep projectile instrumentation transparent to gameplay code. Every caller
-- continues to use ProjectileManager's vanilla API while the extension records
-- activity before delegating to the original engine function.
if IsServer() and ProjectileManager ~= nil then
	if ProjectileManager.CreateLinearProjectile ~= nil
		and _G.XHS_NATIVE_CREATE_LINEAR_PROJECTILE == nil then
		_G.XHS_NATIVE_CREATE_LINEAR_PROJECTILE = ProjectileManager.CreateLinearProjectile

		ProjectileManager.CreateLinearProjectile = function(manager, info)
			local counters = _G.XHSPerformanceCounters
			if counters ~= nil and counters.Increment ~= nil then
				counters:Increment("linear_projectiles", 1)
			end
			return _G.XHS_NATIVE_CREATE_LINEAR_PROJECTILE(manager, info)
		end
	end

	if ProjectileManager.CreateTrackingProjectile ~= nil
		and _G.XHS_NATIVE_CREATE_TRACKING_PROJECTILE == nil then
		_G.XHS_NATIVE_CREATE_TRACKING_PROJECTILE = ProjectileManager.CreateTrackingProjectile

		ProjectileManager.CreateTrackingProjectile = function(manager, info)
			local counters = _G.XHSPerformanceCounters
			if counters ~= nil and counters.Increment ~= nil then
				counters:Increment("tracking_projectiles", 1)
			end
			return _G.XHS_NATIVE_CREATE_TRACKING_PROJECTILE(manager, info)
		end
	end
end

if IsServer() and LinkLuaModifier ~= nil and _G.XHS_NATIVE_LINK_LUA_MODIFIER == nil then
	_G.XHS_NATIVE_LINK_LUA_MODIFIER = LinkLuaModifier
	_G.XHS_LINK_LUA_MODIFIER_REGISTRY = _G.XHS_LINK_LUA_MODIFIER_REGISTRY or {}
	_G.XHS_CLIENT_LINKED_LUA_MODIFIERS = _G.XHS_CLIENT_LINKED_LUA_MODIFIERS or {}
	_G.XHS_PENDING_CLIENT_LINK_LUA_MODIFIERS = _G.XHS_PENDING_CLIENT_LINK_LUA_MODIFIERS or {}
	_G.XHS_CLIENT_LINK_LUA_MODIFIER_THINK_ACTIVE = _G.XHS_CLIENT_LINK_LUA_MODIFIER_THINK_ACTIVE or false

	local function XHSPublishClientLinkedLuaModifiers()
		if CustomNetTables == nil then return end

		local payload = {}
		for name, entry in pairs(_G.XHS_CLIENT_LINKED_LUA_MODIFIERS) do
			payload[name] = {
				name = entry.name,
				path = entry.path,
				motion = entry.motion,
			}
		end

		CustomNetTables:SetTableValue("xhs_lua_modifiers", "client_links", payload)
	end

	local function XHSInspectClientLuaModifierLink(name, entry)
		if name == nil or entry == nil then return false, false end
		if _G.XHS_CLIENT_LINKED_LUA_MODIFIERS[name] ~= nil then return false, false end

		local modifierClass = _G[name]
		if modifierClass ~= nil and modifierClass.XHS_LINK_CLIENT == true then
			_G.XHS_CLIENT_LINKED_LUA_MODIFIERS[name] = entry
			_G.XHS_PENDING_CLIENT_LINK_LUA_MODIFIERS[name] = nil
			return true, false
		end

		if modifierClass ~= nil then
			_G.XHS_PENDING_CLIENT_LINK_LUA_MODIFIERS[name] = nil
			return false, false
		end

		entry.attempts = (entry.attempts or 0) + 1
		if entry.attempts >= 20 then
			_G.XHS_PENDING_CLIENT_LINK_LUA_MODIFIERS[name] = nil
			return false, false
		end

		return false, true
	end

	local function XHSInspectPendingClientLuaModifierLinks()
		local hasPending = false
		local changed = false

		for name, entry in pairs(_G.XHS_PENDING_CLIENT_LINK_LUA_MODIFIERS) do
			local entryChanged, entryPending = XHSInspectClientLuaModifierLink(name, entry)
			changed = changed or entryChanged
			hasPending = hasPending or entryPending
		end

		if changed then
			XHSPublishClientLinkedLuaModifiers()
		end

		if hasPending then
			return 0.1
		end

		_G.XHS_CLIENT_LINK_LUA_MODIFIER_THINK_ACTIVE = false
		return nil
	end

	local function XHSScheduleClientLuaModifierLinkInspect()
		if _G.XHS_CLIENT_LINK_LUA_MODIFIER_THINK_ACTIVE == true then return end
		if GameRules == nil or GameRules.GetGameModeEntity == nil then return end

		local mode = GameRules:GetGameModeEntity()
		if mode == nil then return end

		_G.XHS_CLIENT_LINK_LUA_MODIFIER_THINK_ACTIVE = true
		mode:SetContextThink("xhs_client_link_lua_modifier_inspect", XHSInspectPendingClientLuaModifierLinks, 0.0)
	end

	LinkLuaModifier = function(name, path, motion)
		_G.XHS_NATIVE_LINK_LUA_MODIFIER(name, path, motion)

		if name == nil or path == nil then return end

		_G.XHS_LINK_LUA_MODIFIER_REGISTRY[name] = {
			name = name,
			path = path,
			motion = motion or LUA_MODIFIER_MOTION_NONE,
		}
		_G.XHS_PENDING_CLIENT_LINK_LUA_MODIFIERS[name] = _G.XHS_LINK_LUA_MODIFIER_REGISTRY[name]

		XHSScheduleClientLuaModifierLinkInspect()
	end

	if CDOTA_BaseNPC ~= nil and CDOTA_BaseNPC.AddNewModifier ~= nil and _G.XHS_NATIVE_ADD_NEW_MODIFIER == nil then
		_G.XHS_NATIVE_ADD_NEW_MODIFIER = CDOTA_BaseNPC.AddNewModifier

		CDOTA_BaseNPC.AddNewModifier = function(self, caster, ability, modifierName, modifierTable)
			if self == nil or (IsValidEntity ~= nil and not IsValidEntity(self)) then
				return nil
			end

			local modifier = _G.XHS_NATIVE_ADD_NEW_MODIFIER(self, caster, ability, modifierName, modifierTable)
			local entry = _G.XHS_LINK_LUA_MODIFIER_REGISTRY[modifierName]
			if entry ~= nil then
				local changed = XHSInspectClientLuaModifierLink(modifierName, entry)
				if changed then
					XHSPublishClientLinkedLuaModifiers()
				end
			end

			return modifier
		end
	end
end

function GetReductionFromArmor(armor)
	return ((0.052 * armor) / (0.9 + 0.048 * armor))
end

local XHS_SUPPORTER_LIFESTEAL_CONFIG = {
	attack = {
		player_field = "attack_lifesteal_pfx",
		cooldown = 0.30,
	},
	spell = {
		player_field = "spell_lifesteal_pfx",
	},
}

local XHS_SUPPORTER_LIFESTEAL_PARTICLE_PROFILES = {
	["particles/econ/items/drow/drow_arcana/drow_arcana_lifesteal.vpcf"] = "hero_cp1",
	["particles/econ/items/lone_druid/lone_druid_immortal_2021/lone_druid_immortal_2021_lifesteal.vpcf"] = "hero_cp1",
	["particles/item/lifesteal_mask/lifesteal_particle.vpcf"] = "victim_to_hero",
}

local XHS_SUPPORTER_LIFESTEAL_BLOCKED_PREFIXES = {
	"particles/units/heroes/hero_skeletonking/wraith_king_vampiric_aura_lifesteal",
	"particles/units/heroes/hero_skeletonking/skeletonking_vampiric_aura_lifesteal",
}

local function XHSIsValidLifestealEntity(entity)
	if entity == nil then return false end
	if IsValidEntity ~= nil and not IsValidEntity(entity) then return false end
	if entity.IsNull ~= nil and entity:IsNull() then return false end
	return true
end

local function XHSGetLifestealPlayerID(hero)
	if not XHSIsValidLifestealEntity(hero) then return nil end
	if hero.IsRealHero == nil or not hero:IsRealHero() then return nil end
	if hero.GetPlayerOwnerID == nil then return nil end

	local playerID = hero:GetPlayerOwnerID()
	if type(playerID) ~= "number" or playerID < 0 then return nil end
	if PlayerResource ~= nil and PlayerResource.IsValidPlayerID ~= nil
		and not PlayerResource:IsValidPlayerID(playerID) then
		return nil
	end

	return playerID
end

local function XHSIsValidLifestealParticlePath(path)
	if type(path) ~= "string" then return false end
	local normalized = string.lower(path)
	return string.sub(normalized, 1, 10) == "particles/"
		and string.sub(normalized, -5) == ".vpcf"
end

local function XHSIsBlockedLifestealParticle(path)
	if not XHSIsValidLifestealParticlePath(path) then return false end
	local normalized = string.lower(path)

	for _, prefix in ipairs(XHS_SUPPORTER_LIFESTEAL_BLOCKED_PREFIXES) do
		if string.sub(normalized, 1, string.len(prefix)) == prefix then
			return true
		end
	end

	return false
end

local function XHSResolveSupporterLifestealParticle(hero, playerID, config)
	if Battlepass ~= nil and Battlepass.AreSupporterRewardsEnabled ~= nil then
		local success, enabled = pcall(Battlepass.AreSupporterRewardsEnabled, Battlepass, playerID)
		if success and not enabled then return nil end
	end

	if Battlepass == nil or Battlepass.GetPlayerParticle == nil then return nil end
	local particle = Battlepass:GetPlayerParticle(hero, config.player_field)
	if not XHSIsValidLifestealParticlePath(particle) then return nil end
	if XHSIsBlockedLifestealParticle(particle) then return nil end
	return particle
end

local function XHSSetLifestealParticleControlEntity(particle, controlPoint, entity)
	if not XHSIsValidLifestealEntity(entity) then return false end

	ParticleManager:SetParticleControl(particle, controlPoint, entity:GetAbsOrigin())
	ParticleManager:SetParticleControlEnt(
		particle,
		controlPoint,
		entity,
		PATTACH_POINT_FOLLOW,
		"attach_hitloc",
		entity:GetAbsOrigin(),
		true
	)
	return true
end

local function XHSCreateSupporterLifestealParticle(hero, victim, particleName)
	if not XHSIsValidLifestealParticlePath(particleName) then return false end
	if XHSIsBlockedLifestealParticle(particleName) then return false end
	if ParticleManager == nil or ParticleManager.CreateParticle == nil then return false end

	local profile = XHS_SUPPORTER_LIFESTEAL_PARTICLE_PROFILES[string.lower(particleName)] or "hero"
	local parent = hero
	if profile == "victim_to_hero" then
		if not XHSIsValidLifestealEntity(victim) then return false end
		parent = victim
	end

	local particle = ParticleManager:CreateParticle(
		particleName,
		PATTACH_ABSORIGIN_FOLLOW,
		parent
	)
	if particle == nil or particle < 0 then return false end

	if profile == "victim_to_hero" then
		XHSSetLifestealParticleControlEntity(particle, 0, victim)
		XHSSetLifestealParticleControlEntity(particle, 1, hero)
	elseif profile == "hero_cp1" then
		XHSSetLifestealParticleControlEntity(particle, 0, hero)
		XHSSetLifestealParticleControlEntity(particle, 1, hero)
	else
		XHSSetLifestealParticleControlEntity(particle, 0, hero)
	end

	ParticleManager:ReleaseParticleIndex(particle)
	return true
end

local function XHSGetSupporterLifestealState(hero)
	hero.xhs_supporter_lifesteal_fx_state = hero.xhs_supporter_lifesteal_fx_state or {}
	return hero.xhs_supporter_lifesteal_fx_state
end

local function XHSGetSupporterLifestealTime()
	if GameRules ~= nil and GameRules.GetGameTime ~= nil then
		return GameRules:GetGameTime()
	end
	if Time ~= nil then return Time() end
	return nil
end

function XHSPlaySupporterLifestealFX(hero, victim, kind, actualHeal)
	if IsServer ~= nil and not IsServer() then return false end

	local playerID = XHSGetLifestealPlayerID(hero)
	local config = XHS_SUPPORTER_LIFESTEAL_CONFIG[kind]
	local heal = tonumber(actualHeal) or 0
	if playerID == nil or config == nil or heal <= 0 then return false end

	if config.cooldown ~= nil then
		local state = XHSGetSupporterLifestealState(hero)
		local now = XHSGetSupporterLifestealTime()
		local lastTime = tonumber(state.last_attack_fx_time)
		if now ~= nil and lastTime ~= nil and now >= lastTime
			and now - lastTime < config.cooldown then
			return false
		end
		if now ~= nil then
			state.last_attack_fx_time = now
		end
	end

	local particleName = XHSResolveSupporterLifestealParticle(hero, playerID, config)
	return XHSCreateSupporterLifestealParticle(hero, victim, particleName)
end

function XHSPlaySupporterAttackLifestealFX(hero, victim, actualHeal)
	return XHSPlaySupporterLifestealFX(hero, victim, "attack", actualHeal)
end

function XHSQueueSupporterSpellLifestealFX(hero, victim, actualHeal)
	if IsServer ~= nil and not IsServer() then return false end
	if XHSGetLifestealPlayerID(hero) == nil then return false end

	local heal = tonumber(actualHeal) or 0
	if heal <= 0 then return false end

	local state = XHSGetSupporterLifestealState(hero)
	state.pending_spell_heal = (tonumber(state.pending_spell_heal) or 0) + heal
	if XHSIsValidLifestealEntity(victim) then
		state.pending_spell_victim = victim
	end
	if state.spell_fx_scheduled then return true end
	state.spell_fx_scheduled = true

	local function FlushSupporterSpellLifestealFX()
		state.spell_fx_scheduled = false
		local pendingHeal = tonumber(state.pending_spell_heal) or 0
		local pendingVictim = state.pending_spell_victim
		state.pending_spell_heal = nil
		state.pending_spell_victim = nil

		if pendingHeal > 0 then
			XHSPlaySupporterLifestealFX(hero, pendingVictim, "spell", pendingHeal)
		end
		return nil
	end

	if Timers ~= nil and Timers.CreateTimer ~= nil then
		Timers:CreateTimer(0.03, FlushSupporterSpellLifestealFX)
		return true
	end

	if GameRules ~= nil and GameRules.GetGameModeEntity ~= nil then
		local gameMode = GameRules:GetGameModeEntity()
		if gameMode ~= nil then
			local contextName = "xhs_supporter_spell_lifesteal_" .. tostring(hero:entindex())
			if DoUniqueString ~= nil then
				contextName = DoUniqueString(contextName)
			end
			gameMode:SetContextThink(contextName, FlushSupporterSpellLifestealFX, 0.03)
			return true
		end
	end

	FlushSupporterSpellLifestealFX()
	return true
end

function CDOTA_BaseNPC:SendLifestealAttack(hTarget, damage_dealt)
	local lifesteal = 0
	local lifesteal_source = nil

	for _, parent_modifier in pairs(self:FindAllModifiers()) do
		if parent_modifier and parent_modifier.GetModifierLifesteal then
			local modifier_lifesteal = tonumber(parent_modifier:GetModifierLifesteal()) or 0
			if modifier_lifesteal > lifesteal then
				lifesteal = modifier_lifesteal
				lifesteal_source = parent_modifier:GetAbility()
			end
		end
	end

	if lifesteal > 0 then
		-- OnTakeDamage supplies the final damage actually received by the victim.
		local damage = math.max(0, tonumber(damage_dealt) or 0)
		local heal = damage * (lifesteal / 100)
		if heal <= 0 then return end

		local health_before = self:GetHealth()
		self:Heal(heal, lifesteal_source)
		local actual_heal = math.max(0, self:GetHealth() - health_before)
		if actual_heal <= 0 then return end

		SendOverheadEventMessage(nil, OVERHEAD_ALERT_HEAL, self, actual_heal, nil)
		XHSPlaySupporterAttackLifestealFX(self, hTarget, actual_heal)
	end
end

function CDOTA_BaseNPC:GetRealDamageDone(hTarget)
	local base_damage = self:GetAverageTrueAttackDamage(hTarget)
	local armor_reduction = GetReductionFromArmor(hTarget:GetPhysicalArmorValue(false))
	return base_damage - (base_damage * armor_reduction)
end

function CDOTA_BaseNPC:FindItemByName(ItemName, bStash)
	local count = 8

	if bStash == true then
		count = 14
	end

	for slot = 0, count do
		local item = self:GetItemInSlot(slot)
		if item then
			if item:GetName() == ItemName then
				return item
			end
		end
	end

	return nil
end

function CDOTA_BaseNPC:RemoveItemByName(ItemName, bStash)
	local count = 8

	if bStash == true then
		count = 14
	end

	for slot = 0, count do
		local item = self:GetItemInSlot(slot)
		if item then
			if item:GetName() == ItemName then
				self:RemoveItem(item)
				break
			end
		end
	end
end

function CDOTA_BaseNPC:IncrementAttributes(amount, options)
	if self:IsIllusion() then return end
	if not self:IsAlive() then return end

	local playSound = true
	if type(options) == "table" and options.play_sound == false then
		playSound = false
	elseif options == false then
		playSound = false
	end

	if self:HasModifier("modifier_tome_of_stats") then
		self:FindModifierByName("modifier_tome_of_stats"):SetStackCount(self:FindModifierByName("modifier_tome_of_stats"):GetStackCount() + amount)
	else
		self:AddNewModifier(self, nil, "modifier_tome_of_stats", {}):SetStackCount(amount)
	end

	if XHSRecordTomeStats ~= nil and (type(options) ~= "table" or options.record_stats ~= false) then
		XHSRecordTomeStats(self, amount)
	end

	if not self.GetPlayerID then return end

	local levelupParticle = XHSGetBattlepassParticle ~= nil
		and XHSGetBattlepassParticle(self, "levelup_pfx", "particles/generic_hero_status/hero_levelup.vpcf")
		or "particles/generic_hero_status/hero_levelup.vpcf"
	local particle1 = ParticleManager:CreateParticle(levelupParticle, PATTACH_ABSORIGIN_FOLLOW, self)
	ParticleManager:SetParticleControl(particle1, 0, self:GetAbsOrigin())

	if playSound == true then
		self:EmitSound("ui.trophy_levelup")
	end

	self:CalculateStatBonus(true)
end

function CDOTA_BaseNPC:GetNetworth()
	if not self:IsRealHero() then return 0 end
	local gold = self:GetGold()

	-- Iterate over item slots adding up its gold cost
	for i = 0, 15 do
		local item = self:GetItemInSlot(i)
		if item then
			gold = gold + item:GetCost()
		end
	end

	return gold
end

-- credits to yahnich for the following
function CDOTA_BaseNPC:IsFakeHero()
	if self:IsIllusion() or (self:HasModifier("modifier_monkey_king_fur_army_soldier") or self:HasModifier("modifier_monkey_king_fur_army_soldier_hidden")) or self:IsTempestDouble() or self:IsClone() then
		return true
	else
		return false
	end
end

function CDOTA_BaseNPC:IsRealHero()
	if not self:IsNull() then
		return self:IsHero() and not (self:IsIllusion() or self:IsClone()) and not self:IsFakeHero()
	end
end

function CDOTA_BaseNPC:Blink(position, bTeamOnlyParticle, bPlaySound)
	if self:IsNull() then return end
	local blink_effect = "particles/items_fx/blink_dagger_start.vpcf"
	local blink_effect_end = "particles/items_fx/blink_dagger_end.vpcf"
	local blink_sound = "DOTA_Item.BlinkDagger.Activate"
	if self.blink_effect or self:GetPlayerOwner().blink_effect then blink_effect = self.blink_effect end
	if self.blink_effect_end or self:GetPlayerOwner().blink_effect_end then blink_effect_end = self.blink_effect_end end
	if self.blink_sound or self:GetPlayerOwner().blink_sound then blink_sound = self.blink_sound end
	if bPlaySound == true then EmitSoundOn(blink_sound, self) end
	if bTeamOnlyParticle == true then
		local blink_pfx = ParticleManager:CreateParticleForTeam(blink_effect, PATTACH_ABSORIGIN, self, self:GetTeamNumber())
		ParticleManager:ReleaseParticleIndex(blink_pfx)
	else
		ParticleManager:FireParticle(blink_effect, PATTACH_ABSORIGIN, self, { [0] = self:GetAbsOrigin() })
	end
	FindClearSpaceForUnit(self, position, true)
	ProjectileManager:ProjectileDodge(self)
	if bTeamOnlyParticle == true then
		local blink_end_pfx = ParticleManager:CreateParticleForTeam(blink_effect_end, PATTACH_ABSORIGIN, self, self:GetTeamNumber())
		ParticleManager:ReleaseParticleIndex(blink_end_pfx)
	else
		ParticleManager:FireParticle(blink_effect_end, PATTACH_ABSORIGIN, self, { [0] = self:GetAbsOrigin() })
	end
	if bPlaySound == true then EmitSoundOn("DOTA_Item.BlinkDagger.NailedIt", self) end
end

local ignored_pfx_list = {}
ignored_pfx_list["particles/dev/empty_particle.vpcf"] = true
ignored_pfx_list["particles/ambient/fountain_danger_circle.vpcf"] = true
ignored_pfx_list["particles/range_indicator.vpcf"] = true
ignored_pfx_list["particles/units/heroes/hero_skeletonking/wraith_king_ambient_custom.vpcf"] = true
ignored_pfx_list["particles/generic_gameplay/radiant_fountain_regen.vpcf"] = true
ignored_pfx_list["particles/econ/courier/courier_wyvern_hatchling/courier_wyvern_hatchling_fire.vpcf"] = true
ignored_pfx_list["particles/units/heroes/hero_wisp/wisp_tether.vpcf"] = true
ignored_pfx_list["particles/units/heroes/hero_templar_assassin/templar_assassin_trap.vpcf"] = true
ignored_pfx_list["particles/econ/courier/courier_donkey_ti7/courier_donkey_ti7_ambient.vpcf"] = true
ignored_pfx_list["particles/econ/courier/courier_golden_roshan/golden_roshan_ambient.vpcf"] = true
ignored_pfx_list["particles/econ/courier/courier_platinum_roshan/platinum_roshan_ambient.vpcf"] = true
ignored_pfx_list["particles/econ/courier/courier_roshan_darkmoon/courier_roshan_darkmoon.vpcf"] = true
ignored_pfx_list["particles/econ/courier/courier_roshan_desert_sands/baby_roshan_desert_sands_ambient.vpcf"] = true
ignored_pfx_list["particles/econ/courier/courier_roshan_ti8/courier_roshan_ti8.vpcf"] = true
ignored_pfx_list["particles/econ/courier/courier_roshan_lava/courier_roshan_lava.vpcf"] = true
ignored_pfx_list["particles/econ/courier/courier_roshan_frost/courier_roshan_frost_ambient.vpcf"] = true
ignored_pfx_list["particles/econ/courier/courier_babyroshan_winter18/courier_babyroshan_winter18_ambient.vpcf"] = true
ignored_pfx_list["particles/econ/courier/courier_babyroshan_ti9/courier_babyroshan_ti9_ambient.vpcf"] = true
ignored_pfx_list["particles/units/heroes/hero_witchdoctor/witchdoctor_voodoo_restoration.vpcf"] = true
ignored_pfx_list["particles/units/heroes/hero_earth_spirit/espirit_stoneremnant.vpcf"] = true
ignored_pfx_list["particles/econ/items/tiny/tiny_prestige/tiny_prestige_tree_ambient.vpcf"] = true
ignored_pfx_list["particles/econ/events/ti7/ti7_hero_effect_1.vpcf"] = true
ignored_pfx_list["particles/econ/events/ti9/ti9_emblem_effect_loadout.vpcf"] = true
ignored_pfx_list["particles/econ/events/ti8/ti8_hero_effect.vpcf"] = true
ignored_pfx_list["particles/econ/events/ti7/ti7_hero_effect.vpcf"] = true
ignored_pfx_list["particles/econ/events/ti10/emblem/ti10_emblem_effect.vpcf"] = true
ignored_pfx_list["particles/units/heroes/hero_ember_spirit/ember_spirit_flameguard.vpcf"] = true
ignored_pfx_list["particles/act_2/campfire_flame.vpcf"] = true

-- Keep runtime particle accounting centralized without changing particle paths.
local original_CreateParticle = CScriptParticleManager.CreateParticle
CScriptParticleManager.CreateParticle = function(self, sParticleName, iAttachType, hParent)
	if XHSPrecache and XHSPrecache.NoteRuntimeAsset then
		XHSPrecache:NoteRuntimeAsset("particle", sParticleName, "CreateParticle")
	end

	-- call the original function
	local response = original_CreateParticle(self, sParticleName, iAttachType, hParent)

	--	print("CreateParticle response:", sParticleName)

	if not ignored_pfx_list[sParticleName] and CScriptParticleManager and CScriptParticleManager.ACTIVE_PARTICLES then
		table.insert(CScriptParticleManager.ACTIVE_PARTICLES, { response, 0 })
	end

	return response
end

-- Preserve runtime asset accounting for team-scoped particles.
local original_CreateParticleForTeam = CScriptParticleManager.CreateParticleForTeam
CScriptParticleManager.CreateParticleForTeam = function(self, sParticleName, iAttachType, hParent, iTeamNumber)
	if XHSPrecache and XHSPrecache.NoteRuntimeAsset then
		XHSPrecache:NoteRuntimeAsset("particle", sParticleName, "CreateParticleForTeam")
	end

	-- call the original function
	local response = original_CreateParticleForTeam(self, sParticleName, iAttachType, hParent, iTeamNumber)

	return response
end

-- Preserve runtime asset accounting for player-scoped particles.
local original_CreateParticleForPlayer = CScriptParticleManager.CreateParticleForPlayer
CScriptParticleManager.CreateParticleForPlayer = function(self, sParticleName, iAttachType, hParent, hPlayer)
	if XHSPrecache and XHSPrecache.NoteRuntimeAsset then
		XHSPrecache:NoteRuntimeAsset("particle", sParticleName, "CreateParticleForPlayer")
	end

	-- call the original function
	local response = original_CreateParticleForPlayer(self, sParticleName, iAttachType, hParent, hPlayer)

	return response
end
