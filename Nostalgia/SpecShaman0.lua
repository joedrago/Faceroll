-----------------------------------------------------------------------------------------
-- Nostalgia Classic Shaman (0)

if Faceroll == nil then
    _, Faceroll = ...
end

local spec = Faceroll.createSpec("SHMN", "0070de", "SHAMAN-CLASSIC")

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
    { "lightningbolt", spell = "Lightning Bolt" },
}

spec.calcAction = function(mode, state)
    local st = (mode == Faceroll.MODE_ST)
    local aoe = (mode == Faceroll.MODE_AOE)

    if state.targetingenemy then
        return "lightningbolt"
    end
end
