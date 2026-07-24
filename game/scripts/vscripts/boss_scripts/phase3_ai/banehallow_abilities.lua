require("boss_scripts/phase3_ai/core")
require("boss_scripts/phase3_ai/cast_bar")

frostivus_boss_shadowraze = frostivus_boss_shadowraze or class({})
frostivus_boss_meteorain = frostivus_boss_meteorain or class({})
frostivus_boss_ragna_blade = frostivus_boss_ragna_blade or class({})
frostivus_boss_soul_harvest = frostivus_boss_soul_harvest or class({})
frostivus_boss_nevermore = frostivus_boss_nevermore or class({})
frostivus_boss_requiem_of_souls = frostivus_boss_requiem_of_souls or class({})

local RAZE_WARNING_PARTICLE = "particles/boss_nevermore/pre_raze.vpcf"
local RAZE_IMPACT_PARTICLE = "particles/boss_nevermore/raze_blast.vpcf"
local METEOR_WARNING_PARTICLE = "particles/boss_nevermore/meteorain_pre.vpcf"
local METEOR_IMPACT_PARTICLE = "particles/boss_nevermore/meteorain.vpcf"
local METEOR_PARTICLE_FALL_TIME = 1.5
local RAGNA_WARNING_PARTICLE = "particles/boss_nevermore/ragna_blade_pre_warning.vpcf"
local RAGNA_IMPACT_PARTICLE = "particles/boss_nevermore/ragna_blade.vpcf"
local REQUIEM_PRECAST_PARTICLE = "particles/units/heroes/hero_nevermore/nevermore_requiemofsouls.vpcf"
local REQUIEM_LINE_PARTICLE = "particles/units/heroes/hero_nevermore/nevermore_requiemofsouls_line.vpcf"
local SOUL_HARVEST_PROJECTILE = "particles/econ/items/shadow_fiend/sf_desolation/sf_base_attack_desolation_fire_arcana.vpcf"
local SCREEN_REQUIEM_PARTICLE = "particles/boss_nevermore/screen_requiem_indicator.vpcf"
local DARKNESS_CAST_LINES = 8
local DARKNESS_RELEASE_LINES = 24

local function IsValidAlive(unit)
	return unit ~= nil and IsValidEntity(unit) and not unit:IsNull() and unit:IsAlive()
end

local function GetContext(ability)
	return ability.xhs_banehallow_context or {}
end

local function ClearContext(ability)
	ability.xhs_banehallow_context = nil
end

local function StartBossCastBar(ability, displayName)
	if XHSBossCastBar ~= nil then
		XHSBossCastBar:Start(ability:GetCaster(), ability, {
			display_name = displayName,
			style = "banehallow",
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

local function ApplyNecromastery(caster, amount)
	local modifier = caster ~= nil and caster:FindModifierByName("modifier_frostivus_necromastery") or nil
	if modifier == nil then return end

	for _ = 1, amount or 1 do
		modifier:IncrementStackCount()
	end
end

local function DamageEnemies(caster, ability, position, radius, damage, damageType, overheadType)
	if not IsValidAlive(caster) then return end

	local units = FindUnitsInRadius(
		DOTA_TEAM_GOODGUYS,
		position,
		nil,
		radius,
		DOTA_UNIT_TARGET_TEAM_FRIENDLY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
		FIND_ANY_ORDER,
		false
	)

	for _, enemy in pairs(units) do
		if IsValidAlive(enemy) then
			local damageDealt = ApplyDamage({
				victim = enemy,
				attacker = caster,
				ability = ability,
				damage = damage,
				damage_type = damageType or ability:GetAbilityDamageType(),
			})
			SendOverheadEventMessage(nil, overheadType or OVERHEAD_ALERT_BONUS_SPELL_DAMAGE, enemy, damageDealt, nil)
			ApplyNecromastery(caster, 1)
		end
	end
end

local function CreateRazeWarning(position, radius)
	local particle = ParticleManager:CreateParticle(RAZE_WARNING_PARTICLE, PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleControl(particle, 0, position)
	ParticleManager:SetParticleControl(particle, 1, Vector(radius, 0, 0))
	ParticleManager:ReleaseParticleIndex(particle)
end

local function ImpactRaze(caster, ability, position, radius, damage, playImpactSound)
	if not IsValidAlive(caster) then return end

	if playImpactSound == true then
		caster:EmitSound("Hero_Nevermore.Shadowraze")
	end

	local particle = ParticleManager:CreateParticle(RAZE_IMPACT_PARTICLE, PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleControl(particle, 0, position)
	ParticleManager:SetParticleControl(particle, 1, Vector(0, 0, 0))
	ParticleManager:ReleaseParticleIndex(particle)

	DamageEnemies(caster, ability, position, radius, damage, ability:GetAbilityDamageType(), OVERHEAD_ALERT_BONUS_SPELL_DAMAGE)
end

local function PickMeteorRainTarget(caster, center, radius, excluded)
	if not IsValidAlive(caster) then return nil end

	local heroes = XHSPhase3BossAI:GetLivingHeroes(center or caster:GetAbsOrigin(), radius or 2200, true)
	local candidates = {}
	for _, hero in pairs(heroes or {}) do
		if IsValidAlive(hero) and (excluded == nil or excluded[hero:entindex()] ~= true) then
			candidates[#candidates + 1] = hero
		end
	end

	if #candidates <= 0 then return nil end
	return candidates[RandomInt(1, #candidates)]
end

local function CreateMeteor(caster, ability, position, radius, damage, fallDelay)
	if not IsValidAlive(caster) or caster.xhs_banehallow_stopped == true then return end

	fallDelay = math.max(0.2, fallDelay or 1.5)
	caster:EmitSound("Hero_Invoker.ChaosMeteor.Cast")

	local warning = ParticleManager:CreateParticle(METEOR_WARNING_PARTICLE, PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleControl(warning, 0, position)
	ParticleManager:SetParticleControl(warning, 1, Vector(radius, 0, 0))
	Timers:CreateTimer(fallDelay + 0.05, function()
		ParticleManager:DestroyParticle(warning, false)
		ParticleManager:ReleaseParticleIndex(warning)
		return nil
	end)

	-- This legacy particle completes its visible fall in at most 1.5 seconds,
	-- independently of longer difficulty telegraphs. Start it late so its
	-- ground contact, impact sound and gameplay damage happen together.
	local meteorFallTime = math.min(fallDelay, METEOR_PARTICLE_FALL_TIME)
	local meteorStartDelay = math.max(0, fallDelay - meteorFallTime)
	local function SpawnFallingMeteor()
		if not IsValidAlive(caster) or caster.xhs_banehallow_stopped == true then return nil end

		local meteor = ParticleManager:CreateParticle(METEOR_IMPACT_PARTICLE, PATTACH_WORLDORIGIN, nil)
		ParticleManager:SetParticleControl(meteor, 0, position + Vector(300, -300, 1000))
		ParticleManager:SetParticleControl(meteor, 1, position)
		ParticleManager:SetParticleControl(meteor, 2, Vector(meteorFallTime, 0, 0))
		ParticleManager:ReleaseParticleIndex(meteor)
		return nil
	end

	if meteorStartDelay > 0 then
		Timers:CreateTimer(meteorStartDelay, SpawnFallingMeteor)
	else
		SpawnFallingMeteor()
	end

	Timers:CreateTimer(fallDelay, function()
		if not IsValidAlive(caster) or caster.xhs_banehallow_stopped == true then return nil end
		caster:EmitSound("Hero_Invoker.ChaosMeteor.Impact")
		DamageEnemies(caster, ability, position, radius, damage, ability:GetAbilityDamageType(), OVERHEAD_ALERT_BONUS_SPELL_DAMAGE)
		return nil
	end)
end

local function CreateDarknessRequiemPulse(caster, lineCount, durationScale)
	if not IsValidAlive(caster) then return end

	lineCount = math.max(1, lineCount or DARKNESS_RELEASE_LINES)
	durationScale = durationScale or 9 / 7
	local origin = caster:GetAbsOrigin()
	local north = origin + Vector(0, 700, 0)

	for i = 1, lineCount do
		local velocity = (RotatePosition(origin, QAngle(0, (i - 1) * 360 / lineCount, 0), north) - origin):Normalized() * 700
		local line = ParticleManager:CreateParticle(REQUIEM_LINE_PARTICLE, PATTACH_ABSORIGIN, caster)
		ParticleManager:SetParticleControl(line, 0, origin)
		ParticleManager:SetParticleControl(line, 1, velocity)
		ParticleManager:SetParticleControl(line, 2, Vector(0, durationScale, 0))
		ParticleManager:ReleaseParticleIndex(line)
	end
end

local function DamageRequiemLine(caster, ability, origin, velocity, distance, width, damage)
	if not IsValidAlive(caster) then return end

	local direction = Vector(velocity.x, velocity.y, 0)
	if direction:Length2D() <= 0 then return end
	direction = direction:Normalized()

	local enemies = FindUnitsInLine(
		DOTA_TEAM_GOODGUYS,
		origin,
		origin + direction * distance,
		nil,
		width,
		DOTA_UNIT_TARGET_TEAM_FRIENDLY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES
	)

	for _, enemy in pairs(enemies) do
		if IsValidAlive(enemy) then
			enemy:EmitSound("Hero_Nevermore.RequiemOfSouls.Damage")
			local damageDealt = ApplyDamage({
				victim = enemy,
				attacker = caster,
				ability = ability,
				damage = damage * RandomInt(90, 110) * 0.01,
				damage_type = ability:GetAbilityDamageType(),
			})
			SendOverheadEventMessage(nil, OVERHEAD_ALERT_DAMAGE, enemy, damageDealt, nil)
		end
	end
end

function frostivus_boss_shadowraze:OnAbilityPhaseStart()
	if not IsServer() then return true end

	local context = GetContext(self)
	local caster = self:GetCaster()
	local radius = self:GetSpecialValueFor("radius")
	local activity = context.activity or ACT_DOTA_RAZE_2

	StartBossCastBar(self, "Shadowraze")
	StartAnimation(caster, { duration = self:GetCastPoint(), activity = activity, rate = 1.0 })
	for _, entry in pairs(context.impacts or {}) do
		CreateRazeWarning(entry.position, radius)
	end

	return true
end

function frostivus_boss_shadowraze:OnAbilityPhaseInterrupted()
	if IsServer() then HideBossCastBar(self) end
end

function frostivus_boss_shadowraze:OnSpellStart()
	if not IsServer() then return end

	local context = GetContext(self)
	local caster = self:GetCaster()
	local radius = self:GetSpecialValueFor("radius")
	local damage = ScaleDamage(self:GetSpecialValueFor("damage"))

	for _, entry in pairs(context.impacts or {}) do
		ImpactRaze(caster, self, entry.position, radius, damage, entry.play_sound)
	end

	if context.emit_sound ~= false then
		caster:EmitSound("Hero_Nevermore.Shadowraze")
	end

	ClearContext(self)
end

function frostivus_boss_meteorain:OnAbilityPhaseStart()
	if not IsServer() then return true end

	local caster = self:GetCaster()
	StartBossCastBar(self, "Meteor Rain")
	caster:EmitSound("Hero_Invoker.ChaosMeteor.Cast")
	StartAnimation(caster, { duration = self:GetCastPoint() + 1.0, activity = ACT_DOTA_IDLE_RARE, rate = 1.0 })
	return true
end

function frostivus_boss_meteorain:OnAbilityPhaseInterrupted()
	if IsServer() then HideBossCastBar(self) end
end

function frostivus_boss_meteorain:OnSpellStart()
	if not IsServer() then return end

	local context = GetContext(self)
	local caster = self:GetCaster()
	local radius = self:GetSpecialValueFor("radius")
	local damage = ScaleDamage(self:GetSpecialValueFor("damage"))
	local fallDelay = self:GetSpecialValueFor("delay")
	local duration = context.duration or self:GetSpecialValueFor("duration")
	local spawnDelay = context.spawn_delay or self:GetSpecialValueFor("spawn_delay")
	local impacts = context.impacts or {}
	local elapsed = 0
	local spawned = 0

	if context.chase == true then
		local totalMeteors = context.total_meteors or math.max(1, math.floor(duration / math.max(0.1, spawnDelay) + 0.5))
		local batchSize = math.max(1, context.batch_size or 1)
		local center = context.arena_center or caster:GetAbsOrigin()
		local targetRadius = context.target_radius or 2200

		Timers:CreateTimer(0, function()
			if not IsValidAlive(caster) or caster.xhs_banehallow_stopped == true or elapsed > duration or spawned >= totalMeteors then return nil end

			local targeted = {}
			for _ = 1, batchSize do
				if spawned >= totalMeteors then break end
				local target = PickMeteorRainTarget(caster, center, targetRadius, targeted)
				if target == nil then break end
				targeted[target:entindex()] = true
				spawned = spawned + 1
				CreateMeteor(caster, self, target:GetAbsOrigin(), radius, damage, fallDelay)
			end

			elapsed = elapsed + spawnDelay
			if elapsed <= duration and spawned < totalMeteors then
				return spawnDelay
			end

			return nil
		end)

		ClearContext(self)
		return
	end

	Timers:CreateTimer(0, function()
		if not IsValidAlive(caster) or caster.xhs_banehallow_stopped == true or spawned >= #impacts then return nil end

		for _ = 1, context.batch_size or 1 do
			spawned = spawned + 1
			if impacts[spawned] == nil then break end
			CreateMeteor(caster, self, impacts[spawned].position, radius, damage, fallDelay)
		end

		elapsed = elapsed + spawnDelay
		if elapsed <= duration and spawned < #impacts then
			return spawnDelay
		end

		return nil
	end)

	ClearContext(self)
end

function frostivus_boss_ragna_blade:OnAbilityPhaseStart()
	if not IsServer() then return true end

	local context = GetContext(self)
	local caster = self:GetCaster()
	local castPoint = self:GetCastPoint()

	StartBossCastBar(self, "Ragna Blade")
	for _, target in pairs(context.targets or {}) do
		if IsValidAlive(target) then
			local warning = ParticleManager:CreateParticle(RAGNA_WARNING_PARTICLE, PATTACH_WORLDORIGIN, nil)
			local warningEndsAt = GameRules:GetGameTime() + castPoint
			ParticleManager:SetParticleControl(warning, 0, target:GetAbsOrigin() + Vector(0, 0, 280))
			target:EmitSound("Frostivus.AbilityWarning")

			Timers:CreateTimer(0, function()
				if IsValidAlive(target) and GameRules:GetGameTime() < warningEndsAt then
					ParticleManager:SetParticleControl(warning, 0, target:GetAbsOrigin() + Vector(0, 0, 280))
					return 0.03
				end
				ParticleManager:DestroyParticle(warning, true)
				ParticleManager:ReleaseParticleIndex(warning)
				return nil
			end)
		end
	end

	Timers:CreateTimer(math.max(0.1, castPoint - 0.85), function()
		if not IsValidAlive(caster) then return nil end
		local target = context.targets and context.targets[1]
		if IsValidAlive(target) then
			caster:FaceTowards(target:GetAbsOrigin())
		end
		StartAnimation(caster, { duration = 1.75, activity = ACT_DOTA_VICTORY, rate = 2.0 })
		return nil
	end)

	return true
end

function frostivus_boss_ragna_blade:OnAbilityPhaseInterrupted()
	if IsServer() then HideBossCastBar(self) end
end

function frostivus_boss_ragna_blade:OnSpellStart()
	if not IsServer() then return end

	local context = GetContext(self)
	local caster = self:GetCaster()
	local damagePct = self:GetSpecialValueFor("damage_pct")

	caster:EmitSound("Hero_Lina.LagunaBlade.Immortal")
	for _, target in pairs(context.targets or {}) do
		if IsValidAlive(target) then
			target:EmitSound("Hero_Lina.LagunaBladeImpact.Immortal")

			local impact = ParticleManager:CreateParticle(RAGNA_IMPACT_PARTICLE, PATTACH_ABSORIGIN_FOLLOW, target)
			ParticleManager:SetParticleControlEnt(impact, 0, caster, PATTACH_POINT_FOLLOW, "attach_head", caster:GetAbsOrigin(), true)
			ParticleManager:SetParticleControlEnt(impact, 1, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
			ParticleManager:ReleaseParticleIndex(impact)

			local damage = target:GetMaxHealth() / 100 * damagePct
			local damageDealt = ApplyDamage({ victim = target, attacker = caster, ability = self, damage = damage, damage_type = self:GetAbilityDamageType() })
			SendOverheadEventMessage(nil, OVERHEAD_ALERT_DAMAGE, target, damageDealt, nil)
			ApplyNecromastery(caster, 1)
		end
	end

	ClearContext(self)
end

function frostivus_boss_soul_harvest:OnAbilityPhaseStart()
	if not IsServer() then return true end

	local caster = self:GetCaster()
	StartBossCastBar(self, "Soul Harvest")
	StartAnimation(caster, { duration = 1.04, activity = ACT_DOTA_ATTACK, rate = 1.0 })
	return true
end

function frostivus_boss_soul_harvest:OnAbilityPhaseInterrupted()
	if IsServer() then HideBossCastBar(self) end
end

function frostivus_boss_soul_harvest:OnSpellStart()
	if not IsServer() then return end

	local context = GetContext(self)
	local caster = self:GetCaster()
	local target = context.target
	if not IsValidAlive(caster) or not IsValidAlive(target) then
		ClearContext(self)
		return
	end

	ProjectileManager:CreateTrackingProjectile({
		Target = target,
		Source = caster,
		Ability = self,
		EffectName = SOUL_HARVEST_PROJECTILE,
		bDodgeable = true,
		bProvidesVision = false,
		bVisibleToEnemies = true,
		bReplaceExisting = false,
		iMoveSpeed = 1200,
		iVisionRadius = 0,
		iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_ATTACK_1,
		ExtraData = { damage = context.damage or 0 },
	})

	ClearContext(self)
end

function frostivus_boss_soul_harvest:OnProjectileHit_ExtraData(target, location, keys)
	if not IsServer() or not IsValidAlive(target) then return end

	target:EmitSound("Hero_Nevermore.ProjectileImpact")
	ApplyNecromastery(self:GetCaster(), 1)

	local damageDealt = ApplyDamage({
		victim = target,
		attacker = self:GetCaster(),
		ability = self,
		damage = (keys.damage or 0) * RandomInt(90, 110) * 0.01,
		damage_type = self:GetAbilityDamageType(),
	})
	SendOverheadEventMessage(nil, OVERHEAD_ALERT_DAMAGE, target, damageDealt, nil)
end

function frostivus_boss_nevermore:OnAbilityPhaseStart()
	if not IsServer() then return true end

	local caster = self:GetCaster()
	StartBossCastBar(self, "Darkness")
	caster:EmitSound("Hero_Nevermore.RequiemOfSoulsCast")
	CreateDarknessRequiemPulse(caster, DARKNESS_CAST_LINES, 0.55)
	StartAnimation(caster, { duration = self:GetCastPoint() + 1.0, activity = ACT_DOTA_VERSUS, rate = 2.0 })
	return true
end

function frostivus_boss_nevermore:OnAbilityPhaseInterrupted()
	if IsServer() then HideBossCastBar(self) end
end

function frostivus_boss_nevermore:OnSpellStart()
	if not IsServer() then return end

	local context = GetContext(self)
	local caster = self:GetCaster()
	local duration = context.duration or self:GetSpecialValueFor("duration")

	caster:EmitSound("Hero_Nevermore.RequiemOfSouls")
	CreateDarknessRequiemPulse(caster, context.visual_line_count or DARKNESS_RELEASE_LINES, 9 / 7)

	for playerID = 0, 20 do
		local player = PlayerResource:GetPlayer(playerID)
		if player ~= nil and PlayerResource:GetTeam(playerID) == (context.team or DOTA_TEAM_GOODGUYS) then
			local hero = PlayerResource:GetSelectedHeroEntity(playerID)
			if IsValidAlive(hero) then
				local particle = ParticleManager:CreateParticleForPlayer(SCREEN_REQUIEM_PARTICLE, PATTACH_EYES_FOLLOW, hero, player)
				Timers:CreateTimer(duration, function()
					ParticleManager:DestroyParticle(particle, true)
					ParticleManager:ReleaseParticleIndex(particle)
					return nil
				end)
			end
		end
	end

	Timers:CreateTimer(math.max(0.2, duration * 0.45), function()
		if not IsValidAlive(caster) then return nil end
		local shadowraze = caster:FindAbilityByName("frostivus_boss_shadowraze")
		if shadowraze == nil then return nil end
		if XHSPhase3BossAI:IsCastBlocked(caster) then return nil end

		shadowraze.xhs_banehallow_context = {
			impacts = context.inner_impacts or {},
			activity = context.inner_activity or ACT_DOTA_RAZE_2,
		}
		caster:FaceTowards(caster:GetAbsOrigin() + Vector(0, -100, 0))
		XHSPhase3BossAI:ProtectCast(caster, shadowraze)
		caster:CastAbilityNoTarget(shadowraze, -1)
		return nil
	end)

	ClearContext(self)
end

function frostivus_boss_requiem_of_souls:OnAbilityPhaseStart()
	if not IsServer() then return true end

	local caster = self:GetCaster()
	local castPoint = self:GetCastPoint()
	local radius = self:GetSpecialValueFor("distance")
	StartBossCastBar(self, "Requiem of Souls")
	local warning = ParticleManager:CreateParticle(REQUIEM_PRECAST_PARTICLE, PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleControlEnt(warning, 0, caster, PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", caster:GetAbsOrigin(), true)
	ParticleManager:SetParticleControl(warning, 1, Vector(radius, 0, 0))
	Timers:CreateTimer(castPoint + 0.05, function()
		ParticleManager:DestroyParticle(warning, false)
		ParticleManager:ReleaseParticleIndex(warning)
		return nil
	end)
	Timers:CreateTimer(math.max(0.1, castPoint - 1.65), function()
		if not IsValidAlive(caster) then return nil end
		caster:FaceTowards(caster:GetAbsOrigin() + Vector(0, -100, 0))
		caster:EmitSound("Hero_Nevermore.ROS.Arcana.Cast")
		StartAnimation(caster, { duration = 2.0, activity = ACT_DOTA_RAZE_3, rate = 0.35 })
		return nil
	end)
	return true
end

function frostivus_boss_requiem_of_souls:OnAbilityPhaseInterrupted()
	if IsServer() then HideBossCastBar(self) end
end

function frostivus_boss_requiem_of_souls:OnSpellStart()
	if not IsServer() then return end

	local context = GetContext(self)
	local caster = self:GetCaster()
	local lineDamage = ScaleDamage(self:GetSpecialValueFor("damage"))
	local distance = self:GetSpecialValueFor("distance")
	local lineCount = context.line_count or self:GetSpecialValueFor("line_amount")
	local bossLoc = caster:GetAbsOrigin()
	local north = bossLoc + Vector(0, 700, 0)

	caster:EmitSound("Hero_Nevermore.ROS.Arcana")
	local necromastery = caster:FindModifierByName("modifier_frostivus_necromastery")
	if necromastery ~= nil then
		necromastery:SetStackCount(0)
	end

	for i = 1, lineCount do
		local velocity = (RotatePosition(bossLoc, QAngle(0, (i - 1) * 360 / lineCount, 0), north) - bossLoc):Normalized() * 700

		local line = ParticleManager:CreateParticle(REQUIEM_LINE_PARTICLE, PATTACH_ABSORIGIN, caster)
		ParticleManager:SetParticleControl(line, 0, bossLoc)
		ParticleManager:SetParticleControl(line, 1, velocity)
		ParticleManager:SetParticleControl(line, 2, Vector(0, 9 / 7, 0))
		ParticleManager:ReleaseParticleIndex(line)

		DamageRequiemLine(caster, self, bossLoc, velocity, distance, 160, lineDamage)
	end
	DamageEnemies(caster, self, bossLoc, distance, lineDamage, self:GetAbilityDamageType(), OVERHEAD_ALERT_DAMAGE)

	ClearContext(self)
end
