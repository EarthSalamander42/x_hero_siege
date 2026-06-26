if XHSBossCastBar == nil then
	XHSBossCastBar = {}
end

local CAST_BAR_TEXTURES = {
	xhs_magtheridon_brutal_slam = "custom/xhs_magtheridon_brutal_slam",
	xhs_magtheridon_fel_stomp = "custom/xhs_magtheridon_fel_stomp",
	xhs_magtheridon_targeted_firestorms = "custom/xhs_magtheridon_targeted_firestorms",
	xhs_magtheridon_fel_fissure = "custom/xhs_magtheridon_fel_fissure",
	xhs_magtheridon_infernal_rings = "custom/xhs_magtheridon_infernal_rings",
	xhs_magtheridon_demonic_howl = "custom/xhs_magtheridon_demonic_howl",
	xhs_magtheridon_rupture = "custom/xhs_magtheridon_rupture",
	frostivus_boss_shadowraze = "custom/xhs_banehallow_shadowraze",
	frostivus_boss_meteorain = "custom/xhs_banehallow_meteorain",
	frostivus_boss_ragna_blade = "custom/xhs_banehallow_ragna_blade",
	frostivus_boss_soul_harvest = "custom/xhs_banehallow_soul_harvest",
	frostivus_boss_nevermore = "custom/xhs_banehallow_darkness",
	frostivus_boss_requiem_of_souls = "custom/xhs_banehallow_requiem_of_souls",
	xhs_grom_mirror_trial = "custom/xhs_grom_mirror_trial",
	xhs_grom_blade_storm = "custom/xhs_grom_blade_storm",
	xhs_grom_mirror_cleave = "custom/xhs_grom_mirror_cleave",
	xhs_grom_windwalk_ambush = "custom/xhs_grom_windwalk_ambush",
	xhs_grom_warsong_leap = "custom/xhs_grom_warsong_leap",
	xhs_illidan_metamorphosis = "custom/xhs_illidan_metamorphosis",
	xhs_illidan_fel_beam = "custom/xhs_illidan_fel_beam",
	xhs_illidan_shadow_dash = "custom/xhs_illidan_shadow_dash",
	xhs_illidan_immolation_burst = "custom/xhs_illidan_immolation_burst",
	xhs_illidan_glaive_storm = "custom/xhs_illidan_glaive_storm",
	xhs_balanar_nightfall = "custom/xhs_balanar_nightfall",
	xhs_balanar_dread_howl = "custom/xhs_balanar_dread_howl",
	xhs_balanar_sleeping_terror = "custom/xhs_balanar_sleeping_terror",
	xhs_balanar_carrion_swarm = "custom/xhs_balanar_carrion_swarm",
	xhs_balanar_rain_of_chaos = "custom/xhs_balanar_rain_of_chaos",
	xhs_proudmoore_admirals_command = "custom/xhs_proudmoore_admirals_command",
	xhs_proudmoore_torrent_line = "custom/xhs_proudmoore_torrent_line",
	xhs_proudmoore_broadside = "custom/xhs_proudmoore_broadside",
	xhs_proudmoore_anchor_smash = "custom/xhs_proudmoore_anchor_smash",
	xhs_proudmoore_focus_fire = "custom/xhs_proudmoore_focus_fire",
	xhs_lich_king_remorseless_winter = "custom/xhs_lich_king_remorseless_winter",
	xhs_lich_king_frostmourne_hunger = "custom/xhs_lich_king_frostmourne_hunger",
	xhs_lich_king_howling_blast = "custom/xhs_lich_king_howling_blast",
	xhs_lich_king_glacial_spikes = "custom/xhs_lich_king_glacial_spikes",
	xhs_lich_king_defile = "custom/xhs_lich_king_defile",
	xhs_lich_king_sindragosa_flyby = "custom/xhs_lich_king_sindragosa_flyby",
	xhs_spirit_master_trinity_cycle = "custom/xhs_spirit_master_trinity_cycle",
	xhs_spirit_master_palm_of_balance = "custom/xhs_spirit_master_palm_of_balance",
	xhs_spirit_master_elemental_mandala = "custom/xhs_spirit_master_elemental_mandala",
	xhs_spirit_master_spirit_call = "custom/xhs_spirit_master_spirit_call",
	xhs_spirit_master_convergence = "custom/xhs_spirit_master_convergence",
	xhs_spirit_storm_arc_dash = "custom/xhs_spirit_storm_arc_dash",
	xhs_spirit_storm_static_orbs = "custom/xhs_spirit_storm_static_orbs",
	xhs_spirit_storm_chain_focus = "custom/xhs_spirit_storm_chain_focus",
	xhs_spirit_earth_fault_line = "custom/xhs_spirit_earth_fault_line",
	xhs_spirit_earth_stone_guard = "custom/xhs_spirit_earth_stone_guard",
	xhs_spirit_earth_resonant_pillar = "custom/xhs_spirit_earth_resonant_pillar",
	xhs_spirit_fire_cinder_step = "custom/xhs_spirit_fire_cinder_step",
	xhs_spirit_fire_solar_flare = "custom/xhs_spirit_fire_solar_flare",
	xhs_spirit_fire_wildfire_ring = "custom/xhs_spirit_fire_wildfire_ring",
}

local function GetAbilityCastPoint(ability)
	if ability == nil then return 0 end
	if ability.GetCastPoint ~= nil then
		local castPoint = ability:GetCastPoint()
		if castPoint ~= nil and castPoint > 0 then return castPoint end
	end

	return ability:GetSpecialValueFor("cast_point")
end

local function GetAbilityName(ability)
	if ability ~= nil and ability.GetAbilityName ~= nil then
		local abilityName = ability:GetAbilityName()
		if abilityName ~= nil and abilityName ~= "" then
			return abilityName
		end
	end

	return ""
end

local function GetAbilityTexture(ability, options)
	if options ~= nil and options.texture ~= nil and options.texture ~= "" then
		return options.texture
	end

	local abilityName = GetAbilityName(ability)
	if CAST_BAR_TEXTURES[abilityName] ~= nil then
		return CAST_BAR_TEXTURES[abilityName]
	end

	if ability ~= nil and ability.GetAbilityTextureName ~= nil then
		local success, texture = pcall(function()
			return ability:GetAbilityTextureName()
		end)
		if success and texture ~= nil and texture ~= "" then
			return texture
		end
	end

	return abilityName
end

function XHSBossCastBar:Start(caster, ability, options)
	if not IsServer() then return end
	if caster == nil or not IsValidEntity(caster) or caster:IsNull() then return end
	if ability == nil or ability:IsNull() then return end

	options = options or {}
	local duration = options.duration or GetAbilityCastPoint(ability)
	if duration == nil or duration <= 0 then return end
	local abilityName = GetAbilityName(ability)

	CustomGameEventManager:Send_ServerToAllClients("xhs_boss_cast_start", {
		boss_count = caster.boss_count or 1,
		boss_bar_id = GetBossBarId and GetBossBarId(caster) or nil,
		ability_name = abilityName,
		display_name = options.display_name,
		texture = GetAbilityTexture(ability, options),
		duration = duration,
		style = options.style,
	})
end

function XHSBossCastBar:Hide(caster)
	if not IsServer() then return end
	if caster == nil or not IsValidEntity(caster) or caster:IsNull() then return end

	CustomGameEventManager:Send_ServerToAllClients("xhs_boss_cast_hide", {
		boss_count = caster.boss_count or 1,
		boss_bar_id = GetBossBarId and GetBossBarId(caster) or nil,
	})
end
