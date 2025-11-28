-- Polyfill for GUID handling in WotLK 3.3.5a
if not Details then return end

-- WotLK GUIDs are hex strings (e.g., 0xF130001234005678)
-- High part contains the type, low part contains the ID/counter
-- We need to extract the NPC ID from this hex string

function Details:GetNpcIdFromGuid(guid)
    if not guid then return 0 end
    
    -- Check if it's already a modern GUID (just in case)
    if type(guid) == "string" and guid:find("-") then
        return tonumber(guid:match("^[^%-]*%-[^%-]*%-[^%-]*%-[^%-]*%-[^%-]*%-([^%-]*)")) or 0
    end

    -- WotLK Hex GUID parsing
    local guidNumber = tonumber(guid)
    if not guidNumber then return 0 end

    -- Mask for Creature/Vehicle
    -- Based on Mangos/TrinityCore structure
    -- HighGUID: 0xF130 (Creature) or 0xF150 (Vehicle)
    -- The NPC ID is in the middle bits of the low part, but for addons, 
    -- we usually parse the hex string directly if possible, or use bitwise ops.
    
    -- In Lua 5.1 (WoW 3.3.5a), we don't have bit32 library.
    -- We can parse the hex string.
    -- Format: 0x(Type)(Zero)(ID)(Counter) roughly? 
    -- Actually, standard WotLK GUID: 0xF130000123004567
    -- F130 = Type (Creature)
    -- 000123 = Entry ID (Hex) -> 291 decimal
    -- 004567 = Spawn ID
    
    -- Let's try to extract the entry ID from the hex string
    -- 0xF130 000123 004567
    -- 18 chars total (0x + 16 hex digits)
    
    if guid:len() == 18 then
        local typeStr = guid:sub(3, 6)
        if typeStr == "F130" or typeStr == "F150" then
            local entryHex = guid:sub(7, 12)
            return tonumber(entryHex, 16) or 0
        end
    end
    
    return 0
end
