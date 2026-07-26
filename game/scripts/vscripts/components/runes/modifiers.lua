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
modifier_xhs_rune_healing.XHS_LINK_CLIENT = true
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
modifier_xhs_rune_revitalization.XHS_LINK_CLIENT = true
function modifier_xhs_rune_revitalization:OnCreated(kv)
	kv = kv or {}
	self.cooldown_reduction_pct = tonumber(kv.cooldown_reduction_pct) or 30
end
function modifier_xhs_rune_revitalization:OnRefresh(kv) self:OnCreated(kv) end
function modifier_xhs_rune_revitalization:GetTexture() return "rune_arcane" end
function modifier_xhs_rune_revitalization:DeclareFunctions() return { MODIFIER_PROPERTY_COOLDOWN_PERCENTAGE } end
function modifier_xhs_rune_revitalization:GetModifierPercentageCooldown() return self.cooldown_reduction_pct or 0 end

modifier_xhs_rune_restoration = modifier_xhs_rune_restoration or class({})
modifier_xhs_rune_restoration.XHS_LINK_CLIENT = true
function modifier_xhs_rune_restoration:OnCreated(kv)
	kv = kv or {}
	self.restored_pct = tonumber(kv.restored_pct) or 35
end
function modifier_xhs_rune_restoration:OnRefresh(kv) self:OnCreated(kv) end
function modifier_xhs_rune_restoration:GetTexture() return "rune_regen" end
function modifier_xhs_rune_restoration:DeclareFunctions() return { MODIFIER_PROPERTY_TOOLTIP } end
function modifier_xhs_rune_restoration:OnTooltip() return self.restored_pct or 35 end

modifier_xhs_rune_second_wind = modifier_xhs_rune_second_wind or class({})
modifier_xhs_rune_second_wind.XHS_LINK_CLIENT = true
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
function modifier_xhs_rune_second_wind:DeclareFunctions()
	return { MODIFIER_PROPERTY_TOOLTIP, MODIFIER_PROPERTY_TOOLTIP2 }
end
function modifier_xhs_rune_second_wind:OnTooltip() return self.threshold_pct or 30 end
function modifier_xhs_rune_second_wind:OnTooltip2() return self.guard_reduction or 20 end
function modifier_xhs_rune_second_wind:OnIntervalThink()
	if self.consumed then return end

	local parent = self:GetParent()
	if parent == nil or parent:IsNull() or not parent:IsAlive() then return end

	if parent:GetHealth() > parent:GetMaxHealth() * self.threshold_pct * 0.01 then return end

	self.consumed = true
	self:SetStackCount(0)
	local healBurst = ParticleManager:CreateParticle("particles/units/heroes/hero_abaddon/abaddon_borrowed_time_heal.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent)
	ParticleManager:ReleaseParticleIndex(healBurst)
	local impact = ParticleManager:CreateParticle("particles/units/heroes/hero_abaddon/abaddon_aphotic_shield_explosion.vpcf", PATTACH_ABSORIGIN, parent)
	ParticleManager:SetParticleControl(impact, 0, parent:GetAbsOrigin())
	ParticleManager:ReleaseParticleIndex(impact)
	parent:EmitSound("Hero_Abaddon.BorrowedTime")
	parent:EmitSound("Hero_Abaddon.AphoticShield.Cast")
	parent:AddNewModifier(parent, nil, "modifier_xhs_rune_second_wind_heal", { duration = self.recovery_duration, recovery_duration = self.recovery_duration, heal_pct = self.heal_pct, mana_pct = self.mana_pct })
	parent:AddNewModifier(parent, nil, "modifier_xhs_rune_second_wind_guard", { duration = self.guard_duration, guard_reduction = self.guard_reduction })
	self:Destroy()
end

modifier_xhs_rune_second_wind_heal = modifier_xhs_rune_second_wind_heal or class({})
modifier_xhs_rune_second_wind_heal.XHS_LINK_CLIENT = true
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
modifier_xhs_rune_second_wind_guard.XHS_LINK_CLIENT = true
function modifier_xhs_rune_second_wind_guard:OnCreated(kv)
	kv = kv or {}
	self.guard_reduction = tonumber(kv.guard_reduction) or 20
	if IsServer() then
		local guard_particle = ParticleManager:CreateParticle("particles/units/heroes/hero_abaddon/holdout_borrowed_time_4.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
		ParticleManager:SetParticleControl(guard_particle, 1, Vector(1.35, 0, 0))
		self:AddParticle(guard_particle, false, false, -1, false, false)
	end
end
function modifier_xhs_rune_second_wind_guard:OnRefresh(kv) self:OnCreated(kv) end
function modifier_xhs_rune_second_wind_guard:GetTexture() return "abaddon_borrowed_time" end
function modifier_xhs_rune_second_wind_guard:DeclareFunctions() return { MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE } end
function modifier_xhs_rune_second_wind_guard:GetModifierIncomingDamage_Percentage() return -(self.guard_reduction or 0) end

modifier_xhs_rune_barrier = modifier_xhs_rune_barrier or class({})
modifier_xhs_rune_barrier.XHS_LINK_CLIENT = true
function modifier_xhs_rune_barrier:OnCreated(kv)
	kv = kv or {}
	self.max_shield = self:GetParent():GetMaxHealth() * ((tonumber(kv.shield_pct) or 25) * 0.01)
	self.shield = self.max_shield
	self.health_regen = self:GetParent():GetMaxHealth() * ((tonumber(kv.health_regen_pct) or tonumber(kv.regen_pct) or 4) * 0.01)
	if IsServer() then
		self:SetHasCustomTransmitterData(true)
		self:RefreshShieldVisual()
		self:UpdateShieldState()
	end
end
function modifier_xhs_rune_barrier:OnRefresh(kv) self:OnCreated(kv) end
function modifier_xhs_rune_barrier:GetTexture() return "roshan_spell_block" end
function modifier_xhs_rune_barrier:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_INCOMING_DAMAGE_CONSTANT,
		MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
		MODIFIER_PROPERTY_TOOLTIP,
		MODIFIER_PROPERTY_TOOLTIP2,
	}
end
function modifier_xhs_rune_barrier:AddCustomTransmitterData()
	return {
		shield = self.shield or 0,
		max_shield = self.max_shield or 0,
		health_regen = self.health_regen or 0,
	}
end
function modifier_xhs_rune_barrier:HandleCustomTransmitterData(data)
	self.shield = data.shield or 0
	self.max_shield = data.max_shield or 0
	self.health_regen = data.health_regen or 0
end
function modifier_xhs_rune_barrier:UpdateShieldState()
	self:SetStackCount(math.floor(self.shield or 0))
	self:SendBuffRefreshToClients()
end
function modifier_xhs_rune_barrier:RefreshShieldVisual()
	if not IsServer() then return end
	if (self.shield or 0) > 0 and self.shield_particle == nil then
		local parent = self:GetParent()
		self.shield_particle = ParticleManager:CreateParticle("particles/neutral_fx/miniboss_shield.vpcf", PATTACH_POINT_FOLLOW, parent)
		ParticleManager:SetParticleControlEnt(self.shield_particle, 0, parent, PATTACH_POINT_FOLLOW, "attach_hitloc", parent:GetAbsOrigin(), true)
	elseif (self.shield or 0) <= 0 and self.shield_particle ~= nil then
		ParticleManager:DestroyParticle(self.shield_particle, true)
		ParticleManager:ReleaseParticleIndex(self.shield_particle)
		self.shield_particle = nil
	end
end
function modifier_xhs_rune_barrier:PlayShieldImpact()
	local parent = self:GetParent()
	local particle = ParticleManager:CreateParticle("particles/neutral_fx/miniboss_damage_impact.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent)
	ParticleManager:SetParticleControlEnt(particle, 0, parent, PATTACH_POINT_FOLLOW, "attach_hitloc", parent:GetAbsOrigin(), true)
	ParticleManager:ReleaseParticleIndex(particle)

	local now = GameRules:GetGameTime()
	if (self.next_impact_sound or 0) <= now then
		parent:EmitSound("Miniboss.Tormenter.Target")
		self.next_impact_sound = now + 0.12
	end
end
function modifier_xhs_rune_barrier:GetModifierIncomingDamageConstant(event)
	if not IsServer() then return self.shield or 0 end

	local damage = tonumber(event.damage) or 0
	if damage <= 0 or (self.shield or 0) <= 0 then return 0 end

	local absorbed = math.min(damage, self.shield)
	self.shield = self.shield - absorbed
	self:PlayShieldImpact()
	self:RefreshShieldVisual()
	self:UpdateShieldState()
	return -absorbed
end
function modifier_xhs_rune_barrier:OnTooltip() return math.floor(self.shield or 0) end
function modifier_xhs_rune_barrier:OnTooltip2() return math.floor(self.health_regen or 0) end
function modifier_xhs_rune_barrier:GetModifierConstantHealthRegen() return self.health_regen or 0 end
function modifier_xhs_rune_barrier:OnDestroy()
	if not IsServer() or self.shield_particle == nil then return end
	ParticleManager:DestroyParticle(self.shield_particle, true)
	ParticleManager:ReleaseParticleIndex(self.shield_particle)
	self.shield_particle = nil
end

modifier_xhs_rune_retaliation = modifier_xhs_rune_retaliation or class({})
modifier_xhs_rune_retaliation.XHS_LINK_CLIENT = true
function modifier_xhs_rune_retaliation:OnCreated(kv)
	kv = kv or {}
	self.reflect_pct = tonumber(kv.reflect_pct) or 25
end
function modifier_xhs_rune_retaliation:OnRefresh(kv) self:OnCreated(kv) end
function modifier_xhs_rune_retaliation:GetTexture() return "blade_mail" end
function modifier_xhs_rune_retaliation:GetEffectName() return "particles/items_fx/blademail.vpcf" end
function modifier_xhs_rune_retaliation:GetEffectAttachType() return PATTACH_ABSORIGIN_FOLLOW end
function modifier_xhs_rune_retaliation:DeclareFunctions()
	return { MODIFIER_EVENT_ON_TAKEDAMAGE, MODIFIER_PROPERTY_TOOLTIP }
end
function modifier_xhs_rune_retaliation:OnTooltip() return self.reflect_pct or 25 end
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
	local returnFx = ParticleManager:CreateParticle("particles/units/heroes/hero_centaur/centaur_return.vpcf", PATTACH_ABSORIGIN, self:GetParent())
	ParticleManager:SetParticleControlEnt(returnFx, 0, self:GetParent(), PATTACH_POINT_FOLLOW, "attach_hitloc", self:GetParent():GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(returnFx, 1, params.attacker, PATTACH_POINT_FOLLOW, "attach_hitloc", params.attacker:GetAbsOrigin(), true)
	ParticleManager:ReleaseParticleIndex(returnFx)
	_G.XHS_RUNE_REFLECTING = nil
end

modifier_xhs_rune_bulwark = modifier_xhs_rune_bulwark or class({})
modifier_xhs_rune_bulwark.XHS_LINK_CLIENT = true
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
modifier_xhs_rune_fortitude.XHS_LINK_CLIENT = true
function modifier_xhs_rune_fortitude:OnCreated(kv)
	kv = kv or {}
	self.status_resist = tonumber(kv.status_resist) or 35
	self.damage_reduction = tonumber(kv.damage_reduction) or 20
end
function modifier_xhs_rune_fortitude:OnRefresh(kv) self:OnCreated(kv) end
function modifier_xhs_rune_fortitude:GetTexture() return "omniknight_guardian_angel" end
function modifier_xhs_rune_fortitude:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_STATUS_RESISTANCE_STACKING,
		MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
		MODIFIER_PROPERTY_TOOLTIP,
	}
end
function modifier_xhs_rune_fortitude:GetModifierStatusResistanceStacking() return self.status_resist or 0 end
function modifier_xhs_rune_fortitude:GetModifierIncomingDamage_Percentage() return -(self.damage_reduction or 0) end
function modifier_xhs_rune_fortitude:OnTooltip() return self.damage_reduction or 0 end

modifier_xhs_rune_titan = modifier_xhs_rune_titan or class({})
modifier_xhs_rune_titan.XHS_LINK_CLIENT = true
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
function modifier_xhs_rune_titan:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MODEL_SCALE,
		MODIFIER_PROPERTY_HEALTH_BONUS,
		MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE,
		MODIFIER_PROPERTY_TOOLTIP,
	}
end
function modifier_xhs_rune_titan:GetModifierModelScale() return self.model_scale or 0 end
function modifier_xhs_rune_titan:GetModifierHealthBonus() return self.health_bonus or 0 end
function modifier_xhs_rune_titan:GetModifierDamageOutgoing_Percentage() return self.outgoing_damage or 0 end
function modifier_xhs_rune_titan:OnTooltip() return self.max_hp_pct or 30 end
function modifier_xhs_rune_titan:OnDestroy()
	if IsServer() then self:GetParent():CalculateStatBonus(true) end
end

modifier_xhs_rune_fury = modifier_xhs_rune_fury or class({})
modifier_xhs_rune_fury.XHS_LINK_CLIENT = true
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
modifier_xhs_rune_siegebreaker.XHS_LINK_CLIENT = true
function modifier_xhs_rune_siegebreaker:OnCreated(kv)
	kv = kv or {}
	self.bonus_damage = tonumber(kv.bonus_damage) or 45
end
function modifier_xhs_rune_siegebreaker:OnRefresh(kv) self:OnCreated(kv) end
function modifier_xhs_rune_siegebreaker:GetTexture() return "sven_gods_strength" end
function modifier_xhs_rune_siegebreaker:DeclareFunctions()
	return { MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE, MODIFIER_PROPERTY_TOOLTIP }
end
function modifier_xhs_rune_siegebreaker:OnTooltip() return self.bonus_damage or 45 end
function modifier_xhs_rune_siegebreaker:GetModifierTotalDamageOutgoing_Percentage(params)
	local target = params.target
	if target == nil or target:IsNull() or target:IsBuilding() then return 0 end
	if target:IsCreep() or target:IsSummoned() or target:IsConsideredHero() then
		return self.bonus_damage or 0
	end
	return 0
end

modifier_xhs_rune_storm = modifier_xhs_rune_storm or class({})
modifier_xhs_rune_storm.XHS_LINK_CLIENT = true
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
function modifier_xhs_rune_storm:OnTooltip()
	local parent = self:GetParent()
	if parent ~= nil and not parent:IsNull() and parent.GetAttackDamage ~= nil then
		return math.floor(parent:GetAttackDamage())
	end
	return self.damage or 0
end
function modifier_xhs_rune_storm:OnIntervalThink()
	local parent = self:GetParent()
	local enemies = FindUnitsInRadius(parent:GetTeamNumber(), parent:GetAbsOrigin(), nil, self.radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_CLOSEST, false)
	local count = 0
	for _, enemy in pairs(enemies) do
		if enemy ~= nil and not enemy:IsNull() and not enemy:IsBuilding() then
			count = count + 1
			if count == 1 then
				parent:EmitSoundParams("Hero_Zuus.ArcLightning.Cast", 0, 0.7, 0)
			end
			local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_zuus/zuus_arc_lightning.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent)
			ParticleManager:SetParticleControlEnt(particle, 0, parent, PATTACH_POINT_FOLLOW, "attach_hitloc", parent:GetAbsOrigin(), true)
			ParticleManager:SetParticleControlEnt(particle, 1, enemy, PATTACH_POINT_FOLLOW, "attach_hitloc", enemy:GetAbsOrigin(), true)
			ParticleManager:ReleaseParticleIndex(particle)
			local physicalDamage = self.damage
			if parent.GetAverageTrueAttackDamage ~= nil then
				physicalDamage = parent:GetAverageTrueAttackDamage(parent)
			elseif parent.GetAttackDamage ~= nil then
				physicalDamage = parent:GetAttackDamage()
			end
			ApplyDamage({ attacker = parent, victim = enemy, damage = physicalDamage, damage_type = DAMAGE_TYPE_PHYSICAL })
			if count >= self.targets then return end
		end
	end
end

modifier_xhs_rune_bounty_surge = modifier_xhs_rune_bounty_surge or class({})
modifier_xhs_rune_bounty_surge.XHS_LINK_CLIENT = true
function modifier_xhs_rune_bounty_surge:OnCreated(kv)
	kv = kv or {}
	self.bounty_pct = tonumber(kv.bounty_pct) or 35
	self.min_total = tonumber(kv.min_total) or 15
end
function modifier_xhs_rune_bounty_surge:OnRefresh(kv) self:OnCreated(kv) end
function modifier_xhs_rune_bounty_surge:GetTexture() return "bounty_hunter_track" end
function modifier_xhs_rune_bounty_surge:DeclareFunctions() return { MODIFIER_PROPERTY_TOOLTIP } end
function modifier_xhs_rune_bounty_surge:OnTooltip() return self.bounty_pct or 35 end

modifier_xhs_rune_momentum = modifier_xhs_rune_momentum or class({})
modifier_xhs_rune_momentum.XHS_LINK_CLIENT = true
function modifier_xhs_rune_momentum:OnCreated(kv)
	kv = kv or {}
	self.move_speed = tonumber(kv.move_speed) or 18
	self.gold_pct = tonumber(kv.gold_pct) or 20
	self.xp_pct = tonumber(kv.xp_pct) or 20
end
function modifier_xhs_rune_momentum:OnRefresh(kv) self:OnCreated(kv) end
function modifier_xhs_rune_momentum:GetTexture() return "rune_haste" end
function modifier_xhs_rune_momentum:DeclareFunctions()
	return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE, MODIFIER_PROPERTY_TOOLTIP }
end
function modifier_xhs_rune_momentum:GetModifierMoveSpeedBonus_Percentage() return self.move_speed or 0 end
function modifier_xhs_rune_momentum:OnTooltip() return self.gold_pct or 20 end

ApplyVisibleRuneModifierDefaults(modifier_xhs_rune_healing)
ApplyVisibleRuneModifierDefaults(modifier_xhs_rune_revitalization)
ApplyVisibleRuneModifierDefaults(modifier_xhs_rune_restoration)
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
