-----------------------------------------------------------------------------------------
-- Nostalgia Holy Paladin (1)
--
-- Avenging Wrath: manually controlled
-- Divine Favor: manually controlled

if Faceroll == nil then
    _, Faceroll = ...
end

local spec = Faceroll.createSpec("HPAL", "ffcc00", "PALADIN-1")

spec.buffs = {
    "Blessing of Wisdom",
}

-----------------------------------------------------------------------------------------
-- Macros (/frm)

spec.macros = {

["Attack"] = [[
/startAttack
]],

["Consecration"] = [[
#showtooltip Consecration
/stopmacro [channeling]
/stopmacro [noexist]
/say .cast @@Consecration@@
]],

["Cleanse"] = [[
#showtooltip
/cast [target=player] @Cleanse|Purify@
]],

}

-----------------------------------------------------------------------------------------
-- States

spec.overlay = Faceroll.createOverlay({
    "- Buffs -",
    { "b_seal",          "Seal of Wisdom" },

    "- Spells -",
    { "s_judgement",      "Judgement of Light" },
    { "s_holyshock",      "Holy Shock" },
    { "s_consecration",   "Consecration" },
})

-----------------------------------------------------------------------------------------
-- Actions

spec.actions = {
    { "attack",          macro = "Attack" },
    { "judgement",       spell = "Judgement of Light" },
    { "holyshock",       spell = "Holy Shock" },
    { "consecration",    macro = "Consecration" },
    { "healself",        spell = "Holy Light", deadzone = true },
    { "seal",            spell = "Seal of Wisdom" },
}

spec.calcAction = function(mode, state)
    local aoe = (mode == Faceroll.MODE_AOE)

    -- Keep seal up
    if not state.b_seal and Faceroll.isActionAvailable("seal") then
        return "seal"

    -- Self-heal when solo and low HP
    elseif not state.combat and not state.group and state.hp < 0.75 and not state.z_healself then
        return "healself"

    elseif state.targetingenemy then

        -- Holy Shock on cooldown (instant, talented)
        if state.s_holyshock then
            return "holyshock"

        -- Judgement on cooldown
        elseif state.s_judgement then
            return "judgement"

        -- Consecration in AOE
        elseif aoe and state.s_consecration then
            return "consecration"

        -- Filler
        else
            return "attack"
        end
    end
end
