-----------------------------------------------------------------------------------------
-- Nostalgia Arms Warrior (1)
--
-- Recklessness, Bladestorm: manually controlled
-- Self-healing: warriors have no self-heal, skipped

if Faceroll == nil then
    _, Faceroll = ...
end

local spec = Faceroll.createSpec("ARMS", "ddaa66", "WARRIOR-1")

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

["Cleave"] = [[
/cast !@Cleave@
/startAttack
]],

["MS"] = [[
#showtooltip
/cast @Mortal Strike@
/startAttack
]],

["Execute"] = [[
#showtooltip
/cast @Execute@
/startAttack
]],

-- Utility: stance macros
["BattleStance"] = [[
#showtooltip
/cast @Battle Stance@
]],

["BerserkerStance"] = [[
#showtooltip
/cast @Berserker Stance@
]],

}

-----------------------------------------------------------------------------------------
-- States

spec.overlay = Faceroll.createOverlay({
    "- Buffs -",
    { "b_battleshout", "Battle Shout" },
    { "b_overpower",   "Taste for Blood" },

    "- Debuffs -",
    { "d_rend",        "Rend" },

    "- Spells -",
    { "s_ms",          "Mortal Strike" },
    { "s_overpower",   "Overpower" },
    { "s_execute",     "Execute" },
    { "s_slam",        "Slam" },
    { "s_charge",      "Charge" },

    "- Custom -",
    "targethp",
})

spec.calcState = function(state)
    state.targethp = 0
    if state.targetingenemy then
        state.targethp = UnitHealth("target") / UnitHealthMax("target")
    end
    return state
end

-----------------------------------------------------------------------------------------
-- Actions

spec.actions = {
    { "attack",        macro = "Attack" },
    { "ms",            macro = "MS" },
    { "overpower",     spell = "Overpower" },
    { "execute",       macro = "Execute" },
    { "slam",          spell = "Slam" },
    { "rend",          spell = "Rend" },
    { "battleshout",   spell = "Battle Shout" },
    { "heroic",        macro = "Heroic" },
    { "cleave",        macro = "Cleave" },
    { "charge",        spell = "Charge" },
}

spec.calcAction = function(mode, state)
    -- local st = (mode == Faceroll.MODE_ST)
    local aoe = (mode == Faceroll.MODE_AOE)

    -- Keep Battle Shout up
    if not state.b_battleshout and Faceroll.isActionAvailable("battleshout") then
        return "battleshout"

    elseif state.targetingenemy then
        -- Charge into melee range
        if state.s_charge and not state.melee then
            return "charge"

        -- Maintain Rend
        elseif state.melee and not state.d_rend and Faceroll.isActionAvailable("rend") then
            return "rend"

        -- Overpower on proc (Taste for Blood or dodge)
        elseif state.s_overpower then
            return "overpower"

        -- Mortal Strike on cooldown
        elseif state.s_ms then
            return "ms"

        -- Execute at low HP
        elseif state.targethp > 0 and state.targethp < 0.20 and state.s_execute then
            return "execute"

        -- AOE: Cleave
        elseif aoe and Faceroll.isActionAvailable("cleave") then
            return "cleave"

        -- Heroic Strike as rage dump
        elseif state.rage > 50 and Faceroll.isActionAvailable("heroic") then
            return "heroic"

        -- Slam as filler
        elseif state.s_slam then
            return "slam"

        -- Auto-attack filler
        else
            return "attack"
        end
    end
end
