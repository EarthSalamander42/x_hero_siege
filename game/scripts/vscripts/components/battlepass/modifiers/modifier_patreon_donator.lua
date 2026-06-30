modifier_patreon_donator = class({})

local DONATOR_BORROWED_TIME_PARTICLES = {
	blue = "particles/units/heroes/hero_abaddon/holdout_borrowed_time.vpcf",
	green = "particles/units/heroes/hero_abaddon/holdout_borrowed_time_2.vpcf",
	red = "particles/units/heroes/hero_abaddon/holdout_borrowed_time_3.vpcf",
	gold = "particles/units/heroes/hero_abaddon/holdout_borrowed_time_4.vpcf",
	purple = "particles/units/heroes/hero_abaddon/holdout_borrowed_time_purple.vpcf",
}

local DONATOR_STATUS_BORROWED_TIME_PARTICLES = {
	[1] = DONATOR_BORROWED_TIME_PARTICLES.red, -- Lead Developer
	[2] = DONATOR_BORROWED_TIME_PARTICLES.red, -- Developer
	[3] = DONATOR_BORROWED_TIME_PARTICLES.blue, -- Administrator
	[4] = DONATOR_BORROWED_TIME_PARTICLES.red, -- Ember Donator
	[5] = DONATOR_BORROWED_TIME_PARTICLES.gold, -- Golden Donator
	[6] = DONATOR_BORROWED_TIME_PARTICLES.green, -- Donator
	[7] = DONATOR_BORROWED_TIME_PARTICLES.blue, -- Stoneguard Donator
	[8] = DONATOR_BORROWED_TIME_PARTICLES.purple, -- Earthwarden Donator
	[9] = DONATOR_BORROWED_TIME_PARTICLES.purple, -- Legacy Gaben Donator
}

local BORROWED_TIME_PARTICLES = {
	["particles/units/heroes/hero_abaddon/abaddon_borrowed_time.vpcf"] = true,
	["particles/units/heroes/hero_abaddon/holdout_borrowed_time.vpcf"] = true,
	["particles/units/heroes/hero_abaddon/holdout_borrowed_time_2.vpcf"] = true,
	["particles/units/heroes/hero_abaddon/holdout_borrowed_time_3.vpcf"] = true,
	["particles/units/heroes/hero_abaddon/holdout_borrowed_time_4.vpcf"] = true,
	["particles/units/heroes/hero_abaddon/holdout_borrowed_time_custom.vpcf"] = true,
	["particles/units/heroes/hero_abaddon/holdout_borrowed_time_purple.vpcf"] = true,
}

local function GetDonatorBorrowedTimeParticle(playerID)
	local donatorLevel = 0
	if api and api.GetDonatorStatus then
		donatorLevel = tonumber(api:GetDonatorStatus(playerID)) or 0
	end

	return DONATOR_STATUS_BORROWED_TIME_PARTICLES[donatorLevel]
end

local function NormalizeDonatorEffect(effectName, playerID)
	if BORROWED_TIME_PARTICLES[effectName] then
		return GetDonatorBorrowedTimeParticle(playerID) or ""
	end

	return effectName
end

function modifier_patreon_donator:IsHidden() return true end
function modifier_patreon_donator:IsPurgable() return false end

function modifier_patreon_donator:OnCreated()
	if not IsServer() then return end

	self:SetStackCount(api:GetDonatorStatus(self:GetParent():GetPlayerID()))
	self.current_effect_name = ""
	self:SetDonatorEffect(api:GetPlayerEmblem(self:GetParent():GetPlayerID()))
	self:StartIntervalThink(0.2)
end

function modifier_patreon_donator:SetDonatorEffect(effectName)
	self.base_effect_name = effectName
	self.effect_name = NormalizeDonatorEffect(self.base_effect_name, self:GetParent():GetPlayerID())
	self:RefreshEffect()
end

function modifier_patreon_donator:OnIntervalThink()
	if not IsServer() then return end

	self:SetStackCount(api:GetDonatorStatus(self:GetParent():GetPlayerID()))
	self.effect_name = NormalizeDonatorEffect(self.base_effect_name, self:GetParent():GetPlayerID())
	for _, v in ipairs(SHARED_NODRAW_MODIFIERS) do
		if self:GetParent():HasModifier(v) then
--			print("hide donator effect...")
			self.effect_name = ""
			self:RefreshEffect()
			return
		end
	end

--	print(self.effect_name)
	self:RefreshEffect()
end

function modifier_patreon_donator:RefreshEffect()
	if not IsServer() then return end
	if not self:GetParent() then return end

	self.effect_name = NormalizeDonatorEffect(self.effect_name, self:GetParent():GetPlayerID())

	if self.current_effect_name ~= self.effect_name then
--		print("Old Effect:", self.current_effect_name)
--		print("Effect:", self.effect_name)

		self.current_effect_name = self.effect_name

		if self.pfx then
			ParticleManager:DestroyParticle(self.pfx, false)
			ParticleManager:ReleaseParticleIndex(self.pfx)
		end

		if self.effect_name and self.effect_name ~= "" then
			self.pfx = ParticleManager:CreateParticle(self.effect_name, PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
			ParticleManager:SetParticleControl(self.pfx, 0, self:GetParent():GetAbsOrigin())
		end
	end
end

function modifier_patreon_donator:OnDestroy()
	if not IsServer() then return end

	if self.pfx then
		ParticleManager:DestroyParticle(self.pfx, false)
		ParticleManager:ReleaseParticleIndex(self.pfx)
	end
end
