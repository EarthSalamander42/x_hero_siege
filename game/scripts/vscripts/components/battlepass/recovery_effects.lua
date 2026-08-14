-- Supporter Pass potion and rebirth particles.
--
-- The gameplay item owns the event. This helper only selects the equipped
-- player's final path from Battlepass.Player and creates that path directly.

SupporterRecoveryEffects = SupporterRecoveryEffects or {}

local HEALTH_POTION_BURST = "particles/items3_fx/fish_bones_active.vpcf"
local MANA_POTION_BURST = "particles/items3_fx/mango_active.vpcf"
local LIGHT_POTION_BURST = "particles/items2_fx/mekanism.vpcf"
local POTION_PARTICLE_LIFETIME = 1.5

local POTION_WORLD_CP_PROFILES = {
	["particles/econ/items/necrolyte/necronub_death_pulse/necrolyte_pulse_ka_friend.vpcf"] = {
		0,
		1,
	},
	["particles/units/heroes/hero_oracle/oracle_scepter_rain_of_destiny_heal_motes_cast.vpcf"] = {
		0,
		2,
	},
	["particles/units/heroes/hero_keeper_of_the_light/keeper_mana_leak_impact.vpcf"] = {
		0,
		1,
		2,
	},
}

local POTION_CHANNEL_ALLOWLIST = {
	health = {
		["particles/econ/events/ti7/bottle_ti7.vpcf"] = true,
	},
	mana = {
		["particles/econ/events/ti6/bottle_ti6.vpcf"] = true,
		["particles/econ/events/ti9/bottle_ti9.vpcf"] = true,
	},
}

local LEGACY_POTION_BURST_REPLACEMENTS = {
	["particles/econ/events/ti6/bottle_ti6.vpcf"] =
		"particles/items3_fx/mango_active.vpcf",
	["particles/econ/events/ti7/bottle_ti7.vpcf"] =
		"particles/items_fx/arcane_boots_recipient.vpcf",
	["particles/econ/events/ti8/bottle_ti8.vpcf"] =
		"particles/units/heroes/hero_keeper_of_the_light/keeper_chakra_magic.vpcf",
	["particles/econ/events/ti9/bottle_ti9.vpcf"] =
		"particles/units/heroes/hero_obsidian_destroyer/obsidian_destroyer_essence_effect.vpcf",
	["particles/econ/events/ti10/bottle_ti10.vpcf"] =
		"particles/units/heroes/hero_medusa/medusa_mana_shield_buff_burst.vpcf",
	["particles/econ/events/fall_2022/bottle/bottle_fall2022.vpcf"] =
		"particles/items2_fx/soul_ring.vpcf",
	["particles/econ/events/seasonal_reward_line_fall_2025/bottle_fallrewardline_2025.vpcf"] =
		"particles/units/heroes/hero_antimage/antimage_manavoid_buff_burst.vpcf",
}

local function IsValidEntity(entity)
	return entity ~= nil and (entity.IsNull == nil or not entity:IsNull())
end

local function IsParticlePath(path)
	if type(path) ~= "string" then return false end
	local normalized = string.lower(path)
	return string.match(normalized, "^particles/.+%.vpcf$") ~= nil
		or normalized == "models/heroes/muerta/debut/particles/revenant/muerta_debut_revenant_spawn_portal.vpcf"
end

local function NormalizePotionParticle(path, channel)
	local fallback = MANA_POTION_BURST
	if channel == "health" then
		fallback = HEALTH_POTION_BURST
	elseif channel == "light" then
		fallback = LIGHT_POTION_BURST
	end
	if not IsParticlePath(path) then return fallback end

	local normalized = string.lower(path)
	if POTION_CHANNEL_ALLOWLIST[channel] ~= nil
		and POTION_CHANNEL_ALLOWLIST[channel][normalized] == true then
		return path
	end
	local replacement = LEGACY_POTION_BURST_REPLACEMENTS[normalized]
	if replacement ~= nil then return replacement end
	if string.find(normalized, "/bottle", 1, true)
		or string.find(normalized, "bottle_", 1, true) then
		return fallback
	end
	return path
end

local function GetPlayerParticle(hero, key, fallback)
	if Battlepass ~= nil and Battlepass.GetPlayerParticle ~= nil then
		return Battlepass:GetPlayerParticle(hero, key, fallback)
	end
	return fallback
end

local function PlayParticle(hero, particlePath, lifetime, options)
	if not IsValidEntity(hero) or not IsParticlePath(particlePath) then return nil end
	options = type(options) == "table" and options or {}

	local origin = hero:GetAbsOrigin()
	local worldControlPoints = POTION_WORLD_CP_PROFILES[string.lower(particlePath)]
	local particle = ParticleManager:CreateParticle(
		particlePath,
		worldControlPoints ~= nil and PATTACH_WORLDORIGIN or PATTACH_ABSORIGIN_FOLLOW,
		worldControlPoints ~= nil and nil or hero
	)
	if particle == nil or particle < 0 then return nil end

	if worldControlPoints ~= nil then
		for _, controlPoint in ipairs(worldControlPoints) do
			ParticleManager:SetParticleControl(particle, controlPoint, origin)
		end
	else
		ParticleManager:SetParticleControl(particle, 0, origin)
	end
	if options.externally_managed == true then
		-- Content Studio owns this index so STOP/new-preview can destroy it.
		-- Ordinary gameplay keeps the historical release/self-termination path.
	elseif lifetime ~= nil and lifetime > 0 and Timers ~= nil then
		Timers:CreateTimer(lifetime, function()
			ParticleManager:DestroyParticle(particle, false)
			ParticleManager:ReleaseParticleIndex(particle)
			return nil
		end)
	else
		ParticleManager:ReleaseParticleIndex(particle)
	end
	return particle
end

function SupporterRecoveryEffects:Init()
	self.initialized = true
	return self
end

function SupporterRecoveryEffects:PlayPotion(hero, potionKind, fallback)
	local kind = string.lower(tostring(potionKind or ""))
	if kind == "hp" then kind = "health" end
	if kind == "mp" then kind = "mana" end
	if kind == "full" then kind = "light" end
	if kind ~= "health" and kind ~= "mana" and kind ~= "light" then return nil end

	fallback = NormalizePotionParticle(fallback, kind)
	local key = "mana_potion_pfx"
	if kind == "health" then
		key = "health_potion_pfx"
	elseif kind == "light" then
		key = "light_potion_pfx"
	end
	local particlePath = NormalizePotionParticle(
		GetPlayerParticle(hero, key, fallback),
		kind
	)
	return PlayParticle(hero, particlePath, POTION_PARTICLE_LIFETIME)
end

function SupporterRecoveryEffects:PlayRebirth(hero, fallback, options)
	return PlayParticle(
		hero,
		GetPlayerParticle(hero, "rebirth_pfx", fallback),
		nil,
		options
	)
end

return SupporterRecoveryEffects
