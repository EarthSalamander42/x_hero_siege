local function IsBattleRagePlayerHero(hero)
	if hero == nil then return false end
	if IsValidEntity ~= nil and not IsValidEntity(hero) then return false end
	if hero.IsNull ~= nil and hero:IsNull() then return false end
	if hero.IsRealHero == nil or not hero:IsRealHero() then return false end
	if hero.IsIllusion ~= nil and hero:IsIllusion() then return false end
	if hero.IsClone ~= nil and hero:IsClone() then return false end
	if hero.IsTempestDouble ~= nil and hero:IsTempestDouble() then return false end
	if hero.GetTeamNumber == nil or hero:GetTeamNumber() ~= (DOTA_TEAM_GOODGUYS or 2) then return false end
	if hero.GetPlayerOwnerID == nil then return false end

	local playerID = hero:GetPlayerOwnerID()
	if playerID < 0 then return false end
	if PlayerResource ~= nil and PlayerResource.IsValidPlayerID ~= nil
	and not PlayerResource:IsValidPlayerID(playerID) then return false end
	return true
end

local function GetBattleRageBeneficiary(keys)
	-- Both RunScript actions explicitly target ATTACKER. If an older event
	-- payload also exposes attacker, accept it only when it is a player hero.
	if IsBattleRagePlayerHero(keys.target) then return keys.target end
	if keys.attacker ~= keys.target and IsBattleRagePlayerHero(keys.attacker) then
		return keys.attacker
	end
	return nil
end

function AxeBattleRageLifestealBegin(keys)
	local hero = GetBattleRageBeneficiary(keys)
	if hero == nil then return end

	hero.xhs_supporter_axe_battle_rage_lifesteal = nil
	local health_before = hero:GetHealth()
	if health_before >= hero:GetMaxHealth() then return end

	hero.xhs_supporter_axe_battle_rage_lifesteal = {
		health_before = health_before,
		victim = keys.unit or keys.victim,
	}
end

function AxeBattleRageLifestealEnd(keys)
	local hero = GetBattleRageBeneficiary(keys)
	if hero == nil then return end

	local state = hero.xhs_supporter_axe_battle_rage_lifesteal
	hero.xhs_supporter_axe_battle_rage_lifesteal = nil
	if state == nil then return end

	local actual_heal = hero:GetHealth() - (tonumber(state.health_before) or hero:GetHealth())
	if actual_heal > 0 and XHSPlaySupporterAttackLifestealFX ~= nil then
		XHSPlaySupporterAttackLifestealFX(hero, state.victim, actual_heal)
	end
end
