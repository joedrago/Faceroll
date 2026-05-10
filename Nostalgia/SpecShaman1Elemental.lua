-----------------------------------------------------------------------------------------
-- Nostalgia Elemental Shaman (1)

if Faceroll == nil then
    _, Faceroll = ...
end

local spec = Faceroll.createSpec("ELE", "44aaff", "SHAMAN-1")

-- Elemental Mastery: manually controlled
-- Thunderstorm: excluded (close-range AOE in ranged spec)

-----------------------------------------------------------------------------------------
-- Macros (/frm)

spec.macros = {

["Earth Shock"] = [[
#showtooltip
/cast @Earth Shock@
/startAttack
]],

["Ghost Wolf"] = [[
#showtooltip
/cast @Ghost Wolf@
]],

["Stop"] = [[
/frstop
]],

}
-----------------------------------------------------------------------------------------
-- States

spec.overlay = Faceroll.createOverlay({
    "- Buffs -",
    { "b_lightningshield", "Lightning Shield" },

    "- Debuffs -",
    { "d_flameshock",  "Flame Shock" },

    "- Spells -",
    { "s_lavaburst",      "Lava Burst" },
    { "s_windshear",      "Wind Shear" },
    { "s_chainlightning", "Chain Lightning" },
})

-----------------------------------------------------------------------------------------
-- Actions

spec.actions = {
    { "lightningbolt",   spell = "Lightning Bolt" },
    { "lightningshield", spell = "Lightning Shield" },
    { "flameshock",      spell = "Flame Shock" },
    { "lavaburst",       spell = "Lava Burst" },
    { "chainlightning",  spell = "Chain Lightning" },
    { "windshear",       spell = "Wind Shear" },
    { "earthshock",      macro = "Earth Shock" },
    { "healself",        spell = "Healing Wave", deadzone = true },
    { "totems",          spell = "Call of the Spirits" },
    { "recall",          spell = "Totemic Recall" },
    "drink",
}

spec.calcAction = function(mode, state)
    local aoe = (mode == Faceroll.MODE_AOE)

    if not state.b_lightningshield then
        return "lightningshield"

    elseif not state.combat and not state.group and state.hp < 0.6 and not state.z_healself then
        return "healself"

    elseif state.targetingenemy then
        if not aoe and state.targetcasting and state.s_windshear then
            return "windshear"

        elseif not state.d_flameshock and Faceroll.isActionAvailable("flameshock") then
            return "flameshock"

        elseif state.s_lavaburst then
            return "lavaburst"

        elseif aoe and state.s_chainlightning then
            return "chainlightning"

        elseif state.s_earthshock then
            return "earthshock"

        else
            return "lightningbolt"

        end

    -- Drink when low mana
    elseif state.mana < 0.9 and not state.combat and not state.b_drink and Faceroll.isActionAvailable("drink") then
        return "drink"

    elseif not state.combat and state.group then
        return nil

    end
end
