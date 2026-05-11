-----------------------------------------------------------------------------------------
-- Nostalgia Discipline Priest (1)
--
-- Pain Suppression: manually controlled
-- Power Infusion: manually controlled

if Faceroll == nil then
    _, Faceroll = ...
end

local spec = Faceroll.createSpec("DISC", "ddcc55", "PRIEST-1")

spec.buffs = {
    "Power Word: Fortitude|Prayer of Fortitude",
    "Inner Fire",
}

-----------------------------------------------------------------------------------------
-- Macros (/frm)
--
-- Penance (damage) is channeled. Smite and Holy Fire need [nochanneling]
-- guards so Faceroll doesn't interrupt Penance mid-channel.

spec.macros = {

["Smite"] = [[
#showtooltip
/cast [nochanneling] @Smite@
]],

["HolyFire"] = [[
#showtooltip
/cast [nochanneling] @Holy Fire@
]],

}

-----------------------------------------------------------------------------------------
-- States

spec.overlay = Faceroll.createOverlay({
    "- Buffs -",
    { "b_fortitude",  "Power Word: Fortitude" },
    { "b_innerfire",  "Inner Fire" },
    { "b_renew",      "Renew" },
    { "b_drink",      "Drink" },

    "- Debuffs -",
    { "d_pain",       "Shadow Word: Pain" },

    "- Spells -",
    { "s_penance",    "Penance" },
    { "s_holyfire",   "Holy Fire" },
})

-----------------------------------------------------------------------------------------
-- Actions

spec.actions = {
    { "smite",        macro = "Smite" },
    { "holyfire",     macro = "HolyFire" },
    { "penance",      spell = "Penance" },
    { "pain",         spell = "Shadow Word: Pain" },
    { "fortitude",    spell = "Power Word: Fortitude" },
    { "innerfire",    spell = "Inner Fire" },
    { "renew",        spell = "Renew" },
    "drink",
}

spec.calcAction = function(mode, state)
    local aoe = (mode == Faceroll.MODE_AOE)

    -- Keep Power Word: Fortitude up
    if not state.b_fortitude and Faceroll.isActionAvailable("fortitude") then
        return "fortitude"

    -- Keep Inner Fire up
    elseif not state.b_innerfire then
        return "innerfire"

    -- Self-heal with Renew when solo and low HP
    elseif not state.combat and not state.group and state.hp < 0.6 and not state.b_renew and Faceroll.isActionAvailable("renew") then
        return "renew"

    elseif state.targetingenemy then
        -- Penance on cooldown (talented)
        if state.s_penance then
            return "penance"

        -- Holy Fire on cooldown
        elseif state.s_holyfire then
            return "holyfire"

        -- When solo and not in combat, lead with a cast before dots
        elseif not state.combat and not state.group then
            return "smite"

        -- Shadow Word: Pain if missing
        elseif not state.d_pain then
            return "pain"

        -- Smite filler
        else
            return "smite"
        end

    -- Drink when low mana
    elseif state.mana < 0.9 and not state.combat and not state.b_drink and Faceroll.isActionAvailable("drink") then
        return "drink"
    end
end
