if XHSBotItemPlanner == nil then
	XHSBotItemPlanner = {}
end

local function Clamp(value, minimum, maximum)
	return math.max(minimum, math.min(maximum, tonumber(value) or 0))
end

local function Count(snapshot, name)
	return math.max(0, tonumber(snapshot.owned and snapshot.owned[name]) or 0)
end

local function TeamCount(snapshot, name)
	return math.max(
		0,
		tonumber(snapshot.allied_item_counts and snapshot.allied_item_counts[name]) or 0
	)
end

local function ShallowCopy(source)
	local result = {}
	for key, value in pairs(source or {}) do result[key] = value end
	return result
end

local function AddReason(reasons, condition, text)
	if condition then table.insert(reasons, text) end
end

local GetAffinity
local ROLE_FAMILY_TAG_WEIGHTS = {
	frontline = {
		frontline = 1.00, survival = 1.00, armor = 0.80,
		physical_defense = 0.70,
	},
	right_click = {
		right_click = 1.00, physical = 0.80, attack_speed = 0.70,
		single_target = 0.50, wave = 0.45, cleave = 0.65,
	},
	ranged_dps = {
		right_click = 0.90, physical = 0.75, attack_speed = 0.60,
		single_target = 0.55,
	},
	support = {
		team = 1.00, sustain = 0.80, cooldown = 0.45, mana = 0.30,
	},
	spellcaster = {
		caster = 1.00, magical = 1.00, cooldown = 0.80, mana = 0.45,
	},
	control = {
		control = 1.00, cooldown = 0.60, magical = 0.30,
	},
	wave_clear = {
		wave = 1.00, cleave = 0.90, magical = 0.45, physical = 0.45,
	},
}

function XHSBotItemPlanner:IsHighThreat(snapshot)
	return snapshot.base_threat_active == true
		or (tonumber(snapshot.combat_threat) or 0) >= 0.78
		or (tonumber(snapshot.base_threat_score) or 0) >= 0.58
		or (tonumber(snapshot.assignment_urgency) or 0) >= 0.88
		or (tonumber(snapshot.focused_by_count) or 0) >= 2
		or (tonumber(snapshot.recent_damage_ratio) or 0) >= 0.10
		or (tonumber(snapshot.health_ratio) or 1) <= 0.42
end

function XHSBotItemPlanner:GetFamilyProgress(snapshot, family)
	local highestTier = 0
	local completed = 0
	for tier, level in ipairs(family.levels or {}) do
		local owned = Count(snapshot, level.name)
		if owned > 0 then
			highestTier = math.max(highestTier, tier)
			if tier == #family.levels then completed = completed + owned end
		end
	end
	return highestTier, completed
end

function XHSBotItemPlanner:GetPhase(snapshot)
	local activeSlots = math.max(0, tonumber(snapshot.active_slots) or 0)
	local completedCores = 0
	local tierTwoFamilies = 0
	for _, family in pairs(XHSBotItemCatalog:GetFamilies()) do
		local tier, completed = self:GetFamilyProgress(snapshot, family)
		if tier >= 2 then tierTwoFamilies = tierTwoFamilies + 1 end
		completedCores = completedCores + completed
	end
	if activeSlots == 0 then return "sustain" end
	if tierTwoFamilies == 0 then return "core_1" end
	if tierTwoFamilies < 2 and activeSlots < 4 then return "core_2" end
	if activeSlots < 6 then return "six_slot" end
	if completedCores < 2 then return "upgrades" end
	return "luxury"
end

function XHSBotItemPlanner:GetFamilyLimit(profile, familyName)
	local configured = profile and profile.item_family_limits
		and tonumber(profile.item_family_limits[familyName]) or nil
	return math.max(0, math.floor(configured or 1))
end

function XHSBotItemPlanner:GetMinimumCoreScore(profile)
	return math.max(0, tonumber(profile and profile.minimum_core_score) or 40)
end

function XHSBotItemPlanner:GetOwnedOrbFamilyCount(snapshot)
	local count = 0
	for _, family in pairs(XHSBotItemCatalog:GetFamilies()) do
		local tier = self:GetFamilyProgress(snapshot, family)
		if tier >= 1 then count = count + 1 end
	end
	return count
end

function XHSBotItemPlanner:GetFamilyRoleFit(roleName, family)
	local weights = ROLE_FAMILY_TAG_WEIGHTS[tostring(roleName or "")]
	if weights == nil then return 0 end
	local fit = 0
	for tag, weight in pairs(weights) do
		fit = fit + (tonumber(family and family.tags and family.tags[tag]) or 0)
			* weight
	end
	return fit
end

function XHSBotItemPlanner:GetOwnedFamilyOverlap(snapshot, candidateFamilyName, candidate)
	local maximumOverlap = 0
	for ownedFamilyName, ownedFamily in pairs(XHSBotItemCatalog:GetFamilies()) do
		if ownedFamilyName ~= candidateFamilyName
			and self:GetFamilyProgress(snapshot, ownedFamily) >= 1 then
			local overlap = 0
			for tag, weight in pairs(candidate and candidate.tags or {}) do
				overlap = overlap + math.min(
					tonumber(weight) or 0,
					tonumber(ownedFamily.tags and ownedFamily.tags[tag]) or 0
				)
			end
			maximumOverlap = math.max(maximumOverlap, overlap)
		end
	end
	return maximumOverlap
end

function XHSBotItemPlanner:BuildOpeningOrbCandidates(snapshot, profile)
	local candidates = {}
	for familyName, family in pairs(XHSBotItemCatalog:GetFamilies()) do
		local tier = self:GetFamilyProgress(snapshot, family)
		if tier <= 0 and self:GetFamilyLimit(profile, familyName) > 0 then
			local entry = XHSBotItemCatalog:CopyEntry(family.levels[1].name)
			local score, reasons = self:ScoreFamily(
				snapshot,
				profile,
				familyName,
				family,
				entry
			)
			table.insert(candidates, {
				entry = entry,
				family = familyName,
				score = math.floor(score * 10) / 10,
				reason = table.concat(reasons, "+") .. "+opening_t1",
			})
		end
	end
	table.sort(candidates, function(left, right)
		if left.score == right.score then
			return left.entry.name < right.entry.name
		end
		return left.score > right.score
	end)
	return candidates
end

function XHSBotItemPlanner:GetLifestealOpeningScore(snapshot, profile)
	local affinities = profile and profile.item_affinities or {}
	local rightClick = GetAffinity(
		affinities,
		"right_click",
		"physical",
		"single_target"
	)
	local attackDps = math.max(0, tonumber(snapshot.attack_dps) or 0)
	local sustainPerSecond = attackDps * 0.50
	local score = 72
		+ rightClick * 24
		+ math.min(55, sustainPerSecond / 8)
	local entry = XHSBotItemCatalog:CopyEntry("item_lifesteal_mask")
	if entry ~= nil then
		score = score - self:GetShopTravelPenalty(snapshot, entry)
	end
	return math.floor(score * 10) / 10, rightClick, sustainPerSecond
end

function XHSBotItemPlanner:IsItemRedundant(profile, itemName)
	return profile ~= nil
		and type(profile.redundant_items) == "table"
		and profile.redundant_items[itemName] == true
end

function XHSBotItemPlanner:HasIntrinsicLifesteal(profile)
	local sustain = profile and profile.intrinsic_sustain or nil
	return type(sustain) == "table"
		and (sustain.attack_lifesteal == true or sustain.lifesteal_aura == true)
		and (tonumber(sustain.lifesteal_pct) or 0) > 0
end

function XHSBotItemPlanner:ShouldOpenWithLifesteal(snapshot, profile)
	if Count(snapshot, "item_lifesteal_mask") > 0 then return false end
	if self:IsItemRedundant(profile, "item_lifesteal_mask")
		or self:HasIntrinsicLifesteal(profile) then
		return false
	end
	if snapshot.secret_shop_available == false then return false end
	local _, rightClick, sustainPerSecond =
		self:GetLifestealOpeningScore(snapshot, profile)
	return sustainPerSecond >= 160
		or rightClick >= 0.85 and sustainPerSecond >= 115
end

function XHSBotItemPlanner:GetOpeningPackage(snapshot, profile, minimumCoreScore)
	local orbCount = self:GetOwnedOrbFamilyCount(snapshot)
	local tomesBought = math.max(0, tonumber(snapshot.tomes_bought) or 0)
	local maskOwned = Count(snapshot, "item_lifesteal_mask") > 0
	local maskRedundant = self:IsItemRedundant(profile, "item_lifesteal_mask")
		or self:HasIntrinsicLifesteal(profile)
	local maskAvailable = snapshot.secret_shop_available ~= false
		and not maskRedundant
	local orbCandidates = self:BuildOpeningOrbCandidates(snapshot, profile)
	local qualifying = 0
	for _, candidate in ipairs(orbCandidates) do
		if candidate.score >= minimumCoreScore then
			qualifying = qualifying + 1
		end
	end
	local desiredOrbs = 1
	if orbCount >= 2
		or orbCount == 1 and qualifying >= 1
		or orbCount == 0 and qualifying >= 2 then
		desiredOrbs = 2
	end
	local desiredTomes = desiredOrbs
	local maskNeeded = not maskOwned and maskAvailable
	local maskFirst = self:ShouldOpenWithLifesteal(snapshot, profile)

	local function OrbStep(index)
		local candidate = orbCandidates[index or 1]
		if candidate == nil then return nil end
		return {
			complete = false,
			stage = orbCount <= 0 and "first_orb_t1" or "second_orb_t1",
			candidate = candidate,
			entry = candidate.entry,
			desired_orbs = desiredOrbs,
			desired_tomes = desiredTomes,
			mask_first = maskFirst,
		}
	end

	local function MaskStep()
		local entry = XHSBotItemCatalog:CopyEntry("item_lifesteal_mask")
		if entry == nil then return nil end
		local score, _, sustainPerSecond =
			self:GetLifestealOpeningScore(snapshot, profile)
		return {
			complete = false,
			stage = "lifesteal_mask",
			candidate = {
				entry = entry,
				family = "lifesteal",
				score = score,
				reason = "opening cornerstone+sustain_per_second:"
					.. tostring(math.floor(sustainPerSecond)),
			},
			entry = entry,
			desired_orbs = desiredOrbs,
			desired_tomes = desiredTomes,
			mask_first = maskFirst,
		}
	end

	local function TomeStep()
		return {
			complete = false,
			stage = tomesBought <= 0 and "first_tome_t1" or "second_tome_t1",
			tome_due = true,
			desired_orbs = desiredOrbs,
			desired_tomes = desiredTomes,
			mask_first = maskFirst,
		}
	end

	if maskFirst and maskNeeded then return MaskStep() end
	if orbCount < desiredOrbs then
		local step = OrbStep(1)
		if step ~= nil then return step end
	end
	if tomesBought < desiredTomes then return TomeStep() end
	if maskNeeded then return MaskStep() end
	return {
		complete = true,
		stage = "complete",
		desired_orbs = desiredOrbs,
		desired_tomes = desiredTomes,
		mask_first = maskFirst,
		mask_unavailable = not maskOwned and not maskAvailable,
		mask_redundant = maskRedundant,
	}
end

function XHSBotItemPlanner:GetNextFamilyEntry(snapshot, profile, familyName, family)
	local limit = self:GetFamilyLimit(profile, familyName)
	if limit <= 0 then return nil end
	local terminal = family.levels[#family.levels]
	local completed = Count(snapshot, terminal.name)
	if completed >= limit then return nil end

	for tier = #family.levels - 1, 1, -1 do
		local owned = Count(snapshot, family.levels[tier].name)
		if owned > 0 then
			return XHSBotItemCatalog:CopyEntry(family.levels[tier + 1].name)
		end
	end
	return XHSBotItemCatalog:CopyEntry(family.levels[1].name)
end

GetAffinity = function(affinities, ...)
	local result = 0
	for index = 1, select("#", ...) do
		result = math.max(
			result,
			tonumber(affinities[select(index, ...)]) or 0
		)
	end
	return Clamp(result, 0, 1.25)
end

function XHSBotItemPlanner:GetStatPower(snapshot, profile, entry)
	local stats = entry and entry.stats or {}
	local previousStats = {}
	if snapshot.score_total_item_power ~= true and entry.predecessor ~= nil then
		local predecessor = XHSBotItemCatalog:Get(entry.predecessor)
		previousStats = predecessor and predecessor.stats or {}
	end
	local function Delta(name)
		return math.max(
			0,
			(tonumber(stats[name]) or 0)
				- (tonumber(previousStats[name]) or 0)
		)
	end

	local affinities = profile and profile.item_affinities or {}
	local rightClick = math.max(0.20, GetAffinity(affinities, "right_click", "physical"))
	local survival = math.max(0.20, GetAffinity(affinities, "survival", "frontline"))
	local caster = math.max(0.20, GetAffinity(affinities, "caster", "magical"))
	local wave = math.max(0.15, GetAffinity(affinities, "wave", "cleave"))
	local boss = math.max(0.15, GetAffinity(affinities, "boss", "single_target"))
	local mobility = math.max(0.15, GetAffinity(affinities, "mobility", "evasion"))

	-- These are normalized marginal combat contributions, not arbitrary
	-- item rankings.  Candidate upgrades score only the stats gained over
	-- their predecessor; six-slot loadouts score the terminal item's total
	-- slot power.
	local power = 0
	power = power + Delta("bonus_damage") / 120 * (0.35 + rightClick * 0.65)
	power = power + Delta("cleave_pct") / 2.5 * (0.25 + wave * 0.75)
	power = power + Delta("bonus_hp") / 650 * (0.35 + survival * 0.65)
	power = power + Delta("bonus_armor") / 4 * (0.30 + survival * 0.70)
	power = power + Delta("bonus_health_regen") / 25 * survival
	power = power + Delta("spell_amp_pct") / 5 * (0.30 + caster * 0.70)
	power = power + Delta("cooldown_reduction_pct") / 3 * caster
	power = power + Delta("exposure_magic_resist_reduction") / 3 * caster
	power = power + Delta("bonus_evasion_pct") / 5 * (0.35 + mobility * 0.65)
	power = power + (
		Delta("bonus_movement_speed")
			+ Delta("bonus_movespeed_pct")
	) / 35 * mobility
	power = power + Delta("poison_damage_per_second") / 30
		* (0.35 + boss * 0.65)
	power = power + Delta("armor_reduction") / 2.5
		* (0.30 + boss * 0.70)
	power = power + Delta("toxic_saturation_damage") / 125 * boss
	power = power + Delta("bat_reduction") * 50 * rightClick
	power = power + Delta("evasion_proc_damage_reduction_pct") / 5
		* survival
	power = power + Delta("bash_chance") * Delta("bash_duration") / 2
	power = power + Delta("purge_chance") / 10
	power = power + Delta("lifesteal_pct") / 5
		* (0.35 + rightClick * 0.65)

	local valueFactor = math.min(
		1.25,
		10000 / math.max(1000, tonumber(entry.cost) or 10000)
	)
	return math.min(28, power) * valueFactor
end

function XHSBotItemPlanner:GetShopTravelPenalty(snapshot, entry)
	if snapshot.ignore_travel_cost == true or entry == nil then return 0 end
	local shop = tostring(entry.shop or "home")
	local distance = shop == "secret"
		and tonumber(snapshot.secret_shop_distance)
		or tonumber(snapshot.home_shop_distance)
	if distance == nil or distance < 0 then return 0 end

	local arrivalRadius = shop == "secret" and 350 or 550
	local travelDistance = math.max(0, distance - arrivalRadius)
	if travelDistance <= 0 then return 0 end
	local movementSpeed = math.max(220, tonumber(snapshot.movement_speed) or 300)
	local travelSeconds = travelDistance / movementSpeed
	local pressure = math.max(
		Clamp(snapshot.combat_threat, 0, 1.5),
		Clamp(snapshot.base_threat_score, 0, 1.5),
		Clamp(snapshot.assignment_urgency, 0, 1.5)
	)
	local penalty = travelSeconds * (0.55 + pressure * 0.75)
	if snapshot.in_combat == true then
		penalty = penalty + math.min(6, 2 + pressure * 3)
	end
	return math.min(22, math.floor(penalty * 10 + 0.5) / 10)
end

function XHSBotItemPlanner:ScoreFamily(snapshot, profile, familyName, family, entry)
	local affinities = profile and profile.item_affinities or {}
	local score = 20
	local reasons = {}
	local strongestTag = nil
	local strongestValue = 0
	for tag, weight in pairs(family.tags or {}) do
		local affinity = tonumber(affinities[tag]) or 0
		local contribution = affinity * weight * 26
		score = score + contribution
		if contribution > strongestValue then
			strongestTag = tag
			strongestValue = contribution
		end
	end
	AddReason(reasons, strongestTag ~= nil, "kit:" .. tostring(strongestTag))

	local familyTier = self:GetFamilyProgress(snapshot, family)
	if familyTier <= 0 and self:GetOwnedOrbFamilyCount(snapshot) >= 1 then
		local secondaryFit =
			self:GetFamilyRoleFit(profile and profile.secondary_role, family)
		if secondaryFit > 0 then
			local secondaryBonus = math.min(26, secondaryFit * 12)
			score = score + secondaryBonus
			table.insert(reasons, "secondary_role:"
				.. tostring(profile.secondary_role))
		end
		local overlap = self:GetOwnedFamilyOverlap(snapshot, familyName, family)
		if overlap > 0 then
			score = score - math.min(18, overlap * 10)
			table.insert(reasons, "cross_core_overlap")
		end
	end

	local statPower = self:GetStatPower(snapshot, profile, entry)
	score = score + statPower
	if statPower >= 0.5 then
		table.insert(reasons, "stats:" .. tostring(math.floor(statPower * 10) / 10))
	end
	local meleeCleave = familyName == "fire"
		and (tonumber(profile and profile.preferred_range) or 999) <= 250
	if meleeCleave then
		score = score + 7 + (tonumber(affinities.wave) or 0) * 7
		table.insert(reasons, "melee_cleave")
	end

	local threat = Clamp(snapshot.combat_threat, 0, 2)
	local baseThreat = Clamp(snapshot.base_threat_score, 0, 2)
	local focused = math.max(0, tonumber(snapshot.focused_by_count) or 0)
	local nearby = math.max(0, tonumber(snapshot.nearby_screen_count) or 0)
	local survivalWeight = (tonumber(family.tags.survival) or 0)
		+ (tonumber(family.tags.physical_defense) or 0) * 0.7
	score = score + survivalWeight * (threat * 18 + baseThreat * 14 + focused * 5)
	AddReason(reasons, survivalWeight > 0 and self:IsHighThreat(snapshot), "danger")

	local waveWeight = tonumber(family.tags.wave) or 0
	if nearby >= 3 then
		score = score + waveWeight * math.min(24, nearby * 4)
		AddReason(reasons, waveWeight > 0, "dense_wave")
	end
	if snapshot.boss_nearby == true or snapshot.goal == "fight_boss" then
		local bossWeight = tonumber(family.tags.boss) or 0
			+ (tonumber(family.tags.single_target) or 0) * 0.65
			+ (tonumber(family.tags.magical) or 0) * 0.25
		score = score + bossWeight * 20
		AddReason(reasons, bossWeight > 0, "boss")
	end
	local groupedFight = snapshot.boss_nearby == true
		or snapshot.base_threat_active == true
		or snapshot.goal == "fight_boss"
		or snapshot.goal == "defend_base"
	local sharedDebuff = tonumber(family.tags.shared_debuff) or 0
	local alliedCoverage = math.max(
		0,
		tonumber(
			snapshot.allied_family_counts
				and snapshot.allied_family_counts[familyName]
		) or 0
	)
	if groupedFight and sharedDebuff > 0 and alliedCoverage > 0 then
		score = score - math.min(16, alliedCoverage * sharedDebuff * 8)
		table.insert(reasons, "ally_coverage")
	end

	if entry.tier > 1 then
		score = score + 10 + entry.tier * 3
		table.insert(reasons, "upgrade")
	end
	local completed = Count(snapshot, family.levels[#family.levels].name)
	if completed > 0 then
		score = score - completed * 9
		table.insert(reasons, "duplicate_marginal")
	end
	score = score + math.min(9, 10000 / math.max(1000, entry.cost) * 4)
	local travelPenalty = self:GetShopTravelPenalty(snapshot, entry)
	if travelPenalty > 0 then
		score = score - travelPenalty
		table.insert(reasons, "travel_cost:" .. tostring(travelPenalty))
	end

	if entry.shop == "secret" and snapshot.secret_shop_available == false then
		return -1000, { "secret_shop_unavailable" }
	end
	if entry.tier == 1 and (tonumber(snapshot.inventory_slots) or 0) >= 9 then
		score = score - 18
		table.insert(reasons, "replacement_required")
	end
	return score, reasons
end

function XHSBotItemPlanner:GetBootsCandidate(snapshot, profile, phase)
	if phase ~= "core_2" and phase ~= "six_slot" then return nil end
	if Count(snapshot, "item_boots_of_speed") > 0 then return nil end
	if snapshot.secret_shop_available == false then return nil end
	if (tonumber(snapshot.inventory_slots) or 0) >= 6 then return nil end

	local affinities = profile and profile.item_affinities or {}
	local mobility = GetAffinity(affinities, "mobility")
	local laneDistance = math.max(0, tonumber(snapshot.lane_anchor_distance) or 0)
	local longRotation = Clamp((laneDistance - 1800) / 3200, 0, 1)
	local stuckPressure = Clamp(
		(tonumber(snapshot.stuck_recoveries) or 0) / 3,
		0,
		1
	)
	local movementNeed = math.max(longRotation, stuckPressure * 0.75)

	-- Boots consume one of six precious slots and require a castle-shop trip.
	-- A mobility-oriented kit plus measured rotation friction must both justify
	-- them; ordinary certified profiles therefore keep preferring real cores.
	if mobility < 0.70 or movementNeed < 0.55 then return nil end
	local entry = XHSBotItemCatalog:CopyEntry("item_boots_of_speed")
	if entry == nil then return nil end
	entry.maximum = 1
	entry.tier = 1
	local statPower = self:GetStatPower(snapshot, profile, entry)
	local travelPenalty = self:GetShopTravelPenalty(snapshot, entry)
	local score = 20
		+ mobility * 30
		+ movementNeed * 28
		+ statPower
		- math.max(0, tonumber(entry.default_penalty) or 0)
		- travelPenalty
	local reasons = {
		"kit:mobility",
		"rotation:" .. tostring(math.floor(movementNeed * 10) / 10),
		"slot_penalty:" .. tostring(entry.default_penalty or 0),
	}
	if statPower > 0 then
		table.insert(reasons, "stats:" .. tostring(math.floor(statPower * 10) / 10))
	end
	if travelPenalty > 0 then
		table.insert(reasons, "travel_cost:" .. tostring(travelPenalty))
	end
	return {
		entry = entry,
		family = "mobility",
		score = math.floor(score * 10) / 10,
		reason = table.concat(reasons, "+"),
	}
end

function XHSBotItemPlanner:BuildCoreCandidates(snapshot, profile, phase)
	local candidates = {}
	for familyName, family in pairs(XHSBotItemCatalog:GetFamilies()) do
		local entry = self:GetNextFamilyEntry(snapshot, profile, familyName, family)
		if entry ~= nil then
			local score, reasons = self:ScoreFamily(
				snapshot,
				profile,
				familyName,
				family,
				entry
			)
			table.insert(candidates, {
				entry = entry,
				family = familyName,
				score = math.floor(score * 10) / 10,
				reason = table.concat(reasons, "+"),
			})
		end
	end
	local bootsCandidate = self:GetBootsCandidate(snapshot, profile, phase)
	if bootsCandidate ~= nil then table.insert(candidates, bootsCandidate) end
	table.sort(candidates, function(left, right)
		if left.score == right.score then
			return left.entry.name < right.entry.name
		end
		return left.score > right.score
	end)
	return candidates
end

function XHSBotItemPlanner:BuildTargetLoadout(snapshot, profile)
	local minimumCoreScore = self:GetMinimumCoreScore(profile)
	local slots = {}
	local scoringSnapshot = ShallowCopy(snapshot)
	-- The loadout represents the strategic destination. A castle_shop that
	-- disappears later must not make an already-owned terminal core look
	-- worthless or trigger destructive churn.
	scoringSnapshot.secret_shop_available = true
	scoringSnapshot.inventory_slots = 0
	scoringSnapshot.score_total_item_power = true
	scoringSnapshot.ignore_travel_cost = true
	for familyName, family in pairs(XHSBotItemCatalog:GetFamilies()) do
		local terminal = family.levels[#family.levels]
		local entry = XHSBotItemCatalog:CopyEntry(terminal.name)
		local baseScore, reasons = self:ScoreFamily(
			scoringSnapshot,
			profile,
			familyName,
			family,
			entry
		)
		local completed = Count(snapshot, terminal.name)
		-- ScoreFamily discounts duplicates based on current ownership. Remove
		-- that stateful term here, then price each prospective slot explicitly.
		baseScore = baseScore + completed * 9
		local limit = self:GetFamilyLimit(profile, familyName)
		for slotIndex = 1, limit do
			local score = baseScore - (slotIndex - 1) * 9
			if completed >= slotIndex then score = score + 4 end
			if score >= minimumCoreScore or completed >= slotIndex then
				table.insert(slots, {
					name = terminal.name,
					family = familyName,
					score = math.floor(score * 10) / 10,
					reason = table.concat(reasons, "+"),
					owned = completed >= slotIndex,
				})
			end
		end
	end
	local lifestealEntry = XHSBotItemCatalog:CopyEntry("item_lifesteal_mask")
	if lifestealEntry ~= nil
		and not self:IsItemRedundant(profile, lifestealEntry.name)
		and not self:HasIntrinsicLifesteal(profile) then
		local lifestealScore, rightClick, sustainPerSecond =
			self:GetLifestealOpeningScore(scoringSnapshot, profile)
		lifestealScore = math.max(
			112,
			lifestealScore + rightClick * 10
				+ math.min(18, sustainPerSecond / 20)
		)
		if Count(snapshot, lifestealEntry.name) > 0 then
			lifestealScore = lifestealScore + 4
		end
		table.insert(slots, {
			name = lifestealEntry.name,
			family = "lifesteal",
			score = math.floor(lifestealScore * 10) / 10,
			reason = "opening_cornerstone+50pct_lifesteal",
			owned = Count(snapshot, lifestealEntry.name) > 0,
		})
	end
	table.sort(slots, function(left, right)
		if left.score == right.score then
			if left.owned ~= right.owned then return left.owned == true end
			if left.name == right.name then return left.family < right.family end
			return left.name < right.name
		end
		return left.score > right.score
	end)

	local loadout = {}
	local itemScores = {}
	local familyScores = {}
	local details = {}
	for index = 1, math.min(6, #slots) do
		local slot = slots[index]
		table.insert(loadout, slot.name)
		table.insert(details, slot)
		itemScores[slot.name] = math.max(
			tonumber(itemScores[slot.name]) or -math.huge,
			slot.score
		)
		familyScores[slot.family] = math.max(
			tonumber(familyScores[slot.family]) or -math.huge,
			slot.score
		)
	end
	return loadout, itemScores, familyScores, details
end

function XHSBotItemPlanner:GetDesiredPotionCharges(
	kind,
	snapshot,
	profile,
	difficulty,
	phase,
	reserve
)
	local profileTarget = profile and profile.consumable_targets
		and tonumber(profile.consumable_targets[kind]) or nil
	local difficultyTarget = difficulty
		and tonumber(difficulty["target_" .. tostring(kind) .. "_potion_charges"]) or nil
	local potionName = kind == "mana"
		and "item_mana_potion" or "item_health_potion"
	local potion = XHSBotItemCatalog:Get(potionName) or {}
	local stackCharges = math.max(1, math.floor(tonumber(potion.charges) or 15))
	local baseTarget = math.max(
		stackCharges,
		math.floor(tonumber(profileTarget or difficultyTarget) or stackCharges)
	)
	local phaseTarget = stackCharges
	if phase == "core_2" or phase == "six_slot" then
		phaseTarget = stackCharges * 2
	elseif phase == "upgrades" or phase == "luxury" then
		phaseTarget = stackCharges * 3
	end
	local spendable = math.max(
		0,
		(tonumber(snapshot and snapshot.gold) or 0)
			- math.max(0, tonumber(reserve) or 0)
	)
	local cost = math.max(1, tonumber(potion.cost) or 1)
	local affordableStacks = math.floor(spendable / cost)
	local currentCharges = math.max(
		0,
		tonumber(snapshot and snapshot[tostring(kind) .. "_potion_charges"])
			or 0
	)
	local affordableTarget = currentCharges + affordableStacks * stackCharges
	return math.max(
		baseTarget,
		math.min(phaseTarget, affordableTarget)
	)
end

function XHSBotItemPlanner:GetPotionRestockThreshold(kind, snapshot, profile, difficulty)
	if kind == "health" then
		return math.max(
			0,
			math.floor(tonumber(
				difficulty and difficulty.health_resupply_trigger_charges
			) or 3)
		)
	end
	return 3
end

function XHSBotItemPlanner:GetDesiredAnkhCharges(snapshot, phase, nextItemReserve)
	local gold = math.max(0, tonumber(snapshot.gold) or 0)
	local deathSeconds = math.max(
		tonumber(snapshot.last_death_duration) or 0,
		tonumber(snapshot.expected_respawn_seconds) or 0
	)
	local expensiveDeath = deathSeconds >= 28
		or (tonumber(snapshot.game_time) or 0) >= 10 * 60
	local desired = 0
	if expensiveDeath or self:IsHighThreat(snapshot) and gold >= 3000 then
		desired = 1
	end
	if phase ~= "sustain" and gold >= 1500 + math.min(10000, nextItemReserve or 0) then
		desired = math.max(desired, 1)
	end
	local extreme = (tonumber(snapshot.game_difficulty) or 0) >= 4
		and ((tonumber(snapshot.combat_threat) or 0) >= 1.10
			or (tonumber(snapshot.base_threat_score) or 0) >= 0.85
			or deathSeconds >= 40)
	if extreme and phase ~= "core_1"
		and gold >= math.max(6000, (nextItemReserve or 0) + 3000) then
		desired = 2
	end
	return desired
end

function XHSBotItemPlanner:GetTacticalPurchase(snapshot, profile, phase, coreReserve)
	local affinities = profile and profile.item_affinities or {}
	local difficulty = tonumber(snapshot.game_difficulty) or 0
	local gold = math.max(0, tonumber(snapshot.gold) or 0)
	local threat = math.max(0, tonumber(snapshot.combat_threat) or 0)
	local baseThreat = math.max(0, tonumber(snapshot.base_threat_score) or 0)
	local focused = math.max(0, tonumber(snapshot.focused_by_count) or 0)
	local healthRatio = tonumber(snapshot.health_ratio) or 1
	local manaRatio = tonumber(snapshot.mana_ratio) or 1
	local wavePressure = (tonumber(snapshot.nearby_screen_count) or 0) >= 4
	local highThreat = self:IsHighThreat(snapshot)
	local extremeThreat = threat >= 1.05 or baseThreat >= 0.82
		or focused >= 3 or healthRatio <= 0.28
	local candidates = {}

	local function Add(name, score, reason, preserveCore)
		local entry = XHSBotItemCatalog:CopyEntry(name)
		if entry == nil or Count(snapshot, name) > 0 then return end
		if entry.shop == "secret" and snapshot.secret_shop_available == false then return end
		local cost = math.max(0, tonumber(entry.cost) or 0)
		local reserve = preserveCore and math.min(cost, math.max(0, coreReserve or 0)) or 0
		if gold < cost + reserve then return end
		entry.maximum = 1
		entry.blocking = false
		table.insert(candidates, {
			entry = entry,
			score = score,
			reason = reason,
		})
	end

	-- Cheap sustain may interrupt a core when the alternative is a likely
	-- death or a collapsing castle. Stable lanes preserve the core reserve.
	if highThreat and (healthRatio <= 0.55 or manaRatio <= 0.16)
		and (tonumber(snapshot.max_health) or 0) >= 9000 then
		Add("item_potion_full", 118 + (1 - healthRatio) * 35,
			"emergency 30k restoration", not extremeThreat)
	end
	if (baseThreat >= 0.55 or threat >= 0.80)
		and (tonumber(affinities.team) or 0) >= 0.55
		and healthRatio <= 0.82 then
		local smallWardCoverage = Count(snapshot, "item_healing_wards")
			+ TeamCount(snapshot, "item_healing_wards")
		local greaterWardCoverage = Count(snapshot, "item_healing_wards2")
			+ TeamCount(snapshot, "item_healing_wards2")
		local latePhase = phase == "upgrades" or phase == "luxury"
		if latePhase
			and greaterWardCoverage <= 0
			and (baseThreat >= 0.70 or threat >= 0.90)
			and (tonumber(affinities.team) or 0) >= 0.70 then
			Add("item_healing_wards2", 118 + baseThreat * 22
				+ math.min(4, tonumber(snapshot.allied_low_health_count) or 0) * 5,
				"greater team sustain under major pressure", true)
		end
		if smallWardCoverage <= 0 and greaterWardCoverage <= 0 then
			Add("item_healing_wards", 96 + baseThreat * 18,
				"team sustain under pressure", true)
		end
	end

	-- Expensive consumables and summons are reserved for real high
	-- difficulties. Easy/Normal never burn 5k+ on panic insurance.
	if difficulty >= 4 and highThreat then
		if snapshot.has_owned_furbolg ~= true and threat >= 0.85 then
			Add("item_amulet_of_the_wild", 112 + threat * 16,
				"high-threat furbolg screen", not extremeThreat)
		end
		if wavePressure and (tonumber(affinities.frontline) or 0) >= 0.55 then
			Add("item_xhs_cloak_of_flames", 100
				+ (tonumber(affinities.frontline) or 0) * 18,
				"frontline wave pressure", true)
		end
		if extremeThreat then
			Add("item_potion_of_invulnerability", 128 + focused * 8,
				"fatal physical pressure", false)
		end
		if (tonumber(snapshot.magical_threat) or 0) >= 0.68 then
			Add("item_potion_of_antimagic", 122
				+ (tonumber(snapshot.magical_threat) or 0) * 15,
				"measured magical pressure", not extremeThreat)
		end
	end

	local casterValue = (tonumber(affinities.magical) or 0)
		+ (tonumber(affinities.control) or 0)
	if (phase == "upgrades" or phase == "luxury")
		and casterValue >= 1.15
		and (snapshot.boss_nearby == true or threat >= 0.75) then
		Add("item_staff_of_mastery", 82 + casterValue * 18,
			"caster control against dangerous target", true)
	end

	table.sort(candidates, function(left, right)
		if left.score == right.score then
			return left.entry.name < right.entry.name
		end
		return left.score > right.score
	end)
	local best = candidates[1]
	return best and best.entry or nil, best and best.reason or nil
end

function XHSBotItemPlanner:GetTomeAllowance(
	snapshot,
	phase,
	nextItemReserve,
	difficulty,
	opening
)
	if snapshot.in_farm_event == true then
		return math.max(1, math.min(8, tonumber(difficulty.max_tomes_per_think) or 1))
	end
	if opening ~= nil and opening.complete ~= true then
		return opening.tome_due == true and 1 or 0
	end
	local bought = math.max(0, tonumber(snapshot.tomes_bought) or 0)
	local spendable = math.max(
		0,
		(tonumber(snapshot.gold) or 0) - math.max(0, tonumber(nextItemReserve) or 0)
	)
	if phase == "sustain" or phase == "core_1" then return 0 end
	if phase == "core_2" then
		return bought < 1 and spendable >= 20000 and 1 or 0
	end
	if phase == "six_slot" then
		return bought < 2 and spendable >= 20000 and 1 or 0
	end
	return math.max(0, math.min(3, tonumber(difficulty.max_tomes_per_think) or 1))
end

function XHSBotItemPlanner:Plan(snapshot, profile, difficulty)
	snapshot = snapshot or {}
	local phase = self:GetPhase(snapshot)
	local candidates = self:BuildCoreCandidates(snapshot, profile, phase)
	local nextCandidate = candidates[1]
	local minimumCoreScore = self:GetMinimumCoreScore(profile)
	local opening = self:GetOpeningPackage(snapshot, profile, minimumCoreScore)
	if opening ~= nil and opening.complete ~= true then
		nextCandidate = opening.candidate
	end
	if nextCandidate ~= nil
		and (opening == nil or opening.complete == true)
		and nextCandidate.entry.tier == 1
		and nextCandidate.score < minimumCoreScore then
		nextCandidate = nil
	end
	if nextCandidate ~= nil and nextCandidate.score < 0 then nextCandidate = nil end
	if nextCandidate == nil
		and (opening == nil or opening.complete == true)
		and phase ~= "sustain" and phase ~= "core_1" then
		phase = "luxury"
	end
	local reserve = nextCandidate and math.max(0, tonumber(nextCandidate.entry.cost) or 0) or 0
	local tactical, tacticalReason = self:GetTacticalPurchase(
		snapshot,
		profile,
		phase,
		reserve
	)
	local targetLoadout, targetLoadoutScores, familyLoadoutScores,
		targetLoadoutDetails = self:BuildTargetLoadout(snapshot, profile)
	local plan = {
		phase = phase,
		candidates = candidates,
		next_entry = nextCandidate and nextCandidate.entry or nil,
		next_family = nextCandidate and nextCandidate.family or "",
		next_score = nextCandidate and nextCandidate.score or 0,
		next_reason = nextCandidate and nextCandidate.reason
			or opening ~= nil and opening.tome_due == true
				and "opening small tome"
			or "no core clears marginal score " .. tostring(minimumCoreScore),
		minimum_core_score = minimumCoreScore,
		reserve_gold = reserve,
		tactical_entry = tactical,
		tactical_reason = tacticalReason or "",
		target_loadout = targetLoadout,
		target_loadout_scores = targetLoadoutScores,
		family_loadout_scores = familyLoadoutScores,
		target_loadout_details = targetLoadoutDetails,
		inventory_slots = tonumber(snapshot.inventory_slots) or 0,
		replacement_required = nextCandidate ~= nil
			and nextCandidate.entry.tier == 1
			and (tonumber(snapshot.inventory_slots) or 0) >= 9,
		health_potion_target = self:GetDesiredPotionCharges(
			"health", snapshot, profile, difficulty, phase, reserve
		),
		mana_potion_target = self:GetDesiredPotionCharges(
			"mana", snapshot, profile, difficulty, phase, reserve
		),
		opening_stage = opening and opening.stage or "complete",
		opening_complete = opening == nil or opening.complete == true,
		opening_tome_due = opening ~= nil and opening.tome_due == true,
		opening_mask_first = opening ~= nil and opening.mask_first == true,
		opening_mask_unavailable = opening ~= nil
			and opening.mask_unavailable == true,
		opening_orb_target = opening and opening.desired_orbs or 0,
		opening_tome_target = opening and opening.desired_tomes or 0,
	}
	plan.health_potion_restock = self:GetPotionRestockThreshold(
		"health", snapshot, profile, difficulty
	)
	plan.mana_potion_restock = self:GetPotionRestockThreshold(
		"mana", snapshot, profile, difficulty
	)
	plan.ankh_target = self:GetDesiredAnkhCharges(snapshot, phase, reserve)
	plan.tome_allowance = self:GetTomeAllowance(
		snapshot,
		phase,
		reserve,
		difficulty,
		opening
	)
	return plan
end

return XHSBotItemPlanner
