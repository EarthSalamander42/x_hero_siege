HeroSelection = class({})

-- available heroes
local herolist = {}
local hotdisabledlist = {}
local totalheroes = 0

-- list all available heroes and get their primary attrs, and send it to client
ListenToGameEvent('game_rules_state_change', function()
	if GameRules:State_Get() == DOTA_GAMERULES_STATE_HERO_SELECTION then
		local herolistFile = "scripts/npc/herolist.txt"

		for key,value in pairs(LoadKeyValues(herolistFile)) do
			if KeyValues.HeroKV[key] == nil then -- Cookies: If the hero is not in custom file, load vanilla KV's
--				print(key .. " is not in custom file!")
				local data = LoadKeyValues("scripts/npc/npc_heroes.txt")
				if data and data[key] then
					KeyValues.HeroKV[key] = data[key]
				end
			end

			herolist[key] = KeyValues.HeroKV[key].AttributePrimary

--			if api.imba.hero_is_disabled(key) then
--				hotdisabledlist[key] = 1
--			end

			if value == 0 then
				hotdisabledlist[key] = 1
			else
				totalheroes = totalheroes + 1
				assert(key ~= FORCE_PICKED_HERO, "FORCE_PICKED_HERO cannot be a pickable hero")
			end
		end

		CustomNetTables:SetTableValue("hero_selection", "herolist", {
			herolist = herolist,
			hotdisabledlist = hotdisabledlist,
		})
	end
end, nil)

-- utils
function HeroSelection:RandomImbaHero()
	while true do
		local choice = HeroSelection:UnsafeRandomHero()

		for key, value in pairs(imbalist) do
--			print(key, choice, self:IsHeroDisabled(choice))
			if key == choice and not self:IsHeroDisabled(choice) then
				return choice
			end
		end
	end
end

function HeroSelection:UnsafeRandomHero()
	local curstate = 0
	local rndhero = RandomInt(0, totalheroes)

	for name, _ in pairs(herolist) do
--		print(curstate, rndhero, name)
		if curstate == rndhero then
			for k, v in pairs(hotdisabledlist) do
				if k == name then
--					print("Hero disabled! Try again!")
					return HeroSelection:UnsafeRandomHero()
				end
			end

			return name
		end

		curstate = curstate + 1
	end
end

local load_attachment_modifier = false
function HeroSelection:Attachments(hero)
	if load_attachment_modifier == false then
		load_attachment_modifier = true
		LinkLuaModifier( "modifier_animation_translate_permanent_string", "libraries/modifiers/modifier_animation_translate_permanent_string.lua", LUA_MODIFIER_MOTION_NONE )
	end

	hero_name = string.gsub(hero:GetUnitName(), "npc_dota_hero_", "")

	if hero_name == "sohei" then
		-- hero.hand = SpawnEntityFromTableSynchronous("prop_dynamic", {model = "models/heroes/sohei/so_weapon.vmdl"})
		hero.hand = SpawnEntityFromTableSynchronous("prop_dynamic", {model = "models/heroes/sohei/weapon/immortal/thunderlord.vmdl"})

		-- lock to bone
		hero.hand:FollowEntity(hero, true)

		-- hero:AddNewModifier(hero, nil, 'modifier_animation_translate_permanent_string', {translate = 'walk'})
		-- hero:AddNewModifier(hero, nil, 'modifier_animation_translate_permanent_string', {translate = 'odachi'})
		-- hero:AddNewModifier(hero, nil, 'modifier_animation_translate_permanent_string', {translate = 'aggressive'})
	end
end
