-----------------------------------------------------------------------------------------
-- Nostalgia Classic Warrior (0)

if Faceroll == nil then
    _, Faceroll = ...
end

local spec = Faceroll.createSpec("WARR", "c79c6e", "WARRIOR-CLASSIC")

spec.buffs = {
    "Battle Shout",
}

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

    "- Debuffs -",
    { "d_rend",        "Rend" },

    "- Spells -",
    { "s_heroic",      "Heroic Strike" },
    { "s_charge",      "Charge" },
    { "s_clap",        "Thunder Clap" },
    { "s_victoryrush", "Victory Rush" },
})

spec.calcState = function(state)
    return state
end

-----------------------------------------------------------------------------------------
-- Actions

spec.actions = {
    { "attack",        macro = "Attack" },
    { "heroic",        macro = "Heroic" },
    { "charge",        spell = "Charge" },
    { "battleshout",   spell = "Battle Shout" },
    { "rend",          spell = "Rend" },
    { "clap",          spell = "Thunder Clap" },
    { "victoryrush",   spell = "Victory Rush" },
}

spec.calcAction = function(mode, state)
    -- local st = (mode == Faceroll.MODE_ST)
    local aoe = (mode == Faceroll.MODE_AOE)

    -- Keep Battle Shout up
    if state.rage >= 10 and not state.b_battleshout and Faceroll.isActionAvailable("battleshout") then
        return "battleshout"

    elseif state.targetingenemy then
        -- Charge into melee range
        if state.s_charge and not state.melee then
            return "charge"

        -- Victory Rush (free damage + heal, use before it expires)
        elseif state.melee and state.s_victoryrush then
            return "victoryrush"

        -- Thunder Clap on cooldown
        elseif state.rage >= 20 and state.melee and state.s_clap then
            return "clap"

        -- Maintain Rend
        elseif state.rage >= 10 and state.melee and not state.d_rend and Faceroll.isActionAvailable("rend") then
            return "rend"

        -- Heroic Strike as filler (no rotational cooldowns to save rage for at this level)
        elseif Faceroll.isActionAvailable("heroic") then
            return "heroic"
        else
            return "attack"
        end
    end
end
