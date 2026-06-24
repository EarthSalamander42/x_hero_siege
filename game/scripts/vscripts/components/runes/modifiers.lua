local function ApplyVisibleRuneModifierDefaults(modifierClass)
	if modifierClass == nil then return end

	if modifierClass.IsHidden == nil then
		modifierClass.IsHidden = function() return false end
	end

	if modifierClass.IsPurgable == nil then
		modifierClass.IsPurgable = function() return false end
	end

	if modifierClass.IsPurgeException == nil then
		modifierClass.IsPurgeException = function() return false end
	end
end

modifier_xhs_rune_healing = modifier_xhs_rune_healing or class({})
function modifier_xhs_rune_healing:OnCreated(kv)
	kv = kv or {}
	self.hp_regen_pct = tonumber(kv.hp_regen_pct) or 5
	self.mana_regen_pct = tonumber(kv.mana_regen_pct) or 8
end
function modifier_xhs_rune_healing:OnRefresh(kv) self:OnCreated(kv) end
function modifier_xhs_rune_healing:GetTexture() return "rune_regen" end
function modifier_xhs_rune_healing:DeclareFunctions() return { MODIFIER_PROPERTY_HEALTH_REGEN_PERCENTAGE, MODIFIER_PROPERTY_MANA_REGEN_TOTAL_PERCENTAGE } end
function modifier_xhs_rune_healing:GetModifierHealthRegenPercentage() return self.hp_regen_pct or 0 end
function modifier_xhs_rune_healing:GetModifierTotalPercentageManaRegen() return self.mana_regen_pct or 0 end

modifier_xhs_rune_revitalization = modifier_xhs_rune_revitalization or class({})
function modifier_xhs_rune_revitalization:OnCreated(kv)
	kv = kv or {}
	self.mana_regen_pct = tonumber(kv.mana_regen_pct) or 12
end
function modifier_xhs_rune_revitalization:OnRefresh(kv) self:OnCreated(kv) end
function modifier_xhs_rune_revitalization:GetTexture() return "rune_arcane" end
function modifier_xhs_rune_revitalization:DeclareFunctions() return { MODIFIER_PROPERTY_MANA_REGEN_TOTAL_PERCENTAGE } end
function modifier_xhs_rune_revitalization:GetModifierTotalPercentageManaRegen() return self.mana_regen_pct or 0 end

modifier_xhs_rune_second_wind = modifier_xhs_rune_second_wind or class({})
function modifier_xhs_rune_second_wind:OnCreated(kv)
	kv = kv or {}
	self.threshold_pct = tonumber(kv.threshold_pct) or 30
	self.heal_pct = tonumber(kv.heal_pct) or 30
	self.mana_pct = tonumber(kv.mana_pct) or 0
	self.recovery_duration = tonumber(kv.recovery_duration) or 3
	self.guard_duration = tonumber(kv.guard_duration) or 4
	self.guard_reduction = tonumber(kv.guard_reduction) or 20
	self.consumed = false

	if IsServer() then
		self:SetStackCount(1)
		self:StartIntervalThink(0.2)
	end
end
function modifier_xhs_rune_second_wind:OnRefresh(kv) self:OnCreated(kv) end
function modifier_xhs_rune_second_wind:GetTexture() return "oracle_false_promise" end
function modifier_xhs_rune_second_wind:OnIntervalThink()
	if self.consumed then return end

	local parent = self:GetParent()
	if parent == nil or parent:IsNull() or not parent:IsAlive() then return end

	if parent:GetHealth() > parent:GetMaxHealth() * self.threshold_pct * 0.01 then return end

	self.consumed = true
	self:SetStackCount(0)
	parent:AddNewModifier(parent, nil, "modifier_xhs_rune_second_wind_heal", { duration = self.recovery_duration, recovery_duration = self.recovery_duration, heal_pct = self.heal_pct, mana_pct = self.mana_pct })
	parent:AddNewModifier(parent, nil, "modifier_xhs_rune_second_wind_guard", { duration = self.guard_duration, guard_reduction = self.guard_reduction })
	self:Destroy()
end

modifier_xhs_rune_second_wind_heal = modifier_xhs_rune_second_wind_heal or class({})
function modifier_xhs_rune_second_wind_heal:OnCreated(kv)
	kv = kv or {}
	self.heal_pct = tonumber(kv.heal_pct) or 30
	self.mana_pct = tonumber(kv.mana_pct) or 0
	self.recovery_duration = math.max(0.1, tonumber(kv.recovery_duration) or self:GetDuration() or 3)
	self.health_regen = self:GetParent():GetMaxHealth() * self.heal_pct * 0.01 / self.recovery_duration
	self.mana_regen = self:GetParent():GetMaxMana() * self.mana_pct * 0.01 / self.recovery_duration
end
function modifier_xhs_rune_second_wind_heal:OnRefresh(kv) self:OnCreated(kv) end
function modifier_xhs_rune_second_wind_heal:GetTexture() return "rune_regen" end
function modifier_xhs_rune_second_wind_heal:DeclareFunctions() return { MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT, MODIFIER_PROPERTY_MANA_REGEN_CONSTANT } end
function modifier_xhs_rune_second_wind_heal:GetModifierConstantHealthRegen() return self.health_regen or 0 end
function modifier_xhs_rune_second_wind_heal:GetModifierConstantManaRegen() return self.mana_regen or 0 end

modifier_xhs_rune_second_wind_guard = modifier_xhs_rune_second_wind_guard or class({})
function modifier_xhs_rune_second_wind_guard:OnCreated(kv)
	kv = kv or {}
	self.guard_reduction = tonumber(kv.guard_reduction) or 20
end
function modifier_xhs_rune_second_wind_guard:OnRefresh(kv) self:OnCreated(kv) end
function modifier_xhs_rune_second_wind_guard:GetTexture() return "abaddon_borrowed_time" end
function modifier_xhs_rune_second_wind_guard:DeclareFunctions() return { MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE } end
function modifier_xhs_rune_second_wind_guard:GetModifierIncomingDamage_Percentage() return -(self.guard_reduction or 0) end

modifier_xhs_rune_barrier = modifier_xhs_rune_barrier or class({})
function modifier_xhs_rune_barrier:OnCreated(kv)
	kv = kv or {}
	self.max_shield = self:GetParent():GetMaxHealth() * ((tonumber(kv.shield_pct) or 25) * 0.01)
	self.shield = self.max_shield
	self.regen_per_second = self:GetParent():GetMaxHealth() * ((tonumber(kv.regen_pct) or 4) * 0.01)
	self:SetStackCount(math.floor(self.shield))
	if IsServer() then self:StartIntervalThink(0.25) end
end
function modifier_xhs_rune_barrier:OnRefresh(kv) self:OnCreated(kv) end
function modifier_xhs_rune_barrier:GetTexture() return "roshan_spell_block" end
function modifier_xhs_rune_barrier:OnIntervalThink()
	self.shield = math.min(self.max_shield, self.shield + self.regen_per_second * 0.25)
	self:SetStackCount(math.floor(self.shield))
end
function modifier_xhs_rune_barrier:AbsorbDamage(damage)
	damage = tonumber(damage) or 0
	if damage <= 0 or self.shield <= 0 then return damage end

	local absorbed = math.min(damage, self.shield)
	self.shield = self.shield - absorbed
	self:SetStackCount(math.floor(self.shield))
	return damage - absorbed
end

modifier_xhs_rune_retaliation = modifier_xhs_rune_retaliation or class({})
function modifier_xhs_rune_retaliation:OnCreated(kv)
	kv = kv or {}
	self.reflect_pct = tonumber(kv.reflect_pct) or 25
end
function modifier_xhs_rune_retaliation:OnRefresh(kv) self:OnCreated(kv) end
function modifier_xhs_rune_retaliation:GetTexture() return "blade_mail" end
function modifier_xhs_rune_retaliation:DeclareFunctions() return { MODIFIER_EVENT_ON_TAKEDAMAGE } end
function modifier_xhs_rune_retaliation:OnTakeDamage(params)
	if not IsServer() or _G.XHS_RUNE_REFLECTING == true then return end
	if params.unit ~= self:GetParent() then return end
	if params.attacker == nil or params.attacker:IsNull() or params.attacker:GetTeamNumber() == self:GetParent():GetTeamNumber() then return end
	if params.attacker:IsBuilding() or (params.damage or 0) <= 0 then return end

	_G.XHS_RUNE_REFLECTING = true
	ApplyDamage({
		attacker = self:GetParent(),
		victim = params.attacker,
		damage = params.damage * self.reflect_pct * 0.01,
		damage_type = params.damage_type or DAMAGE_TYPE_PURE,
		damage_flags = DOTA_DAMAGE_FLAG_REFLECTION,
	})
	_G.XHS_RUNE_REFLECTING = nil
end

modifier_xhs_rune_bulwark = modifier_xhs_rune_bulwark or class({})
function modifier_xhs_rune_bulwark:OnCreated(kv)
	kv = kv or {}
	self.armor = tonumber(kv.armor) or 35
	self.magic_resist = tonumber(kv.magic_resist) or 25
end
function modifier_xhs_rune_bulwark:OnRefresh(kv) self:OnCreated(kv) end
function modifier_xhs_rune_bulwark:GetTexture() return "dragon_knight_dragon_blood" end
function modifier_xhs_rune_bulwark:DeclareFunctions() return { MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS, MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS } end
function modifier_xhs_rune_bulwark:GetModifierPhysicalArmorBonus() return self.armor or 0 end
function modifier_xhs_rune_bulwark:GetModifierMagicalResistanceBonus() return self.magic_resist or 0 end

modifier_xhs_rune_fortitude = modifier_xhs_rune_fortitude or class({})
function modifier_xhs_rune_fortitude:OnCreated(kv)
	kv = kv or {}
	self.status_resist = tonumber(kv.status_resist) or 35
	self.damage_reduction = tonumber(kv.damage_reduction) or 20
end
function modifier_xhs_rune_fortitude:OnRefresh(kv) self:OnCreated(kv) end
function modifier_xhs_rune_fortitude:GetTexture() return "omniknight_guardian_angel" end
function modifier_xhs_rune_fortitude:DeclareFunctions() return { MODIFIER_PROPERTY_STATUS_RESISTANCE_STACKING, MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE } end
function modifier_xhs_rune_fortitude:GetModifierStatusResistanceStacking() return self.status_resist or 0 end
function modifier_xhs_rune_fortitude:GetModifierIncomingDamage_Percentage() return -(self.damage_reduction or 0) end

modifier_xhs_rune_titan = modifier_xhs_rune_titan or class({})
function modifier_xhs_rune_titan:OnCreated(kv)
	kv = kv or {}
	self.model_scale = tonumber(kv.model_scale) or 18
	self.max_hp_pct = tonumber(kv.max_hp_pct) or 30
	self.outgoing_damage = tonumber(kv.outgoing_damage) or 25
	self.health_bonus = self:GetParent():GetMaxHealth() * self.max_hp_pct * 0.01
	if IsServer() then self:GetParent():CalculateStatBonus(true) end
end
function modifier_xhs_rune_titan:OnRefresh(kv) self:OnCreated(kv) end
function modifier_xhs_rune_titan:GetTexture() return "tiny_grow" end
function modifier_xhs_rune_titan:DeclareFunctions() return { MODIFIER_PROPERTY_MODEL_SCALE, MODIFIER_PROPERTY_HEALTH_BONUS, MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE } end
function modifier_xhs_rune_titan:GetModifierModelScale() return self.model_scale or 0 end
function modifier_xhs_rune_titan:GetModifierHealthBonus() return self.health_bonus or 0 end
function modifier_xhs_rune_titan:GetModifierDamageOutgoing_Percentage() return self.outgoing_damage or 0 end
function modifier_xhs_rune_titan:OnDestroy()
	if IsServer() then self:GetParent():CalculateStatBonus(true) end
end

modifier_xhs_rune_fury = modifier_xhs_rune_fury or class({})
function modifier_xhs_rune_fury:OnCreated(kv)
	kv = kv or {}
	self.attack_speed = tonumber(kv.attack_speed) or 160
	self.spell_amp = tonumber(kv.spell_amp) or 25
end
function modifier_xhs_rune_fury:OnRefresh(kv) self:OnCreated(kv) end
function modifier_xhs_rune_fury:GetTexture() return "rune_haste" end
function modifier_xhs_rune_fury:DeclareFunctions() return { MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT, MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE } end
function modifier_xhs_rune_fury:GetModifierAttackSpeedBonus_Constant() return self.attack_speed or 0 end
function modifier_xhs_rune_fury:GetModifierSpellAmplify_Percentage() return self.spell_amp or 0 end

modifier_xhs_rune_siegebreaker = modifier_xhs_rune_siegebreaker or class({})
function modifier_xhs_rune_siegebreaker:OnCreated(kv)
	kv = kv or {}
	self.bonus_damage = tonumber(kv.bonus_damage) or 45
end
function modifier_xhs_rune_siegebreaker:OnRefresh(kv) self:OnCreated(kv) end
function modifier_xhs_rune_siegebreaker:GetTexture() return "sven_gods_strength" end
function modifier_xhs_rune_siegebreaker:DeclareFunctions() return { MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE } end
function modifier_xhs_rune_siegebreaker:GetModifierTotalDamageOutgoing_Percentage(params)
	local target = params.target
	if target == nil or target:IsNull() or target:IsBuilding() then return 0 end
	if target:IsCreep() or target:IsSummoned() or target:IsConsideredHero() then
		return self.bonus_damage or 0
	end
	return 0
end

modifier_xhs_rune_storm = modifier_xhs_rune_storm or class({})
function modifier_xhs_rune_storm:IsHidden() return false end
function modifier_xhs_rune_storm:IsDebuff() return false end
function modifier_xhs_rune_storm:IsPurgable() return false end
function modifier_xhs_rune_storm:IsPurgeException() return false end
function modifier_xhs_rune_storm:OnCreated(kv)
	kv = kv or {}
	self.interval = tonumber(kv.interval) or 1.2
	self.radius = tonumber(kv.radius) or 650
	self.targets = tonumber(kv.targets) or 4
	self.damage = tonumber(kv.damage) or 550
	if IsServer() then self:StartIntervalThink(self.interval) end
end
function modifier_xhs_rune_storm:OnRefresh(kv) self:OnCreated(kv) end
function modifier_xhs_rune_storm:GetTexture() return "zuus_arc_lightning" end
function modifier_xhs_rune_storm:GetEffectName() return "particles/units/heroes/hero_stormspirit/stormspirit_overload_ambient.vpcf" end
function modifier_xhs_rune_storm:GetEffectAttachType() return PATTACH_ABSORIGIN_FOLLOW end
function modifier_xhs_rune_storm:DeclareFunctions() return { MODIFIER_PROPERTY_TOOLTIP } end
function modifier_xhs_rune_storm:OnTooltip() return self.damage or 0 end
function modifier_xhs_rune_storm:OnIntervalThink()
	local parent = self:GetParent()
	local enemies = FindUnitsInRadius(parent:GetTeamNumber(), parent:GetAbsOrigin(), nil, self.radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_CLOSEST, false)
	local count = 0
	for _, enemy in pairs(enemies) do
		if enemy ~= nil and not enemy:IsNull() and not enemy:IsBuilding() then
			count = count + 1
			local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_zuus/zuus_arc_lightning.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent)
			ParticleManager:SetParticleControlEnt(particle, 0, parent, PATTACH_POINT_FOLLOW, "attach_hitloc", parent:GetAbsOrigin(), true)
			ParticleManager:SetParticleControlEnt(particle, 1, enemy, PATTACH_POINT_FOLLOW, "attach_hitloc", enemy:GetAbsOrigin(), true)
			ParticleManager:ReleaseParticleIndex(particle)
			ApplyDamage({ attacker = parent, victim = enemy, damage = self.damage, damage_type = DAMAGE_TYPE_MAGICAL })
			if count >= self.targets then return end
		end
	end
end

modifier_xhs_rune_bounty_surge = modifier_xhs_rune_bounty_surge or class({})
function modifier_xhs_rune_bounty_surge:OnCreated(kv)
	kv = kv or {}
	self.bounty_pct = tonumber(kv.bounty_pct) or 35
	self.min_total = tonumber(kv.min_total) or 15
end
function modifier_xhs_rune_bounty_surge:OnRefresh(kv) self:OnCreated(kv) end
function modifier_xhs_rune_bounty_surge:GetTexture() return "bounty_hunter_track" end

modifier_xhs_rune_momentum = modifier_xhs_rune_momentum or class({})
function modifier_xhs_rune_momentum:OnCreated(kv)
	kv = kv or {}
	self.move_speed = tonumber(kv.move_speed) or 18
	self.gold_pct = tonumber(kv.gold_pct) or 20
	self.xp_pct = tonumber(kv.xp_pct) or 20
end
function modifier_xhs_rune_momentum:OnRefresh(kv) self:OnCreated(kv) end
function modifier_xhs_rune_momentum:GetTexture() return "rune_haste" end
function modifier_xhs_rune_momentum:DeclareFunctions() return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE } end
function modifier_xhs_rune_momentum:GetModifierMoveSpeedBonus_Percentage() return self.move_speed or 0 end

ApplyVisibleRuneModifierDefaults(modifier_xhs_rune_healing)
ApplyVisibleRuneModifierDefaults(modifier_xhs_rune_revitalization)
ApplyVisibleRuneModifierDefaults(modifier_xhs_rune_second_wind)
ApplyVisibleRuneModifierDefaults(modifier_xhs_rune_second_wind_heal)
ApplyVisibleRuneModifierDefaults(modifier_xhs_rune_second_wind_guard)
ApplyVisibleRuneModifierDefaults(modifier_xhs_rune_barrier)
ApplyVisibleRuneModifierDefaults(modifier_xhs_rune_retaliation)
ApplyVisibleRuneModifierDefaults(modifier_xhs_rune_bulwark)
ApplyVisibleRuneModifierDefaults(modifier_xhs_rune_fortitude)
ApplyVisibleRuneModifierDefaults(modifier_xhs_rune_titan)
ApplyVisibleRuneModifierDefaults(modifier_xhs_rune_fury)
ApplyVisibleRuneModifierDefaults(modifier_xhs_rune_siegebreaker)
ApplyVisibleRuneModifierDefaults(modifier_xhs_rune_storm)
ApplyVisibleRuneModifierDefaults(modifier_xhs_rune_bounty_surge)
ApplyVisibleRuneModifierDefaults(modifier_xhs_rune_momentum)
