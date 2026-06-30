LinkLuaModifier("modifier_wisp_passive", "abilities/heroes/hero_wisp.lua", LUA_MODIFIER_MOTION_NONE)

local WISP_SUPPORTER_AMBIENT_PARTICLES = {
	blue = "particles/units/heroes/hero_abaddon/holdout_borrowed_time.vpcf",
	green = "particles/units/heroes/hero_abaddon/holdout_borrowed_time_2.vpcf",
	red = "particles/units/heroes/hero_abaddon/holdout_borrowed_time_3.vpcf",
	gold = "particles/units/heroes/hero_abaddon/holdout_borrowed_time_4.vpcf",
	purple = "particles/units/heroes/hero_abaddon/holdout_borrowed_time_purple.vpcf",
}

local WISP_SUPPORTER_STATUS_PARTICLES = {
	[1] = WISP_SUPPORTER_AMBIENT_PARTICLES.red, -- Lead Developer
	[2] = WISP_SUPPORTER_AMBIENT_PARTICLES.red, -- Developer
	[3] = WISP_SUPPORTER_AMBIENT_PARTICLES.blue, -- Administrator
	[4] = WISP_SUPPORTER_AMBIENT_PARTICLES.red, -- Ember Donator
	[5] = WISP_SUPPORTER_AMBIENT_PARTICLES.gold, -- Golden Donator
	[6] = WISP_SUPPORTER_AMBIENT_PARTICLES.green, -- Donator
	[7] = WISP_SUPPORTER_AMBIENT_PARTICLES.blue, -- Stoneguard Donator
	[8] = WISP_SUPPORTER_AMBIENT_PARTICLES.purple, -- Earthwarden Donator
	[9] = WISP_SUPPORTER_AMBIENT_PARTICLES.purple, -- Legacy Gaben Donator
}

local function GetWispDonatorLevel(parent)
	if not api or not parent then
		return 0
	end

	return tonumber(api:GetDonatorStatus(parent:GetPlayerID())) or 0
end

local function GetWispSupporterParticle(donator_level)
	return WISP_SUPPORTER_STATUS_PARTICLES[tonumber(donator_level) or 0]
end

local function HasWispSupporterAmbient(donator_level)
	return GetWispSupporterParticle(donator_level) ~= nil
end

local function ApplyWispSupporterAmbientControls(particle, parent)
	ParticleManager:SetParticleControl(particle, 0, parent:GetAbsOrigin())
end

wisp_pick_random_hero = wisp_pick_random_hero or class({})

function wisp_pick_random_hero:OnSpellStart()
	if not IsServer() then return end
	self.caster = self:GetCaster()

	local random = RandomInt(1, #HEROLIST)
	local IsAvailableHero = Entities:FindByName(nil, "trigger_hero_" .. random)
	local difficulty = GameRules:GetCustomGameDifficulty()
	local hero_name

	if random == 12 then
		print("This hero is disabled! Re-rolls Random Hero")
		self:OnSpellStart()
		return
	end

	hero_name = "npc_dota_hero_" .. HEROLIST[random]

	if IsAvailableHero then
		UTIL_Remove(IsAvailableHero)
	end

	local particle = ParticleManager:CreateParticle("particles/generic_hero_status/hero_levelup.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.caster, self.caster)
	ParticleManager:SetParticleControl(particle, 0, self.caster:GetAbsOrigin())

	EmitSoundOnClient("ui.trophy_levelup", PlayerResource:GetPlayer(self.caster:GetPlayerID()))

	self.caster:AddNewModifier(self.caster, nil, "modifier_command_restricted", {})

	Notifications:Bottom(self.caster:GetPlayerOwnerID(), {
		duration = 5.0,
		segments = {
			{ hero = hero_name },
			{ text = "HERO: ",                              style = { color = "white" } },
			{ text = "#npc_dota_hero_" .. HEROLIST[random], style = { color = "white" } },
		},
	})

	XHSPrecache:ReplaceHeroWith(self.caster:GetPlayerID(), hero_name, XHS_STARTING_GOLD[difficulty] * 2, 0, self.caster, {
		startingItems = true,
	})
end

wisp_passives = wisp_passives or class({})

function wisp_passives:GetIntrinsicModifierName()
	return "modifier_wisp_passive"
end

modifier_wisp_passive = modifier_wisp_passive or class({})

function modifier_wisp_passive:IsHidden() return true end

function modifier_wisp_passive:CheckState()
	return {
		[MODIFIER_STATE_UNSELECTABLE] = true,
		[MODIFIER_STATE_NO_TEAM_MOVE_TO] = true,
		[MODIFIER_STATE_NO_TEAM_SELECT] = true,
		[MODIFIER_STATE_ATTACK_IMMUNE] = true,
		[MODIFIER_STATE_MAGIC_IMMUNE] = true,
	}
end

function modifier_wisp_passive:OnCreated()
	if not IsServer() then return end

	local parent = self:GetParent()
	local donator_level = GetWispDonatorLevel(parent)
	local particleName = GetWispSupporterParticle(donator_level)

	if particleName then
		self.supporterAmbientParticleName = particleName
		self.supporterAmbientPfx = ParticleManager:CreateParticle(self.supporterAmbientParticleName, PATTACH_ABSORIGIN_FOLLOW, parent)
		ApplyWispSupporterAmbientControls(self.supporterAmbientPfx, parent)

		if IsInToolsMode() then
			print("[XHS Wisp] supporter ambient created, donator status:", donator_level, self.supporterAmbientParticleName)
		end

		self.supporterAmbientRefreshAttempts = 0
		self:StartIntervalThink(1.0)
	end
end

function modifier_wisp_passive:OnIntervalThink()
	if not IsServer() then return end

	if not self.supporterAmbientPfx then
		self:StartIntervalThink(-1)
		return
	end

	self.supporterAmbientRefreshAttempts = (self.supporterAmbientRefreshAttempts or 0) + 1

	local parent = self:GetParent()
	local donator_level = GetWispDonatorLevel(parent)
	local particleName = GetWispSupporterParticle(donator_level)

	if not particleName then
		ParticleManager:DestroyParticle(self.supporterAmbientPfx, false)
		ParticleManager:ReleaseParticleIndex(self.supporterAmbientPfx)
		self.supporterAmbientPfx = nil
		self.supporterAmbientParticleName = nil
		self:StartIntervalThink(-1)
		return
	end

	if self.supporterAmbientParticleName ~= particleName then
		ParticleManager:DestroyParticle(self.supporterAmbientPfx, false)
		ParticleManager:ReleaseParticleIndex(self.supporterAmbientPfx)
		self.supporterAmbientParticleName = particleName
		self.supporterAmbientPfx = ParticleManager:CreateParticle(particleName, PATTACH_ABSORIGIN_FOLLOW, parent)
	end

	ApplyWispSupporterAmbientControls(self.supporterAmbientPfx, parent)

	if donator_level > 0 or self.supporterAmbientRefreshAttempts >= 10 then
		if IsInToolsMode() then
			print("[XHS Wisp] supporter ambient finalized, donator status:", donator_level, self.supporterAmbientParticleName)
		end

		self:StartIntervalThink(-1)
	end
end

function modifier_wisp_passive:OnDestroy()
	if not IsServer() then return end

	if self.supporterAmbientPfx then
		ParticleManager:DestroyParticle(self.supporterAmbientPfx, false)
		ParticleManager:ReleaseParticleIndex(self.supporterAmbientPfx)
		self.supporterAmbientPfx = nil
		self.supporterAmbientParticleName = nil
	end
end
