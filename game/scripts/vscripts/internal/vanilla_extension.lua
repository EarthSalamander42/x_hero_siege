function GetReductionFromArmor(armor)
	return ((0.052 * armor) / (0.9 + 0.048 * armor))
end

function CDOTA_BaseNPC:GetLifesteal()
	local lifesteal = 0

	-- useless atm because modifier can't have multiple instances, find a way to call lifefsteal attack once
	for _, parent_modifier in pairs(self:FindAllModifiers()) do
		if parent_modifier and parent_modifier.GetModifierLifesteal and parent_modifier:GetModifierLifesteal() and lifesteal then
			if parent_modifier:GetModifierLifesteal() > lifesteal then
				lifesteal = parent_modifier:GetModifierLifesteal()
			end
		end
	end

	return lifesteal
end

function CDOTA_BaseNPC:GetRealDamageDone(hTarget)
	local base_damage = self:GetAverageTrueAttackDamage(hTarget)
	local armor_reduction = GetReductionFromArmor(hTarget:GetPhysicalArmorValue(false))
	return base_damage - (base_damage * armor_reduction)
end

function CDOTA_BaseNPC:FindItemByName(ItemName, bStash)
	local count = 8

	if bStash == true then
		count = 14
	end

	for slot = 0, count do
		local item = self:GetItemInSlot(slot)
		if item then
			if item:GetName() == ItemName then
				return item
			end
		end
	end

	return nil
end

function CDOTA_BaseNPC:RemoveItemByName(ItemName, bStash)
	local count = 8

	if bStash == true then
		count = 14
	end

	for slot = 0, count do
		local item = self:GetItemInSlot(slot)
		if item then
			if item:GetName() == ItemName then
				self:RemoveItem(item)
				break
			end
		end
	end
end

function CDOTA_BaseNPC:IncrementAttributes(amount, bAll)
	if self:IsIllusion() then return end

	local bSoundPlayed = false

	if self:HasModifier("modifier_tome_of_stats") then
		self:FindModifierByName("modifier_tome_of_stats"):SetStackCount(self:FindModifierByName("modifier_tome_of_stats"):GetStackCount() + amount)
	else
		self:AddNewModifier(self, nil, "modifier_tome_of_stats", {}):SetStackCount(amount)
	end

	if not self.GetPlayerID then return end

	local particle1 = ParticleManager:CreateParticle("particles/generic_hero_status/hero_levelup.vpcf", PATTACH_ABSORIGIN_FOLLOW, self, self)
	ParticleManager:SetParticleControl(particle1, 0, self:GetAbsOrigin())

	if bAll == true and bSoundPlayed == false then
		bSoundPlayed = true
		self:EmitSound("ui.trophy_levelup")
	end

	self:CalculateStatBonus(true)
end

function CDOTA_BaseNPC:GetNetworth()
	if not self:IsRealHero() then return 0 end
	local gold = self:GetGold()

	-- Iterate over item slots adding up its gold cost
	for i = 0, 15 do
		local item = self:GetItemInSlot(i)
		if item then
			gold = gold + item:GetCost()
		end
	end

	return gold
end

-- credits to yahnich for the following
function CDOTA_BaseNPC:IsFakeHero()
	if self:IsIllusion() or (self:HasModifier("modifier_monkey_king_fur_army_soldier") or self:HasModifier("modifier_monkey_king_fur_army_soldier_hidden")) or self:IsTempestDouble() or self:IsClone() then
		return true
	else return false end
end

function CDOTA_BaseNPC:IsRealHero()
	if not self:IsNull() then
		return self:IsHero() and not ( self:IsIllusion() or self:IsClone() ) and not self:IsFakeHero()
	end
end

function CDOTA_BaseNPC:Blink(position, bTeamOnlyParticle, bPlaySound)
	if self:IsNull() then return end
	local blink_effect = "particles/items_fx/blink_dagger_start.vpcf"
	local blink_effect_end = "particles/items_fx/blink_dagger_end.vpcf"
	local blink_sound = "DOTA_Item.BlinkDagger.Activate"
	if self.blink_effect or self:GetPlayerOwner().blink_effect then blink_effect = self.blink_effect end
	if self.blink_effect_end or self:GetPlayerOwner().blink_effect_end then blink_effect_end = self.blink_effect_end end
	if self.blink_sound or self:GetPlayerOwner().blink_sound then blink_sound = self.blink_sound end
	if bPlaySound == true then EmitSoundOn(blink_sound, self) end
	if bTeamOnlyParticle == true then
		local blink_pfx = ParticleManager:CreateParticleForTeam(blink_effect, PATTACH_ABSORIGIN, self, self:GetTeamNumber())
		ParticleManager:ReleaseParticleIndex(blink_pfx)
	else
		ParticleManager:FireParticle(blink_effect, PATTACH_ABSORIGIN, self, {[0] = self:GetAbsOrigin()})
	end
	FindClearSpaceForUnit(self, position, true)
	ProjectileManager:ProjectileDodge( self )
	if bTeamOnlyParticle == true then
		local blink_end_pfx = ParticleManager:CreateParticleForTeam(blink_effect_end, PATTACH_ABSORIGIN, self, self:GetTeamNumber())
		ParticleManager:ReleaseParticleIndex(blink_end_pfx)
	else
		ParticleManager:FireParticle(blink_effect_end, PATTACH_ABSORIGIN, self, {[0] = self:GetAbsOrigin()})
	end
	if bPlaySound == true then EmitSoundOn("DOTA_Item.BlinkDagger.NailedIt", self) end
end

local ignored_pfx_list = {}
ignored_pfx_list["particles/dev/empty_particle.vpcf"] = true
ignored_pfx_list["particles/ambient/fountain_danger_circle.vpcf"] = true
ignored_pfx_list["particles/range_indicator.vpcf"] = true
ignored_pfx_list["particles/units/heroes/hero_skeletonking/wraith_king_ambient_custom.vpcf"] = true
ignored_pfx_list["particles/generic_gameplay/radiant_fountain_regen.vpcf"] = true
ignored_pfx_list["particles/econ/courier/courier_wyvern_hatchling/courier_wyvern_hatchling_fire.vpcf"] = true
ignored_pfx_list["particles/units/heroes/hero_wisp/wisp_tether.vpcf"] = true
ignored_pfx_list["particles/units/heroes/hero_templar_assassin/templar_assassin_trap.vpcf"] = true
ignored_pfx_list["particles/econ/courier/courier_donkey_ti7/courier_donkey_ti7_ambient.vpcf"] = true
ignored_pfx_list["particles/econ/courier/courier_golden_roshan/golden_roshan_ambient.vpcf"] = true
ignored_pfx_list["particles/econ/courier/courier_platinum_roshan/platinum_roshan_ambient.vpcf"] = true
ignored_pfx_list["particles/econ/courier/courier_roshan_darkmoon/courier_roshan_darkmoon.vpcf"] = true
ignored_pfx_list["particles/econ/courier/courier_roshan_desert_sands/baby_roshan_desert_sands_ambient.vpcf"] = true
ignored_pfx_list["particles/econ/courier/courier_roshan_ti8/courier_roshan_ti8.vpcf"] = true
ignored_pfx_list["particles/econ/courier/courier_roshan_lava/courier_roshan_lava.vpcf"] = true
ignored_pfx_list["particles/econ/courier/courier_roshan_frost/courier_roshan_frost_ambient.vpcf"] = true
ignored_pfx_list["particles/econ/courier/courier_babyroshan_winter18/courier_babyroshan_winter18_ambient.vpcf"] = true
ignored_pfx_list["particles/econ/courier/courier_babyroshan_ti9/courier_babyroshan_ti9_ambient.vpcf"] = true
ignored_pfx_list["particles/units/heroes/hero_witchdoctor/witchdoctor_voodoo_restoration.vpcf"] = true
ignored_pfx_list["particles/units/heroes/hero_earth_spirit/espirit_stoneremnant.vpcf"] = true
ignored_pfx_list["particles/econ/items/tiny/tiny_prestige/tiny_prestige_tree_ambient.vpcf"] = true
ignored_pfx_list["particles/econ/events/ti7/ti7_hero_effect_1.vpcf"] = true
ignored_pfx_list["particles/econ/events/ti9/ti9_emblem_effect_loadout.vpcf"] = true
ignored_pfx_list["particles/econ/events/ti8/ti8_hero_effect.vpcf"] = true
ignored_pfx_list["particles/econ/events/ti7/ti7_hero_effect.vpcf"] = true
ignored_pfx_list["particles/econ/events/ti10/emblem/ti10_emblem_effect.vpcf"] = true
ignored_pfx_list["particles/units/heroes/hero_ember_spirit/ember_spirit_flameguard.vpcf"] = true
ignored_pfx_list["particles/act_2/campfire_flame.vpcf"] = true

-- Call custom functions whenever CreateParticle is being called anywhere
local original_CreateParticle = CScriptParticleManager.CreateParticle
CScriptParticleManager.CreateParticle = function(self, sParticleName, iAttachType, hParent, hCaster)
	local override = nil

	if hCaster then
		override = CustomNetTables:GetTableValue("battlepass_player", sParticleName..'_'..hCaster:GetPlayerOwnerID()) 
	end

	if override then
		sParticleName = override["1"]
	end

	-- call the original function
	local response = original_CreateParticle(self, sParticleName, iAttachType, hParent)

--	print("CreateParticle response:", sParticleName)

	if not ignored_pfx_list[sParticleName] then
		if hCaster and not hCaster:IsHero() then
			table.insert(CScriptParticleManager.ACTIVE_PARTICLES, {response, 0})
		else
			table.insert(CScriptParticleManager.ACTIVE_PARTICLES, {response, 0})
		end
	end

	return response
end

-- Call custom functions whenever CreateParticleForTeam is being called anywhere
local original_CreateParticleForTeam = CScriptParticleManager.CreateParticleForTeam
CScriptParticleManager.CreateParticleForTeam = function(self, sParticleName, iAttachType, hParent, iTeamNumber, hCaster)
--	print("Create Particle (override):", sParticleName, iAttachType, hParent, iTeamNumber, hCaster)

	local override = nil

	if hCaster then
		override = CustomNetTables:GetTableValue("battlepass_player", sParticleName..'_'..hCaster:GetPlayerOwnerID()) 
	end

	if override then
		sParticleName = override["1"]
	end

	-- call the original function
	local response = original_CreateParticleForTeam(self, sParticleName, iAttachType, hParent, iTeamNumber)

	return response
end

-- Call custom functions whenever CreateParticleForPlayer is being called anywhere
local original_CreateParticleForPlayer = CScriptParticleManager.CreateParticleForPlayer
CScriptParticleManager.CreateParticleForPlayer = function(self, sParticleName, iAttachType, hParent, hPlayer, hCaster)
--	print("Create Particle (override):", sParticleName, iAttachType, hParent, hPlayer, hCaster)

	local override = nil

	if hCaster then
		override = CustomNetTables:GetTableValue("battlepass_player", sParticleName..'_'..hCaster:GetPlayerOwnerID()) 
	end

	if override then
		sParticleName = override["1"]
	end

	-- call the original function
	local response = original_CreateParticleForPlayer(self, sParticleName, iAttachType, hParent, hPlayer)

	return response
end