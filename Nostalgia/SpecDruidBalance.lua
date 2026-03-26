-----------------------------------------------------------------------------------------
-- Classic Balance Druid

if Faceroll == nil then
    _, Faceroll = ...
end

local spec = Faceroll.createSpec("BAL", "aa6600", "DRUID-1")
Faceroll.aliasSpec(spec, "DRUID-CLASSIC") -- pre-talent points

-----------------------------------------------------------------------------------------
-- Macros (/frm)

spec.macros = {

["Human"] = [[
/dismount
/cancelform
]],

["Dash"] = [[
#showtooltip Dash
/cast [noform:3] !@Cat Form@
/cast [form:3] @Dash@
]],

["Prowl"] = [[
#showtooltip
/cast [noform:3] !@Cat Form@
/cast [form:3] @Prowl@
]],

["Moonkin"] = [[
#showtooltip
/cast !@Moonkin Form@
]],

["Hurricane"] = [[
#showtooltip Hurricane
/stopmacro [channeling]
/stopmacro [noexist]
/say .cast @@Hurricane@@
]],

}

-----------------------------------------------------------------------------------------
-- States

spec.overlay = Faceroll.createOverlay({
    "- Stances -",
    { "b_moonkin",  "Moonkin Form" },

    "- Combat -",
    { "b_drink",    "Drink" },

    "- Debuffs -",
    { "d_moonfire", "Moonfire" },
    { "d_swarm",    "Insect Swarm" },

    "- Buffs -",
    { "b_lunar",    "Eclipse (Lunar)" },
})

spec.calcState = function(state)
    return state
end

-----------------------------------------------------------------------------------------
-- Actions

spec.actions = {
    { "moonkin",        macro = "Moonkin" },
    { "moonfire",       spell = "Moonfire" },
    { "wrath",          spell = "Wrath" },
    { "starfire",       spell = "Starfire" },
    { "hurricane",      macro = "Hurricane" },
    { "swarm",          spell = "Insect Swarm" },
    "drink",
}

spec.calcAction = function(mode, state)
    local aoe = (mode == Faceroll.MODE_AOE)

    if not state.b_moonkin and Faceroll.isActionAvailable("moonkin") then
        return "moonkin"

    elseif state.targetingenemy then
        if aoe and Faceroll.isActionAvailable("hurricane") then
            return "hurricane"

        elseif not state.d_moonfire and (state.group or state.combat) and Faceroll.isActionAvailable("moonfire") then
            return "moonfire"
        elseif not state.d_swarm and (state.group or state.combat) and Faceroll.isActionAvailable("swarm") then
            return "swarm"
        elseif state.b_lunar and Faceroll.isActionAvailable("starfire") then
            return "starfire"
        else
            return "wrath"
        end

    elseif state.mana < 0.9 and not state.combat and not state.b_drink and Faceroll.isActionAvailable("drink") then
        return "drink"
    end
end
