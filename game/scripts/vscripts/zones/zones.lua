if CDungeonZone == nil then
	CDungeonZone = class({})
end

--------------------------------------------------------------------

function CDungeonZone:Init(data)
	--	print("CDungeonZone:Init:", data)
	if data == nil then
		return
	end

	CDungeonZone.bPrecached = false
	CDungeonZone.bActivated = false
	CDungeonZone.bZoneCompleted = false
	CDungeonZone.bZoneCleanupComplete = false
	CDungeonZone.flCompletionTime = 0.0
	CDungeonZone.nStars = 0
	CDungeonZone.nKills = 0
	CDungeonZone.nDeaths = 0
	CDungeonZone.nItems = 0
	CDungeonZone.nGoldBags = 0
	CDungeonZone.nPotions = 0
	CDungeonZone.nReviveTime = 0
	CDungeonZone.nDamage = 0
	CDungeonZone.nHealing = 0

	CDungeonZone.flZoneCleanupTime = 99999.9

	CDungeonZone.PlayerStats = {}

	CDungeonZone.SpawnGroups = {}
	CDungeonZone.Enemies = {}
	CDungeonZone.Bosses = {}

	CDungeonZone.szName = data.szName
	CDungeonZone.nZoneID = data.nZoneID
	CDungeonZone.bVictoryOnComplete = data.bVictoryOnComplete
	CDungeonZone.szTeleportEntityName = data.szTeleportEntityName or nil
	CDungeonZone.vTeleportPos = data.vTeleportPos or nil
	CDungeonZone.Type = data.Type
	CDungeonZone.Quests = data.Quests

	CDungeonZone.StarCriteria = data.StarCriteria or nil
	CDungeonZone.nXPRemaining = data.MaxZoneXP or 0
	CDungeonZone.nMaxZoneXP = data.MaxZoneXP or 1
	CDungeonZone.nGoldRemaining = data.MaxZoneGold or 0
	CDungeonZone.nMaxZoneGold = data.MaxZoneGold or 1
	CDungeonZone.bNoLeaderboard = data.bNoLeaderboard or false
	CDungeonZone.bDropsDisabled = false
	CDungeonZone.hZoneTrigger = Entities:FindByName(nil, "zonevolume_" .. CDungeonZone.szName)
	CDungeonZone.hZoneCheckpoint = Entities:FindByName(nil, CDungeonZone.szName .. "_checkpoint_building")
	CDungeonZone.nPrecacheCount = 0
	CDungeonZone.nExpectedSquadNPCCount = 0
	CDungeonZone.bSpawnedSquads = false
	CDungeonZone.bSpawnedChests = false
	CDungeonZone.bSpawnedBreakables = false
	CDungeonZone.bSpawnedAlliedStructures = false
	CDungeonZone.Squads = data.Squads or {}
	CDungeonZone.Chests = data.Chests or {}
	CDungeonZone.Breakables = data.Breakables or {}
	CDungeonZone.AlliedStructures = data.AlliedStructures or {}
	CDungeonZone.nVIPsKilled = 0
	CDungeonZone.VIPsAlive = {}
	CDungeonZone.VIPs = data.VIPs or {}
	CDungeonZone.Neutrals = data.Neutrals or {}
	CDungeonZone.NeutralsAlive = {}

	if CDungeonZone.hZoneTrigger == nil then
		print("CDungeonZone:Init() - ERROR - No Zone Volume found for zone " .. CDungeonZone.szName)
	end

	for _, quest in pairs(CDungeonZone.Quests) do
		if quest ~= nil then
			quest.bActivated = false
			quest.bCompleted = false
			quest.nCompleted = 0
			quest.bOptional = quest.bOptional or false
			if quest.nCompleteLimit == nil then
				quest.nCompleteLimit = 1
			end
		end
	end

	CDungeonZone.PlayerStats = {}

	for nPlayerID = 0, PlayerResource:GetPlayerCount() - 1 do
		CDungeonZone.PlayerStats[nPlayerID] = {}
		CDungeonZone.PlayerStats[nPlayerID]["Kills"] = 0
		CDungeonZone.PlayerStats[nPlayerID]["Items"] = 0
		CDungeonZone.PlayerStats[nPlayerID]["GoldBags"] = 0
		CDungeonZone.PlayerStats[nPlayerID]["Potions"] = 0
		CDungeonZone.PlayerStats[nPlayerID]["ReviveTime"] = 0
		CDungeonZone.PlayerStats[nPlayerID]["Damage"] = 0
		CDungeonZone.PlayerStats[nPlayerID]["Healing"] = 0
		CDungeonZone.PlayerStats[nPlayerID]["Deaths"] = 0
	end

	if CDungeonZone.Type == ZONE_TYPE_SURVIVAL then
		CDungeonZone.Survival = data.Survival
		CDungeonZone.Survival.bStarted = false
		CDungeonZone.Survival.flTimeOfNextAttack = 0
	end

	if CDungeonZone.Type == ZONE_TYPE_HOLDOUT then
		CDungeonZone.Holdout = data.Holdout
		CDungeonZone.Holdout.bStarted = false
		CDungeonZone.Holdout.bCompleted = false

		CDungeonZone.nCurrentWave = 0
		CDungeonZone.flTimeOfNextSpawn = 0
		CDungeonZone.flTimeOfNextWave = 0

		CDungeonZone.Waves = data.Holdout.Waves
		CDungeonZone.Spawners = data.Holdout.Spawners
		CDungeonZone.nVIPDeathsAllowed = data.Holdout.nVIPDeathsAllowed or 0
	end

	if CDungeonZone.Type == ZONE_TYPE_ASSAULT then
		CDungeonZone.Assault = data.Assault
		CDungeonZone.Assault.bStarted = false
		CDungeonZone.Assault.bCompleted = false
	end

	-- temporary fix
	CDungeonZone:Precache()
end

--------------------------------------------------------------------

function CDungeonZone:Precache()
	--	print( "CDungeonZone:Precache - Precaching Zone " .. CDungeonZone.szName )
	if CDungeonZone.bPrecached == true then
		return
	end

	CDungeonZone.nPrecacheCount = 0

	CDungeonZone:PrecacheNPCs(CDungeonZone.Squads.Fixed)
	CDungeonZone:PrecacheNPCs(CDungeonZone.Squads.Random)
	CDungeonZone:PrecacheVIPs(CDungeonZone.VIPs)
	CDungeonZone:PrecacheNeutrals(CDungeonZone.Neutrals)

	if CDungeonZone.Type == ZONE_TYPE_SURVIVAL then
		if CDungeonZone.Squads.Chasing ~= nil then
			CDungeonZone:PrecacheNPCs(CDungeonZone.Squads.Chasing)
		end
	end

	if CDungeonZone.Type == ZONE_TYPE_HOLDOUT then
		CDungeonZone:PrecacheNPCs(CDungeonZone.Waves)
	end

	if CDungeonZone.Type == ZONE_TYPE_ASSAULT then
		if CDungeonZone.Squads.Chasing ~= nil then
			CDungeonZone:PrecacheNPCs(CDungeonZone.Squads.Chasing)
		end
		CDungeonZone:PrecacheNPCs(CDungeonZone.Assault.Attackers)
	end

	CDungeonZone.bPrecached = true
end

--------------------------------------------------------------------

function CDungeonZone:PrecacheNPCs(zoneTable)
	local nNPCCount = 0

	if zoneTable == nil then
		return
	end

	for _, npcTable in pairs(zoneTable) do
		if npcTable ~= nil then
			--	print( "CDungeonZone:PrecacheEnemies() - Precaching squad " .. tostring( enemyTable ) )
			for _, unitTable in pairs(npcTable["NPCs"]) do
				if unitTable ~= nil then
					nNPCCount = nNPCCount + unitTable.nCount
					local bFound = false
					for _, precachedNPC in pairs(GameRules.GameMode.PrecachedEnemies) do
						if precachedNPC == unitTable.szNPCName then
							bFound = true
						end
					end
					if bFound == false then
						CDungeonZone.nPrecacheCount = CDungeonZone.nPrecacheCount + 1
						PrecacheUnitByNameAsync(unitTable.szNPCName, function(sg) table.insert(CDungeonZone.SpawnGroups, sg) end)
						table.insert(GameRules.GameMode.PrecachedEnemies, unitTable.szNPCName)
						--print( "CDungeonZone:PrecacheNPCs() - Precached unit of type " .. unitTable.szNPCName )
					end
				end
			end
		end
	end
end

--------------------------------------------------------------------

function CDungeonZone:PrecacheVIPs(vipTable)
	if vipTable == nil or #vipTable == 0 then
		return
	end

	local nVIPCount = 0
	CDungeonZone.nPrecacheVIPCount = 0

	--	print( "CDungeonZone:PrecacheVIPs() - Precaching VIPs " .. tostring( vipTable ) )
	for _, unitTable in pairs(vipTable) do
		if unitTable ~= nil then
			nVIPCount = nVIPCount + unitTable.nCount
			local bFound = false
			for _, precachedVIP in pairs(GameRules.GameMode.PrecachedVIPs) do
				if precachedVIP == unitTable.szVIPName then
					bFound = true
				end
			end
			if bFound == false then
				CDungeonZone.nPrecacheVIPCount = CDungeonZone.nPrecacheVIPCount + 1
				PrecacheUnitByNameAsync(unitTable.szVIPName, function(sg) table.insert(CDungeonZone.SpawnGroups, sg) end)
				table.insert(GameRules.GameMode.PrecachedVIPs, unitTable.szVIPName)
				--print( "CDungeonZone:PrecacheVIPs() - Precached unit of type " .. unitTable.szVIPName )
			end
		end
	end
	--	print( "CDungeonZone:PrecacheVIPs() - There are " .. CDungeonZone.nPrecacheVIPCount .. " VIP types in zone." )
end

--------------------------------------------------------------------

function CDungeonZone:PrecacheNeutrals(neutralTable)
	if neutralTable == nil or #neutralTable == 0 then
		return
	end

	--print( "CDungeonZone:PrecacheNeutrals() - Precaching Neutrals " .. tostring( neutralTable ) )
	for _, unitTable in pairs(neutralTable) do
		if unitTable ~= nil then
			PrecacheUnitByNameAsync(unitTable.szNPCName, function(sg) table.insert(CDungeonZone.SpawnGroups, sg) end)
		end
	end
end

--------------------------------------------------------------------

function CDungeonZone:SpawnSquadCreatures(bAsync)
	if CDungeonZone.bSpawnedSquads == true then
		return
	end

	CDungeonZone.bSpawnedSquads = true
	CDungeonZone.nExpectedSquadNPCCount = 0
	--print( "-----------------------------------" )
	if CDungeonZone.Squads.Fixed ~= nil then
		--print( "CDungeonZone:SpawnSquadCreatures() - Spawning Fixed Squads" )
		for _, squadTable in pairs(CDungeonZone.Squads.Fixed) do
			if (squadTable.szSpawnerName == nil) then
				print("CDungeonZone:SpawnSquadCreatures() - ERROR: No spawnerName specified for this squad type")
				return
			end

			local hSpawners = Entities:FindAllByName(squadTable.szSpawnerName)
			--print( "Found " .. #hSpawners .. " map spawners." )

			for _, hSpawner in pairs(hSpawners) do
				hSpawner.tSquadMembers = {}
				for _, npc in pairs(squadTable.NPCs) do
					for k = 1, npc.nCount do
						local hUnit = CDungeonZone:SpawnSquadUnit(npc, DOTA_TEAM_BADGUYS, hSpawner, "SquadState", squadTable.nMaxSpawnDistance, bAsync)

						-- Add unit to the hSpawner's squad members table
						table.insert(hSpawner.tSquadMembers, hUnit)
					end
					CDungeonZone.nExpectedSquadNPCCount = CDungeonZone.nExpectedSquadNPCCount + npc.nCount
				end
			end
		end
	end


	if CDungeonZone.Squads.Random ~= nil then
		--print( "CDungeonZone:SpawnSquadCreatures() - Spawning Random Squads" )
		local hSpawnerList = {}
		for _, squadTable in pairs(CDungeonZone.Squads.Random) do
			if (squadTable.szSpawnerName == nil) then
				print("CDungeonZone:SpawnSquadCreatures() - ERROR: No spawnerName specified for this squad type")
				return
			end

			local hSpawners = Entities:FindAllByName(squadTable.szSpawnerName)
			for _, hSpawner in pairs(hSpawners) do
				local bRepeated = false
				for _, UsedSpawner in pairs(hSpawnerList) do
					if UsedSpawner == hSpawner then
						bRepeated = true
					end
				end

				if not bRepeated then
					table.insert(hSpawnerList, hSpawner)
				end
			end
		end

		for _, squadTable in pairs(CDungeonZone.Squads.Random) do
			local nIndex = RandomInt(1, #hSpawnerList)
			local hSpawnerToUse = hSpawnerList[nIndex]
			if hSpawnerToUse ~= nil then
				for _, npc in pairs(squadTable.NPCs) do
					for k = 1, npc.nCount do
						local hUnit = CDungeonZone:SpawnSquadUnit(npc, DOTA_TEAM_BADGUYS, hSpawnerToUse, "SquadState", squadTable.nMaxSpawnDistance, bAsync)

						-- Add unit to the hSpawner's squad members table
						--	table.insert( hSpawner.tSquadMembers, hUnit )
					end
					CDungeonZone.nExpectedSquadNPCCount = CDungeonZone.nExpectedSquadNPCCount + npc.nCount
				end

				table.remove(hSpawnerList, nIndex)
			end
		end
	end
end

--------------------------------------------------------------------------------

function CDungeonZone:SpawnSquadUnit(npcData, nTeam, hSpawner, sState, nMaxSpawnDistance, bAsync)
	local vSpawnerPos = hSpawner:GetOrigin()
	if nMaxSpawnDistance == nil then
		nMaxSpawnDistance = 0
	end
	local vUnitSpawnPos = vSpawnerPos + RandomVector(RandomFloat(25, nMaxSpawnDistance))

	local nAttempts = 0
	-- Verify path is clear from spawner to desired spawn loc (give up after a few, so we can't get stuck)
	while ((not GridNav:CanFindPath(vSpawnerPos, vUnitSpawnPos)) and (nAttempts < 5)) do
		vUnitSpawnPos = vSpawnerPos + RandomVector(RandomFloat(25, nMaxSpawnDistance))
		nAttempts = nAttempts + 1
		--print( "Verify path is clear from spawner to desired spawn loc, attempt #" .. nAttempts )
	end

	if bAsync then
		CreateUnitByNameAsync(npcData.szNPCName, vUnitSpawnPos, true, nil, nil, nTeam,
			function(hUnit)
				--	print( hUnit )
				--	print( hUnit:GetUnitName() )
				hUnit.sState = sState
				if npcData.bBoss == true then
					hUnit.bBoss = true
					hUnit.bStarted = false
				end
				CDungeonZone:AddEnemyToZone(hUnit)
				if npcData.bUseSpawnerFaceAngle == true then
					local vSpawnerForward = hSpawner:GetForwardVector()
					hUnit:SetForwardVector(vSpawnerForward)
				else
					hUnit:FaceTowards(hSpawner:GetOrigin())
				end


				if #CDungeonZone.Enemies == CDungeonZone.nExpectedSquadNPCCount then
					--print( "CDungeonZone:SpawnSquadUnit() - Async Spawning Complete.  There are " .. #CDungeonZone.Enemies .. " enemies in zone." )
				end
			end)
	else
		local hUnit = CreateUnitByName(npcData.szNPCName, vUnitSpawnPos, true, nil, nil, nTeam)
		hUnit.sState = sState
		if npcData.bBoss == true then
			hUnit.bBoss = true
			hUnit.bStarted = false
		end
		CDungeonZone:AddEnemyToZone(hUnit)
		if npcData.bUseSpawnerFaceAngle == true then
			local vSpawnerForward = hSpawner:GetForwardVector()
			hUnit:SetForwardVector(vSpawnerForward)
		else
			hUnit:FaceTowards(hSpawner:GetOrigin())
		end
		return hUnit
	end
end

--------------------------------------------------------------------------------

function CDungeonZone:SpawnChests()
	if CDungeonZone.bSpawnedChests == true then
		return
	end

	CDungeonZone.bSpawnedChests = true

	--print( "-----------------------------------" )
	--print( "CDungeonZone:SpawnChests()" )

	--print( string.format( "There are %d chest tables in zone \"%s\"", #CDungeonZone.Chests, CDungeonZone.szName ) )
	--PrintTable( CDungeonZone.Chests, "   " )

	for index, chestTable in ipairs(CDungeonZone.Chests) do
		--print( "" )
		--print( "Looking at chestTable #" .. index )
		if (chestTable.szSpawnerName == nil) then
			print(string.format("CDungeonZone:SpawnChests() - ERROR: No szSpawnerName specified for this chest. [Zone: \"%s\"]", CDungeonZone.szName))
		end

		local fSpawnChance = chestTable.fSpawnChance
		if fSpawnChance == nil or fSpawnChance <= 0 then
			print(string.format("CDungeonZone:SpawnChests - ERROR: Treasure chest spawn chance is not valid [Zone: \"%s\"]", CDungeonZone.szName))
		end

		if chestTable.nMaxSpawnDistance == nil or chestTable.nMaxSpawnDistance < 0 then
			print(string.format("CDungeonZone:SpawnChests - WARNING: nMaxSpawnDistance is not valid. Defaulting to 0. [Zone: \"%s\"]", CDungeonZone.szName))
			chestTable.nMaxSpawnDistance = 0
		end

		if (chestTable.szSpawnerName ~= nil) then
			--print( "chestTable.szSpawnerName == " .. chestTable.szSpawnerName )
			local hSpawners = Entities:FindAllByName(chestTable.szSpawnerName)
			for _, hSpawner in pairs(hSpawners) do
				local vSpawnLoc = hSpawner:GetOrigin() + RandomVector(RandomFloat(0, chestTable.nMaxSpawnDistance))
				-- Roll dice to determine whether to spawn chest at this spawner
				local fThreshold = 1 - fSpawnChance
				local bSpawnChest = RandomFloat(0, 1) >= fThreshold
				if bSpawnChest then
					local hUnit = CreateUnitByName(chestTable.szNPCName, vSpawnLoc, true, nil, nil, DOTA_TEAM_GOODGUYS)
					if hUnit ~= nil then
						local vSpawnerForward = hSpawner:GetForwardVector()
						hUnit:SetForwardVector(vSpawnerForward)

						--print( "Created chest unit named " .. hUnit:GetUnitName() )
						hUnit.zone = CDungeonZone
						hUnit.Items = chestTable.Items
						hUnit.fItemChance = chestTable.fItemChance
						hUnit.Relics = chestTable.Relics
						hUnit.fRelicChance = chestTable.fRelicChance
						hUnit.nMinGold = chestTable.nMinGold
						hUnit.nMaxGold = chestTable.nMaxGold
						hUnit.szTraps = chestTable.szTraps
						hUnit.nTrapLevel = chestTable.nTrapLevel

						CDungeonZone:AddTreasureChestToZone(hUnit)
					end
				end
			end
		end
	end
end

--------------------------------------------------------------------

function CDungeonZone:SpawnBreakables()
	if CDungeonZone.bSpawnedBreakables == true then
		return
	end

	CDungeonZone.bSpawnedBreakables = true

	--print( "-----------------------------------" )
	--print( "CDungeonZone:SpawnBreakables()" )
	--print( string.format( "There are %d breakable tables in zone \"%s\"", #CDungeonZone.Breakables, CDungeonZone.szName ) )
	--PrintTable( CDungeonZone.Breakables, "   " )

	for index, breakableTable in ipairs(CDungeonZone.Breakables) do
		--print( "" )
		--print( "Looking at breakableTable #" .. index )
		if (breakableTable.szSpawnerName == nil) then
			print(string.format("CDungeonZone:SpawnBreakables() - ERROR: No szSpawnerName specified for this breakable container. [Zone: \"%s\"]", CDungeonZone.szName))
		end

		local fSpawnChance = breakableTable.fSpawnChance
		if fSpawnChance == nil or fSpawnChance <= 0 then
			print(string.format("CDungeonZone:SpawnBreakables - ERROR: Breakable container spawn chance is not valid [Zone: \"%s\"]", CDungeonZone.szName))
		end

		if breakableTable.nMaxSpawnDistance == nil or breakableTable.nMaxSpawnDistance < 0 then
			print(string.format("CDungeonZone:SpawnBreakables - WARNING: nMaxSpawnDistance is not valid. Defaulting to 0. [Zone: \"%s\"]", CDungeonZone.szName))
			breakableTable.nMaxSpawnDistance = 0
		end

		if (breakableTable.szSpawnerName ~= nil) then
			--print( "breakableTable.szSpawnerName == " .. breakableTable.szSpawnerName )
			local hSpawners = Entities:FindAllByName(breakableTable.szSpawnerName)
			for _, hSpawner in pairs(hSpawners) do
				local vSpawnLoc = hSpawner:GetOrigin() + RandomVector(RandomFloat(0, breakableTable.nMaxSpawnDistance))
				-- Roll dice to determine whether to spawn breakable at this spawner
				local fThreshold = 1 - fSpawnChance
				local bSpawnBreakable = RandomFloat(0, 1) >= fThreshold
				if bSpawnBreakable then
					local hUnit = CreateUnitByName(breakableTable.szNPCName, vSpawnLoc, true, nil, nil, DOTA_TEAM_BADGUYS)
					if hUnit ~= nil then
						local vSpawnerForward = hSpawner:GetForwardVector()
						hUnit:SetForwardVector(vSpawnerForward)

						--print( "Created breakable container unit named " .. hUnit:GetUnitName() )
						hUnit.zone = CDungeonZone
						hUnit.CommonItems = breakableTable.CommonItems
						hUnit.fCommonItemChance = breakableTable.fCommonItemChance
						hUnit.RareItems = breakableTable.RareItems
						hUnit.fRareItemChance = breakableTable.fRareItemChance
						hUnit.nMinGold = breakableTable.nMinGold
						hUnit.nMaxGold = breakableTable.nMaxGold
						hUnit.fGoldChance = breakableTable.fGoldChance
						hUnit:AddNewModifier(hUnit, nil, "modifier_breakable_container", {})

						CDungeonZone:AddBreakableContainerToZone(hUnit)
					end
				end
			end
		end
	end
end

--------------------------------------------------------------------

function CDungeonZone:SpawnAlliedStructures()
	if CDungeonZone.bSpawnedAlliedStructures == true then
		return
	end

	CDungeonZone.bSpawnedAlliedStructures = true

	--print( "-----------------------------------" )
	--print( "CDungeonZone:SpawnAlliedStructures()" )
	--print( string.format( "There are %d structure tables in zone \"%s\"", #CDungeonZone.AlliedStructures, CDungeonZone.szName ) )
	--PrintTable( CDungeonZone.AlliedStructures, "   " )

	for index, structureTable in ipairs(CDungeonZone.AlliedStructures) do
		--print( "" )
		--print( "Looking at structureTable #" .. index )
		if (structureTable.szSpawnerName == nil) then
			print(string.format("CDungeonZone:SpawnAlliedStructures() - ERROR: No szSpawnerName specified for this structure. [Zone: \"%s\"]", CDungeonZone.szName))
		end

		local fSpawnChance = structureTable.fSpawnChance
		if fSpawnChance == nil or fSpawnChance <= 0 then
			print(string.format("CDungeonZone:SpawnAlliedStructures - ERROR: Structure spawn chance is not valid [Zone: \"%s\"]", CDungeonZone.szName))
		end

		if structureTable.nMaxSpawnDistance == nil or structureTable.nMaxSpawnDistance < 0 then
			print(string.format("CDungeonZone:SpawnAlliedStructures - WARNING: nMaxSpawnDistance is not valid. Defaulting to 0. [Zone: \"%s\"]", CDungeonZone.szName))
			structureTable.nMaxSpawnDistance = 0
		end

		if (structureTable.szSpawnerName) then
			--print( "structureTable.szSpawnerName == " .. structureTable.szSpawnerName )
			local hSpawners = Entities:FindAllByName(structureTable.szSpawnerName)
			for _, hSpawner in pairs(hSpawners) do
				local vSpawnLoc = hSpawner:GetOrigin() + RandomVector(RandomFloat(0, structureTable.nMaxSpawnDistance))
				-- Roll dice to determine whether to spawn structure at this spawner
				local fThreshold = 1 - fSpawnChance
				local bSpawnStructure = RandomFloat(0, 1) >= fThreshold
				if bSpawnStructure then
					local hUnit = CreateUnitByName(structureTable.szNPCName, vSpawnLoc, true, nil, nil, DOTA_TEAM_GOODGUYS)
					if hUnit then
						local vSpawnerForward = hSpawner:GetForwardVector()
						hUnit:SetForwardVector(vSpawnerForward)

						--print( "Created allied structure unit named " .. hUnit:GetUnitName() )
						hUnit.zone = CDungeonZone

						--CDungeonZone:AddBreakableContainerToZone( hUnit )
					end
				end
			end
		end
	end
end

--------------------------------------------------------------------

function CDungeonZone:SpawnVIPs(vipsTable)
	-- print( "-----------------------------------" )
	-- print( "CDungeonZone:SpawnVIPs()" )
	if vipsTable == nil then
		print("CDungeonZone:SpawnVIPs() - ERROR: No VIPs Table")
		return
	end

	for _, vip in pairs(vipsTable) do
		local hSpawner = Entities:FindByName(nil, vip.szSpawnerName)
		if hSpawner == nil then
			print("CDungeonZone:SpawnVIPs() - ERROR: No Spawners found named:", vip.szSpawnerName)
			return
		end

		if hSpawner ~= nil then
			-- print( "CDungeonZone:SpawnVIPs() - Spawning " .. vip.nCount .. " " .. vip.szVIPName )

			if vip.nSpawnAmt == nil then
				vip.nSpawnAmt = 0
			end

			if (vip.nMaxSpawnCount == nil) or (vip.nSpawnAmt < vip.nMaxSpawnCount) then
				for i = 1, vip.nCount do
					local hUnit = CreateUnitByName(vip.szVIPName, hSpawner:GetOrigin(), true, nil, nil, DOTA_TEAM_GOODGUYS)

					if hUnit ~= nil then
						hUnit.zone = CDungeonZone
						hUnit.isInHoldout = true
						hUnit:AddNewModifier(hUnit, nil, "modifier_npc_dialog", { duration = -1 })
						local hAnimationBuff = hUnit:AddNewModifier(hUnit, nil, "modifier_stack_count_animation_controller", {})
						if hAnimationBuff ~= nil and vip.Activity ~= nil then
							hAnimationBuff:SetStackCount(vip.Activity)
						end
						hUnit.bRequired = vip.bRequired or false

						local vSpawnerForward = hSpawner:GetForwardVector()
						hUnit:SetForwardVector(vSpawnerForward)

						if vip.szWaypointName then
							local hWaypoint = nil
							hWaypoint = Entities:FindByName(nil, vip.szWaypointName)
							if hWaypoint ~= nil then
								hUnit:SetInitialGoalEntity(hWaypoint)
							end
						end

						vip.nSpawnAmt = vip.nSpawnAmt + 1
						table.insert(CDungeonZone.VIPsAlive, hUnit)
					else
						print("CDungeonZone:SpawnVIPs() - ERROR: Unit spawning of unit " .. vip.szVIPName .. " failed")
					end
				end
			end
		end
	end
end

--------------------------------------------------------------------

function CDungeonZone:SpawnNeutrals(NeutralsTable)
	--print( "-----------------------------------" )
	--print( "CDungeonZone:SpawnNeutrals()" )
	if NeutralsTable == nil then
		print("CDungeonZone:SpawnNeutrals() - ERROR: No Neutrals Table")
		return
	end

	for _, neutral in pairs(NeutralsTable) do
		local hSpawner = Entities:FindByName(nil, neutral.szSpawnerName)
		if hSpawner == nil then
			print("CDungeonZone:SpawnNeutrals() - ERROR: No Spawners named " .. neutral.szSpawnerName .. " found")
		else
			--print( "CDungeonZone:SpawnNeutrals() - Spawning " .. neutral.nCount .. " " .. neutral.szNPCName )

			if neutral.nSpawnAmt == nil then
				neutral.nSpawnAmt = 0
			end

			if (neutral.nMaxSpawnCount == nil) or (neutral.nSpawnAmt < neutral.nMaxSpawnCount) then
				for i = 1, neutral.nCount do
					local hUnit = CreateUnitByName(neutral.szNPCName, hSpawner:GetOrigin(), true, nil, nil, DOTA_TEAM_GOODGUYS)
					if hUnit ~= nil then
						hUnit.zone = CDungeonZone
						hUnit.isInHoldout = true
						hUnit:AddNewModifier(hUnit, nil, "modifier_npc_dialog", { duration = -1 })
						local hAnimationBuff = hUnit:AddNewModifier(hUnit, nil, "modifier_stack_count_animation_controller", {})
						if hAnimationBuff ~= nil and neutral.Activity ~= nil then
							hAnimationBuff:SetStackCount(neutral.Activity)
						end
						--hack
						if hUnit:GetUnitName() == "npc_dota_creature_invoker" then
							hUnit:RemoveModifierByName("modifier_stack_count_animation_controller")
							hUnit:AddNewModifier(hUnit, nil, "modifier_invoker_juggle", { duration = -1 });
						end

						hUnit.bRequired = neutral.bRequired or false

						local vSpawnerForward = hSpawner:GetForwardVector()
						hUnit:SetForwardVector(vSpawnerForward)

						if neutral.szWaypointName then
							local hWaypoint = nil
							hWaypoint = Entities:FindByName(nil, neutral.szWaypointName)
							if hWaypoint ~= nil then
								hUnit:SetInitialGoalEntity(hWaypoint)
								hUnit:AddNewModifier(hUnit, nil, "modifier_followthrough", { duration = 1.0 }) -- maybe this fixes NPC staying in his idle state
							end
						end

						neutral.nSpawnAmt = neutral.nSpawnAmt + 1
						table.insert(CDungeonZone.NeutralsAlive, hUnit)
					else
						print("CDungeonZone:SpawnNeutrals() - ERROR: Unit spawning of unit " .. neutral.szNPCName .. " failed")
					end
				end
			end
		end
	end
end

--------------------------------------------------------------------

function CDungeonZone:SpawnChasingSquads(nCount, nTeamNumber, ChaserSquads, ChaserSpawners, SquadPool, bNoRepeat)
	if CDungeonZone:InBossFight() then
		--	print( "CDungeonZone:SpawnChasingSquads() - Aborting Spawn, boss fight is active." )
		return
	end

	if ChaserSquads == nil or ChaserSpawners == nil or SquadPool == nil then
		print("CDungeonZone:SpawnChasingSquads() - ERROR: Squads or Spawners are nil")
		return
	end

	EmitAnnouncerSound("Dungeon.ChaserSpawn")

	local SelectedSpawners = {}
	local RemainingSquads = shallowcopy(ChaserSquads)
	for i = 1, nCount do
		local nSelectedSquadIndex = RandomInt(1, #RemainingSquads)
		local szChaserSquadName = RemainingSquads[nSelectedSquadIndex]
		if szChaserSquadName == nil then
			print("CDungeonZone:SpawnChasingSquads() - ERROR: No Chaser Squad Name")
			return
		end

		if bNoRepeat then
			if #RemainingSquads == 1 and i < nCount then
				print("CDungeonZone:SpawnChasingSquads() - ERROR: There are " .. nCount - i .. " too few squads defined")
			end
			table.remove(RemainingSquads, nSelectedSquadIndex)
			--	print( "CDungeonZone:SpawnChasingSquads() - No Repeat set, removing squad named " .. szChaserSquadName )
		end

		local ChaserSquad = SquadPool.Fixed[szChaserSquadName]
		if ChaserSquad == nil then
			--Look in random
			ChaserSquad = SquadPool.Random[szChaserSquadName]
			if ChaserSquad == nil then
				-- Look in Attackers
				ChaserSquad = SquadPool.Chasing[szChaserSquadName]
				if ChaserSquad == nil then
					print("CDungeonZone:SpawnChasingSquads() - ERROR: No Chaser Squad named " .. szChaserSquadName)
					return
				end
			end
		end

		local vCenterOfHeroes = nil
		local Heroes = HeroList:GetAllHeroes()
		if #Heroes == 0 then
			print("CDungeonZone:SpawnChasingSquads() - ERROR: No Heroes")
			return
		end

		for _, hero in ipairs(Heroes) do
			if hero ~= nil and hero:IsRealHero() and hero:IsAlive() then
				if vCenterOfHeroes == nil then
					vCenterOfHeroes = hero:GetOrigin()
				else
					vCenterOfHeroes = vCenterOfHeroes + hero:GetOrigin()
				end
			end
		end

		if vCenterOfHeroes == nil then
			--	print( "CDungeonZone:SpawnChasingSquads() - All heroes dead, skip chasing spawn." )
			return
		end

		vCenterOfHeroes = vCenterOfHeroes / #Heroes

		local hNearestHiddenSpawner = nil
		local flClosestDist = 10000
		local flMinDist = 1500
		for _, szSpawnerName in pairs(ChaserSpawners) do
			--	print( "CDungeonZone:SpawnChasingSquads() - Calculating Distance of " .. szSpawnerName )
			local hSpawners = Entities:FindAllByName(szSpawnerName)
			--	print( "CDungeonZone:SpawnChasingSquads() - #hSpawners == " .. #hSpawners )
			if hSpawners == nil or #hSpawners == 0 then
				print("CDungeonZone:SpawnChasingSquads() - ERROR: No Spawner Found Named: " .. szSpawnerName)
			else
				--print( "Found " .. #hSpawners .. " spawners" )
				for _, spawner in pairs(hSpawners) do
					local bUsed = false
					for _, UsedSpawners in pairs(SelectedSpawners) do
						if UsedSpawners == spawner then
							bUsed = true
						end
					end

					if not IsLocationVisible(DOTA_TEAM_GOODGUYS, spawner:GetOrigin()) then
						local flSpawnerDist = (spawner:GetOrigin() - vCenterOfHeroes):Length2D()
						if (not bUsed) and (flSpawnerDist < flClosestDist) and (flSpawnerDist > flMinDist) then
							--	print( "   this spawner's distance of " .. flSpawnerDist .. " is closer than our previous closest distance of " .. flClosestDist )
							flClosestDist = flSpawnerDist
							hNearestHiddenSpawner = spawner
						end
					end
				end
			end
		end

		if hNearestHiddenSpawner == nil then
			print("CDungeonZone:SpawnChasingSquads() - ERROR: No Nearest Hidden Spawner Found")
			return
		end


		local NPCs = ChaserSquad.NPCs
		if NPCs == nil then
			print("CDungeonZone:SpawnChasingSquads() - ERROR: No NPCs Table")
			return
		end

		--print( "Spawn Squad " .. szAttackerSquad .. " at " .. hNearestHiddenSpawner:GetName() )
		for _, npc in pairs(NPCs) do
			for i = 1, npc.nCount do
				local hUnit = CreateUnitByName(npc.szNPCName, hNearestHiddenSpawner:GetOrigin(), true, nil, nil, nTeamNumber)
				if hUnit ~= nil then
					hUnit.bAttacker = true
					if nTeamNumber == DOTA_TEAM_BADGUYS then
						CDungeonZone:AddEnemyToZone(hUnit)
					end

					local hAttackTarget = nil

					for i = 1, #Heroes do
						if hAttackTarget == nil then
							hAttackTarget = Heroes[RandomInt(1, #Heroes)]
							if hAttackTarget ~= nil and CDungeonZone:ContainsUnit(hAttackTarget) and (hAttackTarget:IsRealHero() == false or hAttackTarget:IsAlive() == false) then
								hAttackTarget = nil
							end
						end
					end
					if hAttackTarget ~= nil then
						hUnit:SetInitialGoalEntity(hAttackTarget)
						hUnit:SetContextThink(string.format("Chaser_aiThink_%s", hUnit:entindex()), function() return Chaser_aiThink(CDungeonZone, hUnit) end, 0)
					else
						print("CDungeonZone:SpawnChasingSquads() - ERROR: No Valid Attacker Target Found")
					end

					if CDungeonZone.bDropsDisabled then
						hUnit:RemoveAllItemDrops()
					end
				else
					print("CDungeonZone:SpawnChasingSquads() - ERROR: Spawning of unit " .. npc.szNPCName .. " failed")
				end
			end
		end

		table.insert(SelectedSpawners, hNearestHiddenSpawner)
	end
end

--------------------------------------------------------------------

function CDungeonZone:SpawnPathingSquads(waveTable, nTeamNumber)
	--print( "-----------------------------------" )
	--print( "CDungeonZone:SpawnPathingSquads()" )
	if waveTable == nil then
		print("CDungeonZone:SpawnPathingSquads() - ERROR: No Wave Table")
		return
	end

	local NPCs = waveTable.NPCs
	if NPCs == nil then
		print("CDungeonZone:SpawnPathingSquads() - ERROR: No NPCs Table")
		return
	end

	for _, npc in pairs(NPCs) do
		if npc.flDelay ~= nil then
			--print( "CDungeonZone:SpawnPathingSquads() - NPC " .. npc.szNPCName .. " has " .. npc.flDelay .. " seconds remaining before spawning." )
			npc.flDelay = npc.flDelay - waveTable.flSpawnInterval
			if npc.flDelay <= 0.0 then
				npc.flDelay = nil
			end
		end

		if npc.flDelay == nil then
			local hSpawner = Entities:FindByName(nil, npc.szSpawnerName)
			local hWaypoint = Entities:FindByName(nil, npc.szWaypointName)
			if hWaypoint == nil or hSpawner == nil then
				if hWaypoint == nil then
					for _, VIP in pairs(CDungeonZone.VIPsAlive) do
						if VIP ~= nil and VIP:GetUnitName() == npc.szWaypointName then
							hWaypoint = VIP
						end
					end
					if hWaypoint == nil then
						print("CDungeonZone:SpawnPathingSquads() - ERROR: No Waypoint Found")
					end
				end

				if hSpawner == nil then
					if #CDungeonZone.Spawners == 0 then
						print("CDungeonZone:SpawnPathingSquads() - ERROR: No Specific or Random Spawners Defined")
					else
						local SpawnerData = CDungeonZone.Spawners[RandomInt(1, #CDungeonZone.Spawners)]
						if SpawnerData ~= nil then
							hSpawner = Entities:FindByName(nil, SpawnerData.szSpawnerName)
							hWaypoint = Entities:FindByName(nil, SpawnerData.szWaypointName)
						else
							print("CDungeonZone:SpawnPathingSquads() - ERROR: Choosing random spawner and waypoint failed")
						end
					end
				end
			end

			if hSpawner ~= nil and hWaypoint ~= nil then
				if npc.nSpawnAmt == nil then
					npc.nSpawnAmt = 0
				end
				if (npc.nMaxSpawnCount == nil) or (npc.nSpawnAmt < npc.nMaxSpawnCount) then
					for i = 1, npc.nCount do
						local hUnit = CreateUnitByName(npc.szNPCName, hSpawner:GetOrigin(), true, nil, nil, nTeamNumber)
						if hUnit ~= nil then
							hUnit.isInHoldout = true

							--This might seem weird, but it's so we can move the bounty into gold bags and zone xp distribution and maintain limits

							hUnit.bBoss = npc.bBoss or false
							hUnit.bStarted = false
							if nTeamNumber == DOTA_TEAM_BADGUYS then
								CDungeonZone:AddEnemyToZone(hUnit)
							end

							if not npc.bDontSetGoalEntity then
								hUnit:SetInitialGoalEntity(hWaypoint)
							end
							npc.nSpawnAmt = npc.nSpawnAmt + 1
						else
							print("CDungeonZone:SpawnPathingSquads() - ERROR: Unit spawning of unit " .. npc.szNPCName .. " failed")
						end
					end
				end
			end
		end
	end
end

--------------------------------------------------------------------

function CDungeonZone:Activate()
	if CDungeonZone.bActivated == true or CDungeonZone.bZoneCompleted == true then
		return
	end

	if CDungeonZone.flTimeOfFirstActivation == nil then
		CDungeonZone.flTimeOfFirstActivation = GameRules:GetGameTime()
	end

	if CDungeonZone.bSpawnedSquads == false and #CDungeonZone.Squads > 0 then
		CDungeonZone:SpawnSquadCreatures(false)
	end

	--print( string.format( "CDungeonZone.bSpawnedChests == %s, #CDungeonZone.Chests == %d", tostring( CDungeonZone.bSpawnedChests ), #CDungeonZone.Chests ) )
	if CDungeonZone.bSpawnedChests == false and #CDungeonZone.Chests > 0 then
		CDungeonZone:SpawnChests()
	end

	if CDungeonZone.bSpawnedBreakables == false and CDungeonZone.Breakables and #CDungeonZone.Breakables > 0 then
		CDungeonZone:SpawnBreakables()
	end

	if CDungeonZone.bSpawnedAlliedStructures == false and CDungeonZone.AlliedStructures and #CDungeonZone.AlliedStructures > 0 then
		CDungeonZone:SpawnAlliedStructures()
	end

	--	print("CDungeonZone.bSpawnedVIPs (should be nil or false:", CDungeonZone.bSpawnedVIPs)

	if not CDungeonZone.bSpawnedVIPs then
		--		print(CDungeonZone.VIPs)
		CDungeonZone:SpawnVIPs(CDungeonZone.VIPs)
		CDungeonZone:SpawnNeutrals(CDungeonZone.Neutrals)
		CDungeonZone.bSpawnedVIPs = true
	end

	--print( "CDungeonZone:Activate - Zone " .. CDungeonZone.szName .. " is being activated" )
	GameRules.GameMode:OnZoneActivated(CDungeonZone)

	if CDungeonZone.Type == ZONE_TYPE_SURVIVAL then
		if CDungeonZone.Survival.StartQuest == nil then
			CDungeonZone:SurvivalStart()
		end
	end

	if CDungeonZone.Type == ZONE_TYPE_HOLDOUT then
		if CDungeonZone.Holdout.StartQuest == nil then
			CDungeonZone:HoldoutStart()
		end
	end

	if CDungeonZone.Type == ZONE_TYPE_ASSAULT then
		if CDungeonZone.Assault.StartQuest == nil then
			CDungeonZone:AssaultStart()
		end
	end
	CDungeonZone.bActivated = true
end

--------------------------------------------------------------------

function CDungeonZone:OnZoneActivated(zone)
	for _, quest in pairs(CDungeonZone.Quests) do
		if quest ~= nil and quest.bCompleted == false then
			if quest.bActivated == false then
				local bShouldActivate = false
				for _, activator in pairs(quest.Activators) do
					if activator ~= nil and activator.Type == QUEST_EVENT_ON_ZONE_ACTIVATE and activator.szZoneName == zone.szName then
						bShouldActivate = true
					end

					if activator.Type == QUEST_EVENT_ON_DIALOG or activator.Type == QUEST_EVENT_ON_DIALOG_ALL_CONFIRMED and zone.szName == CDungeonZone.szName then
						local hDialogEntities = FindUnitsInRadius(DOTA_TEAM_GOODGUYS, Vector(0, 0, 0), nil, FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, 0, false)
						for _, DialogEnt in pairs(hDialogEntities) do
							if DialogEnt ~= nil and DialogEnt:GetUnitName() == activator.szNPCName and DialogEnt:FindModifierByName("modifier_npc_dialog_notify") == nil then
								DialogEnt:AddNewModifier(DialogEnt, nil, "modifier_npc_dialog_notify", {})
							end
						end
					end
				end

				if bShouldActivate == true then
					GameRules.GameMode:OnQuestStarted(CDungeonZone, quest)
				end
			end

			if quest.bActivated == true and quest.Completion.Type == QUEST_EVENT_ON_ZONE_ACTIVATE and quest.Completion.szZoneName == zone.szName then
				GameRules.GameMode:OnQuestCompleted(CDungeonZone, quest)
			end
		end
	end
end

--------------------------------------------------------------------

function CDungeonZone:OnZoneEventComplete(zone)
	for _, quest in pairs(CDungeonZone.Quests) do
		if quest ~= nil and not quest.bCompleted == true then
			if quest.bActivated == false then
				local bShouldActivate = false
				for _, activator in pairs(quest.Activators) do
					if activator ~= nil and activator.Type == QUEST_EVENT_ON_ZONE_EVENT_FINISHED and activator.szZoneName == zone.szName then
						bShouldActivate = true
					end
				end
				if bShouldActivate == true then
					GameRules.GameMode:OnQuestStarted(CDungeonZone, quest)
				end
			end

			if quest.bActivated == true and quest.Completion.Type == QUEST_EVENT_ON_ZONE_EVENT_FINISHED and quest.Completion.szZoneName == zone.szName then
				GameRules.GameMode:OnQuestCompleted(CDungeonZone, quest)
			end
		end
	end
end

--------------------------------------------------------------------

function CDungeonZone:OnEnemyKilled(killedUnit, Zone)
	-- print("OnEnemyKilled", killedUnit:GetUnitName())
	for _, quest in pairs(CDungeonZone.Quests) do
		if quest ~= nil and not quest.bCompleted == true then
			if quest.bActivated == false then
				local bShouldActivate = false
				for _, activator in pairs(quest.Activators) do
					if activator ~= nil and activator.Type == QUEST_EVENT_ON_ENEMY_KILLED and activator.szNPCName == killedUnit:GetUnitName() and ((quest.Completion.szZoneName == Zone.szName) or (quest.Completion.szZoneName == nil)) and not killedUnit:IsBuilding() then
						bShouldActivate = true
					end
					if activator ~= nil and activator.Type == QUEST_EVENT_ON_TEAM_ENEMY_KILLED and activator.szTeamName == killedUnit:GetTeam() and ((quest.Completion.szZoneName == Zone.szName) or (quest.Completion.szZoneName == nil)) and not killedUnit:IsBuilding() then
						bShouldActivate = true
					end
				end

				if bShouldActivate == true then
					GameRules.GameMode:OnQuestStarted(CDungeonZone, quest)
				end
			end

			if quest.zsQuestName == "kill_grom" then
				print(quest.bActivated)
				print(quest.Completion.Type)
				print(quest)
				print(quest.Completion.szNPCName)
				print(killedUnit:GetUnitName())
			end

			if quest.bActivated == true and quest.Completion.Type == QUEST_EVENT_ON_ENEMY_KILLED and quest.Completion.szNPCName == killedUnit:GetUnitName() and ((quest.Completion.szZoneName == Zone.szName) or (quest.Completion.szZoneName == nil)) then
				GameRules.GameMode:OnQuestCompleted(CDungeonZone, quest)
			end
			if quest.bActivated == true and quest.Completion.Type == QUEST_EVENT_ON_TEAM_ENEMY_KILLED and quest.Completion.szTeamName == killedUnit:GetTeam() and ((quest.Completion.szZoneName == Zone.szName) or (quest.Completion.szZoneName == nil)) then
				GameRules.GameMode:OnQuestCompleted(CDungeonZone, quest)
			end
		end
	end
end

--------------------------------------------------------------------

function CDungeonZone:OnTreasureOpened(szZoneName)
	for _, quest in pairs(CDungeonZone.Quests) do
		if quest ~= nil and not quest.bCompleted == true then
			if quest.bActivated == false then
				local bShouldActivate = false
				for _, activator in pairs(quest.Activators) do
					if activator ~= nil and activator.Type == QUEST_EVENT_ON_TREASURE_OPENED and activator.szZoneName == szZoneName then
						bShouldActivate = true
					end
				end

				if bShouldActivate == true then
					GameRules.GameMode:OnQuestStarted(CDungeonZone, quest)
				end
			end

			if quest.bActivated == true and quest.Completion.Type == QUEST_EVENT_ON_TREASURE_OPENED and quest.Completion.szZoneName == szZoneName then
				GameRules.GameMode:OnQuestCompleted(CDungeonZone, quest)
			end
		end
	end
end

--------------------------------------------------------------------

function CDungeonZone:OnKeyItemPickedUp(szZoneName, szItemName)
	for _, quest in pairs(CDungeonZone.Quests) do
		if quest ~= nil and not quest.bCompleted == true then
			if quest.bActivated == false then
				local bShouldActivate = false
				for _, activator in pairs(quest.Activators) do
					if activator ~= nil and activator.Type == QUEST_EVENT_ON_KEY_ITEM_RECEIVED and activator.szItemName == szItemName and activator.szZoneName == szZoneName then
						bShouldActivate = true
					end
				end

				if bShouldActivate == true then
					GameRules.GameMode:OnQuestStarted(CDungeonZone, quest)
				end
			end

			if quest.bActivated == true and quest.Completion.Type == QUEST_EVENT_ON_KEY_ITEM_RECEIVED and quest.Completion.szItemName == szItemName and quest.Completion.szZoneName == szZoneName then
				GameRules.GameMode:OnQuestCompleted(CDungeonZone, quest)
			end
		end
	end
end

--------------------------------------------------------------------

function CDungeonZone:OnDialogBegin(hDialogEnt)
	for _, quest in pairs(CDungeonZone.Quests) do
		if quest ~= nil and not quest.bCompleted == true then
			if quest.bActivated == false then
				local bShouldActivate = false
				for _, activator in pairs(quest.Activators) do
					if activator ~= nil and activator.Type == QUEST_EVENT_ON_DIALOG and activator.szNPCName == hDialogEnt:GetUnitName() and hDialogEnt.nCurrentLine == activator.nDialogLine then
						bShouldActivate = true
					end
				end

				if bShouldActivate == true then
					GameRules.GameMode:OnQuestStarted(CDungeonZone, quest)
				end
			end

			if quest.bActivated == true and quest.Completion.Type == QUEST_EVENT_ON_DIALOG and quest.Completion.szNPCName == hDialogEnt:GetUnitName() and hDialogEnt.nCurrentLine == quest.Completion.nDialogLine then
				GameRules.GameMode:OnQuestCompleted(CDungeonZone, quest)
			end
		end
	end
end

--------------------------------------------------------------------

function CDungeonZone:OnDialogAllConfirmed(hDialogEnt, nDialogLine)
	for _, quest in pairs(CDungeonZone.Quests) do
		if quest ~= nil and not quest.bCompleted == true then
			if quest.bActivated == false then
				local bShouldActivate = false
				for _, activator in pairs(quest.Activators) do
					if activator ~= nil and activator.Type == QUEST_EVENT_ON_DIALOG_ALL_CONFIRMED and hDialogEnt ~= nil and activator.szNPCName == hDialogEnt:GetUnitName() and nDialogLine == activator.nDialogLine then
						bShouldActivate = true
					end
				end

				if bShouldActivate == true then
					GameRules.GameMode:OnQuestStarted(CDungeonZone, quest)
				end
			end

			if quest.bActivated == true and quest.Completion.Type == QUEST_EVENT_ON_DIALOG_ALL_CONFIRMED and hDialogEnt ~= nil and quest.Completion.szNPCName == hDialogEnt:GetUnitName() and nDialogLine == quest.Completion.nDialogLine then
				GameRules.GameMode:OnQuestCompleted(CDungeonZone, quest)
			end
		end
	end
end

--------------------------------------------------------------------

function CDungeonZone:StartQuestByName(szQuestName)
	print("Start zone by name: " .. szQuestName)
	for _, quest in pairs(CDungeonZone.Quests) do
		-- print(quest)
		if quest ~= nil and quest.szQuestName == szQuestName then
			if quest.bActivated == true then
				print("CDungeonZone:StartQuestByName - ERROR: Quest " .. szQuestName .. " has already started.")
			end
			if quest.bCompleted == true then
				print("CDungeonZone:StartQuestByName - ERROR: Quest " .. szQuestName .. " has already finished.")
			end

			GameRules.GameMode:OnQuestStarted(CDungeonZone, quest)
		end
	end
end

--------------------------------------------------------------------

function CDungeonZone:IsQuestActive(szQuestName)
	for _, quest in pairs(CDungeonZone.Quests) do
		if quest ~= nil and quest.szQuestName == szQuestName then
			if quest.bActivated == true and quest.bCompleted == false then
				return true
			end
		end
	end

	return false
end

--------------------------------------------------------------------

function CDungeonZone:IsQuestComplete(szQuestName)
	for _, quest in pairs(CDungeonZone.Quests) do
		if quest ~= nil and quest.szQuestName == szQuestName then
			if quest.bCompleted == true then
				return true
			end
		end
	end

	return false
end

--------------------------------------------------------------------

function CDungeonZone:GetQuestCompleteCount(szQuestName)
	for _, quest in pairs(CDungeonZone.Quests) do
		if quest ~= nil and quest.szQuestName == szQuestName then
			return quest.nCompleted
		end
	end

	return -1
end

--------------------------------------------------------------------

function CDungeonZone:OnQuestStarted(quest)
	for _, zoneQuest in pairs(CDungeonZone.Quests) do
		if zoneQuest ~= nil and not zoneQuest.bCompleted == true then
			if zoneQuest.bActivated == false then
				local bShouldActivate = false
				for _, activator in pairs(zoneQuest.Activators) do
					if activator ~= nil and activator.Type == QUEST_EVENT_ON_QUEST_ACTIVATE and activator.szQuestName == quest.szQuestName then
						bShouldActivate = true
					end
				end

				if bShouldActivate == true then
					GameRules.GameMode:OnQuestStarted(CDungeonZone, zoneQuest)
				end
			end

			if zoneQuest.bActivated == true and zoneQuest.Completion.Type == QUEST_EVENT_ON_QUEST_ACTIVATE and zoneQuest.Completion.szQuestName == quest.szQuestName then
				GameRules.GameMode:OnQuestCompleted(CDungeonZone, zoneQuest)
			end
		end
	end

	for _, vip in pairs(CDungeonZone.VIPsAlive) do
		local Dialog = GameRules.GameMode:GetDialog(vip)
		if Dialog ~= nil and Dialog.szAdvanceQuestActive == quest.szQuestName then
			--print( "Dialog.szAdvanceQuestActive == " .. Dialog.szAdvanceQuestActive )
			vip.nCurrentLine = vip.nCurrentLine + 1
			vip:AddNewModifier(vip, nil, "modifier_npc_dialog_notify", {})
		end
	end

	if CDungeonZone.Type == ZONE_TYPE_SURVIVAL then
		if CDungeonZone.Survival.StartQuest ~= nil and CDungeonZone.Survival.StartQuest.bOnCompleted == false then
			if quest.szQuestName == CDungeonZone.Survival.StartQuest.szQuestName then
				--	print( "CDungeonZone:OnQuestStarted() - Survival in " .. CDungeonZone.szName .. " starting because quest " .. quest.szQuestName .. " started." )
				CDungeonZone:SurvivalStart()
				return
			end
		end
	end

	if CDungeonZone.Type == ZONE_TYPE_HOLDOUT then
		if CDungeonZone.Holdout.StartQuest ~= nil and CDungeonZone.Holdout.StartQuest.bOnCompleted == false then
			if quest.szQuestName == CDungeonZone.Holdout.StartQuest.szQuestName then
				--	print( "CDungeonZone:OnQuestStarted() - Holdout in " .. CDungeonZone.szName .. " starting because quest " .. quest.szQuestName .. " started." )
				CDungeonZone:HoldoutStart()
				return
			end
		end
	end

	if CDungeonZone.Type == ZONE_TYPE_ASSAULT then
		if CDungeonZone.Assault.StartQuest ~= nil and CDungeonZone.Assault.StartQuest.bOnCompleted == false then
			if quest.szQuestName == CDungeonZone.Assault.StartQuest.szQuestName then
				--	print( "CDungeonZone:OnQuestStarted() - Assault in " .. CDungeonZone.szName .. " starting because quest " .. quest.szQuestName .. " started." )
				CDungeonZone:AssaultStart()
				return
			end
		end
	end
end

--------------------------------------------------------------------

function CDungeonZone:OnQuestCompleted(quest)
	for _, zoneQuest in pairs(CDungeonZone.Quests) do
		if zoneQuest ~= nil and not zoneQuest.bCompleted == true then
			if zoneQuest.bActivated == false then
				local bShouldActivate = false
				for _, activator in pairs(zoneQuest.Activators) do
					if activator ~= nil and activator.Type == QUEST_EVENT_ON_QUEST_COMPLETE and activator.szQuestName == quest.szQuestName then
						bShouldActivate = true
					end
				end

				if bShouldActivate == true then
					GameRules.GameMode:OnQuestStarted(CDungeonZone, zoneQuest)
				end
			end

			if zoneQuest.bActivated == true and zoneQuest.Completion.Type == QUEST_EVENT_ON_QUEST_COMPLETE and zoneQuest.Completion.szQuestName == quest.szQuestName then
				GameRules.GameMode:OnQuestCompleted(CDungeonZone, zoneQuest)
			end
		end
	end

	if CDungeonZone.Type == ZONE_TYPE_SURVIVAL then
		if CDungeonZone.Survival.StartQuest ~= nil and CDungeonZone.Survival.StartQuest.bOnCompleted == true then
			if quest.szQuestName == CDungeonZone.Survival.StartQuest.szQuestName then
				--	print( "CDungeonZone:OnQuestStarted() - Survival in " .. CDungeonZone.szName .. " starting because quest " .. quest.szQuestName .. " was completed." )
				CDungeonZone:SurvivalStart()
			end
		end
	end

	if CDungeonZone.Type == ZONE_TYPE_HOLDOUT then
		if CDungeonZone.Holdout.StartQuest ~= nil and CDungeonZone.Holdout.StartQuest.bOnCompleted == true then
			if quest.szQuestName == CDungeonZone.Holdout.StartQuest.szQuestName then
				--	print( "CDungeonZone:OnQuestStarted() - Holdout in " .. CDungeonZone.szName .. " starting because quest " .. quest.szQuestName .. " was completed." )
				CDungeonZone:HoldoutStart()
			end
		end
	end

	if CDungeonZone.Type == ZONE_TYPE_ASSAULT then
		if CDungeonZone.Assault.StartQuest ~= nil and CDungeonZone.Assault.StartQuest.bOnCompleted == false then
			if quest.szQuestName == CDungeonZone.Assault.StartQuest.szQuestName then
				--	print( "CDungeonZone:OnQuestStarted() - Assault in " .. CDungeonZone.szName .. " starting because quest " .. quest.szQuestName .. " started." )
				CDungeonZone:AssaultStart()
				return
			end
		end
	end
end

--------------------------------------------------------------------

function CDungeonZone:Deactivate()
	if CDungeonZone.bActivated == false then
		return
	end

	if CDungeonZone.Type == ZONE_TYPE_HOLDOUT and CDungeonZone.Holdout.bStarted == true and CDungeonZone.bZoneCompleted == false then
		return
	end

	if CDungeonZone.Type == ZONE_TYPE_ASSAULT and CDungeonZone.Assault.bStarted == true and CDungeonZone.bZoneCompleted == false then
		return
	end

	--print( "CDungeonZone:Deactivate() - Zone " .. CDungeonZone.szName .. " is being deactivated." )

	CDungeonZone.bActivated = false

	CustomGameEventManager:Send_ServerToAllClients("remove_vips", netTable)
end

--------------------------------------------------------------------

function CDungeonZone:OnThink()
	if CDungeonZone.bPrecached == false then
		return
	else
		if #CDungeonZone.SpawnGroups >= CDungeonZone.nPrecacheCount then
			if CDungeonZone.nPrecacheCount ~= 0 then
				CDungeonZone:SpawnSquadCreatures(true)
			end
		end
	end

	if GameRules:IsGamePaused() then
		return
	end

	if CDungeonZone:HasAnyPlayers() == true then
		if CDungeonZone.bActivated == false then
			CDungeonZone:Activate()
			return
		end
	else
		if CDungeonZone.bActivated == true then
			CDungeonZone:Deactivate()
			return
		end
		if CDungeonZone.bZoneCompleted == true and CDungeonZone.bZoneCleanupComplete == false and (GameRules:GetGameTime() > CDungeonZone.flZoneCleanupTime) then
			CDungeonZone:PerformZoneCleanup()
			return
		end
	end

	if CDungeonZone.bActivated == false then
		local Heroes = HeroList:GetAllHeroes()
		for _, enemy in pairs(CDungeonZone.Enemies) do
			if enemy ~= nil and not enemy:IsNull() and enemy:IsAlive() and enemy.bAttacker == true then
				local bCanBeSeen = false
				local Heroes = HeroList:GetAllHeroes()
				for _, Hero in pairs(Heroes) do
					if Hero:CanEntityBeSeenByMyTeam(enemy) then
						bCanBeSeen = true
					end
				end

				if not bCanBeSeen then
					enemy:Kill(nil, nil)
				end
			end
		end
		return
	end

	if #CDungeonZone.Bosses > 0 then
		CDungeonZone:BossThink()
	end

	CDungeonZone.flCompletionTime = CDungeonZone.flCompletionTime + 1.0
	CDungeonZone.PlayerStats["CompletionTime"] = CDungeonZone.flCompletionTime
	CDungeonZone.PlayerStats["ZoneStars"] = CDungeonZone.nStars
	CustomNetTables:SetTableValue("zone_scores", CDungeonZone.szName, CDungeonZone.PlayerStats)

	CDungeonZone:CheckForZoneComplete()
end

--------------------------------------------------------------------

function CDungeonZone:CheckForZoneComplete()
	if CDungeonZone:AllQuestsComplete() == false then
		if CDungeonZone.Type == ZONE_TYPE_SURVIVAL then
			CDungeonZone:SurvivalThink()
			return
		end

		if CDungeonZone.Type == ZONE_TYPE_HOLDOUT then
			CDungeonZone:HoldoutThink()
			return
		end

		if CDungeonZone.Type == ZONE_TYPE_ASSAULT then
			CDungeonZone:AssaultThink()
			return
		end
	elseif CDungeonZone.bZoneCompleted == false then
		--print( "CDungeonZone:CheckForZoneComplete() - Zone " .. CDungeonZone.szName .. " completed in " .. CDungeonZone.flCompletionTime .. " seconds." )
		CDungeonZone.bZoneCompleted = true

		if not CDungeonZone.bNoLeaderboard then
			for nPlayerID = 0, 3 do
				if CDungeonZone.PlayerStats[nPlayerID] ~= nil then
					if CDungeonZone.PlayerStats[nPlayerID]["Kills"] ~= nil then CDungeonZone.nKills = CDungeonZone.nKills + CDungeonZone.PlayerStats[nPlayerID]["Kills"] end
					if CDungeonZone.PlayerStats[nPlayerID]["Items"] ~= nil then CDungeonZone.nItems = CDungeonZone.nItems + CDungeonZone.PlayerStats[nPlayerID]["Items"] end
					if CDungeonZone.PlayerStats[nPlayerID]["GoldBags"] ~= nil then CDungeonZone.nGoldBags = CDungeonZone.nGoldBags + CDungeonZone.PlayerStats[nPlayerID]["GoldBags"] end
					if CDungeonZone.PlayerStats[nPlayerID]["Potions"] ~= nil then CDungeonZone.nPotions = CDungeonZone.nPotions + CDungeonZone.PlayerStats[nPlayerID]["Potions"] end
					if CDungeonZone.PlayerStats[nPlayerID]["ReviveTime"] ~= nil then CDungeonZone.nReviveTime = CDungeonZone.nReviveTime + CDungeonZone.PlayerStats[nPlayerID]["ReviveTime"] end
					if CDungeonZone.PlayerStats[nPlayerID]["Damage"] ~= nil then CDungeonZone.nDamage = CDungeonZone.nDamage + CDungeonZone.PlayerStats[nPlayerID]["Damage"] end
					if CDungeonZone.PlayerStats[nPlayerID]["Healing"] ~= nil then CDungeonZone.nHealing = CDungeonZone.nHealing + CDungeonZone.PlayerStats[nPlayerID]["Healing"] end
					if CDungeonZone.PlayerStats[nPlayerID]["Deaths"] ~= nil then
						CDungeonZone.nDeaths = CDungeonZone.nDeaths + CDungeonZone.PlayerStats[nPlayerID]["Deaths"]
					else
						CDungeonZone.PlayerStats[nPlayerID]["Deaths"] = 0
					end
				end
			end
			if CDungeonZone.StarCriteria ~= nil then
				for _, Criteria in pairs(CDungeonZone.StarCriteria) do
					if Criteria ~= nil then
						Criteria.StarScore = 0
						Criteria.Result = 0
						if Criteria.Type == ZONE_STAR_CRITERIA_TIME then
							if Criteria.Values == nil then
								print("CDungeonZone:CheckForZoneComplete - ERROR: StarCriteria for ZONE_STAR_CRITERIA_TIME has malformed values!")
							end
							Criteria.Result = CDungeonZone.flCompletionTime
							for i = 1, #Criteria.Values do
								local time = Criteria.Values[i]
								if time ~= nil and time >= Criteria.Result then
									if i > Criteria.StarScore then
										Criteria.StarScore = i
									end
								end
							end
							print("CDungeonZone:CheckForZoneComplete - Score for ZONE_STAR_CRITERIA_TIME is " .. Criteria.StarScore .. " with a value of " .. Criteria.Result)
						end

						if Criteria.Type == ZONE_STAR_CRITERIA_DEATHS then
							if Criteria.Values == nil then
								print("CDungeonZone:CheckForZoneComplete - ERROR: StarCriteria for ZONE_STAR_CRITERIA_DEATHS has malformed values!")
							end

							Criteria.Result = CDungeonZone.nDeaths

							for i = 1, #Criteria.Values do
								local deaths = Criteria.Values[i]
								if deaths ~= nil and deaths >= Criteria.Result then
									if i > Criteria.StarScore then
										Criteria.StarScore = i
									end
								end
							end
							print("CDungeonZone:CheckForZoneComplete - Score for ZONE_STAR_CRITERIA_DEATHS is " .. Criteria.StarScore .. " with a value of " .. Criteria.Result)
						end

						if Criteria.Type == ZONE_STAR_CRITERIA_QUEST_COMPLETE then
							Criteria.Result = CDungeonZone:GetQuestCompleteCount(Criteria.szQuestName)
							if Criteria.szQuestName == nil or nCompleteCount then
								print("CDungeonZone:CheckForZoneComplete - ERROR: StarCriteria for ZONE_STAR_CRITERIA_QUEST_COMPLETE has invalid quest name!")
							end
							if Criteria.Values == nil then
								print("CDungeonZone:CheckForZoneComplete - ERROR: StarCriteria for ZONE_STAR_CRITERIA_QUEST_COMPLETE has malformed values!")
							end
							for i = 1, #Criteria.Values do
								local completed = Criteria.Values[i]
								if completed ~= nil and completed <= Criteria.Result then
									if i > Criteria.StarScore then
										Criteria.StarScore = i
									end
								end
							end
							print("CDungeonZone:CheckForZoneComplete - Score for ZONE_STAR_CRITERIA_QUEST_COMPLETE is " .. Criteria.StarScore .. " with a value of " .. Criteria.Result)
						end
					end
				end
				CDungeonZone.nStars = 9999
				for _, Criteria in pairs(CDungeonZone.StarCriteria) do
					if Criteria ~= nil and Criteria.StarScore ~= nil and Criteria.StarScore < CDungeonZone.nStars then
						CDungeonZone.nStars = Criteria.StarScore
					end
				end
			end

			-- local nData1 = bit.bor( bit.lshift( CDungeonZone.nKills, 16 ), bit.band(CDungeonZone.nDeaths, 0xFFFF ) )
			-- local nData2 = bit.bor( bit.lshift( CDungeonZone.nGoldBags, 16 ), bit.band(CDungeonZone.nPotions, 0xFFFF ) )
			-- local nData3 = bit.bor( bit.lshift( CDungeonZone.nItems, 16 ), bit.band(CDungeonZone.nReviveTime, 0xFFFF ) )
			-- local nData4 = bit.bor( bit.lshift( CDungeonZone.nDamage / 1000, 16 ), bit.band(CDungeonZone.nHealing / 1000, 0xFFFF ) )
			-- local nData5 = bit.lshift( CDungeonZone.PlayerStats[0]["Deaths"], 24 ) + bit.lshift( CDungeonZone.PlayerStats[1]["Deaths"], 16 ) + bit.lshift( CDungeonZone.PlayerStats[2]["Deaths"], 8 ) + CDungeonZone.PlayerStats[3]["Deaths"]

			-- GameRules:AddEventMetadataLeaderboardEntry( CDungeonZone.szName, math.ceil( CDungeonZone.flCompletionTime ), CDungeonZone.nStars, 3, nData1, nData2, nData3, nData4, nData5 )

			local nFurthestZone = 0
			local nTotalTime = 0
			local nTotalStars = 0
			local nMaxTotalStars = 0
			local nTotalKills = 0
			local nTotalDeaths = 0
			local nTotalItems = 0
			local nTotalGoldBags = 0
			local nTotalPotions = 0
			local nTotalDeaths = 0
			local nTotalReviveTime = 0
			local nTotalDamage = 0
			local nTotalHealing = 0
			local nTotalPlayerDeaths = {}
			for nPlayerID = 0, 3 do
				nTotalPlayerDeaths[nPlayerID] = 0
			end

			print("CDungeonZone:Totaling scores")

			for zone_num, zone in pairs(GameRules.GameMode.Zones) do
				if not zone.bNoLeaderboard then
					if zone.bZoneCompleted then
						nTotalTime = nTotalTime + math.ceil(zone.flCompletionTime)
						nTotalStars = nTotalStars + zone.nStars
						if zone_num > nFurthestZone then
							nFurthestZone = zone_num
						end
						nTotalKills = nTotalKills + zone.nKills
						nTotalDeaths = nTotalDeaths + zone.nDeaths
						nTotalItems = nTotalItems + zone.nItems
						nTotalGoldBags = nTotalGoldBags + zone.nGoldBags
						nTotalPotions = nTotalPotions + zone.nPotions
						nTotalReviveTime = nTotalReviveTime + zone.nReviveTime
						nTotalDamage = nTotalDamage + zone.nDamage
						nTotalHealing = nTotalHealing + zone.nHealing
						for nPlayerID = 0, 3 do
							nTotalPlayerDeaths[nPlayerID] = nTotalPlayerDeaths[nPlayerID] + (zone.PlayerStats[nPlayerID]["Deaths"] or 0)
						end
					end

					nMaxTotalStars = nMaxTotalStars + 3

					print("CDungeonZone:Totaling - through zone " .. zone.szName .. ", stars: " .. nTotalStars)
				end
			end

			local nTotalData1 = bit.lshift(nTotalKills, 16) + bit.lshift(nFurthestZone - 1, 8) + bit.band(nTotalDeaths, 0xFF)
			local nTotalData2 = bit.lshift(nTotalGoldBags, 16) + bit.band(nTotalPotions, 0xFFFF)
			local nTotalData3 = bit.lshift(nTotalItems, 16) + bit.band(nTotalReviveTime, 0xFFFF)
			local nTotalData4 = bit.lshift(nTotalDamage / 1000000, 16) + bit.band(nTotalHealing / 1000000, 0xFFFF)
			local nTotalData5 = bit.lshift(nTotalPlayerDeaths[0], 24) + bit.lshift(nTotalPlayerDeaths[1], 16) + bit.lshift(nTotalPlayerDeaths[2], 8) + nTotalPlayerDeaths[3]

			GameRules:AddEventMetadataLeaderboardEntry("total", nTotalTime, nTotalStars, nMaxTotalStars, nTotalData1, nTotalData2, nTotalData3, nTotalData4, nTotalData5)
		end

		GameRules.GameMode:OnZoneCompleted(CDungeonZone)

		local netTable = {}
		netTable["CompletionTime"] = CDungeonZone.flCompletionTime
		netTable["ZoneName"] = CDungeonZone.szName
		netTable["ZoneStars"] = CDungeonZone.nStars
		CDungeonZone.flZoneCleanupTime = GameRules:GetGameTime() + 180.0
		if not CDungeonZone.bNoLeaderboard then
			CustomGameEventManager:Send_ServerToAllClients("zone_complete", netTable)
		end

		CDungeonZone.PlayerStats["CompletionTime"] = CDungeonZone.flCompletionTime
		CDungeonZone.PlayerStats["ZoneStars"] = CDungeonZone.nStars
		CustomNetTables:SetTableValue("zone_scores", CDungeonZone.szName, CDungeonZone.PlayerStats)

		for _, neutral in pairs(CDungeonZone.NeutralsAlive) do
			neutral:AddNewModifier(neutral, nil, "modifier_npc_dialog", {})
		end

		if CDungeonZone.bVictoryOnComplete == true then
			GameRules.GameMode.flVictoryTime = GameRules:GetGameTime() + 0.0
		end

		CDungeonZone:Deactivate()
	end
end

--------------------------------------------------------------------

function CDungeonZone:PerformZoneCleanup()
	if #CDungeonZone.Enemies > 0 then
		--print( "CDungeonZone:PerformZoneCleanup() - There are " .. #CDungeonZone.Enemies .. " enemies remaining in " .. CDungeonZone.szName )
		local Heroes = HeroList:GetAllHeroes()
		local nEnemiesRemoved = 0
		for i = #CDungeonZone.Enemies, 1, -1 do
			local enemy = CDungeonZone.Enemies[i]
			if enemy ~= nil and enemy:IsNull() == false then
				local bCanBeSeen = false
				for _, Hero in pairs(Heroes) do
					if Hero:CanEntityBeSeenByMyTeam(enemy) then
						bCanBeSeen = true
					end
				end
				if not bCanBeSeen then
					UTIL_Remove(enemy)
					table.remove(CDungeonZone.Enemies, i)
					nEnemiesRemoved = nEnemiesRemoved + 1
				end
			end
		end
		--	print( "CDungeonZone:PerformZoneCleanup() - Removed " .. nEnemiesRemoved.. " enemies from " .. CDungeonZone.szName  )
	else
		--	print( "CDungeonZone:PerformZoneCleanup() - Unloading " .. #CDungeonZone.SpawnGroups .. " spawn groups from " .. CDungeonZone.szName  )
		for _, SpawnGroup in pairs(CDungeonZone.SpawnGroups) do
			if SpawnGroup ~= nil then
				UnloadSpawnGroupByHandle(SpawnGroup)
			end
		end
		CDungeonZone.bZoneCleanupComplete = true
	end
end

--------------------------------------------------------------------

function CDungeonZone:HasAnyPlayers()
	if CDungeonZone.hZoneTrigger == nil then
		print("CDungeonZone:HasAnyPlayers() - ERROR: No Zone Volume")
		return false
	end

	local Heroes = HeroList:GetAllHeroes()
	if #Heroes == 0 then
		print("CDungeonZone:HasAnyPlayers() - ERROR: No Heroes")
		return
	end

	for _, hero in pairs(Heroes) do
		if CDungeonZone:ContainsUnit(hero) then
			return true
		end
	end

	return false
end

--------------------------------------------------------------------

function CDungeonZone:ContainsUnit(hUnit)
	if CDungeonZone.hZoneTrigger == nil or CDungeonZone.bZoneCompleted == true then
		return false
	end

	return CDungeonZone.hZoneTrigger:IsTouching(hUnit)
end

--------------------------------------------------------------------

function CDungeonZone:OnBossStart(hBoss)
	if hBoss == nil then
		print("CDungeonZone:OnBossStart - ERROR: Boss Start with invalid boss")
		return
	end

	if hBoss.bStarted == true then
		print("CDungeonZone:OnBossStart - ERROR: Boss already started")
		return
	end

	GameRules.GameMode:OnBossFightIntro(hBoss)
end

--------------------------------------------------------------------

function CDungeonZone:BossThink()
	--print( "CDungeonZone:BossThink()" )
	local Heroes = HeroList:GetAllHeroes()
	local nBossesIntroComplete = 0
	local nTotalBossHPPct = 0
	for _, Boss in pairs(CDungeonZone.Bosses) do
		if Boss.bAwake == nil or Boss.bAwake == true then
			--print( "CDungeonZone:BossThink() - Boss is awake" )
			if Boss.bStarted == false then
				--print( "CDungeonZone:BossThink() - Boss has not started" )
				for _, Hero in pairs(Heroes) do
					if Hero ~= nil and Hero:GetTeamNumber() == DOTA_TEAM_GOODGUYS and Hero:CanEntityBeSeenByMyTeam(Boss) then
						--	print( "CDungeonZone:BossThink() - Starting Boss" )
						CDungeonZone:OnBossStart(Boss)
						return
					end
				end
			else
				--print( "CDungeonZone:BossThink() - Boss has started" )
				if Boss.bStarted == true and GameRules:GetGameTime() > Boss.flIntroEndTime and Boss.bIntroComplete == false then
					Boss.bIntroComplete = true
					GameRules.GameMode:OnBossFightIntroEnd(Boss)
					return
				end
			end

			if Boss.bIntroComplete == true then
				nBossesIntroComplete = nBossesIntroComplete + 1
				if Boss:IsAlive() then
					local bCanBeSeen = false
					for _, Hero in pairs(Heroes) do
						if Hero:CanEntityBeSeenByMyTeam(Boss) and Hero:IsAlive() then
							bCanBeSeen = true
							if Boss:FindModifierByName("modifier_provide_vision") == nil then
								Boss:AddNewModifier(Hero, nil, "modifier_provide_vision", {})
							end
						end
					end
					if bCanBeSeen then
						nTotalBossHPPct = nTotalBossHPPct + Boss:GetHealthPercent()
					else
						Boss:RemoveModifierByName("modifier_provide_vision")
					end
				end
			end
		end
	end

	if CDungeonZone:GetNumberOfBosses() == nBossesIntroComplete and nBossesIntroComplete ~= 0 then
		local netTable = {}
		netTable["boss_hp"] = nTotalBossHPPct / (100 * CDungeonZone:GetNumberOfBosses()) * 100
		CustomNetTables:SetTableValue("boss", string.format("%d", 0), netTable)
	end
end

--------------------------------------------------------------------

function CDungeonZone:SurvivalStart()
	--print( "CDungeonZone:SurvivalStart()" )

	CDungeonZone.Survival.bStarted = true

	if not CDungeonZone.Survival.flSpawnInterval then
		CDungeonZone.Survival.flSpawnInterval = CDungeonZone.Survival.flMaxSpawnInterval or 60.0
		if CDungeonZone.Survival.flMaxSpawnInterval == nil then
			CDungeonZone.Survival.flMaxSpawnInterval = 60.0
			print("CDungeonZone:SurvivalStart - WARNING: No flMaxSpawnInterval defined.  Using default of " .. CDungeonZone.Survival.flMaxSpawnInterval .. " instead.")
		end
		if CDungeonZone.Survival.flMinSpawnInterval == nil then
			CDungeonZone.Survival.flMinSpawnInterval = 30.0
			print("CDungeonZone:SurvivalStart - WARNING: No flMinSpawnInterval defined.  Using default of " .. CDungeonZone.Survival.flMinSpawnInterval .. " instead.")
		end
		if CDungeonZone.Survival.flSpawnIntervalChange == nil then
			CDungeonZone.Survival.flSpawnIntervalChange = 5.0
			print("CDungeonZone:SurvivalStart - WARNING: No flSpawnIntervalChange defined.  Using default of " .. CDungeonZone.Survival.flSpawnIntervalChange .. " instead.")
		end
	end

	--print( "CDungeonZone:SurvivalStart() - " .. ConvertToTime( GameRules:GetGameTime() ) .. " - Spawning creeps in " .. CDungeonZone.Survival.flSpawnInterval .. " seconds." )
	CDungeonZone.Survival.flTimeOfNextAttack = GameRules:GetGameTime() + CDungeonZone.Survival.flSpawnInterval
end

--------------------------------------------------------------------

function CDungeonZone:SurvivalThink()
	if CDungeonZone.Survival.bStarted == false then
		return
	end

	local flTimeNow = GameRules:GetGameTime()
	if flTimeNow > CDungeonZone.Survival.flTimeOfNextAttack then
		CDungeonZone:SpawnSurvivalAttackers()
		local flNewInterval = math.max(CDungeonZone.Survival.flMinSpawnInterval, CDungeonZone.Survival.flSpawnInterval - CDungeonZone.Survival.flSpawnIntervalChange)
		--print( "CDungeonZone:SurvivalThink() - " .. ConvertToTime( flTimeNow ) .. " - Previous interval: " .. CDungeonZone.Survival.flSpawnInterval .. ", new interval:" .. flNewInterval )
		CDungeonZone.Survival.flSpawnInterval = flNewInterval
		--print( "CDungeonZone:SurvivalThink() - " .. ConvertToTime( flTimeNow ) .. " - Spawning creeps in " .. CDungeonZone.Survival.flSpawnInterval .. " seconds." )
		CDungeonZone.Survival.flTimeOfNextAttack = flTimeNow + CDungeonZone.Survival.flSpawnInterval
	end
end

--------------------------------------------------------------------

function CDungeonZone:SpawnSurvivalAttackers()
	--print( "-----------------------------------" )
	--print( "CDungeonZone:SpawnSurvivalAttackers()" )

	CDungeonZone:SpawnChasingSquads(CDungeonZone.Survival.nSquadsPerSpawn, DOTA_TEAM_BADGUYS, CDungeonZone.Survival.ChasingSquads, CDungeonZone.Survival.ChasingSpawners, CDungeonZone.Squads, CDungeonZone.Survival.bDontRepeatSquads)
end

--------------------------------------------------------------------

function CDungeonZone:HoldoutStart()
	--print( "CDungeonZone:HoldoutStart()" )
	if CDungeonZone.bActivated == false then
		CDungeonZone:Activate()
	end
	CDungeonZone.Holdout.bStarted = true
	CDungeonZone.Holdout.nLastReportedCount = 0
	CDungeonZone.flTimeOfNextWave = GameRules:GetGameTime()

	local netTable = {}
	for index, VIP in pairs(CDungeonZone.VIPsAlive) do
		netTable[index] = VIP:entindex()
		VIP:RemoveModifierByName("modifier_stack_count_animation_controller")
	end
	for _, neutral in pairs(CDungeonZone.NeutralsAlive) do
		if neutral ~= nil and neutral:IsNull() == false and neutral:FindAbilityByName("ability_journal_note") == nil then
			neutral:RemoveModifierByName("modifier_stack_count_animation_controller")
			neutral:RemoveModifierByName("modifier_npc_dialog")
		end
	end
	CustomNetTables:SetTableValue("vips", string.format("%d", 0), netTable)
end

--------------------------------------------------------------------

function CDungeonZone:HoldoutThink()
	if CDungeonZone.Holdout.bCompleted == true or CDungeonZone.Holdout.bStarted == false then
		return
	end

	for index, VIP in pairs(CDungeonZone.VIPsAlive) do
		if VIP:IsNull() or VIP:IsAlive() == false then
			--print( "vip died" )
			CDungeonZone.nVIPsKilled = CDungeonZone.nVIPsKilled + 1
			table.remove(CDungeonZone.VIPsAlive, index)

			if CDungeonZone.nVIPsKilled > CDungeonZone.nVIPDeathsAllowed then
				GameRules.GameMode:OnGameFinished()
				GameRules:MakeTeamLose(DOTA_TEAM_GOODGUYS)
			end

			return
		end

		if IsInToolsMode() then
			print(VIP:GetUnitName())
			for _, parent_modifier in pairs(VIP:FindAllModifiers()) do
				print(parent_modifier:GetName())
			end
		end
	end

	for index2, neutral in pairs(CDungeonZone.NeutralsAlive) do
		if neutral:IsNull() or neutral:IsAlive() == false then
			--print( "vip died" )
			table.remove(CDungeonZone.NeutralsAlive, index2)
		end
	end

	local nTotalEnemiesRemaining = #CDungeonZone.Enemies
	local nEnemiesRemainingToSpawn = 0
	if CDungeonZone.nCurrentWave > 0 then
		local NPCs = CDungeonZone.Waves[CDungeonZone.nCurrentWave].NPCs
		if NPCs ~= nil then
			for _, npc in pairs(NPCs) do
				if npc.flDelay ~= nil then
					nEnemiesRemainingToSpawn = nEnemiesRemainingToSpawn + 1
				end
			end
		end
	end

	nTotalEnemiesRemaining = nTotalEnemiesRemaining + nEnemiesRemainingToSpawn
	if CDungeonZone.Holdout.nLastReportedCount ~= nTotalEnemiesRemaining then
		--	print( "CDungeonZone:HoldoutThink() - There are " .. nTotalEnemiesRemaining .. " enemies remaining in holdout event." )
		CDungeonZone.Holdout.nLastReportedCount = nTotalEnemiesRemaining
	end
	if nEnemiesRemainingToSpawn > 0 then
		--	print( "CDungeonZone:HoldoutThink() - There are " .. nEnemiesRemainingToSpawn .. " enemies delayed in holdout event." )
	end

	local flTimeNow = GameRules:GetGameTime()
	if flTimeNow > CDungeonZone.flTimeOfNextWave and CDungeonZone.nCurrentWave < #CDungeonZone.Waves then
		CDungeonZone.nCurrentWave = CDungeonZone.nCurrentWave + 1
		--	print( "CDungeonZone:HoldoutThink() - Wave Start - " .. CDungeonZone.nCurrentWave )
		CDungeonZone:SpawnPathingSquads(CDungeonZone.Waves[CDungeonZone.nCurrentWave], DOTA_TEAM_BADGUYS)

		CDungeonZone.flTimeOfNextSpawn = flTimeNow + CDungeonZone.Waves[CDungeonZone.nCurrentWave].flSpawnInterval
		CDungeonZone.flTimeOfNextWave = flTimeNow + CDungeonZone.Waves[CDungeonZone.nCurrentWave].flDuration
		--	print( "CDungeonZone:HoldoutThink() - Next Wave at " .. ConvertToTime( CDungeonZone.flTimeOfNextWave ) )
		--	print( "CDungeonZone:HoldoutThink() - Next Spawn at " .. ConvertToTime( CDungeonZone.flTimeOfNextSpawn ) )
	else
		if CDungeonZone.nCurrentWave == 0 then
			return
		end

		if flTimeNow > CDungeonZone.flTimeOfNextSpawn then
			CDungeonZone:SpawnPathingSquads(CDungeonZone.Waves[CDungeonZone.nCurrentWave], DOTA_TEAM_BADGUYS)
			CDungeonZone.flTimeOfNextSpawn = flTimeNow + CDungeonZone.Waves[CDungeonZone.nCurrentWave].flSpawnInterval
			--		print( "CDungeonZone:HoldoutThink() - Next Spawn at " .. ConvertToTime( CDungeonZone.flTimeOfNextSpawn ) )
		end
	end

	if CDungeonZone.nCurrentWave == #CDungeonZone.Waves then
		--	print( "CDungeonZone:HoldoutThink() - All Waves Completed" )	
		if nTotalEnemiesRemaining == 0 then
			--		print( "CDungeonZone:HoldoutThink() - Holdout Event Completed" )	
			CDungeonZone.Holdout.bCompleted = true
			GameRules.GameMode:OnZoneEventComplete(CDungeonZone)
		else
			--		print( "CDungeonZone:HoldoutThink() - Holdout Event has " .. nEnemiesRemainingToSpawn .. " enemies waiting to spawn." )	
		end
	end
end

--------------------------------------------------------------------

function CDungeonZone:AssaultStart()
	--print( "CDungeonZone:AssaultStart()" )
	if CDungeonZone.bActivated == false then
		CDungeonZone:Activate()
	end
	CDungeonZone.Assault.bStarted = true
	for _, Attacker in pairs(CDungeonZone.Assault.Attackers) do
		if Attacker ~= nil then
			Attacker.flTimeOfNextSpawn = GameRules:GetGameTime()
		end
	end
	CDungeonZone.Assault.RescuedAttackers = {}
	local hRescuedAttackerEntity = Entities:FindByName(nil, CDungeonZone.Assault.szRescuedAttackerStartEntity)
	if hRescuedAttackerEntity ~= nil then
		local hRescuedEntities = FindUnitsInRadius(CDungeonZone.Assault.nAttackerTeam, hRescuedAttackerEntity:GetAbsOrigin(), hRescuedAttackerEntity, 2500, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, 0, false)
		for _, RescuedEntity in pairs(hRescuedEntities) do
			for _, szRescuedName in pairs(CDungeonZone.Assault.szRescuedAttackerTypes) do
				if RescuedEntity:GetUnitName() == szRescuedName then
					--			print( "CDungeonZone:AssaultStart() - Adding " .. szRescuedName .. " to Assault attackers." )
					if RescuedEntity:GetUnitName() == "npc_dota_creature_friendly_ogre_tank" or RescuedEntity:GetUnitName() == "npc_dota_radiant_captain" then
						local hWaypoint = Entities:FindByName(nil, CDungeonZone.Assault.szRescuedAttackerWaypoint)
						if hWaypoint == nil then
							print("CDungeonZone:AssaultThink() - ERROR: Rescued waypoint is nil.")
						end

						--				print( "CDungeonZone:AssaultThink() - Issuing order to " .. RescuedEntity:GetUnitName() )
						RescuedEntity:SetInitialGoalEntity(hWaypoint)
						RescuedEntity:RemoveModifierByName("modifier_npc_dialog")
						RescuedEntity:RemoveModifierByName("modifier_npc_dialog_notify")
						RescuedEntity:RemoveModifierByName("modifier_stack_count_animation_controller")
					else
						table.insert(CDungeonZone.Assault.RescuedAttackers, RescuedEntity)
					end
				end
			end
		end
	end

	CDungeonZone.Assault.Defenders.flTimeOfNextSpawn = GameRules:GetGameTime()
end

--------------------------------------------------------------------

function CDungeonZone:AssaultThink()
	if CDungeonZone.Assault.bCompleted == true or CDungeonZone.Assault.bStarted == false then
		return
	end

	local flTimeNow = GameRules:GetGameTime()
	for _, Attacker in pairs(CDungeonZone.Assault.Attackers) do
		if Attacker ~= nil then
			if flTimeNow >= Attacker.flTimeOfNextSpawn then
				CDungeonZone:SpawnPathingSquads(Attacker, CDungeonZone.Assault.nAttackerTeam)
				Attacker.flTimeOfNextSpawn = flTimeNow + Attacker.flSpawnInterval
				local nOrdersLeft = CDungeonZone.Assault.nMaxRescuedAttackersPerWave
				while #CDungeonZone.Assault.RescuedAttackers > 0 and nOrdersLeft > 0 do
					local nIndex = RandomInt(1, #CDungeonZone.Assault.RescuedAttackers)
					local hRescuedAttacker = CDungeonZone.Assault.RescuedAttackers[nIndex]
					local hWaypoint = Entities:FindByName(nil, CDungeonZone.Assault.szRescuedAttackerWaypoint)
					if hRescuedAttacker == nil or hRescuedAttacker:IsNull() then
						print("CDungeonZone:AssaultThink() - ERROR: Rescued Attacker is nil.")
					end
					if hWaypoint == nil then
						print("CDungeonZone:AssaultThink() - ERROR: Rescued waypoint is nil.")
					end

					--			print( "CDungeonZone:AssaultThink() - Issuing order to " .. hRescuedAttacker:GetUnitName() )
					hRescuedAttacker:SetInitialGoalEntity(hWaypoint)
					hRescuedAttacker:RemoveModifierByName("modifier_npc_dialog")
					hRescuedAttacker:RemoveModifierByName("modifier_npc_dialog_notify")
					hRescuedAttacker:RemoveModifierByName("modifier_stack_count_animation_controller")

					nOrdersLeft = nOrdersLeft - 1
					table.remove(CDungeonZone.Assault.RescuedAttackers, nIndex)
				end
			end
		end
	end

	if flTimeNow >= CDungeonZone.Assault.Defenders.flTimeOfNextSpawn then
		if #CDungeonZone.Enemies >= CDungeonZone.Assault.nMaxDefenders then
			--	print ( "CDungeonZone:AssaultThink - Number of defenders: " .. #CDungeonZone.Enemies .. " exceeds max defender count of: " .. CDungeonZone.Assault.nMaxDefenders )
		else
			CDungeonZone:SpawnChasingSquads(CDungeonZone.Assault.Defenders.nSquadsPerSpawn, CDungeonZone.Assault.nDefenderTeam, CDungeonZone.Assault.Defenders.ChasingSquads, CDungeonZone.Assault.Defenders.ChasingSpawners, CDungeonZone.Squads, CDungeonZone.Assault.Defenders.bDontRepeatSquads)
		end
		CDungeonZone.Assault.Defenders.flTimeOfNextSpawn = flTimeNow + CDungeonZone.Assault.Defenders.flSpawnInterval
	end
end

--------------------------------------------------------------------

function CDungeonZone:AddEnemyToZone(hUnit)
	table.insert(CDungeonZone.Enemies, hUnit)
	if hUnit.bBoss == true then
		table.insert(CDungeonZone.Bosses, hUnit)
	end
	hUnit.zone = CDungeonZone
	hUnit.nMinGoldBounty = hUnit:GetMinimumGoldBounty()
	hUnit.nMaxGoldBounty = hUnit:GetMaximumGoldBounty()
	hUnit.nDeathXP = hUnit:GetDeathXP()
	hUnit:SetMinimumGoldBounty(0)
	hUnit:SetMaximumGoldBounty(0)
	hUnit:SetDeathXP(0)
	if CDungeonZone.bDropsDisabled and hUnit.bBoss ~= true then
		hUnit:RemoveAllItemDrops()
	end
end

--------------------------------------------------------------------

function CDungeonZone:AddTreasureChestToZone(hUnit)
	--table.insert( CDungeonZone.ChestUnits, hUnit )
	hUnit.zone = CDungeonZone
end

--------------------------------------------------------------------


function CDungeonZone:AddBreakableContainerToZone(hUnit)
	--table.insert( CDungeonZone.BreakableContainerUnits, hUnit )
	hUnit.zone = CDungeonZone
end

--------------------------------------------------------------------

function CDungeonZone:CleanupZoneEnemy(deadEnemy)
	local bIsBoss = deadEnemy.bBoss

	for i = 1, #CDungeonZone.Enemies do
		local enemy = CDungeonZone.Enemies[i]
		if enemy == deadEnemy then
			table.remove(CDungeonZone.Enemies, i)
		end
	end

	if bIsBoss == true then
		for i = 1, #CDungeonZone.Bosses do
			local enemy = CDungeonZone.Bosses[i]
			if enemy == deadEnemy then
				table.remove(CDungeonZone.Bosses, i)
				if #CDungeonZone.Bosses == 0 then
					local netTable = {}
					netTable["boss_hp"] = 0
					CustomNetTables:SetTableValue("boss", string.format("%d", 0), netTable)
				end
			end
		end
	end
end

--------------------------------------------------------------------

function CDungeonZone:GetNumberOfEnemies()
	return #CDungeonZone.Enemies
end

--------------------------------------------------------------------

function CDungeonZone:GetNumberOfBosses()
	return #CDungeonZone.Bosses
end

--------------------------------------------------------------------

function CDungeonZone:WakeBosses()
	for _, Boss in pairs(CDungeonZone.Bosses) do
		Boss.bAwake = true
	end
end

--------------------------------------------------------------------

function CDungeonZone:InBossFight()
	for _, Boss in pairs(CDungeonZone.Bosses) do
		if Boss.bStarted == true and Boss:IsAlive() then
			return true
		end
	end

	return false
end

--------------------------------------------------------------------

function CDungeonZone:AllQuestsComplete()
	for _, quest in pairs(CDungeonZone.Quests) do
		if quest ~= nil and quest.bCompleted == false and quest.bOptional == false then
			return false
		end
	end

	return true
end

--------------------------------------------------------------------

function CDungeonZone:RemoveItemDropsFromZoneEnemies()
	if CDungeonZone.bDropsDisabled == true then
		return
	end

	for _, enemy in pairs(CDungeonZone.Enemies) do
		if enemy ~= nil and enemy.bBoss == false then
			enemy:RemoveAllItemDrops()
		end
	end

	CDungeonZone.bDropsDisabled = true
	--print( "CDungeonZone:RemoveItemDropsFromZoneEnemies()" )
end

--------------------------------------------------------------------

function CDungeonZone:AddStat(nPlayerID, Type, flAmount)
	if PlayerResource:IsValidTeamPlayer(nPlayerID) then
		if CDungeonZone.PlayerStats[nPlayerID] == nil then
			CDungeonZone.PlayerStats[nPlayerID] = {}
		end
		if Type == ZONE_STAT_KILLS then
			if CDungeonZone.PlayerStats[nPlayerID]["Kills"] == nil then
				CDungeonZone.PlayerStats[nPlayerID]["Kills"] = 0
			end
			CDungeonZone.PlayerStats[nPlayerID]["Kills"] = CDungeonZone.PlayerStats[nPlayerID]["Kills"] + flAmount
		end
		if Type == ZONE_STAT_DEATHS then
			if CDungeonZone.PlayerStats[nPlayerID]["Deaths"] == nil then
				CDungeonZone.PlayerStats[nPlayerID]["Deaths"] = 0
			end
			CDungeonZone.PlayerStats[nPlayerID]["Deaths"] = CDungeonZone.PlayerStats[nPlayerID]["Deaths"] + flAmount
		end
		if Type == ZONE_STAT_ITEMS then
			if CDungeonZone.PlayerStats[nPlayerID]["Items"] == nil then
				CDungeonZone.PlayerStats[nPlayerID]["Items"] = 0
			end
			CDungeonZone.PlayerStats[nPlayerID]["Items"] = CDungeonZone.PlayerStats[nPlayerID]["Items"] + flAmount
		end
		if Type == ZONE_STAT_GOLD_BAGS then
			if CDungeonZone.PlayerStats[nPlayerID]["GoldBags"] == nil then
				CDungeonZone.PlayerStats[nPlayerID]["GoldBags"] = 0
			end
			CDungeonZone.PlayerStats[nPlayerID]["GoldBags"] = CDungeonZone.PlayerStats[nPlayerID]["GoldBags"] + flAmount
		end
		if Type == ZONE_STAT_POTIONS then
			if CDungeonZone.PlayerStats[nPlayerID]["Potions"] == nil then
				CDungeonZone.PlayerStats[nPlayerID]["Potions"] = 0
			end
			CDungeonZone.PlayerStats[nPlayerID]["Potions"] = CDungeonZone.PlayerStats[nPlayerID]["Potions"] + flAmount
		end
		if Type == ZONE_STAT_REVIVE_TIME then
			if CDungeonZone.PlayerStats[nPlayerID]["ReviveTime"] == nil then
				CDungeonZone.PlayerStats[nPlayerID]["ReviveTime"] = 0
			end
			CDungeonZone.PlayerStats[nPlayerID]["ReviveTime"] = CDungeonZone.PlayerStats[nPlayerID]["ReviveTime"] + flAmount
		end
		if Type == ZONE_STAT_DAMAGE then
			if CDungeonZone.PlayerStats[nPlayerID]["Damage"] == nil then
				CDungeonZone.PlayerStats[nPlayerID]["Damage"] = 0
			end
			CDungeonZone.PlayerStats[nPlayerID]["Damage"] = CDungeonZone.PlayerStats[nPlayerID]["Damage"] + flAmount
		end
		if Type == ZONE_STAT_HEALING then
			if CDungeonZone.PlayerStats[nPlayerID]["Healing"] == nil then
				CDungeonZone.PlayerStats[nPlayerID]["Healing"] = 0
			end
			CDungeonZone.PlayerStats[nPlayerID]["Healing"] = CDungeonZone.PlayerStats[nPlayerID]["Healing"] + flAmount
		end

		if CDungeonZone.szName ~= "start" then
			CustomNetTables:SetTableValue("zone_scores", CDungeonZone.szName, CDungeonZone.PlayerStats)
		end
	end
end

--------------------------------------------------------------------

function CDungeonZone:GetCheckpoint()
	return CDungeonZone.hZoneCheckpoint
end

--------------------------------------------------------------------

function CDungeonZone:SetCheckpoint(hCheckpoint)
	--print( "CDungeonZone:SetCheckpoint - Assigning new checkpoint for zone " .. CDungeonZone.szName )
	CDungeonZone.hZoneCheckpoint = hCheckpoint
end

--------------------------------------------------------------------

function CDungeonZone:IsCheckpointActivated()
	if CDungeonZone.hZoneCheckpoint == nil then
		print("Zone checkpoint is nil in " .. CDungeonZone.szName)
		return false
	end

	if CDungeonZone.hZoneCheckpoint:GetTeamNumber() ~= DOTA_TEAM_GOODGUYS then
		print("Zone checkpoint not yet tagged in  " .. CDungeonZone.szName)
		return false
	end

	return true
end
