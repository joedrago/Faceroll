-----------------------------------------------------------------------------------------
-- Nostalgia Affliction Warlock (1)

if Faceroll == nil then
    _, Faceroll = ...
end

local spec = Faceroll.createSpec("AFF", "8844aa", "WARLOCK-1")

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
    { "shadowbolt", spell = "Shadow Bolt" },
}

spec.calcAction = function(mode, state)
    local st = (mode == Faceroll.MODE_ST)
    local aoe = (mode == Faceroll.MODE_AOE)

    if state.targetingenemy then
        return "shadowbolt"
    end
end
