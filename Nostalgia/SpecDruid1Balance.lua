-----------------------------------------------------------------------------------------
-- Nostalgia Balance Druid (1)
--
-- Starfall: manually controlled
-- Force of Nature (Treants): manually controlled
-- Typhoon: manually controlled (push/interrupt, unglyphed knockback annoys tanks)

if Faceroll == nil then
    _, Faceroll = ...
end

local spec = Faceroll.createSpec("BAL", "aa6600", "DRUID-1")

spec.buffs = {
    "Mark of the Wild|Gift of the Wild",
    "Thorns",
}

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
/cancelform [noform:3]
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

["Rejuv"] = [[
#showtooltip
/cast [target=player] @Rejuvenation@
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
    { "d_ff",       "Faerie Fire" },

    "- Buffs -",
    { "b_lunar",    "Eclipse (Lunar)" },    -- Solar not tracked: Wrath is already the default filler
    { "b_rejuv",    "Rejuvenation" },

    "- Custom -",
    "moving",
})

spec.calcState = function(state)
    state.moving = Faceroll.moving
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
    { "ff",             spell = "Faerie Fire" },
    { "rejuv",          macro = "Rejuv" },
    "drink",
}

spec.calcAction = function(mode, state)
    local aoe = (mode == Faceroll.MODE_AOE)

    if not state.b_moonkin and Faceroll.isActionAvailable("moonkin") then
        return "moonkin"

    elseif not state.combat and not state.group and state.hp < 0.6 and not state.b_rejuv and Faceroll.isActionAvailable("rejuv") then
        return "rejuv"

    elseif state.targetingenemy then
        if aoe then
            return "hurricane"
        end

        -- ST priority
        if state.group and not state.d_ff and Faceroll.isActionAvailable("ff") then
            return "ff"
        elseif state.group and not state.d_swarm and Faceroll.isActionAvailable("swarm") then
            return "swarm"
        elseif not state.d_moonfire and (state.group or state.combat) then
            return "moonfire"
        elseif state.b_lunar and Faceroll.isActionAvailable("starfire") then
            return "starfire"
        elseif state.moving then
            return "moonfire"
        else
            return "wrath"
        end

    elseif state.mana < 0.9 and not state.combat and not state.b_drink and Faceroll.isActionAvailable("drink") then
        return "drink"
    end
end
