require("boss_scripts/phase3_ai/core")

LinkLuaModifier("modifier_xhs_banehallow_phase3_ai", "boss_scripts/phase3_ai/banehallow.lua", LUA_MODIFIER_MOTION_NONE)

modifier_xhs_banehallow_phase3_ai = modifier_xhs_banehallow_phase3_ai or class({})

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

local BANEHALLOW_HP_THRESHOLDS = { 75, 50, 25 }

function modifier_xhs_banehallow_phase3_ai:IsHidden() return true end
function modifier_xhs_banehallow_phase3_ai:IsPurgable() return false end

function modifier_xhs_banehallow_phase3_ai:OnCreated(params)
	if not IsServer() then return end

	local boss = self:GetParent()
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

	XHSPhase3BossAI:SetAbilityLevels(boss, BANEHALLOW_ABILITIES)
	self:UpdateBossBarMarkers()
	self:CreateCosmetics()
	self:BuildPatternDeck()
	self:StartIntervalThink(0.25)
end

function modifier_xhs_banehallow_phase3_ai:OnDestroy()
	if not IsServer() then return end

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
	self:TrySoulHarvest(now)

	if boss:HasModifier("modifier_invulnerable") or boss:HasModifier("modifier_pause_creeps") then
		self.state = "intro"
		return
	end

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

	for _, threshold in pairs(BANEHALLOW_HP_THRESHOLDS) do
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
	boss.xhs_boss_bar_markers = {}

	for index, threshold in pairs(BANEHALLOW_HP_THRESHOLDS) do
		boss.xhs_boss_bar_markers[index] = {
			pct = threshold,
			kind = "companion",
			label = "Ghost Revenants",
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
	StartAnimation(boss, { duration = 1.04, activity = ACT_DOTA_ATTACK, rate = 1.0 })

	Timers:CreateTimer(0.5, function()
		if not self:IsBossActive() or target == nil or target:IsNull() or not target:IsAlive() then return nil end

		ProjectileManager:CreateTrackingProjectile({
			Target = target,
			Source = boss,
			Ability = ability,
			EffectName = "particles/econ/items/shadow_fiend/sf_desolation/sf_base_attack_desolation_fire_arcana.vpcf",
			bDodgeable = true,
			bProvidesVision = false,
			bVisibleToEnemies = true,
			bReplaceExisting = false,
			iMoveSpeed = 1200,
			iVisionRadius = 0,
			iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_ATTACK_1,
			ExtraData = { damage = XHSPhase3BossAI:ScaleDamage(damage) },
		})
	end)
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

	boss:FaceTowards(targetPosition)
	StartAnimation(boss, { duration = delay, activity = ACT_DOTA_RAZE_3, rate = 1.0 })

	local count = XHSPhase3BossAI:ScaleDensity(7, 5)
	for i = 1, count do
		local point = boss:GetAbsOrigin() + direction * (radius * 0.5 + spawnDistance * (i - 1))
		self:Raze(point, false, delay)
	end

	Timers:CreateTimer(delay, function()
		if self:IsBossActive() then boss:EmitSound("Hero_Nevermore.Shadowraze") end
	end)

	return delay + 0.4
end

function modifier_xhs_banehallow_phase3_ai:CastSoulRings()
	local boss = self:GetParent()
	local ability = boss:FindAbilityByName("frostivus_boss_shadowraze")
	if ability == nil then return nil end

	local delay = XHSPhase3BossAI:ScaleDelay(ability:GetSpecialValueFor("delay"))
	local nearHeroes = XHSPhase3BossAI:GetLivingHeroes(boss:GetAbsOrigin(), 550, true)
	local distance = #nearHeroes >= 1 and 650 or 375
	local count = distance > 450 and XHSPhase3BossAI:ScaleDensity(12, 8) or XHSPhase3BossAI:ScaleDensity(6, 4)

	boss:FaceTowards(boss:GetAbsOrigin() + Vector(0, -100, 0))
	StartAnimation(boss, { duration = delay, activity = distance > 450 and ACT_DOTA_RAZE_2 or ACT_DOTA_RAZE_1, rate = 1.0 })

	for i = 1, count do
		local point = RotatePosition(self.arena_center, QAngle(0, 360 / count * (i - 1), 0), self.arena_center + Vector(0, distance, 0))
		self:Raze(point, false, delay)
	end

	Timers:CreateTimer(delay, function()
		if self:IsBossActive() then boss:EmitSound("Hero_Nevermore.Shadowraze") end
	end)

	return delay + 0.5
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
			local damage_dealt = ApplyDamage({ victim = enemy, attacker = boss, ability = nil, damage = damage, damage_type = DAMAGE_TYPE_PURE })
			SendOverheadEventMessage(nil, OVERHEAD_ALERT_BONUS_SPELL_DAMAGE, enemy, damage_dealt, nil)
			self:ApplyNecromastery(1)
		end
	end)
end

function modifier_xhs_banehallow_phase3_ai:CastMeteorHunt()
	local boss = self:GetParent()
	local ability = boss:FindAbilityByName("frostivus_boss_meteorain")
	if ability == nil then return nil end

	local delay = XHSPhase3BossAI:ScaleDelay(ability:GetSpecialValueFor("delay"))
	local duration = XHSPhase3BossAI:ScaleDelay(ability:GetSpecialValueFor("duration"))
	local spawnDelay = XHSPhase3BossAI:ScaleDelay(ability:GetSpecialValueFor("spawn_delay"))
	local spawnAmount = XHSPhase3BossAI:ScaleDensity(ability:GetSpecialValueFor("spawn_amount"), 2)
	local radius = ability:GetSpecialValueFor("radius")
	local damage = XHSPhase3BossAI:ScaleDamage(ability:GetSpecialValueFor("damage"))

	boss:EmitSound("Hero_Invoker.ChaosMeteor.Cast")
	boss:FaceTowards(self.arena_center)
	StartAnimation(boss, { duration = delay + 1.0, activity = ACT_DOTA_IDLE_RARE, rate = 1.0 })

	Timers:CreateTimer(delay, function()
		if not self:IsBossActive() then return nil end

		local elapsed = 0
		local spawned = 0
		Timers:CreateTimer(0, function()
			if not self:IsBossActive() or spawned >= spawnAmount then return nil end

			local heroes = XHSPhase3BossAI:GetLivingHeroes(self.arena_center, 2200, true)
			for _, hero in pairs(heroes) do
				if spawned >= spawnAmount then break end
				self:Meteor(self:GetPredictedHeroPosition(hero), radius, damage)
				spawned = spawned + 1
			end

			elapsed = elapsed + spawnDelay
			if elapsed <= duration and spawned < spawnAmount then
				return spawnDelay
			end
		end)
	end)

	return delay + duration + 1.8
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
			local damage_dealt = ApplyDamage({ victim = enemy, attacker = boss, ability = nil, damage = damage, damage_type = DAMAGE_TYPE_PURE })
			SendOverheadEventMessage(nil, OVERHEAD_ALERT_BONUS_SPELL_DAMAGE, enemy, damage_dealt, nil)
			self:ApplyNecromastery(1)
		end
	end)
end

function modifier_xhs_banehallow_phase3_ai:CastRagnaMark()
	local boss = self:GetParent()
	local ability = boss:FindAbilityByName("frostivus_boss_ragna_blade")
	if ability == nil then return nil end

	local delay = XHSPhase3BossAI:ScaleDelay(ability:GetSpecialValueFor("delay"))
	local targetAmount = XHSPhase3BossAI:ScaleDensity(ability:GetSpecialValueFor("target_amount"), 1)
	local damagePct = ability:GetSpecialValueFor("damage_pct")
	local heroes = XHSPhase3BossAI:GetLivingHeroes(self.arena_center, 2200, true)
	local targets = {}

	for _, hero in pairs(heroes) do
		targets[#targets + 1] = hero
		if #targets >= targetAmount then break end
	end

	if #targets <= 0 then return nil end

	for _, target in pairs(targets) do
		local warning_pfx = ParticleManager:CreateParticle("particles/boss_nevermore/ragna_blade_pre_warning.vpcf", PATTACH_OVERHEAD_FOLLOW, target)
		ParticleManager:SetParticleControl(warning_pfx, 0, target:GetAbsOrigin())
		target:EmitSound("Frostivus.AbilityWarning")

		Timers:CreateTimer(delay, function()
			ParticleManager:DestroyParticle(warning_pfx, true)
			ParticleManager:ReleaseParticleIndex(warning_pfx)
		end)
	end

	Timers:CreateTimer(math.max(0.1, delay - 0.85), function()
		if not self:IsBossActive() or targets[1] == nil or targets[1]:IsNull() then return nil end
		boss:FaceTowards(targets[1]:GetAbsOrigin())
		StartAnimation(boss, { duration = 1.75, activity = ACT_DOTA_VICTORY, rate = 2.0 })
	end)

	Timers:CreateTimer(delay, function()
		if not self:IsBossActive() then return nil end

		boss:EmitSound("Hero_Lina.LagunaBlade.Immortal")
		for _, target in pairs(targets) do
			if target ~= nil and not target:IsNull() and target:IsAlive() then
				target:EmitSound("Hero_Lina.LagunaBladeImpact.Immortal")
				local impact_pfx = ParticleManager:CreateParticle("particles/boss_nevermore/ragna_blade.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
				ParticleManager:SetParticleControlEnt(impact_pfx, 0, boss, PATTACH_POINT_FOLLOW, "attach_head", boss:GetAbsOrigin(), true)
				ParticleManager:SetParticleControlEnt(impact_pfx, 1, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
				ParticleManager:ReleaseParticleIndex(impact_pfx)

				local damage = target:GetMaxHealth() / 100 * damagePct
				local damage_dealt = ApplyDamage({ victim = target, attacker = boss, ability = nil, damage = damage, damage_type = DAMAGE_TYPE_PURE })
				SendOverheadEventMessage(nil, OVERHEAD_ALERT_DAMAGE, target, damage_dealt, nil)
				self:ApplyNecromastery(1)
			end
		end
	end)

	return delay + 0.8
end

function modifier_xhs_banehallow_phase3_ai:CastDarkness()
	local boss = self:GetParent()
	local ability = boss:FindAbilityByName("frostivus_boss_nevermore")
	if ability == nil then return nil end

	local delay = XHSPhase3BossAI:ScaleDelay(ability:GetSpecialValueFor("delay"))
	local duration = XHSPhase3BossAI:ScaleDelay(ability:GetSpecialValueFor("duration"))

	boss:EmitSound("Hero_Nevermore.RequiemOfSoulsCast")
	boss:FaceTowards(self.arena_center)
	StartAnimation(boss, { duration = delay + 1.0, activity = ACT_DOTA_VERSUS, rate = 2.0 })

	Timers:CreateTimer(delay, function()
		if not self:IsBossActive() then return nil end

		for player_id = 0, 20 do
			local player = PlayerResource:GetPlayer(player_id)
			if player ~= nil and PlayerResource:GetTeam(player_id) == self.team then
				local hero = PlayerResource:GetSelectedHeroEntity(player_id)
				if hero ~= nil then
					local pfx = ParticleManager:CreateParticleForPlayer("particles/boss_nevermore/screen_requiem_indicator.vpcf", PATTACH_EYES_FOLLOW, hero, player)
					self:AddParticle(pfx, false, false, -1, false, false)
					Timers:CreateTimer(duration, function()
						ParticleManager:DestroyParticle(pfx, true)
						ParticleManager:ReleaseParticleIndex(pfx)
					end)
				end
			end
		end

		Timers:CreateTimer(math.max(0.2, duration * 0.45), function()
			if self:IsBossActive() then
				self:CastSoulRings()
			end
		end)
	end)

	return delay + duration + 2.0
end

function modifier_xhs_banehallow_phase3_ai:CastRequiem()
	local boss = self:GetParent()
	local ability = boss:FindAbilityByName("frostivus_boss_requiem_of_souls")
	if ability == nil then return nil end

	local delay = XHSPhase3BossAI:ScaleDelay(ability:GetSpecialValueFor("delay"))
	local baseLineAmount = ability:GetSpecialValueFor("line_amount")
	local lineDamage = XHSPhase3BossAI:ScaleDamage(ability:GetSpecialValueFor("damage"))
	local distance = ability:GetSpecialValueFor("distance")
	local stacks = self:GetNecromasteryStacks()

	Timers:CreateTimer(math.max(0.1, delay - 1.65), function()
		if not self:IsBossActive() then return nil end
		boss:FaceTowards(boss:GetAbsOrigin() + Vector(0, -100, 0))
		boss:EmitSound("Hero_Nevermore.ROS.Arcana.Cast")
		StartAnimation(boss, { duration = 2.0, activity = ACT_DOTA_RAZE_3, rate = 0.35 })
	end)

	Timers:CreateTimer(delay, function()
		if not self:IsBossActive() then return nil end

		boss:EmitSound("Hero_Nevermore.ROS.Arcana")
		local necromastery = boss:FindModifierByName("modifier_frostivus_necromastery")
		if necromastery ~= nil then
			necromastery:SetStackCount(0)
		end

		local lineCount = XHSPhase3BossAI:ScaleDensity(baseLineAmount, 32) + math.floor(stacks * 0.5)
		lineCount = math.min(lineCount, 120)
		local bossLoc = boss:GetAbsOrigin()
		local north = bossLoc + Vector(0, 700, 0)

		for i = 1, lineCount do
			local velocity = (RotatePosition(bossLoc, QAngle(0, (i - 1) * 360 / lineCount, 0), north) - bossLoc):Normalized() * 700
			ProjectileManager:CreateLinearProjectile({
				Ability = ability,
				EffectName = "particles/units/heroes/hero_nevermore/nevermore_requiemofsouls_line.vpcf",
				vSpawnOrigin = bossLoc,
				fDistance = distance,
				fStartRadius = 125,
				fEndRadius = 300,
				Source = boss,
				bHasFrontalCone = false,
				bReplaceExisting = false,
				iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
				iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
				iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
				fExpireTime = GameRules:GetGameTime() + 10.0,
				bDeleteOnHit = false,
				vVelocity = Vector(velocity.x, velocity.y, 0),
				bProvidesVision = false,
				ExtraData = { damage = lineDamage },
			})

			local line_pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_nevermore/nevermore_requiemofsouls_line.vpcf", PATTACH_ABSORIGIN, boss)
			ParticleManager:SetParticleControl(line_pfx, 0, bossLoc)
			ParticleManager:SetParticleControl(line_pfx, 1, velocity)
			ParticleManager:SetParticleControl(line_pfx, 2, Vector(0, 9 / 7, 0))
			ParticleManager:ReleaseParticleIndex(line_pfx)
		end
	end)

	return delay + 1.5
end

function modifier_xhs_banehallow_phase3_ai:SummonThresholdRevenants(threshold)
	local boss = self:GetParent()
	local count = XHSPhase3BossAI:ScaleDensity(4, 3)
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
		label = "Ghost Revenants",
		remaining = GameMode.BanehallowRevenantsRemaining,
		total = GameMode.BanehallowRevenantsTotal,
	})
end
