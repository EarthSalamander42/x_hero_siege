LinkLuaModifier("modifier_wisp_passive", "abilities/heroes/hero_wisp.lua", LUA_MODIFIER_MOTION_NONE)

wisp_pick_random_hero = wisp_pick_random_hero or class({})

function wisp_pick_random_hero:OnSpellStart()
	if not IsServer() then return end

	local random = RandomInt(1, #HEROLIST + 1) -- +1 for Weekly hero
	local IsAvailableHero = Entities:FindByName(nil, "trigger_hero_"..random)
	local difficulty = GameRules:GetCustomGameDifficulty()
	local hero_name

	if random == 12 then
		print("This hero is disabled! Re-rolls Random Hero")
		self:OnSpellStart()
		return
	elseif random == #HEROLIST + 1 then
		hero_name = WeekHero
	end

	hero_name = "npc_dota_hero_"..HEROLIST[random]

	if IsAvailableHero then
		UTIL_Remove(IsAvailableHero)
	end

	local particle = ParticleManager:CreateParticle(CustomNetTables:GetTableValue("battlepass_item_effects", tostring(self:GetCaster():GetPlayerID())).tome_stats["effect1"], PATTACH_ABSORIGIN_FOLLOW, self:GetCaster())
	ParticleManager:SetParticleControl(particle, 0, self:GetCaster():GetAbsOrigin())

	EmitSoundOnClient("ui.trophy_levelup", PlayerResource:GetPlayer(self:GetCaster():GetPlayerID()))

	self:GetCaster():AddNewModifier(self:GetCaster(), nil, "modifier_command_restricted", {})

	Notifications:Bottom(self:GetCaster():GetPlayerOwnerID(), {hero=hero_name, duration = 5.0})
	Notifications:Bottom(self:GetCaster():GetPlayerOwnerID(), {text="HERO: ", duration = 5.0, style={color="white"}, continue=true})
	Notifications:Bottom(self:GetCaster():GetPlayerOwnerID(), {text="#npc_dota_hero_"..HEROLIST[random], duration = 5.0, style={color="white"}, continue=true})

	local newHero = PlayerResource:ReplaceHeroWith(self:GetCaster():GetPlayerID(), hero_name, STARTING_GOLD[difficulty] * 2, 0)
	StartingItems(self:GetCaster(), newHero)

	Timers:CreateTimer(0.1, function()
		if self and self.GetCaster and IsValidEntity(self:GetCaster()) then
			UTIL_Remove(self:GetCaster())
		end
	end)
end

wisp_passives = wisp_passives or class({})

function wisp_passives:GetIntrinsicModifierName()
	return "modifier_wisp_passive"
end

modifier_wisp_passive = modifier_wisp_passive or class({})

function modifier_wisp_passive:IsHidden() return true end

function modifier_wisp_passive:CheckState() return {
	[MODIFIER_STATE_UNSELECTABLE] = true,
	[MODIFIER_STATE_NO_TEAM_MOVE_TO] = true,
	[MODIFIER_STATE_NO_TEAM_SELECT] = true,
	[MODIFIER_STATE_ATTACK_IMMUNE] = true,
	[MODIFIER_STATE_MAGIC_IMMUNE] = true,
} end

function modifier_wisp_passive:OnCreated()
	if not IsServer() then return end

	local donator_level = api:GetDonatorStatus(self:GetParent():GetPlayerID())

	print("Donator level:", donator_level)
	if donator_level then
		local stack_count = {}
		stack_count[0] = ""
		stack_count[1] = "_3"
		stack_count[2] = ""
		stack_count[3] = ""
		stack_count[4] = "_3"
		stack_count[5] = "_4"
		stack_count[6] = "_6"

		print("Donator string pfx:", stack_count[donator_level])
		if stack_count[donator_level] then
			local vip_effect = ParticleManager:CreateParticle("particles/status_fx/status_effect_holdout_borrowed_time"..stack_count[donator_level]..".vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
			ParticleManager:SetParticleControl(vip_effect, 0, self:GetParent():GetAbsOrigin())
			ParticleManager:SetParticleControl(vip_effect, 1, self:GetParent():GetAbsOrigin())

			local vip_effect2 = ParticleManager:CreateParticle("particles/units/heroes/hero_abaddon/holdout_borrowed_time"..stack_count[donator_level]..".vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
			ParticleManager:SetParticleControl(vip_effect2, 0, self:GetParent():GetAbsOrigin())
			ParticleManager:SetParticleControl(vip_effect2, 1, self:GetParent():GetAbsOrigin())
		end
	end
end

--[[
function WispEffects(caster)
	if caster:GetUnitName() == "npc_dota_hero_wisp" then
		local donator_level = api:GetDonatorStatus(caster:GetPlayerID())

		if donator_level == 1 then
			local vip_effect = ParticleManager:CreateParticle("particles/status_fx/status_effect_holdout_borrowed_time_3.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
			ParticleManager:SetParticleControl(vip_effect, 0, caster:GetAbsOrigin())
			ParticleManager:SetParticleControl(vip_effect, 1, caster:GetAbsOrigin())

			local vip_effect2 = ParticleManager:CreateParticle("particles/units/heroes/hero_abaddon/holdout_borrowed_time_3.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
			ParticleManager:SetParticleControl(vip_effect2, 0, caster:GetAbsOrigin())
			ParticleManager:SetParticleControl(vip_effect2, 1, caster:GetAbsOrigin())
		elseif donator_level == 2 or donator_level == 3 then
			local vip_effect = ParticleManager:CreateParticle("particles/status_fx/status_effect_holdout_borrowed_time.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
			ParticleManager:SetParticleControl(vip_effect, 0, caster:GetAbsOrigin())
			ParticleManager:SetParticleControl(vip_effect, 1, caster:GetAbsOrigin())

			local vip_effect2 = ParticleManager:CreateParticle("particles/units/heroes/hero_abaddon/holdout_borrowed_time.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
			ParticleManager:SetParticleControl(vip_effect2, 0, caster:GetAbsOrigin())
			ParticleManager:SetParticleControl(vip_effect2, 1, caster:GetAbsOrigin())
		elseif donator_level == 4 then
			local vip_effect = ParticleManager:CreateParticle("particles/status_fx/status_effect_holdout_borrowed_time_3.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
			ParticleManager:SetParticleControl(vip_effect, 0, caster:GetAbsOrigin())
			ParticleManager:SetParticleControl(vip_effect, 1, caster:GetAbsOrigin())

			local vip_effect2 = ParticleManager:CreateParticle("particles/units/heroes/hero_abaddon/holdout_borrowed_time_3.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
			ParticleManager:SetParticleControl(vip_effect2, 0, caster:GetAbsOrigin())
			ParticleManager:SetParticleControl(vip_effect2, 1, caster:GetAbsOrigin())
		elseif donator_level == 5 then
			local vip_effect = ParticleManager:CreateParticle("particles/status_fx/status_effect_holdout_borrowed_time_4.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
			ParticleManager:SetParticleControl(vip_effect, 0, caster:GetAbsOrigin())
			ParticleManager:SetParticleControl(vip_effect, 1, caster:GetAbsOrigin())

			local vip_effect2 = ParticleManager:CreateParticle("particles/units/heroes/hero_abaddon/holdout_borrowed_time_4.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
			ParticleManager:SetParticleControl(vip_effect2, 0, caster:GetAbsOrigin())
			ParticleManager:SetParticleControl(vip_effect2, 1, caster:GetAbsOrigin())
		elseif donator_level == 6 then
			local vip_effect = ParticleManager:CreateParticle("particles/status_fx/status_effect_holdout_borrowed_time_2.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
			ParticleManager:SetParticleControl(vip_effect, 0, caster:GetAbsOrigin())
			ParticleManager:SetParticleControl(vip_effect, 1, caster:GetAbsOrigin())

			local vip_effect2 = ParticleManager:CreateParticle("particles/units/heroes/hero_abaddon/holdout_borrowed_time_2.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
			ParticleManager:SetParticleControl(vip_effect2, 0, caster:GetAbsOrigin())
			ParticleManager:SetParticleControl(vip_effect2, 1, caster:GetAbsOrigin())
		end
	end
end
--]]
