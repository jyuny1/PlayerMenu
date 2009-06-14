local _, class = UnitClass("player")
local Spell = {}
local SpellIgnoreClearTarget = {}
local v

if class == "PRIEST" then
	Spell = {
		1243,		--Power Word: Fortitude
		21562,		--Prayer of Fortitude
		17,			--Power Word: Shield
		14752,		--Divine Spirit
		27681,		--Prayer of Spirit
		976,		--Shadow Protection
		27683,		--Prayer of Shadow Protection
		10060,		--Power Infusion
		552,		--Abolish Disease
		528,		--Cure Disease
		527,		--Dispel Magic
		2006,		--Resurrection
	}
elseif class == "DRUID" then
	Spell = {
		21849,		--Gift of the Wild
		1126,		--Mark of the Wild
		467,		--Thorns
		2893,		--Abolish Poison
		29166,		--Innervate
		2782,		--Remove Curse
		20484,		--Rebirth
	}
elseif class == "PALADIN" then
	Spell = {
		1044,		--Blessing of Freedom
		20217,		--Blessing of Kings
		19977,		--Blessing of Light
		19740,		--Blessing of Might
		1022,		--Blessing of Protection
		6940,		--Blessing of Sacrifice
		1038,		--Blessing of Salvation
		20911,		--Blessing of Sanctuary
		19742,		--Blessing of Wisdom
		25898,		--Greater Blessing of Kings
		25890,		--Greater Blessing of Light
		25782,		--Greater Blessing of Might
		25895,		--Greater Blessing of Salvation
		25899,		--Greater Blessing of Sanctuary
		25894,		--Greater Blessing of Wisdom
		19752,		--Divine Intervention
		7328,		--Redemption
		4987,		--Cleanse
	}
elseif class == "WARLOCK" then
	Spell = {
		5697,		--Unending Breath
		698,		--Ritual of Summoning
	}
	SpellIgnoreClearTarget = {
		698,		--Ritual of Summoning
	}
elseif class == "MAGE" then
	Spell = {
		1459,		--Arcane Intellect
		23028,		--Arcane Brilliance
		604,		--Dampen Magic
		1008,		--Amplify Magic
		475,		--Remove Lesser Curse
	}
elseif class == "SHAMAN" then
	Spell = {
		131,		--Water Breathing
		526,		--Cure Poison
		2870,		--Cure Disease
	}
end

PlayerMenu.Spell = {}
PlayerMenu.SpellIgnoreClearTarget = {}

for _,v in ipairs(Spell) do
	local name, _, icon = GetSpellInfo(v)
	--PlayerMenu.Spell[name] = icon
end

for _,v in ipairs(SpellIgnoreClearTarget) do
	local name = GetSpellInfo(v)
	PlayerMenu.SpellIgnoreClearTarget[name] = 1
end
