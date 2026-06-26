require("boss_scripts/phase3_ai/core")
require("boss_scripts/phase3_ai/telegraphs")
require("boss_scripts/phase3_ai/cast_bar")

xhs_proudmoore_admirals_command = xhs_proudmoore_admirals_command or class({})
xhs_proudmoore_torrent_line = xhs_proudmoore_torrent_line or class({})
xhs_proudmoore_broadside = xhs_proudmoore_broadside or class({})
xhs_proudmoore_anchor_smash = xhs_proudmoore_anchor_smash or class({})
xhs_proudmoore_focus_fire = xhs_proudmoore_focus_fire or class({})
xhs_proudmoore_command_aura = xhs_proudmoore_command_aura or class({})

LinkLuaModifier("modifier_xhs_proudmoore_command", "boss_scripts/phase3_ai/proudmoore_abilities.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_xhs_proudmoore_anchor_slow", "boss_scripts/phase3_ai/proudmoore_abilities.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_xhs_proudmoore_torrent_slow", "boss_scripts/phase3_ai/proudmoore_abilities.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_xhs_proudmoore_command_aura", "boss_scripts/phase3_ai/proudmoore_abilities.lua", LUA_MODIFIER_MOTION_NONE)

modifier_xhs_proudmoore_command = modifier_xhs_proudmoore_command or class({})
modifier_xhs_proudmoore_anchor_slow = modifier_xhs_proudmoore_anchor_slow or class({})
modifier_xhs_proudmoore_torrent_slow = modifier_xhs_proudmoore_torrent_slow or class({})
modifier_xhs_proudmoore_command_aura = modifier_xhs_proudmoore_command_aura or class({})

local PROUDMOORE_COLORS = {
	primary = Vector(70, 190, 255),
	secondary = Vector(255, 215, 95),
	style = 7,
}

local TORRENT_SPLASH_PARTICLE = "particles/hero/kunkka/torrent_splash.vpcf"
local GHOSTSHIP_SPLASH_PARTICLE = "particles/econ/items/kunkka/kunkka_immortal/kunkka_immortal_ghost_ship_splash.vpcf"
local ANCHOR_SMASH_PARTICLE = "particles/units/heroes/hero_tidehunter/tidehunter_anchor_hero.vpcf"
local TIDEBRINGER_PARTICLE = "particles/econ/items/kunkka/kunkka_weapon_whaleblade/kunkka_spell_tidebringer.vpcf"

local function IsValidAlive(unit)
	return unit ~= nil and IsValidEntity(unit) and not unit:IsNull() and unit:IsAlive()
end

local function GetContext(ability)
	return ability.xhs_proudmoore_context or {}
end

local function ClearContext(ability)
	ability.xhs_proudmoore_context = nil
end

local function NormalizeDirection(direction)
	if direction == nil then return Vector(1, 0, 0) end
	direction.z = 0
	if direction:Length2D() <= 0 then return Vector(1, 0, 0) end
	return direction:Normalized()
end

local function StartBossCastBar(ability, displayName)
	if XHSBossCastBar ~= nil then
		XHSBossCastBar:Start(ability:GetCaster(), ability, {
			display_name = displayName,
			style = "proudmoore",
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
				damage_type = damageType or DAMAGE_TYPE_MAGICAL,
			})
			if onHit ~= nil then
				onHit(enemy)
			end
		end
	end
end

local function DamageLine(caster, ability, startPosition, direction, length, width, damage)
	if not IsValidAlive(caster) then return end

	direction = NormalizeDirection(direction)
	local enemies = FindUnitsInLine(
		caster:GetTeamNumber(),
		startPosition,
		startPosition + direction * length,
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
				damage_type = DAMAGE_TYPE_PURE,
			})
		end
	end
end

local function CreateTorrentImpact(position, radius)
	local particle = ParticleManager:CreateParticle(TORRENT_SPLASH_PARTICLE, PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleControl(particle, 0, position)
	ParticleManager:SetParticleControl(particle, 1, Vector(radius or 220, 0, 0))
	ParticleManager:ReleaseParticleIndex(particle)
end

local function ApplyTorrentControl(caster, ability, enemy, position)
	if not IsValidAlive(enemy) then return end
	local stunDuration = ability:GetSpecialValueFor("torrent_stun_duration")
	if stunDuration <= 0 then stunDuration = 1.15 end
	local slowDuration = ability:GetSpecialValueFor("torrent_slow_duration")
	if slowDuration <= 0 then slowDuration = 2.2 end
	local height = ability:GetSpecialValueFor("torrent_height")
	if height <= 0 then height = 360 end
	local radius = ability:GetSpecialValueFor("width")
	local direction = enemy:GetAbsOrigin() - position
	if direction:Length2D() <= 0 then direction = RandomVector(1) end
	local border = direction:Normalized() * (radius + 100)

	enemy:RemoveModifierByName("modifier_knockback")
	enemy:AddNewModifier(caster, ability, "modifier_knockback", {
		should_stun = 1,
		knockback_duration = stunDuration,
		duration = stunDuration,
		knockback_distance = 0,
		knockback_height = height,
		center_x = (position + border).x,
		center_y = (position + border).y,
		center_z = position.z,
	})
	enemy:AddNewModifier(caster, ability, "modifier_stunned", { duration = stunDuration })
	enemy:AddNewModifier(caster, ability, "modifier_xhs_proudmoore_torrent_slow", { duration = slowDuration })
end

local function CreateGhostshipImpact(position)
	local particle = ParticleManager:CreateParticle(GHOSTSHIP_SPLASH_PARTICLE, PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleControl(particle, 3, position)
	ParticleManager:ReleaseParticleIndex(particle)
end

local function CreateAnchorSmash(caster, radius)
	local particle = ParticleManager:CreateParticle(ANCHOR_SMASH_PARTICLE, PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleControlEnt(particle, 0, caster, PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", caster:GetAbsOrigin(), true)
	ParticleManager:SetParticleControl(particle, 1, Vector(radius or 400, 0, 0))
	ParticleManager:ReleaseParticleIndex(particle)
end

local function CreateTidebringerImpact(position, radius)
	local particle = ParticleManager:CreateParticle(TIDEBRINGER_PARTICLE, PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleControl(particle, 0, position)
	ParticleManager:SetParticleControl(particle, 1, Vector(radius or 240, 0, 0))
	ParticleManager:ReleaseParticleIndex(particle)
end

local function EmitLocationSound(caster, position, soundName)
	if IsValidAlive(caster) and position ~= nil and soundName ~= nil then
		EmitSoundOnLocationWithCaster(position, soundName, caster)
	end
end

function xhs_proudmoore_admirals_command:OnAbilityPhaseStart()
	if not IsServer() then return true end

	local caster = self:GetCaster()
	local context = GetContext(self)
	StartBossCastBar(self, "Admiral's Command")
	XHSBossTelegraphs:Circle(caster:GetAbsOrigin(), self:GetSpecialValueFor("radius"), self:GetCastPoint(), PROUDMOORE_COLORS)
	for _, point in pairs(context.points or {}) do
		XHSBossTelegraphs:Target(point.position, self:GetSpecialValueFor("strike_radius"), self:GetCastPoint() + (point.delay or 0), PROUDMOORE_COLORS)
	end
	StartAnimation(caster, { duration = self:GetCastPoint() + 0.3, activity = ACT_DOTA_CAST_ABILITY_4, rate = 0.85 })
	caster:EmitSound("Hero_Kunkka.Ghostship.bell")
	return true
end

function xhs_proudmoore_admirals_command:OnAbilityPhaseInterrupted()
	if IsServer() then HideBossCastBar(self) end
end

function xhs_proudmoore_admirals_command:OnSpellStart()
	if not IsServer() then return end

	local caster = self:GetCaster()
	local context = GetContext(self)
	caster:AddNewModifier(caster, self, "modifier_xhs_proudmoore_command", { duration = self:GetSpecialValueFor("duration") })
	DamageEnemies(caster, self, caster:GetAbsOrigin(), self:GetSpecialValueFor("radius"), ScaleDamage(self:GetSpecialValueFor("damage")), DAMAGE_TYPE_MAGICAL)

	for _, point in pairs(context.points or {}) do
		Timers:CreateTimer(point.delay or 0, function()
			if not IsValidAlive(caster) then return nil end
			DamageEnemies(caster, self, point.position, self:GetSpecialValueFor("strike_radius"), ScaleDamage(self:GetSpecialValueFor("strike_damage")), DAMAGE_TYPE_MAGICAL)
			CreateGhostshipImpact(point.position)
			EmitLocationSound(caster, point.position, "Hero_Kunkka.Torrent")
			return nil
		end)
	end
	ClearContext(self)
end

function xhs_proudmoore_torrent_line:OnAbilityPhaseStart()
	if not IsServer() then return true end

	local context = GetContext(self)
	local caster = self:GetCaster()
	local direction = NormalizeDirection(context.direction or caster:GetForwardVector())
	local length = self:GetSpecialValueFor("length")
	local width = self:GetSpecialValueFor("width")
	local spacing = math.max(1, width * 1.25)

	StartBossCastBar(self, "Torrent Line")
	XHSBossTelegraphs:Line(caster:GetAbsOrigin(), direction, spacing, width, math.max(1, math.floor(length / spacing)), self:GetCastPoint(), PROUDMOORE_COLORS, 120)
	StartAnimation(caster, { duration = self:GetCastPoint() + 0.15, activity = ACT_DOTA_CAST_ABILITY_1, rate = 1.0 })
	caster:EmitSound("Ability.Torrent")
	return true
end

function xhs_proudmoore_torrent_line:OnAbilityPhaseInterrupted()
	if IsServer() then HideBossCastBar(self) end
end

function xhs_proudmoore_torrent_line:OnSpellStart()
	if not IsServer() then return end

	local caster = self:GetCaster()
	local context = GetContext(self)
	local direction = NormalizeDirection(context.direction or caster:GetForwardVector())
	local width = self:GetSpecialValueFor("width")
	local length = self:GetSpecialValueFor("length")
	local spacing = math.max(1, width * 1.25)
	local count = math.max(1, math.floor(length / spacing))
	local startDistance = 120
	local damage = ScaleDamage(self:GetSpecialValueFor("damage"))
	for i = 1, count do
		local position = caster:GetAbsOrigin() + direction * (startDistance + spacing * (i - 1))
		CreateTorrentImpact(position, width)
		EmitLocationSound(caster, position, "Ability.Torrent")
		DamageEnemies(caster, self, position, width, damage, DAMAGE_TYPE_PURE, function(enemy)
			ApplyTorrentControl(caster, self, enemy, position)
		end)
	end
	ClearContext(self)
end

function xhs_proudmoore_broadside:OnAbilityPhaseStart()
	if not IsServer() then return true end

	local points = GetContext(self).points or {}
	StartBossCastBar(self, "Broadside")
	for _, point in pairs(points) do
		XHSBossTelegraphs:Target(point.position, self:GetSpecialValueFor("radius"), self:GetCastPoint() + (point.delay or 0), PROUDMOORE_COLORS)
	end
	StartAnimation(self:GetCaster(), { duration = self:GetCastPoint() + 0.2, activity = ACT_DOTA_CAST_ABILITY_2, rate = 0.95 })
	self:GetCaster():EmitSound("Hero_Kunkka.Ghostship")
	return true
end

function xhs_proudmoore_broadside:OnAbilityPhaseInterrupted()
	if IsServer() then HideBossCastBar(self) end
end

function xhs_proudmoore_broadside:OnSpellStart()
	if not IsServer() then return end

	local caster = self:GetCaster()
	local damage = ScaleDamage(self:GetSpecialValueFor("damage"))
	for _, point in pairs(GetContext(self).points or {}) do
		Timers:CreateTimer(point.delay or 0, function()
			if not IsValidAlive(caster) then return nil end
			DamageEnemies(caster, self, point.position, self:GetSpecialValueFor("radius"), damage, DAMAGE_TYPE_MAGICAL)
			CreateGhostshipImpact(point.position)
			EmitLocationSound(caster, point.position, "Hero_Kunkka.Ghostship")
			return nil
		end)
	end
	ClearContext(self)
end

function xhs_proudmoore_anchor_smash:OnAbilityPhaseStart()
	if not IsServer() then return true end

	local caster = self:GetCaster()
	StartBossCastBar(self, "Anchor Smash")
	XHSBossTelegraphs:Circle(caster:GetAbsOrigin(), self:GetSpecialValueFor("radius"), self:GetCastPoint(), PROUDMOORE_COLORS)
	StartAnimation(caster, { duration = self:GetCastPoint() + 0.2, activity = ACT_DOTA_ATTACK, rate = 0.65 })
	caster:EmitSound("Hero_Tidehunter.AnchorSmash")
	return true
end

function xhs_proudmoore_anchor_smash:OnAbilityPhaseInterrupted()
	if IsServer() then HideBossCastBar(self) end
end

function xhs_proudmoore_anchor_smash:OnSpellStart()
	if not IsServer() then return end

	local caster = self:GetCaster()
	local radius = self:GetSpecialValueFor("radius")
	DamageEnemies(caster, self, caster:GetAbsOrigin(), radius, ScaleDamage(self:GetSpecialValueFor("damage")), DAMAGE_TYPE_PURE, function(enemy)
		enemy:AddNewModifier(caster, self, "modifier_xhs_proudmoore_anchor_slow", { duration = self:GetSpecialValueFor("slow_duration") })
	end)
	CreateAnchorSmash(caster, radius)
	caster:EmitSound("Hero_Tidehunter.AnchorSmash")
	ClearContext(self)
end

function xhs_proudmoore_focus_fire:OnAbilityPhaseStart()
	if not IsServer() then return true end

	local position = GetContext(self).position or self:GetCaster():GetAbsOrigin()
	StartBossCastBar(self, "Focus Fire")
	XHSBossTelegraphs:Target(position, self:GetSpecialValueFor("radius"), self:GetCastPoint(), PROUDMOORE_COLORS)
	StartAnimation(self:GetCaster(), { duration = self:GetCastPoint() + 0.15, activity = ACT_DOTA_CAST_ABILITY_3, rate = 1.0 })
	self:GetCaster():EmitSound("Hero_Kunkka.Tidebringer")
	return true
end

function xhs_proudmoore_focus_fire:OnAbilityPhaseInterrupted()
	if IsServer() then HideBossCastBar(self) end
end

function xhs_proudmoore_focus_fire:OnSpellStart()
	if not IsServer() then return end

	local caster = self:GetCaster()
	local position = GetContext(self).position or caster:GetAbsOrigin()
	local radius = self:GetSpecialValueFor("radius")
	DamageEnemies(caster, self, position, radius, ScaleDamage(self:GetSpecialValueFor("damage")), DAMAGE_TYPE_PURE)
	CreateTidebringerImpact(position, radius)
	EmitLocationSound(caster, position, "Hero_Kunkka.Tidebringer")
	ClearContext(self)
end

function xhs_proudmoore_command_aura:GetIntrinsicModifierName()
	return "modifier_xhs_proudmoore_command_aura"
end

function modifier_xhs_proudmoore_command:IsPurgable() return false end
function modifier_xhs_proudmoore_command:DeclareFunctions()
	return { MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS, MODIFIER_PROPERTY_BASEDAMAGEOUTGOING_PERCENTAGE }
end
function modifier_xhs_proudmoore_command:GetModifierPhysicalArmorBonus()
	return self:GetAbility() and self:GetAbility():GetSpecialValueFor("bonus_armor") or 0
end
function modifier_xhs_proudmoore_command:GetModifierBaseDamageOutgoing_Percentage()
	return self:GetAbility() and self:GetAbility():GetSpecialValueFor("bonus_damage_pct") or 0
end

function modifier_xhs_proudmoore_anchor_slow:IsPurgable() return true end
function modifier_xhs_proudmoore_anchor_slow:IsDebuff() return true end
function modifier_xhs_proudmoore_anchor_slow:DeclareFunctions()
	return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE, MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT }
end
function modifier_xhs_proudmoore_anchor_slow:GetModifierMoveSpeedBonus_Percentage()
	return -(self:GetAbility() and self:GetAbility():GetSpecialValueFor("slow_pct") or 35)
end
function modifier_xhs_proudmoore_anchor_slow:GetModifierAttackSpeedBonus_Constant()
	return -(self:GetAbility() and self:GetAbility():GetSpecialValueFor("attack_slow") or 60)
end

function modifier_xhs_proudmoore_torrent_slow:IsPurgable() return true end
function modifier_xhs_proudmoore_torrent_slow:IsDebuff() return true end
function modifier_xhs_proudmoore_torrent_slow:DeclareFunctions()
	return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE }
end
function modifier_xhs_proudmoore_torrent_slow:GetModifierMoveSpeedBonus_Percentage()
	return -(self:GetAbility() and self:GetAbility():GetSpecialValueFor("torrent_slow_pct") or 40)
end

function modifier_xhs_proudmoore_command_aura:IsHidden() return true end
function modifier_xhs_proudmoore_command_aura:IsPurgable() return false end
function modifier_xhs_proudmoore_command_aura:DeclareFunctions()
	return { MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS }
end
function modifier_xhs_proudmoore_command_aura:GetModifierPhysicalArmorBonus()
	return self:GetAbility() and self:GetAbility():GetSpecialValueFor("armor") or 0
end
