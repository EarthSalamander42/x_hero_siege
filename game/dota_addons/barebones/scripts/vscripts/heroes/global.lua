require("libraries/timers")

function Lifesteal(event)
local attacker = event.attacker
local target = event.target
local ability = event.ability

	if target.GetInvulnCount == nil and not target:IsBuilding() then
		ability:ApplyDataDrivenModifier(attacker, attacker, "modifier_lifesteal", {duration = 0.03})		
	end
end

function Reincarnation(event)
local hero = event.caster
local ability = event.ability -- Item
local ability_alt = hero:FindAbilityByName("holdout_reincarnation") -- Ability
local position = hero:GetAbsOrigin()
local respawntime = ability:GetSpecialValueFor("reincarnation_time")

	if hero:IsRealHero() and ANKHS == 1 then
		hero:SetRespawnsDisabled(true)
		hero.respawn_timer = Timers:CreateTimer(respawntime, function() 
			hero:SetRespawnPosition(position)
			hero:EmitSound("Ability.ReincarnationAlt")
			hero:RespawnHero(false, false, false)
			ParticleManager:CreateParticle("particles/items_fx/aegis_respawn.vpcf", PATTACH_ABSORIGIN_FOLLOW, hero)
			hero:SetRespawnsDisabled(false)
			hero.ankh_respawn = false
		end)

		if ability_alt then
			if ability_alt:IsCooldownReady() then
				ability_alt:StartCooldown(60.0)
			end
		end

		if not ability_alt or not ability_alt:IsCooldownReady() then
			if ability then
				hero:SetRespawnsDisabled(true)
				hero.respawn_timer = Timers:CreateTimer(respawntime, function() 
					hero:SetRespawnPosition(position)
					hero:EmitSound("Ability.ReincarnationAlt")
					hero:RespawnHero(false, false, false)
					ParticleManager:CreateParticle("particles/items_fx/aegis_respawn.vpcf", PATTACH_ABSORIGIN_FOLLOW, hero)
					hero.ankh_respawn = false
					hero:SetRespawnsDisabled(false)
					end)
				hero.ankh_respawn = true

				if ability:GetCurrentCharges() -1 >= 1 then
					ability:SetCurrentCharges(ability:GetCurrentCharges() -1)
				else
					ability:RemoveSelf()
				end
			end
		end
	end
end

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
local caster = event.caster
local ability = event.ability
local heroes = HeroList:GetAllHeroes()
local Waypoint = Entities:FindByName(nil, "final_wave_player_1")
local Health = ability:GetSpecialValueFor("hp_tooltip")
local InvTime = ability:GetSpecialValueFor("invulnerability_time")
local PauseTime = 10.0

	if caster:GetHealthPercent() <= Health then
		local Muradin = CreateUnitByName("npc_dota_creature_muradin_bronzebeard", Waypoint:GetAbsOrigin(), false, nil, nil, DOTA_TEAM_GOODGUYS)
		Muradin:SetInitialGoalEntity(Waypoint)
		Muradin:MoveToPositionAggressive(Waypoint:GetAbsOrigin())
		Muradin:EmitSound("MountainKing.Avatar")
		for _, hero in pairs(heroes) do
			PlayerResource:SetCameraTarget(hero:GetPlayerID(), Muradin)
			Timers:CreateTimer(5.0, function()
				PlayerResource:SetCameraTarget(hero:GetPlayerID(), nil)
			end)
		end
		PauseCreepsCastle()
		caster:AddNewModifier(caster, nil, "modifier_invulnerable", {duration = InvTime + PauseTime})
		Notifications:TopToAll({text = "Muradin is requested to defend your castle!", duration = PauseTime, continue = true})
		Timers:CreateTimer(InvTime + PauseTime, function()
			UTIL_Remove(Muradin)
		end)
		caster:RemoveAbility("castle_muradin_defend")
	end
end
