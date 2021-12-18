item_tome_small = item_tome_small or class({})

function item_tome_small:OnSpellStart()
	if not IsServer() then return end

	self:GetCaster():IncrementAttributes(self:GetSpecialValueFor("stat_bonus"))
	self:SpendCharge()
end

item_tome_big = item_tome_big or class({})

function item_tome_big:OnSpellStart()
	if not IsServer() then return end

	self:GetCaster():IncrementAttributes(self:GetSpecialValueFor("stat_bonus"))
	self:SpendCharge()
end

item_tome_of_power = item_tome_of_power or class({})

function item_tome_of_power:OnSpellStart()
	if not IsServer() then return end

	if self:GetCaster():GetLevel() < 30 then
		self:GetCaster():AddExperience(XP_PER_LEVEL_TABLE[self:GetCaster():GetLevel()+1]-XP_PER_LEVEL_TABLE[self:GetCaster():GetLevel()] , DOTA_ModifyXP_Unspecified , false, true)
		self:SpendCharge()
	else
		Notifications:Bottom(self:GetCaster():GetPlayerID(), {text="Hero at max level!", duration=5.0, style={color="white"}})
		self:StartCooldown(0.0)
	end
end

modifier_tome_of_stats = modifier_tome_of_stats or class({})

function modifier_tome_of_stats:IsHidden() return true end
function modifier_tome_of_stats:IsPurgable() return false end
function modifier_tome_of_stats:IsPurgeException() return false end
function modifier_tome_of_stats:IsDebuff() return false end
function modifier_tome_of_stats:RemoveOnDeath() return false end

function modifier_tome_of_stats:DeclareFunctions() return {
	MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
	MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
	MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
} end

function modifier_tome_of_stats:GetModifierBonusStats_Strength() return self:GetStackCount() end
function modifier_tome_of_stats:GetModifierBonusStats_Agility() return self:GetStackCount() end
function modifier_tome_of_stats:GetModifierBonusStats_Intellect() return self:GetStackCount() end
