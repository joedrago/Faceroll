-----------------------------------------------------------------------------------------
-- Nostalgia Fury Warrior (2)

if Faceroll == nil then
    _, Faceroll = ...
end

local spec = Faceroll.createSpec("FURY", "ee3333", "WARRIOR-2")

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
    { "attack", macro = "Attack" },
}

spec.calcAction = function(mode, state)
    local st = (mode == Faceroll.MODE_ST)
    local aoe = (mode == Faceroll.MODE_AOE)

    if state.targetingenemy then
        return "attack"
    end
end
