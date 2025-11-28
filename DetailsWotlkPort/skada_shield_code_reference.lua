-- This file contains the corrected Skada-style absorption tracking code section
-- that should replace lines ~157-230 in parser.lua

-- Skada-style absorption tracking
-- Active shields:indexed by target, stores expiration time
Details.ActiveShields = Details.ActiveShields or {}
-- Structure: [targetKey][spellid][sourceName] = {srcGUID, srcFlags, school, points, amount, expiresAt, isFull}

-- Learned maximum shield amounts (for capped shields like PW:S)
Details.LearnedShieldAmounts = Details.LearnedShieldAmounts or {}
-- Structure: [sourceName][spellid] = maxAmount

-- Recent heals for Divine Aegis calculation
Details.RecentHeals = Details.RecentHeals or {}
-- Structure: [targetName][sourceName] = {ts, amount}

-- Shield spell ID classifications
local mage_ward = {
	[543] = true, [8457] = true, [8458] = true, [10223] = true, [10225] = true, [27128] = true, [43010] = true,
	[1100543] = true, [1108457] = true, [1108458] = true, [1110223] = true, [1110225] = true, [1127128] = true, [1143010] = true,
	[6143] = true, [8461] = true, [8462] = true, [10177] = true, [28609] = true, [32796] = true, [43012] = true,
	[1106143] = true, [1108461] = true, [1108462] = true, [1110177] = true, [1128609] = true, [1132796] = true, [1143012] = true,
}

local warlock_shadow_ward = {
	[6229] = true, [11739] = true, [11740] = true, [28610] = true, [47890] = true, [47891] = true,
	[1106229] = true, [1111739] = true, [1111740] = true, [1128610] = true, [1147890] = true, [1147891] = true,
}

local mage_ice_barrier = {
	[11426] = true, [13031] = true, [13032] = true, [13033] = true, [27134] = true, [33245] = true, [33405] = true, [43038] = true, [43039] = true,
	[1111426] = true, [1113031] = true, [1113032] = true, [1113033] = true, [1127134] = true, [1133405] = true, [1143038] = true, [1143039] = true,
}

local warlock_sacrifice = {
	[7812] = true, [19438] = true, [19440] = true, [19441] = true, [19442] = true, [19443] = true, [27273] = true, [47985] = true, [47986] = true,
	[1107812] = true, [1119438] = true, [1119440] = true, [1119441] = true, [1119442] = true, [1119443] = true, [1127273] = true, [1147985] = true, [1147986] = true,
}

local priest_divine_aegis = {
	[47509] = true, [47511] = true, [47515] = true, [47753] = true, [54704] = true,
	[157509] = true, [157511] = true, [157515] = true, [157753] = true, [164704] = true,
}

-- Shield spell database with durations and caps
local absorbSpellData = {
	-- Divine Aegis - stackable, calculated from heals
	[47509] = {dur = 12, stackable = true, calc = "divine_aegis"},
	[47511] = {dur = 12, stackable = true, calc = "divine_aegis"},
	[47515] = {dur = 12, stackable = true, calc = "divine_aegis"},
	[47753] = {dur = 12, stackable = true, calc = "divine_aegis"},
	[54704] = {dur = 12, stackable = true, calc = "divine_aegis"},
	[157509] = {dur = 12, stackable = true, calc = "divine_aegis"},
	[157511] = {dur = 12, stackable = true, calc = "divine_aegis"},
	[157515] = {dur = 12, stackable = true, calc = "divine_aegis"},
	[157753] = {dur = 12, stackable = true, calc = "divine_aegis"},
	[164704] = {dur = 12, stackable = true, calc = "divine_aegis"},
	
	-- Vala'nyr - stackable, calculated from heals
	[64413] = {dur = 8, stackable = true, calc = "valannyr", cap = 20000},
	
	-- Anti-Magic Shell/Zone - based on max health
	[48707] = {dur = 5, calc = "ams"},
	[51052] = {dur = 10, calc = "ams"},
	
	-- Power Word: Shield - standard capped shield
	[17] = {dur = 30, cap = 10000},
	[1110901] = {dur = 30, cap = 10000}, -- Ascension custom
}

local function GetShieldTargetKey(targetSerial, targetName)
	if (targetSerial and targetSerial ~= "") then
		return targetSerial
	end
	return targetName
end

-- Sort shields by Ascension's absorption priority
-- Returns true if shield 'a' should consume before shield 'b'
-- This matches the game engine's AbsorbAuraOrderPred
local function SortShieldsByPriority(a, b)
	local a_spellid, b_spellid = a.spellid, b.spellid
	
	if a_spellid == b_spellid then
		return (a.ts > b.ts) -- newer applied first for same spell
	end
	
	-- Twin Val'kyr shields (highest priority)
	if a_spellid == 65686 then return false end
	if b_spellid == 65686 then return true end
	if a_spellid == 65684 then return false end
	if b_spellid == 65684 then return true end
	
	-- Wards (Fire/Frost/Shadow Ward)
	if warlock_shadow_ward[a_spellid] or mage_ward[a_spellid] then return false end
	if warlock_shadow_ward[b_spellid] or mage_ward[b_spellid] then return true end
	
	-- Sacred Shield
	if a_spellid == 58597 then return false end
	if b_spellid == 58597 then return true end
	
	-- Fel Blossom
	if a_spellid == 28527 then return false end
	if b_spellid == 28527 then return true end
	
	-- Divine Aegis (all ranks)
	if priest_divine_aegis[a_spellid] then return false end
	if priest_divine_aegis[b_spellid] then return true end
	
	-- Ice Barrier
	if mage_ice_barrier[a_spellid] then return false end
	if mage_ice_barrier[b_spellid] then return true end
	
	-- Sacrifice
	if warlock_sacrifice[a_spellid] then return false end
	if warlock_sacrifice[b_spellid] then return true end
	
	-- Custom Ascension shields
	if a_spellid == 881472 then return false end -- Dominant Word: Shield
	if b_spellid == 881472 then return true end
	if a_spellid == 84380 then return false end -- Armor of Faith
	if b_spellid == 84380 then return true end
	
	-- Default: newer timestamp = lower priority
	return (a.ts > b.ts)
end
