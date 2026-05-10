-----------------------------------------------------------------------------------------
-- Nostalgia Classic Death Knight (0)
--
-- Icebound Fortitude, Anti-Magic Shell: manually controlled
-- Empower Rune Weapon: manually controlled (burst timing)

if Faceroll == nil then
    _, Faceroll = ...
end

local spec = Faceroll.createSpec("DK", "cc3366", "DEATHKNIGHT-CLASSIC")

spec.buffs = {
    "Horn of Winter",
}

-----------------------------------------------------------------------------------------
-- Macros (/frm)

spec.macros = {

["Attack"] = [[
/startAttack
]],

["DnD"] = [[
#showtooltip Death and Decay
/stopmacro [noexist]
/say .cast @@Death and Decay@@
]],

}

-----------------------------------------------------------------------------------------
-- States

spec.overlay = Faceroll.createOverlay({
    "- Buffs -",
    { "b_hornofwinter", "Horn of Winter" },

    "- Debuffs -",
    { "d_frostfever",   "Frost Fever" },
    { "d_bloodplague",  "Blood Plague" },

    "- Spells -",
    { "s_icytouch",     "Icy Touch" },
    { "s_plaguestrike", "Plague Strike" },
    { "s_bloodstrike",  "Blood Strike" },
    { "s_deathstrike",  "Death Strike" },
    { "s_deathcoil",    "Death Coil" },
    { "s_mindfreeze",   "Mind Freeze" },
    { "s_bloodboil",    "Blood Boil" },
    { "s_deathgrip",    "Death Grip" },
})

spec.calcState = function(state)
    return state
end

-----------------------------------------------------------------------------------------
-- Actions

spec.actions = {
    { "attack",        macro = "Attack" },
    { "icytouch",      spell = "Icy Touch" },
    { "plaguestrike",  spell = "Plague Strike" },
    { "bloodstrike",   spell = "Blood Strike" },
    { "deathstrike",   spell = "Death Strike" },
    { "deathcoil",     spell = "Death Coil" },
    { "hornofwinter",  spell = "Horn of Winter" },
    { "mindfreeze",    spell = "Mind Freeze" },
    { "bloodboil",     spell = "Blood Boil" },
    { "pestilence",    spell = "Pestilence" },
    { "dnd",           macro = "DnD" },
    { "deathgrip",     spell = "Death Grip" },
}

spec.calcAction = function(mode, state)
    -- local st = (mode == Faceroll.MODE_ST)
    local aoe = (mode == Faceroll.MODE_AOE)

    -- Keep Horn of Winter up
    if not state.b_hornofwinter and Faceroll.isActionAvailable("hornofwinter") then
        return "hornofwinter"

    elseif state.targetingenemy then
        -- Interrupt
        if not aoe and state.targetcasting and state.s_mindfreeze then
            return "mindfreeze"

        -- Death Grip to pull (solo, out of combat)
        elseif not state.combat and not state.group and not state.melee and state.s_deathgrip then
            return "deathgrip"

        -- Apply Frost Fever
        elseif not state.d_frostfever and state.s_icytouch then
            return "icytouch"

        -- Apply Blood Plague
        elseif not state.d_bloodplague and state.s_plaguestrike then
            return "plaguestrike"

        -- AOE: Death and Decay
        elseif aoe and state.melee and Faceroll.isActionAvailable("dnd") then
            return "dnd"

        -- AOE: Pestilence to spread diseases
        elseif aoe and state.d_frostfever and state.d_bloodplague and state.s_bloodboil and Faceroll.isActionAvailable("pestilence") then
            return "pestilence"

        -- AOE: Blood Boil
        elseif aoe and state.melee and state.s_bloodboil then
            return "bloodboil"

        -- Death Strike for healing
        elseif state.melee and state.s_deathstrike then
            return "deathstrike"

        -- Blood Strike
        elseif state.melee and state.s_bloodstrike then
            return "bloodstrike"

        -- Death Coil (runic power dump)
        elseif state.runicpower >= 40 and state.s_deathcoil then
            return "deathcoil"

        -- Auto-attack filler
        else
            return "attack"
        end
    end
end
