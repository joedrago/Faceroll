-----------------------------------------------------------------------------------------
-- Nostalgia Restoration Shaman (3)

if Faceroll == nil then
    _, Faceroll = ...
end

local spec = Faceroll.createSpec("RSHM", "44cc88", "SHAMAN-3")

spec.buffs = {
    "Water Shield",
}

-- Nature's Swiftness: manually controlled
-- Mana Tide Totem: manually controlled
-- Thunderstorm: excluded (close-range AOE in ranged spec)

-----------------------------------------------------------------------------------------
-- Macros (/frm)

spec.macros = {

["Riptide"] = [[
#showtooltip
/cast [target=player] @Riptide@
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
    { "b_watershield", "Water Shield" },
    { "b_riptide",     "Riptide" },

    "- Debuffs -",
    { "d_flameshock",  "Flame Shock" },

    "- Spells -",
    { "s_windshear",   "Wind Shear" },
})

-----------------------------------------------------------------------------------------
-- Actions

spec.actions = {
    { "lightningbolt",  spell = "Lightning Bolt" },
    { "watershield",    spell = "Water Shield" },
    { "riptide",        macro = "Riptide" },
    { "flameshock",     spell = "Flame Shock" },
    { "windshear",      spell = "Wind Shear" },
    { "healself",       spell = "Healing Wave", deadzone = true },
    "drink",
}

spec.calcAction = function(mode, state)
    local aoe = (mode == Faceroll.MODE_AOE)

    if not state.b_watershield then
        return "watershield"

    elseif not state.combat and not state.group and state.hp < 0.6 and not state.b_riptide and Faceroll.isActionAvailable("riptide") then
        return "riptide"

    elseif not state.combat and not state.group and state.hp < 0.6 and not Faceroll.isActionAvailable("riptide") and not state.z_healself then
        return "healself"

    elseif state.targetingenemy then
        if not aoe and state.targetcasting and state.s_windshear then
            return "windshear"

        elseif not state.d_flameshock and Faceroll.isActionAvailable("flameshock") then
            return "flameshock"

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
