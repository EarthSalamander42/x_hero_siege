-- Supporter Pass potion and rebirth cosmetic runtime.
--
-- Gameplay code calls the empty XHS anchors only after this module has proven
-- that the affected unit is the equipped player's real Radiant hero. Otherwise
-- the original particle is created with the original call shape.

SupporterRecoveryEffects = SupporterRecoveryEffects or {}

local HEALTH_POTION_ANCHOR = "particles/custom/supporter_pass/health_potion_anchor.vpcf"
local MANA_POTION_ANCHOR = "particles/custom/supporter_pass/mana_potion_anchor.vpcf"
local REBIRTH_ANCHOR = "particles/custom/supporter_pass/rebirth_anchor.vpcf"

local SLOT_ALIASES = {
	ankh = "rebirth",
	health_potion = "potion",
	mana_potion = "potion",
	potion_effect = "potion",
	potions = "potion",
	reincarnation = "rebirth",
	rebirth_effect = "rebirth",
	revival = "rebirth",
	respawn = "rebirth",
}

local ID_FIELDS = {
	"entitlement_id",
	"catalog_item_id",
	"catalog_id",
	"reward_item_id",
	"reward_id",
	"item_id",
	"id",
	"sku",
	"slug",
	"key",
	"name",
}

local DIRECT_PARTICLE_FIELDS = {
	health = {
		"health_potion_particle",
		"health_potion_pfx",
		"health_particle",
		"health_pfx",
	},
	mana = {
		"mana_potion_particle",
		"mana_potion_pfx",
		"mana_particle",
		"mana_pfx",
	},
	rebirth = {
		"rebirth_particle",
		"rebirth_pfx",
		"reincarnation_particle",
		"reincarnation_pfx",
		"respawn_particle",
		"respawn_pfx",
	},
}

local function IsValidEntity(entity)
	return entity ~= nil and (entity.IsNull == nil or not entity:IsNull())
end

local function NormalizeSlot(slot)
	local normalized = string.lower(tostring(slot or ""))
	return SLOT_ALIASES[normalized] or normalized
end

local function IsParticlePath(value)
	if type(value) ~= "string" then return false end
	local normalized = string.lower(value)
	return string.match(normalized, "^particles/.+%.vpcf$") ~= nil
end

local function IsEligibleHero(hero)
	if not IsValidEntity(hero) or hero.IsRealHero == nil or not hero:IsRealHero() then
		return false
	end
	if hero.IsIllusion ~= nil and hero:IsIllusion() then return false end
	if hero.IsClone ~= nil and hero:IsClone() then return false end
	if hero.IsTempestDouble ~= nil and hero:IsTempestDouble() then return false end
	if hero.IsOwnedByAnyPlayer ~= nil and not hero:IsOwnedByAnyPlayer() then return false end
	if hero.GetTeamNumber == nil or hero:GetTeamNumber() ~= (DOTA_TEAM_GOODGUYS or 2) then
		return false
	end
	if hero.GetPlayerOwnerID == nil then return false end

	local playerID = hero:GetPlayerOwnerID()
	return playerID ~= nil
		and playerID >= 0
		and PlayerResource ~= nil
		and PlayerResource:IsValidPlayerID(playerID)
end

local function CopyTable(source)
	local result = {}
	if type(source) ~= "table" then return result end
	for key, value in pairs(source) do
		result[key] = value
	end
	return result
end

local function MergeMissing(target, source, visited)
	if type(target) ~= "table" or type(source) ~= "table" then return target end
	visited = visited or {}
	if visited[source] then return target end
	visited[source] = true

	for key, value in pairs(source) do
		if (target[key] == nil or target[key] == "") and value ~= nil and value ~= "" then
			target[key] = value
		elseif type(target[key]) == "table" and type(value) == "table" then
			MergeMissing(target[key], value, visited)
		end
	end
	return target
end

local function GetItemIdentity(item)
	if type(item) ~= "table" then
		return item ~= nil and tostring(item) or nil
	end
	for _, field in ipairs(ID_FIELDS) do
		if item[field] ~= nil and tostring(item[field]) ~= "" then
			return tostring(item[field])
		end
	end
	return nil
end

local function ItemMatchesIdentity(item, identity)
	if type(item) ~= "table" or identity == nil then return false end
	local expected = tostring(identity)
	for _, field in ipairs(ID_FIELDS) do
		if item[field] ~= nil and tostring(item[field]) == expected then
			return true
		end
	end
	return false
end

local function ItemMatchesSlot(item, slot)
	if type(item) ~= "table" then return false end
	local candidate = item.slot_id or item.item_type or item.type or item.slot
	return candidate == nil or candidate == "" or NormalizeSlot(candidate) == slot
end

local function AsLoadoutItem(value, slot)
	if type(value) == "table" then
		local item = CopyTable(value)
		item.slot_id = item.slot_id or item.item_type or slot
		return item
	end
	if value == nil or tostring(value) == "" then return nil end
	return {
		item_id = tostring(value),
		slot_id = slot,
	}
end

local function FindSlotInLoadout(loadout, slot, visited, depth)
	if type(loadout) ~= "table" then return nil end
	depth = depth or 0
	if depth > 5 then return nil end
	visited = visited or {}
	if visited[loadout] then return nil end
	visited[loadout] = true

	local direct = loadout[slot]
	if direct ~= nil then
		return AsLoadoutItem(direct, slot)
	end

	for key, value in pairs(loadout) do
		if NormalizeSlot(key) == slot then
			local item = AsLoadoutItem(value, slot)
			if item ~= nil then return item end
		end
		if type(value) == "table" and ItemMatchesSlot(value, slot) then
			local candidateSlot = NormalizeSlot(value.slot_id or value.item_type or value.type or value.slot)
			if candidateSlot == slot then
				return AsLoadoutItem(value, slot)
			end
		end
	end

	for _, wrapper in ipairs({ "loadout", "items", "rewards", "equipped" }) do
		local item = FindSlotInLoadout(loadout[wrapper], slot, visited, depth + 1)
		if item ~= nil then return item end
	end
	return nil
end

local function GetSteamPlayer(playerID)
	if api == nil or type(api.players) ~= "table" or PlayerResource == nil then return nil end
	local steamID = tostring(PlayerResource:GetSteamID(playerID))
	return api.players[steamID]
end

local function GetRawLoadouts(playerID)
	local sources = {}

	if api ~= nil and api.GetSupporterPassLoadout ~= nil then
		local success, loadout = pcall(api.GetSupporterPassLoadout, api, playerID)
		if success and type(loadout) == "table" then
			table.insert(sources, loadout)
		end
	end

	local player = GetSteamPlayer(playerID)
	if type(player) == "table" then
		local pass = player.supporter_pass
		if type(pass) == "table" and type(pass.loadout) == "table" then
			table.insert(sources, pass.loadout)
		end
		if type(player.loadout) == "table" then
			table.insert(sources, player.loadout)
		end
	end

	if CustomNetTables ~= nil and CustomNetTables.GetTableValue ~= nil then
		local published = CustomNetTables:GetTableValue("supporter_pass_player", tostring(playerID))
		if type(published) == "table" and type(published.loadout) == "table" then
			table.insert(sources, published.loadout)
		end
	end

	return sources
end

local function GetEquippedItem(playerID, slot)
	if Battlepass ~= nil and Battlepass.GetEquippedSupporterItem ~= nil then
		local success, item = pcall(
			Battlepass.GetEquippedSupporterItem,
			Battlepass,
			playerID,
			slot
		)
		if success and type(item) == "table" and ItemMatchesSlot(item, slot) then
			return CopyTable(item)
		end
	end

	for _, loadout in ipairs(GetRawLoadouts(playerID)) do
		local item = FindSlotInLoadout(loadout, slot)
		if item ~= nil then return item end
	end
	return nil
end

local function GetPlayerArmory(playerID)
	local sources = {}
	if api ~= nil and api.GetSupporterPassArmory ~= nil then
		local success, armory = pcall(api.GetSupporterPassArmory, api, playerID)
		if success and type(armory) == "table" then
			table.insert(sources, armory)
		end
	end

	local player = GetSteamPlayer(playerID)
	if type(player) == "table" and type(player.supporter_pass) == "table" then
		for _, field in ipairs({ "armory", "entitlements", "items" }) do
			if type(player.supporter_pass[field]) == "table" then
				table.insert(sources, player.supporter_pass[field])
			end
		end
	end

	if CustomNetTables ~= nil and CustomNetTables.GetTableValue ~= nil then
		local armory = CustomNetTables:GetTableValue(
			"supporter_pass_armory",
			"rewards_" .. tostring(playerID)
		)
		if type(armory) == "table" then
			table.insert(sources, armory)
		end
	end
	return sources
end

local function FindDefinition(root, identity, slot, visited, depth)
	if type(root) ~= "table" or identity == nil then return nil end
	depth = depth or 0
	if depth > 7 then return nil end
	visited = visited or {}
	if visited[root] then return nil end
	visited[root] = true

	if ItemMatchesIdentity(root, identity) and ItemMatchesSlot(root, slot) then
		return root
	end

	for _, value in pairs(root) do
		if type(value) == "table" then
			local found = FindDefinition(value, identity, slot, visited, depth + 1)
			if found ~= nil then return found end
		end
	end
	return nil
end

local function GetCatalogSources(playerID)
	local sources = GetPlayerArmory(playerID)

	if api ~= nil and type(api.supporter_pass) == "table" then
		for _, field in ipairs({ "rewards", "catalog", "items", "armory" }) do
			if type(api.supporter_pass[field]) == "table" then
				table.insert(sources, api.supporter_pass[field])
			end
		end
	end

	if CustomNetTables ~= nil and CustomNetTables.GetTableValue ~= nil then
		for _, tableName in ipairs({
			"supporter_pass_rewards_free",
			"supporter_pass_rewards_premium",
		}) do
			local rewards = CustomNetTables:GetTableValue(tableName, "rewards")
			if type(rewards) == "table" then
				table.insert(sources, rewards)
			end
		end
	end
	return sources
end

local function HydrateItem(playerID, slot, item)
	if type(item) ~= "table" then return nil end
	local result = CopyTable(item)
	local identity = GetItemIdentity(result)

	if identity ~= nil and Battlepass ~= nil and Battlepass.ResolveSupporterItem ~= nil then
		local success, resolved = pcall(
			Battlepass.ResolveSupporterItem,
			Battlepass,
			playerID,
			identity,
			slot
		)
		if success and type(resolved) == "table" then
			MergeMissing(result, resolved)
		end
	end

	if identity ~= nil and ItemsGame ~= nil and ItemsGame.GetItemKV ~= nil then
		local success, definition = pcall(ItemsGame.GetItemKV, ItemsGame, identity)
		if success and type(definition) == "table" and ItemMatchesSlot(definition, slot) then
			MergeMissing(result, definition)
		end
	end

	if identity ~= nil then
		for _, source in ipairs(GetCatalogSources(playerID)) do
			local definition = FindDefinition(source, identity, slot)
			if definition ~= nil then
				MergeMissing(result, definition)
				break
			end
		end
	end

	return result
end

local ExtractDirectParticle

local function ChannelMatches(value, channel)
	if value == nil then return false end
	local normalized = string.lower(tostring(value))
	if channel == "health" then
		return normalized == "health" or normalized == "health_potion"
	elseif channel == "mana" then
		return normalized == "mana" or normalized == "mana_potion"
	end
	return normalized == "rebirth"
		or normalized == "reincarnation"
		or normalized == "respawn"
		or normalized == "ankh"
end

local function ExtractHookedParticle(root, anchor, channel, visited, depth)
	if type(root) ~= "table" then return nil end
	depth = depth or 0
	if depth > 7 then return nil end
	visited = visited or {}
	if visited[root] then return nil end
	visited[root] = true

	local direct = ExtractDirectParticle(root, channel)
	if direct ~= nil and direct ~= anchor then return direct end

	local mapped = root[anchor]
	if IsParticlePath(mapped) and mapped ~= anchor then return mapped end
	if type(mapped) == "table" then
		local mappedPath = mapped.path
			or mapped.modifier
			or mapped.replacement
			or mapped.particle
			or mapped.pfx
			or mapped.file
			or mapped.resource
			or mapped.value
		if IsParticlePath(mappedPath) and mappedPath ~= anchor then return mappedPath end
	end

	local hook = root.hook or root.asset or root.source or root.anchor or root.original
	local path = root.path
		or root.modifier
		or root.replacement
		or root.particle
		or root.pfx
		or root.file
		or root.resource
		or root.value
	if IsParticlePath(path) and path ~= anchor then
		if tostring(hook or "") == anchor then return path end
		local kind = root.channel or root.slot_id or root.item_type or root.effect_type or root.name
		if (hook == nil or hook == "") and ChannelMatches(kind, channel) then
			return path
		end
	end

	for _, value in pairs(root) do
		if type(value) == "table" then
			local found = ExtractHookedParticle(value, anchor, channel, visited, depth + 1)
			if found ~= nil then return found end
		end
	end
	return nil
end

ExtractDirectParticle = function(item, channel)
	for _, field in ipairs(DIRECT_PARTICLE_FIELDS[channel] or {}) do
		if IsParticlePath(item[field]) then return item[field] end
	end

	local channelPayload = item[channel]
	if type(channelPayload) == "table" then
		for _, field in ipairs({ "particle", "particle_path", "pfx", "path", "file" }) do
			if IsParticlePath(channelPayload[field]) then return channelPayload[field] end
		end
	elseif IsParticlePath(channelPayload) then
		return channelPayload
	end

	-- Rebirth is a single-channel slot, so generic direct particle fields are
	-- unambiguous. Potion rewards must expose both health and mana explicitly.
	if channel == "rebirth" then
		for _, field in ipairs({ "particle", "particle_path", "pfx", "effect", "file" }) do
			if IsParticlePath(item[field]) then return item[field] end
		end
	end
	return nil
end

local function GetAnchorOverride(playerID, anchor)
	if CustomNetTables == nil or CustomNetTables.GetTableValue == nil then return nil end
	local value = CustomNetTables:GetTableValue(
		"supporter_pass_player",
		anchor .. "_" .. tostring(playerID)
	)
	if type(value) ~= "table" then return nil end
	local path = value[1] or value["1"]
	if IsParticlePath(path) and path ~= anchor then return path end
	return nil
end

local function ResolveParticle(playerID, slot, channel, anchor)
	local equipped = GetEquippedItem(playerID, slot)
	if equipped == nil then return nil end
	equipped = HydrateItem(playerID, slot, equipped) or equipped

	local direct = ExtractDirectParticle(equipped, channel)
	if direct ~= nil and direct ~= anchor then return direct end

	for _, field in ipairs({ "runtime_assets", "visuals", "assets", "particles", "effects", "payload", "metadata" }) do
		local particle = ExtractHookedParticle(equipped[field], anchor, channel)
		if particle ~= nil then return particle end
	end

	-- The central loadout applier may already have published the exact hook. It
	-- is only considered after proving that this slot is currently equipped.
	return GetAnchorOverride(playerID, anchor)
end

local function RewardsEnabled(playerID)
	if Battlepass ~= nil and Battlepass.AreSupporterRewardsEnabled ~= nil then
		local success, enabled = pcall(
			Battlepass.AreSupporterRewardsEnabled,
			Battlepass,
			playerID
		)
		if success and enabled ~= nil then return enabled == true end
	end

	if CustomNetTables ~= nil and CustomNetTables.GetTableValue ~= nil then
		local player = CustomNetTables:GetTableValue("supporter_pass_player", tostring(playerID)) or {}
		local value = player.pass_rewards
		if value == nil then value = player.bp_rewards end
		if value ~= nil then
			return value ~= false and value ~= 0 and value ~= "0"
		end
	end
	return true
end

local function PublishAnchorOverride(playerID, anchor, particle)
	if CustomNetTables == nil
		or CustomNetTables.GetTableValue == nil
		or CustomNetTables.SetTableValue == nil then
		return false
	end

	local current = CustomNetTables:GetTableValue(
		"supporter_pass_player",
		anchor .. "_" .. tostring(playerID)
	)
	local currentPath = type(current) == "table" and (current[1] or current["1"]) or nil
	if currentPath ~= particle then
		CustomNetTables:SetTableValue(
			"supporter_pass_player",
			anchor .. "_" .. tostring(playerID),
			{ particle }
		)
	end
	return true
end

local function PlayParticle(hero, fallback, slot, channel, anchor, setOrigin)
	if not IsValidEntity(hero) or not IsParticlePath(fallback) then return nil end

	local particlePath = fallback
	local cosmetic = false
	if IsEligibleHero(hero) then
		local playerID = hero:GetPlayerOwnerID()
		if RewardsEnabled(playerID) then
			local replacement = ResolveParticle(playerID, slot, channel, anchor)
			if replacement ~= nil and PublishAnchorOverride(playerID, anchor, replacement) then
				particlePath = anchor
				cosmetic = true
			end
		end
	end

	local particle
	if cosmetic then
		-- The fourth argument is intentionally the actual benefiting hero. XHS's
		-- particle wrapper uses it to resolve the per-player anchor override.
		particle = ParticleManager:CreateParticle(
			particlePath,
			PATTACH_ABSORIGIN_FOLLOW,
			hero,
			hero
		)
	else
		-- Keep the vanilla path and original three-argument call when the reward
		-- is disabled, unavailable or belongs to an ineligible unit.
		particle = ParticleManager:CreateParticle(
			particlePath,
			PATTACH_ABSORIGIN_FOLLOW,
			hero
		)
	end

	if particle ~= nil and particle >= 0 then
		if setOrigin and hero.GetAbsOrigin ~= nil then
			ParticleManager:SetParticleControl(particle, 0, hero:GetAbsOrigin())
		end
		ParticleManager:ReleaseParticleIndex(particle)
	end
	return particle
end

function SupporterRecoveryEffects:Init()
	if self.initialized then return self end
	self.initialized = true
	return self
end

function SupporterRecoveryEffects:PlayPotion(hero, potionKind, fallback)
	local kind = string.lower(tostring(potionKind or ""))
	if kind == "hp" then kind = "health" end
	if kind == "mp" then kind = "mana" end
	if kind ~= "health" and kind ~= "mana" then return nil end

	local anchor = kind == "health" and HEALTH_POTION_ANCHOR or MANA_POTION_ANCHOR
	return PlayParticle(hero, fallback, "potion", kind, anchor, false)
end

function SupporterRecoveryEffects:PlayRebirth(hero, fallback)
	return PlayParticle(hero, fallback, "rebirth", "rebirth", REBIRTH_ANCHOR, true)
end

SupporterRecoveryEffects.HEALTH_POTION_ANCHOR = HEALTH_POTION_ANCHOR
SupporterRecoveryEffects.MANA_POTION_ANCHOR = MANA_POTION_ANCHOR
SupporterRecoveryEffects.REBIRTH_ANCHOR = REBIRTH_ANCHOR

return SupporterRecoveryEffects
