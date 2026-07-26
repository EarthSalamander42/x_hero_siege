require("boss_scripts/phase3_ai/core")
require("boss_scripts/phase3_ai/telegraphs")
require("boss_scripts/phase3_ai/cast_bar")

xhs_arthas_judgment_of_lordaeron = xhs_arthas_judgment_of_lordaeron or class({})
xhs_arthas_frostmourne_mark = xhs_arthas_frostmourne_mark or class({})
xhs_arthas_frozen_chains = xhs_arthas_frozen_chains or class({})
xhs_arthas_death_advance = xhs_arthas_death_advance or class({})
xhs_arthas_frostmourne_execute = xhs_arthas_frostmourne_execute or class({})

modifier_xhs_arthas_mark = modifier_xhs_arthas_mark or class({})
modifier_xhs_arthas_mark.XHS_LINK_CLIENT = true
modifier_xhs_arthas_chains = modifier_xhs_arthas_chains or class({})
modifier_xhs_arthas_chains.XHS_LINK_CLIENT = true
modifier_xhs_arthas_judgment_lock = modifier_xhs_arthas_judgment_lock or class({})
modifier_xhs_arthas_judgment_lock.XHS_LINK_CLIENT = true
modifier_xhs_arthas_radiant_conviction = modifier_xhs_arthas_radiant_conviction or class({})
modifier_xhs_arthas_radiant_conviction.XHS_LINK_CLIENT = true

LinkLuaModifier("modifier_xhs_arthas_mark", "boss_scripts/phase3_ai/arthas_abilities.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_xhs_arthas_chains", "boss_scripts/phase3_ai/arthas_abilities.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_xhs_arthas_judgment_lock", "boss_scripts/phase3_ai/arthas_abilities.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_xhs_arthas_radiant_conviction", "boss_scripts/phase3_ai/arthas_abilities.lua", LUA_MODIFIER_MOTION_NONE)

local ARTHAS_COLORS = {
	primary = Vector(105, 215, 255),
	secondary = Vector(235, 250, 255),
	style = 7,
}

local DARK_COLORS = {
	primary = Vector(25, 70, 140),
	secondary = Vector(170, 225, 255),
	style = 6,
}

local LIGHT_COLORS = {
	primary = Vector(255, 235, 125),
	secondary = Vector(255, 255, 245),
	style = 2,
}

local JUDGMENT_BEACON_PARTICLE = "particles/units/heroes/hero_omniknight/omniknight_purification_cast.vpcf"
local JUDGMENT_IMPACT_PARTICLE = "particles/units/heroes/hero_omniknight/omniknight_purification_hit.vpcf"
local MARK_PARTICLE = "particles/units/heroes/hero_abaddon/abaddon_curse_counter_stack.vpcf"
local CHAINS_PARTICLE = "particles/units/heroes/hero_lich/lich_frost_nova.vpcf"
local DASH_PARTICLE = "particles/units/heroes/hero_sven/sven_spell_storm_bolt.vpcf"
local EXECUTE_PARTICLE = "particles/units/heroes/hero_skeletonking/skeletonking_hellfireblast_explosion.vpcf"

local function IsValidAlive(unit)
	return unit ~= nil and IsValidEntity(unit) and not unit:IsNull() and unit:IsAlive()
end

local function GetContext(ability)
	return ability.xhs_arthas_context or {}
end

local function ClearContext(ability)
	ability.xhs_arthas_context = nil
end

local function NormalizeDirection(direction)
	if direction == nil then return Vector(1, 0, 0) end
	direction.z = 0
	if direction:Length2D() <= 0 then return Vector(1, 0, 0) end
	return direction:Normalized()
end

local function ScaleDamage(value)
	if XHSPhase3BossAI ~= nil then return XHSPhase3BossAI:ScaleDamage(value) end
	return value or 0
end

local function StartBossCastBar(ability, displayName)
	if XHSBossCastBar ~= nil then
		XHSBossCastBar:Start(ability:GetCaster(), ability, {
			display_name = displayName,
			style = "arthas",
		})
	end
end

local function HideBossCastBar(ability)
	if XHSBossCastBar ~= nil then
		XHSBossCastBar:Hide(ability:GetCaster())
	end
end

local function CreateImpact(position, particleName, radius, duration)
	local p = ParticleManager:CreateParticle(particleName, PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleControl(p, 0, position)
	ParticleManager:SetParticleControl(p, 1, Vector(radius or 220, 0, 0))
	Timers:CreateTimer(duration or 1.0, function()
		ParticleManager:DestroyParticle(p, false)
		ParticleManager:ReleaseParticleIndex(p)
		return nil
	end)
end

local function DamageEnemies(caster, ability, position, radius, damage, damageType, onHit)
	if not IsValidAlive(caster) or position == nil then return end
	local enemies = FindUnitsInRadius(
		caster:GetTeamNumber(),
		position,
		nil,
		radius or 200,
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
		FIND_ANY_ORDER,
		false
	)
	for _, enemy in pairs(enemies) do
		if IsValidAlive(enemy) and not enemy:IsInvulnerable() then
			local finalDamage = damage or 0
			if enemy:HasModifier("modifier_xhs_arthas_mark") then
				finalDamage = finalDamage * (1 + (ability:GetSpecialValueFor("marked_bonus_pct") or 0) * 0.01)
			end
			local damageDealt = ApplyDamage({
				victim = enemy,
				attacker = caster,
				ability = ability,
				damage = finalDamage,
				damage_type = damageType or ability:GetAbilityDamageType(),
			})
			SendOverheadEventMessage(nil, OVERHEAD_ALERT_DAMAGE, enemy, damageDealt, nil)
			if onHit ~= nil then onHit(enemy) end
		end
	end
end

local function DamageLine(caster, ability, startPosition, direction, length, width, damage, onHit)
	direction = NormalizeDirection(direction)
	local enemies = FindUnitsInLine(
		caster:GetTeamNumber(),
		startPosition,
		startPosition + direction * length,
		nil,
		width or 180,
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES
	)
	for _, enemy in pairs(enemies) do
		if IsValidAlive(enemy) and not enemy:IsInvulnerable() then
			local finalDamage = damage or 0
			if enemy:HasModifier("modifier_xhs_arthas_mark") then
				finalDamage = finalDamage * (1 + (ability:GetSpecialValueFor("marked_bonus_pct") or 0) * 0.01)
			end
			local damageDealt = ApplyDamage({ victim = enemy, attacker = caster, ability = ability, damage = finalDamage, damage_type = ability:GetAbilityDamageType() })
			SendOverheadEventMessage(nil, OVERHEAD_ALERT_DAMAGE, enemy, damageDealt, nil)
			if onHit ~= nil then onHit(enemy) end
		end
	end
end

local function GetLivingHeroesAt(caster, position, radius)
	local heroes = FindUnitsInRadius(
		caster:GetTeamNumber(),
		position,
		nil,
		radius,
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO,
		DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
		FIND_ANY_ORDER,
		false
	)
	local living = {}
	for _, hero in pairs(heroes) do
		if IsValidAlive(hero) and not hero:IsInvulnerable() then
			table.insert(living, hero)
		end
	end
	return living
end

local function GetJudgmentPositions(center, count, ringRadius, offsetDegrees)
	local positions = {}
	count = math.max(1, count or 1)
	for index = 1, count do
		local angle = ((index - 1) / count) * 360 + (offsetDegrees or 0)
		table.insert(positions, RotatePosition(center, QAngle(0, angle, 0), center + Vector(ringRadius, 0, 0)))
	end
	return positions
end

local function TelegraphJudgmentLine(ability, center, position, duration)
	local direction = NormalizeDirection(position - center)
	local length = (position - center):Length2D()
	local nodes = math.max(2, ability:GetSpecialValueFor("beam_nodes"))
	XHSBossTelegraphs:Line(
		center,
		direction,
		length / math.max(1, nodes - 1),
		ability:GetSpecialValueFor("beam_width"),
		nodes,
		duration,
		LIGHT_COLORS,
		0
	)
end

local function CreateJudgmentLineImpacts(ability, center, direction, length, count)
	count = math.max(2, count or 2)
	for index = 1, count do
		local position = center + direction * (length * ((index - 1) / math.max(1, count - 1)))
		CreateImpact(position, JUDGMENT_IMPACT_PARTICLE, ability:GetSpecialValueFor("beam_width"), 0.8)
	end
end

local function GetArthasAI(caster)
	if caster == nil or caster:IsNull() then return nil end
	return caster:FindModifierByName("modifier_xhs_arthas_phase3_ai")
end

function xhs_arthas_judgment_of_lordaeron:GetAbilityTextureName() return "omniknight_guardian_angel" end
function xhs_arthas_frostmourne_mark:GetAbilityTextureName() return "custom/arthas_frostmourne" end
function xhs_arthas_frozen_chains:GetAbilityTextureName() return "lich_frost_nova" end
function xhs_arthas_death_advance:GetAbilityTextureName() return "custom/arthas_light_roar" end
function xhs_arthas_frostmourne_execute:GetAbilityTextureName() return "custom/arthas_frostmourne" end

function xhs_arthas_judgment_of_lordaeron:OnAbilityPhaseStart()
	if not IsServer() then return true end
	local caster = self:GetCaster()
	local center = GetContext(self).arena_center or caster:GetAbsOrigin()
	StartBossCastBar(self, "Judgment of Lordaeron")
	XHSBossTelegraphs:Circle(center, 260, self:GetCastPoint(), LIGHT_COLORS)
	StartAnimation(caster, { duration = self:GetCastPoint() + 0.25, activity = ACT_DOTA_CAST_ABILITY_5, rate = 0.75 })
	caster:EmitSound("Hero_Omniknight.GuardianAngel.Cast")
	return true
end

function xhs_arthas_judgment_of_lordaeron:OnAbilityPhaseInterrupted()
	if not IsServer() then return end
	HideBossCastBar(self)
	local context = GetContext(self)
	local ai = GetArthasAI(self:GetCaster())
	if ai ~= nil and ai.CancelJudgment ~= nil then
		ai:CancelJudgment(context.threshold)
	end
	ClearContext(self)
end

function xhs_arthas_judgment_of_lordaeron:OnSpellStart()
	if not IsServer() then return end
	local ability = self
	local caster = self:GetCaster()
	local context = GetContext(self)
	local threshold = context.threshold or 66
	local center = context.arena_center or caster:GetAbsOrigin()
	local telegraphDuration = self:GetSpecialValueFor("wave_telegraph")
	local waveGap = self:GetSpecialValueFor("wave_gap")
	local finalDelay = self:GetSpecialValueFor("final_delay")
	local finalTelegraph = self:GetSpecialValueFor("final_telegraph")
	local waveCount = threshold <= 33
		and math.max(1, self:GetSpecialValueFor("lower_threshold_waves"))
		or math.max(1, self:GetSpecialValueFor("upper_threshold_waves"))
	local sequenceDuration = waveCount * telegraphDuration
		+ math.max(0, waveCount - 1) * waveGap
		+ finalDelay
		+ finalTelegraph
		+ 0.5

	local heroes = XHSPhase3BossAI:GetLivingHeroes(center, 3000, true)
	local beaconCount = math.max(1, math.min(#heroes, math.max(1, self:GetSpecialValueFor("max_beacons"))))
	local ringRadius = self:GetSpecialValueFor("beacon_ring_radius")
	local soakRadius = self:GetSpecialValueFor("soak_radius")
	local state = { charges = 0 }

	local ai = GetArthasAI(caster)
	if ai ~= nil and ai.CommitJudgment ~= nil then
		ai:CommitJudgment(threshold, sequenceDuration)
	end

	FindClearSpaceForUnit(caster, center, true)
	caster:Stop()
	caster:AddNewModifier(caster, self, "modifier_xhs_arthas_judgment_lock", { duration = sequenceDuration })
	local conviction = caster:AddNewModifier(caster, self, "modifier_xhs_arthas_radiant_conviction", { duration = sequenceDuration })
	if conviction ~= nil then conviction:SetStackCount(0) end
	CreateImpact(center, JUDGMENT_IMPACT_PARTICLE, 260, 1.0)
	caster:EmitSound("Hero_Omniknight.Purification")

	local StartWave
	local StartFinalJudgment

	StartFinalJudgment = function()
		if not IsValidAlive(caster) or ability == nil or ability:IsNull() then return end
		local baseLines = math.max(1, ability:GetSpecialValueFor("final_base_lines"))
		local extraLines = math.min(state.charges, math.max(0, ability:GetSpecialValueFor("max_extra_lines")))
		local lineCount = baseLines + extraLines
		local lineLength = ability:GetSpecialValueFor("final_range")
		local lineWidth = ability:GetSpecialValueFor("final_width")
		local angleOffset = RandomFloat(0, 360 / math.max(1, lineCount))
		local directions = {}

		for index = 1, lineCount do
			local angle = angleOffset + ((index - 1) / lineCount) * 360
			local direction = RotatePosition(Vector(0, 0, 0), QAngle(0, angle, 0), Vector(1, 0, 0))
			table.insert(directions, direction)
			local nodes = math.max(3, math.floor(lineLength / math.max(1, lineWidth * 1.2)))
			XHSBossTelegraphs:Line(center, direction, lineLength / math.max(1, nodes - 1), lineWidth, nodes, finalTelegraph, LIGHT_COLORS, 0)
		end

		StartAnimation(caster, { duration = finalTelegraph + 0.4, activity = ACT_DOTA_CAST_ABILITY_4, rate = 0.75 })
		caster:EmitSound("Hero_Omniknight.GuardianAngel.Cast")
		Timers:CreateTimer(finalTelegraph, function()
			if not IsValidAlive(caster) or ability == nil or ability:IsNull() then return nil end
			local damage = ScaleDamage(ability:GetSpecialValueFor("final_damage"))
			DamageEnemies(caster, ability, center, 320, damage, ability:GetAbilityDamageType())
			for _, direction in ipairs(directions) do
				DamageLine(caster, ability, center, direction, lineLength, lineWidth, damage)
				CreateJudgmentLineImpacts(ability, center, direction, lineLength, ability:GetSpecialValueFor("beam_nodes"))
			end
			CreateImpact(center, JUDGMENT_IMPACT_PARTICLE, 320, 1.0)
			caster:EmitSound("Hero_Omniknight.Purification")
			caster:RemoveModifierByName("modifier_xhs_arthas_radiant_conviction")
			caster:RemoveModifierByName("modifier_xhs_arthas_judgment_lock")
			return nil
		end)
	end

	StartWave = function(waveIndex)
		if not IsValidAlive(caster) or ability == nil or ability:IsNull() then return end
		local offset = (waveIndex - 1) * (180 / math.max(1, beaconCount))
		local positions = GetJudgmentPositions(center, beaconCount, ringRadius, offset)

		for _, position in ipairs(positions) do
			XHSBossTelegraphs:Target(position, soakRadius, telegraphDuration, LIGHT_COLORS)
			TelegraphJudgmentLine(ability, center, position, telegraphDuration)
			CreateImpact(position, JUDGMENT_BEACON_PARTICLE, soakRadius, telegraphDuration)
		end

		Timers:CreateTimer(telegraphDuration, function()
			if not IsValidAlive(caster) or ability == nil or ability:IsNull() then return nil end
			for _, position in ipairs(positions) do
				local soakers = GetLivingHeroesAt(caster, position, soakRadius)
				if #soakers > 0 then
					DamageEnemies(caster, ability, position, soakRadius, ScaleDamage(ability:GetSpecialValueFor("intercept_damage")), ability:GetAbilityDamageType())
					CreateImpact(position, JUDGMENT_IMPACT_PARTICLE, soakRadius, 1.0)
					EmitSoundOnLocationWithCaster(position, "Hero_Omniknight.Purification", caster)
				else
					state.charges = state.charges + 1
					if conviction ~= nil and not conviction:IsNull() then
						conviction:SetStackCount(state.charges)
					end
					local direction = NormalizeDirection(position - center)
					CreateJudgmentLineImpacts(ability, center, direction, ringRadius, ability:GetSpecialValueFor("beam_nodes"))
					CreateImpact(center, JUDGMENT_IMPACT_PARTICLE, 180, 0.8)
				end
			end

			if waveIndex < waveCount then
				Timers:CreateTimer(waveGap, function()
					StartWave(waveIndex + 1)
					return nil
				end)
			else
				Timers:CreateTimer(finalDelay, function()
					StartFinalJudgment()
					return nil
				end)
			end
			return nil
		end)
	end

	StartWave(1)
	ClearContext(self)
end

function xhs_arthas_frostmourne_mark:OnAbilityPhaseStart()
	if not IsServer() then return true end
	local target = GetContext(self).target
	StartBossCastBar(self, "Frostmourne Mark")
	if IsValidAlive(target) then
		XHSBossTelegraphs:Target(target:GetAbsOrigin(), self:GetSpecialValueFor("radius"), self:GetCastPoint(), DARK_COLORS)
	end
	StartAnimation(self:GetCaster(), { duration = self:GetCastPoint() + 0.15, activity = ACT_DOTA_CAST_ABILITY_1, rate = 0.9 })
	self:GetCaster():EmitSound("Hero_Abaddon.Curse.Proc")
	return true
end

function xhs_arthas_frostmourne_mark:OnAbilityPhaseInterrupted() if IsServer() then HideBossCastBar(self) end end
function xhs_arthas_frostmourne_mark:OnSpellStart()
	if not IsServer() then return end
	local target = GetContext(self).target
	if IsValidAlive(target) then
		target:AddNewModifier(self:GetCaster(), self, "modifier_xhs_arthas_mark", { duration = self:GetSpecialValueFor("duration") })
		target:EmitSound("Hero_Abaddon.Curse.Proc")
	end
	ClearContext(self)
end

function xhs_arthas_frozen_chains:OnAbilityPhaseStart()
	if not IsServer() then return true end
	local position = GetContext(self).position or self:GetCaster():GetAbsOrigin()
	StartBossCastBar(self, "Frozen Chains")
	XHSBossTelegraphs:Target(position, self:GetSpecialValueFor("radius"), self:GetCastPoint(), ARTHAS_COLORS)
	StartAnimation(self:GetCaster(), { duration = self:GetCastPoint() + 0.2, activity = ACT_DOTA_CAST_ABILITY_2, rate = 0.85 })
	self:GetCaster():EmitSound("Hero_Crystal.Frostbite")
	return true
end

function xhs_arthas_frozen_chains:OnAbilityPhaseInterrupted() if IsServer() then HideBossCastBar(self) end end
function xhs_arthas_frozen_chains:OnSpellStart()
	if not IsServer() then return end
	local caster = self:GetCaster()
	local position = GetContext(self).position or caster:GetAbsOrigin()
	local radius = self:GetSpecialValueFor("radius")
	DamageEnemies(caster, self, position, radius, ScaleDamage(self:GetSpecialValueFor("damage")), self:GetAbilityDamageType(), function(enemy)
		enemy:AddNewModifier(caster, self, "modifier_xhs_arthas_chains", { duration = self:GetSpecialValueFor("root_duration") })
	end)
	CreateImpact(position, CHAINS_PARTICLE, radius, 1.0)
	EmitSoundOnLocationWithCaster(position, "Hero_Lich.FrostBlast", caster)
	ClearContext(self)
end

function xhs_arthas_death_advance:OnAbilityPhaseStart()
	if not IsServer() then return true end
	local caster = self:GetCaster()
	local position = GetContext(self).position or caster:GetAbsOrigin() + caster:GetForwardVector() * 600
	local direction = NormalizeDirection(position - caster:GetAbsOrigin())
	local length = math.min(self:GetSpecialValueFor("range"), math.max(220, (position - caster:GetAbsOrigin()):Length2D()))
	StartBossCastBar(self, "Death Advance")
	XHSBossTelegraphs:Line(caster:GetAbsOrigin(), direction, self:GetSpecialValueFor("width") * 1.25, self:GetSpecialValueFor("width"), math.max(1, math.floor(length / math.max(1, self:GetSpecialValueFor("width") * 1.25))), self:GetCastPoint(), DARK_COLORS, 120)
	StartAnimation(caster, { duration = self:GetCastPoint() + 0.2, activity = ACT_DOTA_CAST_ABILITY_3, rate = 1.0 })
	caster:EmitSound("Hero_Sven.StormBolt")
	return true
end

function xhs_arthas_death_advance:OnAbilityPhaseInterrupted() if IsServer() then HideBossCastBar(self) end end
function xhs_arthas_death_advance:OnSpellStart()
	if not IsServer() then return end
	local caster = self:GetCaster()
	local position = GetContext(self).position or caster:GetAbsOrigin() + caster:GetForwardVector() * 600
	local direction = NormalizeDirection(position - caster:GetAbsOrigin())
	local length = math.min(self:GetSpecialValueFor("range"), math.max(220, (position - caster:GetAbsOrigin()):Length2D()))
	local start = caster:GetAbsOrigin()
	DamageLine(caster, self, start, direction, length, self:GetSpecialValueFor("width"), ScaleDamage(self:GetSpecialValueFor("damage")), function(enemy)
		enemy:EmitSound("Hero_Sven.StormBoltImpact")
	end)
	local p = ParticleManager:CreateParticle(DASH_PARTICLE, PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleControl(p, 0, start)
	ParticleManager:SetParticleControl(p, 1, start + direction * length)
	Timers:CreateTimer(0.8, function()
		ParticleManager:DestroyParticle(p, false)
		ParticleManager:ReleaseParticleIndex(p)
		return nil
	end)
	FindClearSpaceForUnit(caster, start + direction * length, true)
	ClearContext(self)
end

function xhs_arthas_frostmourne_execute:OnAbilityPhaseStart()
	if not IsServer() then return true end
	local position = GetContext(self).position or self:GetCaster():GetAbsOrigin()
	StartBossCastBar(self, "Frostmourne Execute")
	XHSBossTelegraphs:Circle(position, self:GetSpecialValueFor("radius"), self:GetCastPoint(), DARK_COLORS)
	StartAnimation(self:GetCaster(), { duration = self:GetCastPoint() + 0.3, activity = ACT_DOTA_CAST_ABILITY_4, rate = 0.75 })
	self:GetCaster():EmitSound("Hero_SkeletonKing.Reincarnate")
	return true
end

function xhs_arthas_frostmourne_execute:OnAbilityPhaseInterrupted() if IsServer() then HideBossCastBar(self) end end
function xhs_arthas_frostmourne_execute:OnSpellStart()
	if not IsServer() then return end
	local caster = self:GetCaster()
	local position = GetContext(self).position or caster:GetAbsOrigin()
	local radius = self:GetSpecialValueFor("radius")
	DamageEnemies(caster, self, position, radius, ScaleDamage(self:GetSpecialValueFor("damage")), self:GetAbilityDamageType())
	CreateImpact(position, EXECUTE_PARTICLE, radius, 1.0)
	EmitSoundOnLocationWithCaster(position, "Hero_SkeletonKing.Hellfire_BlastImpact", caster)
	ClearContext(self)
end

function modifier_xhs_arthas_mark:IsPurgable() return false end
function modifier_xhs_arthas_mark:IsDebuff() return true end
function modifier_xhs_arthas_mark:GetTexture() return "custom/arthas_frostmourne" end
function modifier_xhs_arthas_mark:OnCreated()
	if not IsServer() then return end
	local parent = self:GetParent()
	self.pfx = ParticleManager:CreateParticle(MARK_PARTICLE, PATTACH_OVERHEAD_FOLLOW, parent)
	ParticleManager:SetParticleControlEnt(self.pfx, 0, parent, PATTACH_OVERHEAD_FOLLOW, "attach_hitloc", parent:GetAbsOrigin(), true)
	ParticleManager:SetParticleControl(self.pfx, 1, Vector(1, 0, 0))
end
function modifier_xhs_arthas_mark:OnDestroy()
	if not IsServer() then return end
	if self.pfx ~= nil then
		ParticleManager:DestroyParticle(self.pfx, false)
		ParticleManager:ReleaseParticleIndex(self.pfx)
	end
end

function modifier_xhs_arthas_chains:IsPurgable() return true end
function modifier_xhs_arthas_chains:IsDebuff() return true end
function modifier_xhs_arthas_chains:GetTexture() return "lich_frost_nova" end
function modifier_xhs_arthas_chains:DeclareFunctions()
	return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE }
end
function modifier_xhs_arthas_chains:GetModifierMoveSpeedBonus_Percentage() return -45 end
function modifier_xhs_arthas_chains:CheckState()
	return {
		[MODIFIER_STATE_ROOTED] = true,
	}
end

function modifier_xhs_arthas_judgment_lock:IsHidden() return true end
function modifier_xhs_arthas_judgment_lock:IsPurgable() return false end
function modifier_xhs_arthas_judgment_lock:CheckState()
	return {
		[MODIFIER_STATE_INVULNERABLE] = true,
		[MODIFIER_STATE_STUNNED] = true,
		[MODIFIER_STATE_DISARMED] = true,
		[MODIFIER_STATE_SILENCED] = true,
	}
end

function modifier_xhs_arthas_radiant_conviction:IsHidden() return false end
function modifier_xhs_arthas_radiant_conviction:IsPurgable() return false end
function modifier_xhs_arthas_radiant_conviction:GetTexture() return "omniknight_guardian_angel" end
