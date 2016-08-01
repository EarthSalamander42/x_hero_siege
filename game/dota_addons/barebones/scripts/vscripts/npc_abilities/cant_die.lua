require('phases/phase3')

EXPLOSION_SOUND_TABLE = {"Hero_Techies.RemoteMine.Detonate", "Hero_Rattletrap.Rocket_Flare.Explode"}
EXPLOSION_PARTICLE_TABLE = {"particles/econ/items/shadow_fiend/sf_fire_arcana/sf_fire_arcana_shadowraze.vpcf"}

function death_check(event)
	local caster = event.caster
	local ability = event.ability
	if not caster.deathStart then
		if caster:GetHealth() < 50 then
			ability:ApplyDataDrivenModifier(caster, caster, "modifier_dying_generic", {duration = 20})
			CustomGameEventManager:Send_ServerToAllClients("hide_boss_health", {})
			caster.deathStart = true
			if caster:GetUnitName() == "npc_dota_hero_illidan" then
				mines_boss_die(caster)
			elseif caster:GetUnitName() == "npc_dota_hero_balanar" then
				mines_boss_die(caster)
			elseif caster:GetUnitName() == "npc_dota_hero_proudmoore" then
				mines_boss_die(caster)
			elseif caster:GetUnitName() == "npc_dota_hero_grom_hellscream" then
				mines_boss_die(caster)
			elseif caster:GetUnitName() == "npc_dota_hero_arthas" then
				mines_boss_die(caster)
			elseif caster:GetUnitName() == "npc_dota_hero_banehallow" then
				graveyard_boss_die(caster)
			elseif caster:GetUnitName() == "npc_dota_creature_abaddon" then
				mines_boss_die(caster)
			end
		end
	end
end

function BossTakeDamage(event)
	local caster = event.caster
	local ability = event.ability
	local damage = event.attack_damage
	CustomGameEventManager:Send_ServerToAllClients("update_boss_health", {current_health = caster:GetHealth()})
end

function death_animation(keys)
	caster = keys.caster
    local particleName = EXPLOSION_PARTICLE_TABLE[RandomInt(1, 1)]
    local particleVector = caster:GetAbsOrigin()
    pfx = ParticleManager:CreateParticle( particleName, PATTACH_ABSORIGIN_FOLLOW, caster )
    ParticleManager:SetParticleControlEnt( pfx, 0, caster, PATTACH_POINT_FOLLOW, "attach_hitloc", particleVector, true )
    local sound = EXPLOSION_SOUND_TABLE[RandomInt(1, 2)]
    EmitSoundOn(sound, caster)
end

function graveyard_boss_die(caster)
	caster:RemoveModifierByName("modifier_graveyard_boss_blast")
	local casterOrigin = caster:GetAbsOrigin()
	EmitSoundOn("skeleton_king_wraith_death_long_01", caster)
	EmitSoundOn("skeleton_king_wraith_death_long_01", caster)
	EmitSoundOn("skeleton_king_wraith_death_long_01", caster)
	StartAnimation(caster, {duration=4.9, activity=ACT_DOTA_FLAIL, rate=0.75})

	Timers:CreateTimer(1.5, function()
		EmitGlobalSound("Loot_Drop_Stinger_Arcana")
	end)
	Timers:CreateTimer(8, function()
		StartAnimation(caster, {duration=5.5, activity=ACT_DOTA_DIE, rate=0.20})
		EmitSoundOn("skeleton_king_wraith_death_long_09", caster)
		EmitSoundOn("skeleton_king_wraith_death_long_09", caster)
	end)
	Timers:CreateTimer(14, function()
		UTIL_Remove(caster)
	end)

	Timers:CreateTimer(19, function()
	local point = Entities:FindByName(nil,"point_teleport_boss"):GetAbsOrigin()
	local heroes = HeroList:GetAllHeroes()
		Timers:CreateTimer(5, StartAbaddonArena)
		for _,hero in pairs(heroes) do
			if hero:GetTeam() == DOTA_TEAM_GOODGUYS then
				FindClearSpaceForUnit(hero, point, true)
				hero:AddNewModifier(nil, nil, "modifier_stunned",nil)
				hero:AddNewModifier(nil, nil, "modifier_invulnerable",nil)
				PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(),hero)
			end
		end
	end)
end

function mines_boss_die(caster)
	caster.dying = true
	EmitGlobalSound("razor_raz_death_04")
	EmitGlobalSound("razor_raz_death_04")
	EmitGlobalSound("razor_raz_death_04")
	StartAnimation(caster, {duration=4.9, activity=ACT_DOTA_FLAIL, rate=0.75})
	Timers:CreateTimer(1.5, function()
		EmitGlobalSound("Loot_Drop_Stinger_Arcana")
	end)
	Timers:CreateTimer(5, function()
		StartAnimation(caster, {duration=10.5, activity=ACT_DOTA_DIE, rate=0.30})
		EmitSoundOn("razor_raz_death_05", caster)
		EmitSoundOn("razor_raz_death_05", caster)
		EmitSoundOn("razor_raz_death_05", caster)
	end)
	Timers:CreateTimer(14, function()
		UTIL_Remove(caster)
		GameRules:SetGameWinner( DOTA_TEAM_GOODGUYS )
	end)
end
