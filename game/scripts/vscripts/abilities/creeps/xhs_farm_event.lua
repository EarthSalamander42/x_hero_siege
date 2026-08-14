xhs_farm_howling_blast = xhs_farm_howling_blast or class({})

LinkLuaModifier(
	"modifier_xhs_farm_howling_blast",
	"abilities/creeps/xhs_farm_event.lua",
	LUA_MODIFIER_MOTION_NONE
)
LinkLuaModifier(
	"modifier_xhs_farm_howling_blast_fx",
	"abilities/creeps/xhs_farm_event.lua",
	LUA_MODIFIER_MOTION_NONE
)

local HOWLING_BLAST_PARTICLE =
	"particles/units/heroes/heroes_underlord/abyssal_underlord_pitofmalice_stun.vpcf"

function xhs_farm_howling_blast:GetIntrinsicModifierName()
	return "modifier_xhs_farm_howling_blast"
end

modifier_xhs_farm_howling_blast = modifier_xhs_farm_howling_blast or class({})
modifier_xhs_farm_howling_blast_fx = modifier_xhs_farm_howling_blast_fx or class({})

function modifier_xhs_farm_howling_blast:IsHidden() return true end
function modifier_xhs_farm_howling_blast:IsPurgable() return false end
function modifier_xhs_farm_howling_blast:IsPurgeException() return false end

function modifier_xhs_farm_howling_blast_fx:IsHidden() return true end
function modifier_xhs_farm_howling_blast_fx:IsPurgable() return false end
function modifier_xhs_farm_howling_blast_fx:IsPurgeException() return false end
function modifier_xhs_farm_howling_blast_fx:GetEffectName() return HOWLING_BLAST_PARTICLE end
function modifier_xhs_farm_howling_blast_fx:GetEffectAttachType() return PATTACH_ABSORIGIN_FOLLOW end

function modifier_xhs_farm_howling_blast:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_ATTACKED,
	}
end

function modifier_xhs_farm_howling_blast:OnAttacked(keys)
	if not IsServer() or keys.target ~= self:GetParent() then return end

	local parent = self:GetParent()
	local attacker = keys.attacker
	local ability = self:GetAbility()
	if attacker == nil or attacker:IsNull() or attacker:IsBuilding()
		or ability == nil or ability:IsNull() or not parent:IsAlive() then
		return
	end

	local now = GameRules:GetGameTime()
	if now < (self.next_proc_at or 0) then return end
	if not RollPercentage(ability:GetSpecialValueFor("ensnare_chance")) then return end

	local duration = ability:GetSpecialValueFor("ensnare_duration")
	local damage = ability:GetSpecialValueFor("ensnare_damage")
	self.next_proc_at = now + math.max(0.1, ability:GetSpecialValueFor("internal_cooldown"))

	attacker:AddNewModifier(parent, ability, "modifier_rooted", { duration = duration })
	attacker:AddNewModifier(parent, ability, "modifier_disarmed", { duration = duration })
	attacker:AddNewModifier(parent, ability, "modifier_xhs_farm_howling_blast_fx", { duration = duration })
	attacker:EmitSound("Hero_AbyssalUnderlord.Pit.TargetHero")

	ApplyDamage({
		victim = attacker,
		attacker = parent,
		damage = damage,
		ability = ability,
		damage_type = DAMAGE_TYPE_MAGICAL,
	})
end
