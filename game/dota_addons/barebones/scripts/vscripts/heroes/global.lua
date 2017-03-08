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
		if ability_alt then
			if ability_alt:IsCooldownReady() then
			hero:SetRespawnsDisabled(true)
			ability_alt:StartCooldown(60.0)
			hero.respawn_timer = Timers:CreateTimer(respawntime, function() 
				hero:SetRespawnPosition(position)
				hero:EmitSound("Ability.ReincarnationAlt")
				hero:RespawnHero(false, false, false)
				ParticleManager:CreateParticle("particles/items_fx/aegis_respawn.vpcf", PATTACH_ABSORIGIN_FOLLOW, hero)
				hero:SetRespawnsDisabled(false)
			end)
			print("Ability Reincarnation")
			elseif not ability_alt:IsCooldownReady() then
				print("No Respawns Bitch!")
			end
		elseif not ability_alt or not ability_alt:IsCooldownReady() then
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
			print("Item Reincarnation")
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

function FountainThink( keys )
	local caster = keys.caster
	local ability = keys.ability
	local particle_danger = keys.particle_danger

	local danger_pfx = ParticleManager:CreateParticle(particle_danger, PATTACH_CUSTOMORIGIN, nil)
	ParticleManager:SetParticleControl(danger_pfx, 0, caster:GetAbsOrigin())

	-- If mega creeps are nearby on arena mode, disable fountain protection
	if END_GAME_ON_KILLS and not caster.fountain_disabled then
		local enemy_creeps = FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), nil, 5000, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
		for	_,enemy in pairs(enemy_creeps) do
			if enemy:GetTeam() ~= caster:GetTeam() and string.find(enemy:GetUnitName(), "mega") then
				ability:ApplyDataDrivenModifier(caster, caster, "modifier_imba_fountain_disabled", {})
				caster.fountain_disabled = true
			end
		end
	end
end

function FountainBash( keys )
	local caster = keys.caster
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1
	local particle_bash = keys.particle_bash
	local sound_bash = keys.sound_bash

	-- Parameters
	local bash_radius = ability:GetLevelSpecialValueFor("bash_radius", ability_level)
	local bash_duration = ability:GetLevelSpecialValueFor("bash_duration", ability_level)
	local bash_distance = ability:GetLevelSpecialValueFor("bash_distance", ability_level)
	local bash_height = ability:GetLevelSpecialValueFor("bash_height", ability_level)
	local fountain_loc = caster:GetAbsOrigin()

	-- Knockback table
	local fountain_bash =	{
		should_stun = 1,
		knockback_duration = bash_duration,
		duration = bash_duration,
		knockback_distance = bash_distance,
		knockback_height = bash_height,
		center_x = fountain_loc.x,
		center_y = fountain_loc.y,
		center_z = fountain_loc.z
	}

	-- Find units to bash
	local nearby_enemies = FindUnitsInRadius(caster:GetTeamNumber(), fountain_loc, nil, bash_radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)

	-- Bash all of them
	for _,enemy in pairs(nearby_enemies) do

		-- Bash
		enemy:RemoveModifierByName("modifier_knockback")
		enemy:AddNewModifier(caster, ability, "modifier_knockback", fountain_bash)

		-- Play particle
		local bash_pfx = ParticleManager:CreateParticle(particle_bash, PATTACH_ABSORIGIN, enemy)
		ParticleManager:SetParticleControl(bash_pfx, 0, enemy:GetAbsOrigin())

		-- Play sound
		enemy:EmitSound(sound_bash)
	end
end
