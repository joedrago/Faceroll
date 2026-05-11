-----------------------------------------------------------------------------------------
-- Nostalgia Restoration Druid (3)
--
-- Tree of Life: manually controlled (group form, mana cost)
-- Tranquility: manually controlled (long cooldown, group heal)
-- Nature's Swiftness: manually controlled (emergency instant heal)

if Faceroll == nil then
    _, Faceroll = ...
end

local spec = Faceroll.createSpec("RDRU", "88ccaa", "DRUID-3")

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
/cast [noform:3] !@Cat Form@
/cast [form:3] @Prowl@
]],

["Rejuv"] = [[
#showtooltip
/cast [target=player] @Rejuvenation@
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
    "- Combat -",
    { "b_drink",    "Drink" },

    "- Debuffs -",
    { "d_moonfire", "Moonfire" },
    { "d_ff",       "Faerie Fire" },

    "- Buffs -",
    { "b_motw",     "Mark of the Wild" },
    { "b_thorns",   "Thorns" },
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
    { "wrath",          spell = "Wrath" },
    { "moonfire",       spell = "Moonfire" },
    { "hurricane",      macro = "Hurricane" },
    { "ff",             spell = "Faerie Fire" },
    { "rejuv",          macro = "Rejuv" },
    { "motw",           spell = "Mark of the Wild" },
    { "thorns",         spell = "Thorns" },
    "drink",
}

spec.calcAction = function(mode, state)
    local aoe = (mode == Faceroll.MODE_AOE)

    -- Preamble: self-buffs
    if not state.b_motw and Faceroll.isActionAvailable("motw") then
        return "motw"

    elseif not state.b_thorns and Faceroll.isActionAvailable("thorns") then
        return "thorns"

    -- Self-heal: solo only, instant HoT
    elseif not state.combat and not state.group and state.hp < 0.6 and not state.b_rejuv and Faceroll.isActionAvailable("rejuv") then
        return "rejuv"

    elseif state.targetingenemy then
        if aoe then
            return "hurricane"
        end

        -- ST priority
        if state.group and not state.d_ff and Faceroll.isActionAvailable("ff") then
            return "ff"
        elseif not state.d_moonfire and (state.group or state.combat) then
            return "moonfire"
        elseif state.moving then
            return "moonfire"
        else
            return "wrath"
        end

    elseif state.mana < 0.9 and not state.combat and not state.b_drink and Faceroll.isActionAvailable("drink") then
        return "drink"
    end
end
