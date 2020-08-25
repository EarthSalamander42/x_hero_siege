function EnchantedAxes(keys)
local attacker = keys.caster
local target = keys.target
local ability = keys.ability
local radius = ability:GetSpecialValueFor("radius")
local splash = ability:GetSpecialValueFor("splash_pct")
local full_damage = attacker:GetRealDamageDone(attacker)
local splash_pct = splash * full_damage / 100
local splash_targets = FindUnitsInRadius(attacker:GetTeamNumber(), target:GetAbsOrigin(), nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)
local ability_level = ability:GetLevel() - 1
local multiplier = ability:GetLevelSpecialValueFor("damage_multiplier", ability_level) -1
local dmg_mult = full_damage * multiplier

	if attacker:GetAttackCapability() == DOTA_UNIT_CAP_MELEE_ATTACK then
		for _,unit in pairs(splash_targets) do
			if unit ~= target and not unit:IsBuilding() then
				ApplyDamage({victim = unit, attacker = attacker, damage = splash_pct, ability = ability, damage_type = DAMAGE_TYPE_PHYSICAL})
			end
		end
	elseif attacker:GetAttackCapability() == DOTA_UNIT_CAP_RANGED_ATTACK then
		if not target:IsBuilding() then
			ApplyDamage({victim = target, attacker = attacker, damage = dmg_mult, ability = ability, damage_type = DAMAGE_TYPE_PHYSICAL})
		end
	end
end

-------------------------------------------
--			  BESERKERS RAGE
-------------------------------------------
LinkLuaModifier("modifier_imba_berserkers_rage_ranged", "abilities/heroes/hero_troll_warlord", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_imba_berserkers_rage_melee", "abilities/heroes/hero_troll_warlord", LUA_MODIFIER_MOTION_NONE)

holdout_berserkers_rage_alt = holdout_berserkers_rage_alt or class({})
function holdout_berserkers_rage_alt:IsHiddenWhenStolen() return false end
function holdout_berserkers_rage_alt:IsRefreshable() return true end
function holdout_berserkers_rage_alt:IsStealable() return false end
function holdout_berserkers_rage_alt:IsNetherWardStealable() return false end
function holdout_berserkers_rage_alt:ResetToggleOnRespawn() return true end

function holdout_berserkers_rage_alt:GetAbilityTextureName()
   return "troll_warlord_berserkers_rage"
end
-------------------------------------------

-- Always have one of the buffs
function holdout_berserkers_rage_alt:OnUpgrade()
	if IsServer() then
		local caster = self:GetCaster()
		if not (caster:HasModifier("modifier_imba_berserkers_rage_ranged") or caster:HasModifier("modifier_imba_berserkers_rage_melee")) then
			if self:GetToggleState() then
				caster:AddNewModifier(caster, self, "modifier_imba_berserkers_rage_melee", {})
			else
				caster:AddNewModifier(caster, self, "modifier_imba_berserkers_rage_ranged", {})
			end
		end
	end
end

function holdout_berserkers_rage_alt:OnOwnerSpawned()
	if self.mode == 1 then
		self:ToggleAbility()
		self:ToggleAbility()
		self:ToggleAbility()
		-- Yeah, volvo.
	end
end

function holdout_berserkers_rage_alt:OnToggle()
	if IsServer() then
		local caster = self:GetCaster()
		caster:EmitSound("Hero_TrollWarlord.BerserkersRage.Toggle")
		-- Randomly play a cast line
		if RollPercentage(25) and (caster:GetName() == "npc_dota_hero_troll_warlord") and not caster.beserk_sound then
			caster:EmitSound("troll_warlord_troll_beserker_0"..math.random(1,4))
			caster.beserk_sound = true
			Timers:CreateTimer( 10, function()
				caster.beserk_sound = nil
			end)
		end
		caster:StartGesture(ACT_DOTA_CAST_ABILITY_1)
		if caster:HasModifier("modifier_imba_berserkers_rage_ranged") and self:GetToggleState() then
			caster:RemoveModifierByName("modifier_imba_berserkers_rage_ranged")
			caster:AddNewModifier(caster, self, "modifier_imba_berserkers_rage_melee", {})
		else
			caster:RemoveModifierByName("modifier_imba_berserkers_rage_melee")
			caster:AddNewModifier(caster, self, "modifier_imba_berserkers_rage_ranged", {})
		end
	end
end

function holdout_berserkers_rage_alt:GetAbilityTextureName()
	if self.mode == 1 then
		return "troll_warlord_berserkers_rage_active"
	else
		return "troll_warlord_berserkers_rage"
	end
end

-------------------------------------------
--			  BATTLE TRANCE
-------------------------------------------
LinkLuaModifier("modifier_battle_trance", "abilities/heroes/hero_troll_warlord", LUA_MODIFIER_MOTION_NONE)

holdout_battle_trance = holdout_battle_trance or class({})
function holdout_battle_trance:IsHiddenWhenStolen() return false end
function holdout_battle_trance:IsRefreshable() return true end
function holdout_battle_trance:IsStealable() return true end
function holdout_battle_trance:IsNetherWardStealable() return true end

function holdout_battle_trance:GetAbilityTextureName()
   return "troll_warlord_battle_trance"
end
-------------------------------------------

function holdout_battle_trance:OnSpellStart()
	if IsServer() then
		local caster = self:GetCaster()
		local duration = self:GetSpecialValueFor("buff_duration")
		local sound = "troll_warlord_troll_battletrance_0"..math.random(1,6)
		local allies = FindUnitsInRadius(caster:GetTeamNumber(), Vector(0,0,0), nil, 25000, self:GetAbilityTargetTeam(), self:GetAbilityTargetType(), self:GetAbilityTargetFlags(), FIND_ANY_ORDER, false)

		caster:EmitSound(sound)
		for _,ally in ipairs(allies) do
			local mod = ally:AddNewModifier(caster, self, "modifier_battle_trance", {duration = duration})
			mod.sound = sound
		end
		local cast_pfx = ParticleManager:CreateParticle( "particles/units/heroes/hero_troll_warlord/troll_warlord_battletrance_cast.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster )
		ParticleManager:SetParticleControlEnt( cast_pfx, 0, caster, PATTACH_POINT_FOLLOW, "attach_hitloc" , caster:GetOrigin(), true )
		ParticleManager:ReleaseParticleIndex(cast_pfx)
		caster:StartGesture(ACT_DOTA_CAST_ABILITY_4)
	end
end

-------------------------------------------
modifier_battle_trance = modifier_battle_trance or class({})
function modifier_battle_trance:IsDebuff() return false end
function modifier_battle_trance:IsHidden() return false end
function modifier_battle_trance:IsPurgable() return false end
function modifier_battle_trance:IsPurgeException() return false end
function modifier_battle_trance:IsStunDebuff() return false end
function modifier_battle_trance:RemoveOnDeath() return true end
-------------------------------------------

function modifier_battle_trance:DeclareFunctions()
	local decFuns =
	{
		MODIFIER_PROPERTY_BASE_ATTACK_TIME_CONSTANT
	}
	return decFuns
end

function modifier_battle_trance:OnCreated()
local ability = self:GetAbility()
local parent = self:GetParent()
local bonus_bat = ability:GetSpecialValueFor("bonus_bat")

	parent:GetAbilityByIndex(5):SetActivated(false)
	if parent:IsRealHero() and IsServer() then
		EmitSoundOnClient("Hero_TrollWarlord.BattleTrance.Cast.Team", parent:GetPlayerOwner())
	end
	if parent:GetBaseAttackTime() <= bonus_bat then
		self.bonus_bat = bonus_bat
	else
		self.bonus_bat = 0
	end
end

function modifier_battle_trance:OnRefresh()
	self:OnCreated()
end

function modifier_battle_trance:OnDestroy()
	if IsServer() then
		local parent = self:GetParent()
		parent:GetAbilityByIndex(5):SetActivated(true)
		if not parent:HasAbility("imba_troll_warlord_fervor") and parent:HasModifier("modifier_imba_fervor_stacks") then
			parent:RemoveModifierByName("modifier_imba_fervor_stacks")
		end
	end
end

function modifier_battle_trance:GetPriority()
	return 10
end

function modifier_battle_trance:GetModifierBaseAttackTimeConstant()
	return self.bonus_bat
end

function modifier_battle_trance:GetEffectName()
	return "particles/units/heroes/hero_troll_warlord/troll_warlord_battletrance_buff.vpcf"
end

function modifier_battle_trance:GetEffectAttachType()
	return PATTACH_POINT_FOLLOW
end
