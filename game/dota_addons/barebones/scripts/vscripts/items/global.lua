-- Orb of Fire
function Splash(event)
	local attacker = event.caster
	local target = event.target
	local ability = event.ability
	local radius = ability:GetSpecialValueFor("full_damage_radius")
	local full_damage = attacker:GetAttackDamage()

	local splash_targets = FindUnitsInRadius(attacker:GetTeamNumber(), target:GetAbsOrigin(), nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)
	for _,unit in pairs(splash_targets) do
		if unit ~= target and not unit:IsBuilding() then
			ApplyDamage({victim = unit, attacker = attacker, damage = full_damage/5, ability = ability, damage_type = DAMAGE_TYPE_PHYSICAL})
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

	if not target:IsBuilding() then
		target:Purge( RemovePositiveBuffs, RemoveDebuffs, BuffsCreatedThisFrameOnly, RemoveStuns, RemoveExceptions)
		ParticleManager:CreateParticle('particles/generic_gameplay/generic_purge.vpcf', PATTACH_ABSORIGIN_FOLLOW, target)
		target:EmitSound("DOTA_Item.DiffusalBlade.Target")
		ability:ApplyDataDrivenModifier(caster, target, 'modifier_purge', {duration = duration})
	elseif bSummoned then
		ApplyDamage({victim = target, attacker = caster, damage = ability:GetSpecialValueFor('damage_to_summons'), damage_type = DAMAGE_TYPE_PURE, ability = ability})
	end
end

-- Orb of Earth
function Bash(event)
	local caster = event.caster
	local target = event.target
	local ability = event.ability

	ability:StartCooldown(10.0)
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