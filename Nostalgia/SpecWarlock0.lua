-----------------------------------------------------------------------------------------
-- Nostalgia Classic Warlock (0)

if Faceroll == nil then
    _, Faceroll = ...
end

local spec = Faceroll.createSpec("LOCK", "9482c9", "WARLOCK-CLASSIC")

spec.keepRanks = { "Drain Soul" }

-----------------------------------------------------------------------------------------
-- Macros (/frm)

spec.macros = {
}

-----------------------------------------------------------------------------------------
-- States

spec.overlay = Faceroll.createOverlay({
    "- Buffs -",
    { "b_demonarmor", "Demon Armor" },
    { "b_drink",      "Drink" },

    "- Debuffs -",
    { "d_corruption", "Corruption" },
})

spec.calcState = function(state)
    return state
end

-----------------------------------------------------------------------------------------
-- Actions

spec.actions = {
    { "shadowbolt",   spell = "Shadow Bolt" },
    { "corruption",   spell = "Corruption" },
    { "demonarmor",   spell = "Demon Armor" },
    "drink",
}

spec.calcAction = function(mode, state)
    local aoe = (mode == Faceroll.MODE_AOE)

    -- Keep Demon Armor up
    if not state.b_demonarmor and Faceroll.isActionAvailable("demonarmor") then
        return "demonarmor"

    elseif state.targetingenemy then
        -- When solo and not in combat, lead with Shadow Bolt before dots
        if not state.combat and not state.group then
            return "shadowbolt"
        end

        -- Apply Corruption if missing
        if not state.d_corruption and Faceroll.isActionAvailable("corruption") then
            return "corruption"

        -- Shadow Bolt filler
        else
            return "shadowbolt"
        end

    -- Drink when low mana
    elseif state.mana < 0.9 and not state.combat and not state.b_drink and Faceroll.isActionAvailable("drink") then
        return "drink"
    end
end
