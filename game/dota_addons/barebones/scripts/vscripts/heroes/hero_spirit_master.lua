function SpiritRemnants(keys)
local caster = keys.caster
local caster_origin = caster:GetAbsOrigin()
local direction = (keys.target_points[1] - caster_origin):Normalized()
local ability_level = keys.ability:GetLevel()
local duration = keys.Duration
direction.z = 0

local ward = {}
ward[1] = { 55, 110, 0 }	-- North-East
ward[2] = { -55, 110, 0 }	-- North-West
ward[3] = { -110, 0, 0 }	-- West
ward[4] = { 110, 0, 0 }		-- East
ward[5] = { -55, -110, 0 }	-- South-West
ward[6] = { 55, -110, 0 }	-- South-East

	for count = 1, 6 do
		local remnant = CreateUnitByName("npc_dota_stormspirit_remnant", keys.target_points[1] + Vector( ward[count][1], ward[count][2], ward[count][3]), false, caster, caster, caster:GetTeam())
		remnant:SetForwardVector(direction)
		remnant:AddNewModifier(caster, nil, "modifier_phased", {})
	end
end

function static_remnant_init(keys)
local caster = keys.caster
local target = caster:GetAbsOrigin()
local ability = keys.ability
local model_name = caster:GetModelName()
local dummyModifierName = "modifier_static_remnant_dummy_datadriven"
local dummyFreezeModifierName = "modifier_static_remnant_dummy_freeze_datadriven"
local remnant_interval_check = 0.1
local delay = ability:GetLevelSpecialValueFor( "static_remnant_delay", ability:GetLevel() - 1 )
local trigger_radius = ability:GetLevelSpecialValueFor( "static_remnant_radius", ability:GetLevel() - 1 )
local damage_radius = ability:GetLevelSpecialValueFor( "static_remnant_damage_radius", ability:GetLevel() - 1 )
local ability_damage = ability:GetLevelSpecialValueFor( "static_remnant_damage", ability:GetLevel() - 1 )
local ability_damage_type = ability:GetAbilityDamageType()
local ability_duration = ability:GetDuration()

local ward = {}
ward[1] = { 100, 200, 0 }	-- North-East
ward[2] = { -100, 200, 0 }	-- North-West
ward[3] = { -200, 0, 0 }	-- West
ward[4] = { 200, 0, 0 }		-- East
ward[5] = { -100, -200, 0 }	-- South-West
ward[6] = { 100, -200, 0 }	-- South-East

local remnant_timer = {}
remnant_timer[1] = {0}
remnant_timer[2] = {0}
remnant_timer[3] = {0}
remnant_timer[4] = {0}
remnant_timer[5] = {0}
remnant_timer[6] = {0}

	-- Dummy creation
	for count = 1, 6 do
		local dummy = CreateUnitByName("npc_dota_storm_spirit_remnant", target + Vector( ward[count][1], ward[count][2], ward[count][3]), false, caster, nil, caster:GetTeamNumber())
		ability:ApplyDataDrivenModifier( caster, dummy, dummyModifierName, {} )
		dummy:SetModel(caster:GetModelName())
		dummy:SetOriginalModel(caster:GetModelName())

		Timers:CreateTimer(delay/1.5, function()
			if not dummy:HasModifier(dummyFreezeModifierName) then
				ability:ApplyDataDrivenModifier(caster, dummy, dummyFreezeModifierName, {})
			end
		end)

		Timers:CreateTimer(delay, function()
			-- Check in aoe
			local units = FindUnitsInRadius(caster:GetTeamNumber(), dummy:GetAbsOrigin(), caster, trigger_radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, 0, false)

			-- If there is at least one unit, explode
			if #units > 0 then
				for k, v in pairs(units) do
					local damageTable = {
						victim = v,
						attacker = caster,
						damage = ability_damage,
						damage_type = ability_damage_type
					}
					ApplyDamage( damageTable )
				end

				if not dummy:IsNull() then
					EmitSoundOn("Hero_StormSpirit.StaticRemnantExplode", dummy)
					dummy:RemoveSelf()
				end	
				return nil
			else
				caster:RemoveModifierByName("modifier_static_remnant_check")
			end

			-- Update timer
			remnant_timer[count][1] = remnant_timer[count][1] + remnant_interval_check	-- 6 Remnants, so the timer goes 6 times faster, so we divide by 6

			-- Check if timer should be expired
			if remnant_timer[count][1] >= ability_duration then
				if not dummy:IsNull() then
					EmitSoundOn("Hero_StormSpirit.StaticRemnantExplode", dummy)
					dummy:RemoveSelf()
				end			
				return nil
			else
				return remnant_interval_check
			end
		end)
	end
end

-- Author: Fudge (Dota Imba)
--------------------------------------
---		   	  OVERLOAD		       ---
--------------------------------------
xhs_spirit_master_overload = xhs_spirit_master_overload or class({})
LinkLuaModifier("modifier_imba_overload",			"heroes/hero_spirit_master.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_imba_overload_buff",		"heroes/hero_spirit_master.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_imba_overload_debuff",	"heroes/hero_spirit_master.lua", LUA_MODIFIER_MOTION_NONE)

function xhs_spirit_master_overload:GetIntrinsicModifierName()
	return "modifier_imba_overload"
end

function xhs_spirit_master_overload:GetAbilityTextureName()
	return "storm_spirit_overload"
end

--- OVERLOAD PASSIVE MODIFIER
modifier_imba_overload = modifier_imba_overload or class({})

-- Modifier properties
function modifier_imba_overload:IsPassive() return true end
function modifier_imba_overload:IsDebuff() return false end
function modifier_imba_overload:IsHidden() return true end
function modifier_imba_overload:IsPurgable() return false end
function modifier_imba_overload:RemoveOnDeath() return true end

function modifier_imba_overload:DeclareFunctions()
	local funcs	=	{
		MODIFIER_EVENT_ON_ABILITY_EXECUTED
	}
	return funcs
end

function modifier_imba_overload:OnAbilityExecuted( keys )
	if IsServer() then
		if keys.ability then
			-- When an actual ability was executed
			local parent =	self:GetParent()
			-- When the attacker is Storm then
			if keys.unit == parent then
				-- Doesn't work when Storm is broken
				if not parent:PassivesDisabled() then
					-- Ignore toggles and items
					if ( not keys.ability:IsItem() and not keys.ability:IsToggle() )  then

						parent:AddNewModifier(parent, self:GetAbility(), "modifier_imba_overload_buff",	{} )
					end
				end
			end
		end
	end
end

--------------------------------
--- OVERLOAD "ACTIVE" MODIFIER
--------------------------------
modifier_imba_overload_buff = modifier_imba_overload_buff or class({})

-- Modifier properties
function modifier_imba_overload_buff:IsDebuff() return false end
function modifier_imba_overload_buff:IsHidden() return false end
function modifier_imba_overload_buff:IsPurgable() return true end

function modifier_imba_overload_buff:OnCreated()
	if IsServer() then
		-- Attach the particle to Storm
		local parent	=	self:GetParent()
		local particle	=	"particles/units/heroes/hero_stormspirit/stormspirit_overload_ambient.vpcf"
		self.particle_fx = ParticleManager:CreateParticle(particle, PATTACH_CUSTOMORIGIN, parent)
		ParticleManager:SetParticleControlEnt(self.particle_fx, 0, parent, PATTACH_POINT_FOLLOW, "attach_attack1", parent:GetAbsOrigin(), true)

	end
end

function modifier_imba_overload_buff:DeclareFunctions()
	local funcs ={
		MODIFIER_EVENT_ON_ATTACK_LANDED,
		MODIFIER_PROPERTY_TRANSLATE_ACTIVITY_MODIFIERS,
		MODIFIER_PROPERTY_OVERRIDE_ANIMATION
	}
	return funcs
end

function modifier_imba_overload_buff:OnAttackLanded( keys )
	if IsServer() then
		-- When someone affected by overload buff has attacked
		if keys.attacker == self:GetParent() then
			-- Does not proc when attacking buildings or allies
			if not keys.target:IsBuilding() and keys.target:GetTeamNumber() ~= keys.attacker:GetTeamNumber() then

				-- Ability properties
				local parent	=	self:GetParent()
				local ability	=	self:GetAbility()
				local particle	=	"particles/units/heroes/hero_stormspirit/stormspirit_overload_discharge.vpcf"
				-- Ability paramaters
				local radius 		=	ability:GetSpecialValueFor("aoe")
				local damage		=	ability:GetSpecialValueFor("damage")
				local slow_duration	=	ability:GetSpecialValueFor("slow_duration")

				-- Find enemies around the target
				local enemies	=	FindUnitsInRadius(	parent:GetTeamNumber(),
				keys.target:GetAbsOrigin(),
				nil,
				radius,
				DOTA_UNIT_TARGET_TEAM_ENEMY,
				DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_CREEP,
				ability:GetAbilityTargetFlags(),
				FIND_ANY_ORDER,
				false)

				-- Damage and apply slow to enemies near target
				for _,enemy in pairs(enemies) do

					-- Deal damage
					local damageTable = {victim = enemy,
						damage = damage,
						damage_type = DAMAGE_TYPE_MAGICAL,
						attacker = parent,
						ability = ability
					}

					ApplyDamage(damageTable)

					-- Apply debuff
					enemy:AddNewModifier(parent, ability, "modifier_imba_overload_debuff",	{duration = slow_duration} )

					-- Emit particle
					local particle_fx = ParticleManager:CreateParticle(particle, PATTACH_ABSORIGIN, parent)
					ParticleManager:SetParticleControl(particle_fx, 0, keys.target:GetAbsOrigin())
					ParticleManager:ReleaseParticleIndex(particle_fx)
					-- Remove overload buff
					self:Destroy()
				end
			end
		end
	end
end

function modifier_imba_overload_buff:GetActivityTranslationModifiers()
	if self:GetParent():GetName() == "npc_dota_hero_storm_spirit" then
		--return ACT_STORM_SPIRIT_OVERLOAD_RUN_OVERRIDE
		return "overload"
	end
	return 0
end

function modifier_imba_overload_buff:GetOverrideAnimation()
	return ACT_STORM_SPIRIT_OVERLOAD_RUN_OVERRIDE
end

function modifier_imba_overload_buff:OnDestroy()
	if IsServer() then
		-- Remove the particle
		ParticleManager:DestroyParticle(self.particle_fx, false)
		ParticleManager:ReleaseParticleIndex(self.particle_fx)
	end
end

--- OVERLOAD DEBUFF MODIFIER
modifier_imba_overload_debuff = modifier_imba_overload_debuff or class({})

-- Modifier properties
function modifier_imba_overload_debuff:IsDebuff() return true end
function modifier_imba_overload_debuff:IsHidden() return false end
function modifier_imba_overload_debuff:IsPurgable() return true end

function modifier_imba_overload_debuff:OnCreated()
	-- Ability properties
	local ability	=	self:GetAbility()
	-- Ability parmameters
	self.move_slow		=	ability:GetSpecialValueFor("move_slow")
	self.attack_slow	=	ability:GetSpecialValueFor("attack_slow")
end

function modifier_imba_overload_debuff:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT
	}
	return funcs
end

-- Slow functions
function modifier_imba_overload_debuff:GetModifierMoveSpeedBonus_Percentage()
	return self.move_slow
end

function modifier_imba_overload_debuff:GetModifierAttackSpeedBonus_Constant()
	return self.attack_slow
end

--[[
	Author: Cookies
	Date: 25.11.2016.
	Skin Changer: Swap hero, keeping all stats and abilities leveled up
]]
function SpiritSwapPhaseCast(keys)
local caster = keys.caster

	CURRENT_XP = caster:GetCurrentXP()
end

function SpiritSwap(keys)
local caster = keys.caster
local PlayerID = caster:GetPlayerID()
local gold = caster:GetGold()
local loc = caster:GetAbsOrigin()
local Strength = caster:GetBaseStrength()
local Intellect = caster:GetBaseIntellect()
local Agility = caster:GetBaseAgility()
-- local HP = caster:GetMaxHealth() * caster:GetHealthPercent() / 100
local HP = caster:GetHealth()
local Mana = caster:GetMaxMana() * caster:GetManaPercent() / 100
local AbPoints = caster:GetAbilityPoints()
local cooldowns_caster = {}

	if caster:GetUnitName() == "npc_dota_hero_storm_spirit" then
		hero = PlayerResource:ReplaceHeroWith( PlayerID, "npc_dota_hero_earth_spirit", gold, 0)
		local ability = hero:FindAbilityByName("holdout_spirit_str"):StartCooldown(20)
		local remnants = FindUnitsInRadius(caster:GetTeamNumber(), Vector(0, 0, 0), nil, FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_INVULNERABLE, FIND_ANY_ORDER, false)
		for _, remnant in pairs(remnants) do
			if remnant:GetUnitName() == "npc_dota_storm_spirit_remnant" then
				remnant:RemoveSelf()
			end
		end
	elseif caster:GetUnitName() == "npc_dota_hero_earth_spirit" then
		hero = PlayerResource:ReplaceHeroWith( PlayerID, "npc_dota_hero_ember_spirit", gold, 0)
		local ability = hero:FindAbilityByName("holdout_spirit_agi"):StartCooldown(20)
	elseif caster:GetUnitName() == "npc_dota_hero_ember_spirit" then
		hero = PlayerResource:ReplaceHeroWith( PlayerID, "npc_dota_hero_storm_spirit", gold, 0)
		local ability = hero:FindAbilityByName("holdout_spirit_int"):StartCooldown(20)
	end

	for i = 0, 5 do 
	caster_ability = caster:GetAbilityByIndex(i)
	hero_ability = hero:GetAbilityByIndex(i)
		if IsValidEntity(caster_ability) then
			if i == 4 then -- Ignores Spirit Swap Ability
			else
				hero_ability:SetLevel(caster_ability:GetLevel())
			end
			cooldowns_caster[i] = caster_ability:GetCooldownTimeRemaining()
			hero_ability:StartCooldown(cooldowns_caster[i])
		end
	end

	local items = {}
	for i = 0, 8 do
		if caster:GetItemInSlot(i) ~= nil and caster:GetItemInSlot(i):GetName() ~= "item_classchange_reset" then
			itemCopy = CreateItem(caster:GetItemInSlot(i):GetName(), nil, nil)
			items[i] = itemCopy
		end
	end

	for i = 0, 8 do
		if items[i] ~= nil then
			hero:AddItem(items[i])
			items[i]:SetCurrentCharges(caster:GetItemInSlot(i):GetCurrentCharges())
		end
	end

	hero:AddExperience(CURRENT_XP, false, false)
	hero:SetAbsOrigin(loc)
	hero:SetBaseStrength(Strength)
	hero:SetBaseIntellect(Intellect)
	hero:SetBaseAgility(Agility)
	hero:SetHealth(HP)
	hero:SetMana(Mana)
	hero:SetAbilityPoints(AbPoints)

	Timers:CreateTimer(1.0, function()
		if not caster:IsNull() then
			UTIL_Remove(caster)
		end
	end)
end

function EnhancedSpirit(keys)
local caster = keys.caster
local ability = keys.ability

	if caster:GetUnitName() == "npc_dota_hero_storm_spirit" then
		caster:RemoveModifierByName("modifier_enhanced_spirit_earth")
		caster:RemoveModifierByName("modifier_enhanced_spirit_fire")
		ability:ApplyDataDrivenModifier(caster, caster, "modifier_enhanced_spirit_storm", {})
	elseif caster:GetUnitName() == "npc_dota_hero_earth_spirit" then
		caster:RemoveModifierByName("modifier_enhanced_spirit_storm")
		caster:RemoveModifierByName("modifier_enhanced_spirit_fire")
		ability:ApplyDataDrivenModifier(caster, caster, "modifier_enhanced_spirit_earth", {})
	elseif caster:GetUnitName() == "npc_dota_hero_ember_spirit" then
		caster:RemoveModifierByName("modifier_enhanced_spirit_storm")
		caster:RemoveModifierByName("modifier_enhanced_spirit_earth")
		ability:ApplyDataDrivenModifier(caster, caster, "modifier_enhanced_spirit_fire", {})
	end
end
