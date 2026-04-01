-----------------------------------------------------------------------------------------
-- Nostalgia Beast Mastery Hunter (1)

if Faceroll == nil then
    _, Faceroll = ...
end

local spec = Faceroll.createSpec("BM", "abd473", "HUNTER-1")

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
    { "autoshot", spell = "Auto Shot" },
}

spec.calcAction = function(mode, state)
    local st = (mode == Faceroll.MODE_ST)
    local aoe = (mode == Faceroll.MODE_AOE)

    if state.targetingenemy then
        return "autoshot"
    end
end
