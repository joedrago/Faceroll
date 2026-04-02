-----------------------------------------------------------------------------------------
-- Nostalgia Classic Shaman (0)

if Faceroll == nil then
    _, Faceroll = ...
end

local spec = Faceroll.createSpec("SHMN", "0070de", "SHAMAN-CLASSIC")

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

    "- Spells -",
    { "s_earthshock",  "Earth Shock" },
})

spec.calcState = function(state)
    return state
end

-----------------------------------------------------------------------------------------
-- Actions

spec.actions = {
    { "lightningbolt",   spell = "Lightning Bolt" },
    { "lightningshield", spell = "Lightning Shield" },
    { "earthshock",      macro = "Earth Shock" },
    "drink",
}

spec.calcAction = function(mode, state)
    local aoe = (mode == Faceroll.MODE_AOE)

    if not state.b_lightningshield and Faceroll.isActionAvailable("lightningshield") then
        return "lightningshield"

    elseif state.targetingenemy then
        if state.s_earthshock then
            return "earthshock"

        else
            return "lightningbolt"

        end

    -- Drink when low mana
    elseif state.mana < 0.9 and not state.combat and not state.b_drink and Faceroll.isActionAvailable("drink") then
        return "drink"
    end
end
