-----------------------------------------------------------------------------------------
-- Nostalgia Classic Warrior (0)

if Faceroll == nil then
    _, Faceroll = ...
end

local spec = Faceroll.createSpec("WARR", "c79c6e", "WARRIOR-CLASSIC")

-----------------------------------------------------------------------------------------
-- Macros (/frm)

spec.macros = {

["Attack"] = [[
/startAttack
]],

["Heroic"] = [[
/cast !@Heroic Strike@
/startAttack
]],

}

-----------------------------------------------------------------------------------------
-- States

spec.overlay = Faceroll.createOverlay({
    "- Buffs -",
    { "b_battleshout", "Battle Shout" },

    "- Spells -",
    { "s_heroic",      "Heroic Strike" },
})

spec.calcState = function(state)
    return state
end

-----------------------------------------------------------------------------------------
-- Actions

spec.actions = {
    { "attack",        macro = "Attack" },
    { "heroic",        macro = "Heroic" },
    { "battleshout",   spell = "Battle Shout" },
}

spec.calcAction = function(mode, state)
    -- local st = (mode == Faceroll.MODE_ST)
    local aoe = (mode == Faceroll.MODE_AOE)

    -- Keep Battle Shout up
    if not state.b_battleshout and Faceroll.isActionAvailable("battleshout") then
        return "battleshout"

    elseif state.targetingenemy then
        if state.rage >= 15 and state.s_heroic then
            return "heroic"
        else
            return "attack"
        end
    end
end
