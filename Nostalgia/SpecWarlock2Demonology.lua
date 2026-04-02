-----------------------------------------------------------------------------------------
-- Nostalgia Demonology Warlock (2)
--
-- Metamorphosis: manually controlled
-- Self-healing (Drain Life / Health Funnel): skipped, channeled spells add complexity

if Faceroll == nil then
    _, Faceroll = ...
end

local spec = Faceroll.createSpec("DEMO", "9482c9", "WARLOCK-2")

-----------------------------------------------------------------------------------------
-- Macros (/frm)

spec.macros = {

["FelArmor"] = [[
#showtooltip
/cast @Fel Armor|Demon Armor@
]],

["Seed"] = [[
#showtooltip
/cast @Seed of Corruption@
]],

}

-----------------------------------------------------------------------------------------
-- States

spec.overlay = Faceroll.createOverlay({
    "- Buffs -",
    { "b_felarmor",     "Fel Armor" },
    { "b_demonarmor",   "Demon Armor" },
    { "b_decimation",   "Decimation" },
    { "b_drink",        "Drink" },

    "- Debuffs -",
    { "d_immolate",     "Immolate" },
    { "d_corruption",   "Corruption" },
    { "d_coa",          "Curse of Agony" },
    { "d_coe",          "Curse of the Elements" },

    "- Spells -",
    { "s_soulfire",     "Soul Fire" },

    "- Custom -",
    "targethp",
})

spec.calcState = function(state)
    state.targethp = 0
    if state.targetingenemy then
        state.targethp = UnitHealth("target") / UnitHealthMax("target")
    end

    return state
end

-----------------------------------------------------------------------------------------
-- Actions

spec.actions = {
    { "shadowbolt",    spell = "Shadow Bolt" },
    { "immolate",      spell = "Immolate" },
    { "corruption",    spell = "Corruption" },
    { "coa",           spell = "Curse of Agony" },
    { "coe",           spell = "Curse of the Elements" },
    { "soulfire",      spell = "Soul Fire" },
    { "seed",          macro = "Seed" },
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

    -- Drink when low mana out of combat
    elseif state.mana < 0.9 and not state.combat and not state.b_drink and Faceroll.isActionAvailable("drink") then
        return "drink"

    elseif state.targetingenemy then
        -- AOE: Seed of Corruption
        if aoe and Faceroll.isActionAvailable("seed") then
            return "seed"

        -- Curse of Elements in groups if missing
        elseif state.group and not state.d_coe and Faceroll.isActionAvailable("coe") then
            return "coe"

        -- Curse of Agony if no CoE needed
        elseif not state.group and not state.d_coa and Faceroll.isActionAvailable("coa") then
            return "coa"

        -- Immolate if missing
        elseif not state.d_immolate and Faceroll.isActionAvailable("immolate") then
            return "immolate"

        -- Corruption if missing
        elseif not state.d_corruption then
            return "corruption"

        -- Decimation proc: Soul Fire
        elseif state.b_decimation and state.s_soulfire then
            return "soulfire"

        -- Shadow Bolt filler
        else
            return "shadowbolt"
        end
    end
end
