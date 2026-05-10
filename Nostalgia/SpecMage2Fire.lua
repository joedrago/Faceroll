-----------------------------------------------------------------------------------------
-- Nostalgia Fire Mage (2)
--
-- Combustion: manually controlled
-- Blast Wave, Dragon's Breath: excluded (close-range AOE)

if Faceroll == nil then
    _, Faceroll = ...
end

local spec = Faceroll.createSpec("FIRE", "ff6633", "MAGE-2")

spec.buffs = {
    { "Molten Armor", "Mage Armor", "Ice Armor", "Frost Armor" },
    "Arcane Intellect",
}

-----------------------------------------------------------------------------------------
-- Macros (/frm)

spec.macros = {

["Flamestrike"] = [[
#showtooltip Flamestrike
/stopmacro [channeling]
/stopmacro [noexist]
/say .cast @@Flamestrike@@
]],

}

-----------------------------------------------------------------------------------------
-- States

spec.overlay = Faceroll.createOverlay({
    "- Buffs -",
    { "b_moltenarmor", "Molten Armor" },
    { "b_ai",          "Arcane Intellect" },
    { "b_drink",       "Drink" },
    { "b_hotstreak",   "Hot Streak" },

    "- Debuffs -",
    { "d_livingbomb",  "Living Bomb" },
    { "d_scorch",      "Scorch" },

    "- Spells -",
    { "s_fireblast",   "Fire Blast" },
    { "s_pyroblast",   "Pyroblast" },
})

spec.calcState = function(state)
    return state
end

-----------------------------------------------------------------------------------------
-- Actions

spec.actions = {
    { "fireball",      spell = "Fireball" },
    { "pyroblast",     spell = "Pyroblast" },
    { "livingbomb",    spell = "Living Bomb" },
    { "scorch",        spell = "Scorch" },
    { "fireblast",     spell = "Fire Blast" },
    { "flamestrike",   macro = "Flamestrike" },
    { "moltenarmor",   spell = "Molten Armor" },
    { "ai",            spell = "Arcane Intellect" },
    "drink",
}

spec.calcAction = function(mode, state)
    local st = (mode == Faceroll.MODE_ST)
    local aoe = (mode == Faceroll.MODE_AOE)

    -- Keep Molten Armor up
    if not state.b_moltenarmor and Faceroll.isActionAvailable("moltenarmor") then
        return "moltenarmor"

    -- Keep Arcane Intellect up
    elseif not state.b_ai and Faceroll.isActionAvailable("ai") then
        return "ai"

    elseif state.targetingenemy then
        -- Hot Streak proc: instant Pyroblast
        if state.b_hotstreak and state.s_pyroblast then
            return "pyroblast"

        -- Maintain Living Bomb DoT
        elseif not state.d_livingbomb and Faceroll.isActionAvailable("livingbomb") then
            return "livingbomb"

        -- Maintain Scorch debuff (group only)
        elseif state.group and not state.d_scorch and Faceroll.isActionAvailable("scorch") then
            return "scorch"

        -- AOE: Flamestrike
        elseif aoe and Faceroll.isActionAvailable("flamestrike") then
            return "flamestrike"

        -- Fire Blast on cooldown
        elseif st and state.s_fireblast then
            return "fireblast"

        -- Fireball filler
        else
            return "fireball"
        end

    -- Drink when low mana
    elseif state.mana < 0.9 and not state.combat and not state.b_drink and Faceroll.isActionAvailable("drink") then
        return "drink"
    end
end
