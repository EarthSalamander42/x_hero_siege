local PASSIVE_NAMES = {
	"xhs_creep_blood_hunger", "xhs_creep_heavy_hide", "xhs_creep_ricochet",
	"xhs_creep_dragon_blood", "xhs_creep_double_tap", "xhs_creep_berserker_blood",
	"xhs_creep_frost_arrows", "xhs_creep_headshot", "xhs_creep_plague_cloud",
	"xhs_creep_endurance", "xhs_creep_thorns", "xhs_creep_death_aura",
	"xhs_creep_magic_ward", "xhs_creep_restoration", "xhs_creep_chaos_strike",
	"xhs_creep_mana_break", "xhs_creep_fervor", "xhs_creep_venom_shot",
	"xhs_creep_scorching_breath", "xhs_creep_titanic_cleave", "xhs_creep_evasion",
	"xhs_creep_pack_leader", "xhs_creep_cold_skin", "xhs_creep_corrosive_scales",
	"xhs_creep_untouchable", "xhs_creep_silencing_glaive", "xhs_creep_toxic_flight",
	"xhs_creep_static_charge", "xhs_creep_death_surge", "xhs_creep_riposte",
	"xhs_creep_crushing_armor", "xhs_creep_reactive_armor", "xhs_creep_spell_ward",
	"xhs_creep_moon_glaive", "xhs_creep_geminate_shot", "xhs_creep_knights_guard",
	"xhs_creep_shamanic_ward", "xhs_creep_chimaera_splash", "xhs_creep_devotion",
	"xhs_creep_spiked_carapace", "xhs_creep_craggy_exterior", "xhs_creep_dread_aura",
	"xhs_creep_fiery_soul", "xhs_creep_frostmourne_hunger", "xhs_creep_unholy_sustain",
	"xhs_creep_war_leader", "xhs_creep_vengeance_aura", "xhs_creep_command_aura",
	"xhs_creep_fel_ward", "xhs_creep_crippling_strike",
	"xhs_creep_fury_swipes",
}

for _, ability_name in ipairs(PASSIVE_NAMES) do
	_G[ability_name] = _G[ability_name] or class({})
	_G[ability_name].GetIntrinsicModifierName = function()
		return "modifier_xhs_creep_passive"
	end
end

local MODIFIER_SCRIPT = "abilities/creeps/xhs_creep_passives.lua"

LinkLuaModifier("modifier_xhs_creep_passive", MODIFIER_SCRIPT, LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_xhs_creep_passive_slow", MODIFIER_SCRIPT, LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_xhs_creep_passive_dot", MODIFIER_SCRIPT, LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_xhs_creep_passive_armor_break", MODIFIER_SCRIPT, LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_xhs_creep_passive_aura", MODIFIER_SCRIPT, LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_xhs_creep_fury_swipes", MODIFIER_SCRIPT, LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_xhs_creep_fury_swipes_debuff", MODIFIER_SCRIPT, LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_xhs_creep_crushing_armor_sync", MODIFIER_SCRIPT, LUA_MODIFIER_MOTION_NONE)

local EFFECT_MODIFIERS = {
	xhs_creep_frost_arrows = { slow = "modifier_xhs_creep_frost_arrows_debuff" },
	xhs_creep_plague_cloud = { aura = "modifier_xhs_creep_plague_cloud_aura" },
	xhs_creep_endurance = { aura = "modifier_xhs_creep_endurance_aura" },
	xhs_creep_death_aura = { aura = "modifier_xhs_creep_death_aura_debuff" },
	xhs_creep_restoration = { aura = "modifier_xhs_creep_restoration_aura" },
	xhs_creep_venom_shot = { dot = "modifier_xhs_creep_venom_shot_debuff" },
	xhs_creep_scorching_breath = { dot = "modifier_xhs_creep_scorching_breath_debuff" },
	xhs_creep_pack_leader = { aura = "modifier_xhs_creep_pack_leader_aura" },
	xhs_creep_cold_skin = { slow = "modifier_xhs_creep_cold_skin_debuff" },
	xhs_creep_corrosive_scales = { armor = "modifier_xhs_creep_corrosive_scales_debuff" },
	xhs_creep_untouchable = { slow = "modifier_xhs_creep_untouchable_debuff" },
	xhs_creep_silencing_glaive = { silence = "modifier_xhs_creep_silencing_glaive_debuff" },
	xhs_creep_toxic_flight = {
		slow = "modifier_xhs_creep_toxic_flight_slow",
		dot = "modifier_xhs_creep_toxic_flight_dot",
	},
	xhs_creep_crushing_armor = { armor = "modifier_xhs_creep_crushing_armor_debuff" },
	xhs_creep_devotion = { aura = "modifier_xhs_creep_devotion_aura" },
	xhs_creep_craggy_exterior = { slow = "modifier_xhs_creep_craggy_exterior_debuff" },
	xhs_creep_dread_aura = { aura = "modifier_xhs_creep_dread_aura_debuff" },
	xhs_creep_fiery_soul = { dot = "modifier_xhs_creep_fiery_soul_debuff" },
	xhs_creep_war_leader = { aura = "modifier_xhs_creep_war_leader_aura" },
	xhs_creep_vengeance_aura = { aura = "modifier_xhs_creep_vengeance_aura" },
	xhs_creep_command_aura = { aura = "modifier_xhs_creep_command_aura" },
	xhs_creep_crippling_strike = { slow = "modifier_xhs_creep_crippling_strike_debuff" },
}

for _, modifier_names in pairs(EFFECT_MODIFIERS) do
	for _, modifier_name in pairs(modifier_names) do
		LinkLuaModifier(modifier_name, MODIFIER_SCRIPT, LUA_MODIFIER_MOTION_NONE)
	end
end

local function Special(ability, name)
	return ability and ability:GetSpecialValueFor(name) or 0
end

local MOON_GLAIVE_PROJECTILE = "particles/units/heroes/hero_luna/luna_moon_glaive_bounce.vpcf"
local MOON_GLAIVE_IMPACT_SOUND = "Hero_Luna.MoonGlaive.Impact"

local function IsValidMoonGlaiveTarget(caster, target)
	return caster ~= nil
		and not caster:IsNull()
		and target ~= nil
		and not target:IsNull()
		and target:IsAlive()
		and not target:IsBuilding()
		and target:GetTeamNumber() ~= caster:GetTeamNumber()
end

function xhs_creep_moon_glaive:LaunchGlaiveProjectile(source, target, chain_id, damage, bounces_remaining)
	if not IsServer() or not IsValidMoonGlaiveTarget(self:GetCaster(), target) then
		if self.xhs_glaive_chains ~= nil then
			self.xhs_glaive_chains[chain_id] = nil
		end
		return
	end
	if source == nil or source:IsNull() then
		source = self:GetCaster()
	end

	ProjectileManager:CreateTrackingProjectile({
		Target = target,
		Source = source,
		Ability = self,
		EffectName = MOON_GLAIVE_PROJECTILE,
		iMoveSpeed = math.max(1, Special(self, "projectile_speed")),
		iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_HITLOCATION,
		vSourceLoc = source:GetAbsOrigin(),
		bDodgeable = false,
		bIsAttack = false,
		bReplaceExisting = false,
		bProvidesVision = false,
		flExpireTime = GameRules:GetGameTime() + 5.0,
		ExtraData = {
			chain_id = chain_id,
			damage = damage,
			bounces_remaining = bounces_remaining,
		},
	})
end

function xhs_creep_moon_glaive:StartGlaiveChain(primary_target, primary_damage)
	if not IsServer() or not IsValidMoonGlaiveTarget(self:GetCaster(), primary_target) then return end

	local bounce_count = math.max(0, math.floor(Special(self, "bounces")))
	if bounce_count <= 0 then return end

	local caster = self:GetCaster()
	local candidates = FindUnitsInRadius(
		caster:GetTeamNumber(),
		primary_target:GetAbsOrigin(),
		nil,
		Special(self, "bounce_range"),
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
		FIND_CLOSEST,
		false
	)

	local first_target = nil
	for _, candidate in ipairs(candidates) do
		if candidate ~= primary_target and IsValidMoonGlaiveTarget(caster, candidate) then
			first_target = candidate
			break
		end
	end
	if first_target == nil then return end

	self.xhs_glaive_chain_id = (tonumber(self.xhs_glaive_chain_id) or 0) + 1
	local chain_id = self.xhs_glaive_chain_id
	self.xhs_glaive_chains = self.xhs_glaive_chains or {}
	self.xhs_glaive_chains[chain_id] = {
		hit = {
			[primary_target:entindex()] = true,
		},
	}

	local reduction = math.max(0, math.min(100, Special(self, "damage_reduction_pct"))) * 0.01
	local first_damage = math.max(0, tonumber(primary_damage) or 0) * (1 - reduction)
	self:LaunchGlaiveProjectile(primary_target, first_target, chain_id, first_damage, bounce_count)
end

function xhs_creep_moon_glaive:OnProjectileHit_ExtraData(target, location, extra_data)
	if not IsServer() then return true end

	extra_data = extra_data or {}
	local chain_id = tonumber(extra_data.chain_id)
	local chains = self.xhs_glaive_chains
	local chain = chains and chain_id and chains[chain_id] or nil
	local caster = self:GetCaster()
	if chain == nil or not IsValidMoonGlaiveTarget(caster, target) then
		if chains and chain_id then chains[chain_id] = nil end
		return true
	end

	chain.hit[target:entindex()] = true
	ApplyDamage({
		victim = target,
		attacker = caster,
		ability = self,
		damage = math.max(0, tonumber(extra_data.damage) or 0),
		damage_type = DAMAGE_TYPE_PHYSICAL,
		damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION,
	})
	EmitSoundOn(MOON_GLAIVE_IMPACT_SOUND, target)

	local bounces_remaining = math.max(0, math.floor(tonumber(extra_data.bounces_remaining) or 0))
	if bounces_remaining <= 1 then
		chains[chain_id] = nil
		return true
	end

	local candidates = FindUnitsInRadius(
		caster:GetTeamNumber(),
		target:GetAbsOrigin(),
		nil,
		Special(self, "bounce_range"),
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
		FIND_CLOSEST,
		false
	)
	local next_target = nil
	for _, candidate in ipairs(candidates) do
		if chain.hit[candidate:entindex()] ~= true and IsValidMoonGlaiveTarget(caster, candidate) then
			next_target = candidate
			break
		end
	end

	if next_target == nil then
		chains[chain_id] = nil
		return true
	end

	local reduction = math.max(0, math.min(100, Special(self, "damage_reduction_pct"))) * 0.01
	local next_damage = math.max(0, tonumber(extra_data.damage) or 0) * (1 - reduction)
	self:LaunchGlaiveProjectile(target, next_target, chain_id, next_damage, bounces_remaining - 1)
	return true
end

local function EffectModifierName(ability, effect, fallback)
	if ability == nil or ability:IsNull() then return fallback end
	local modifier_names = EFFECT_MODIFIERS[ability:GetAbilityName()]
	return modifier_names and modifier_names[effect] or fallback
end

local function AbilityTexture(modifier)
	local ability = modifier:GetAbility()
	return ability and not ability:IsNull() and ability:GetAbilityTextureName() or ""
end

local function PlayProcFeedback(source, target, particle_name, sound_name)
	local now = GameRules:GetGameTime()
	if (source.xhs_creep_feedback_ready_at or 0) > now then return end
	source.xhs_creep_feedback_ready_at = now + 0.5
	local particle = ParticleManager:CreateParticle(particle_name, PATTACH_ABSORIGIN_FOLLOW, target)
	ParticleManager:ReleaseParticleIndex(particle)
	target:EmitSound(sound_name)
end

local function ExistingCrushingArmorReduction(modifier)
	if modifier.GetAppliedArmorReduction then
		return math.max(0, modifier:GetAppliedArmorReduction())
	end

	return math.max(0, tonumber(modifier.armor) or Special(modifier:GetAbility(), "armor_reduction"))
end

local function ApplySharedCrushingArmor(parent, target, ability, armor_per_stack, duration)
	local modifier_name = "modifier_xhs_creep_crushing_armor_debuff"
	local modifier = nil
	local current_reduction = 0
	local modifiers = target:FindAllModifiersByName(modifier_name)

	-- Reconstruct the target's armor without Crushing Armor before merging any
	-- legacy per-caster instances. This makes the shared cap exact.
	for _, existing_modifier in pairs(modifiers) do
		current_reduction = current_reduction + ExistingCrushingArmorReduction(existing_modifier)
		if modifier == nil then
			modifier = existing_modifier
		end
	end

	local armor_without_crushing = target:GetPhysicalArmorValue(false) + current_reduction
	local maximum_reduction = math.max(0, armor_without_crushing)
	current_reduction = math.min(current_reduction, maximum_reduction)

	for _, existing_modifier in pairs(modifiers) do
		if existing_modifier ~= modifier then
			existing_modifier:Destroy()
		end
	end

	if maximum_reduction <= 0 then
		if modifier ~= nil then modifier:Destroy() end
		return
	end

	-- The last stack may be partial so Crushing Armor reaches exactly 0 armor
	-- and can never push the target into negative armor by itself.
	local new_reduction = math.min(maximum_reduction, current_reduction + armor_per_stack)
	if modifier == nil then
		modifier = target:AddNewModifier(parent, ability, modifier_name, {
			duration = duration,
			armor = new_reduction,
			armor_per_stack = armor_per_stack,
		})
	else
		modifier:SetDuration(duration, true)
		modifier:SetAppliedArmorReduction(new_reduction, armor_per_stack)
	end
end

xhs_creep_fury_swipes = xhs_creep_fury_swipes or class({})
function xhs_creep_fury_swipes:GetIntrinsicModifierName()
	return "modifier_xhs_creep_fury_swipes"
end

modifier_xhs_creep_fury_swipes = modifier_xhs_creep_fury_swipes or class({})
modifier_xhs_creep_fury_swipes.XHS_LINK_CLIENT = true
function modifier_xhs_creep_fury_swipes:IsHidden() return true end
function modifier_xhs_creep_fury_swipes:IsPurgable() return false end
function modifier_xhs_creep_fury_swipes:GetAttributes() return MODIFIER_ATTRIBUTE_PERMANENT end
function modifier_xhs_creep_fury_swipes:DeclareFunctions()
	return { MODIFIER_EVENT_ON_ATTACK_LANDED }
end
function modifier_xhs_creep_fury_swipes:OnAttackLanded(params)
	if not IsServer() or params.attacker ~= self:GetParent() or params.target == nil then return end

	local parent = self:GetParent()
	local target = params.target
	if parent.PassivesDisabled and parent:PassivesDisabled() then return end
	if target:GetTeamNumber() == parent:GetTeamNumber() or target:IsBuilding() then return end

	local ability = self:GetAbility()
	if ability == nil or ability:IsNull() then return end

	local modifier_name = "modifier_xhs_creep_fury_swipes_debuff"
	local modifier = nil
	local current_stacks = 0

	-- Fury Swipes belongs to the victim, not to an individual attacker.
	-- Merge any legacy per-caster instances so the whole wave builds one stack.
	for _, existing_modifier in pairs(target:FindAllModifiersByName(modifier_name)) do
		current_stacks = current_stacks + existing_modifier:GetStackCount()
		if modifier == nil then
			modifier = existing_modifier
		else
			existing_modifier:Destroy()
		end
	end

	local bonus_damage = current_stacks * Special(ability, "damage_per_stack")

	if bonus_damage > 0 and target:IsAlive() then
		ApplyDamage({
			victim = target,
			attacker = parent,
			ability = ability,
			damage = bonus_damage,
			damage_type = DAMAGE_TYPE_PHYSICAL,
		})
	end

	if not target:IsAlive() then return end

	local duration = Special(ability, "stack_duration")
	if modifier ~= nil then
		modifier:SetDuration(duration, true)
	else
		modifier = target:AddNewModifier(parent, ability, modifier_name, { duration = duration })
	end

	if modifier ~= nil then
		modifier:SetStackCount(current_stacks + 1)
	end
end

modifier_xhs_creep_fury_swipes_debuff = modifier_xhs_creep_fury_swipes_debuff or class({})
modifier_xhs_creep_fury_swipes_debuff.XHS_LINK_CLIENT = true
function modifier_xhs_creep_fury_swipes_debuff:IsHidden() return false end
function modifier_xhs_creep_fury_swipes_debuff:IsDebuff() return true end
function modifier_xhs_creep_fury_swipes_debuff:IsPurgable() return false end
function modifier_xhs_creep_fury_swipes_debuff:GetTexture() return "ursa_fury_swipes" end

modifier_xhs_creep_passive = modifier_xhs_creep_passive or class({})
modifier_xhs_creep_passive.XHS_LINK_CLIENT = true
function modifier_xhs_creep_passive:IsHidden() return true end
function modifier_xhs_creep_passive:IsPurgable() return false end
function modifier_xhs_creep_passive:GetAttributes() return MODIFIER_ATTRIBUTE_PERMANENT end
function modifier_xhs_creep_passive:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_BASEDAMAGEOUTGOING_PERCENTAGE,
		MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
		MODIFIER_PROPERTY_HEALTH_REGEN_PERCENTAGE,
		MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
		MODIFIER_PROPERTY_EVASION_CONSTANT,
		MODIFIER_PROPERTY_PHYSICAL_CONSTANT_BLOCK,
		MODIFIER_PROPERTY_PREATTACK_CRITICALSTRIKE,
		MODIFIER_EVENT_ON_ATTACK_LANDED,
		MODIFIER_EVENT_ON_TAKEDAMAGE,
	}
end
function modifier_xhs_creep_passive:GetModifierBaseDamageOutgoing_Percentage()
	return -Special(self:GetAbility(), "damage_compensation_pct")
end
function modifier_xhs_creep_passive:GetModifierIncomingDamage_Percentage()
	return Special(self:GetAbility(), "defense_compensation_pct") - Special(self:GetAbility(), "damage_reduction_pct")
end
function modifier_xhs_creep_passive:GetModifierPhysicalArmorBonus()
	return Special(self:GetAbility(), "bonus_armor")
end
function modifier_xhs_creep_passive:GetModifierHealthRegenPercentage()
	return Special(self:GetAbility(), "regen_pct")
end
function modifier_xhs_creep_passive:GetModifierMagicalResistanceBonus()
	return Special(self:GetAbility(), "magic_resist")
end
function modifier_xhs_creep_passive:GetModifierAttackSpeedBonus_Constant()
	local ability = self:GetAbility()
	local value = Special(ability, "attack_speed")
	if Special(ability, "low_health_attack_speed") > 0 then
		local missing = 1 - self:GetParent():GetHealthPercent() / 100
		value = value + Special(ability, "low_health_attack_speed") * missing
	end
	return value
end
function modifier_xhs_creep_passive:GetModifierEvasion_Constant()
	return Special(self:GetAbility(), "evasion")
end
function modifier_xhs_creep_passive:GetModifierPhysical_ConstantBlock()
	return Special(self:GetAbility(), "physical_block")
end
function modifier_xhs_creep_passive:GetModifierPreAttack_CriticalStrike(params)
	local chance = Special(self:GetAbility(), "crit_chance")
	if chance > 0 and RollPseudoRandomPercentage(chance, 1971, self:GetParent()) then
		return Special(self:GetAbility(), "crit_damage")
	end
end
function modifier_xhs_creep_passive:IsAura()
	return Special(self:GetAbility(), "aura_mode") > 0
end
function modifier_xhs_creep_passive:GetModifierAura()
	return EffectModifierName(self:GetAbility(), "aura", "modifier_xhs_creep_passive_aura")
end
function modifier_xhs_creep_passive:GetAuraRadius() return Special(self:GetAbility(), "aura_radius") end
function modifier_xhs_creep_passive:GetAuraSearchTeam()
	return Special(self:GetAbility(), "aura_mode") == 2 and DOTA_UNIT_TARGET_TEAM_ENEMY or DOTA_UNIT_TARGET_TEAM_FRIENDLY
end
function modifier_xhs_creep_passive:GetAuraSearchType()
	return Special(self:GetAbility(), "aura_targets_heroes_only") > 0 and DOTA_UNIT_TARGET_HERO or DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
end
function modifier_xhs_creep_passive:GetAuraSearchFlags() return DOTA_UNIT_TARGET_FLAG_NONE end

function modifier_xhs_creep_passive:OnAttackLanded(params)
	if not IsServer() or params.attacker ~= self:GetParent() or params.target == nil then return end
	if params.target:GetTeamNumber() == params.attacker:GetTeamNumber() or params.target:IsBuilding() then return end

	local ability = self:GetAbility()
	local parent = self:GetParent()
	local target = params.target
	if ability:GetAbilityName() == "xhs_creep_moon_glaive" then
		local attack_damage = math.max(0, tonumber(params.damage) or 0)
		if parent.GetAttackDamage ~= nil then
			attack_damage = math.max(attack_damage, tonumber(parent:GetAttackDamage()) or 0)
		end
		attack_damage = math.max(attack_damage, parent:GetAverageTrueAttackDamage(target))
		ability:StartGlaiveChain(target, attack_damage)
	end

	local slow = Special(ability, "slow_pct")
	if slow > 0 then
		target:AddNewModifier(parent, ability, EffectModifierName(ability, "slow", "modifier_xhs_creep_passive_slow"), {
			duration = Special(ability, "debuff_duration"),
			slow = slow,
			attack_slow = Special(ability, "attack_slow"),
		})
	end

	local dot = Special(ability, "dot_damage_pct")
	if dot > 0 then
		target:AddNewModifier(parent, ability, EffectModifierName(ability, "dot", "modifier_xhs_creep_passive_dot"), {
			duration = Special(ability, "debuff_duration"),
			damage = parent:GetAverageTrueAttackDamage(target) * dot * 0.01,
		})
	end

	local bonus = Special(ability, "proc_damage_pct")
	local proc_chance = Special(ability, "proc_chance")
	if bonus > 0 and RollPseudoRandomPercentage(proc_chance, 1972, parent) then
		ApplyDamage({ victim = target, attacker = parent, ability = ability, damage = parent:GetAverageTrueAttackDamage(target) * bonus * 0.01, damage_type = DAMAGE_TYPE_PHYSICAL })
		PlayProcFeedback(parent, target, "particles/units/heroes/hero_sniper/sniper_headshot_slow.vpcf", "DOTA_Item.SkullBasher")
	end

	local mana_burn = Special(ability, "mana_burn_pct")
	if mana_burn > 0 and target.GetMana then
		local burned = math.min(target:GetMana(), target:GetMaxMana() * mana_burn * 0.01)
		if burned > 0 then
			if target.Script_ReduceMana ~= nil then
				target:Script_ReduceMana(burned, ability)
			elseif target.SetMana ~= nil then
				target:SetMana(math.max(0, target:GetMana() - burned))
			end
			ApplyDamage({ victim = target, attacker = parent, ability = ability, damage = burned, damage_type = DAMAGE_TYPE_PHYSICAL })
		end
	end

	local armor_break = Special(ability, "armor_reduction")
	if armor_break > 0 then
		if ability:GetAbilityName() == "xhs_creep_crushing_armor" then
			ApplySharedCrushingArmor(parent, target, ability, armor_break, Special(ability, "debuff_duration"))
		else
			target:AddNewModifier(parent, ability, EffectModifierName(ability, "armor", "modifier_xhs_creep_passive_armor_break"), {
				duration = Special(ability, "debuff_duration"),
				armor = armor_break,
			})
		end
	end

	local cleave = Special(ability, "cleave_pct")
	if cleave > 0 then
		local enemies = FindUnitsInRadius(parent:GetTeamNumber(), target:GetAbsOrigin(), nil, Special(ability, "splash_radius"), DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
		for _, enemy in pairs(enemies) do
			if enemy ~= target then
				ApplyDamage({ victim = enemy, attacker = parent, ability = ability, damage = params.damage * cleave * 0.01, damage_type = DAMAGE_TYPE_PHYSICAL })
			end
		end
	end

	local silence_chance = Special(ability, "silence_chance")
	if silence_chance > 0 and ability:IsCooldownReady() and RollPseudoRandomPercentage(silence_chance, 1973, parent) then
		target:AddNewModifier(parent, ability, EffectModifierName(ability, "silence", "modifier_xhs_creep_silencing_glaive_debuff"), {
			duration = Special(ability, "silence_duration"),
		})
		ability:StartCooldown(Special(ability, "proc_cooldown"))
		target:EmitSound("Hero_Silencer.LastWord.Damage")
	end
end

function modifier_xhs_creep_passive:OnTakeDamage(params)
	if not IsServer() then return end
	local parent = self:GetParent()
	local ability = self:GetAbility()
	local is_attack_damage = params.damage_category == DOTA_DAMAGE_CATEGORY_ATTACK
	if params.damage_category == nil then
		is_attack_damage = params.inflictor == nil
	end
	if params.attacker == parent and params.damage > 0 and is_attack_damage then
		local lifesteal = Special(ability, "lifesteal_pct")
		if lifesteal > 0 then
			parent:Heal(params.damage * lifesteal * 0.01, ability)
		end
	end
	if params.unit ~= parent or params.attacker == nil or params.attacker == parent then return end

	local reflect = Special(ability, "reflect_pct")
	if reflect > 0 and not parent.xhs_reflecting then
		parent.xhs_reflecting = true
		ApplyDamage({ victim = params.attacker, attacker = parent, ability = ability, damage = params.damage * reflect * 0.01, damage_type = DAMAGE_TYPE_PURE, damage_flags = DOTA_DAMAGE_FLAG_REFLECTION })
		parent.xhs_reflecting = nil
	end

	local cold_slow = Special(ability, "retaliation_slow")
	if cold_slow > 0 then
		params.attacker:AddNewModifier(parent, ability, EffectModifierName(ability, "slow", "modifier_xhs_creep_passive_slow"), {
			duration = Special(ability, "debuff_duration"),
			slow = cold_slow,
			attack_slow = cold_slow,
		})
	end
end

modifier_xhs_creep_passive_slow = modifier_xhs_creep_passive_slow or class({})
modifier_xhs_creep_passive_slow.XHS_LINK_CLIENT = true
function modifier_xhs_creep_passive_slow:IsDebuff() return true end
function modifier_xhs_creep_passive_slow:IsPurgable() return true end
function modifier_xhs_creep_passive_slow:GetTexture() return AbilityTexture(self) end
function modifier_xhs_creep_passive_slow:OnCreated(kv) self.slow = tonumber(kv.slow) or 0 self.attack_slow = tonumber(kv.attack_slow) or 0 end
function modifier_xhs_creep_passive_slow:OnRefresh(kv) self:OnCreated(kv) end
function modifier_xhs_creep_passive_slow:DeclareFunctions() return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE, MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT } end
function modifier_xhs_creep_passive_slow:GetModifierMoveSpeedBonus_Percentage() return -self.slow end
function modifier_xhs_creep_passive_slow:GetModifierAttackSpeedBonus_Constant() return -self.attack_slow end

modifier_xhs_creep_silencing_glaive_debuff = modifier_xhs_creep_silencing_glaive_debuff or class({})
modifier_xhs_creep_silencing_glaive_debuff.XHS_LINK_CLIENT = true
function modifier_xhs_creep_silencing_glaive_debuff:IsHidden() return true end
function modifier_xhs_creep_silencing_glaive_debuff:IsDebuff() return true end
function modifier_xhs_creep_silencing_glaive_debuff:IsPurgable() return true end
function modifier_xhs_creep_silencing_glaive_debuff:GetTexture() return AbilityTexture(self) end
function modifier_xhs_creep_silencing_glaive_debuff:GetEffectName()
	return "particles/generic_gameplay/generic_silenced.vpcf"
end
function modifier_xhs_creep_silencing_glaive_debuff:GetEffectAttachType()
	return PATTACH_OVERHEAD_FOLLOW
end
function modifier_xhs_creep_silencing_glaive_debuff:CheckState()
	return {
		[MODIFIER_STATE_SILENCED] = true,
	}
end

modifier_xhs_creep_passive_dot = modifier_xhs_creep_passive_dot or class({})
modifier_xhs_creep_passive_dot.XHS_LINK_CLIENT = true
function modifier_xhs_creep_passive_dot:IsDebuff() return true end
function modifier_xhs_creep_passive_dot:IsPurgable() return true end
function modifier_xhs_creep_passive_dot:GetTexture() return AbilityTexture(self) end
function modifier_xhs_creep_passive_dot:OnCreated(kv) self.damage = tonumber(kv.damage) or 0 if IsServer() then self:StartIntervalThink(1) end end
function modifier_xhs_creep_passive_dot:OnRefresh(kv) self.damage = tonumber(kv.damage) or self.damage end
function modifier_xhs_creep_passive_dot:OnIntervalThink()
	ApplyDamage({ victim = self:GetParent(), attacker = self:GetCaster(), ability = self:GetAbility(), damage = self.damage, damage_type = DAMAGE_TYPE_MAGICAL })
end

modifier_xhs_creep_passive_armor_break = modifier_xhs_creep_passive_armor_break or class({})
modifier_xhs_creep_passive_armor_break.XHS_LINK_CLIENT = true
function modifier_xhs_creep_passive_armor_break:IsDebuff() return true end
function modifier_xhs_creep_passive_armor_break:IsPurgable() return true end
function modifier_xhs_creep_passive_armor_break:GetTexture() return AbilityTexture(self) end
function modifier_xhs_creep_passive_armor_break:OnCreated(kv) self.armor = tonumber(kv.armor) or 0 end
function modifier_xhs_creep_passive_armor_break:OnRefresh(kv) self:OnCreated(kv) end
function modifier_xhs_creep_passive_armor_break:DeclareFunctions() return { MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS } end
function modifier_xhs_creep_passive_armor_break:GetModifierPhysicalArmorBonus() return -self.armor end

local CRUSHING_ARMOR_SYNC_SCALE = 100

modifier_xhs_creep_crushing_armor_sync = modifier_xhs_creep_crushing_armor_sync or class({})
modifier_xhs_creep_crushing_armor_sync.XHS_LINK_CLIENT = true
function modifier_xhs_creep_crushing_armor_sync:IsHidden() return true end
function modifier_xhs_creep_crushing_armor_sync:IsDebuff() return true end
function modifier_xhs_creep_crushing_armor_sync:IsPurgable() return false end
function modifier_xhs_creep_crushing_armor_sync:IsPurgeException() return false end
function modifier_xhs_creep_crushing_armor_sync:GetAppliedArmorReduction()
	return math.max(0, self:GetStackCount()) / CRUSHING_ARMOR_SYNC_SCALE
end
function modifier_xhs_creep_crushing_armor_sync:DeclareFunctions()
	return { MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS }
end
function modifier_xhs_creep_crushing_armor_sync:GetModifierPhysicalArmorBonus()
	return -self:GetAppliedArmorReduction()
end

modifier_xhs_creep_crushing_armor_debuff = modifier_xhs_creep_crushing_armor_debuff or class({})
modifier_xhs_creep_crushing_armor_debuff.XHS_LINK_CLIENT = true
function modifier_xhs_creep_crushing_armor_debuff:IsHidden() return false end
function modifier_xhs_creep_crushing_armor_debuff:IsDebuff() return true end
function modifier_xhs_creep_crushing_armor_debuff:IsPurgable() return true end
function modifier_xhs_creep_crushing_armor_debuff:GetTexture() return AbilityTexture(self) end
function modifier_xhs_creep_crushing_armor_debuff:OnCreated(kv)
	self.armor_reduction = math.max(0, tonumber(kv.armor) or 0)
	self.armor_per_stack = math.max(0.01, tonumber(kv.armor_per_stack) or Special(self:GetAbility(), "armor_reduction"))
	if IsServer() then
		self:SetHasCustomTransmitterData(true)
		self:SetAppliedArmorReduction(self.armor_reduction, self.armor_per_stack)
		self:StartIntervalThink(0.2)
	end
end
function modifier_xhs_creep_crushing_armor_debuff:AddCustomTransmitterData()
	return {
		armor_reduction = self.armor_reduction or 0,
		armor_per_stack = self.armor_per_stack or 0.01,
	}
end
function modifier_xhs_creep_crushing_armor_debuff:HandleCustomTransmitterData(data)
	self.armor_reduction = tonumber(data.armor_reduction) or 0
	self.armor_per_stack = tonumber(data.armor_per_stack) or 0.01
end
function modifier_xhs_creep_crushing_armor_debuff:GetAppliedArmorReduction()
	-- The visible modifier owns the exact transmitted float. A freshly
	-- replicated hidden sync modifier can temporarily exist with 0 stacks; it
	-- must not mask the already valid tooltip value.
	local transmitted_reduction = math.max(0, tonumber(self.armor_reduction) or tonumber(self.armor) or 0)
	if transmitted_reduction > 0 then
		return transmitted_reduction
	end

	local synced_reduction = 0
	for _, sync_modifier in pairs(self:GetParent():FindAllModifiersByName("modifier_xhs_creep_crushing_armor_sync")) do
		synced_reduction = math.max(synced_reduction, sync_modifier:GetAppliedArmorReduction())
	end
	if synced_reduction > 0 then
		return synced_reduction
	end

	-- Last-resort client fallback. The visible stack count is replicated even
	-- on builds where custom transmitter data arrives a frame late.
	local armor_per_stack = Special(self:GetAbility(), "armor_reduction")
	if armor_per_stack <= 0 then
		armor_per_stack = math.max(0, tonumber(self.armor_per_stack) or 0)
	end
	return math.max(0, self:GetStackCount()) * armor_per_stack
end
function modifier_xhs_creep_crushing_armor_debuff:SetAppliedArmorReduction(reduction, armor_per_stack)
	if not IsServer() then return end

	self.armor_reduction = math.max(0, tonumber(reduction) or 0)
	self.armor_per_stack = math.max(0.01, tonumber(armor_per_stack) or self.armor_per_stack or 0.01)

	local sync_modifier = self:GetParent():FindModifierByName("modifier_xhs_creep_crushing_armor_sync")
	if sync_modifier == nil then
		sync_modifier = self:GetParent():AddNewModifier(
			self:GetCaster(),
			self:GetAbility(),
			"modifier_xhs_creep_crushing_armor_sync",
			{}
		)
	end
	if sync_modifier ~= nil then
		sync_modifier:SetStackCount(math.floor(self.armor_reduction * CRUSHING_ARMOR_SYNC_SCALE + 0.5))
	end

	local stacks = 0
	if self.armor_reduction > 0 then
		stacks = math.max(1, math.ceil(self.armor_reduction / self.armor_per_stack - 0.0001))
	end
	self:SetStackCount(stacks)
	self:SendBuffRefreshToClients()
	self:GetParent():CalculateStatBonus(true)
end
function modifier_xhs_creep_crushing_armor_debuff:OnIntervalThink()
	local parent = self:GetParent()
	local current_reduction = self:GetAppliedArmorReduction()
	local armor_without_crushing = parent:GetPhysicalArmorValue(false) + current_reduction
	local clamped_reduction = math.min(current_reduction, math.max(0, armor_without_crushing))

	if clamped_reduction <= 0 then
		self:Destroy()
	elseif math.abs(clamped_reduction - current_reduction) > 0.001 then
		self:SetAppliedArmorReduction(clamped_reduction, self.armor_per_stack)
	end
end
function modifier_xhs_creep_crushing_armor_debuff:OnDestroy()
	if not IsServer() then return end

	for _, sync_modifier in pairs(self:GetParent():FindAllModifiersByName("modifier_xhs_creep_crushing_armor_sync")) do
		sync_modifier:Destroy()
	end
end
function modifier_xhs_creep_crushing_armor_debuff:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_TOOLTIP,
	}
end
function modifier_xhs_creep_crushing_armor_debuff:OnTooltip()
	return self:GetAppliedArmorReduction()
end

modifier_xhs_creep_passive_aura = modifier_xhs_creep_passive_aura or class({})
modifier_xhs_creep_passive_aura.XHS_LINK_CLIENT = true
function modifier_xhs_creep_passive_aura:IsHidden() return false end
function modifier_xhs_creep_passive_aura:IsPurgable() return false end
function modifier_xhs_creep_passive_aura:IsDebuff() return Special(self:GetAbility(), "aura_mode") == 2 end
function modifier_xhs_creep_passive_aura:GetTexture() return AbilityTexture(self) end
function modifier_xhs_creep_passive_aura:OnCreated()
	if IsServer() and Special(self:GetAbility(), "aura_dot_damage_pct") > 0 then
		self:StartIntervalThink(1)
	end
end
function modifier_xhs_creep_passive_aura:OnIntervalThink()
	local caster = self:GetCaster()
	if caster == nil or caster:IsNull() then return end
	ApplyDamage({
		victim = self:GetParent(),
		attacker = caster,
		ability = self:GetAbility(),
		damage = caster:GetAverageTrueAttackDamage(self:GetParent()) * Special(self:GetAbility(), "aura_dot_damage_pct") * 0.01,
		damage_type = DAMAGE_TYPE_MAGICAL,
	})
end
function modifier_xhs_creep_passive_aura:DeclareFunctions()
	return { MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT, MODIFIER_PROPERTY_BASEDAMAGEOUTGOING_PERCENTAGE, MODIFIER_PROPERTY_HEALTH_REGEN_PERCENTAGE, MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS, MODIFIER_PROPERTY_TOOLTIP }
end
function modifier_xhs_creep_passive_aura:GetModifierAttackSpeedBonus_Constant() return Special(self:GetAbility(), "aura_attack_speed") end
function modifier_xhs_creep_passive_aura:GetModifierBaseDamageOutgoing_Percentage() return Special(self:GetAbility(), "aura_damage_pct") end
function modifier_xhs_creep_passive_aura:GetModifierHealthRegenPercentage() return Special(self:GetAbility(), "aura_regen_pct") end
function modifier_xhs_creep_passive_aura:GetModifierPhysicalArmorBonus() return -Special(self:GetAbility(), "aura_armor_reduction") end
function modifier_xhs_creep_passive_aura:OnTooltip()
	return Special(self:GetAbility(), "aura_damage_pct")
end

local EFFECT_BASE_CLASSES = {
	slow = modifier_xhs_creep_passive_slow,
	silence = modifier_xhs_creep_silencing_glaive_debuff,
	dot = modifier_xhs_creep_passive_dot,
	armor = modifier_xhs_creep_passive_armor_break,
	aura = modifier_xhs_creep_passive_aura,
}

for _, modifier_names in pairs(EFFECT_MODIFIERS) do
	for effect, modifier_name in pairs(modifier_names) do
		local base_class = EFFECT_BASE_CLASSES[effect]
		if _G[modifier_name] == nil then
			assert(type(base_class) == "table", "Missing creep effect base class: " .. tostring(effect))
			_G[modifier_name] = class({}, nil, base_class)
		end
		_G[modifier_name].XHS_LINK_CLIENT = true
	end
end

-- Toxic Flight uses separate slow and damage components internally. Keep the
-- damage component hidden so the victim sees one debuff instead of two
-- identical Toxic Flight icons.
function modifier_xhs_creep_toxic_flight_dot:IsHidden()
	return true
end
