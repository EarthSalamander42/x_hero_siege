function Rejuvenation( keys )
local caster = keys.caster
local target = keys.target
local ability = keys.ability
local ability_level = ability:GetLevel() - 1
local sound_target = keys.sound_target
local modifier_buff = keys.modifier_buff
local duration = ability:GetLevelSpecialValueFor("duration", ability_level)
	
-- If the target is an ally, use "good" sound/modifier
if caster:GetTeam() == target:GetTeam() then
	-- Apply modifier
	ability:ApplyDataDrivenModifier(caster, target, modifier_buff, {})
end

	-- Start or reset looping debuff sound
	Timers:CreateTimer(duration, function()
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
local tick_heal = ability:GetLevelSpecialValueFor("tick_heal", ability_level)
local tick_heal_pct = ability:GetLevelSpecialValueFor("tick_heal_pct", ability_level)
local total_heal = tick_heal + target:GetMaxHealth() * tick_heal_pct / 100
total_heal = math.floor(total_heal + 0.5)

-- Apply healing
target:Heal(total_heal, caster)
SendOverheadEventMessage(nil, OVERHEAD_ALERT_HEAL, target, total_heal, nil)
end
