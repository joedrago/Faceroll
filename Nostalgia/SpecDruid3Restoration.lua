-----------------------------------------------------------------------------------------
-- Nostalgia Restoration Druid (3)

if Faceroll == nil then
    _, Faceroll = ...
end

local spec = Faceroll.createSpec("RDRU", "88ccaa", "DRUID-3")

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
    { "wrath", spell = "Wrath" },
}

spec.calcAction = function(mode, state)
    local st = (mode == Faceroll.MODE_ST)
    local aoe = (mode == Faceroll.MODE_AOE)

    if state.targetingenemy then
        return "wrath"
    end
end
