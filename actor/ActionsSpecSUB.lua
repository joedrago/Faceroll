-----------------------------------------------------------------------------------------
-- Outlaw Rogue

-- Actions to Keybind table
local actions = {
    ["shadowstrike"] = "1",
    ["backstab"] = "z",
    ["symbolsofdeath"] = "q",
    ["shadowdance"] = "f",
    ["shadowblades"] = "4",
    ["flagellation"] = "2",
    ["coldblood"] = "pad4",
    ["rupture"] = "pad8",
    ["eviscerate"] = "pad7",
    ["secrettechnique"] = "x",
    ["stealth"] = "9",
    ["vanish"] = "v",
}

local bitMap = {
    -- player/base class state
    ["combat"]                      = 0x1,
    ["cp6"]                         = 0x2,
    ["stealth"]                     = 0x4,

    -- buffs
    ["shadowblades_active"]         = 0x10,
    ["symbolsofdeath_active"]       = 0x20,
    ["premeditation_active"]        = 0x40,
    ["shadowdance_active"]          = 0x80,
    ["coldblood_active"]            = 0x100,
    ["flagellation_active"]         = 0x200,
    ["flagellation_maxed"]          = 0x400,
    ["dansemacabre_low"]            = 0x800,

    -- cds
    ["shadowblades_available"]      = 0x1000,
    ["symbolsofdeath_available"]    = 0x2000,
    ["shadowdance_available"]       = 0x4000,
    ["coldblood_available"]         = 0x8000,
    ["flagellation_available"]      = 0x10000,
    ["flagellation_soon"]           = 0x20000,
    ["vanish_available"]            = 0x40000,
    ["secrettechnique_available"]  = 0x80000,
    ["secrettechnique_soon"]       = 0x100000,

    -- target debuffs
    ["should_rupture"]              = 0x200000,
}

local function nextAction(action, bits)
    -- player/base class state
    local combat = bitand(bits, bitMap["combat"]) > 0
    local cp6 = bitand(bits, bitMap["cp6"]) > 0
    local stealth = bitand(bits, bitMap["stealth"]) > 0
    
    -- buffs
    local shadowblades_active = bitand(bits, bitMap["shadowblades_active"]) > 0
    local symbolsofdeath_active = bitand(bits, bitMap["symbolsofdeath_active"]) > 0
    local premeditation_active = bitand(bits, bitMap["premeditation_active"]) > 0
    local shadowdance_active = bitand(bits, bitMap["shadowdance_active"]) > 0
    local coldblood_active = bitand(bits, bitMap["coldblood_active"]) > 0
    local flagellation_active = bitand(bits, bitMap["flagellation_active"]) > 0
    local flagellation_maxed = bitand(bits, bitMap["flagellation_maxed"]) > 0
    local dansemacabre_low = bitand(bits, bitMap["dansemacabre_low"]) > 0
    
    -- cds
    local shadowblades_available = bitand(bits, bitMap["shadowblades_available"]) > 0
    local symbolsofdeath_available = bitand(bits, bitMap["symbolsofdeath_available"]) > 0
    local shadowdance_available = bitand(bits, bitMap["shadowdance_available"]) > 0
    local coldblood_available = bitand(bits, bitMap["coldblood_available"]) > 0
    local flagellation_available = bitand(bits, bitMap["flagellation_available"]) > 0
    local flagellation_soon = bitand(bits, bitMap["flagellation_soon"]) > 0
    local vanish_available = bitand(bits, bitMap["vanish_available"]) > 0
    local secrettechnique_available = bitand(bits, bitMap["secrettechnique_available"]) > 0
    local secrettechnique_soon = bitand(bits, bitMap["secrettechnique_soon"]) > 0

    -- target debuffs
    local should_rupture = bitand(bits, bitMap["should_rupture"]) > 0

    local useCooldowns = action == ACTION_ST

    if flagellation_active and shadowblades_available and useCooldowns then
        return actions["shadowblades"]
    end

    if cp6 then
        -- flagellation should be fired on cd
        if flagellation_available and not flagellation_active and useCooldowns then
            return actions["flagellation"]
        end

        -- shadow dance finishers (only eviscerate and secret techniques, we want secret techniques to be the 2nd finisher generally)
        if shadowdance_active then
            -- symbols
            if not symbolsofdeath_active then
                if flagellation_active and flagellation_maxed then
                    if secrettechnique_soon or secrettechnique_available then
                        return actions["symbolsofdeath"]
                    end

                    -- no op; don't want to symbols too early
                elseif not flagellation_active or not flagellation_maxed then
                    return actions["symbolsofdeath"]
                end
            end

            -- in dance finishers
            if secrettechnique_available then
                print("secret technique is available")
                if coldblood_available and flagellation_maxed then
                    print("firing cold blood")
                    return actions["coldblood"]
                end
                return actions["secrettechnique"]
            else
                print("secret technique not available")
                return actions["eviscerate"]
            end
        end

        -- finisher out of dance
        if should_rupture then
            return actions["rupture"]
        end

        return actions["eviscerate"]
    else
        if shadowdance_active then
            if premeditation_active then
                return actions["backstab"]
            else
                return actions["shadowstrike"]
            end
        elseif shadowdance_available and not stealth then
            if not flagellation_soon then
                return actions["shadowdance"]
            end
        end

        if stealth then
            return actions["shadowstrike"]
        end

        -- Build CP
        return actions["backstab"]
    end

    return nil

end

return nextAction
