require('libraries/timers')
require('phases/phase2')

function EquipOrbs(keys)
local caster = keys.caster

	Timers:CreateTimer(0.05, function()
		caster:RemoveModifierByName("modifier_orb_of_fire")
		caster:RemoveModifierByName("modifier_orb_of_lightning")
		caster:RemoveModifierByName("modifier_orb_of_earth")
		caster:RemoveModifierByName("modifier_orb_of_frost")
		caster:RemoveModifierByName("modifier_orb_of_darkness")
	end)
end

function CooldownOrbs(keys)
local caster = keys.caster
local ability = keys.ability
local Items = {
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

	for Item = 1, #Items do
		for itemSlot = 0, 5 do
			local item = caster:GetItemInSlot(itemSlot)
			if item ~= nil then
				if item:GetName() == Items[Item] then
					local itemName = item:GetName()
					item:StartCooldown(10.0)
				end
			end
		end
	end
end

-- Orb of Fire
function Splash(event)
local attacker = event.caster
local target = event.target
local ability = event.ability
local radius = ability:GetSpecialValueFor("full_damage_radius")
local cleave = ability:GetSpecialValueFor("cleave_pct_tooltip")
local full_damage = attacker:GetAverageTrueAttackDamage(attacker)
local cleave_pct = cleave * full_damage / 100

	local splash_targets = FindUnitsInRadius(DOTA_TEAM_BADGUYS, target:GetAbsOrigin(), nil, radius, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)
	local splash_targets2 = FindUnitsInRadius(DOTA_TEAM_NEUTRALS, target:GetAbsOrigin(), nil, radius, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)
	local splash_targets3 = FindUnitsInRadius(DOTA_TEAM_CUSTOM_1, target:GetAbsOrigin(), nil, radius, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)
	if attacker:GetTeamNumber() == 2 then
		for _, unit in pairs(splash_targets) do
			if unit ~= target and not unit:IsBuilding() then
				ApplyDamage({victim = unit, attacker = attacker, damage = cleave_pct, ability = ability, damage_type = DAMAGE_TYPE_PHYSICAL})
			end
		end
		for _, unit in pairs(splash_targets2) do
			if unit ~= target and not unit:IsBuilding() then
				ApplyDamage({victim = unit, attacker = attacker, damage = cleave_pct, ability = ability, damage_type = DAMAGE_TYPE_PHYSICAL})
			end
		end
		for _, unit in pairs(splash_targets3) do
			if unit ~= target and not unit:IsBuilding() then
				ApplyDamage({victim = unit, attacker = attacker, damage = cleave_pct, ability = ability, damage_type = DAMAGE_TYPE_PHYSICAL})
			end
		end
	end
end

-- Orb of Lightning
function Purge(event)
local caster = event.caster
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
local target = event.target
local ability = event.ability

	if ability:IsCooldownReady() then
		ability:StartCooldown(10.0)
	end
end

-- Key of the 3 Moons
function KeyUnequip(keys)
local hero = keys.caster

	hero.has_epic_1 = false
end

-- Shield of Invincibility
function ShieldUnequip(keys)
local hero = keys.caster

	hero.has_epic_2 = false
end

-- Lightning Sword
function SwordUnequip(keys)
local hero = keys.caster

	hero.has_epic_3 = false
end

-- Ring of Superiority
function RingUnequip(keys)
local hero = keys.caster

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
			CreateUnitByName("npc_dota_hero_magtheridon_medium", point, true, nil, nil, DOTA_TEAM_BADGUYS)
		end
	end
end

function respawnMagtheridon()

	local magtheridon = CreateUnitByName("npc_dota_hero_magtheridon", point, true, nil, nil, DOTA_TEAM_BADGUYS)
	local ankh = CreateItem("item_magtheridon_ankh", mag, mag)

	if itemCharges -1 ~= 0 then
		magtheridon:AddItem(ankh)
	end

	ankh:SetCurrentCharges(itemCharges -1)
	magtheridon:EmitSound("Ability.Reincarnation")
	BossBar(magtheridon, "mag")
end

function respawnMagtheridonMedium(keys)
local caster = keys.caster

	for i = 1, 2 do
		CreateUnitByName("npc_dota_hero_magtheridon_small", caster:GetAbsOrigin(), true, nil, nil, DOTA_TEAM_BADGUYS)
	end
end
