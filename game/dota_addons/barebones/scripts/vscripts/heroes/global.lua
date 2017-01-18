require("libraries/timers")

function Lifesteal( event )
local attacker = event.attacker
local target = event.target
local ability = event.ability

	if target.GetInvulnCount == nil and not target:IsBuilding() then
		ability:ApplyDataDrivenModifier(attacker, attacker, "modifier_lifesteal", {duration = 0.03})		
	end
end

function Reincarnation(event)
	local ability = event.ability
	local hero = event.caster
	local position = hero:GetAbsOrigin()
	local respawntime = ability:GetSpecialValueFor("reincarnation_time")

	if hero:IsRealHero() and not hero.ankh_respawn then
		hero:SetRespawnsDisabled(true)

		hero.respawn_timer = Timers:CreateTimer(respawntime,function () 
			hero:SetRespawnPosition(position)
			hero:EmitSound("Ability.ReincarnationAlt")
			hero:RespawnHero(false, false, false)
			ParticleManager:CreateParticle("particles/items_fx/aegis_respawn.vpcf", PATTACH_ABSORIGIN_FOLLOW, hero)
			hero.ankh_respawn = false
			hero:SetRespawnsDisabled(false)
			end)
		hero.ankh_respawn = true

		ability:StartCooldown(60.0)
	end
end

function CastleMuradin(event)
local caster = event.caster
local ability = event.ability
local Waypoint = Entities:FindByName(nil, "final_wave_player_1")
local InvTime = ability:GetSpecialValueFor("invulnerability_time")

	if ability:IsCooldownReady() then
		local Muradin = CreateUnitByName("npc_dota_creature_muradin_bronzebeard", Waypoint:GetAbsOrigin(), false, nil, nil, DOTA_TEAM_GOODGUYS)
		Muradin:SetInitialGoalEntity(Waypoint)
		Muradin:MoveToPositionAggressive(Waypoint:GetAbsOrigin())
		PauseCreepsCastle()
		ability:StartCooldown(600.0)
		caster:AddNewModifier(caster, nil, "modifier_invulnerable", {duration = InvTime + 10.0})
	end
end
