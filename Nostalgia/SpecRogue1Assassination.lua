-----------------------------------------------------------------------------------------
-- Nostalgia Assassination Rogue (1)

if Faceroll == nil then
    _, Faceroll = ...
end

local spec = Faceroll.createSpec("ASN", "cc4444", "ROGUE-1")

-----------------------------------------------------------------------------------------
-- Macros (/frm)

spec.macros = {

["Attack"] = [[
/startAttack
]],

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
    { "sinisterstrike", spell = "Sinister Strike" },
}

spec.calcAction = function(mode, state)
    local st = (mode == Faceroll.MODE_ST)
    local aoe = (mode == Faceroll.MODE_AOE)

    if state.targetingenemy then
        return "sinisterstrike"
    end
end
