-- Nevermore's Necromastery (for the clientside modifier)

frostivus_boss_necromastery = class({})

function frostivus_boss_necromastery:IsHiddenWhenStolen() return true end
function frostivus_boss_necromastery:IsRefreshable() return true end
function frostivus_boss_necromastery:IsStealable() return false end

function frostivus_boss_necromastery:GetIntrinsicModifierName()
	return "modifier_frostivus_necromastery"
end

-- Passive modifier
LinkLuaModifier("modifier_frostivus_necromastery", "boss_scripts/boss_abilities/necromastery.lua", LUA_MODIFIER_MOTION_NONE )
modifier_frostivus_necromastery = modifier_frostivus_necromastery or class({})

function modifier_frostivus_necromastery:IsHidden() return false end
function modifier_frostivus_necromastery:IsDebuff() return false end
function modifier_frostivus_necromastery:IsPurgable() return false end