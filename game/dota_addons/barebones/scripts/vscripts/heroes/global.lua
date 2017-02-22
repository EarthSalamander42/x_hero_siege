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
