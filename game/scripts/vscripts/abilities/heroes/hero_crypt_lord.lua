require("libraries/timers")

LinkLuaModifier("modifier_xhs_crypt_lord_impale_airborne", "abilities/heroes/hero_crypt_lord.lua", LUA_MODIFIER_MOTION_VERTICAL)
LinkLuaModifier("modifier_xhs_crypt_lord_infested", "abilities/heroes/hero_crypt_lord.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_xhs_carrion_beetle", "abilities/heroes/hero_crypt_lord.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_xhs_carrion_plague_handler", "abilities/heroes/hero_crypt_lord.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_xhs_carrion_plague", "abilities/heroes/hero_crypt_lord.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_xhs_spiked_carapace_passive", "abilities/heroes/hero_crypt_lord.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_xhs_spiked_carapace_active", "abilities/heroes/hero_crypt_lord.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_xhs_frenzy_of_the_hive", "abilities/heroes/hero_crypt_lord.lua", LUA_MODIFIER_MOTION_NONE)

local function IsValidCryptLordUnit(unit)
	return unit ~= nil and not unit:IsNull() and unit:IsAlive()
end

local function IsCryptLordBoss(unit)
	if unit == nil or unit:IsNull() then return false end
	if XHSIsBossDamageTarget ~= nil then return XHSIsBossDamageTarget(unit) end
	return unit:IsConsideredHero() and not unit:IsRealHero()
end

local function GetCryptLordBeetles(caster)
	local result = {}
	for _, beetle in pairs(caster.wolves or {}) do
		if IsValidCryptLordUnit(beetle) and beetle:HasModifier("modifier_xhs_carrion_beetle") then
			table.insert(result, beetle)
		end
	end
	return result
end

local function HealCryptLordHive(caster, ability, amount)
	if amount <= 0 or not IsValidCryptLordUnit(caster) then return end
	caster:Heal(math.min(amount, caster:GetMaxHealth() - caster:GetHealth()), ability)
	for _, beetle in pairs(GetCryptLordBeetles(caster)) do
		beetle:Heal(math.min(amount, beetle:GetMaxHealth() - beetle:GetHealth()), ability)
	end
end

local function ApplyCarrionPlague(caster, target)
	if not IsValidCryptLordUnit(caster) or not IsValidCryptLordUnit(target) then return end
	if caster:GetTeamNumber() == target:GetTeamNumber() or target:IsBuilding() or target:IsOther() then return end
	local ability = caster:FindAbilityByName("holdout_poison_sting")
	if ability == nil or ability:GetLevel() <= 0 then return end
	target:AddNewModifier(caster, ability, "modifier_xhs_carrion_plague", {
		duration = ability:GetSpecialValueFor("duration"),
	})
end

-- Impale is always cast manually. Its autocast toggle only controls beetle focus.
nyx_assassin_impale = nyx_assassin_impale or class({})

function nyx_assassin_impale:GetAOERadius()
	return self:GetSpecialValueFor("width")
end

function nyx_assassin_impale:OnSpellStart()
	if not IsServer() then return end
	local caster = self:GetCaster()
	local origin = caster:GetAbsOrigin()
	local direction = self:GetCursorPosition() - origin
	direction.z = 0
	direction = direction:Length2D() < 1 and caster:GetForwardVector() or direction:Normalized()

	caster:EmitSound("Hero_NyxAssassin.Impale")
	ProjectileManager:CreateLinearProjectile({
		Ability = self,
		EffectName = "particles/units/heroes/hero_nyx_assassin/nyx_assassin_impale.vpcf",
		vSpawnOrigin = origin,
		fDistance = self:GetSpecialValueFor("length"),
		fStartRadius = self:GetSpecialValueFor("width"),
		fEndRadius = self:GetSpecialValueFor("width"),
		Source = caster,
		bHasFrontalCone = false,
		bReplaceExisting = false,
		iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
		iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
		iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		fExpireTime = GameRules:GetGameTime() + 2,
		bDeleteOnHit = false,
		vVelocity = direction * self:GetSpecialValueFor("speed"),
		bProvidesVision = false,
	})
end

function nyx_assassin_impale:OnProjectileHit(target, location)
	if not IsServer() or target == nil or target:IsNull() then return false end
	local caster = self:GetCaster()
	ApplyDamage({
		victim = target,
		attacker = caster,
		ability = self,
		damage = self:GetSpecialValueFor("impale_damage"),
		damage_type = DAMAGE_TYPE_MAGICAL,
	})
	target:AddNewModifier(caster, self, "modifier_stunned", { duration = self:GetSpecialValueFor("duration") })
	target:AddNewModifier(caster, self, "modifier_xhs_crypt_lord_impale_airborne", {
		duration = 0.5,
		height = 350,
	})
	target:AddNewModifier(caster, self, "modifier_xhs_crypt_lord_infested", {
		duration = self:GetSpecialValueFor("infested_duration"),
	})
	local impact = ParticleManager:CreateParticle(
		"particles/units/heroes/hero_nyx_assassin/nyx_assassin_impale.vpcf",
		PATTACH_CUSTOMORIGIN,
		nil
	)
	ParticleManager:SetParticleControl(impact, 0, location or target:GetAbsOrigin())
	Timers:CreateTimer(0.5, function()
		ParticleManager:DestroyParticle(impact, false)
		ParticleManager:ReleaseParticleIndex(impact)
	end)
	target:EmitSound("Hero_NyxAssassin.Impale.Target")
	return false
end

modifier_xhs_crypt_lord_impale_airborne = modifier_xhs_crypt_lord_impale_airborne or class({})
modifier_xhs_crypt_lord_impale_airborne.XHS_LINK_CLIENT = true
function modifier_xhs_crypt_lord_impale_airborne:IsHidden() return true end
function modifier_xhs_crypt_lord_impale_airborne:IsPurgable() return false end
function modifier_xhs_crypt_lord_impale_airborne:OnCreated(keys)
	if not IsServer() then return end

	self.air_duration = math.max(0.03, tonumber(keys.duration) or 0.5)
	self.height = math.max(0, tonumber(keys.height) or 350)
	self.elapsed = 0
	local origin = self:GetParent():GetAbsOrigin()
	self.ground_height = GetGroundHeight(origin, self:GetParent())
	if not self:ApplyVerticalMotionController() then
		self:Destroy()
	end
end
function modifier_xhs_crypt_lord_impale_airborne:OnDestroy()
	if not IsServer() then return end

	local parent = self:GetParent()
	if parent == nil or parent:IsNull() then return end
	parent:RemoveVerticalMotionController(self)
	parent:SetUnitOnClearGround()
end
function modifier_xhs_crypt_lord_impale_airborne:DeclareFunctions()
	return { MODIFIER_PROPERTY_OVERRIDE_ANIMATION }
end
function modifier_xhs_crypt_lord_impale_airborne:GetOverrideAnimation() return ACT_DOTA_FLAIL end
function modifier_xhs_crypt_lord_impale_airborne:CheckState()
	return { [MODIFIER_STATE_NO_UNIT_COLLISION] = true }
end
function modifier_xhs_crypt_lord_impale_airborne:UpdateVerticalMotion(parent, delta)
	self.elapsed = math.min(self.air_duration, self.elapsed + delta)
	local progress = self.elapsed / self.air_duration
	local position = parent:GetAbsOrigin()
	position.z = self.ground_height + (4 * self.height * progress * (1 - progress))
	parent:SetAbsOrigin(position)
	if self.elapsed >= self.air_duration then
		self:Destroy()
	end
end
function modifier_xhs_crypt_lord_impale_airborne:OnVerticalMotionInterrupted()
	if IsServer() then self:Destroy() end
end

modifier_xhs_crypt_lord_infested = modifier_xhs_crypt_lord_infested or class({})
modifier_xhs_crypt_lord_infested.XHS_LINK_CLIENT = true
function modifier_xhs_crypt_lord_infested:IsHidden() return false end
function modifier_xhs_crypt_lord_infested:IsDebuff() return true end
function modifier_xhs_crypt_lord_infested:IsPurgable() return true end
function modifier_xhs_crypt_lord_infested:GetTexture() return "nyx_assassin_impale" end
function modifier_xhs_crypt_lord_infested:GetEffectName()
	return "particles/units/heroes/hero_weaver/weaver_swarm_debuff.vpcf"
end
function modifier_xhs_crypt_lord_infested:GetEffectAttachType() return PATTACH_ABSORIGIN_FOLLOW end

-- Carrion Beetles: preserve the current count and replacement loop, but scale the renewed beetle.
function InitializeCarrionBeetle(keys)
	if not IsServer() then return end
	local caster = keys.caster
	local beetle = keys.target
	local ability = keys.ability
	if not IsValidCryptLordUnit(caster) or not IsValidCryptLordUnit(beetle) or ability == nil then return end
	beetle:SetOwner(caster)
	if caster:GetPlayerOwnerID() >= 0 then beetle:SetControllableByPlayer(caster:GetPlayerOwnerID(), true) end
	beetle:AddNewModifier(caster, ability, "modifier_xhs_carrion_beetle", {
		duration = ability:GetSpecialValueFor("wolf_duration"),
	})
	local frenzy = caster:FindModifierByName("modifier_xhs_frenzy_of_the_hive")
	local claw = caster:FindAbilityByName("holdout_anubarak_claw")
	if frenzy ~= nil and claw ~= nil then
		beetle:AddNewModifier(caster, claw, "modifier_xhs_frenzy_of_the_hive", {
			duration = frenzy:GetRemainingTime(),
			hive_member = 1,
		})
	end
end

modifier_xhs_carrion_beetle = modifier_xhs_carrion_beetle or class({})
modifier_xhs_carrion_beetle.XHS_LINK_CLIENT = true
function modifier_xhs_carrion_beetle:IsHidden() return true end
function modifier_xhs_carrion_beetle:IsPurgable() return false end
function modifier_xhs_carrion_beetle:OnCreated()
	if IsServer() then self:StartIntervalThink(0.4) end
end
function modifier_xhs_carrion_beetle:DeclareFunctions()
	return { MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE, MODIFIER_EVENT_ON_ATTACK_LANDED }
end
function modifier_xhs_carrion_beetle:GetModifierPreAttack_BonusDamage()
	local caster = self:GetCaster()
	local ability = self:GetAbility()
	if caster == nil or caster:IsNull() or ability == nil then return 0 end
	return caster:GetStrength() * ability:GetSpecialValueFor("strength_damage_pct") * 0.01
		+ caster:GetAttackDamage() * ability:GetSpecialValueFor("hero_attack_damage_pct") * 0.01
end
function modifier_xhs_carrion_beetle:OnAttackLanded(keys)
	if not IsServer() or keys.attacker ~= self:GetParent() or not IsValidCryptLordUnit(keys.target) then return end
	ApplyCarrionPlague(self:GetCaster(), keys.target)
	if keys.target:HasModifier("modifier_xhs_crypt_lord_infested") then
		local attack_damage = tonumber(keys.original_damage) or tonumber(keys.damage) or 0
		if attack_damage <= 0 then
			attack_damage = keys.attacker:GetAverageTrueAttackDamage(keys.target)
		end
		ApplyDamage({
			victim = keys.target,
			attacker = self:GetCaster(),
			ability = self:GetAbility(),
			damage = attack_damage * self:GetAbility():GetSpecialValueFor("infested_bonus_pct") * 0.01,
			damage_type = DAMAGE_TYPE_PHYSICAL,
		})
	end
end
function modifier_xhs_carrion_beetle:OnIntervalThink()
	local beetle = self:GetParent()
	local caster = self:GetCaster()
	if not IsValidCryptLordUnit(beetle) or not IsValidCryptLordUnit(caster) then return end
	local impale = caster:FindAbilityByName("nyx_assassin_impale")
	if impale == nil or impale:GetLevel() <= 0 or not impale:GetAutoCastState() then return end
	local current = beetle:GetAttackTarget()
	if IsValidCryptLordUnit(current) and current:HasModifier("modifier_xhs_crypt_lord_infested") then return end
	local enemies = FindUnitsInRadius(caster:GetTeamNumber(), beetle:GetAbsOrigin(), nil,
		self:GetAbility():GetSpecialValueFor("priority_radius"), DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_CLOSEST, false)
	for _, enemy in pairs(enemies) do
		if enemy:HasModifier("modifier_xhs_crypt_lord_infested") then
			beetle:MoveToTargetToAttack(enemy)
			return
		end
	end
end

-- Carrion Plague: three stacks, non-propagating death burst, fixed hive healing.
holdout_poison_sting = holdout_poison_sting or class({})
function holdout_poison_sting:GetIntrinsicModifierName() return "modifier_xhs_carrion_plague_handler" end

modifier_xhs_carrion_plague_handler = modifier_xhs_carrion_plague_handler or class({})
modifier_xhs_carrion_plague_handler.XHS_LINK_CLIENT = true
function modifier_xhs_carrion_plague_handler:IsHidden() return true end
function modifier_xhs_carrion_plague_handler:IsPurgable() return false end
function modifier_xhs_carrion_plague_handler:DeclareFunctions() return { MODIFIER_EVENT_ON_ATTACK_LANDED } end
function modifier_xhs_carrion_plague_handler:OnAttackLanded(keys)
	if IsServer() and keys.attacker == self:GetParent() then ApplyCarrionPlague(self:GetParent(), keys.target) end
end

modifier_xhs_carrion_plague = modifier_xhs_carrion_plague or class({})
modifier_xhs_carrion_plague.XHS_LINK_CLIENT = true
function modifier_xhs_carrion_plague:IsHidden() return false end
function modifier_xhs_carrion_plague:IsDebuff() return true end
function modifier_xhs_carrion_plague:IsPurgable() return true end
function modifier_xhs_carrion_plague:GetTexture() return "venomancer_poison_sting" end
function modifier_xhs_carrion_plague:GetEffectName()
	return "particles/units/heroes/hero_viper/viper_poison_debuff.vpcf"
end
function modifier_xhs_carrion_plague:GetEffectAttachType() return PATTACH_ABSORIGIN_FOLLOW end
function modifier_xhs_carrion_plague:OnCreated()
	self.move_slow = self:GetAbility():GetSpecialValueFor("bonus_movement_speed")
	if IsServer() then
		self:SetStackCount(1)
		self:StartIntervalThink(1)
	end
end
function modifier_xhs_carrion_plague:OnRefresh()
	self.move_slow = self:GetAbility():GetSpecialValueFor("bonus_movement_speed")
	if IsServer() then
		self:SetStackCount(math.min(self:GetStackCount() + 1, self:GetAbility():GetSpecialValueFor("max_stacks")))
	end
end
function modifier_xhs_carrion_plague:DeclareFunctions()
	return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE, MODIFIER_EVENT_ON_DEATH }
end
function modifier_xhs_carrion_plague:GetModifierMoveSpeedBonus_Percentage()
	return (self.move_slow or 0) * self:GetStackCount()
end
function modifier_xhs_carrion_plague:OnIntervalThink()
	local target = self:GetParent()
	local caster = self:GetCaster()
	local ability = self:GetAbility()
	if not IsValidCryptLordUnit(target) or not IsValidCryptLordUnit(caster) or ability == nil then return end
	local damage = ability:GetSpecialValueFor("damage") * self:GetStackCount()
	if IsCryptLordBoss(target) then damage = damage * ability:GetSpecialValueFor("boss_poison_pct") * 0.01 end
	ApplyDamage({ victim = target, attacker = caster, ability = ability, damage = damage, damage_type = DAMAGE_TYPE_MAGICAL })
end
function modifier_xhs_carrion_plague:OnDeath(keys)
	if not IsServer() or keys.unit ~= self:GetParent() then return end
	local caster = self:GetCaster()
	local ability = self:GetAbility()
	if not IsValidCryptLordUnit(caster) or ability == nil then return end
	local stacks = math.max(1, self:GetStackCount())
	local origin = self:GetParent():GetAbsOrigin()
	local enemies = FindUnitsInRadius(caster:GetTeamNumber(), origin, nil,
		ability:GetSpecialValueFor("death_burst_radius"), DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
	for _, enemy in pairs(enemies) do
		local damage = ability:GetSpecialValueFor("death_burst_damage") * stacks
		if IsCryptLordBoss(enemy) then damage = damage * ability:GetSpecialValueFor("boss_burst_pct") * 0.01 end
		ApplyDamage({ victim = enemy, attacker = caster, ability = ability, damage = damage, damage_type = DAMAGE_TYPE_MAGICAL })
	end
	-- Intentionally no plague application here: bursts can never propagate or chain exponentially.
	HealCryptLordHive(caster, ability, ability:GetSpecialValueFor("death_heal") * stacks)
	local burst = ParticleManager:CreateParticle("particles/units/heroes/hero_necrolyte/necrolyte_pulse_enemy.vpcf", PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleControl(burst, 0, origin)
	ParticleManager:SetParticleControl(burst, 1, Vector(ability:GetSpecialValueFor("death_burst_radius"), 0, 0))
	ParticleManager:ReleaseParticleIndex(burst)
end

-- Spiked Carapace: real received-damage reflection and a reactive defensive active.
holdout_spiked_carapace = holdout_spiked_carapace or class({})
function holdout_spiked_carapace:GetIntrinsicModifierName() return "modifier_xhs_spiked_carapace_passive" end
function holdout_spiked_carapace:OnSpellStart()
	if not IsServer() then return end
	local caster = self:GetCaster()
	caster:AddNewModifier(caster, self, "modifier_xhs_spiked_carapace_active", {
		duration = self:GetSpecialValueFor("active_duration"),
	})
	caster:EmitSound("Hero_NyxAssassin.SpikedCarapace")
end

modifier_xhs_spiked_carapace_passive = modifier_xhs_spiked_carapace_passive or class({})
modifier_xhs_spiked_carapace_passive.XHS_LINK_CLIENT = true
function modifier_xhs_spiked_carapace_passive:IsHidden() return true end
function modifier_xhs_spiked_carapace_passive:IsPurgable() return false end
function modifier_xhs_spiked_carapace_passive:DeclareFunctions()
	return { MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS, MODIFIER_EVENT_ON_TAKEDAMAGE }
end
function modifier_xhs_spiked_carapace_passive:GetModifierPhysicalArmorBonus()
	return self:GetAbility():GetSpecialValueFor("bonus_armor")
end
function modifier_xhs_spiked_carapace_passive:OnTakeDamage(keys)
	if not IsServer() or keys.unit ~= self:GetParent() or self.reflecting == true then return end
	local attacker = keys.attacker
	if not IsValidCryptLordUnit(attacker) or attacker:GetTeamNumber() == self:GetParent():GetTeamNumber() then return end
	if attacker:IsBuilding() or (keys.damage or 0) <= 0 then return end
	if bit ~= nil and bit.band(keys.damage_flags or 0, DOTA_DAMAGE_FLAG_REFLECTION) ~= 0 then return end
	local ability = self:GetAbility()
	local return_pct = attacker:IsRealHero() and ability:GetSpecialValueFor("hero_return_percent")
		or ability:GetSpecialValueFor("creep_return_percent")
	local return_damage = keys.damage * return_pct * 0.01
	if not attacker:IsRealHero() then
		return_damage = math.max(return_damage, ability:GetSpecialValueFor("creep_return_minimum"))
	end
	self.reflecting = true
	ApplyDamage({
		victim = attacker,
		attacker = self:GetParent(),
		ability = ability,
		damage = return_damage,
		damage_type = keys.damage_type or DAMAGE_TYPE_PHYSICAL,
		damage_flags = DOTA_DAMAGE_FLAG_REFLECTION,
	})
	self.reflecting = false
	local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_centaur/centaur_return.vpcf",
		PATTACH_ABSORIGIN, self:GetParent())
	ParticleManager:SetParticleControlEnt(particle, 0, self:GetParent(), PATTACH_POINT_FOLLOW,
		"attach_hitloc", self:GetParent():GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(particle, 1, attacker, PATTACH_POINT_FOLLOW,
		"attach_hitloc", attacker:GetAbsOrigin(), true)
	ParticleManager:ReleaseParticleIndex(particle)
end

modifier_xhs_spiked_carapace_active = modifier_xhs_spiked_carapace_active or class({})
modifier_xhs_spiked_carapace_active.XHS_LINK_CLIENT = true
function modifier_xhs_spiked_carapace_active:IsHidden() return false end
function modifier_xhs_spiked_carapace_active:IsPurgable() return false end
function modifier_xhs_spiked_carapace_active:GetTexture() return "nyx_assassin_spiked_carapace" end
function modifier_xhs_spiked_carapace_active:GetEffectName() return "particles/items_fx/blademail.vpcf" end
function modifier_xhs_spiked_carapace_active:GetEffectAttachType() return PATTACH_ABSORIGIN_FOLLOW end
function modifier_xhs_spiked_carapace_active:OnCreated()
	self.damage_reduction = self:GetAbility():GetSpecialValueFor("active_damage_reduction")
	if IsServer() then self.attack_count = 0 end
end
function modifier_xhs_spiked_carapace_active:DeclareFunctions()
	return { MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE, MODIFIER_EVENT_ON_TAKEDAMAGE }
end
function modifier_xhs_spiked_carapace_active:GetModifierIncomingDamage_Percentage()
	return -(self.damage_reduction or 0)
end
function modifier_xhs_spiked_carapace_active:OnTakeDamage(keys)
	if not IsServer() or keys.unit ~= self:GetParent() or keys.inflictor ~= nil then return end
	if not IsValidCryptLordUnit(keys.attacker) or keys.attacker:GetTeamNumber() == self:GetParent():GetTeamNumber() then return end
	self.attack_count = self.attack_count + 1
	local ability = self:GetAbility()
	if self.attack_count < ability:GetSpecialValueFor("pulse_hits") then return end
	self.attack_count = 0
	local radius = ability:GetSpecialValueFor("pulse_radius")
	local enemies = FindUnitsInRadius(self:GetParent():GetTeamNumber(), self:GetParent():GetAbsOrigin(), nil, radius,
		DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
	for _, enemy in pairs(enemies) do
		ApplyDamage({
			victim = enemy,
			attacker = self:GetParent(),
			ability = ability,
			damage = ability:GetSpecialValueFor("pulse_damage"),
			damage_type = DAMAGE_TYPE_PHYSICAL,
		})
	end
	local pulse = ParticleManager:CreateParticle("particles/units/heroes/hero_sandking/sandking_epicenter.vpcf",
		PATTACH_ABSORIGIN, self:GetParent())
	ParticleManager:SetParticleControl(pulse, 0, self:GetParent():GetAbsOrigin())
	ParticleManager:SetParticleControl(pulse, 1, Vector(radius, 1, 1))
	ParticleManager:ReleaseParticleIndex(pulse)
	self:GetParent():EmitSound("Hero_NyxAssassin.SpikedCarapace.Stun")
end

-- Frenzy of the Hive: buffs the hero and renewed beetle, deliberately without splash or cleave.
holdout_anubarak_claw = holdout_anubarak_claw or class({})
function holdout_anubarak_claw:OnSpellStart()
	if not IsServer() then return end
	local caster = self:GetCaster()
	local duration = self:GetSpecialValueFor("duration")
	caster:AddNewModifier(caster, self, "modifier_xhs_frenzy_of_the_hive", { duration = duration })
	for _, beetle in pairs(GetCryptLordBeetles(caster)) do
		beetle:AddNewModifier(caster, self, "modifier_xhs_frenzy_of_the_hive", {
			duration = duration,
			hive_member = 1,
		})
	end
	caster:EmitSound("DOTA_Item.MaskOfMadness.Activate")
end

modifier_xhs_frenzy_of_the_hive = modifier_xhs_frenzy_of_the_hive or class({})
modifier_xhs_frenzy_of_the_hive.XHS_LINK_CLIENT = true
function modifier_xhs_frenzy_of_the_hive:IsHidden() return false end
function modifier_xhs_frenzy_of_the_hive:IsPurgable() return true end
function modifier_xhs_frenzy_of_the_hive:GetTexture() return "beastmaster_inner_beast" end
function modifier_xhs_frenzy_of_the_hive:GetEffectName() return "particles/items2_fx/mask_of_madness.vpcf" end
function modifier_xhs_frenzy_of_the_hive:GetEffectAttachType() return PATTACH_ABSORIGIN_FOLLOW end
function modifier_xhs_frenzy_of_the_hive:OnCreated(keys)
	self.attack_speed = self:GetAbility():GetSpecialValueFor("bonus_attack_speed")
	self.move_speed = self:GetAbility():GetSpecialValueFor("bonus_movement_speed_percentage")
	if IsServer() then
		self.is_hive_member = tonumber(keys.hive_member) == 1
		self.extension_used = 0
	end
end
function modifier_xhs_frenzy_of_the_hive:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
		MODIFIER_EVENT_ON_DEATH,
	}
end
function modifier_xhs_frenzy_of_the_hive:GetModifierAttackSpeedBonus_Constant() return self.attack_speed or 0 end
function modifier_xhs_frenzy_of_the_hive:GetModifierMoveSpeedBonus_Percentage() return self.move_speed or 0 end
function modifier_xhs_frenzy_of_the_hive:OnDeath(keys)
	if not IsServer() or self.is_hive_member then return end
	local victim = keys.unit
	if victim == nil or victim:IsNull() or not victim:HasModifier("modifier_xhs_carrion_plague") then return end
	local caster = self:GetCaster()
	local killer = keys.attacker
	local valid_killer = killer == caster
	if not valid_killer and killer ~= nil and not killer:IsNull() then
		local beetle_modifier = killer:FindModifierByName("modifier_xhs_carrion_beetle")
		valid_killer = beetle_modifier ~= nil and beetle_modifier:GetCaster() == caster
	end
	if not valid_killer then return end
	local ability = self:GetAbility()
	local extension = math.min(ability:GetSpecialValueFor("kill_extension"),
		math.max(0, ability:GetSpecialValueFor("max_extension") - self.extension_used))
	if extension <= 0 then return end
	self.extension_used = self.extension_used + extension
	local new_duration = self:GetRemainingTime() + extension
	self:SetDuration(new_duration, true)
	for _, beetle in pairs(GetCryptLordBeetles(caster)) do
		local modifier = beetle:FindModifierByName("modifier_xhs_frenzy_of_the_hive")
		if modifier ~= nil then modifier:SetDuration(math.max(modifier:GetRemainingTime(), new_duration), true) end
	end
end

function BurrowImpale(keys)
local caster = keys.caster
local target = keys.target

	local impale = ParticleManager:CreateParticle("particles/units/heroes/hero_nyx_assassin/nyx_assassin_impale.vpcf", PATTACH_CUSTOMORIGIN, nil)
	ParticleManager:SetParticleControl(impale, 0, target:GetAbsOrigin())

	Timers:CreateTimer(0.49, function()
		ParticleManager:DestroyParticle(impale, true)
	end)
end

function BurrowImpaleAnimation(keys)
local caster = keys.caster

	StartAnimation(caster, {duration = 0.49, activity = ACT_DOTA_CAST_ABILITY_1, rate = 1.25})
end

function BurrowImpaleChannelEnd(keys)
local caster = keys.caster
	EndAnimation(caster)
end

function Return( event )
local caster = event.caster
local attacker = event.attacker
local ability = event.ability
local damageType = ability:GetAbilityDamageType()
local hero_damage = ability:GetLevelSpecialValueFor( "hero_return_percent" , ability:GetLevel() - 1  )
local creep_damage = ability:GetLevelSpecialValueFor( "creep_return_percent" , ability:GetLevel() - 1  )
local attacker_damage = attacker:GetBaseDamageMin()
local divided_damage = attacker_damage / 100

	if attacker:GetTeamNumber() ~= caster:GetTeamNumber() and attacker:IsHero() then
		ApplyDamage({ victim = attacker, attacker = caster, damage = divided_damage * hero_damage, damage_type = damageType })
	elseif attacker:GetTeamNumber() ~= caster:GetTeamNumber() and attacker:IsCreep() then
		ApplyDamage({ victim = attacker, attacker = caster, damage = divided_damage * creep_damage, damage_type = damageType })
	end
end
