-----------------------------------------------------------------------------------------
-- Nostalgia Combat Rogue (2)

if Faceroll == nil then
    _, Faceroll = ...
end

local spec = Faceroll.createSpec("ROGUE", "fff469", "ROGUE-2")

-----------------------------------------------------------------------------------------
-- Macros (/frm)

spec.macros = {

["SS"] = [[
/cast @Sinister Strike@
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
    { "s_riposte", "Riposte" },

})

-----------------------------------------------------------------------------------------
-- Actions

spec.actions = {
    { "sinisterstrike",  macro = "SS" },
    { "eviscerate",      spell = "Eviscerate" },
    { "slice",           spell = "Slice and Dice" },
    { "riposte",         spell = "Riposte" },
    { "kick",            spell = "Kick" },
    { "garrote",         spell = "Garrote" },
    { "fanofknives",     spell = "Fan of Knives" },
    { "rupture",         spell = "Rupture" },
}

spec.calcAction = function(mode, state)
    -- local st = (mode == Faceroll.MODE_ST)
    local aoe = (mode == Faceroll.MODE_AOE)

    if state.targetingenemy then
        if aoe and state.melee and Faceroll.isActionAvailable("fanofknives") then
            return "fanofknives"

        elseif not aoe and state.b_stealth and Faceroll.isActionAvailable("garrote") then
            return "garrote"

        elseif not aoe and not state.d_rupture and state.combopoints >= 5 and Faceroll.isActionAvailable("rupture") then
            return "rupture"

        elseif not aoe and state.targetcasting and state.s_kick then
            return "kick"

        -- not aoe and state.d_rupture and
        elseif not state.b_slice and state.combopoints >= 2 and Faceroll.isActionAvailable("slice") then
            return "slice"

        elseif state.combopoints >= 5 then
            return "eviscerate"

        elseif state.s_riposte then
            return "riposte"

        else
            return "sinisterstrike"
        end

    end
end
