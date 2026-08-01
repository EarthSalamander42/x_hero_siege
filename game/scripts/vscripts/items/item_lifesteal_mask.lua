-- Author: Cookies
-- Date: 22.11.2016

-----------------------
--    MORBID MASK    --
-----------------------

LinkLuaModifier("modifier_lifesteal_mask", "items/item_lifesteal_mask.lua", LUA_MODIFIER_MOTION_NONE)

item_lifesteal_mask = item_lifesteal_mask or class({})

local DEFAULT_ITEM_TEXTURE = "custom/lifesteal_mask"
local DEFAULT_MODIFIER_TEXTURE = "modifiers/lifesteal_mask"
local SUPPORTER_TEXTURES_BY_PLAYER = {}

local function GetOwnerPlayerID(subject)
	if subject == nil or (subject.IsNull ~= nil and subject:IsNull()) then return nil end
	for _, getter in ipairs({ "GetPlayerOwnerID", "GetPlayerID" }) do
		if subject[getter] ~= nil then
			local success, playerID = pcall(subject[getter], subject)
			if success and tonumber(playerID) ~= nil and tonumber(playerID) >= 0 then
				return tonumber(playerID)
			end
		end
	end
	return nil
end

local function NormalizeTexture(texture, fallback)
	if type(texture) == "string" and texture ~= "" then
		return texture
	end
	return fallback
end

local function GetEquippedAttackLifestealTextures(parent)
	local itemTexture = DEFAULT_ITEM_TEXTURE
	local modifierTexture = DEFAULT_MODIFIER_TEXTURE
	if not IsServer() or parent == nil or parent:IsNull() then
		return itemTexture, modifierTexture
	end

	local playerID = GetOwnerPlayerID(parent)
	if playerID == nil
		or Battlepass == nil
		or Battlepass.GetEquippedSupporterItem == nil then
		return itemTexture, modifierTexture
	end
	if Battlepass.AreSupporterRewardsEnabled ~= nil
		and not Battlepass:AreSupporterRewardsEnabled(playerID) then
		return itemTexture, modifierTexture
	end

	local reward = Battlepass:GetEquippedSupporterItem(playerID, "attack_lifesteal")
	if type(reward) ~= "table" then
		return itemTexture, modifierTexture
	end

	return NormalizeTexture(reward.item_texture, itemTexture),
		NormalizeTexture(reward.modifier_texture, modifierTexture)
end

function item_lifesteal_mask:GetAbilityTextureName()
	local caster = self:GetCaster()
	if IsServer() then
		local itemTexture = GetEquippedAttackLifestealTextures(caster)
		return itemTexture
	end

	local textures = SUPPORTER_TEXTURES_BY_PLAYER[GetOwnerPlayerID(caster)]
	return textures and textures.item_texture or DEFAULT_ITEM_TEXTURE
end

function item_lifesteal_mask:GetIntrinsicModifierName()
	return "modifier_lifesteal_mask"
end

modifier_lifesteal_mask = modifier_lifesteal_mask or class({})
modifier_lifesteal_mask.XHS_LINK_CLIENT = true

function modifier_lifesteal_mask:GetTexture()
	return self.supporter_modifier_texture or DEFAULT_MODIFIER_TEXTURE
end

function modifier_lifesteal_mask:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_TOOLTIP,
	}
end

function modifier_lifesteal_mask:OnCreated()
	self.lifesteal_pct = self:GetAbility():GetSpecialValueFor("lifesteal_pct")
	self.supporter_item_texture = DEFAULT_ITEM_TEXTURE
	self.supporter_modifier_texture = DEFAULT_MODIFIER_TEXTURE

	if IsServer() then
		self:SetHasCustomTransmitterData(true)
		self:RefreshSupporterTextures()
		self:StartIntervalThink(0.5)
	end
end

function modifier_lifesteal_mask:OnRefresh()
	self.lifesteal_pct = self:GetAbility():GetSpecialValueFor("lifesteal_pct")
	if IsServer() then
		self:RefreshSupporterTextures()
	end
end

function modifier_lifesteal_mask:AddCustomTransmitterData()
	return {
		item_texture = self.supporter_item_texture or DEFAULT_ITEM_TEXTURE,
		modifier_texture = self.supporter_modifier_texture or DEFAULT_MODIFIER_TEXTURE,
		player_id = GetOwnerPlayerID(self:GetParent()) or -1,
	}
end

function modifier_lifesteal_mask:HandleCustomTransmitterData(data)
	self.supporter_item_texture = NormalizeTexture(data.item_texture, DEFAULT_ITEM_TEXTURE)
	self.supporter_modifier_texture = NormalizeTexture(data.modifier_texture, DEFAULT_MODIFIER_TEXTURE)
	local playerID = tonumber(data.player_id)
	if playerID ~= nil and playerID >= 0 then
		SUPPORTER_TEXTURES_BY_PLAYER[playerID] = {
			item_texture = self.supporter_item_texture,
			modifier_texture = self.supporter_modifier_texture,
		}
	end
end

function modifier_lifesteal_mask:RefreshSupporterTextures()
	if not IsServer() then return end

	local itemTexture, modifierTexture = GetEquippedAttackLifestealTextures(self:GetParent())
	local playerID = GetOwnerPlayerID(self:GetParent())
	local needsClientSync = self.supporter_texture_player_id ~= playerID
	self.supporter_texture_player_id = playerID
	if self.supporter_item_texture ~= itemTexture
		or self.supporter_modifier_texture ~= modifierTexture
		or needsClientSync then
		self.supporter_item_texture = itemTexture
		self.supporter_modifier_texture = modifierTexture
		self:SendBuffRefreshToClients()
	end
end

function modifier_lifesteal_mask:OnIntervalThink()
	self:RefreshSupporterTextures()
end

function modifier_lifesteal_mask:OnTooltip()
	return self.lifesteal_pct
end

function modifier_lifesteal_mask:GetModifierLifesteal()
	return self.lifesteal_pct
end
