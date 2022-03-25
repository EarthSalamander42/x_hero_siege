campfire = campfire or class({})

LinkLuaModifier( "modifier_campfire", "abilities/heroes/creeps", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_campfire_effect", "abilities/heroes/creeps", LUA_MODIFIER_MOTION_NONE )

function campfire:GetIntrinsicModifierName()
	return "modifier_campfire"
end


modifier_campfire = modifier_campfire or class({})

function modifier_campfire:IsHidden()
	return true
end

function modifier_campfire:IsPurgable()
	return false
end

function modifier_campfire:IsAura()
	return true
end

function modifier_campfire:GetModifierAura()
	return  "modifier_campfire_effect"
end

function modifier_campfire:GetAuraSearchTeam()
	return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_campfire:GetAuraSearchType()
	return DOTA_UNIT_TARGET_ALL
end

function modifier_campfire:GetAuraRadius()
	return self.aura_radius
end

function modifier_campfire:OnCreated( kv )
	if IsServer() then
		self.aura_radius = self:GetAbility():GetSpecialValueFor( "aura_radius" )

--		self:GetParent():AddNewModifier( nil, nil, "modifier_disable_aggro", { duration = -1 } )
		self:GetParent():AddNewModifier( nil, nil, "modifier_provides_fow_position", { duration = -1 } )

		EmitSoundOn( "Campfire.Warmth.Loop", self:GetParent() )

		self:StartIntervalThink( 0.25 )
	end
end

function modifier_campfire:CheckState()
	local state = {}
	if IsServer()  then
		state[MODIFIER_STATE_ROOTED] = true
		state[MODIFIER_STATE_NO_HEALTH_BAR] = true
		state[MODIFIER_STATE_NOT_ON_MINIMAP] = true
		state[MODIFIER_STATE_BLIND] = true
		state[MODIFIER_STATE_INVULNERABLE] = true
		state[MODIFIER_STATE_OUT_OF_GAME] = true
	end

	return state
end

function modifier_campfire:OnIntervalThink()
	if IsServer() then
		if ( not self.nFXIndex ) then
			local vCasterPos = self:GetCaster():GetOrigin()
			local vOffset = Vector( 0, 0, 50 )

			self.nFXIndex = ParticleManager:CreateParticle( "particles/act_2/campfire_flame.vpcf", PATTACH_ABSORIGIN, self:GetCaster() )
			ParticleManager:SetParticleControl( self.nFXIndex, 2, vCasterPos + vOffset )
		end
	end
end

function modifier_campfire:OnDestroy()
	if IsServer() then
		StopSoundOn( "Campfire.Warmth.Loop", self:GetParent() )
	end
end

modifier_campfire_effect = class({})

function modifier_campfire_effect:GetEffectName()
	return "particles/camp_fire_buff.vpcf"
end

function modifier_campfire_effect:OnCreated( kv )

end

function modifier_campfire_effect:DeclareFunctions()
	local funcs = 
	{
		MODIFIER_PROPERTY_HEALTH_REGEN_PERCENTAGE,
		MODIFIER_PROPERTY_MANA_REGEN_TOTAL_PERCENTAGE
	}
	return funcs
end

function modifier_campfire_effect:GetModifierHealthRegenPercentage( params )
	return self:GetAbility():GetSpecialValueFor( "aura_hp_regen" )
end

function modifier_campfire_effect:GetModifierTotalPercentageManaRegen( params )
	return self:GetAbility():GetSpecialValueFor( "aura_mana_regen" )
end

undead_disease_cloud = class({})

LinkLuaModifier("modifier_disease_cloud_aura", "abilities/heroes/creeps.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_disease_cloud_debuff", "abilities/heroes/creeps.lua", LUA_MODIFIER_MOTION_NONE)

function undead_disease_cloud:GetIntrinsicModifierName()
	return "modifier_disease_cloud_aura"
end

--------------------------------------------------------------------------------

modifier_disease_cloud_aura = class({})

function modifier_disease_cloud_aura:OnCreated()
	if IsServer() then
		local particle = ParticleManager:CreateParticle("particles/custom/undead/disease_cloud.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
		ParticleManager:SetParticleControl(particle, 1, Vector(200,0,0))
		self:AddParticle(particle, false, false, 1, false, false)
	end
end

function modifier_disease_cloud_aura:OnDestroy()
	if IsServer() then
		local unit = self:GetParent()
		if unit:GetUnitName() == "undead_abomination" then
			local disease_cloud_dummy = CreateUnitByName("dummy_unit_disease_cloud", unit:GetAbsOrigin(), false, nil, nil, unit:GetTeamNumber())
			local explosion = ParticleManager:CreateParticle("particles/custom/undead/rot_recipient.vpcf",PATTACH_ABSORIGIN_FOLLOW,disease_cloud_dummy)
			Timers:CreateTimer(1, function() ParticleManager:DestroyParticle(explosion,true) end)
			Timers:CreateTimer(10, function()
				UTIL_Remove(disease_cloud_dummy)
			end)
		end
	end
end

function modifier_disease_cloud_aura:IsAura()
	return true
end

function modifier_disease_cloud_aura:IsHidden()
	return true
end

function modifier_disease_cloud_aura:IsPurgable()
	return false
end

function modifier_disease_cloud_aura:GetAuraRadius()
	return self:GetAbility():GetSpecialValueFor("radius")
end

function modifier_disease_cloud_aura:GetModifierAura()
	return "modifier_disease_cloud_debuff"
end
   
function modifier_disease_cloud_aura:GetAuraSearchTeam()
	return DOTA_UNIT_TARGET_TEAM_ENEMY
end

--  function modifier_disease_cloud_aura:GetAuraEntityReject(target)
--		return IsBuilding()
--	end

function modifier_disease_cloud_aura:GetAuraSearchType()
	return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
end

function modifier_disease_cloud_aura:GetAuraDuration()
	return 120
end

--------------------------------------------------------------------------------

modifier_disease_cloud_debuff = class({})

function modifier_disease_cloud_debuff:IsPurgable()
	return false
end

function modifier_disease_cloud_debuff:IsDebuff()
	return true
end

function modifier_disease_cloud_debuff:OnCreated()
	if IsServer() then
		self:StartIntervalThink(1)
	end
end

function modifier_disease_cloud_debuff:GetEffectName()
	return "particles/custom/undead/disease_debuff.vpcf"
end

function modifier_disease_cloud_debuff:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_disease_cloud_debuff:OnIntervalThink()
	ApplyDamage({victim = self:GetParent(), attacker = self:GetCaster(), damage = 1, damage_type = DAMAGE_TYPE_MAGICAL})
end

--------------------------------------------------------------------------------

LinkLuaModifier("modifier_endurance_aura", "modifiers/auras/modifier_endurance_aura.lua", LUA_MODIFIER_MOTION_NONE)

holdout_endurance_aura = holdout_endurance_aura or class({})

function holdout_endurance_aura:GetIntrinsicModifierName() return "modifier_endurance_aura" end

xhs_creeps_phase_2_endurance_aura = xhs_creeps_phase_2_endurance_aura or class({})

function xhs_creeps_phase_2_endurance_aura:GetIntrinsicModifierName() return "modifier_endurance_aura" end

--------------------------------------------------------------------------------

LinkLuaModifier("modifier_command_aura", "modifiers/auras/modifier_command_aura.lua", LUA_MODIFIER_MOTION_NONE)

holdout_command_aura = holdout_command_aura or class({})

function holdout_command_aura:GetIntrinsicModifierName() return "modifier_command_aura" end

holdout_command_aura_innate = holdout_command_aura_innate or class({})

function holdout_command_aura_innate:GetIntrinsicModifierName() return "modifier_command_aura" end

command_aura = command_aura or class({})

function command_aura:GetIntrinsicModifierName() return "modifier_command_aura" end

--------------------------------------------------------------------------------

LinkLuaModifier("modifier_unholy_aura", "modifiers/auras/modifier_unholy_aura.lua", LUA_MODIFIER_MOTION_NONE)

xhs_creeps_phase_2_unholy_aura = xhs_creeps_phase_2_unholy_aura or class({})

function xhs_creeps_phase_2_unholy_aura:GetIntrinsicModifierName() return "modifier_unholy_aura" end
