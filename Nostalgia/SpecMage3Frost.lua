-----------------------------------------------------------------------------------------
-- Nostalgia Frost Mage (3)

if Faceroll == nil then
    _, Faceroll = ...
end

local spec = Faceroll.createSpec("FROST", "44ddff", "MAGE-3")

-----------------------------------------------------------------------------------------
-- Macros (/frm)

spec.macros = {
}

-----------------------------------------------------------------------------------------
-- States

spec.overlay = Faceroll.createOverlay({
    -- { "s_spellname", "Spell Name" },
})

spec.calcState = function(state)
    return state
end

-----------------------------------------------------------------------------------------
-- Actions

spec.actions = {
    { "frostbolt", spell = "Frostbolt" },
}

spec.calcAction = function(mode, state)
    local st = (mode == Faceroll.MODE_ST)
    local aoe = (mode == Faceroll.MODE_AOE)

    if state.targetingenemy then
        return "frostbolt"
    end
end
