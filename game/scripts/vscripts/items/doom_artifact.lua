-- Author: Cookies
-- Date: 05.12.2019

LinkLuaModifier("modifier_doom_artifact_passives", "items/doom_artifact.lua", LUA_MODIFIER_MOTION_NONE)

-- not sure those are required, probably if item is given through cheats
LinkLuaModifier("modifier_key_passives", "items/item_key_of_the_three_moons.lua", LUA_MODIFIER_MOTION_NONE)

LinkLuaModifier("modifier_shield_of_invincibility", "items/shield_of_invincibility.lua", LUA_MODIFIER_MOTION_NONE)

LinkLuaModifier("modifier_lightning_sword_unique", "items/item_lightning_sword.lua", LUA_MODIFIER_MOTION_NONE)

LinkLuaModifier("modifier_ring_of_superiority", "items/ring_of_superiority/modifier_ring_of_superiority.lua", LUA_MODIFIER_MOTION_NONE)

item_doom_artifact = item_doom_artifact or class({})

modifier_doom_artifact_passives = modifier_doom_artifact_passives or class({})

function modifier_doom_artifact_passives:IsHidden() return true end

function modifier_doom_artifact_passives:OnCreated()
	if not IsServer() then return end

	local line_duration = 10

	if _G.DOOM_ARTIFACT_MERGED == false then
		_G.DOOM_ARTIFACT_MERGED = true

		self:GetParent():EmitSound("Hero_TemplarAssassin.Trap")
		Notifications:TopToAll({hero = self:GetParent():GetName(), duration = line_duration})
--		Notifications:TopToAll({text = self:GetParent():GetUnitName().." ", duration = line_duration, continue = true})
		Notifications:TopToAll({text = PlayerResource:GetPlayerName(self:GetParent():GetPlayerID()).." ", duration = line_duration, continue = true})
		Notifications:TopToAll({text = "#xhs_doom_artifact_merged", duration = line_duration, style = {color = "Red"}, continue = true})
	end

	self:SetDuration(line_duration, true)

	-- Don't need to handle modifiers removal, can't unequip this item
	self:GetParent():AddNewModifier(self:GetParent(), self:GetAbility(), "modifier_key_passives", {})

	self:GetParent():AddNewModifier(self:GetParent(), self:GetAbility(), "modifier_shield_of_invincibility", {})

	self:GetParent():AddNewModifier(self:GetParent(), self:GetAbility(), "modifier_lightning_sword_unique", {})

	self:GetParent():AddNewModifier(self:GetParent(), self:GetAbility(), "modifier_ring_of_superiority", {})
end
