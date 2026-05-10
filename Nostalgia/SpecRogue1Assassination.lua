-----------------------------------------------------------------------------------------
-- Nostalgia Assassination Rogue (1)

if Faceroll == nil then
    _, Faceroll = ...
end

local spec = Faceroll.createSpec("ASN", "cc4444", "ROGUE-1")

-- Big cooldowns (manually controlled): Vanish, Cold Blood, Cloak of Shadows

-----------------------------------------------------------------------------------------
-- Macros (/frm)

spec.macros = {

["Attack"] = [[
/startAttack
]],

["Mutilate"] = [[
/cast @Mutilate@
/startAttack
]],

}

-----------------------------------------------------------------------------------------
-- States

spec.overlay = Faceroll.createOverlay({
    "- Buffs -",
    { "b_slice",           "Slice and Dice" },
    { "b_stealth",         "Stealth" },
    { "b_hungerforblood",  "Hunger for Blood" },

    "- Dots -",
    { "d_rupture",         "Rupture" },

    "- Spells -",
    { "s_kick",            "Kick" },

})

-----------------------------------------------------------------------------------------
-- Actions

spec.actions = {
    { "mutilate",       macro = "Mutilate" },
    { "envenom",        spell = "Envenom" },
    { "slice",          spell = "Slice and Dice" },
    { "kick",           spell = "Kick" },
    { "garrote",        spell = "Garrote" },
    { "hungerforblood", spell = "Hunger for Blood" },
    { "rupture",        spell = "Rupture" },
    { "fanofknives",    spell = "Fan of Knives" },
}

spec.calcAction = function(mode, state)
    -- local st = (mode == Faceroll.MODE_ST)
    local aoe = (mode == Faceroll.MODE_AOE)

    if state.targetingenemy then
        if aoe and state.melee and Faceroll.isActionAvailable("fanofknives") then
            return "fanofknives"

        elseif not aoe and state.b_stealth and Faceroll.isActionAvailable("garrote") then
            return "garrote"

        elseif not aoe and state.targetcasting and state.s_kick then
            return "kick"

        elseif not state.b_hungerforblood and Faceroll.isActionAvailable("hungerforblood") then
            return "hungerforblood"

        elseif not state.b_slice and state.combopoints >= 1 and Faceroll.isActionAvailable("slice") then
            return "slice"

        elseif not aoe and not state.d_rupture and state.combopoints >= 5 and Faceroll.isActionAvailable("rupture") then
            return "rupture"

        elseif not aoe and state.combopoints >= 4 and Faceroll.isActionAvailable("envenom") then
            return "envenom"

        else
            return "mutilate"
        end

    end
end
