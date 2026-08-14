LinkLuaModifier(
	"modifier_xhs_special_wave_bash",
	"abilities/creeps/xhs_special_wave_bash.lua",
	LUA_MODIFIER_MOTION_NONE
)

xhs_special_wave_bash = class({})

function xhs_special_wave_bash:GetIntrinsicModifierName()
	return "modifier_xhs_special_wave_bash"
end

modifier_xhs_special_wave_bash = class({})

function modifier_xhs_special_wave_bash:IsHidden()
	return true
end

function modifier_xhs_special_wave_bash:IsPurgable()
	return false
end

function modifier_xhs_special_wave_bash:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_ATTACK_LANDED,
	}
end

function modifier_xhs_special_wave_bash:OnCreated()
	self.valid_attack_count = 0
end

function modifier_xhs_special_wave_bash:OnAttackLanded(params)
	if not IsServer() or params.attacker ~= self:GetParent() then
		return
	end

	local target = params.target
	local ability = self:GetAbility()
	if target == nil or target:IsNull() or ability == nil or ability:IsNull() then
		return
	end

	if target:GetTeamNumber() == params.attacker:GetTeamNumber()
		or target:IsBuilding()
		or target:IsOther() then
		return
	end

	-- Do not bank a ready bash while another stun is active. With several
	-- special-wave creeps this reset prevents a new stun on the first free frame.
	if target:IsStunned() then
		self.valid_attack_count = 0
		return
	end

	self.valid_attack_count = self.valid_attack_count + 1
	local attacks_required = math.max(1, ability:GetSpecialValueFor("attack_count"))
	if self.valid_attack_count < attacks_required then
		return
	end

	self.valid_attack_count = 0

	local stun_duration = ability:GetSpecialValueFor("duration")
	target:AddNewModifier(params.attacker, ability, "modifier_stunned", {
		duration = stun_duration,
	})

	target:EmitSound("Hero_Slardar.Bash")

	ApplyDamage({
		victim = target,
		attacker = params.attacker,
		ability = ability,
		damage = ability:GetSpecialValueFor("bonus_damage"),
		damage_type = DAMAGE_TYPE_PHYSICAL,
	})
end
