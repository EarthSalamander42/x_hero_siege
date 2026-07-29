require("boss_scripts/phase3_ai/cast_bar")
require("boss_scripts/phase3_ai/telegraphs")

XHSSpecialArenaAI = XHSSpecialArenaAI or {}

LinkLuaModifier("modifier_xhs_special_arena_ai", "boss_scripts/special_arena_ai.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_xhs_special_arena_last_stand", "boss_scripts/special_arena_ai.lua", LUA_MODIFIER_MOTION_NONE)

modifier_xhs_special_arena_ai = modifier_xhs_special_arena_ai or class({})
modifier_xhs_special_arena_last_stand = modifier_xhs_special_arena_last_stand or class({})

local PROFILES = {
	ramero = {
		{ name = "sven_warcry", cast = "no_target", label = "Warcry" },
		{ name = "sven_gods_strength", cast = "no_target", label = "God's Strength", partner_death_only = true },
	},
	baristol = {
		{ name = "baristol_holy_light", cast = "friendly", label = "Holy Light", range = 900, ally_health_below = 95 },
		{ name = "centaur_hoof_stomp", cast = "no_target", label = "Holy Stomp", range = 350, radius = 350 },
		{ name = "omniknight_guardian_angel", cast = "no_target", label = "Guardian Angel", ally_health_below = 65 },
	},
	sogat = {
		{ name = "roshan_stormbolt", cast = "enemy", label = "Storm Bolt", range = 900 },
		{ name = "sven_warcry", cast = "no_target", label = "Warsong" },
		{ name = "sven_gods_strength", cast = "no_target", label = "Bloodlust" },
	},
}

local function IsAlive(unit)
	return unit ~= nil and IsValidEntity(unit) and not unit:IsNull() and unit:IsAlive()
end

local function FindEnemy(boss)
	local enemies = FindUnitsInRadius(
		boss:GetTeamNumber(),
		boss:GetAbsOrigin(),
		nil,
		1600,
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO,
		DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
		FIND_CLOSEST,
		false
	)
	for _, enemy in ipairs(enemies) do
		if IsAlive(enemy) and enemy:IsRealHero() and not enemy:IsIllusion() then return enemy end
	end
	return nil
end

local function FindInjuredAlly(boss, radius, healthThreshold)
	local best = nil
	local bestPct = healthThreshold or 99.9
	local allies = FindUnitsInRadius(
		boss:GetTeamNumber(),
		boss:GetAbsOrigin(),
		nil,
		radius or 1200,
		DOTA_UNIT_TARGET_TEAM_FRIENDLY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		DOTA_UNIT_TARGET_FLAG_NONE,
		FIND_ANY_ORDER,
		false
	)
	for _, ally in ipairs(allies) do
		if IsAlive(ally) and ally:GetHealthPercent() < bestPct then
			best = ally
			bestPct = ally:GetHealthPercent()
		end
	end
	return best
end

local LAST_STAND_PARTNER = {
	npc_ramero = "npc_baristol",
	npc_baristol = "npc_ramero",
}

local LAST_STAND_SPELLS = {
	ramero = { "sven_gods_strength" },
	baristol = { "omniknight_guardian_angel" },
}

local REMOVED_PROFILE_ABILITIES = {
	ramero = { "roshan_stormbolt" },
}

local function CopySpellList(source)
	local result = {}
	for _, abilityName in ipairs(source or {}) do
		table.insert(result, abilityName)
	end
	return result
end

local function StartCastFeedback(boss, ability, spell)
	if XHSBossCastBar ~= nil then
		XHSBossCastBar:Start(boss, ability, {
			display_name = spell.label,
			style = "special",
		})
	end
	if spell.radius ~= nil and XHSBossTelegraphs ~= nil then
		XHSBossTelegraphs:Circle(boss:GetAbsOrigin(), spell.radius, math.max(ability:GetCastPoint(), 0.5), {
			primary = Vector(255, 185, 65),
			secondary = Vector(255, 70, 45),
			style = 4,
		})
	end
end

function XHSSpecialArenaAI:Attach(boss, profileName)
	if not IsAlive(boss) or PROFILES[profileName] == nil then return end

	boss:RemoveModifierByName("modifier_ai")
	boss:RemoveModifierByName("modifier_creature_ai")
	boss.xhs_special_arena_profile = profileName

	for _, abilityName in ipairs(REMOVED_PROFILE_ABILITIES[profileName] or {}) do
		if boss:FindAbilityByName(abilityName) ~= nil then
			boss:RemoveAbility(abilityName)
		end
	end

	for _, spell in ipairs(PROFILES[profileName]) do
		local ability = boss:FindAbilityByName(spell.name) or boss:AddAbility(spell.name)
		if ability ~= nil and ability:GetLevel() < 1 then
			ability:SetLevel(math.max(1, math.min(ability:GetMaxLevel(), GameRules:GetCustomGameDifficulty())))
		end
	end

	boss:AddNewModifier(boss, nil, "modifier_xhs_special_arena_ai", {})
end

function modifier_xhs_special_arena_ai:IsHidden() return true end
function modifier_xhs_special_arena_ai:IsPurgable() return false end

function modifier_xhs_special_arena_ai:OnCreated()
	if not IsServer() then return end
	self.next_attack_order = 0
	self.next_spell_index = 1
	self.forced_spells = nil
	self.next_forced_spell_time = 0
	self:StartIntervalThink(0.3)
end

function modifier_xhs_special_arena_ai:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_DEATH,
	}
end

function modifier_xhs_special_arena_ai:OnDeath(event)
	if not IsServer() or self.last_stand_triggered == true or event == nil or event.unit == nil then return end

	local boss = self:GetParent()
	local partnerName = LAST_STAND_PARTNER[boss:GetUnitName()]
	if partnerName == nil or event.unit:GetUnitName() ~= partnerName or event.unit:GetTeamNumber() ~= boss:GetTeamNumber() then return end

	self.last_stand_triggered = true
	boss:AddNewModifier(boss, nil, "modifier_xhs_special_arena_last_stand", {})
	boss:SetMana(boss:GetMaxMana())
	self.forced_spells = CopySpellList(LAST_STAND_SPELLS[boss.xhs_special_arena_profile])
	self.next_forced_spell_time = GameRules:GetGameTime() + 0.1
end

function modifier_xhs_special_arena_ai:OnIntervalThink()
	local boss = self:GetParent()
	if not IsAlive(boss) then
		self:Destroy()
		return
	end
	if boss:HasModifier("modifier_pause_creeps") or boss:IsStunned() or boss:IsChanneling() or boss:IsSilenced() then return end

	local now = GameRules:GetGameTime()
	if self.forced_spells ~= nil and #self.forced_spells > 0 then
		if now < self.next_forced_spell_time then return end

		local abilityName = table.remove(self.forced_spells, 1)
		local ability = boss:FindAbilityByName(abilityName)
		if ability ~= nil then
			ability:EndCooldown()
			boss:SetMana(boss:GetMaxMana())
			boss:CastAbilityNoTarget(ability, -1)
			self.next_forced_spell_time = now + math.max(ability:GetCastPoint() + 0.5, 0.7)
			return
		end
	end

	local target = FindEnemy(boss)
	if target == nil then return end
	local profile = PROFILES[boss.xhs_special_arena_profile] or {}

	for offset = 0, #profile - 1 do
		local index = ((self.next_spell_index + offset - 1) % #profile) + 1
		local spell = profile[index]
		local ability = boss:FindAbilityByName(spell.name)
		if spell.partner_death_only ~= true and ability ~= nil and ability:IsFullyCastable() then
			local castTarget = target
			local canCast = spell.range == nil or (target:GetAbsOrigin() - boss:GetAbsOrigin()):Length2D() <= spell.range
			if spell.cast == "friendly" then
				castTarget = FindInjuredAlly(boss, spell.range or 900, spell.ally_health_below)
				canCast = castTarget ~= nil
			elseif spell.ally_health_below ~= nil then
				canCast = FindInjuredAlly(boss, 1200, spell.ally_health_below) ~= nil
			end

			if canCast then
				local order = {
					UnitIndex = boss:entindex(),
					AbilityIndex = ability:entindex(),
					Queue = false,
				}
				if spell.cast == "enemy" then
					order.OrderType = DOTA_UNIT_ORDER_CAST_TARGET
					order.TargetIndex = target:entindex()
				elseif spell.cast == "friendly" then
					order.OrderType = DOTA_UNIT_ORDER_CAST_TARGET
					order.TargetIndex = castTarget:entindex()
				else
					order.OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET
				end

				StartCastFeedback(boss, ability, spell)
				ExecuteOrderFromTable(order)
				self.next_spell_index = (index % #profile) + 1
				return
			end
		end
	end

	if now >= self.next_attack_order then
		boss:MoveToTargetToAttack(target)
		self.next_attack_order = now + 0.8
	end
end

function modifier_xhs_special_arena_last_stand:IsHidden() return false end
function modifier_xhs_special_arena_last_stand:IsPurgable() return false end
function modifier_xhs_special_arena_last_stand:RemoveOnDeath() return true end
function modifier_xhs_special_arena_last_stand:GetTexture() return "sven_gods_strength" end
function modifier_xhs_special_arena_last_stand:GetEffectName()
	return "particles/units/heroes/hero_sven/sven_spell_gods_strength.vpcf"
end
function modifier_xhs_special_arena_last_stand:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_xhs_special_arena_last_stand:OnCreated()
	if not IsServer() then return end

	local boss = self:GetParent()
	boss:Heal(boss:GetMaxHealth() * 0.25, nil)
	boss:EmitSound("Hero_Sven.GodsStrength")
end

function modifier_xhs_special_arena_last_stand:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_BASEDAMAGEOUTGOING_PERCENTAGE,
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
		MODIFIER_PROPERTY_STATUS_RESISTANCE_STACKING,
	}
end

function modifier_xhs_special_arena_last_stand:GetModifierBaseDamageOutgoing_Percentage() return 40 end
function modifier_xhs_special_arena_last_stand:GetModifierAttackSpeedBonus_Constant() return 60 end
function modifier_xhs_special_arena_last_stand:GetModifierMoveSpeedBonus_Percentage() return 15 end
function modifier_xhs_special_arena_last_stand:GetModifierStatusResistanceStacking() return 25 end
