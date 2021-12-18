-- Editors:
--     EarthSalamander #42, 02.04.2017

--------------------------
--	Entrangling Roots	--
--------------------------

if IsServer() then
	require("abilities/heroes/global")
end

LinkLuaModifier("modifier_entrangling_roots", "abilities/heroes/hero_malfurion", LUA_MODIFIER_MOTION_NONE)

holdout_entrangling_roots = holdout_entrangling_roots or class({})

function holdout_entrangling_roots:OnSpellStart()
	if IsServer() then
		self:GetCursorTarget():EmitSound("Hero_Treant.LeechSeed.Target")
		self:GetCursorTarget():AddNewModifier(self:GetCursorTarget(), self, "modifier_entrangling_roots", {duration=self:GetSpecialValueFor("duration") - 0.01}) -- minus 0.01 second/instance to keep the right root duration but have 1 less damage instance, because first damage instance happen when modifier is granted and not after the first think time.
	end
end

modifier_entrangling_roots = modifier_entrangling_roots or class({})

function modifier_entrangling_roots:IsDebuff() return false end
function modifier_entrangling_roots:IsHidden() return false end

-------------------------------------------

function modifier_entrangling_roots:GetEffectName()
	return "particles/units/heroes/hero_treant/treant_overgrowth_vines.vpcf"
end

function modifier_entrangling_roots:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_entrangling_roots:CheckState()
	local states =
	{
		[MODIFIER_STATE_DISARMED] = true,
		[MODIFIER_STATE_ROOTED] = true,
	}

	return states
end

function modifier_entrangling_roots:OnCreated()
	if IsServer() then
		self:OnIntervalThink()
		self:StartIntervalThink(1.0)
	end
end

function modifier_entrangling_roots:OnIntervalThink()
	ApplyDamage({
		victim = self:GetParent(),
		attacker = self:GetAbility():GetCaster(),
		damage = self:GetAbility():GetSpecialValueFor("dmg_per_sec"),
		damage_type = self:GetAbility():GetAbilityDamageType()
	})
end

------------------------------
--		Rejuvenation		--
------------------------------

LinkLuaModifier("modifier_rejuvenation", "abilities/heroes/hero_malfurion", LUA_MODIFIER_MOTION_NONE)

holdout_rejuvenation_alt = holdout_rejuvenation_alt or class({})

function holdout_rejuvenation_alt:OnAbilityPhaseStart()
	if not IsServer() then return end

	self:GetCaster():StartGesture(ACT_DOTA_OVERRIDE_ABILITY_2)

	return true
end

function holdout_rejuvenation_alt:OnAbilityPhaseInterrupted()
	if not IsServer() then return end

	self:GetCaster():FadeGesture(ACT_DOTA_OVERRIDE_ABILITY_2)
end

function holdout_rejuvenation_alt:OnSpellStart()
	if IsServer() then
		self:GetCaster():EmitSound("Hero_Warlock.ShadowWordCastGood")

		local allies = FindUnitsInRadius(self:GetCaster():GetTeam(), self:GetCaster():GetAbsOrigin(), nil, self:GetSpecialValueFor("radius"), self:GetAbilityTargetTeam(), self:GetAbilityTargetType(), self:GetAbilityTargetFlags(), FIND_ANY_ORDER, false)
		for _, ally in pairs (allies) do
			ally:AddNewModifier(self:GetCaster(), self, "modifier_rejuvenation", {duration=self:GetSpecialValueFor("duration")})
		end
	end
end

modifier_rejuvenation = modifier_rejuvenation or class({})

function modifier_rejuvenation:OnCreated()
	if IsServer() then
		self.heal_per_sec = self:GetAbility():GetSpecialValueFor("heal_per_sec")
		self:StartIntervalThink(1.0)
	end
end

function modifier_rejuvenation:OnIntervalThink()
	local heal_value = self.heal_per_sec

	if self:GetParent():IsBuilding() or string.find(self:GetParent():GetUnitName(), "living_tower") then
		heal_value = self.heal_per_sec / 100 * self:GetAbility():GetSpecialValueFor("heal_per_sec_building_pct")
	else
		if not self:GetParent():IsHero() then
			heal_value = self.heal_per_sec / 100 * self:GetAbility():GetSpecialValueFor("heal_per_sec_creep_pct")
		end
	end

	self:GetParent():Heal(heal_value, self:GetCaster())
	SendOverheadEventMessage(nil, OVERHEAD_ALERT_HEAL, self:GetParent(), heal_value, nil)
end

function modifier_rejuvenation:GetEffectName()
	return "particles/econ/events/ti6/bottle_ti6.vpcf"
end

function modifier_rejuvenation:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

-----------------------------
--     Mark of the Claw    --
-----------------------------

LinkLuaModifier("modifier_mark_of_the_claw", "abilities/heroes/hero_malfurion", LUA_MODIFIER_MOTION_NONE)

holdout_mark_of_the_claw = holdout_mark_of_the_claw or class({})

function holdout_mark_of_the_claw:GetIntrinsicModifierName()
	return "modifier_mark_of_the_claw"
end

modifier_mark_of_the_claw = modifier_mark_of_the_claw or class({})

function modifier_mark_of_the_claw:IsHidden() return true end

function modifier_mark_of_the_claw:DeclareFunctions()
	local funcs = {
		MODIFIER_EVENT_ON_ATTACK_LANDED,
	}

	return funcs
end

function modifier_mark_of_the_claw:OnAttackLanded(kv)
	if IsServer() then
		if self:GetParent() == kv.attacker and kv.attacker:GetTeamNumber() ~= kv.target:GetTeamNumber() then
			if kv.target:IsBuilding() then return end

			if RandomInt(1, 100) <= self:GetAbility():GetSpecialValueFor("chance") then
				local base_damage = kv.damage * (self:GetAbility():GetSpecialValueFor("bonus_damage_pct") / 100)
				local splash_damage = base_damage * (self:GetAbility():GetSpecialValueFor("splash_damage_pct") / 100)

				ApplyDamage({
					victim = kv.target,
					attacker = kv.attacker,
					damage = base_damage,
					damage_type = DAMAGE_TYPE_PHYSICAL
				})

				kv.attacker:EmitSound("Imba.UrsaDeepStrike")

				local coup_pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_phantom_assassin/phantom_assassin_crit_impact.vpcf", PATTACH_CUSTOMORIGIN, kv.attacker)
				ParticleManager:SetParticleControlEnt(coup_pfx, 0, kv.target, PATTACH_POINT_FOLLOW, "attach_hitloc", kv.target:GetAbsOrigin(), true)
				ParticleManager:SetParticleControlEnt(coup_pfx, 1, kv.target, PATTACH_ABSORIGIN_FOLLOW, "attach_origin", kv.target:GetAbsOrigin(), true)
				ParticleManager:ReleaseParticleIndex(coup_pfx)

				DoCleaveAttack(
					kv.attacker,
					kv.target,
					self:GetAbility(),
					splash_damage,
					self:GetAbility():GetSpecialValueFor("cleave_start"),
					self:GetAbility():GetSpecialValueFor("cleave_end"),
					self:GetAbility():GetSpecialValueFor("radius"),
					"particles/econ/items/sven/sven_ti7_sword/sven_ti7_sword_spell_great_cleave_gods_strength.vpcf"
				)
			end
		end
	end
end

-----------------------------
--  Strength of the Wild   --
-----------------------------

LinkLuaModifier("modifier_strength_of_the_wild", "abilities/heroes/hero_malfurion", LUA_MODIFIER_MOTION_NONE)

holdout_strength_of_the_wild = holdout_strength_of_the_wild or class({})

function holdout_strength_of_the_wild:IsInnateAbility() return true end

function holdout_strength_of_the_wild:GetIntrinsicModifierName()
	return "modifier_strength_of_the_wild"
end

modifier_strength_of_the_wild = modifier_strength_of_the_wild or class({})

function holdout_strength_of_the_wild:IsHidden() return true end

function modifier_strength_of_the_wild:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE  
	}
	return funcs
end

function modifier_strength_of_the_wild:GetModifierDamageOutgoing_Percentage(keys)
	if keys.target and not keys.target:IsRealHero() and not self:GetParent():PassivesDisabled() then
		return self:GetAbility():GetSpecialValueFor("bonus_damage_percentage")
	end
end

---------------------
--  Living Tower   --
---------------------

LinkLuaModifier("modifier_imba_malfurion_living_tower", "abilities/heroes/hero_malfurion", LUA_MODIFIER_MOTION_NONE)

imba_malfurion_living_tower = imba_malfurion_living_tower or class({})

function imba_malfurion_living_tower:OnAbilityPhaseStart()
	if not IsServer() then return end

	self:GetCaster():StartGesture(ACT_DOTA_CAST_ABILITY_4)

	return true
end

function imba_malfurion_living_tower:OnAbilityPhaseInterrupted()
	if not IsServer() then return end

	self:GetCaster():FadeGesture(ACT_DOTA_CAST_ABILITY_4)
end

function imba_malfurion_living_tower:OnSpellStart()
	if IsServer() then
		local tower_name = {}
		tower_name[2] = "radiant"
		tower_name[3] = "dire"
		self.living_tower = CreateUnitByName("npc_imba_malfurion_living_tower_"..tower_name[self:GetCaster():GetTeamNumber()], self:GetCursorPosition(), true, self:GetCaster(), self:GetCaster(), self:GetCaster():GetTeam())
		self.living_tower:AddNewModifier(self.living_tower, self, "modifier_kill", {duration=self:GetSpecialValueFor("duration")})
		self.living_tower:AddNewModifier(self.living_tower, self, "modifier_imba_malfurion_living_tower", {})
		self.living_tower:SetControllableByPlayer(self:GetCaster():GetPlayerID(), false)
		self.living_tower:SetMaxHealth(self:GetSpecialValueFor("health"))
		self.living_tower:SetHealth(self:GetSpecialValueFor("health"))
		self.living_tower:SetBaseMaxHealth(self:GetSpecialValueFor("health"))
		self.living_tower:SetBaseDamageMin(self:GetSpecialValueFor("damage") * 0.9)
		self.living_tower:SetBaseDamageMax(self:GetSpecialValueFor("damage") * 1.1)
		self.living_tower:SetAcquisitionRange(self:GetSpecialValueFor("attack_range"))
		self.living_tower:SetDeathXP(self:GetSpecialValueFor("xp_bounty"))
		self.living_tower:SetMinimumGoldBounty(self:GetSpecialValueFor("gold_bounty"))
		self.living_tower:SetMaximumGoldBounty(self:GetSpecialValueFor("gold_bounty"))
		self.living_tower:EmitSound("Hero_Treant.Overgrowth.Cast")
	end
end

modifier_imba_malfurion_living_tower = modifier_imba_malfurion_living_tower or class({})

function modifier_imba_malfurion_living_tower:IsHidden() return true end
function modifier_imba_malfurion_living_tower:RemoveOnDeath() return false end

function modifier_imba_malfurion_living_tower:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_ATTACK_RANGE_BONUS,
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
		MODIFIER_EVENT_ON_ATTACK_LANDED,
		MODIFIER_EVENT_ON_ATTACK_START,
		MODIFIER_PROPERTY_OVERRIDE_ANIMATION,
		MODIFIER_EVENT_ON_DEATH,
	}
	return funcs
end

function modifier_imba_malfurion_living_tower:GetEffectName()
	if self:GetStackCount() == 2 then
		return "particles/econ/world/towers/rock_golem/radiant_rock_golem_ambient.vpcf"
	elseif self:GetStackCount() == 3 then
		return "particles/econ/world/towers/rock_golem/dire_rock_golem_ambient.vpcf"
	end
end

function modifier_imba_malfurion_living_tower:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_imba_malfurion_living_tower:GetOverrideAnimation()
	return ACT_DOTA_CUSTOM_TOWER_IDLE
end

function modifier_imba_malfurion_living_tower:OnCreated()
	if not IsServer() then return end

	local pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_treant/treant_overgrowth_vines.vpcf", PATTACH_ABSORIGIN, self:GetParent())
	ParticleManager:ReleaseParticleIndex(pfx)

	self:SetStackCount(self:GetCaster():GetTeamNumber())
end

function modifier_imba_malfurion_living_tower:OnAttackStart(keys)
	if not IsServer() then return end

	if keys.attacker == self:GetParent() then
		self:GetParent():EmitSound("Tree.GrowBack")
		self:GetParent():StartGestureWithPlaybackRate(ACT_DOTA_CUSTOM_TOWER_ATTACK, self:GetParent():GetAttacksPerSecond())
	end
end

function modifier_imba_malfurion_living_tower:OnAttackLanded(keys)
	if not IsServer() then return end

	if keys.attacker == self:GetParent() then
		local event = {}
		event.caster = keys.attacker
		event.target = keys.target
		event.ability = self:GetAbility()
		Splash(event)
	end
end

function modifier_imba_malfurion_living_tower:OnDeath(keys)
	if not IsServer() then return end

	if keys.unit == self:GetParent() then
		self:GetParent():StartGestureWithPlaybackRate(ACT_DOTA_CUSTOM_TOWER_DIE, 0.75)
	end
end

function modifier_imba_malfurion_living_tower:GetModifierAttackSpeedBonus_Constant()
	return self:GetAbility():GetSpecialValueFor("attack_speed")
end

function modifier_imba_malfurion_living_tower:GetModifierAttackRangeBonus()
	return self:GetAbility():GetSpecialValueFor("attack_range")
end
