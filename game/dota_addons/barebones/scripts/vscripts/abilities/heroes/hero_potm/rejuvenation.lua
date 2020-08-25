function Rejuvenation( keys )
local caster = keys.caster
local target = keys.target
local ability = keys.ability
local ability_level = ability:GetLevel() - 1
local sound_target = keys.sound_target
local modifier_buff = keys.modifier_buff
	
-- If the target is an ally, use "good" sound/modifier
if caster:GetTeam() == target:GetTeam() then
	-- Apply modifier
	ability:ApplyDataDrivenModifier(caster, target, modifier_buff, {})
end

	-- Start or reset looping debuff sound
	Timers:CreateTimer(12.0, function()
		target:StopSound(sound_target)
	end)

target:StopSound(sound_target)
target:EmitSound(sound_target)
end

function RejuvenationHealing( keys )
local caster = keys.caster
local target = keys.target
local ability = keys.ability

-- Parameters
local ability_level = ability:GetLevel() - 1
local tick_damage = ability:GetLevelSpecialValueFor("tick_heal", ability_level)

-- Apply healing
target:Heal(tick_damage, caster)
SendOverheadEventMessage(nil, OVERHEAD_ALERT_HEAL, target, tick_damage, nil)
end
