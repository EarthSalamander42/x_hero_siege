require("boss_scripts/phase3_ai/core")
require("boss_scripts/phase3_ai/telegraphs")
require("boss_scripts/phase3_ai/lich_king_abilities")

modifier_xhs_lich_king_phase3_ai = modifier_xhs_lich_king_phase3_ai or class({})
modifier_xhs_lich_king_phase3_ai.XHS_LINK_CLIENT = true
LinkLuaModifier("modifier_xhs_lich_king_phase3_ai", "boss_scripts/phase3_ai/lich_king.lua", LUA_MODIFIER_MOTION_NONE)

local LICH_KING_ABILITIES = {
	"xhs_lich_king_remorseless_winter",
	"xhs_lich_king_frostmourne_hunger",
	"xhs_lich_king_howling_blast",
	"xhs_lich_king_glacial_spikes",
	"xhs_lich_king_defile",
	"xhs_lich_king_sindragosa_flyby",
	"xhs_lich_king_frozen_throne",
}

local THRESHOLDS = { 75, 50, 25 }

local function IsValidAlive(unit)
	return unit ~= nil and IsValidEntity(unit) and not unit:IsNull() and unit:IsAlive()
end

local function GetLichKingArenaCenter(fallback)
	local point = Entities:FindByName(nil, "npc_dota_spawner_magtheridon_arena")
	if point ~= nil then return point:GetAbsOrigin() end
	point = Entities:FindByName(nil, "npc_dota_spawner_lich_king_bis")
	if point ~= nil then return point:GetAbsOrigin() end
	return fallback or Vector(0, 0, 0)
end

local function NormalizeDirection(direction)
	if direction == nil then return Vector(1, 0, 0) end
	direction.z = 0
	if direction:Length2D() <= 0 then return Vector(1, 0, 0) end
	return direction:Normalized()
end

local function SetAbilityContext(boss, abilityName, context)
	local ability = boss and boss:FindAbilityByName(abilityName)
	if ability == nil then return nil end
	ability.xhs_lich_king_context = context or {}
	ability.xhs_lich_king_context.arena_center = ability.xhs_lich_king_context.arena_center or GetLichKingArenaCenter(boss:GetAbsOrigin())
	return ability
end

local function CastPreparedAbility(boss, abilityName, context, position)
	if not IsValidAlive(boss) then return nil end
	local ability = SetAbilityContext(boss, abilityName, context)
	if ability == nil or not ability:IsCooldownReady() then return nil end
	XHSPhase3BossAI:ProtectCast(boss, ability, 0.2)
	if position ~= nil then
		ExecuteOrderFromTable({
			UnitIndex = boss:entindex(),
			OrderType = DOTA_UNIT_ORDER_CAST_POSITION,
			AbilityIndex = ability:entindex(),
			Position = position,
		})
	else
		ExecuteOrderFromTable({
			UnitIndex = boss:entindex(),
			OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET,
			AbilityIndex = ability:entindex(),
		})
	end
	return ability
end

function XHSLichKing_AttachPhase3AI(boss)
	if boss == nil or boss:IsNull() or boss:GetUnitName() ~= "npc_dota_boss_lich_king" then return end
	if boss:HasModifier("modifier_xhs_lich_king_phase3_ai") then return end
	boss:SetAttackCapability(DOTA_UNIT_CAP_MELEE_ATTACK)
	boss:SetMoveCapability(DOTA_UNIT_CAP_MOVE_GROUND)
	XHSPhase3BossAI:HideVanillaHealthBar(boss)
	XHSPhase3BossAI:SetAbilityLevels(boss, LICH_KING_ABILITIES)
	boss:AddNewModifier(boss, nil, "modifier_xhs_lich_king_phase3_ai", {})
end

function modifier_xhs_lich_king_phase3_ai:IsHidden() return true end
function modifier_xhs_lich_king_phase3_ai:IsPurgable() return false end

function modifier_xhs_lich_king_phase3_ai:OnCreated()
	if not IsServer() then return end
	self.boss = self:GetParent()
	self.arena_center = GetLichKingArenaCenter(self.boss:GetAbsOrigin())
	self.next_action = GameRules:GetGameTime() + 3.0
	self.thresholds_done = {}
	self.hero_positions = {}
	self.patterns = self:BuildPatternDeck()
	self:UpdateBossBarMarkers()
	ShowBossBar(self.boss)
	if XHSLichKing_UpdateSoulCounter ~= nil then XHSLichKing_UpdateSoulCounter(self.boss) end
	self:StartIntervalThink(0.25)
end

function modifier_xhs_lich_king_phase3_ai:OnDestroy()
	if not IsServer() then return end
	CustomGameEventManager:Send_ServerToAllClients("xhs_boss_counter_hide", {
		boss_count = self.boss and self.boss.boss_count or 1,
		boss_bar_id = self.boss and (GetBossBarId and GetBossBarId(self.boss) or self.boss.xhs_boss_bar_id) or nil,
	})
end

function modifier_xhs_lich_king_phase3_ai:BuildPatternDeck()
	return {
		{ name = "frostmourne", weight = 1.2, cooldown = 8.0, run = function() return self:CastFrostmourneHunger() end },
		{ name = "howling", weight = 1.4, cooldown = 7.0, run = function() return self:CastHowlingBlast() end },
		{ name = "spikes", weight = 1.3, cooldown = 9.5, run = function() return self:CastGlacialSpikes() end },
		{ name = "defile", weight = 1.0, cooldown = 11.0, run = function() return self:CastDefile() end },
	}
end

function modifier_xhs_lich_king_phase3_ai:UpdateBossBarMarkers()
	self.boss.xhs_boss_bar_markers = {
		{ percent = 75, label = "Sindragosa Flyby", tooltip = "Sindragosa attacks when this health threshold is crossed." },
		{ percent = 50, label = "Sindragosa Flyby", tooltip = "Sindragosa attacks when this health threshold is crossed." },
		{ percent = 25, label = "Sindragosa Flyby", tooltip = "Sindragosa attacks when this health threshold is crossed." },
	}
end

function modifier_xhs_lich_king_phase3_ai:IsBossActive()
	return IsValidAlive(self.boss) and self.boss.deathStart ~= true and not self.boss:IsInvulnerable()
end

function modifier_xhs_lich_king_phase3_ai:OnIntervalThink()
	if not IsServer() then return end
	if not self:IsBossActive() then return end
	if XHSPhase3BossAI:IsCastBlocked(self.boss) then return end

	self:TrackHeroPositions()

	local now = GameRules:GetGameTime()
	if self:TryThresholdWinter(now) then
		return
	end
	if self:TrySoulPoweredWinter(now) then
		return
	end

	if now < (self.next_action or 0) then return end

	local entry = XHSPhase3BossAI:WeightedChoice(self.patterns, now)
	if entry == nil then
		self.next_action = now + 1.0
		return
	end

	if entry.run() == true then
		entry.ready_at = now + entry.cooldown
		self.next_action = now + 2.2
	else
		entry.ready_at = now + 1.0
		self.next_action = now + 0.8
	end
end

function modifier_xhs_lich_king_phase3_ai:TrackHeroPositions()
	local heroes = XHSPhase3BossAI:GetLivingHeroes(self.arena_center, 2600, true)
	for _, hero in pairs(heroes) do
		if IsValidAlive(hero) then
			local key = tostring(hero:entindex())
			local current = hero:GetAbsOrigin()
			local previous = self.hero_positions[key]
			local velocity = Vector(0, 0, 0)
			if previous ~= nil then
				velocity = current - previous.position
			end
			self.hero_positions[key] = {
				position = current,
				velocity = velocity,
				time = GameRules:GetGameTime(),
			}
		end
	end
end

function modifier_xhs_lich_king_phase3_ai:GetPredictedHeroPosition(hero, lead)
	if not IsValidAlive(hero) then return self.arena_center end
	local data = self.hero_positions[tostring(hero:entindex())]
	if data == nil then return hero:GetAbsOrigin() end
	local velocity = data.velocity or Vector(0, 0, 0)
	return hero:GetAbsOrigin() + velocity * (lead or 2.0)
end

function modifier_xhs_lich_king_phase3_ai:PickHero(radius)
	local heroes = XHSPhase3BossAI:GetLivingHeroes(self.arena_center, radius or 2600, true)
	if #heroes <= 0 then return nil end
	return heroes[RandomInt(1, #heroes)]
end

function modifier_xhs_lich_king_phase3_ai:TryThresholdWinter(now)
	local pct = (self.boss:GetHealth() / math.max(1, self.boss:GetMaxHealth())) * 100
	for _, threshold in pairs(THRESHOLDS) do
		if self.thresholds_done[threshold] ~= true and pct <= threshold then
			self.thresholds_done[threshold] = true
			if self:CastSindragosaFlyby(0) then
				self.next_action = now + 4.5
				return true
			end
		end
	end
	return false
end

function modifier_xhs_lich_king_phase3_ai:GetFrozenThroneAbility()
	if not IsValidAlive(self.boss) then return nil end
	local ability = self.boss:FindAbilityByName("xhs_lich_king_frozen_throne")
	if ability == nil or ability:IsNull() or ability:GetLevel() <= 0 then return nil end
	return ability
end

function modifier_xhs_lich_king_phase3_ai:GetFrostmourneSouls()
	if not IsValidAlive(self.boss) then return 0 end
	local modifier = self.boss:FindModifierByName("modifier_xhs_lich_king_frozen_throne")
	if modifier == nil then return 0 end
	return modifier:GetStackCount()
end

function modifier_xhs_lich_king_phase3_ai:ConsumeFrostmourneSouls(amount)
	local modifier = self.boss:FindModifierByName("modifier_xhs_lich_king_frozen_throne")
	if modifier == nil then return 0 end

	local current = modifier:GetStackCount()
	local consumed = math.min(current, amount or current)
	modifier:SetStackCount(math.max(0, current - consumed))
	if XHSLichKing_UpdateSoulCounter ~= nil then XHSLichKing_UpdateSoulCounter(self.boss) end
	return consumed
end

function modifier_xhs_lich_king_phase3_ai:TrySoulPoweredWinter(now)
	if now < (self.next_action or 0) then return false end

	local ability = self:GetFrozenThroneAbility()
	if ability == nil then return false end

	local souls = self:GetFrostmourneSouls()
	local cost = math.max(1, ability:GetSpecialValueFor("winter_soul_cost"))
	if souls < cost then return false end

	local consumed = self:ConsumeFrostmourneSouls(cost)
	if self:CastRemorselessWinter(consumed) then
		self.next_action = now + 3.5
		return true
	end

	local modifier = self.boss:FindModifierByName("modifier_xhs_lich_king_frozen_throne")
	if modifier ~= nil then
		modifier:SetStackCount(souls)
	end
	if XHSLichKing_UpdateSoulCounter ~= nil then XHSLichKing_UpdateSoulCounter(self.boss) end
	return false
end

function modifier_xhs_lich_king_phase3_ai:CastRemorselessWinter(consumedSouls)
	local ability = CastPreparedAbility(self.boss, "xhs_lich_king_remorseless_winter", {
		consumed_souls = consumedSouls or 0,
	}, nil)
	return ability ~= nil
end

function modifier_xhs_lich_king_phase3_ai:CastFrostmourneHunger()
	local hero = self:PickHero(2600)
	if hero == nil then return false end
	local position = self:GetPredictedHeroPosition(hero, 1.4)
	local ability = CastPreparedAbility(self.boss, "xhs_lich_king_frostmourne_hunger", { position = position }, position)
	return ability ~= nil
end

function modifier_xhs_lich_king_phase3_ai:CastHowlingBlast()
	local hero = self:PickHero(2600)
	if hero == nil then return false end
	local target = self:GetPredictedHeroPosition(hero, 1.8)
	local direction = NormalizeDirection(target - self.boss:GetAbsOrigin())
	local ability = CastPreparedAbility(self.boss, "xhs_lich_king_howling_blast", { direction = direction }, self.boss:GetAbsOrigin() + direction * 600)
	return ability ~= nil
end

function modifier_xhs_lich_king_phase3_ai:BuildHeroPoints(baseCount, lead)
	local heroes = XHSPhase3BossAI:GetLivingHeroes(self.arena_center, 2600, true)
	local points = {}
	local count = math.min(#heroes, XHSPhase3BossAI:ScaleDensity(baseCount, 1))
	for index = 1, count do
		local hero = heroes[index]
		if IsValidAlive(hero) then
			table.insert(points, { position = self:GetPredictedHeroPosition(hero, lead or 1.6) })
		end
	end
	if #points <= 0 then
		table.insert(points, { position = self.arena_center })
	end
	return points
end

function modifier_xhs_lich_king_phase3_ai:CastGlacialSpikes()
	local ability = CastPreparedAbility(self.boss, "xhs_lich_king_glacial_spikes", {
		points = self:BuildHeroPoints(3, 1.7),
	}, self.arena_center)
	return ability ~= nil
end

function modifier_xhs_lich_king_phase3_ai:CastDefile()
	local ability = CastPreparedAbility(self.boss, "xhs_lich_king_defile", {
		points = self:BuildHeroPoints(2, 1.2),
	}, self.arena_center)
	return ability ~= nil
end

function modifier_xhs_lich_king_phase3_ai:CastSindragosaFlyby(consumedSouls)
	local difficulty = XHSPhase3BossAI:GetDifficulty()
	local laneCount = ({ 1, 2, 3, 4, 5 })[difficulty] or 1
	local throne = self:GetFrozenThroneAbility()
	if throne ~= nil and (consumedSouls or 0) > 0 then
		local soulCost = math.max(1, throne:GetSpecialValueFor("bonus_lane_soul_cost"))
		local maxBonus = math.max(0, throne:GetSpecialValueFor("max_bonus_lanes"))
		laneCount = laneCount + math.min(maxBonus, math.floor((consumedSouls or 0) / soulCost))
	end
	local directions = {}
	local baseAngle = RandomFloat(0, 180)
	for index = 1, laneCount do
		local angle = baseAngle + (index - 1) * 12
		table.insert(directions, RotatePosition(Vector(0, 0, 0), QAngle(0, angle, 0), Vector(1, 0, 0)))
	end
	local ability = CastPreparedAbility(self.boss, "xhs_lich_king_sindragosa_flyby", {
		center = self.arena_center,
		directions = directions,
	}, self.arena_center)
	return ability ~= nil
end
