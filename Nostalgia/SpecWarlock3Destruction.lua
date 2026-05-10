-----------------------------------------------------------------------------------------
-- Nostalgia Destruction Warlock (3)
--
-- Shadowfury: manually controlled
-- Self-healing (Drain Life / Health Funnel): skipped, channeled spells add complexity

if Faceroll == nil then
    _, Faceroll = ...
end

local spec = Faceroll.createSpec("DEST", "cc4422", "WARLOCK-3")

-----------------------------------------------------------------------------------------
-- Macros (/frm)

spec.macros = {

["FelArmor"] = [[
#showtooltip
/cast @Fel Armor|Demon Armor@
]],

["Nuke"] = [[
#showtooltip
/cast @Incinerate|Shadow Bolt@
]],

["RainOfFire"] = [[
#showtooltip Rain of Fire
/stopmacro [channeling]
/stopmacro [noexist]
/say .cast @@Rain of Fire@@
]],

}

-----------------------------------------------------------------------------------------
-- States

spec.overlay = Faceroll.createOverlay({
    "- Buffs -",
    { "b_felarmor",     "Fel Armor" },
    { "b_demonarmor",   "Demon Armor" },
    { "b_drink",        "Drink" },

    "- Debuffs -",
    { "d_immolate",     "Immolate" },
    { "d_coe",          "Curse of the Elements" },

    "- Spells -",
    { "s_conflagrate",  "Conflagrate" },
    { "s_chaosbolt",    "Chaos Bolt" },
})

spec.calcState = function(state)
    return state
end

-----------------------------------------------------------------------------------------
-- Actions

spec.actions = {
    { "nuke",          macro = "Nuke" },
    { "immolate",      spell = "Immolate" },
    { "conflagrate",   spell = "Conflagrate" },
    { "chaosbolt",     spell = "Chaos Bolt" },
    { "coe",           spell = "Curse of the Elements" },
    { "rainoffire",    macro = "RainOfFire" },
    { "lifetap",       spell = "Life Tap" },
    { "felarmor",      macro = "FelArmor" },
    "drink",
}

spec.calcAction = function(mode, state)
    local st = (mode == Faceroll.MODE_ST)
    local aoe = (mode == Faceroll.MODE_AOE)

    -- Keep Fel Armor (or Demon Armor) up
    if not state.b_felarmor and not state.b_demonarmor and Faceroll.isActionAvailable("felarmor") then
        return "felarmor"

    -- Life Tap when low mana and healthy enough
    elseif state.mana < 0.3 and state.hp > 0.5 and Faceroll.isActionAvailable("lifetap") then
        return "lifetap"

    elseif state.targetingenemy then
        -- AOE: Rain of Fire
        if aoe and Faceroll.isActionAvailable("rainoffire") then
            return "rainoffire"

        -- Curse of Elements in groups if missing
        elseif state.group and not state.d_coe and Faceroll.isActionAvailable("coe") then
            return "coe"

        -- When solo and not in combat, lead with a cast before dots
        elseif not state.combat and not state.group then
            return "nuke"

        -- Immolate if missing
        elseif not state.d_immolate and Faceroll.isActionAvailable("immolate") then
            return "immolate"

        -- Conflagrate on cooldown
        elseif state.s_conflagrate then
            return "conflagrate"

        -- Chaos Bolt on cooldown
        elseif state.s_chaosbolt then
            return "chaosbolt"

        -- Incinerate / Shadow Bolt filler
        else
            return "nuke"
        end

    -- Drink when low mana
    elseif state.mana < 0.9 and not state.combat and not state.b_drink and Faceroll.isActionAvailable("drink") then
        return "drink"
    end
end
