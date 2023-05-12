HeroSelection = class({})

-- available heroes
local herolist = {}
local hotdisabledlist = {}
local totalheroes = 0

-- list all available heroes and get their primary attrs, and send it to client
ListenToGameEvent('game_rules_state_change', function()
	if GameRules:State_Get() == DOTA_GAMERULES_STATE_HERO_SELECTION then
		local herolistFile = "scripts/npc/herolist.txt"

		for key, value in pairs(LoadKeyValues(herolistFile)) do
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
				assert(key ~= "npc_dota_hero_wisp", "npc_dota_hero_wisp cannot be a pickable hero")
			end
		end

		CustomNetTables:SetTableValue("hero_selection", "herolist", {
			herolist = herolist,
			hotdisabledlist = hotdisabledlist,
		})
	end
end, nil)
