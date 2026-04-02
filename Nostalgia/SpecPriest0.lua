-----------------------------------------------------------------------------------------
-- Nostalgia Classic Priest (0)

if Faceroll == nil then
    _, Faceroll = ...
end

local spec = Faceroll.createSpec("PRI", "cccccc", "PRIEST-CLASSIC")

-----------------------------------------------------------------------------------------
-- Macros (/frm)

spec.macros = {
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
})

spec.calcState = function(state)
    return state
end

-----------------------------------------------------------------------------------------
-- Actions

spec.actions = {
    { "smite",        spell = "Smite" },
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
    elseif not state.b_innerfire and Faceroll.isActionAvailable("innerfire") then
        return "innerfire"

    -- Self-heal with Renew when solo and low HP
    elseif not state.combat and not state.group and state.hp < 0.6 and not state.b_renew and Faceroll.isActionAvailable("renew") then
        return "renew"

    elseif state.targetingenemy then
        -- Apply Shadow Word: Pain if missing
        if not state.d_pain and Faceroll.isActionAvailable("pain") then
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
