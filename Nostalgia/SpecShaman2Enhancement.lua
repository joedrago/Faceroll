-----------------------------------------------------------------------------------------
-- Nostalgia Enhancement Shaman (2)

if Faceroll == nil then
    _, Faceroll = ...
end

local spec = Faceroll.createSpec("SHAM", "333399", "SHAMAN-2")

-----------------------------------------------------------------------------------------
-- Enemy Grid

-- Faceroll.enemyGridTrack(spec, "Rake", "RAKE", "621518")

-----------------------------------------------------------------------------------------
-- Macros (/frm)

spec.macros = {

["Earth Shock"] = [[
#showtooltip
/cast @Earth Shock@
/startAttack
]],

["Stormstrike"] = [[
#showtooltip
/cast @Stormstrike@
/startAttack
]],

["Stop"] = [[
/frstop
]],

}
-----------------------------------------------------------------------------------------
-- States

local healDeadzone = Faceroll.deadzoneCreate("Healing Wave", 1.5, 0.5)

spec.overlay = Faceroll.createOverlay({
    "- Buffs -",
    { "b_lightningshield", "Lightning Shield" },
    { "b_manaspring",  "Mana Spring" },

    "- Spells -",
    { "s_earthshock",  "Earth Shock" },
    { "s_windshear",   "Wind Shear" },
    { "s_stormstrike", "Stormstrike" },
    { "s_firenova",    "Fire Nova" },
    { "s_lavalash",    "Lava Lash" },
    { "s_rage",        "Shamanistic Rage" },

    "- Custom -",
    "totems_st",
    "totems_aoe",
    "healdeadzone",
    "targethp",
})

spec.calcState = function(state)
    if Faceroll.isTotemActive("Searing Totem") then
        state.totems_st = true
    end
    if Faceroll.isTotemActive("Magma Totem") then
        state.totems_aoe = true
    end
    state.healdeadzone = Faceroll.deadzoneUpdate(healDeadzone)

    state.targethp = 0
    if state.targetingenemy then
        local curHP = UnitHealth("target")
        local maxHP = UnitHealthMax("target")
        state.targethp = curHP / maxHP
    end
    return state
end

-----------------------------------------------------------------------------------------
-- Actions

spec.actions = {
    { "lightningbolt",   spell = "Lightning Bolt" },
    { "lightningshield", spell = "Lightning Shield" },
    { "earthshock",      macro = "Earth Shock" },
    { "stormstrike",     macro = "Stormstrike" },
    { "windshear",       spell = "Wind Shear" },
    { "firenova",        spell = "Fire Nova" },
    { "lavalash",        spell = "Lava Lash" },
    { "recall",          spell = "Totemic Recall" },
    { "totems_st",       spell = "Call of the Spirits" },
    { "totems_aoe",      spell = "Call of the Ancestors" },
    { "healself",        spell = "Healing Wave" },
    { "rage",            spell = "Shamanistic Rage" },
    { "stop",            macro = "Stop" },
}

spec.calcAction = function(mode, state)
    local aoe = (mode == Faceroll.MODE_AOE)

    if state.level < 25 then
        -- yes, it is this boring early-game
        return "lightningbolt"
    end

    if not state.b_lightningshield then
        return "lightningshield"

    elseif not state.combat and not state.group and state.hp < 0.6 and not state.healdeadzone then
        return "healself"

    elseif state.targetingenemy then
        if not aoe and state.targetcasting and state.s_windshear then
            return "windshear"

        elseif not aoe and state.group and state.melee and not state.totems_st then
            return "totems_st"
        elseif aoe and state.melee and not state.totems_aoe then
            return "totems_aoe"
        elseif state.melee and state.targethp > 0.8 and state.mana < 0.7 and state.s_rage then
            return "rage"

        elseif aoe and state.s_firenova then
            return "firenova"

        elseif state.melee and state.s_stormstrike then
            return "stormstrike"

        elseif state.melee and state.s_lavalash then
            return "lavalash"

        elseif state.s_earthshock then
            return "earthshock"

        else
            return "stormstrike"

        end

    elseif not state.combat and (state.totems_st or state.totems_aoe) and state.group then
        return "recall"

    elseif not state.combat and state.group then
        return "stop"

    end
end
