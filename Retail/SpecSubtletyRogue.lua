-----------------------------------------------------------------------------------------
-- Subtlety Rogue

if Faceroll == nil then
    _, Faceroll = ...
end

local spec = Faceroll.createSpec("SUB", "660066", "ROGUE-3")

spec.buffs = {
    "Shadow Blades",
    "Symbols of Death",
    "Flagellation",
    "Premeditation",
    "Shadow Dance",
    "Stealth",
    "Vanish",
    "Cold Blood",
    "Danse Macabre",
}

-----------------------------------------------------------------------------------------
-- States

spec.overlay = {
    -- player/base class state
    "combat",
    "cp6",
    "stealth",

    -- buffs
    "shadowblades_active",
    "symbolsofdeath_active",
    "premeditation_active",
    "shadowdance_active",
    "coldblood_active",
    "flagellation_active",
    "flagellation_maxed",
    "dansemacabre_low",

    -- cds
    "shadowblades_available",
    "symbolsofdeath_available",
    "shadowdance_available",
    "coldblood_available",
    "flagellation_available",
    "flagellation_soon",
    "vanish_available",
    "secrettechnique_available",
    "secrettechnique_soon",

    -- target debuffs
    "should_rupture",
}

spec.calcState = function(state)
    local cp = GetComboPoints("player", "target")
    -- print("energy " .. energy .. " cp " .. cp)

    -- player/base class state
    if Faceroll.inCombat() then
        state.combat = true
    end
    if cp >= 6 then
        state.cp6 = true
    end
    if Faceroll.isBuffActive("Stealth") or Faceroll.isBuffActive("Vanish") then
        state.stealth = true
    end

    -- buffs
    if Faceroll.isBuffActive("Shadow Blades") then
        state.shadowblades_active = true
    end
    if Faceroll.isBuffActive("Symbols of Death") then
        state.symbolsofdeath_active = true
    end
    if Faceroll.isBuffActive("Premeditation") then
        state.premeditation_active = true
    end
    if Faceroll.isBuffActive("Shadow Dance") then
        state.shadowdance_active = true
    end
    if Faceroll.isBuffActive("Cold Blood") then
        state.coldblood_active = true
    end
    if Faceroll.isBuffActive("Flagellation") then
        state.flagellation_active = true
    end
    if Faceroll.getBuffStacks("Flagellation") >= 30 then
        state.flagellation_maxed = true
    end
    if Faceroll.getBuffStacks("Danse Macabre") <= 2 then
        state.dansemacabre_low = true
    end

    -- cds
    if Faceroll.isSpellAvailable("Shadow Blades") then
        state.shadowblades_available = true
    end
    if Faceroll.getSpellCharges("Symbols of Death") > 0 then
        state.symbolsofdeath_available = true
    end
    if Faceroll.getSpellCharges("Shadow Dance") > 0 then
        state.shadowdance_available = true
    end
    if Faceroll.isSpellAvailable("Cold Blood") then
        state.coldblood_available = true
    end
    if Faceroll.isSpellAvailable("flagellation") then
        state.flagellation_available = true
    end
    if Faceroll.getSpellCooldown("flagellation") < 30 and Faceroll.getSpellCooldown("flagellation") > 1.5 then
        state.flagellation_soon = true
    end
    if Faceroll.isSpellAvailable("vanish") then
        state.vanish_available = true
    end
    if Faceroll.getSpellCooldown("Secret Technique") < 1.5 then
        state.secrettechnique_available = true
    end
    if Faceroll.getSpellCooldown("Secret Technique") < 10 then
        state.secrettechnique_soon = true
    end

    -- target debuffs
    if Faceroll.getDotRemainingNorm("Rupture") < .3 then
        state.should_rupture = true
    end

    local function bt(b)
        if b then
            return "\124cffffff00T\124r"
        end
        return "\124cff777777F\124r"
    end

    return state
end

-----------------------------------------------------------------------------------------
-- Actions

spec.actions = {
    "backstab",
    "coldblood",
    "eviscerate",
    "flagellation",
    "rupture",
    "secrettechnique",
    "shadowblades",
    "shadowdance",
    "shadowstrike",
    "symbolsofdeath",
}

spec.calcAction = function(mode, state)
    local useCooldowns = mode == Faceroll.MODE_ST

    if state.flagellation_active and state.shadowblades_available and useCooldowns then
        return "shadowblades"
    end

    if state.cp6 then
        -- flagellation should be fired on cd
        if state.flagellation_available and not state.flagellation_active and useCooldowns then
            return "flagellation"
        end

        -- shadow dance finishers (only eviscerate and secret techniques, we want secret techniques to be the 2nd finisher generally)
        if state.shadowdance_active then
            -- symbols
            if not state.symbolsofdeath_active then
                if state.flagellation_active and state.flagellation_maxed then
                    if state.secrettechnique_soon or state.secrettechnique_available then
                        return "symbolsofdeath"
                    end

                    -- no op; don't want to symbols too early
                elseif not state.flagellation_active or not state.flagellation_maxed then
                    return "symbolsofdeath"
                end
            end

            -- in dance finishers
            if state.secrettechnique_available then
                print("secret technique is available")
                if state.coldblood_available and state.flagellation_maxed then
                    print("firing cold blood")
                    return "coldblood"
                end
                return "secrettechnique"
            else
                print("secret technique not available")
                return "eviscerate"
            end
        end

        -- finisher out of dance
        if state.should_rupture then
            return "rupture"
        end

        return "eviscerate"
    else
        if state.shadowdance_active then
            if state.premeditation_active then
                return "backstab"
            else
                return "shadowstrike"
            end
        elseif state.shadowdance_available and not state.stealth then
            if not state.flagellation_soon then
                return "shadowdance"
            end
        end

        if state.stealth then
            return "shadowstrike"
        end

        -- Build CP
        return "backstab"
    end

    return nil

end
