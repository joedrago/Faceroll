-----------------------------------------------------------------------------------------
-- Nostalgia Protection Paladin (2)
--
-- Avenging Wrath: manually controlled
-- Divine Protection: manually controlled

if Faceroll == nil then
    _, Faceroll = ...
end

local spec = Faceroll.createSpec("PPROT", "aabbdd", "PALADIN-2")

spec.buffs = {
    { "Blessing of Sanctuary|Greater Blessing of Sanctuary", "Blessing of Kings|Greater Blessing of Kings" },
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

["HotR"] = [[
#showtooltip
/cast @Hammer of the Righteous@
/startAttack
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
    { "b_seal",          "Seal of Vengeance" },
    { "b_holyshield",    "Holy Shield" },

    "- Spells -",
    { "s_judgement",      "Judgement of Light" },
    { "s_hotr",           "Hammer of the Righteous" },
    { "s_sor",            "Shield of Righteousness" },
    { "s_consecration",   "Consecration" },
    { "s_avengersshield", "Avenger's Shield" },
    { "s_holyshield",     "Holy Shield" },
})

-----------------------------------------------------------------------------------------
-- Actions

spec.actions = {
    { "attack",          macro = "Attack" },
    { "hotr",            macro = "HotR" },
    { "sor",             spell = "Shield of Righteousness" },
    { "judgement",       spell = "Judgement of Light" },
    { "consecration",    macro = "Consecration" },
    { "avengersshield",  spell = "Avenger's Shield" },
    { "holyshield",      spell = "Holy Shield" },
    { "healself",        spell = "Holy Light", deadzone = true },
    { "seal",            spell = "Seal of Vengeance" },
}

spec.calcAction = function(mode, state)
    local aoe = (mode == Faceroll.MODE_AOE)

    -- Keep seal up
    if not state.b_seal and Faceroll.isActionAvailable("seal") then
        return "seal"

    -- Holy Shield maintenance (buff check)
    elseif not state.b_holyshield and state.s_holyshield then
        return "holyshield"

    -- Self-heal when solo and low HP
    elseif not state.combat and not state.group and state.hp < 0.75 and not state.z_healself then
        return "healself"

    elseif state.targetingenemy then

        -- Pull with Avenger's Shield when not in combat
        if not state.combat and state.s_avengersshield then
            return "avengersshield"

        -- Holy Shield maintenance in combat
        elseif not state.b_holyshield and state.s_holyshield then
            return "holyshield"

        -- Hammer of the Righteous on cooldown
        elseif state.s_hotr then
            return "hotr"

        -- Shield of Righteousness on cooldown
        elseif state.s_sor then
            return "sor"

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
