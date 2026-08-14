-- Supporter Pass regeneration aura hook.
--
-- This controller adds exactly one cosmetic particle to the real hero
-- receiving an allowlisted regeneration effect. Editable persistent recipient
-- particles from those sources stay suppressed in their definitions; the
-- equipped final path is created directly here. One-shot pickup bursts,
-- shields, guards and ambient source particles stay untouched because they
-- communicate separate gameplay.
--
-- `modifier_fountain_aura_buff` is native engine content: we can observe it
-- here, but cannot safely replace its built-in particle without a global Dota
-- particle override. The selected cosmetic is therefore additive at fountain.

local MODIFIER_NAME = "modifier_supporter_regen_aura_controller"
local THINK_INTERVAL = 0.15
local SOURCE_LOSS_GRACE = 0.45

LinkLuaModifier(MODIFIER_NAME, "components/battlepass/regen_aura.lua", LUA_MODIFIER_MOTION_NONE)

SupporterRegenAura = SupporterRegenAura or {}
SupporterRegenAura.MODIFIER_NAME = MODIFIER_NAME
SupporterRegenAura.SUPPRESSED_SOURCE_PARTICLES = {
	"particles/units/heroes/hero_juggernaut/juggernaut_healing_ward_variation02.vpcf",
	"particles/econ/events/ti6/bottle_ti6.vpcf",
	"particles/econ/items/juggernaut/jugg_fortunes_tout/jugg_healing_ward_fortunes_tout_ward_gold.vpcf",
	"particles/econ/courier/courier_faceless_rex/cour_rex_ground_a.vpcf",
	"particles/econ/courier/courier_roshan_frost/courier_roshan_frost_steam.vpcf",
	"particles/items_fx/aura_assault.vpcf",
	"particles/camp_fire_buff.vpcf",
}

-- Rules are recipient modifier + originating ability. The ability filter is
-- important for modifiers reused by hostile creature/boss abilities.
local REGEN_SOURCE_RULES = {
	modifier_fountain_aura_buff = {
		abilities = { fountain_aura = true },
	},
	modifier_xhs_rune_healing = {
		allow_no_ability = true,
	},
	modifier_xhs_rune_second_wind_heal = {
		allow_no_ability = true,
	},
	modifier_xhs_rune_barrier = {
		allow_no_ability = true,
	},
	modifier_healing_ward_datadriven = {
		abilities = { holdout_healing_ward = true },
	},
	modifier_healing_ward2_datadriven = {
		abilities = { holdout_healing_ward2 = true },
	},
	modifier_rejuvenation = {
		abilities = { holdout_rejuvenation_alt = true },
	},
	modifier_imba_shadow_word_buff = {
		abilities = { holdout_rejuvenation = true },
	},
	modifier_aura_of_blight_datadriven = {
		abilities = { holdout_aura_of_blight = true },
	},
	modifier_life_regeneration_aura_datadriven = {
		abilities = { holdout_life_regeneration_aura = true },
	},
	modifier_unholy_aura_buff = {
		abilities = { holdout_unholy_aura = true },
	},
	modifier_divine_aura_buff = {
		abilities = {
			holdout_divine_aura = true,
			holdout_divine_aura_alt = true,
		},
	},
	modifier_mechanism_armor = {
		abilities = { holdout_mechanism = true },
	},
	modifier_snappy_aura_datadriven = {
		abilities = { holdout_snappy_aura = true },
	},
	modifier_campfire_effect = {
		abilities = { campfire = true },
	},
}

SupporterRegenAura.REGEN_SOURCE_RULES = REGEN_SOURCE_RULES

local function IsValidEntity(entity)
	return entity ~= nil and (entity.IsNull == nil or not entity:IsNull())
end

local function IsEligibleHero(hero)
	if not IsValidEntity(hero) or hero.IsRealHero == nil or not hero:IsRealHero() then
		return false
	end
	if hero.IsIllusion ~= nil and hero:IsIllusion() then return false end
	if hero.IsClone ~= nil and hero:IsClone() then return false end
	if hero.IsTempestDouble ~= nil and hero:IsTempestDouble() then return false end
	if hero.GetPlayerOwnerID == nil then return false end

	local playerID = hero:GetPlayerOwnerID()
	return PlayerResource ~= nil and PlayerResource:IsValidPlayerID(playerID)
end

local function GetModifierAbilityName(modifier)
	local ability = modifier:GetAbility()
	if not IsValidEntity(ability) then return nil end
	return ability:GetAbilityName()
end

function SupporterRegenAura:IsAllowedSource(modifier)
	if not IsValidEntity(modifier) then return false end

	local rule = REGEN_SOURCE_RULES[modifier:GetName()]
	if rule == nil then return false end

	local abilityName = GetModifierAbilityName(modifier)
	if abilityName == nil then
		return rule.allow_no_ability == true
	end

	return rule.abilities ~= nil and rule.abilities[abilityName] == true
end

function SupporterRegenAura:HasAllowedSource(hero)
	if not IsEligibleHero(hero) then return false end

	for _, modifier in pairs(hero:FindAllModifiers()) do
		if self:IsAllowedSource(modifier) then
			return true
		end
	end

	return false
end

function SupporterRegenAura:GetReplacement(hero)
	if not IsEligibleHero(hero) then return nil end
	if Battlepass == nil or Battlepass.GetPlayerParticle == nil then return nil end
	return Battlepass:GetPlayerParticle(hero, "regen_aura_pfx")
end

function SupporterRegenAura:Ensure(hero)
	if not IsServer() or not IsEligibleHero(hero) then return nil end

	local controller = hero:FindModifierByName(MODIFIER_NAME)
	if controller == nil then
		controller = hero:AddNewModifier(hero, nil, MODIFIER_NAME, {})
	end
	return controller
end

function SupporterRegenAura:Refresh(hero)
	if not IsServer() or not IsEligibleHero(hero) then return end

	local controller = self:Ensure(hero)
	if controller ~= nil and controller.ForceRefresh ~= nil then
		controller:ForceRefresh()
	end
end

function SupporterRegenAura:Init()
	if not IsServer() or self.initialized == true then return end
	self.initialized = true

	ListenToGameEvent("npc_spawned", function(event)
		local npc = event.entindex ~= nil and EntIndexToHScript(event.entindex) or nil
		self:Ensure(npc)
	end, nil)

	-- Also cover a tools reload or a late module initialization.
	for playerID = 0, (DOTA_MAX_TEAM_PLAYERS or 24) - 1 do
		if PlayerResource:IsValidPlayerID(playerID) then
			self:Ensure(PlayerResource:GetSelectedHeroEntity(playerID))
		end
	end
end

modifier_supporter_regen_aura_controller = modifier_supporter_regen_aura_controller or class({})
modifier_supporter_regen_aura_controller.XHS_LINK_CLIENT = true

function modifier_supporter_regen_aura_controller:IsHidden() return true end
function modifier_supporter_regen_aura_controller:IsPurgable() return false end
function modifier_supporter_regen_aura_controller:IsPurgeException() return false end
function modifier_supporter_regen_aura_controller:RemoveOnDeath() return false end
function modifier_supporter_regen_aura_controller:GetAttributes() return MODIFIER_ATTRIBUTE_PERMANENT end

function modifier_supporter_regen_aura_controller:OnCreated()
	if not IsServer() then return end

	self:StartIntervalThink(THINK_INTERVAL)
	self:Evaluate()
end

function modifier_supporter_regen_aura_controller:OnRefresh()
	if not IsServer() then return end
	self:ForceRefresh()
end

function modifier_supporter_regen_aura_controller:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_DEATH,
		MODIFIER_EVENT_ON_RESPAWN,
	}
end

function modifier_supporter_regen_aura_controller:OnDeath(event)
	if not IsServer() or event.unit ~= self:GetParent() then return end

	self.sourceMissingSince = nil
	self:StopParticle()
end

function modifier_supporter_regen_aura_controller:OnRespawn(event)
	if not IsServer() or event.unit ~= self:GetParent() then return end
	self:Evaluate()
end

function modifier_supporter_regen_aura_controller:OnDestroy()
	if not IsServer() then return end
	self:StopParticle()
end

function modifier_supporter_regen_aura_controller:ForceRefresh()
	if not IsServer() then return end

	self.sourceMissingSince = nil
	self:StopParticle()
	self:Evaluate()
end

function modifier_supporter_regen_aura_controller:StartParticle(replacement)
	if self.particleIndex ~= nil then return end

	local parent = self:GetParent()
	if not IsEligibleHero(parent) or not parent:IsAlive() then return end

	local particleIndex = ParticleManager:CreateParticle(
		replacement,
		PATTACH_ABSORIGIN_FOLLOW,
		parent
	)
	if particleIndex == nil or particleIndex < 0 then return end

	self.particleIndex = particleIndex
	self.activeReplacement = replacement
end

function modifier_supporter_regen_aura_controller:StopParticle()
	if self.particleIndex ~= nil then
		ParticleManager:DestroyParticle(self.particleIndex, true)
		ParticleManager:ReleaseParticleIndex(self.particleIndex)
	end

	self.particleIndex = nil
	self.activeReplacement = nil
end

function modifier_supporter_regen_aura_controller:Evaluate()
	if not IsServer() then return end

	local parent = self:GetParent()
	if not IsEligibleHero(parent) or not parent:IsAlive() then
		self.sourceMissingSince = nil
		self:StopParticle()
		return
	end

	local replacement = SupporterRegenAura:GetReplacement(parent)
	if replacement == nil then
		self.sourceMissingSince = nil
		self:StopParticle()
		return
	end

	if not SupporterRegenAura:HasAllowedSource(parent) then
		if self.particleIndex == nil then
			self.sourceMissingSince = nil
			return
		end

		local now = GameRules:GetGameTime()
		self.sourceMissingSince = self.sourceMissingSince or now
		if now - self.sourceMissingSince >= SOURCE_LOSS_GRACE then
			self.sourceMissingSince = nil
			self:StopParticle()
		end
		return
	end

	self.sourceMissingSince = nil
	if self.particleIndex ~= nil and self.activeReplacement ~= replacement then
		self:StopParticle()
	end
	if self.particleIndex == nil then
		self:StartParticle(replacement)
	end
end

function modifier_supporter_regen_aura_controller:OnIntervalThink()
	self:Evaluate()
end

return SupporterRegenAura
