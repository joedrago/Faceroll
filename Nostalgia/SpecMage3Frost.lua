-----------------------------------------------------------------------------------------
-- Nostalgia Frost Mage (3)
--
-- Icy Veins, Cold Snap: manually controlled

if Faceroll == nil then
    _, Faceroll = ...
end

local spec = Faceroll.createSpec("FROST", "44ddff", "MAGE-3")

-----------------------------------------------------------------------------------------
-- Macros (/frm)

spec.macros = {

["Blizzard"] = [[
#showtooltip Blizzard
/stopmacro [channeling]
/stopmacro [noexist]
/say .cast @@Blizzard@@
]],

}

-----------------------------------------------------------------------------------------
-- States

spec.overlay = Faceroll.createOverlay({
    "- Buffs -",
    { "b_armor",          "Ice Armor" },
    { "b_ai",             "Arcane Intellect" },
    { "b_drink",          "Drink" },
    { "b_brainfreeze",    "Brain Freeze" },
    { "b_fingersoffrost", "Fingers of Frost" },

    "- Spells -",
    { "s_deepfreeze",     "Deep Freeze" },
    { "s_icelance",       "Ice Lance" },
})

spec.calcState = function(state)
    return state
end

-----------------------------------------------------------------------------------------
-- Actions

spec.actions = {
    { "frostbolt",     spell = "Frostbolt" },
    { "fireball",      spell = "Fireball" },
    { "deepfreeze",    spell = "Deep Freeze" },
    { "icelance",      spell = "Ice Lance" },
    { "blizzard",      macro = "Blizzard" },
    { "armor",         spell = "Ice Armor" },
    { "ai",            spell = "Arcane Intellect" },
    "drink",
}

spec.calcAction = function(mode, state)
    local st = (mode == Faceroll.MODE_ST)
    local aoe = (mode == Faceroll.MODE_AOE)

    -- Keep Ice Armor up
    if not state.b_armor and Faceroll.isActionAvailable("armor") then
        return "armor"

    -- Keep Arcane Intellect up
    elseif not state.b_ai and Faceroll.isActionAvailable("ai") then
        return "ai"

    -- Drink when low mana
    elseif state.mana < 0.9 and not state.combat and not state.b_drink and Faceroll.isActionAvailable("drink") then
        return "drink"

    elseif state.targetingenemy then
        -- AOE: Blizzard
        if aoe and Faceroll.isActionAvailable("blizzard") then
            return "blizzard"

        -- Brain Freeze proc: instant Fireball
        elseif state.b_brainfreeze and Faceroll.isActionAvailable("fireball") then
            return "fireball"

        -- Fingers of Frost + Deep Freeze
        elseif state.b_fingersoffrost and state.s_deepfreeze then
            return "deepfreeze"

        -- Fingers of Frost + Ice Lance (shatter damage)
        elseif state.b_fingersoffrost and state.s_icelance then
            return "icelance"

        -- Frostbolt filler
        else
            return "frostbolt"
        end
    end
end
