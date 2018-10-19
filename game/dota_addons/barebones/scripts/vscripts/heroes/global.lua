function Reincarnation(event)
local hero = event.caster
local ability = hero:FindAbilityByName("holdout_reincarnation") -- Ability
local ankh = "item_ankh_of_reincarnation"
local doom = "item_doom_artifact"
local shield = "item_shield_of_invincibility"
local position = hero:GetAbsOrigin()
local RespawnTime = 5.0
if hero:GetUnitName() == "npc_spirit_beast" then return end
if hero:IsIllusion() then return end

	if hero.ankh_respawn == false then
		if ability and ability:IsCooldownReady() then
			if hero:IsRealHero() then
				hero.ankh_respawn = true
				hero:SetRespawnsDisabled(true)
				hero.respawn_timer = Timers:CreateTimer(RespawnTime, function() 
					hero:SetRespawnPosition(position)
					hero:EmitSound("Ability.ReincarnationAlt")
					hero:RespawnHero(false, false)
					ParticleManager:CreateParticle("particles/items_fx/aegis_respawn.vpcf", PATTACH_ABSORIGIN_FOLLOW, hero)
					hero:SetRespawnsDisabled(false)
					Timers:CreateTimer(0.1, function()
						hero.ankh_respawn = false
					end)
				end)
				ability:StartCooldown(60.0)
			else -- Only Beastmaster's Bear atm
				hero.ankh_respawn = true
				hero.respawn_timer = Timers:CreateTimer(RespawnTime, function() 
					hero:EmitSound("Ability.ReincarnationAlt")
					hero:RespawnUnit()
					ParticleManager:CreateParticle("particles/items_fx/aegis_respawn.vpcf", PATTACH_ABSORIGIN_FOLLOW, hero)
					Timers:CreateTimer(0.1, function()
						hero.ankh_respawn = false
					end)
				end)
				ability:StartCooldown(60.0)
				if hero:GetOwner():FindAbilityByName("lone_druid_spirit_bear"):IsCooldownReady() then
					hero:GetOwner():FindAbilityByName("lone_druid_spirit_bear"):StartCooldown(5.0)
				end
			end
		return
		elseif hero:HasItemInInventory(ankh) then
			print("Ankh")
			if hero:IsRealHero() then
				hero.ankh_respawn = true
				hero:SetRespawnsDisabled(true)
				hero.respawn_timer = Timers:CreateTimer(RespawnTime, function() 
					hero:SetRespawnPosition(position)
					hero:EmitSound("Ability.ReincarnationAlt")
					hero:RespawnHero(false, false)
					ParticleManager:CreateParticle("particles/items_fx/aegis_respawn.vpcf", PATTACH_ABSORIGIN_FOLLOW, hero)
					hero:SetRespawnsDisabled(false)
					Timers:CreateTimer(0.1, function()
						hero.ankh_respawn = false
					end)
				end)
				for itemSlot = 0, 5 do
				local item = hero:GetItemInSlot(itemSlot)
					if item and item:GetName() == ankh then
						if item:GetCurrentCharges() -1 >= 1 then
							item:SetCurrentCharges(item:GetCurrentCharges() -1)
						else
							item:RemoveSelf()
						end
					end
				end
			else
				hero.ankh_respawn = true
				hero.respawn_timer = Timers:CreateTimer(RespawnTime, function() 
					hero:EmitSound("Ability.ReincarnationAlt")
					hero:RespawnUnit()
					ParticleManager:CreateParticle("particles/items_fx/aegis_respawn.vpcf", PATTACH_ABSORIGIN_FOLLOW, hero)
					Timers:CreateTimer(0.1, function()
						hero.ankh_respawn = false
					end)
				end)
				for itemSlot = 0, 5 do
				local item = hero:GetItemInSlot(itemSlot)
					if item and item:GetName() == ankh then
						if item:GetCurrentCharges() -1 >= 1 then
							item:SetCurrentCharges(item:GetCurrentCharges() -1)
						else
							item:RemoveSelf()
						end
					end
				end
				if hero:GetOwner():FindAbilityByName("lone_druid_spirit_bear"):IsCooldownReady() then
					hero:GetOwner():FindAbilityByName("lone_druid_spirit_bear"):StartCooldown(5.0)
				end
			end
		return
		elseif hero:HasItemInInventory(shield) or hero:HasItemInInventory(doom) then
			print("Shield")
			for itemSlot = 0, 5 do
				local item = hero:GetItemInSlot(itemSlot)
				if item == nil then return end
				if item:GetName() == shield or item:GetName() == doom then
					if item:IsCooldownReady() then
						if hero:IsRealHero() then
							hero.ankh_respawn = true
							hero:SetRespawnsDisabled(true)
							hero.respawn_timer = Timers:CreateTimer(RespawnTime, function() 
								hero:SetRespawnPosition(position)
								hero:EmitSound("Ability.ReincarnationAlt")
								hero:RespawnHero(false, false)
								ParticleManager:CreateParticle("particles/items_fx/aegis_respawn.vpcf", PATTACH_ABSORIGIN_FOLLOW, hero)
								hero:SetRespawnsDisabled(false)
								Timers:CreateTimer(0.1, function()
									hero.ankh_respawn = false
								end)
							end)
							item:StartCooldown(60.0)
						else
							hero.ankh_respawn = true
							hero.respawn_timer = Timers:CreateTimer(RespawnTime, function() 
								hero:EmitSound("Ability.ReincarnationAlt")
								hero:RespawnUnit()
								ParticleManager:CreateParticle("particles/items_fx/aegis_respawn.vpcf", PATTACH_ABSORIGIN_FOLLOW, hero)
								Timers:CreateTimer(0.1, function()
									hero.ankh_respawn = false
								end)
							end)
							item:StartCooldown(60.0)
							if hero:GetOwner():FindAbilityByName("lone_druid_spirit_bear"):IsCooldownReady() then
								hero:GetOwner():FindAbilityByName("lone_druid_spirit_bear"):StartCooldown(5.0)
							end
						end
					end
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

	if not ability then return end

	if caster:GetHealthPercent() <= Health then
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

		PauseCreepsCastle()
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
local full_damage = attacker:GetAverageTrueAttackDamage(attacker)
local cleave_pct = cleave * full_damage / 100

	local splash_targets = FindUnitsInRadius(attacker:GetTeamNumber(), target:GetAbsOrigin(), nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)
	for _, unit in pairs(splash_targets) do
		if target:IsBuilding() then return end
		if unit ~= target and not unit:IsBuilding() then
			local target_armor = unit:GetPhysicalArmorValue()
			local damage = cleave_pct * GetReductionFromArmor(target_armor) * 0.01
			if attacker:GetAttackCapability() == DOTA_UNIT_CAP_MELEE_ATTACK then
--				print("Damage:", damage)
				ApplyDamage({victim = unit, attacker = attacker, damage = damage/2, ability = ability, damage_type = DAMAGE_TYPE_PURE})
			end
		end
	end
end

function SplashAbility(event)
local attacker = event.caster
local target = event.target
local ability = event.ability
local radius = ability:GetSpecialValueFor("radius")
local cleave = ability:GetSpecialValueFor("cleave_pct")
local full_damage = attacker:GetAverageTrueAttackDamage(attacker)
local cleave_pct = cleave * full_damage / 100

	local splash_targets = FindUnitsInRadius(attacker:GetTeamNumber(), target:GetAbsOrigin(), nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)
	for _, unit in pairs(splash_targets) do
		if target:IsBuilding() then return end
		if unit ~= target and not unit:IsBuilding() then
			local target_armor = unit:GetPhysicalArmorValue()
			local damage = cleave_pct * GetReductionFromArmor(target_armor) * 0.01
--			print("Damage:", damage)
			ApplyDamage({victim = unit, attacker = attacker, damage = damage/2, ability = ability, damage_type = DAMAGE_TYPE_PURE})
		end
	end
end

function OrbOfDarkness(event)
local unit = event.caster
local caster = unit:GetPlayerOwner():GetAssignedHero()

	caster:SetModifierStackCount("modifier_orb_of_darkness", caster, caster:GetModifierStackCount("modifier_orb_of_darkness", caster) -1)
end

function EndChannel(keys)
	EndAnimation(keys.caster)
end


campfire = class({})

LinkLuaModifier( "modifier_campfire", "heroes/global", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_campfire_effect", "heroes/global", LUA_MODIFIER_MOTION_NONE )

function campfire:GetIntrinsicModifierName()
	return "modifier_campfire"
end


modifier_campfire = class({})

function modifier_campfire:IsHidden()
	return true
end

function modifier_campfire:IsPurgable()
	return false
end

function modifier_campfire:IsAura()
	return true
end

function modifier_campfire:GetModifierAura()
	return  "modifier_campfire_effect"
end

function modifier_campfire:GetAuraSearchTeam()
	return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_campfire:GetAuraSearchType()
	return DOTA_UNIT_TARGET_ALL
end

function modifier_campfire:GetAuraRadius()
	return self.aura_radius
end

function modifier_campfire:OnCreated( kv )
	if IsServer() then
		self.aura_radius = self:GetAbility():GetSpecialValueFor( "aura_radius" )

--		self:GetParent():AddNewModifier( nil, nil, "modifier_disable_aggro", { duration = -1 } )
		self:GetParent():AddNewModifier( nil, nil, "modifier_provides_fow_position", { duration = -1 } )

		EmitSoundOn( "Campfire.Warmth.Loop", self:GetParent() )

		self:StartIntervalThink( 0.25 )
	end
end

function modifier_campfire:CheckState()
	local state = {}
	if IsServer()  then
		state[MODIFIER_STATE_ROOTED] = true
		state[MODIFIER_STATE_NO_HEALTH_BAR] = true
		state[MODIFIER_STATE_NOT_ON_MINIMAP] = true
		state[MODIFIER_STATE_BLIND] = true
		state[MODIFIER_STATE_INVULNERABLE] = true
		state[MODIFIER_STATE_OUT_OF_GAME] = true
	end

	return state
end

function modifier_campfire:OnIntervalThink()
	if IsServer() then
		if ( not self.nFXIndex ) then
			local vCasterPos = self:GetCaster():GetOrigin()
			local vOffset = Vector( 0, 0, 50 )

			self.nFXIndex = ParticleManager:CreateParticle( "particles/act_2/campfire_flame.vpcf", PATTACH_ABSORIGIN, self:GetCaster() )
			ParticleManager:SetParticleControl( self.nFXIndex, 2, vCasterPos + vOffset )
		end
	end
end

function modifier_campfire:OnDestroy()
	if IsServer() then
		StopSoundOn( "Campfire.Warmth.Loop", self:GetParent() )
	end
end

modifier_campfire_effect = class({})

function modifier_campfire_effect:GetEffectName()
	return "particles/camp_fire_buff.vpcf"
end

function modifier_campfire_effect:OnCreated( kv )

end

function modifier_campfire_effect:DeclareFunctions()
	local funcs = 
	{
		MODIFIER_PROPERTY_HEALTH_REGEN_PERCENTAGE,
		MODIFIER_PROPERTY_MANA_REGEN_TOTAL_PERCENTAGE
	}
	return funcs
end

function modifier_campfire_effect:GetModifierHealthRegenPercentage( params )
	return self:GetAbility():GetSpecialValueFor( "aura_hp_regen" )
end

function modifier_campfire_effect:GetModifierTotalPercentageManaRegen( params )
	return self:GetAbility():GetSpecialValueFor( "aura_mana_regen" )
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
