function tome_use(event)
	local hero = event.caster
	local level = hero:GetLevel()
	print(level)
	if IsValidEntity(hero) and level < 30 then 
		hero:AddExperience(XP_PER_LEVEL_TABLE[level+1]-XP_PER_LEVEL_TABLE[level] , DOTA_ModifyXP_Unspecified , false, true)
	end
end