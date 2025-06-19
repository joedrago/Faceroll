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

spec.abilities = {
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

local bits = Faceroll.createBits({
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
})

spec.calcBits = function()
    bits:reset()

    local cp = GetComboPoints("player", "target")
    -- print("energy " .. energy .. " cp " .. cp)

    -- player/base class state
    if UnitAffectingCombat("player") then
        bits:enable("combat")
    end
    if cp >= 6 then
        bits:enable("cp6")
    end
    if Faceroll.isBuffActive("Stealth") or Faceroll.isBuffActive("Vanish") then
        bits:enable("stealth")
    end

    -- buffs
    if Faceroll.isBuffActive("Shadow Blades") then
        bits:enable("shadowblades_active")
    end
    if Faceroll.isBuffActive("Symbols of Death") then
        bits:enable("symbolsofdeath_active")
    end
    if Faceroll.isBuffActive("Premeditation") then
        bits:enable("premeditation_active")
    end
    if Faceroll.isBuffActive("Shadow Dance") then
        bits:enable("shadowdance_active")
    end
    if Faceroll.isBuffActive("Cold Blood") then
        bits:enable("coldblood_active")
    end
    if Faceroll.isBuffActive("Flagellation") then
        bits:enable("flagellation_active")
    end
    if Faceroll.getBuffStacks("Flagellation") >= 30 then
        bits:enable("flagellation_maxed")
    end
    if Faceroll.getBuffStacks("Danse Macabre") <= 2 then
        bits:enable("dansemacabre_low")
    end

    -- cds
    if Faceroll.isSpellAvailable("Shadow Blades") then
        bits:enable("shadowblades_available")
    end
    if Faceroll.spellCharges("Symbols of Death") > 0 then
        bits:enable("symbolsofdeath_available")
    end
    if Faceroll.spellCharges("Shadow Dance") > 0 then
        bits:enable("shadowdance_available")
    end
    if Faceroll.isSpellAvailable("Cold Blood") then
        bits:enable("coldblood_available")
    end
    if Faceroll.isSpellAvailable("flagellation") then
        bits:enable("flagellation_available")
    end
    if Faceroll.spellCooldown("flagellation") < 30 and Faceroll.spellCooldown("flagellation") > 1.5 then
        bits:enable("flagellation_soon")
    end
    if Faceroll.isSpellAvailable("vanish") then
        bits:enable("vanish_available")
    end
    if Faceroll.spellCooldown("Secret Technique") < 1.5 then
        bits:enable("secrettechnique_available")
    end
    if Faceroll.spellCooldown("Secret Technique") < 10 then
        bits:enable("secrettechnique_soon")
    end

    -- target debuffs
    if Faceroll.isDotActive("Rupture") < .3 then
        bits:enable("should_rupture")
    end

    local function bt(b)
        if b then
            return "\124cffffff00T\124r"
        end
        return "\124cff777777F\124r"
    end

    if Faceroll.debug then
        local o = ""

        o = o .. "SD: " .. bt(Faceroll.isBuffActive("shadowdance")) .. "\n"

        local stAvailable = Faceroll.spellCooldown("Secret Technique") < 1.5
        o = o .. "ST: " .. bt(stAvailable) .. "\n"

        Faceroll.setDebugText(o)
    end

    return bits.value
end

spec.nextAction = function(action, rawBits)
    local state = bits:parse(rawBits)

    local useCooldowns = action == Faceroll.ACTION_ST

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

Faceroll.registerSpec(spec)
