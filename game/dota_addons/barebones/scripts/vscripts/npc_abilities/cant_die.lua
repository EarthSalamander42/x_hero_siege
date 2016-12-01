require('phases/phase3')

EXPLOSION_SOUND_TABLE = {"Hero_Techies.RemoteMine.Detonate", "Hero_Rattletrap.Rocket_Flare.Explode"}
EXPLOSION_PARTICLE_TABLE = {"particles/econ/items/shadow_fiend/sf_fire_arcana/sf_fire_arcana_shadowraze.vpcf"}

function death_check(event)
	local caster = event.caster
	local ability = event.ability
	if not caster.deathStart then
		if caster:GetHealth() < 100 and not caster:IsIllusion() then
			ability:ApplyDataDrivenModifier(caster, caster, "modifier_dying_generic", {duration = 20})
			CustomGameEventManager:Send_ServerToAllClients("hide_boss_health", {})
			caster.deathStart = true
			if caster:GetUnitName() == "npc_dota_hero_illidan" then
				grom_boss_die(caster)
			elseif caster:GetUnitName() == "npc_dota_hero_balanar" then
				balanar_boss_die(caster)
			elseif caster:GetUnitName() == "npc_dota_hero_proudmoore" then
				proudmoore_boss_die(caster)
			elseif caster:GetUnitName() == "npc_dota_hero_grom_hellscream" then
				grom_boss_die(caster)
			elseif caster:GetUnitName() == "npc_dota_hero_arthas" then
				arthas_boss_die(caster)
			elseif caster:GetUnitName() == "npc_dota_hero_banehallow" then
				banehallow_boss_die(caster)
			elseif caster:GetUnitName() == "npc_dota_boss_lich_king" then
				abaddon_boss_die(caster)
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

function grom_boss_die(caster)
FourBossesKillCount()

	Timers:CreateTimer(1.0, function()
		local item = CreateItem("item_bag_of_gold", nil, nil)
		local pos = caster:GetAbsOrigin()
		local drop = CreateItemOnPositionSync( pos, item )
		local pos_launch = pos+RandomVector(RandomFloat(150,200))
		item:LaunchLoot(false, 300, 0.5, pos)
		item:SetCurrentCharges(200000)
		EmitGlobalSound("Loot_Drop_Stinger_Arcana")
	end)

	EmitSoundOn("skeleton_king_wraith_death_long_01", caster)
	EmitSoundOn("skeleton_king_wraith_death_long_01", caster)
	EmitSoundOn("skeleton_king_wraith_death_long_01", caster)
	StartAnimation(caster, {duration=6.0, activity=ACT_DOTA_FLAIL, rate=0.75})

	Timers:CreateTimer(6, function()
		StartAnimation(caster, {duration=6.0, activity=ACT_DOTA_DIE, rate=0.25})
		EmitSoundOn("skeleton_king_wraith_death_long_09", caster)
		EmitSoundOn("skeleton_king_wraith_death_long_09", caster)
	end)

	Timers:CreateTimer(12, function()
		UTIL_Remove(caster)
	end)
end

function proudmoore_boss_die(caster)
FourBossesKillCount()

	Timers:CreateTimer(1.0, function()
		local item = CreateItem("item_bag_of_gold", nil, nil)
		local pos = caster:GetAbsOrigin()
		local drop = CreateItemOnPositionSync( pos, item )
		local pos_launch = pos+RandomVector(RandomFloat(150,200))
		item:LaunchLoot(false, 300, 0.5, pos)
		item:SetCurrentCharges(200000)
		EmitGlobalSound("Loot_Drop_Stinger_Arcana")
	end)

	EmitSoundOn("skeleton_king_wraith_death_long_01", caster)
	EmitSoundOn("skeleton_king_wraith_death_long_01", caster)
	EmitSoundOn("skeleton_king_wraith_death_long_01", caster)
	StartAnimation(caster, {duration=6.0, activity=ACT_DOTA_FLAIL, rate=0.75})

	Timers:CreateTimer(6, function()
		StartAnimation(caster, {duration=6.0, activity=ACT_DOTA_DIE, rate=0.3})
		EmitSoundOn("skeleton_king_wraith_death_long_09", caster)
		EmitSoundOn("skeleton_king_wraith_death_long_09", caster)
	end)

	Timers:CreateTimer(12, function()
		UTIL_Remove(caster)
	end)
end

function balanar_boss_die(caster)
FourBossesKillCount()

	Timers:CreateTimer(1.0, function()
		local item = CreateItem("item_bag_of_gold", nil, nil)
		local pos = caster:GetAbsOrigin()
		local drop = CreateItemOnPositionSync( pos, item )
		local pos_launch = pos+RandomVector(RandomFloat(150,200))
		item:LaunchLoot(false, 300, 0.5, pos)
		item:SetCurrentCharges(200000)
		EmitGlobalSound("Loot_Drop_Stinger_Arcana")
	end)

	EmitSoundOn("skeleton_king_wraith_death_long_01", caster)
	EmitSoundOn("skeleton_king_wraith_death_long_01", caster)
	EmitSoundOn("skeleton_king_wraith_death_long_01", caster)
	StartAnimation(caster, {duration=6.0, activity=ACT_DOTA_FLAIL, rate=0.75})

	Timers:CreateTimer(6, function()
		StartAnimation(caster, {duration=6.0, activity=ACT_DOTA_DIE, rate=0.35})
		EmitSoundOn("skeleton_king_wraith_death_long_09", caster)
		EmitSoundOn("skeleton_king_wraith_death_long_09", caster)
	end)

	Timers:CreateTimer(12, function()
		UTIL_Remove(caster)
	end)
end

function arthas_boss_die(caster)
	Timers:CreateTimer(1.0, function()
		local item = CreateItem("item_bag_of_gold", nil, nil)
		local pos = caster:GetAbsOrigin()
		local drop = CreateItemOnPositionSync( pos, item )
		local pos_launch = pos+RandomVector(RandomFloat(150,200))
		item:LaunchLoot(false, 300, 0.5, pos)
		item:SetCurrentCharges(200000)
		EmitGlobalSound("Loot_Drop_Stinger_Arcana")
	end)

	EmitSoundOn("skeleton_king_wraith_death_long_01", caster)
	EmitSoundOn("skeleton_king_wraith_death_long_01", caster)
	EmitSoundOn("skeleton_king_wraith_death_long_01", caster)
	StartAnimation(caster, {duration=6.0, activity=ACT_DOTA_FLAIL, rate=0.75})

	Timers:CreateTimer(6, function()
		StartAnimation(caster, {duration=6.0, activity=ACT_DOTA_DIE, rate=0.35})
		EmitSoundOn("skeleton_king_wraith_death_long_09", caster)
		EmitSoundOn("skeleton_king_wraith_death_long_09", caster)
	end)

	Timers:CreateTimer(12, function()
		UTIL_Remove(caster)
	end)

	Timers:CreateTimer(19, function()
	local point = Entities:FindByName(nil,"point_teleport_boss"):GetAbsOrigin()
	local heroes = HeroList:GetAllHeroes()
		Timers:CreateTimer(5, StartBaneHallowArena)
		for _,hero in pairs(heroes) do
			if hero:GetTeam() == DOTA_TEAM_GOODGUYS then
				FindClearSpaceForUnit(hero, point, true)
				hero:AddNewModifier(nil, nil, "modifier_animation_freeze_stun", {Duration = 27, IsHidden = true})
				hero:AddNewModifier(nil, nil, "modifier_invulnerable", {Duration = 27, IsHidden = true})
				PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(),hero)
				Timers:CreateTimer(0.1, function()
					PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(),nil)
				end)
			end
		end
	end)
end

function banehallow_boss_die(caster)
	Timers:CreateTimer(1.0, function()
		local item = CreateItem("item_bag_of_gold", nil, nil)
		local pos = caster:GetAbsOrigin()
		local drop = CreateItemOnPositionSync( pos, item )
		local pos_launch = pos+RandomVector(RandomFloat(150, 200))
		item:LaunchLoot(false, 300, 0.5, pos)
		item:SetCurrentCharges(200000)
		EmitGlobalSound("Loot_Drop_Stinger_Arcana")
	end)

	EmitSoundOn("skeleton_king_wraith_death_long_01", caster)
	EmitSoundOn("skeleton_king_wraith_death_long_01", caster)
	EmitSoundOn("skeleton_king_wraith_death_long_01", caster)
	StartAnimation(caster, {duration=6.0, activity=ACT_DOTA_FLAIL, rate=0.75})

	Timers:CreateTimer(6, function()
		StartAnimation(caster, {duration=6.0, activity=ACT_DOTA_DIE, rate=0.20})
		EmitSoundOn("skeleton_king_wraith_death_long_09", caster)
		EmitSoundOn("skeleton_king_wraith_death_long_09", caster)
	end)

	Timers:CreateTimer(12.5, function()
		UTIL_Remove(caster)
	end)

	Timers:CreateTimer(17, StartLichKingArena)
end

function abaddon_boss_die(caster)
	Timers:CreateTimer(1.0, function()
		local item = CreateItem("item_bag_of_gold", nil, nil)
		local pos = caster:GetAbsOrigin()
		local drop = CreateItemOnPositionSync( pos, item )
		local pos_launch = pos+RandomVector(RandomFloat(150,200))
		item:LaunchLoot(false, 300, 0.5, pos)
		item:SetCurrentCharges(200000)
		EmitGlobalSound("Loot_Drop_Stinger_Arcana")
	end)

	EmitGlobalSound("razor_raz_death_04")
	EmitGlobalSound("razor_raz_death_04")
	EmitGlobalSound("razor_raz_death_04")
	StartAnimation(caster, {duration=4.9, activity=ACT_DOTA_FLAIL, rate=0.75})

	Timers:CreateTimer(5, function()
		StartAnimation(caster, {duration=10.0, activity=ACT_DOTA_DIE, rate=0.30})
		EmitSoundOn("razor_raz_death_05", caster)
		EmitSoundOn("razor_raz_death_05", caster)
		EmitSoundOn("razor_raz_death_05", caster)
	end)

	Timers:CreateTimer(14, function()
		UTIL_Remove(caster)
	end)

	Timers:CreateTimer(16, function()
		GameRules:SetGameWinner( DOTA_TEAM_GOODGUYS )
		SendToConsole("dota_health_per_vertical_marker 250")
	end)
end

function FourBossesKillCount()
local teleporters3 = Entities:FindAllByName("trigger_teleport3")
GameMode.BossesTop_killed = GameMode.BossesTop_killed +1
print( GameMode.BossesTop_killed )

	if GameMode.BossesTop_killed > 3 then
		for _,v in pairs(teleporters3) do
			DebugPrint("enable teleport trigger")
			v:Enable()
		end

		Notifications:TopToAll({text="You have killed Grom, Proudmoore, Illidan and Balanar. Red Teleporters Activated" , duration=10.0})
		print( "Teleporter to 4Bosses Activated!" )
	else return nil
	end
end
