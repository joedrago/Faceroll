-----------------------------------------------------------------------------------------
-- Nostalgia Affliction Warlock (1)
--
-- Summon Infernal, Curse of Doom: manually controlled
-- Self-healing (Drain Life / Health Funnel): skipped, channeled spells add complexity

if Faceroll == nil then
    _, Faceroll = ...
end

local spec = Faceroll.createSpec("AFF", "8844aa", "WARLOCK-1")

Faceroll.enemyGridTrack(spec, "Corruption", "COR", "8844aa")
Faceroll.enemyGridTrack(spec, "Unstable Affliction", "UA", "aa44cc")
Faceroll.enemyGridTrack(spec, "Curse of Agony", "CoA", "cc6688")

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
    { "b_felarmor",    "Fel Armor" },
    { "b_demonarmor",  "Demon Armor" },
    { "b_drink",       "Drink" },

    "- Debuffs -",
    { "d_corruption",  "Corruption" },
    { "d_ua",          "Unstable Affliction" },
    { "d_coa",         "Curse of Agony" },
    { "d_haunt",       "Haunt" },
    { "d_coe",         "Curse of the Elements" },

    "- Spells -",
    { "s_haunt",       "Haunt" },

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
    { "haunt",         spell = "Haunt" },
    { "ua",            spell = "Unstable Affliction" },
    { "corruption",    spell = "Corruption" },
    { "coa",           spell = "Curse of Agony" },
    { "coe",           spell = "Curse of the Elements" },
    { "drainsoul",     spell = "Drain Soul" },
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

        -- Haunt on cooldown
        elseif state.s_haunt then
            return "haunt"

        -- Unstable Affliction if missing
        elseif not state.d_ua and Faceroll.isActionAvailable("ua") then
            return "ua"

        -- Corruption if missing
        elseif not state.d_corruption then
            return "corruption"

        -- Drain Soul execute (target < 25%)
        elseif state.targethp < 0.25 and state.targethp > 0 and Faceroll.isActionAvailable("drainsoul") then
            return "drainsoul"

        -- Shadow Bolt filler
        else
            return "shadowbolt"
        end

    -- Drink when low mana
    elseif state.mana < 0.9 and not state.combat and not state.b_drink and Faceroll.isActionAvailable("drink") then
        return "drink"
    end
end
