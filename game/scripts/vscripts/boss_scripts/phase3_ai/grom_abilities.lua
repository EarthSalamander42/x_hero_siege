require("boss_scripts/phase3_ai/core")
require("boss_scripts/phase3_ai/telegraphs")
require("boss_scripts/phase3_ai/cast_bar")

xhs_grom_mirror_trial = xhs_grom_mirror_trial or class({})
xhs_grom_blade_storm = xhs_grom_blade_storm or class({})
xhs_grom_mirror_cleave = xhs_grom_mirror_cleave or class({})
xhs_grom_windwalk_ambush = xhs_grom_windwalk_ambush or class({})
xhs_grom_warsong_leap = xhs_grom_warsong_leap or class({})
xhs_grom_blood_frenzy = xhs_grom_blood_frenzy or class({})

LinkLuaModifier("modifier_xhs_grom_blood_frenzy", "boss_scripts/phase3_ai/grom_abilities.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_xhs_grom_slow", "boss_scripts/phase3_ai/grom_abilities.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_xhs_grom_blade_storm", "boss_scripts/phase3_ai/grom_abilities.lua", LUA_MODIFIER_MOTION_NONE)

modifier_xhs_grom_blood_frenzy = modifier_xhs_grom_blood_frenzy or class({})
modifier_xhs_grom_blood_frenzy.XHS_LINK_CLIENT = true
modifier_xhs_grom_slow = modifier_xhs_grom_slow or class({})
modifier_xhs_grom_slow.XHS_LINK_CLIENT = true
modifier_xhs_grom_blade_storm = modifier_xhs_grom_blade_storm or class({})
modifier_xhs_grom_blade_storm.XHS_LINK_CLIENT = true

local GROM_COLORS = {
	primary = Vector(255, 62, 34),
	secondary = Vector(255, 185, 64),
	style = 4,
}

local GROM_TEXTURES = {
	mirror_trial = "custom/xhs_grom_mirror_trial",
	blade_storm = "custom/xhs_grom_blade_storm",
	mirror_cleave = "custom/xhs_grom_mirror_cleave",
	windwalk_ambush = "custom/xhs_grom_windwalk_ambush",
	warsong_leap = "custom/xhs_grom_warsong_leap",
	blood_frenzy = "custom/xhs_grom_blood_frenzy",
}

local MIRROR_TRIAL_PARTICLE = "particles/units/heroes/hero_chaos_knight/chaos_knight_phantasm.vpcf"
local CLEAVE_PARTICLE = "particles/econ/items/faceless_void/faceless_void_weapon_bfury/faceless_void_weapon_bfury_cleave.vpcf"
local BLADE_STORM_PARTICLE = "particles/units/heroes/hero_juggernaut/juggernaut_blade_fury.vpcf"
local BLADE_STORM_NULL_PARTICLE = "particles/units/heroes/hero_juggernaut/juggernaut_blade_fury_null.vpcf"
local BLADE_STORM_HIT_PARTICLE = "particles/units/heroes/hero_juggernaut/juggernaut_blade_fury_tgt.vpcf"
local WINDWALK_START_PARTICLE = "particles/items_fx/blink_dagger_start.vpcf"
local WINDWALK_END_PARTICLE = "particles/items_fx/blink_dagger_end.vpcf"
local WARSONG_LEAP_PARTICLE = "particles/units/heroes/hero_ursa/ursa_earthshock.vpcf"

local function IsValidAlive(unit)
	return unit ~= nil and IsValidEntity(unit) and not unit:IsNull() and unit:IsAlive()
end

local function PickClosestGromArenaHero(caster)
	if not IsValidAlive(caster) then return nil end

	local arenaCenter = caster:GetAbsOrigin()
	local arenaSpawner = Entities:FindByName(nil, "spawn_grom_hellscream")
	if arenaSpawner ~= nil then
		arenaCenter = arenaSpawner:GetAbsOrigin()
	end

	local closest = nil
	local closestDistance = nil
	for _, hero in pairs(XHSPhase3BossAI:GetLivingHeroes(arenaCenter, 2200, true)) do
		if IsValidAlive(hero) then
			local distance = (hero:GetAbsOrigin() - caster:GetAbsOrigin()):Length2D()
			if closestDistance == nil or distance < closestDistance then
				closest = hero
				closestDistance = distance
			end
		end
	end

	return closest
end

local function GetContext(ability)
	return ability.xhs_grom_context or {}
end

local function ClearContext(ability)
	ability.xhs_grom_context = nil
end

local function StartBossCastBar(ability, displayName)
	if XHSBossCastBar ~= nil then
		XHSBossCastBar:Start(ability:GetCaster(), ability, {
			display_name = displayName,
			style = "grom",
		})
	end
end

local function HideBossCastBar(ability)
	if XHSBossCastBar ~= nil then
		XHSBossCastBar:Hide(ability:GetCaster())
	end
end

local function ScaleDamage(value)
	if XHSPhase3BossAI ~= nil and XHSPhase3BossAI.ScaleDamage ~= nil then
		return XHSPhase3BossAI:ScaleDamage(value)
	end

	return value or 0
end

local function DamageEnemies(caster, ability, position, radius, damage, damageType, onHit)
	if not IsValidAlive(caster) then return end

	local enemies = FindUnitsInRadius(
		caster:GetTeamNumber(),
		position,
		nil,
		radius,
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
		FIND_ANY_ORDER,
		false
	)

	for _, enemy in pairs(enemies) do
		if IsValidAlive(enemy) and not enemy:IsInvulnerable() then
			ApplyDamage({
				victim = enemy,
				attacker = caster,
				ability = ability,
				damage = damage,
				damage_type = damageType or ability:GetAbilityDamageType(),
			})
			if onHit ~= nil then
				onHit(enemy)
			end
		end
	end
end

local function DamageLine(caster, ability, startPosition, direction, length, width, damage, damageType)
	if not IsValidAlive(caster) then return end

	direction.z = 0
	if direction:Length2D() <= 0 then direction = Vector(1, 0, 0) end
	direction = direction:Normalized()

	local endPosition = startPosition + direction * length
	local enemies = FindUnitsInLine(
		caster:GetTeamNumber(),
		startPosition,
		endPosition,
		nil,
		width,
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES
	)

	for _, enemy in pairs(enemies) do
		if IsValidAlive(enemy) and not enemy:IsInvulnerable() then
			ApplyDamage({
				victim = enemy,
				attacker = caster,
				ability = ability,
				damage = damage,
				damage_type = damageType or ability:GetAbilityDamageType(),
			})
		end
	end
end

local function CreateLineParticle(startPosition, direction, length, particleName, duration)
	direction.z = 0
	if direction:Length2D() <= 0 then direction = Vector(1, 0, 0) end
	direction = direction:Normalized()

	local particle = ParticleManager:CreateParticle(particleName, PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleControl(particle, 0, startPosition)
	ParticleManager:SetParticleControl(particle, 1, startPosition + direction * length)
	ParticleManager:SetParticleControl(particle, 2, Vector(duration or 0.55, 0, 0))
	Timers:CreateTimer(math.max(0.1, duration or 0.55) + 0.15, function()
		ParticleManager:DestroyParticle(particle, false)
		ParticleManager:ReleaseParticleIndex(particle)
		return nil
	end)
end

local function CreateWorldParticle(position, particleName, duration)
	local particle = ParticleManager:CreateParticle(particleName, PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleControl(particle, 0, position)
	Timers:CreateTimer(math.max(0.1, duration or 1.2), function()
		ParticleManager:DestroyParticle(particle, false)
		ParticleManager:ReleaseParticleIndex(particle)
		return nil
	end)
end

function xhs_grom_mirror_trial:GetAbilityTextureName() return GROM_TEXTURES.mirror_trial end
function xhs_grom_blade_storm:GetAbilityTextureName() return GROM_TEXTURES.blade_storm end
function xhs_grom_mirror_cleave:GetAbilityTextureName() return GROM_TEXTURES.mirror_cleave end
function xhs_grom_windwalk_ambush:GetAbilityTextureName() return GROM_TEXTURES.windwalk_ambush end
function xhs_grom_warsong_leap:GetAbilityTextureName() return GROM_TEXTURES.warsong_leap end
function xhs_grom_blood_frenzy:GetAbilityTextureName() return GROM_TEXTURES.blood_frenzy end

function xhs_grom_mirror_trial:OnAbilityPhaseStart()
	if not IsServer() then return true end

	local caster = self:GetCaster()
	StartBossCastBar(self, "Mirror Trial")
	StartAnimation(caster, { duration = self:GetCastPoint() + 0.2, activity = ACT_DOTA_CAST_ABILITY_4, rate = 0.9 })
	caster:EmitSound("Hero_ChaosKnight.Phantasm")
	return true
end

function xhs_grom_mirror_trial:OnAbilityPhaseInterrupted()
	if IsServer() then HideBossCastBar(self) end
end

function xhs_grom_mirror_trial:OnSpellStart()
	if not IsServer() then return end

	if XHSGrom_StartMirrorTrial ~= nil then
		XHSGrom_StartMirrorTrial(self:GetCaster(), self)
	end

	local caster = self:GetCaster()
	CreateWorldParticle(caster:GetAbsOrigin(), MIRROR_TRIAL_PARTICLE)
	caster:EmitSound("Hero_ChaosKnight.Phantasm")
	ClearContext(self)
end

function xhs_grom_blade_storm:OnAbilityPhaseStart()
	if not IsServer() then return true end

	local caster = self:GetCaster()
	local radius = self:GetSpecialValueFor("radius")
	StartBossCastBar(self, "Blade Storm")
	XHSBossTelegraphs:Circle(caster:GetAbsOrigin(), radius, self:GetCastPoint(), GROM_COLORS)
	StartAnimation(caster, { duration = self:GetCastPoint() + 0.4, activity = ACT_DOTA_CAST_ABILITY_1, rate = 0.9 })
	caster:EmitSound("Hero_Juggernaut.BladeFuryStart")
	return true
end

function xhs_grom_blade_storm:OnAbilityPhaseInterrupted()
	if IsServer() then HideBossCastBar(self) end
end

function xhs_grom_blade_storm:OnSpellStart()
	if not IsServer() then return end

	local caster = self:GetCaster()
	local radius = self:GetSpecialValueFor("radius")
	local duration = self:GetSpecialValueFor("duration")
	local tick = math.max(0.05, self:GetSpecialValueFor("tick_rate"))
	local damagePerSecond = ScaleDamage(self:GetSpecialValueFor("damage_per_second"))
	local elapsed = 0
	local nextImpactFx = 0

	caster:AddNewModifier(caster, self, "modifier_xhs_grom_blade_storm", { duration = duration })
	local particle = ParticleManager:CreateParticle(BLADE_STORM_PARTICLE, PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleControlEnt(particle, 0, caster, PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", caster:GetAbsOrigin(), true)
	ParticleManager:SetParticleControl(particle, 5, Vector(radius * 1.2, 0, 0))
	local nullParticle = ParticleManager:CreateParticle(BLADE_STORM_NULL_PARTICLE, PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleControlEnt(nullParticle, 0, caster, PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", caster:GetAbsOrigin(), true)
	ParticleManager:SetParticleControl(nullParticle, 1, Vector(radius * 1.2, 0, 0))
	ParticleManager:SetParticleControl(nullParticle, 5, Vector(radius * 1.2, 0, 0))

	Timers:CreateTimer(0, function()
		if not IsValidAlive(caster) then
			ParticleManager:DestroyParticle(particle, true)
			ParticleManager:ReleaseParticleIndex(particle)
			ParticleManager:DestroyParticle(nullParticle, true)
			ParticleManager:ReleaseParticleIndex(nullParticle)
			return nil
		end

		ParticleManager:SetParticleControl(particle, 5, Vector(radius * 1.2, 0, 0))
		ParticleManager:SetParticleControl(nullParticle, 1, Vector(radius * 1.2, 0, 0))
		ParticleManager:SetParticleControl(nullParticle, 5, Vector(radius * 1.2, 0, 0))

		-- Blade Storm is a pursuit window: continuously close the gap with the
		-- nearest living hero using movement-only orders. The active modifier
		-- keeps Grom disarmed, so this can never turn into a basic attack.
		local target = PickClosestGromArenaHero(caster)
		if IsValidAlive(target) then
			caster:SetForceAttackTarget(nil)
			XHSPhase3BossAI:MoveBoss(caster, target:GetAbsOrigin())
		end

		local now = GameRules:GetGameTime()
		DamageEnemies(caster, self, caster:GetAbsOrigin(), radius, damagePerSecond * tick, self:GetAbilityDamageType(), function(enemy)
			if now >= nextImpactFx then
				enemy:EmitSound("Hero_Juggernaut.BladeFury.Impact")
				local hit = ParticleManager:CreateParticle(BLADE_STORM_HIT_PARTICLE, PATTACH_ABSORIGIN_FOLLOW, enemy)
				ParticleManager:SetParticleControlEnt(hit, 0, enemy, PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", enemy:GetAbsOrigin(), true)
				ParticleManager:ReleaseParticleIndex(hit)
			end
		end)
		if now >= nextImpactFx then
			nextImpactFx = now + 0.35
		end
		elapsed = elapsed + tick
		if elapsed < duration then return tick end

		ParticleManager:DestroyParticle(particle, false)
		ParticleManager:ReleaseParticleIndex(particle)
		ParticleManager:DestroyParticle(nullParticle, false)
		ParticleManager:ReleaseParticleIndex(nullParticle)
		caster:RemoveModifierByName("modifier_xhs_grom_blade_storm")
		caster:SetForceAttackTarget(nil)
		caster:Stop()
		EndAnimation(caster)
		caster:StopSound("Hero_Juggernaut.BladeFuryStart")
		caster:EmitSound("Hero_Juggernaut.BladeFuryStop")
		return nil
	end)

	ClearContext(self)
end

function modifier_xhs_grom_blade_storm:IsHidden() return true end
function modifier_xhs_grom_blade_storm:IsPurgable() return false end
function modifier_xhs_grom_blade_storm:CheckState()
	return {
		[MODIFIER_STATE_DISARMED] = true,
		[MODIFIER_STATE_SILENCED] = true,
		[MODIFIER_STATE_MUTED] = true,
	}
end
function modifier_xhs_grom_blade_storm:OnCreated()
	if not IsServer() then return end
	self:GetParent():StartGestureWithPlaybackRate(ACT_DOTA_OVERRIDE_ABILITY_1, 1.0)
end
function modifier_xhs_grom_blade_storm:OnDestroy()
	if not IsServer() then return end
	self:GetParent():FadeGesture(ACT_DOTA_OVERRIDE_ABILITY_1)
end

function xhs_grom_mirror_cleave:OnAbilityPhaseStart()
	if not IsServer() then return true end

	local context = GetContext(self)
	local caster = self:GetCaster()
	local length = self:GetSpecialValueFor("length")
	local width = self:GetSpecialValueFor("width")
	local spacing = math.max(1, width * 1.45)
	local count = math.max(1, math.floor(length / spacing))
	local cleaves = context.cleaves or {}
	if #cleaves == 0 then
		cleaves = {
			{
				start = caster:GetAbsOrigin(),
				direction = caster:GetForwardVector(),
				delay = 0,
				damage_scale = 1.0,
			},
		}
		context.cleaves = cleaves
	end

	StartBossCastBar(self, "Mirror Cleave")
	for _, cleave in ipairs(cleaves) do
		XHSBossTelegraphs:Line(cleave.start, cleave.direction, spacing, width, count, self:GetCastPoint() + (cleave.delay or 0), GROM_COLORS, 120)
	end

	StartAnimation(caster, { duration = self:GetCastPoint() + 0.55, activity = ACT_DOTA_ATTACK_EVENT, rate = 0.75 })
	caster:EmitSound("Hero_Sven.Attack")
	return true
end

function xhs_grom_mirror_cleave:OnAbilityPhaseInterrupted()
	if IsServer() then HideBossCastBar(self) end
end

function xhs_grom_mirror_cleave:OnSpellStart()
	if not IsServer() then return end

	local context = GetContext(self)
	local caster = self:GetCaster()
	local length = self:GetSpecialValueFor("length")
	local width = self:GetSpecialValueFor("width")
	local damage = ScaleDamage(self:GetSpecialValueFor("damage"))
	local cleaves = context.cleaves or {}
	if #cleaves == 0 then
		cleaves = {
			{
				start = caster:GetAbsOrigin(),
				direction = caster:GetForwardVector(),
				delay = 0,
				damage_scale = 1.0,
			},
		}
	end

	for index, cleave in ipairs(cleaves) do
		Timers:CreateTimer(cleave.delay or 0, function()
			if not IsValidAlive(caster) then return nil end
			StartAnimation(caster, { duration = 0.6, activity = ACT_DOTA_ATTACK_EVENT, rate = 1.35 })
			CreateLineParticle(cleave.start, cleave.direction, length, CLEAVE_PARTICLE, 0.65)
			EmitSoundOnLocationWithCaster(cleave.start, "Hero_Sven.GreatCleave", caster)
			DamageLine(caster, self, cleave.start, cleave.direction, length, width, damage * (cleave.damage_scale or 1.0), self:GetAbilityDamageType())
			if index == 1 then
				local direction = cleave.direction
				direction.z = 0
				if direction:Length2D() > 0 then
					local destination = caster:GetAbsOrigin() + direction:Normalized() * math.min(300, length * 0.32)
					FindClearSpaceForUnit(caster, destination, true)
					CreateWorldParticle(destination, WARSONG_LEAP_PARTICLE, 0.7)
				end
			end
			return nil
		end)
	end

	ClearContext(self)
end

function xhs_grom_windwalk_ambush:OnAbilityPhaseStart()
	if not IsServer() then return true end

	local context = GetContext(self)
	local caster = self:GetCaster()
	local target = context.target
	local targetPosition = IsValidAlive(target) and target:GetAbsOrigin() or context.position or caster:GetAbsOrigin()

	StartBossCastBar(self, "Windwalk Ambush")
	XHSBossTelegraphs:Target(targetPosition, self:GetSpecialValueFor("target_radius"), self:GetCastPoint(), GROM_COLORS)
	StartAnimation(caster, { duration = self:GetCastPoint(), activity = ACT_DOTA_CAST_ABILITY_2, rate = 1.0 })
	caster:EmitSound("Hero_Juggernaut.OmniSlash")
	return true
end

function xhs_grom_windwalk_ambush:OnAbilityPhaseInterrupted()
	if IsServer() then HideBossCastBar(self) end
end

function xhs_grom_windwalk_ambush:OnSpellStart()
	if not IsServer() then return end

	local context = GetContext(self)
	local caster = self:GetCaster()
	local target = context.target
	local vanishDelay = self:GetSpecialValueFor("vanish_delay")
	local strikeDelay = self:GetSpecialValueFor("strike_delay")
	local length = self:GetSpecialValueFor("length")
	local width = self:GetSpecialValueFor("width")
	local damage = ScaleDamage(self:GetSpecialValueFor("damage"))

	caster:AddNoDraw()
	CreateWorldParticle(caster:GetAbsOrigin(), WINDWALK_START_PARTICLE, 1.0)
	caster:AddNewModifier(caster, self, "modifier_invulnerable", { duration = vanishDelay + 0.1 })

	Timers:CreateTimer(vanishDelay, function()
		if not IsValidAlive(caster) then return nil end

		local targetPosition = IsValidAlive(target) and target:GetAbsOrigin() or context.position or caster:GetAbsOrigin()
		local direction = targetPosition - caster:GetAbsOrigin()
		direction.z = 0
		if direction:Length2D() <= 0 then direction = RandomVector(1) end
		direction = direction:Normalized()

		local landing = targetPosition - direction * 170
		caster:RemoveNoDraw()
		FindClearSpaceForUnit(caster, landing, true)
		CreateWorldParticle(landing, WINDWALK_END_PARTICLE, 1.0)
		caster:FaceTowards(targetPosition)
		StartAnimation(caster, { duration = strikeDelay + 0.4, activity = ACT_DOTA_ATTACK, rate = 0.8 })
		XHSBossTelegraphs:Line(caster:GetAbsOrigin(), direction, width * 1.35, width, math.max(1, math.floor(length / math.max(1, width * 1.35))), strikeDelay, GROM_COLORS, 80)

		Timers:CreateTimer(strikeDelay, function()
			if not IsValidAlive(caster) then return nil end
			CreateLineParticle(caster:GetAbsOrigin(), direction, length, CLEAVE_PARTICLE, 0.55)
			caster:EmitSound("Hero_Juggernaut.PreAttack")
			DamageLine(caster, self, caster:GetAbsOrigin(), direction, length, width, damage, self:GetAbilityDamageType())
			return nil
		end)

		return nil
	end)

	ClearContext(self)
end

function xhs_grom_warsong_leap:OnAbilityPhaseStart()
	if not IsServer() then return true end

	local context = GetContext(self)
	local caster = self:GetCaster()
	local position = context.position or caster:GetAbsOrigin()
	local radius = self:GetSpecialValueFor("radius")

	StartBossCastBar(self, "Warsong Leap")
	XHSBossTelegraphs:Circle(position, radius, self:GetCastPoint() + self:GetSpecialValueFor("travel_delay"), GROM_COLORS)
	StartAnimation(caster, { duration = self:GetCastPoint() + self:GetSpecialValueFor("travel_delay"), activity = ACT_DOTA_CAST_ABILITY_3, rate = 0.8 })
	caster:EmitSound("Hero_EarthSpirit.RollingBoulder.Cast")
	return true
end

function xhs_grom_warsong_leap:OnAbilityPhaseInterrupted()
	if IsServer() then HideBossCastBar(self) end
end

function xhs_grom_warsong_leap:OnSpellStart()
	if not IsServer() then return end

	local context = GetContext(self)
	local caster = self:GetCaster()
	local position = context.position or caster:GetAbsOrigin()
	local radius = self:GetSpecialValueFor("radius")
	local damage = ScaleDamage(self:GetSpecialValueFor("damage"))
	local slowDuration = self:GetSpecialValueFor("slow_duration")
	local travelDelay = self:GetSpecialValueFor("travel_delay")
	local startPosition = caster:GetAbsOrigin()
	local direction = position - startPosition
	direction.z = 0
	if direction:Length2D() <= 0 then direction = caster:GetForwardVector() end
	CreateWorldParticle(startPosition, WINDWALK_START_PARTICLE, 0.8)
	CreateLineParticle(startPosition, direction, direction:Length2D(), CLEAVE_PARTICLE, travelDelay + 0.15)
	caster:EmitSound("Hero_EarthSpirit.RollingBoulder.Loop")

	Timers:CreateTimer(travelDelay, function()
		caster:StopSound("Hero_EarthSpirit.RollingBoulder.Loop")
		if not IsValidAlive(caster) then return nil end

		FindClearSpaceForUnit(caster, position, true)
		CreateWorldParticle(position, WINDWALK_END_PARTICLE, 0.8)
		caster:EmitSound("Hero_EarthSpirit.BoulderSmash.Target")
		local particle = ParticleManager:CreateParticle(WARSONG_LEAP_PARTICLE, PATTACH_WORLDORIGIN, nil)
		ParticleManager:SetParticleControl(particle, 0, position)
		ParticleManager:SetParticleControl(particle, 1, Vector(radius, 0, 0))
		ParticleManager:ReleaseParticleIndex(particle)

		local enemies = FindUnitsInRadius(
			caster:GetTeamNumber(),
			position,
			nil,
			radius,
			DOTA_UNIT_TARGET_TEAM_ENEMY,
			DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
			DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
			FIND_ANY_ORDER,
			false
		)

		for _, enemy in pairs(enemies) do
			if IsValidAlive(enemy) and not enemy:IsInvulnerable() then
				ApplyDamage({
					victim = enemy,
					attacker = caster,
					ability = self,
					damage = damage,
					damage_type = self:GetAbilityDamageType(),
				})
				enemy:AddNewModifier(caster, self, "modifier_xhs_grom_slow", { duration = slowDuration })
			end
		end

		return nil
	end)

	ClearContext(self)
end

function modifier_xhs_grom_blood_frenzy:IsHidden() return false end
function modifier_xhs_grom_blood_frenzy:IsPurgable() return false end
function modifier_xhs_grom_blood_frenzy:GetTexture() return GROM_TEXTURES.blood_frenzy end

function modifier_xhs_grom_blood_frenzy:OnCreated()
	self.damage_per_stack = self:GetAbility() and self:GetAbility():GetSpecialValueFor("damage_per_stack") or 3
	self.attack_speed_per_stack = self:GetAbility() and self:GetAbility():GetSpecialValueFor("attack_speed_per_stack") or 10
end

function modifier_xhs_grom_blood_frenzy:OnRefresh()
	self:OnCreated()
end

function modifier_xhs_grom_blood_frenzy:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_BASEDAMAGEOUTGOING_PERCENTAGE,
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
	}
end

function modifier_xhs_grom_blood_frenzy:GetModifierBaseDamageOutgoing_Percentage()
	return self:GetStackCount() * (self.damage_per_stack or 3)
end

function modifier_xhs_grom_blood_frenzy:GetModifierAttackSpeedBonus_Constant()
	return self:GetStackCount() * (self.attack_speed_per_stack or 10)
end

function modifier_xhs_grom_slow:IsHidden() return false end
function modifier_xhs_grom_slow:IsDebuff() return true end
function modifier_xhs_grom_slow:IsPurgable() return true end

function modifier_xhs_grom_slow:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
	}
end

function modifier_xhs_grom_slow:GetModifierMoveSpeedBonus_Percentage()
	return -35
end
