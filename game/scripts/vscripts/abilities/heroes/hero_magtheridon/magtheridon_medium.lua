-- Author: Cookies
-- Date: 05.12.2019

LinkLuaModifier("modifier_magtheridon_medium", "abilities/heroes/hero_magtheridon/magtheridon_medium.lua", LUA_MODIFIER_MOTION_NONE)

magtheridon_medium = magtheridon_medium or class({})

function magtheridon_medium:GetIntrinsicModifierName()
	return "modifier_magtheridon_medium"
end

modifier_magtheridon_medium = modifier_magtheridon_medium or class({})

function modifier_magtheridon_medium:DeclareFunctions() return {
	MODIFIER_EVENT_ON_DEATH,
} end

function modifier_magtheridon_medium:OnDeath(params)
	if not IsServer() then return end

	if params.unit == self:GetParent() then
		for i = 1, 2 do
			CreateUnitByName("npc_dota_hero_magtheridon_small", self:GetParent():GetAbsOrigin() + RandomVector(100), true, nil, nil, DOTA_TEAM_CUSTOM_2)
		end
	end
end
