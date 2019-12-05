function LevelUpAbility(event)
local caster = event.caster

	if caster:IsRealHero() then
		local this_ability = event.ability		
		local this_abilityName = this_ability:GetAbilityName()
		local this_abilityLevel = this_ability:GetLevel()

		local ability_name = event.ability_name
		local ability_handle = caster:FindAbilityByName(ability_name)	
		local ability_level = ability_handle:GetLevel()

		if ability_level ~= this_abilityLevel then
			ability_handle:SetLevel(this_abilityLevel)
		end
	end
end

--[[Author: Noya
	Date: 09.08.2015.
	Hides all dem hats
]]
function HideWearables(event)
	local hero = event.caster
	local ability = event.ability

	hero.hiddenWearables = {} -- Keep every wearable handle in a table to show them later
	local model = hero:FirstMoveChild()
	while model ~= nil do
		if model:GetClassname() == "dota_item_wearable" then
			model:AddEffects(EF_NODRAW) -- Set model hidden
			table.insert(hero.hiddenWearables, model)
		end
		model = model:NextMovePeer()
	end
end

function ShowWearables(event)
	local hero = event.caster

	for i,v in pairs(hero.hiddenWearables) do
		v:RemoveEffects(EF_NODRAW)
	end
end

function AbilityStack(keys) -- Called only On Spawn
local caster = keys.caster
local ability = keys.ability
local ability_level = ability:GetLevel() - 1
local modifier_stack = keys.modifier_stack
local stacks = caster:GetLevel()

	ability:ApplyDataDrivenModifier(caster, caster, modifier_stack, {})
	caster:SetModifierStackCount(modifier_stack, ability, stacks)
end

function SwapAbilities(keys)
local caster = keys.caster
local ability = keys.ability
local sub_ability = keys.sub_ability
local main_ability = ability:GetAbilityName()

	caster:SwapAbilities(main_ability, sub_ability, false, true)
end

function CastleMuradin(event)
if event.ability == nil then return end
local caster = event.caster
local ability = event.ability
local heroes = HeroList:GetAllHeroes()
local Waypoint = Entities:FindByName(nil, "final_wave_player_1")
local Health = ability:GetSpecialValueFor("hp_tooltip")
local InvTime = ability:GetSpecialValueFor("invulnerability_time")
local PauseTime = 10.0

	if caster:GetHealthPercent() <= Health then
		PauseCreeps(PauseTime)

		local Muradin = CreateUnitByName("npc_dota_creature_muradin_bronzebeard", Waypoint:GetAbsOrigin(), false, nil, nil, DOTA_TEAM_GOODGUYS)
		Muradin:SetInitialGoalEntity(Waypoint)
		Muradin:MoveToPositionAggressive(Waypoint:GetAbsOrigin())
		Muradin:EmitSound("MountainKing.Avatar")

		for _, hero in pairs(heroes) do
			PlayerResource:SetCameraTarget(hero:GetPlayerID(), Muradin)
			hero:AddNewModifier(nil, nil, "modifier_boss_stun", {Duration = 10, IsHidden = true})
			hero:AddNewModifier(nil, nil, "modifier_invulnerable", {Duration = 10, IsHidden = true})

			Timers:CreateTimer(5.0, function()
				PlayerResource:SetCameraTarget(hero:GetPlayerID(), nil)
			end)
		end

		caster:AddNewModifier(caster, nil, "modifier_invulnerable", {duration = InvTime + PauseTime})
		Notifications:TopToAll({text = "Muradin is requested to defend your castle!", duration = PauseTime, continue = true})

		Timers:CreateTimer(InvTime + PauseTime, function()
			UTIL_Remove(Muradin)
		end)

		caster:RemoveAbility("castle_muradin_defend")
	end
end

-- Global Splash
function Splash(event)
local attacker = event.caster
local target = event.target
local ability = event.ability
local radius = ability:GetSpecialValueFor("radius")
local cleave = ability:GetSpecialValueFor("cleave_pct")

	local splash_targets = FindUnitsInRadius(attacker:GetTeamNumber(), target:GetAbsOrigin(), nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)

	for _, unit in pairs(splash_targets) do
		if target:IsBuilding() then return end
		if unit ~= target and not unit:IsBuilding() then
			if ability:IsItem() and attacker:GetAttackCapability() == DOTA_UNIT_CAP_RANGED_ATTACK then return end
			local full_damage = attacker:GetRealDamageDone(unit)
			local cleave_damage = cleave * full_damage / 100
--			print(full_damage, cleave_damage) -- prints the right value, but somehow damage dealt are incorrect still
			ApplyDamage({victim = unit, attacker = attacker, damage = cleave_damage, ability = ability, damage_type = DAMAGE_TYPE_PURE})
		end
	end
end

function EndChannel(keys)
	EndAnimation(keys.caster)
end

--	LinkLuaModifier( "modifier_hero", "heroes/global", LUA_MODIFIER_MOTION_NONE )

--	modifier_hero = class({})

--	function modifier_hero:IsDebuff() return false end
--	function modifier_hero:IsHidden() return true end
--	function modifier_hero:IsPurgable() return false end
--	function modifier_hero:IsPurgeException() return false end
--	function modifier_hero:IsStunDebuff() return false end
--	function modifier_hero:RemoveOnDeath() return false end

--	function modifier_hero:GetAttackSound()
--		local hero_name = self:GetParent():GetUnitName()
--		hero_name = string.gsub(hero_name, "npc_dota_hero_", "")
--	
--		print("Hero_"..hero_name..".Attack")
--		return "Hero_"..hero_name..".Attack"
--	end
--	
--	function modifier_hero:DeclareFunctions()
--		local decFuncs = 
--		{
--			MODIFIER_PROPERTY_TRANSLATE_ATTACK_SOUND
--		}
--		return decFuncs
--	end
