LinkLuaModifier("modifier_holdout_craggy_exterior", "abilities/heroes/hero_mountain_giant.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_xhs_stone_giant_earth_splitter_slow", "abilities/heroes/hero_mountain_giant.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_xhs_stone_giant_stone_gaze", "abilities/heroes/hero_mountain_giant.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_xhs_stone_giant_stone_gaze_debuff", "abilities/heroes/hero_mountain_giant.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_xhs_stone_giant_petrified", "abilities/heroes/hero_mountain_giant.lua", LUA_MODIFIER_MOTION_NONE)

holdout_craggy_exterior = holdout_craggy_exterior or class({})

function holdout_craggy_exterior:GetIntrinsicModifierName()
	return "modifier_holdout_craggy_exterior"
end

function holdout_craggy_exterior:GetAbilityTextureName()
	return "tiny_craggy_exterior"
end

modifier_holdout_craggy_exterior = modifier_holdout_craggy_exterior or class({})

function modifier_holdout_craggy_exterior:IsHidden() return true end
function modifier_holdout_craggy_exterior:IsPurgable() return false end
function modifier_holdout_craggy_exterior:RemoveOnDeath() return false end

function modifier_holdout_craggy_exterior:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
		MODIFIER_EVENT_ON_ATTACK_LANDED,
	}
end

function modifier_holdout_craggy_exterior:GetModifierPhysicalArmorBonus()
	local ability = self:GetAbility()
	if ability == nil then return 0 end

	return ability:GetSpecialValueFor("bonus_armor")
end

function modifier_holdout_craggy_exterior:OnAttackLanded(keys)
	if not IsServer() then return end

	local parent = self:GetParent()
	local ability = self:GetAbility()
	if ability == nil or keys.target ~= parent or parent:PassivesDisabled() then return end

	local attacker = keys.attacker
	if attacker == nil or attacker:IsNull() or attacker:GetTeamNumber() == parent:GetTeamNumber() then return end
	if attacker:IsBuilding() or attacker:IsOther() then return end
	if not RollPercentage(ability:GetSpecialValueFor("stun_chance")) then return end

	ApplyDamage({
		victim = attacker,
		attacker = parent,
		damage = ability:GetSpecialValueFor("damage"),
		damage_type = DAMAGE_TYPE_MAGICAL,
		ability = ability,
	})

	attacker:AddNewModifier(parent, ability, "modifier_stunned", { duration = ability:GetSpecialValueFor("stun_duration") })
end

xhs_stone_giant_earth_splitter = xhs_stone_giant_earth_splitter or class({})

function xhs_stone_giant_earth_splitter:OnSpellStart()
	if not IsServer() then return end

	local caster = self:GetCaster()
	local origin = caster:GetAbsOrigin()
	local target = self:GetCursorPosition()
	local direction = target - origin
	direction.z = 0

	if direction:Length2D() < 1 then
		direction = caster:GetForwardVector()
	else
		direction = direction:Normalized()
	end

	local distance = self:GetSpecialValueFor("crack_distance")
	local end_pos = origin + direction * distance
	local delay = self:GetSpecialValueFor("crack_time")

	caster:EmitSound("Hero_ElderTitan.EarthSplitter.Cast")

	local pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_elder_titan/elder_titan_earth_splitter.vpcf", PATTACH_WORLDORIGIN, caster)
	ParticleManager:SetParticleControl(pfx, 0, origin)
	ParticleManager:SetParticleControl(pfx, 1, end_pos)
	ParticleManager:SetParticleControl(pfx, 3, Vector(delay, 0, 0))
	ParticleManager:ReleaseParticleIndex(pfx)

	AddFOWViewer(caster:GetTeamNumber(), origin, self:GetSpecialValueFor("vision_width"), delay, false)
	AddFOWViewer(caster:GetTeamNumber(), end_pos, self:GetSpecialValueFor("vision_width"), delay, false)

	Timers:CreateTimer(delay, function()
		if self:IsNull() or caster:IsNull() then return end

		EmitSoundOnLocationWithCaster(end_pos, "Hero_ElderTitan.EarthSplitter.Destroy", caster)

		local enemies = FindUnitsInLine(
			caster:GetTeamNumber(),
			origin,
			end_pos,
			nil,
			self:GetSpecialValueFor("crack_width"),
			DOTA_UNIT_TARGET_TEAM_ENEMY,
			DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
			DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES
		)

		for _, enemy in pairs(enemies) do
			local damage = enemy:GetMaxHealth() * self:GetSpecialValueFor("damage_pct") / 100
			ApplyDamage({
				victim = enemy,
				attacker = caster,
				damage = damage,
				damage_type = self:GetAbilityDamageType(),
				ability = self
			})

			enemy:AddNewModifier(caster, self, "modifier_xhs_stone_giant_earth_splitter_slow", {
				duration = self:GetSpecialValueFor("slow_duration")
			})
		end
	end)
end

modifier_xhs_stone_giant_earth_splitter_slow = modifier_xhs_stone_giant_earth_splitter_slow or class({})

function modifier_xhs_stone_giant_earth_splitter_slow:IsDebuff() return true end
function modifier_xhs_stone_giant_earth_splitter_slow:IsPurgable() return true end

function modifier_xhs_stone_giant_earth_splitter_slow:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
	}
end

function modifier_xhs_stone_giant_earth_splitter_slow:GetModifierMoveSpeedBonus_Percentage()
	return -self:GetAbility():GetSpecialValueFor("slow_pct")
end

xhs_stone_giant_stone_gaze = xhs_stone_giant_stone_gaze or class({})

function xhs_stone_giant_stone_gaze:OnSpellStart()
	if not IsServer() then return end

	local caster = self:GetCaster()
	caster:AddNewModifier(caster, self, "modifier_xhs_stone_giant_stone_gaze", { duration = self:GetSpecialValueFor("duration") })
	caster:EmitSound("Hero_Medusa.StoneGaze.Cast")
end

modifier_xhs_stone_giant_stone_gaze = modifier_xhs_stone_giant_stone_gaze or class({})

function modifier_xhs_stone_giant_stone_gaze:IsHidden() return false end
function modifier_xhs_stone_giant_stone_gaze:IsPurgable() return false end
function modifier_xhs_stone_giant_stone_gaze:IsAura() return true end
function modifier_xhs_stone_giant_stone_gaze:GetModifierAura() return "modifier_xhs_stone_giant_stone_gaze_debuff" end
function modifier_xhs_stone_giant_stone_gaze:GetAuraRadius() return self:GetAbility():GetSpecialValueFor("radius") end
function modifier_xhs_stone_giant_stone_gaze:GetAuraSearchTeam() return DOTA_UNIT_TARGET_TEAM_ENEMY end
function modifier_xhs_stone_giant_stone_gaze:GetAuraSearchType() return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC end
function modifier_xhs_stone_giant_stone_gaze:GetAuraSearchFlags() return DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES end

modifier_xhs_stone_giant_stone_gaze_debuff = modifier_xhs_stone_giant_stone_gaze_debuff or class({})

function modifier_xhs_stone_giant_stone_gaze_debuff:IsDebuff() return true end
function modifier_xhs_stone_giant_stone_gaze_debuff:IsPurgable() return true end

function modifier_xhs_stone_giant_stone_gaze_debuff:OnCreated()
	if not IsServer() then return end

	self.facing_time = 0
	self:StartIntervalThink(0.1)
end

function modifier_xhs_stone_giant_stone_gaze_debuff:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
	}
end

function modifier_xhs_stone_giant_stone_gaze_debuff:GetModifierMoveSpeedBonus_Percentage()
	return -self:GetAbility():GetSpecialValueFor("slow")
end

function modifier_xhs_stone_giant_stone_gaze_debuff:OnIntervalThink()
	local parent = self:GetParent()
	local caster = self:GetCaster()
	local ability = self:GetAbility()
	if not ability or caster:IsNull() or parent:IsNull() then return end
	if parent:HasModifier("modifier_xhs_stone_giant_petrified") then return end

	local direction = caster:GetAbsOrigin() - parent:GetAbsOrigin()
	direction.z = 0
	if direction:Length2D() < 1 then return end

	local forward = parent:GetForwardVector()
	local facing = direction:Normalized()
	local facing_dot = forward.x * facing.x + forward.y * facing.y
	if facing_dot >= math.cos(ability:GetSpecialValueFor("vision_cone")) then
		self.facing_time = self.facing_time + 0.1
	else
		self.facing_time = 0
	end

	if self.facing_time >= ability:GetSpecialValueFor("face_duration") then
		parent:AddNewModifier(caster, ability, "modifier_xhs_stone_giant_petrified", {
			duration = ability:GetSpecialValueFor("stone_duration")
		})
		parent:EmitSound("Hero_Medusa.StoneGaze.Stun")
		self:Destroy()
	end
end

modifier_xhs_stone_giant_petrified = modifier_xhs_stone_giant_petrified or class({})

function modifier_xhs_stone_giant_petrified:IsDebuff() return true end
function modifier_xhs_stone_giant_petrified:IsPurgable() return true end

function modifier_xhs_stone_giant_petrified:CheckState()
	return {
		[MODIFIER_STATE_STUNNED] = true,
	}
end

function modifier_xhs_stone_giant_petrified:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_INCOMING_PHYSICAL_DAMAGE_PERCENTAGE,
	}
end

function modifier_xhs_stone_giant_petrified:GetModifierIncomingPhysicalDamage_Percentage()
	return self:GetAbility():GetSpecialValueFor("bonus_physical_damage")
end

local STONE_GIANT_BASE_MODEL = "models/heroes/tiny_01/tiny_01.vmdl"
local STONE_GIANT_GIANT_MODEL = "models/heroes/tiny_04/tiny_04.vmdl"

local function StoneGiantRemoveLegacyParts(caster)
	for _, field in pairs({ "head", "rarm", "larm", "body" }) do
		local part = caster[field]
		if part ~= nil and not part:IsNull() then
			UTIL_Remove(part)
		end
		caster[field] = nil
	end
end

local function StoneGiantSetModel(caster, model, scale)
	StoneGiantRemoveLegacyParts(caster)
	caster:SetOriginalModel(model)
	caster:SetModel(model)
	caster:SetModelScale(scale)

	local particle = caster.grow_effect or "particles/units/heroes/hero_tiny/tiny_transform.vpcf"
	local pfx = ParticleManager:CreateParticle(particle, PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:ReleaseParticleIndex(pfx)
end

function DwarfToss( keys )
local caster = keys.caster
local ability = keys.ability
local target_pos = keys.target_points[1]
local ability_level = ability:GetLevel() - 1
local root_modifier = keys.root_modifier
local buff_modifier = keys.buff_modifier
local sound_cast = keys.sound_cast
local caster_pos = caster:GetAbsOrigin()
local min_speed = ability:GetLevelSpecialValueFor("min_speed", ability_level)
local base_distance = ability:GetLevelSpecialValueFor("base_distance", ability_level)
local max_time = ability:GetLevelSpecialValueFor("max_time", ability_level)
local buff_radius = ability:GetLevelSpecialValueFor("buff_radius", ability_level)
local cooldown_increase = ability:GetLevelSpecialValueFor("cooldown_increase", ability_level)
local base_height = ability:GetLevelSpecialValueFor("base_height", ability_level)
local height_step = ability:GetLevelSpecialValueFor("height_step", ability_level)
local max_height = ability:GetLevelSpecialValueFor("max_height", ability_level)
local is_night = false

	-- Clears any current command
	caster:Stop()

	-- Disjoint projectiles
	ProjectileManager:ProjectileDodge(caster)

	-- Calculate leap geometry
	local direction = (target_pos - caster_pos):Normalized()
	local distance = (target_pos - caster_pos):Length2D()
	local height = base_height

	-- Cap distance during the day
	if not is_night then
		distance = math.min(distance, base_distance)
		target_pos = caster_pos + direction * distance

	-- Adjust height during long nighttime jumps
	else
		height = math.min( (distance - base_distance) / base_distance * height_step + base_height, max_height)
	end

	-- Calculate leap speed and duration
	local leap_speed = max_time
	local leap_time = leap_speed

	caster:SetForwardVector(direction)
	if StartAnimation ~= nil then
		StartAnimation(caster, { duration = leap_time, activity = ACT_DOTA_CAST_ABILITY_2, rate = 1.0 })
	else
		caster:StartGesture(ACT_DOTA_CAST_ABILITY_2)
	end
	EmitSoundOn("Hero_Tiny.Toss.Throw", caster)

	-- Keep the legacy jump marker without applying ROOTED, which shows a status over the hero.
	ability:ApplyDataDrivenModifier(caster, caster, root_modifier, {})

	-- Perform movement loop
	local current_time = 0
	Timers:CreateTimer(0.03, function()

		-- Update time
		current_time = current_time + 0.03

		-- Calculate height
		local current_height
		if current_time <= (leap_time / 2) then
			current_height = height * current_time / leap_time * 2
		else
			current_height = height * (1 - current_time / leap_time) * 2
		end

		-- Calculate position
		local current_position = caster_pos + direction * distance * current_time / leap_time

		-- Update position
		caster:SetAbsOrigin(Vector(current_position.x, current_position.y, GetGroundHeight(current_position, caster) + current_height))
		
		-- If the jump time hasn't elapsed yet, keep going
		if current_time < leap_time then
			return 0.03

		-- Else, finalize the jump
		else

			-- Unroot the caster
			caster:RemoveModifierByName(root_modifier)

			-- Prevent the caster from getting stuck
			FindClearSpaceForUnit(caster, target_pos, true)
			if EndAnimation ~= nil then
				EndAnimation(caster)
			end
			caster:StartGesture(ACT_DOTA_ATTACK)
			EmitSoundOn("Hero_Tiny.Toss.Impact", caster)

			-- Buff nearby allies
			local nearby_allies = FindUnitsInRadius(caster:GetTeamNumber(), target_pos, nil, buff_radius, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
			for _,ally in pairs(nearby_allies) do
				ability:ApplyDataDrivenModifier(caster, ally, buff_modifier, {})
			end
		end
	end)
end

function SecondWindDamage( keys )
local caster = keys.caster
local attacker = keys.attacker
local ability = keys.ability
local ability_level = ability:GetLevel() - 1
local modifier_regen = keys.modifier_regen
local cooldown = ability:GetLevelSpecialValueFor("regen_cooldown", ability_level)

	caster:RemoveModifierByName(modifier_regen)
	ability:StartCooldown(cooldown)
end

function SecondWindRegen( keys )
local caster = keys.caster
local ability = keys.ability
local modifier_regen = keys.modifier_regen

	if ability:IsCooldownReady() then
		ability:ApplyDataDrivenModifier(caster, caster, modifier_regen, {})
	else
		caster:RemoveModifierByName(modifier_regen)
	end
end

function ToggleOff( keys )
local caster = keys.caster
local ability = keys.ability
local BAT_alt = caster:GetBaseAttackTime(false)
local BAT_Dec = ability:GetLevelSpecialValueFor("bat_reduction", ability:GetLevel() -1)

	caster:SetBaseAttackTime( BAT_alt - BAT_Dec )
	ability:StartCooldown(10.0)

	StoneGiantSetModel(caster, caster.xhs_stone_giant_base_model or STONE_GIANT_BASE_MODEL, 1.1)
	EmitSoundOn("Hero_Tiny.Grow", caster)
end

function ToggleOn( keys )
	local caster = keys.caster
	local ability = keys.ability
	local BAT_alt = caster:GetBaseAttackTime(false)
	local BAT_Dec = ability:GetLevelSpecialValueFor("bat_reduction", ability:GetLevel() -1)

	caster.xhs_stone_giant_base_model = caster.xhs_stone_giant_base_model or caster:GetModelName()
	caster:SetBaseAttackTime( BAT_alt + BAT_Dec )
	StoneGiantSetModel(caster, STONE_GIANT_GIANT_MODEL, 1.25)
	EmitSoundOn("Hero_Tiny.Grow", caster)
end

function Taunt( event )
local caster = event.caster

	caster:StartGesture(ACT_TINY_GROWL)
end

function GrowDummy( event )
	local caster = event.caster
	local ability = event.ability

	Timers:CreateTimer(function() 
		local model = caster:FirstMoveChild()
		while model ~= nil do
			if model:GetClassname() == "dota_item_wearable" then
				if not string.match(model:GetModelName(), "tree") then
					local new_model_name = string.gsub(model:GetModelName(),"1","2")
					model:SetModel(new_model_name)
				else
					model:SetParent(caster, "attach_attack1")
					model:AddEffects(EF_NODRAW)
				end
			end
			model = model:NextMovePeer()
			caster:AddNewModifier(caster, nil, "modifier_phased", {duration = 0.05})
		end
	end)
end
