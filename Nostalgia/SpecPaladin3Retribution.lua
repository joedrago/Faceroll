-----------------------------------------------------------------------------------------
-- Nostalgia Retribution Paladin (3)
--
-- Avenging Wrath: manually controlled
-- Divine Shield: manually controlled

if Faceroll == nil then
    _, Faceroll = ...
end

local spec = Faceroll.createSpec("PAL", "ffffaa", "PALADIN-3")

-----------------------------------------------------------------------------------------
-- Macros (/frm)

spec.macros = {

["Attack"] = [[
/startAttack
]],

["CS"] = [[
#showtooltip
/cast @Crusader Strike@
/startAttack
]],

["Consecration"] = [[
#showtooltip Consecration
/stopmacro [channeling]
/stopmacro [noexist]
/say .cast @@Consecration@@
]],

}

-----------------------------------------------------------------------------------------
-- States

spec.overlay = Faceroll.createOverlay({
    "- Buffs -",
    { "b_seal",          "Seal of Command" },

    "- Procs -",
    { "b_artofwar",      "The Art of War" },

    "- Spells -",
    { "s_judgement",      "Judgement of Light" },
    { "s_cs",             "Crusader Strike" },
    { "s_ds",             "Divine Storm" },
    { "s_consecration",   "Consecration" },
    { "s_exorcism",       "Exorcism" },
    { "s_handofreckoning", "Hand of Reckoning" },
})

-----------------------------------------------------------------------------------------
-- Actions

spec.actions = {
    { "attack",          macro = "Attack" },
    { "cs",              macro = "CS" },
    { "judgement",       spell = "Judgement of Light" },
    { "ds",              spell = "Divine Storm" },
    { "exorcism",        spell = "Exorcism" },
    { "consecration",    macro = "Consecration" },
    { "handofreckoning", spell = "Hand of Reckoning" },
    { "healself",        spell = "Holy Light", deadzone = true },
    { "seal",            spell = "Seal of Command" },
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

        -- Solo pull with taunt
        if not state.combat and not state.group and state.s_handofreckoning then
            return "handofreckoning"

        -- Art of War proc: instant Exorcism
        elseif state.b_artofwar and state.s_exorcism then
            return "exorcism"

        -- Judgement on cooldown
        elseif state.s_judgement then
            return "judgement"

        -- Crusader Strike on cooldown
        elseif state.s_cs then
            return "cs"

        -- Divine Storm on cooldown
        elseif state.s_ds then
            return "ds"

        -- Consecration in AOE
        elseif aoe and state.s_consecration then
            return "consecration"

        -- Filler
        else
            return "attack"
        end
    end
end
