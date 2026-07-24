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
}

for _, ability_name in ipairs(PASSIVE_NAMES) do
	_G[ability_name] = _G[ability_name] or class({})
	_G[ability_name].GetIntrinsicModifierName = function()
		return "modifier_xhs_creep_passive"
	end
end

LinkLuaModifier("modifier_xhs_creep_passive", "abilities/creeps/xhs_creep_passives.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_xhs_creep_passive_slow", "abilities/creeps/xhs_creep_passives.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_xhs_creep_passive_dot", "abilities/creeps/xhs_creep_passives.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_xhs_creep_passive_armor_break", "abilities/creeps/xhs_creep_passives.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_xhs_creep_passive_aura", "abilities/creeps/xhs_creep_passives.lua", LUA_MODIFIER_MOTION_NONE)

local function Special(ability, name)
	return ability and ability:GetSpecialValueFor(name) or 0
end

local function PlayProcFeedback(source, target, particle_name, sound_name)
	local now = GameRules:GetGameTime()
	if (source.xhs_creep_feedback_ready_at or 0) > now then return end
	source.xhs_creep_feedback_ready_at = now + 0.5
	local particle = ParticleManager:CreateParticle(particle_name, PATTACH_ABSORIGIN_FOLLOW, target)
	ParticleManager:ReleaseParticleIndex(particle)
	target:EmitSound(sound_name)
end

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
function modifier_xhs_creep_passive:GetModifierAura() return "modifier_xhs_creep_passive_aura" end
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
	local slow = Special(ability, "slow_pct")
	if slow > 0 then
		target:AddNewModifier(parent, ability, "modifier_xhs_creep_passive_slow", {
			duration = Special(ability, "debuff_duration"),
			slow = slow,
			attack_slow = Special(ability, "attack_slow"),
		})
	end

	local dot = Special(ability, "dot_damage_pct")
	if dot > 0 then
		target:AddNewModifier(parent, ability, "modifier_xhs_creep_passive_dot", {
			duration = Special(ability, "debuff_duration"),
			damage = parent:GetAverageTrueAttackDamage(target) * dot * 0.01,
		})
	end

	local bonus = Special(ability, "proc_damage_pct")
	local proc_chance = Special(ability, "proc_chance")
	if bonus > 0 and RollPseudoRandomPercentage(proc_chance, 1972, parent) then
		ApplyDamage({ victim = target, attacker = parent, ability = ability, damage = parent:GetAverageTrueAttackDamage(target) * bonus * 0.01, damage_type = DAMAGE_TYPE_PHYSICAL })
		PlayProcFeedback(parent, target, "particles/items_fx/skull_basher.vpcf", "DOTA_Item.SkullBasher")
	end

	local mana_burn = Special(ability, "mana_burn_pct")
	if mana_burn > 0 and target.GetMana then
		local burned = math.min(target:GetMana(), target:GetMaxMana() * mana_burn * 0.01)
		target:ReduceMana(burned)
		ApplyDamage({ victim = target, attacker = parent, ability = ability, damage = burned, damage_type = DAMAGE_TYPE_PHYSICAL })
	end

	local armor_break = Special(ability, "armor_reduction")
	if armor_break > 0 then
		target:AddNewModifier(parent, ability, "modifier_xhs_creep_passive_armor_break", {
			duration = Special(ability, "debuff_duration"),
			armor = armor_break,
		})
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
		target:AddNewModifier(parent, ability, "modifier_silence", { duration = Special(ability, "silence_duration") })
		ability:StartCooldown(Special(ability, "proc_cooldown"))
		PlayProcFeedback(parent, target, "particles/generic_gameplay/generic_silenced.vpcf", "Hero_Silencer.LastWord.Damage")
	end
end

function modifier_xhs_creep_passive:OnTakeDamage(params)
	if not IsServer() then return end
	local parent = self:GetParent()
	local ability = self:GetAbility()
	if params.attacker == parent and params.damage_category == DOTA_DAMAGE_CATEGORY_ATTACK then
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
		params.attacker:AddNewModifier(parent, ability, "modifier_xhs_creep_passive_slow", {
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
function modifier_xhs_creep_passive_slow:OnCreated(kv) self.slow = tonumber(kv.slow) or 0 self.attack_slow = tonumber(kv.attack_slow) or 0 end
function modifier_xhs_creep_passive_slow:OnRefresh(kv) self:OnCreated(kv) end
function modifier_xhs_creep_passive_slow:DeclareFunctions() return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE, MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT } end
function modifier_xhs_creep_passive_slow:GetModifierMoveSpeedBonus_Percentage() return -self.slow end
function modifier_xhs_creep_passive_slow:GetModifierAttackSpeedBonus_Constant() return -self.attack_slow end

modifier_xhs_creep_passive_dot = modifier_xhs_creep_passive_dot or class({})
modifier_xhs_creep_passive_dot.XHS_LINK_CLIENT = true
function modifier_xhs_creep_passive_dot:IsDebuff() return true end
function modifier_xhs_creep_passive_dot:IsPurgable() return true end
function modifier_xhs_creep_passive_dot:OnCreated(kv) self.damage = tonumber(kv.damage) or 0 if IsServer() then self:StartIntervalThink(1) end end
function modifier_xhs_creep_passive_dot:OnRefresh(kv) self.damage = tonumber(kv.damage) or self.damage end
function modifier_xhs_creep_passive_dot:OnIntervalThink()
	ApplyDamage({ victim = self:GetParent(), attacker = self:GetCaster(), ability = self:GetAbility(), damage = self.damage, damage_type = DAMAGE_TYPE_MAGICAL })
end

modifier_xhs_creep_passive_armor_break = modifier_xhs_creep_passive_armor_break or class({})
modifier_xhs_creep_passive_armor_break.XHS_LINK_CLIENT = true
function modifier_xhs_creep_passive_armor_break:IsDebuff() return true end
function modifier_xhs_creep_passive_armor_break:IsPurgable() return true end
function modifier_xhs_creep_passive_armor_break:OnCreated(kv) self.armor = tonumber(kv.armor) or 0 end
function modifier_xhs_creep_passive_armor_break:OnRefresh(kv) self:OnCreated(kv) end
function modifier_xhs_creep_passive_armor_break:DeclareFunctions() return { MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS } end
function modifier_xhs_creep_passive_armor_break:GetModifierPhysicalArmorBonus() return -self.armor end

modifier_xhs_creep_passive_aura = modifier_xhs_creep_passive_aura or class({})
modifier_xhs_creep_passive_aura.XHS_LINK_CLIENT = true
function modifier_xhs_creep_passive_aura:IsHidden() return false end
function modifier_xhs_creep_passive_aura:IsPurgable() return false end
function modifier_xhs_creep_passive_aura:IsDebuff() return Special(self:GetAbility(), "aura_mode") == 2 end
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
	return { MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT, MODIFIER_PROPERTY_BASEDAMAGEOUTGOING_PERCENTAGE, MODIFIER_PROPERTY_HEALTH_REGEN_PERCENTAGE, MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS }
end
function modifier_xhs_creep_passive_aura:GetModifierAttackSpeedBonus_Constant() return Special(self:GetAbility(), "aura_attack_speed") end
function modifier_xhs_creep_passive_aura:GetModifierBaseDamageOutgoing_Percentage() return Special(self:GetAbility(), "aura_damage_pct") end
function modifier_xhs_creep_passive_aura:GetModifierHealthRegenPercentage() return Special(self:GetAbility(), "aura_regen_pct") end
function modifier_xhs_creep_passive_aura:GetModifierPhysicalArmorBonus() return -Special(self:GetAbility(), "aura_armor_reduction") end
