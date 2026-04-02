-----------------------------------------------------------------------------------------
-- Nostalgia Fury Warrior (2)
--
-- Death Wish, Recklessness: manually controlled
-- Self-healing: warriors have no self-heal, skipped

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

["Heroic"] = [[
/cast !@Heroic Strike@
/startAttack
]],

["Cleave"] = [[
/cast !@Cleave@
/startAttack
]],

["BT"] = [[
#showtooltip
/cast @Bloodthirst@
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
    { "b_bloodsurge",  "Bloodsurge" },

    "- Spells -",
    { "s_bt",          "Bloodthirst" },
    { "s_whirlwind",   "Whirlwind" },
    { "s_execute",     "Execute" },
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
    { "bt",            macro = "BT" },
    { "whirlwind",     spell = "Whirlwind" },
    { "slam",          spell = "Slam" },
    { "execute",       spell = "Execute" },
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

        -- Execute at low HP (highest priority in execute range)
        elseif state.targethp > 0 and state.targethp < 0.20 and state.s_execute then
            return "execute"

        -- Bloodthirst on cooldown
        elseif state.s_bt then
            return "bt"

        -- Whirlwind on cooldown
        elseif state.s_whirlwind then
            return "whirlwind"

        -- Slam on Bloodsurge proc (instant)
        elseif state.b_bloodsurge and Faceroll.isActionAvailable("slam") then
            return "slam"

        -- AOE: Cleave
        elseif aoe and Faceroll.isActionAvailable("cleave") then
            return "cleave"

        -- Heroic Strike as rage dump
        elseif state.rage > 50 and Faceroll.isActionAvailable("heroic") then
            return "heroic"

        -- Auto-attack filler
        else
            return "attack"
        end
    end
end
