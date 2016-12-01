--[[
	Author: Cookies
	Date: 25.11.2016.
	Swap hero, keeping all stats and abilities leveled up
]]

function SkinChangerPhaseCast(keys)
local caster = keys.caster
CURRENT_XP = caster:GetCurrentXP()
print(CURRENT_XP)

	StartAnimation(caster, {duration = 1.933, activity = ACT_DOTA_VICTORY, rate = 1.0})
end

function SkinChangerCaster( keys )
local caster = keys.caster
local PlayerID = caster:GetPlayerID()
local gold = caster:GetGold()
local loc = caster:GetAbsOrigin()
local Strength = caster:GetBaseStrength()
local Intellect = caster:GetBaseIntellect()
local Agility = caster:GetBaseAgility()
local HP = caster:GetHealth()
local Mana = caster:GetMana()

	local hero = PlayerResource:ReplaceHeroWith( PlayerID, "npc_dota_hero_keeper_of_the_light", gold, 0)
	local ability = hero:FindAbilityByName("holdout_skin_changer_warrior"):StartCooldown(60)
	hero:AddExperience(CURRENT_XP, false, false)

	local items = {}
	for i = 0, 5 do
		if caster:GetItemInSlot(i) ~= nil and caster:GetItemInSlot(i):GetName() ~= "item_classchange_reset" then
			itemCopy = CreateItem(caster:GetItemInSlot(i):GetName(), nil, nil)
			items[i] = itemCopy
		end
	end
	for i = 0, 5 do
		if items[i] ~= nil then
			hero:AddItem(items[i])
			items[i]:SetCurrentCharges(caster:GetItemInSlot(i):GetCurrentCharges())
		end
	end
	hero:SetAbsOrigin(loc)
	hero:SetBaseStrength(Strength)
	hero:SetBaseIntellect(Intellect)
	hero:SetBaseAgility(Agility)
	hero:SetHealth(HP)
	hero:SetMana(Mana)

	Timers:CreateTimer(1.0, function()
		if not caster:IsNull() then
			UTIL_Remove(caster)
		end
	end)
end

function SkinChangerWarrior( keys )
local caster = keys.caster
local PlayerID = caster:GetPlayerID()
local gold = caster:GetGold()
local loc = caster:GetAbsOrigin()
local Strength = caster:GetBaseStrength()
local Intellect = caster:GetBaseIntellect()
local Agility = caster:GetBaseAgility()
local HP = caster:GetHealth()
local Mana = caster:GetMana()

	local hero = PlayerResource:ReplaceHeroWith( PlayerID, "npc_dota_hero_chaos_knight", gold, 0)
	local ability = hero:FindAbilityByName("holdout_skin_changer_caster"):StartCooldown(60)
	hero:AddExperience(CURRENT_XP, false, false)

local items = {}
	for i = 0, 5 do
		if caster:GetItemInSlot(i) ~= nil and caster:GetItemInSlot(i):GetName() ~= "item_classchange_reset" then
			itemCopy = CreateItem(caster:GetItemInSlot(i):GetName(), nil, nil)
			items[i] = itemCopy
		end
	end

	for i = 0, 5 do
		if items[i] ~= nil then
			hero:AddItem(items[i])
			items[i]:SetCurrentCharges(caster:GetItemInSlot(i):GetCurrentCharges())
		end
	end
	hero:SetAbsOrigin(loc)
	hero:SetBaseStrength(Strength)
	hero:SetBaseIntellect(Intellect)
	hero:SetBaseAgility(Agility)
	hero:SetHealth(HP)
	hero:SetMana(Mana)

	Timers:CreateTimer(1.0, function()
		if not caster:IsNull() then
			UTIL_Remove(caster)
		end
	end)
end
