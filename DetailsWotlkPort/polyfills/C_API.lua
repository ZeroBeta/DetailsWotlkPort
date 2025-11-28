    -- Polyfill for C_ APIs
if not C_Spell then C_Spell = {} end
if not C_UnitAuras then C_UnitAuras = {} end
if not C_SpecializationInfo then C_SpecializationInfo = {} end
if not C_AddOns then C_AddOns = {} end
if not C_ChallengeMode then C_ChallengeMode = {} end
if not C_CVar then C_CVar = {} end
if not C_SpellBook then C_SpellBook = {} end
if not C_EventUtils then C_EventUtils = {} end
if not Enum then Enum = {} end
if not Enum.SpellBookSpellBank then Enum.SpellBookSpellBank = {} end

-- CombatLogGetCurrentEventInfo doesn't exist on 3.3.5a; accept varargs from the event handler when available.
if not CombatLogGetCurrentEventInfo then
    local lastCleu
    function CombatLogGetCurrentEventInfo(...)
        if select("#", ...) > 0 then
            lastCleu = {...}
            return unpack(lastCleu)
        elseif lastCleu then
            return unpack(lastCleu)
        end
        return nil
    end
end

-- WotLK doesn't have BackdropTemplate; ignore it in CreateFrame to prevent nil frames.
-- CreateFrame compatibility:
-- Retail templates like BackdropTemplate or mixins don't exist on 3.3.5; retry without them if creation fails.
do
	local originalCreateFrame = CreateFrame
	local warnedBackdrop = false

	CreateFrame = function(frameType, name, parent, template, ...)
		-- First attempt: as requested (but strip retail-only BackdropTemplate on old clients)
		if template == "BackdropTemplate" or (type(template) == "table" and _G.BackdropTemplateMixin and template.mixin == _G.BackdropTemplateMixin) then
			template = nil
			if not warnedBackdrop then
				warnedBackdrop = true
				-- Uncomment for debugging: print("Details: BackdropTemplate stripped for", tostring(name) or "frame")
			end
		end

		local ok, frame = pcall(originalCreateFrame, frameType, name, parent, template, ...)
		if ok and frame then
			return frame
		end

		-- Retry with a capitalized frame type and no template
		local safeType = type(frameType) == "string" and (frameType:sub(1,1):upper() .. frameType:sub(2):lower()) or frameType
		ok, frame = pcall(originalCreateFrame, safeType, name, parent, nil, ...)
		if ok and frame then
			return frame
		end

		-- Final fallback: plain Frame
		ok, frame = pcall(originalCreateFrame, "Frame", name, parent, nil, ...)
		if ok then
			return frame
		end

		return nil
	end
end

-- RegisterAddonMessagePrefix polyfill - make it global if it doesn't exist
if not RegisterAddonMessagePrefix then
    if C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix then
        RegisterAddonMessagePrefix = function(prefix)
            return C_ChatInfo.RegisterAddonMessagePrefix(prefix)
        end
    else
        -- No-op for very old clients that don't have this function
        RegisterAddonMessagePrefix = function(prefix)
            return true
        end
    end
end

-- C_UnitAuras polyfill
if not C_UnitAuras.GetAuraDataByIndex then
    C_UnitAuras.GetAuraDataByIndex = function(unit, index, filter)
        -- In 3.3.5a, use UnitAura/UnitBuff/UnitDebuff
        local name, icon, count, dispelType, duration, expirationTime, source, isStealable, 
              nameplateShowPersonal, spellId, canApplyAura, isBossDebuff, castByPlayer, 
              nameplateShowAll, timeMod = UnitAura(unit, index, filter)
        
        if not name then
            return nil
        end
        
        -- Return as a table matching the modern API structure
        return {
            name = name,
            icon = icon,
            applications = count,
            dispelName = dispelType,
            duration = duration,
            expirationTime = expirationTime,
            sourceUnit = source,
            isStealable = isStealable,
            nameplateShowPersonal = nameplateShowPersonal,
            spellId = spellId,
            canApplyAura = canApplyAura,
            isBossAura = isBossDebuff,
            isFromPlayerOrPlayerPet = castByPlayer,
            nameplateShowAll = nameplateShowAll,
        }
    end
end

-- sendChatMessage stub for LibOpenRaid error logging
if not sendChatMessage then
    sendChatMessage = function(...)
        -- In 3.3.5a, just print to chat for debugging
        print(...)
    end
end

-- C_MythicPlus polyfill
if not C_MythicPlus then C_MythicPlus = {} end
if not C_MythicPlus.GetOwnedKeystoneLevel then
    C_MythicPlus.GetOwnedKeystoneLevel = function() return 0 end
end
if not C_MythicPlus.GetOwnedKeystoneMapID then
    C_MythicPlus.GetOwnedKeystoneMapID = function() return 0 end
end
if not C_MythicPlus.GetOwnedKeystoneChallengeMapID then
    C_MythicPlus.GetOwnedKeystoneChallengeMapID = function() return 0 end
end

-- C_PlayerInfo polyfill
if not C_PlayerInfo then C_PlayerInfo = {} end
if not C_PlayerInfo.GetPlayerMythicPlusRatingSummary then
    C_PlayerInfo.GetPlayerMythicPlusRatingSummary = function(unit)
        return {currentSeasonScore = 0}
    end
end

-- LibOpenRaid mythic+ data (WotLK doesn't have mythic+)
if not LIB_OPEN_RAID_MYTHIC_PLUS_CURRENT_SEASON then
    LIB_OPEN_RAID_MYTHIC_PLUS_CURRENT_SEASON = {}
end

-- C_CVar (Console Variables)
-- In 3.3.5a, we can't dynamically register CVars, so we'll use a simple table to store them
local registeredCVars = {}

function C_CVar.RegisterCVar(name, defaultValue)
    -- In 3.3.5a, we can't actually register CVars, so we just track them
    if not registeredCVars[name] then
        registeredCVars[name] = defaultValue or ""
    end
end

function C_CVar.GetCVar(name)
    -- Try to get the actual CVar first (for built-in CVars)
    local value = GetCVar(name)
    if value then
        return value
    end
    -- Fall back to our registered table
    return registeredCVars[name]
end

function C_CVar.SetCVar(name, value)
    -- Try to set the actual CVar first (for built-in CVars)
    local success = pcall(SetCVar, name, value)
    if not success then
        -- If it fails (because the CVar doesn't exist), store it in our table
        registeredCVars[name] = value
    end
end

-- C_SpellBook
function C_SpellBook.GetSpellBookSkillLineInfo(index)
    local name, texture, offset, numSlots = GetSpellTabInfo(index)
    if not name then return nil end
    return {
        name = name,
        iconID = texture,
        itemIndexOffset = offset,
        numSpellBookItems = numSlots,
        isGuild = false,
        offSpecID = 0,
        shouldHide = false,
        specID = 0
    }
end

function C_SpellBook.HasPetSpells()
    local numPetSpells, petToken = HasPetSpells()
    return numPetSpells ~= nil
end

function C_SpellBook.GetNumSpellBookSkillLines()
    local count = 0
    for i = 1, 20 do
        local name = GetSpellTabInfo(i)
        if name then
            count = count + 1
        else
            break
        end
    end
    return count
end

-- Enum.SpellBookSpellBank (for 3.3.5a compatibility)
Enum.SpellBookSpellBank.Player = "player"
Enum.SpellBookSpellBank.Pet = "pet"

-- C_EventUtils
function C_EventUtils.IsEventValid(event)
    -- In 3.3.5a, we can't dynamically check if events are valid
    -- Return true for common events, false for modern-only events
    local modernOnlyEvents = {
        "SCENARIO_COMPLETED",
        "CHALLENGE_MODE_START",
        "CHALLENGE_MODE_COMPLETED",
        "PET_BATTLE_OPENING_START",
        "PET_BATTLE_CLOSE",
    }
    
    for _, modernEvent in ipairs(modernOnlyEvents) do
        if event == modernEvent then
            return false
        end
    end
    
    return true
end

-- C_Spell
function C_Spell.GetSpellInfo(spellID)
    local name, rank, icon, cost, isFunnel, powerType, castTime, minRange, maxRange = GetSpellInfo(spellID)
    if not name then return nil end
    return {
        name = name,
        iconID = icon,
        castTime = castTime,
        minRange = minRange,
        maxRange = maxRange,
        spellID = spellID,
        originalIconID = icon
    }
end

function C_Spell.IsSpellPassive(spellID)
    return IsPassiveSpell(spellID)
end

function C_Spell.GetOverrideSpell(spellID)
    return GetSpellInfo(spellID) -- Fallback
end

-- C_UnitAuras
function C_UnitAuras.GetBuffDataByIndex(unit, index, filter)
    local name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, shouldConsolidate, spellId = UnitBuff(unit, index, filter)
    if not name then return nil end
    return {
        name = name,
        icon = icon,
        count = count,
        debuffType = debuffType,
        duration = duration,
        expirationTime = expirationTime,
        sourceUnit = unitCaster,
        isStealable = isStealable,
        spellId = spellId,
        isHelpful = true
    }
end

function C_UnitAuras.GetDebuffDataByIndex(unit, index, filter)
    local name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, shouldConsolidate, spellId = UnitDebuff(unit, index, filter)
    if not name then return nil end
    return {
        name = name,
        icon = icon,
        count = count,
        debuffType = debuffType,
        duration = duration,
        expirationTime = expirationTime,
        sourceUnit = unitCaster,
        isStealable = isStealable,
        spellId = spellId,
        isHarmful = true
    }
end

-- C_SpecializationInfo
function C_SpecializationInfo.GetSpecialization()
    -- 3.3.5a doesn't have specializations in the modern sense.
    -- We can try to guess based on talent points.
    return 1 -- Default to spec 1 for now
end

function C_SpecializationInfo.GetSpecializationInfo(specIndex)
    return 1, "Unknown", "Unknown", "Interface\\Icons\\INV_Misc_QuestionMark", "DAMAGER", "Intellect"
end

function C_SpecializationInfo.GetSpecializationRole(specIndex)
    return "DAMAGER" -- Default
end

-- C_AddOns
function C_AddOns.GetAddOnMetadata(addonName, field)
    return GetAddOnMetadata(addonName, field)
end

function C_AddOns.IsAddOnLoaded(addonName)
    if IsAddOnLoaded then
        return IsAddOnLoaded(addonName)
    end
    -- Fallback: assume not loaded
    return false
end

function C_AddOns.LoadAddOn(addonName)
    if LoadAddOn then
        return LoadAddOn(addonName)
    end
    -- No loader available; mimic failure return
    return false, "NO_LOADADDON_API"
end

-- C_ChallengeMode (Not present in 3.3.5a)
function C_ChallengeMode.GetActiveChallengeMapID() return nil end
function C_ChallengeMode.GetActiveKeystoneInfo() return nil end
function C_ChallengeMode.IsChallengeModeActive() return false end
