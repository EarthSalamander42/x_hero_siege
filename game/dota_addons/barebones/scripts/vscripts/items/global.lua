require('libraries/timers')
require('phases/phase2')

Orbs = {
	"item_orb_of_fire",
	"item_orb_of_fire2",
	"item_searing_blade",
	"item_orb_of_darkness",
	"item_orb_of_darkness2",
	"item_bracer_of_the_void",
	"item_orb_of_lightning",
	"item_orb_of_lightning2",
	"item_celestial_claws",
	"item_orb_of_earth",
	"item_orb_of_frost"
}

function EquipOrbs(keys)
local caster = keys.caster
if caster:IsIllusion() then return end

	caster:RemoveModifierByName("modifier_orb_of_fire")
	caster:RemoveModifierByName("modifier_orb_of_lightning")
	caster:RemoveModifierByName("modifier_orb_of_earth")
	caster:RemoveModifierByName("modifier_orb_of_frost")
	caster:RemoveModifierByName("modifier_orb_of_darkness")

	for Item = 1, #Orbs do
		for itemSlot = 0, 5 do
			local item = caster:GetItemInSlot(itemSlot)
			if item ~= nil then
				if item:GetName() == Orbs[Item] then
					local itemName = item:GetName()
					item:StartCooldown(10.0)
				end
			end
		end
	end

	local darkness_units = FindUnitsInRadius(caster:GetTeamNumber(), Vector(0, 0, 0), nil, FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_FLAG_NONE , FIND_ANY_ORDER, false)
	for _, darkness_unit in pairs(darkness_units) do
		if darkness_unit:HasAbility("orb_of_darkness_unit") then
			darkness_unit:RemoveSelf()
		end
	end

--	for _, orb in pairs(Orbs) do
--		if caster:HasItemInInventory(orb) then
--			orb:SetActivated(false)
--		end
--	end
end

-- Orb of Lightning
function Purge(event)
local caster = event.caster
if caster:IsIllusion() then return end
local target = event.target
local ability = event.ability
local duration = ability:GetSpecialValueFor('duration')
local bSummoned = target:IsSummoned()
local RemovePositiveBuffs = true
local RemoveDebuffs = false
local BuffsCreatedThisFrameOnly = false
local RemoveStuns = false
local RemoveExceptions = false

	if ability:IsCooldownReady() then
		if not target:IsBuilding() then
			target:Purge( RemovePositiveBuffs, RemoveDebuffs, BuffsCreatedThisFrameOnly, RemoveStuns, RemoveExceptions)
			ParticleManager:CreateParticle('particles/generic_gameplay/generic_purge.vpcf', PATTACH_ABSORIGIN_FOLLOW, target)
			target:EmitSound("DOTA_Item.DiffusalBlade.Target")
			ability:ApplyDataDrivenModifier(caster, target, 'modifier_purge', {duration = duration})
			ability:StartCooldown(10.0)
		elseif bSummoned then
			ApplyDamage({victim = target, attacker = caster, damage = ability:GetSpecialValueFor('damage_to_summons'), damage_type = DAMAGE_TYPE_PURE, ability = ability})
			ability:StartCooldown(10.0)
		end
	end
end

-- Orb of Earth
function Bash(event)
local caster = event.caster
if caster:IsIllusion() then return end
local target = event.target
local ability = event.ability
if hero:IsIllusion() then return end

	if ability:IsCooldownReady() then
		ability:StartCooldown(10.0)
	end
end

-- Key of the 3 Moons
function KeyUnequip(keys)
local hero = keys.caster
if hero:IsIllusion() then return end

	hero.has_epic_1 = false
end

-- Shield of Invincibility
function ShieldUnequip(keys)
local hero = keys.caster
if hero:IsIllusion() then return end

	hero.has_epic_2 = false
end

-- Lightning Sword
function SwordUnequip(keys)
local hero = keys.caster
if hero:IsIllusion() then return end

	hero.has_epic_3 = false
end

-- Ring of Superiority
function RingUnequip(keys)
local hero = keys.caster
if hero:IsIllusion() then return end

	hero.has_epic_4 = false
end

local itemCharges = 0
local point

function Magtheridon(keys)
local unit = keys.caster
local ability = keys.ability

	if unit:GetHealth() == 0 then
		point = unit:GetAbsOrigin()
		itemCharges = ability:GetCurrentCharges()
		local respawntime = ability:GetSpecialValueFor("reincarnation_time")
		Timers:CreateTimer(respawntime,respawnMagtheridon)

		for i = 1, 8 do
			CreateUnitByName("npc_dota_hero_magtheridon_medium", point, true, nil, nil, DOTA_TEAM_CUSTOM_2)
		end
	end
end

function respawnMagtheridon()

	local magtheridon = CreateUnitByName("npc_dota_hero_magtheridon", point, true, nil, nil, DOTA_TEAM_CUSTOM_2)
	local ankh = CreateItem("item_magtheridon_ankh", mag, mag)

	if itemCharges -1 ~= 0 then
		magtheridon:AddItem(ankh)
	end

	ankh:SetCurrentCharges(itemCharges -1)
	magtheridon:EmitSound("Ability.Reincarnation")
--	BossBar(magtheridon, "mag")
	magtheridon.zone = "xhs_holdout"
end

function respawnMagtheridonMedium(keys)
local caster = keys.caster

	for i = 1, 2 do
		CreateUnitByName("npc_dota_hero_magtheridon_small", caster:GetAbsOrigin(), true, nil, nil, DOTA_TEAM_CUSTOM_2)
	end
end

function OrbOfDarkness(hero, killedUnit)
if hero:IsIllusion() then return end
local duration = 0

	if killedUnit:IsCreep() then
		if not killedUnit:IsConsideredHero() and LeavesCorpse(killedUnit) and killedUnit.no_corpse ~= true then
			if hero:HasModifier("modifier_orb_of_darkness") and hero:GetModifierStackCount("modifier_orb_of_darkness", hero) < 10 then
				if hero:FindAbilityByName("item_orb_of_darkness") then
					print("Orb of Darkness 1")
					local duration = hero:FindAbilityByName("item_orb_of_darkness"):GetSpecialValueFor("duration")
					print(duration)
				end
				hero:SetModifierStackCount("modifier_orb_of_darkness", hero, hero:GetModifierStackCount("modifier_orb_of_darkness", hero) +1)
				local unit = CreateUnitByName(killedUnit:GetUnitName(), killedUnit:GetAbsOrigin(), true, hero, hero, hero:GetTeam())
				unit:SetControllableByPlayer(hero:GetPlayerID(), true)
				unit:SetOwner(hero)
				unit:SetForwardVector(killedUnit:GetForwardVector())
				unit:AddAbility("holdout_blue_effect"):SetLevel(1)
				unit:AddAbility("orb_of_darkness_unit"):SetLevel(1)
				FindClearSpaceForUnit(unit, killedUnit:GetAbsOrigin(), true)
	
				unit:AddNewModifier(hero, nil, "modifier_kill", {duration = 25.0})
				unit:AddNewModifier(hero, nil, "modifier_summoned", {})
				unit:SetNoCorpse()
				unit.no_corpse = true
	
				for i = 0, 15 do
					local a = unit:GetAbilityByIndex(i)
					if a and not a:IsPassive() then
						a:SetActivated(false)
					end
				end
			end
		end
	end
end