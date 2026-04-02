-----------------------------------------------------------------------------------------
-- Nostalgia Beast Mastery Hunter (1)
--
-- Bestial Wrath: manually controlled
-- Intimidation: manually controlled
-- Pet management (Call Pet, Mend Pet, etc.): manual
-- Close-range AOE: excluded (ranged class, melee not desirable)

if Faceroll == nil then
    _, Faceroll = ...
end

local spec = Faceroll.createSpec("BM", "abd473", "HUNTER-1")

-----------------------------------------------------------------------------------------
-- Macros (/frm)

spec.macros = {

["Aspect"] = [[
#showtooltip
/cast @Aspect of the Dragonhawk|Aspect of the Hawk@
]],

["HMark"] = [[
#showtooltip
/cast @Hunter's Mark@
]],

}

-----------------------------------------------------------------------------------------
-- States

spec.overlay = Faceroll.createOverlay({
    "- Buffs -",
    { "b_aspect",        "Aspect of the Dragonhawk" },
    { "b_aspecthawk",    "Aspect of the Hawk" },

    "- Debuffs -",
    { "d_serpentsting",  "Serpent Sting" },
    { "d_huntersmark",   "Hunter's Mark" },

    "- Spells -",
    { "s_killcommand",   "Kill Command" },
    { "s_arcaneshot",    "Arcane Shot" },
    { "s_multishot",     "Multi-Shot" },
    { "s_killshot",      "Kill Shot" },

    "- Custom -",
    "targethp",
})

spec.calcState = function(state)
    state.targethp = 0
    if state.targetingenemy then
        state.targethp = UnitHealth("target") / UnitHealthMax("target")
    end

    return state
end

-----------------------------------------------------------------------------------------
-- Actions

spec.actions = {
    { "autoshot",      spell = "Auto Shot" },
    { "aspect",        macro = "Aspect" },
    { "serpentsting",  spell = "Serpent Sting" },
    { "killcommand",  spell = "Kill Command" },
    { "arcaneshot",    spell = "Arcane Shot" },
    { "multishot",     spell = "Multi-Shot" },
    { "steadyshot",    spell = "Steady Shot" },
    { "killshot",      spell = "Kill Shot" },
    { "huntersmark",   macro = "HMark" },
}

spec.calcAction = function(mode, state)
    local aoe = (mode == Faceroll.MODE_AOE)

    -- Aspect maintenance (Dragonhawk upgrades Hawk at higher levels)
    if not state.b_aspect and not state.b_aspecthawk and Faceroll.isActionAvailable("aspect") then
        return "aspect"

    elseif state.targetingenemy then
        -- Hunter's Mark on target
        if not state.d_huntersmark and Faceroll.isActionAvailable("huntersmark") then
            return "huntersmark"

        -- Kill Shot execute (< 20% HP)
        elseif state.targethp > 0 and state.targethp < 0.2 and state.s_killshot then
            return "killshot"

        -- Serpent Sting maintenance
        elseif not state.d_serpentsting and Faceroll.isActionAvailable("serpentsting") then
            return "serpentsting"

        -- Kill Command on cooldown
        elseif state.s_killcommand then
            return "killcommand"

        -- Multi-Shot in AOE
        elseif aoe and state.s_multishot then
            return "multishot"

        -- Arcane Shot
        elseif state.s_arcaneshot then
            return "arcaneshot"

        -- Steady Shot filler
        elseif Faceroll.isActionAvailable("steadyshot") then
            return "steadyshot"

        -- Auto Shot fallback
        else
            return "autoshot"
        end
    end
end
