-----------------------------------------------------------------------------------------
-- Nostalgia Classic Mage (0)

if Faceroll == nil then
    _, Faceroll = ...
end

local spec = Faceroll.createSpec("MAGE", "69ccf0", "MAGE-CLASSIC")

spec.buffs = {
    "Frost Armor",
    "Arcane Intellect|Arcane Brilliance",
}

-----------------------------------------------------------------------------------------
-- Macros (/frm)

spec.macros = {
}

-----------------------------------------------------------------------------------------
-- States

spec.overlay = Faceroll.createOverlay({
    "- Buffs -",
    { "b_armor",  "Frost Armor" },
    { "b_ai",     "Arcane Intellect" },
    { "b_drink",  "Drink" },
})

-----------------------------------------------------------------------------------------
-- Actions

spec.actions = {
    { "fireball",   spell = "Fireball" },
    { "armor",      spell = "Frost Armor" },
    { "ai",         spell = "Arcane Intellect" },
    "drink",
}

spec.calcAction = function(mode, state)
    local aoe = (mode == Faceroll.MODE_AOE)

    -- Keep Frost Armor up
    if not state.b_armor and Faceroll.isActionAvailable("armor") then
        return "armor"

    -- Keep Arcane Intellect up
    elseif not state.b_ai and Faceroll.isActionAvailable("ai") then
        return "ai"

    elseif state.targetingenemy then
        return "fireball"

    -- Drink when low mana
    elseif state.mana < 0.9 and not state.combat and not state.b_drink and Faceroll.isActionAvailable("drink") then
        return "drink"
    end
end
