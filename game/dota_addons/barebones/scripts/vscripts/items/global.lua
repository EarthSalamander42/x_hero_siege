require('libraries/timers')
require('phases/phase2')

-- Orb of Earth
function Bash(event)
	local caster = event.caster
	if caster:IsIllusion() then return end
	local target = event.target
	local ability = event.ability
	if hero:IsIllusion() then return end

	if ability:IsCooldownReady() then
		ability:StartCooldown(10.0)
	end
end

function Magtheridon(keys)
	local unit = keys.caster
	local ability = keys.ability
	local boss_count = unit.boss_count

	if unit:GetHealth() == 0 then
		point = unit:GetAbsOrigin()
		itemCharges = ability:GetCurrentCharges()
		local respawntime = ability:GetSpecialValueFor("reincarnation_time")

		Timers:CreateTimer(respawntime, function()
			respawnMagtheridon(boss_count)
		end)

		for i = 1, 8 do
			CreateUnitByName("npc_dota_hero_magtheridon_medium", point, true, nil, nil, DOTA_TEAM_CUSTOM_2)
		end
	end
end

function respawnMagtheridon(iBossCount)
	local magtheridon = CreateUnitByName("npc_dota_hero_magtheridon", point, true, nil, nil, DOTA_TEAM_CUSTOM_2)
	magtheridon.boss_count = iBossCount
	local ankh = CreateItem("item_magtheridon_ankh", mag, mag)

	if itemCharges -1 ~= 0 then
		magtheridon:AddItem(ankh)
	end

	ankh:SetCurrentCharges(itemCharges -1)
	magtheridon:EmitSound("Ability.Reincarnation")
--	BossBar(magtheridon, "mag")
	magtheridon.zone = "xhs_holdout"
end

function respawnMagtheridonMedium(keys)
local caster = keys.caster

	for i = 1, 2 do
		CreateUnitByName("npc_dota_hero_magtheridon_small", caster:GetAbsOrigin(), true, nil, nil, DOTA_TEAM_CUSTOM_2)
	end
end
