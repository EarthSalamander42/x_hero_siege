require("boss_scripts/phase3_ai/core")

LinkLuaModifier("modifier_xhs_banehallow_phase3_ai", "boss_scripts/phase3_ai/banehallow.lua", LUA_MODIFIER_MOTION_NONE)

modifier_xhs_banehallow_phase3_ai = modifier_xhs_banehallow_phase3_ai or class({})
modifier_xhs_banehallow_phase3_ai.XHS_LINK_CLIENT = true

local BANEHALLOW_ABILITIES = {
	"frostivus_boss_necromastery",
	"frostivus_boss_immolation",
	"frostivus_boss_ragna_blade",
	"frostivus_boss_meteorain",
	"frostivus_boss_shadowraze",
	"frostivus_boss_soul_harvest",
	"frostivus_boss_nevermore",
	"frostivus_boss_requiem_of_souls",
}

local BANEHALLOW_THRESHOLD_CONFIG = {
	[1] = { thresholds = { 50 }, revenants_per_point = 3 },
	[2] = { thresholds = { 66, 33 }, revenants_per_point = 4 },
	[3] = { thresholds = { 75, 50, 25 }, revenants_per_point = 5 },
	[4] = { thresholds = { 80, 60, 40, 20 }, revenants_per_point = 6 },
	[5] = { thresholds = { 85, 70, 55, 40, 25 }, revenants_per_point = 8 },
}

local function IsValidAlive(unit)
	return unit ~= nil and IsValidEntity(unit) and not unit:IsNull() and unit:IsAlive()
end

local function FaceUnitTowardsPosition(unit, position)
	if unit == nil or not IsValidEntity(unit) or unit:IsNull() or position == nil then return end

	local direction = position - unit:GetAbsOrigin()
	direction.z = 0
	if direction:Length2D() <= 0 then return end

	unit:SetForwardVector(direction:Normalized())
	unit:FaceTowards(position)
end

local function GetAbilityCastPoint(ability)
	if ability == nil then return 0 end
	if ability.GetCastPoint ~= nil then
		local castPoint = ability:GetCastPoint()
		if castPoint ~= nil and castPoint > 0 then return castPoint end
	end

	return ability:GetSpecialValueFor("cast_point")
end

local function GetThresholdConfig()
	local difficulty = XHSPhase3BossAI:GetDifficulty()
	return BANEHALLOW_THRESHOLD_CONFIG[difficulty] or BANEHALLOW_THRESHOLD_CONFIG[1]
end

local function CastPreparedAbility(boss, abilityName, context, facePosition)
	if not IsValidAlive(boss) then return nil end

	local ability = boss:FindAbilityByName(abilityName)
	if ability == nil or ability:IsNull() then return nil end
	if XHSPhase3BossAI:IsCastBlocked(boss) then return nil end

	ability.xhs_banehallow_context = context or {}
	if facePosition ~= nil then
		FaceUnitTowardsPosition(boss, facePosition)
	end

	XHSPhase3BossAI:ProtectCast(boss, ability)
	boss:CastAbilityNoTarget(ability, -1)
	return ability
end

function modifier_xhs_banehallow_phase3_ai:IsHidden() return true end
function modifier_xhs_banehallow_phase3_ai:IsPurgable() return false end

function modifier_xhs_banehallow_phase3_ai:OnCreated(params)
	if not IsServer() then return end

	local boss = self:GetParent()
	boss.xhs_banehallow_stopped = nil
	self.team = DOTA_TEAM_GOODGUYS
	self.arena_center = Entities:FindByName(nil, "npc_dota_spawner_magtheridon_arena"):GetAbsOrigin()
	self.recent_positions = {}
	self.thresholds_done = {}
	self.patterns = {}
	self.state = "intro"
	self.cast_until = 0
	self.recover_until = 0
	self.soul_harvest_ready_at = 0
	self.last_pattern = nil
	self.force_pattern = nil
	self.threshold_next_allowed_at = 0

	XHSPhase3BossAI:HideVanillaHealthBar(boss)
	XHSPhase3BossAI:SetAbilityLevels(boss, BANEHALLOW_ABILITIES)
	self:UpdateBossBarMarkers()
	self:CreateCosmetics()
	XHSPhase3BossAI:RevealBossBarOnce(self)
	self:BuildPatternDeck()
	self:StartIntervalThink(0.25)
end

function modifier_xhs_banehallow_phase3_ai:OnDestroy()
	if not IsServer() then return end

	local boss = self:GetParent()
	if boss ~= nil and not boss:IsNull() then
		boss.xhs_banehallow_stopped = true
	end
	self:DestroyCosmeticEntity("head")
	self:DestroyCosmeticEntity("wings")
	self:DestroyCosmeticEntity("shoulders")
	self:DestroyCosmeticEntity("arms")
	self:DestroyCosmeticEntity("hand")
	self:DestroyParticle("fire_pfx")
	self:DestroyParticle("shoulders_pfx")
	self:DestroyParticle("shadow_trail_pfx")
end

function modifier_xhs_banehallow_phase3_ai:DestroyCosmeticEntity(field)
	local boss = self:GetParent()
	if boss == nil or not IsValidEntity(boss) or boss:IsNull() then return end

	local entity = boss and boss[field]
	if entity ~= nil and IsValidEntity(entity) and not entity:IsNull() then
		UTIL_Remove(entity)
	end
end

function modifier_xhs_banehallow_phase3_ai:DestroyParticle(field)
	if self[field] ~= nil then
		ParticleManager:DestroyParticle(self[field], false)
		ParticleManager:ReleaseParticleIndex(self[field])
		self[field] = nil
	end
end

function modifier_xhs_banehallow_phase3_ai:IsBossActive()
	local boss = self:GetParent()
	return boss ~= nil and IsValidEntity(boss) and not boss:IsNull() and boss:IsAlive() and boss.deathStart ~= true
end

function modifier_xhs_banehallow_phase3_ai:CreateCosmetics()
	local boss = self:GetParent()
	if boss.xhs_banehallow_cosmetics_created == true then return end
	boss.xhs_banehallow_cosmetics_created = true

	boss:SetRenderColor(0, 0, 0)
	boss.head = SpawnEntityFromTableSynchronous("prop_dynamic", { model = "models/items/nevermore/diabolical_fiend_head/diabolical_fiend_head.vmdl" })
	boss.head:FollowEntity(boss, true)
	boss.wings = SpawnEntityFromTableSynchronous("prop_dynamic", { model = "models/heroes/shadow_fiend/arcana_wings.vmdl" })
	boss.wings:FollowEntity(boss, true)
	boss.wings:SetRenderColor(0, 0, 0)
	boss.shoulders = SpawnEntityFromTableSynchronous("prop_dynamic", { model = "models/items/nevermore/ferrum_chiroptera_shoulder/ferrum_chiroptera_shoulder.vmdl" })
	boss.shoulders:FollowEntity(boss, true)
	boss.shoulders:SetRenderColor(0, 0, 0)
	boss.arms = SpawnEntityFromTableSynchronous("prop_dynamic", { model = "models/items/nevermore/diabolical_fiend_arms/diabolical_fiend_arms.vmdl" })
	boss.arms:FollowEntity(boss, true)
	boss.arms:SetRenderColor(0, 0, 0)
	boss.hand = SpawnEntityFromTableSynchronous("prop_dynamic", { model = "models/heroes/shadow_fiend/fx_shadow_fiend_arcana_hand.vmdl" })
	boss.hand:FollowEntity(boss, true)
	boss.hand:SetRenderColor(0, 0, 0)

	local boss_loc = boss:GetAbsOrigin()
	self.fire_pfx = ParticleManager:CreateParticle("particles/econ/items/shadow_fiend/sf_fire_arcana/sf_fire_arcana_ambient.vpcf", PATTACH_POINT_FOLLOW, boss)
	ParticleManager:SetParticleControlEnt(self.fire_pfx, 0, boss, PATTACH_POINT_FOLLOW, "attach_hitloc", boss_loc, true)
	ParticleManager:SetParticleControlEnt(self.fire_pfx, 1, boss, PATTACH_POINT_FOLLOW, "attach_arm_L", boss_loc, true)
	ParticleManager:SetParticleControlEnt(self.fire_pfx, 2, boss, PATTACH_POINT_FOLLOW, "attach_arm_L", boss_loc, true)
	ParticleManager:SetParticleControlEnt(self.fire_pfx, 3, boss, PATTACH_POINT_FOLLOW, "attach_arm_L", boss_loc, true)
	ParticleManager:SetParticleControlEnt(self.fire_pfx, 4, boss, PATTACH_POINT_FOLLOW, "attach_arm_R", boss_loc, true)
	ParticleManager:SetParticleControlEnt(self.fire_pfx, 5, boss, PATTACH_POINT_FOLLOW, "attach_arm_R", boss_loc, true)
	ParticleManager:SetParticleControlEnt(self.fire_pfx, 6, boss, PATTACH_POINT_FOLLOW, "attach_arm_R", boss_loc, true)
	ParticleManager:SetParticleControlEnt(self.fire_pfx, 7, boss, PATTACH_POINT_FOLLOW, "attach_head", boss_loc, true)
	ParticleManager:SetParticleControlEnt(self.fire_pfx, 8, boss, PATTACH_POINT_FOLLOW, "attach_hitloc", boss_loc, true)

	self.shoulders_pfx = ParticleManager:CreateParticle("particles/boss_nevermore/nevermore_shoulder_ambient.vpcf", PATTACH_POINT_FOLLOW, boss)
	ParticleManager:SetParticleControlEnt(self.shoulders_pfx, 0, boss, PATTACH_POINT_FOLLOW, "attach_shoulder_l", boss_loc, true)
	ParticleManager:SetParticleControlEnt(self.shoulders_pfx, 4, boss, PATTACH_POINT_FOLLOW, "attach_hitloc", boss_loc, true)

	self.shadow_trail_pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_nevermore/nevermore_trail.vpcf", PATTACH_ABSORIGIN_FOLLOW, boss)
	ParticleManager:SetParticleControl(self.shadow_trail_pfx, 0, boss_loc)
end

function modifier_xhs_banehallow_phase3_ai:BuildPatternDeck()
	local now = GameRules:GetGameTime()
	self.patterns = {
		{ id = "shadow_line", weight = 4, cooldown = 7.0, ready_at = 0, run = function() return self:CastShadowLine() end },
		{ id = "soul_rings", weight = 4, cooldown = 8.0, ready_at = 0, run = function() return self:CastSoulRings() end },
		{ id = "meteor_hunt", weight = 3, cooldown = 14.0, ready_at = 0, run = function() return self:CastMeteorHunt() end, can_run = function() return self:CanCastMeteorHunt() end },
		{ id = "ragna_mark", weight = 3, cooldown = 12.0, ready_at = 0, run = function() return self:CastRagnaMark() end },
		{ id = "darkness", weight = 1, cooldown = 24.0, ready_at = now + 12.0, run = function() return self:CastDarkness() end },
		{ id = "requiem", weight = 1, cooldown = 28.0, ready_at = now + 18.0, run = function() return self:CastRequiem() end, can_run = function() return self:CanCastRequiem() end },
	}
end

function modifier_xhs_banehallow_phase3_ai:OnIntervalThink()
	if not self:IsBossActive() then
		self.state = "dead"
		self:StartIntervalThink(-1)
		return
	end

	local boss = self:GetParent()
	local now = GameRules:GetGameTime()
	self:TrackHeroPositions()
	if self:TrySoulHarvest(now) then return end

	if boss:HasModifier("modifier_invulnerable") or boss:HasModifier("modifier_pause_creeps") then
		self.state = "intro"
		return
	end

	XHSPhase3BossAI:RevealBossBarOnce(self)
	self:CheckHpThresholds(now)

	if self.state == "casting" then
		if now < self.cast_until then return end
		self.state = "recovery"
	end

	if self.state == "recovery" then
		if now < self.recover_until then return end
		self.state = "idle"
	end

	local entry = self:GetNextPattern(now)
	if entry == nil then
		self:Reposition()
		return
	end

	self:RunPattern(entry, now)
end

function modifier_xhs_banehallow_phase3_ai:TrackHeroPositions()
	local heroes = XHSPhase3BossAI:GetLivingHeroes(self.arena_center, 2200, true)
	for _, hero in pairs(heroes) do
		if hero ~= nil and IsValidEntity(hero) and not hero:IsNull() and hero:IsAlive() then
			local key = tostring(hero:entindex())
			local previous = self.recent_positions[key]
			self.recent_positions[key] = {
				current = hero:GetAbsOrigin(),
				previous = previous and previous.current or hero:GetAbsOrigin(),
			}
		end
	end
end

function modifier_xhs_banehallow_phase3_ai:CheckHpThresholds(now)
	if now < self.threshold_next_allowed_at then return end

	local boss = self:GetParent()
	local hpPct = boss:GetHealth() / math.max(1, boss:GetMaxHealth()) * 100

	for _, threshold in ipairs(GetThresholdConfig().thresholds or {}) do
		if hpPct <= threshold and self.thresholds_done[threshold] ~= true then
			self.thresholds_done[threshold] = true
			self.force_pattern = "requiem"
			self.threshold_next_allowed_at = now + XHSPhase3BossAI:ScaleDelay(8.0)
			self:UpdateBossBarMarkers()
			self:SummonThresholdRevenants(threshold)
			return
		end
	end
end

function modifier_xhs_banehallow_phase3_ai:UpdateBossBarMarkers()
	local boss = self:GetParent()
	local config = GetThresholdConfig()
	local thresholds = config.thresholds or {}
	local revenantsPerPoint = config.revenants_per_point or 3
	boss.xhs_boss_bar_markers = {}

	for index, threshold in ipairs(thresholds) do
		boss.xhs_boss_bar_markers[index] = {
			pct = threshold,
			kind = "companion",
			label = "Ghost Revenants x" .. revenantsPerPoint,
			description = revenantsPerPoint .. " Ghost Revenants spawn at this point. This difficulty has " .. #thresholds .. " revenant points.",
			triggered = self.thresholds_done[threshold] == true,
		}
	end
end

function modifier_xhs_banehallow_phase3_ai:GetPatternById(id)
	for _, entry in pairs(self.patterns) do
		if entry.id == id then return entry end
	end

	return nil
end

function modifier_xhs_banehallow_phase3_ai:GetNextPattern(now)
	if self.force_pattern ~= nil then
		local forced = self:GetPatternById(self.force_pattern)
		self.force_pattern = nil
		if forced ~= nil then return forced end
	end

	return XHSPhase3BossAI:WeightedChoice(self.patterns, now)
end

function modifier_xhs_banehallow_phase3_ai:RunPattern(entry, now)
	local duration = entry.run()
	if duration == nil or duration <= 0 then
		entry.ready_at = now + 1.0
		return
	end

	entry.ready_at = now + XHSPhase3BossAI:ScaleDelay(entry.cooldown)
	self.last_pattern = entry.id
	self.state = "casting"
	self.cast_until = now + duration
	self.recover_until = self.cast_until + XHSPhase3BossAI:ScaleDelay(1.0)
end

function modifier_xhs_banehallow_phase3_ai:Reposition()
	self.state = "reposition"
	local boss = self:GetParent()
	local target = XHSPhase3BossAI:PickClosestHero(self.arena_center, 2200)
	local angle = RandomFloat(0, 360)
	local distance = target ~= nil and 450 or 250
	local position = RotatePosition(self.arena_center, QAngle(0, angle, 0), self.arena_center + Vector(distance, 0, 0))
	XHSPhase3BossAI:MoveBoss(boss, position)
	self.recover_until = GameRules:GetGameTime() + 0.8
	self.state = "recovery"
end

function modifier_xhs_banehallow_phase3_ai:TrySoulHarvest(now)
	if now < self.soul_harvest_ready_at or self.state == "casting" then return end

	local boss = self:GetParent()
	local target = XHSPhase3BossAI:PickClosestHero(boss:GetAbsOrigin(), 700)
	if target == nil then return end

	local ability = boss:FindAbilityByName("frostivus_boss_soul_harvest")
	if ability == nil then return end

	local damage = boss:GetAverageTrueAttackDamage(target) * self:GetNecromasteryAmp()
	self.soul_harvest_ready_at = now + XHSPhase3BossAI:ScaleDelay(4.0)
	local castAbility = CastPreparedAbility(boss, "frostivus_boss_soul_harvest", {
		target = target,
		damage = XHSPhase3BossAI:ScaleDamage(damage),
	}, target:GetAbsOrigin())
	if castAbility == nil then return end

	self.state = "casting"
	self.cast_until = now + GetAbilityCastPoint(castAbility) + 0.55
	self.recover_until = self.cast_until + 0.15
	return true
end

function modifier_xhs_banehallow_phase3_ai:GetNecromasteryAmp()
	local modifier = self:GetParent():FindModifierByName("modifier_frostivus_necromastery")
	if modifier == nil then return 1 end

	return 1 + modifier:GetStackCount() * 0.02
end

function modifier_xhs_banehallow_phase3_ai:GetNecromasteryStacks()
	local modifier = self:GetParent():FindModifierByName("modifier_frostivus_necromastery")
	if modifier == nil then return 0 end

	return modifier:GetStackCount()
end

function modifier_xhs_banehallow_phase3_ai:ApplyNecromastery(amount)
	local modifier = self:GetParent():FindModifierByName("modifier_frostivus_necromastery")
	if modifier == nil then return end

	for _ = 1, amount or 1 do
		modifier:IncrementStackCount()
	end
end

function modifier_xhs_banehallow_phase3_ai:GetPredictedHeroPosition(hero)
	if hero == nil then return self.arena_center end

	local position = hero:GetAbsOrigin()
	local tracked = self.recent_positions[tostring(hero:entindex())]
	if tracked == nil then return position end

	local velocity = tracked.current - tracked.previous
	return tracked.current + velocity * 1.5
end

function modifier_xhs_banehallow_phase3_ai:CanCastMeteorHunt()
	local difficulty = XHSPhase3BossAI:GetDifficulty()
	return not (difficulty <= 2 and self.last_pattern == "darkness")
end

function modifier_xhs_banehallow_phase3_ai:CanCastRequiem()
	return self:GetNecromasteryStacks() >= XHSPhase3BossAI:ScaleDensity(18, 10)
end

function modifier_xhs_banehallow_phase3_ai:CastShadowLine()
	local boss = self:GetParent()
	local ability = boss:FindAbilityByName("frostivus_boss_shadowraze")
	if ability == nil then return nil end

	local target = XHSPhase3BossAI:PickFarthestHero(self.arena_center, 2200)
	if target == nil then return nil end

	local delay = XHSPhase3BossAI:ScaleDelay(ability:GetSpecialValueFor("delay"))
	local radius = ability:GetSpecialValueFor("radius")
	local spawnDistance = ability:GetSpecialValueFor("spawn_distance")
	local targetPosition = self:GetPredictedHeroPosition(target)
	local direction = (targetPosition - boss:GetAbsOrigin()):Normalized()
	if direction:Length2D() <= 0 then direction = Vector(0, 1, 0) end

	local impacts = {}
	local count = XHSPhase3BossAI:ScaleDensity(7, 5)
	for i = 1, count do
		impacts[#impacts + 1] = {
			position = boss:GetAbsOrigin() + direction * (radius * 0.5 + spawnDistance * (i - 1)),
		}
	end

	local castAbility = CastPreparedAbility(boss, "frostivus_boss_shadowraze", {
		impacts = impacts,
		activity = ACT_DOTA_RAZE_3,
	}, targetPosition)
	if castAbility == nil then return nil end

	return GetAbilityCastPoint(castAbility) + 0.4
end

function modifier_xhs_banehallow_phase3_ai:CastSoulRings()
	local boss = self:GetParent()
	local ability = boss:FindAbilityByName("frostivus_boss_shadowraze")
	if ability == nil then return nil end

	local delay = XHSPhase3BossAI:ScaleDelay(ability:GetSpecialValueFor("delay"))
	local nearHeroes = XHSPhase3BossAI:GetLivingHeroes(boss:GetAbsOrigin(), 550, true)
	local distance = #nearHeroes >= 1 and 650 or 375
	local count = distance > 450 and XHSPhase3BossAI:ScaleDensity(12, 8) or XHSPhase3BossAI:ScaleDensity(6, 4)

	local impacts = {}
	for i = 1, count do
		impacts[#impacts + 1] = {
			position = RotatePosition(self.arena_center, QAngle(0, 360 / count * (i - 1), 0), self.arena_center + Vector(0, distance, 0)),
		}
	end

	local castAbility = CastPreparedAbility(boss, "frostivus_boss_shadowraze", {
		impacts = impacts,
		activity = distance > 450 and ACT_DOTA_RAZE_2 or ACT_DOTA_RAZE_1,
	}, boss:GetAbsOrigin() + Vector(0, -100, 0))
	if castAbility == nil then return nil end

	return GetAbilityCastPoint(castAbility) + 0.5
end

function modifier_xhs_banehallow_phase3_ai:Raze(target, playImpactSound, delayOverride)
	local boss = self:GetParent()
	local ability = boss:FindAbilityByName("frostivus_boss_shadowraze")
	if ability == nil then return end

	local delay = delayOverride or XHSPhase3BossAI:ScaleDelay(ability:GetSpecialValueFor("delay"))
	local damage = XHSPhase3BossAI:ScaleDamage(ability:GetSpecialValueFor("damage"))
	local radius = ability:GetSpecialValueFor("radius")

	local warning_pfx = ParticleManager:CreateParticle("particles/boss_nevermore/pre_raze.vpcf", PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleControl(warning_pfx, 0, target)
	ParticleManager:SetParticleControl(warning_pfx, 1, Vector(radius, 0, 0))
	ParticleManager:ReleaseParticleIndex(warning_pfx)

	Timers:CreateTimer(delay, function()
		if not self:IsBossActive() then return nil end

		if playImpactSound then
			boss:EmitSound("Hero_Nevermore.Shadowraze")
		end

		local raze_pfx = ParticleManager:CreateParticle("particles/boss_nevermore/raze_blast.vpcf", PATTACH_WORLDORIGIN, nil)
		ParticleManager:SetParticleControl(raze_pfx, 0, target)
		ParticleManager:SetParticleControl(raze_pfx, 1, Vector(0, 0, 0))
		ParticleManager:ReleaseParticleIndex(raze_pfx)

		local hit_enemies = FindUnitsInRadius(DOTA_TEAM_GOODGUYS, target, nil, radius, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
		for _, enemy in pairs(hit_enemies) do
			local damage_dealt = ApplyDamage({ victim = enemy, attacker = boss, ability = ability, damage = damage, damage_type = ability:GetAbilityDamageType() })
			SendOverheadEventMessage(nil, OVERHEAD_ALERT_BONUS_SPELL_DAMAGE, enemy, damage_dealt, nil)
			self:ApplyNecromastery(1)
		end
	end)
end

function modifier_xhs_banehallow_phase3_ai:CastMeteorHunt()
	local boss = self:GetParent()
	local ability = boss:FindAbilityByName("frostivus_boss_meteorain")
	if ability == nil then return nil end

	local duration = XHSPhase3BossAI:ScaleDelay(ability:GetSpecialValueFor("duration"))
	local spawnDelay = XHSPhase3BossAI:ScaleDelay(ability:GetSpecialValueFor("spawn_delay"))
	local spawnAmount = XHSPhase3BossAI:ScaleDensity(ability:GetSpecialValueFor("spawn_amount"), 2)
	local batchSize = math.min(2, math.max(1, math.floor(spawnAmount / 8)))
	local waveCount = math.max(1, math.floor(duration / math.max(0.1, spawnDelay) + 0.5))
	local heroes = XHSPhase3BossAI:GetLivingHeroes(self.arena_center, 2200, true)
	if #heroes <= 0 then return nil end

	local castAbility = CastPreparedAbility(boss, "frostivus_boss_meteorain", {
		chase = true,
		arena_center = self.arena_center,
		target_radius = 2200,
		duration = duration,
		spawn_delay = spawnDelay,
		total_meteors = math.max(spawnAmount, waveCount * batchSize),
		batch_size = batchSize,
	}, self.arena_center)
	if castAbility == nil then return nil end

	return GetAbilityCastPoint(castAbility) + duration + 1.8
end

function modifier_xhs_banehallow_phase3_ai:Meteor(target, radius, damage)
	local boss = self:GetParent()
	boss:EmitSound("Hero_Invoker.ChaosMeteor.Cast")

	local warning_pfx = ParticleManager:CreateParticle("particles/boss_nevermore/meteorain_pre.vpcf", PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleControl(warning_pfx, 0, target)
	ParticleManager:SetParticleControl(warning_pfx, 1, Vector(radius, 0, 0))
	ParticleManager:ReleaseParticleIndex(warning_pfx)

	local meteor_pfx = ParticleManager:CreateParticle("particles/boss_nevermore/meteorain.vpcf", PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleControl(meteor_pfx, 0, target + Vector(300, -300, 1000))
	ParticleManager:SetParticleControl(meteor_pfx, 1, target)
	ParticleManager:SetParticleControl(meteor_pfx, 2, Vector(1.5, 0, 0))
	ParticleManager:ReleaseParticleIndex(meteor_pfx)

	Timers:CreateTimer(1.5, function()
		if not self:IsBossActive() then return nil end

		boss:EmitSound("Hero_Invoker.ChaosMeteor.Impact")
		local hit_enemies = FindUnitsInRadius(DOTA_TEAM_GOODGUYS, target, nil, radius, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
		for _, enemy in pairs(hit_enemies) do
			local damage_dealt = ApplyDamage({ victim = enemy, attacker = boss, ability = ability, damage = damage, damage_type = ability:GetAbilityDamageType() })
			SendOverheadEventMessage(nil, OVERHEAD_ALERT_BONUS_SPELL_DAMAGE, enemy, damage_dealt, nil)
			self:ApplyNecromastery(1)
		end
	end)
end

function modifier_xhs_banehallow_phase3_ai:CastRagnaMark()
	local boss = self:GetParent()
	local ability = boss:FindAbilityByName("frostivus_boss_ragna_blade")
	if ability == nil then return nil end

	local targetAmount = XHSPhase3BossAI:ScaleDensity(ability:GetSpecialValueFor("target_amount"), 1)
	local heroes = XHSPhase3BossAI:GetLivingHeroes(self.arena_center, 2200, true)
	local targets = {}

	for _, hero in pairs(heroes) do
		targets[#targets + 1] = hero
		if #targets >= targetAmount then break end
	end

	if #targets <= 0 then return nil end

	local castAbility = CastPreparedAbility(boss, "frostivus_boss_ragna_blade", {
		targets = targets,
	}, targets[1]:GetAbsOrigin())
	if castAbility == nil then return nil end

	return GetAbilityCastPoint(castAbility) + 0.8
end

function modifier_xhs_banehallow_phase3_ai:CastDarkness()
	local boss = self:GetParent()
	local ability = boss:FindAbilityByName("frostivus_boss_nevermore")
	if ability == nil then return nil end

	local duration = XHSPhase3BossAI:ScaleDelay(ability:GetSpecialValueFor("duration"))
	local shadowraze = boss:FindAbilityByName("frostivus_boss_shadowraze")
	if shadowraze == nil then return nil end

	local nearHeroes = XHSPhase3BossAI:GetLivingHeroes(boss:GetAbsOrigin(), 550, true)
	local distance = #nearHeroes >= 1 and 650 or 375
	local count = distance > 450 and XHSPhase3BossAI:ScaleDensity(12, 8) or XHSPhase3BossAI:ScaleDensity(6, 4)
	local impacts = {}
	for i = 1, count do
		impacts[#impacts + 1] = {
			position = RotatePosition(self.arena_center, QAngle(0, 360 / count * (i - 1), 0), self.arena_center + Vector(0, distance, 0)),
		}
	end

	local castAbility = CastPreparedAbility(boss, "frostivus_boss_nevermore", {
		duration = duration,
		team = self.team,
		inner_impacts = impacts,
		inner_activity = distance > 450 and ACT_DOTA_RAZE_2 or ACT_DOTA_RAZE_1,
	}, self.arena_center)
	if castAbility == nil then return nil end

	return GetAbilityCastPoint(castAbility) + duration + 2.0
end

function modifier_xhs_banehallow_phase3_ai:CastRequiem()
	local boss = self:GetParent()
	local ability = boss:FindAbilityByName("frostivus_boss_requiem_of_souls")
	if ability == nil then return nil end

	local baseLineAmount = ability:GetSpecialValueFor("line_amount")
	local stacks = self:GetNecromasteryStacks()
	local lineCount = XHSPhase3BossAI:ScaleDensity(baseLineAmount, 32) + math.floor(stacks * 0.5)
	lineCount = math.min(lineCount, 120)

	local castAbility = CastPreparedAbility(boss, "frostivus_boss_requiem_of_souls", {
		line_count = lineCount,
	}, boss:GetAbsOrigin() + Vector(0, -100, 0))
	if castAbility == nil then return nil end

	return GetAbilityCastPoint(castAbility) + 1.5
end

function modifier_xhs_banehallow_phase3_ai:SummonThresholdRevenants(threshold)
	local boss = self:GetParent()
	local count = GetThresholdConfig().revenants_per_point or 3
	GameMode.BanehallowRevenantsTotal = (GameMode.BanehallowRevenantsTotal or 0) + count
	GameMode.BanehallowRevenantsRemaining = (GameMode.BanehallowRevenantsRemaining or 0) + count

	for i = 1, count do
		local spawnerIndex = ((threshold + i) % 12) + 1
		local spawner = Entities:FindByName(nil, "npc_dota_spawner_green_revenant_" .. spawnerIndex)
		if spawner ~= nil then
			local revenant = CreateUnitByName("npc_death_revenant_banehallow", spawner:GetAbsOrigin(), true, nil, nil, DOTA_TEAM_CUSTOM_2)
			revenant:FaceTowards(boss:GetAbsOrigin())
			revenant:SetRenderColor(20, 200, 20)
			revenant.zone = "xhs_holdout"
		end
	end

	CustomGameEventManager:Send_ServerToAllClients("xhs_boss_counter_update", {
		boss_count = 1,
		boss_bar_id = GetBossBarId and GetBossBarId(boss) or boss.xhs_boss_bar_id,
		label = "Ghost Revenants",
		remaining = GameMode.BanehallowRevenantsRemaining,
		total = GameMode.BanehallowRevenantsTotal,
	})
end
