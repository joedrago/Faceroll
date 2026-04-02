-----------------------------------------------------------------------------------------
-- Nostalgia Classic Druid (0)

if Faceroll == nil then
    _, Faceroll = ...
end

local spec = Faceroll.createSpec("DRUID", "ff7d0a", "DRUID-CLASSIC")

-----------------------------------------------------------------------------------------
-- Macros (/frm)

spec.macros = {
}

-----------------------------------------------------------------------------------------
-- States

spec.overlay = Faceroll.createOverlay({
    "- Buffs -",
    { "b_motw",      "Mark of the Wild" },
    { "b_thorns",    "Thorns" },
    { "b_rejuv",     "Rejuvenation" },
    { "b_drink",     "Drink" },

    "- Debuffs -",
    { "d_moonfire",  "Moonfire" },

    "- Spells -",
    { "s_moonfire",  "Moonfire" },
})

spec.calcState = function(state)
    return state
end

-----------------------------------------------------------------------------------------
-- Actions

spec.actions = {
    { "wrath",       spell = "Wrath" },
    { "moonfire",    spell = "Moonfire" },
    { "motw",        spell = "Mark of the Wild" },
    { "thorns",      spell = "Thorns" },
    { "rejuv",       spell = "Rejuvenation" },
    "drink",
}

spec.calcAction = function(mode, state)
    local aoe = (mode == Faceroll.MODE_AOE)

    -- Keep Mark of the Wild up
    if not state.b_motw and Faceroll.isActionAvailable("motw") then
        return "motw"

    -- Keep Thorns up
    elseif not state.b_thorns and Faceroll.isActionAvailable("thorns") then
        return "thorns"

    -- Self-heal with Rejuvenation when solo and low HP
    elseif not state.combat and not state.group and state.hp < 0.6 and not state.b_rejuv and Faceroll.isActionAvailable("rejuv") then
        return "rejuv"

    -- Drink when low mana
    elseif state.mana < 0.9 and not state.combat and not state.b_drink and Faceroll.isActionAvailable("drink") then
        return "drink"

    elseif state.targetingenemy then
        -- Apply Moonfire if not on target
        if not state.d_moonfire and state.s_moonfire then
            return "moonfire"

        -- Wrath filler
        else
            return "wrath"
        end
    end
end
