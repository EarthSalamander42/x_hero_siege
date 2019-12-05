-- Author: Cookies
-- Date: 05.12.2019

LinkLuaModifier("modifier_ankh_passives", "items/ankh_of_reincarnation.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_doom_artifact_passives", "items/doom_artifact.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_key_passives", "items/item_key_of_the_three_moons.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_shield_of_invincibility", "items/shield_of_invincibility.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_lightning_sword_unique", "items/item_lightning_sword.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_lifesteal_lightning_sword", "items/item_lightning_sword.lua", LUA_MODIFIER_MOTION_NONE)

item_doom_artifact = item_doom_artifact or class({})

function item_doom_artifact:GetIntrinsicModifierName()
	return "modifier_ankh_passives"
end

modifier_doom_artifact_passives = modifier_doom_artifact_passives or class({})

function modifier_doom_artifact_passives:OnCreated()
	if not IsServer() then return end

	if _G.DOOM_ARTIFACT_MERGED == false then
		_G.DOOM_ARTIFACT_MERGED = true

		self:GetParent():EmitSound("Hero_TemplarAssassin.Trap")
		local line_duration = 10
		Notifications:TopToAll({hero = self:GetParent():GetName(), duration = line_duration})
--		Notifications:TopToAll({text = self:GetParent():GetUnitName().." ", duration = line_duration, continue = true})
		Notifications:TopToAll({text = PlayerResource:GetPlayerName(self:GetParent():GetPlayerID()).." ", duration = line_duration, continue = true})
		Notifications:TopToAll({text = "#xhs_doom_artifact_merged", duration = line_duration, style = {color = "Red"}, continue = true})
	end
end
