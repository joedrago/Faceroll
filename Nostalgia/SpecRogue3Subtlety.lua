-----------------------------------------------------------------------------------------
-- Nostalgia Subtlety Rogue (3)

if Faceroll == nil then
    _, Faceroll = ...
end

local spec = Faceroll.createSpec("SUB", "aa88dd", "ROGUE-3")

-- Big cooldowns (manually controlled): Shadow Dance, Preparation

-----------------------------------------------------------------------------------------
-- Macros (/frm)

spec.macros = {

["Attack"] = [[
/startAttack
]],

["Hemo"] = [[
/cast @Hemorrhage@
/startAttack
]],

["Ambush"] = [[
/cast @Ambush@
/startAttack
]],

}

-----------------------------------------------------------------------------------------
-- States

spec.overlay = Faceroll.createOverlay({
    "- Buffs -",
    { "b_slice",   "Slice and Dice" },
    { "b_stealth", "Stealth" },

    "- Dots -",
    { "d_rupture", "Rupture" },

    "- Spells -",
    { "s_kick",    "Kick" },

})

spec.calcState = function(state)
    return state
end

-----------------------------------------------------------------------------------------
-- Actions

spec.actions = {
    { "hemorrhage",  macro = "Hemo" },
    { "ambush",      macro = "Ambush" },
    { "eviscerate",  spell = "Eviscerate" },
    { "slice",       spell = "Slice and Dice" },
    { "kick",        spell = "Kick" },
    { "rupture",     spell = "Rupture" },
    { "fanofknives", spell = "Fan of Knives" },
}

spec.calcAction = function(mode, state)
    -- local st = (mode == Faceroll.MODE_ST)
    local aoe = (mode == Faceroll.MODE_AOE)

    if state.targetingenemy then
        if aoe and state.melee and Faceroll.isActionAvailable("fanofknives") then
            return "fanofknives"

        elseif not aoe and state.b_stealth and Faceroll.isActionAvailable("ambush") then
            return "ambush"

        elseif not aoe and state.targetcasting and state.s_kick then
            return "kick"

        elseif not state.b_slice and state.combopoints >= 2 and Faceroll.isActionAvailable("slice") then
            return "slice"

        elseif not aoe and not state.d_rupture and state.combopoints >= 5 and Faceroll.isActionAvailable("rupture") then
            return "rupture"

        elseif state.combopoints >= 5 and Faceroll.isActionAvailable("eviscerate") then
            return "eviscerate"

        else
            return "hemorrhage"
        end

    end
end
