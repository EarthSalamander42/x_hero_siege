require('phases/phase3')

EXPLOSION_SOUND_TABLE = {"Hero_Techies.RemoteMine.Detonate", "Hero_Rattletrap.Rocket_Flare.Explode"}
EXPLOSION_PARTICLE_TABLE = {"particles/econ/items/shadow_fiend/sf_fire_arcana/sf_fire_arcana_shadowraze.vpcf"}

function death_check(event)
	local caster = event.caster
	local ability = event.ability

	if not caster.deathStart then
		if caster:GetHealth() < 100 and not caster:IsIllusion() then
			caster:SetBaseHealthRegen(0.0)
			ability:ApplyDataDrivenModifier(caster, caster, "modifier_dying_generic", {duration = 20})
			CustomGameEventManager:Send_ServerToAllClients("hide_boss_hp", {})
			caster.deathStart = true
			if caster:GetUnitName() == "npc_dota_hero_illidan" then
				illidan_boss_die(caster)
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
				LichKingEnd(caster)
			end
		end
	end
end

function OnCreated(keys)
	if keys.caster:GetUnitName() ~= "npc_dota_hero_grom_hellscream" and keys.caster:GetUnitName() ~= "npc_dota_hero_illidan" and keys.caster:GetUnitName() ~= "npc_dota_hero_balanar" and keys.caster:GetUnitName() ~= "npc_dota_hero_proudmoore" then
		print("Boss Bar created!")
		ShowBossBar(keys.caster)
	end
end

function BossTakeDamage(keys)
	ShowBossBar(keys.caster)
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
		GiveTomeToAllHeroes(250)
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
		DoEntFire("door_illidan", "SetAnimation", "gate_02_open", 0, nil, nil)
		DoEntFire("door_illidan2", "SetAnimation", "gate_02_open", 0, nil, nil)
		caster:ForceKill(true)
		local DoorObs = Entities:FindAllByName("obstruction_illidan")
		for _, obs in pairs(DoorObs) do
			obs:SetEnabled(false, true)
		end
	end)
end

function illidan_boss_die(caster)
FourBossesKillCount()

	Timers:CreateTimer(1.0, function()
		GiveTomeToAllHeroes(250)
		EmitGlobalSound("Loot_Drop_Stinger_Arcana")
	end)

	EmitSoundOn("skeleton_king_wraith_death_long_01", caster)
	EmitSoundOn("skeleton_king_wraith_death_long_01", caster)
	EmitSoundOn("skeleton_king_wraith_death_long_01", caster)
	StartAnimation(caster, {duration=6.0, activity=ACT_DOTA_FLAIL, rate=0.75})

	Timers:CreateTimer(6, function()
		caster:ForceKill(true)
		DoEntFire("door_balanar", "SetAnimation", "gate_02_open", 0, nil, nil)
		DoEntFire("door_balanar2", "SetAnimation", "gate_02_open", 0, nil, nil)
		local DoorObs = Entities:FindAllByName("obstruction_balanar")
		for _, obs in pairs(DoorObs) do
			obs:SetEnabled(false, true)
		end
	end)

	Timers:CreateTimer(6, function()
		StartAnimation(caster, {duration=6.0, activity=ACT_DOTA_DIE, rate=0.25})
		EmitSoundOn("skeleton_king_wraith_death_long_09", caster)
		EmitSoundOn("skeleton_king_wraith_death_long_09", caster)
	end)
end

function proudmoore_boss_die(caster)
FourBossesKillCount()

	Timers:CreateTimer(1.0, function()
		GiveTomeToAllHeroes(250)
		EmitGlobalSound("Loot_Drop_Stinger_Arcana")
	end)

	Timers:CreateTimer(6, function()
		DoEntFire("door_proudmoore2", "SetAnimation", "gate_02_open", 0, nil, nil)
		caster:ForceKill(true)
		local DoorObs = Entities:FindAllByName("obstruction_proudmoore2")
		for _, obs in pairs(DoorObs) do
			obs:SetEnabled(false, true)
		end
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
end

function balanar_boss_die(caster)
FourBossesKillCount()

	Timers:CreateTimer(1.0, function()
		GiveTomeToAllHeroes(250)
		EmitGlobalSound("Loot_Drop_Stinger_Arcana")
	end)

	EmitSoundOn("skeleton_king_wraith_death_long_01", caster)
	EmitSoundOn("skeleton_king_wraith_death_long_01", caster)
	EmitSoundOn("skeleton_king_wraith_death_long_01", caster)
	StartAnimation(caster, {duration=6.0, activity=ACT_DOTA_FLAIL, rate=0.75})

	Timers:CreateTimer(6, function()
		DoEntFire("door_proudmoore", "SetAnimation", "gate_02_open", 0, nil, nil)
		caster:ForceKill(true)
		local DoorObs = Entities:FindAllByName("obstruction_proudmoore")
		for _, obs in pairs(DoorObs) do
			obs:SetEnabled(false, true)
		end
		StartAnimation(caster, {duration=6.0, activity=ACT_DOTA_DIE, rate=0.35})
		EmitSoundOn("skeleton_king_wraith_death_long_09", caster)
		EmitSoundOn("skeleton_king_wraith_death_long_09", caster)
	end)
end

function arthas_boss_die(caster)
	EmitGlobalSound("Arthas.Death")
	Timers:CreateTimer(1.0, function()
		GiveTomeToAllHeroes(250)
		EmitGlobalSound("Loot_Drop_Stinger_Arcana")
	end)

	EmitSoundOn("skeleton_king_wraith_death_long_01", caster)
	EmitSoundOn("skeleton_king_wraith_death_long_01", caster)
	EmitSoundOn("skeleton_king_wraith_death_long_01", caster)
	StartAnimation(caster, {duration=6.0, activity=ACT_DOTA_FLAIL, rate=0.75})

	Timers:CreateTimer(6.2, function()
		StartAnimation(caster, {duration=6.3, activity=ACT_DOTA_DIE, rate=0.22})
		EmitSoundOn("skeleton_king_wraith_death_long_09", caster)
		EmitSoundOn("skeleton_king_wraith_death_long_09", caster)
	end)

	Timers:CreateTimer(11.0, function()
		caster:ForceKill(true)
		CustomGameEventManager:Send_ServerToAllClients("hide_ui", {})
		RefreshPlayers()
	end)

	Timers:CreateTimer(19, function()
	local heroes = HeroList:GetAllHeroes()
		Timers:CreateTimer(5, StartBanehallowArena)
		for _,hero in pairs(heroes) do
		local id = hero:GetPlayerID()
		local point = Entities:FindByName(nil, "point_teleport_boss_"..id)
			if hero:GetTeam() == DOTA_TEAM_GOODGUYS then
				FindClearSpaceForUnit(hero, point:GetAbsOrigin(), true)
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
		GiveTomeToAllHeroes(250)
		EmitGlobalSound("Loot_Drop_Stinger_Arcana")
	end)

	EmitSoundOn("skeleton_king_wraith_death_long_01", caster)
	EmitSoundOn("skeleton_king_wraith_death_long_01", caster)
	EmitSoundOn("skeleton_king_wraith_death_long_01", caster)
	StartAnimation(caster, {duration=6.0, activity=ACT_DOTA_FLAIL, rate=0.75})

	Timers:CreateTimer(6, function()
		StartAnimation(caster, {duration = 6.3, activity=ACT_DOTA_DIE, rate=0.17})
		EmitSoundOn("skeleton_king_wraith_death_long_09", caster)
		EmitSoundOn("skeleton_king_wraith_death_long_09", caster)
	end)

	Timers:CreateTimer(12.5, function()
		caster:ForceKill(true)
		CustomGameEventManager:Send_ServerToAllClients("hide_ui", {})
		RefreshPlayers()
	end)

	Timers:CreateTimer(17, StartLichKingArena)
end

function LichKingEnd(caster)
	Timers:CreateTimer(1.0, function()
		GiveTomeToAllHeroes(250)
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
		caster:ForceKill(true)
		CustomGameEventManager:Send_ServerToAllClients("hide_ui", {})
		RefreshPlayers()
	end)

	Timers:CreateTimer(17, function()
		SPIRIT_MASTER = 0
		SPECIAL_EVENT = 1
		RefreshPlayers()
		GameRules:SetGameWinner(DOTA_TEAM_GOODGUYS)
--		Notifications:TopToAll({text="It's Duel Time!", duration=5.0, style={color="white"}})
--		Timers:CreateTimer(1, function()
--			PauseHeroes()
--			Timers:CreateTimer(5, function()
--				DuelEvent()
--				Timers:CreateTimer(3, RestartHeroes())
--			end)
--		end)
	end)
end
