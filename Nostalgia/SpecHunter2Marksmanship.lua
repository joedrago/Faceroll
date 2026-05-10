-----------------------------------------------------------------------------------------
-- Nostalgia Marksmanship Hunter (2)
--
-- Readiness: manually controlled
-- Rapid Fire: manually controlled
-- Pet management (Call Pet, Mend Pet, etc.): manual

if Faceroll == nil then
    _, Faceroll = ...
end

local spec = Faceroll.createSpec("MM", "44bbcc", "HUNTER-2")

spec.buffs = {
    { "Aspect of the Dragonhawk", "Aspect of the Hawk" },
}

-----------------------------------------------------------------------------------------
-- Macros (/frm)

spec.macros = {

["Aspect"] = [[
#showtooltip
/cast @Aspect of the Dragonhawk|Aspect of the Hawk@
]],

["Volley"] = [[
#showtooltip Volley
/stopmacro [channeling]
/stopmacro [noexist]
/say .cast @@Volley@@
]],

["Aimed"] = [[
#showtooltip
/cast @Aimed Shot@
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
    { "s_chimera",       "Chimera Shot" },
    { "s_aimed",         "Aimed Shot" },
    { "s_arcaneshot",    "Arcane Shot" },
    { "s_multishot",     "Multi-Shot" },
    { "s_killshot",      "Kill Shot" },
    { "s_silencing",     "Silencing Shot" },

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
    { "chimera",       spell = "Chimera Shot" },
    { "aimed",         macro = "Aimed" },
    { "arcaneshot",    spell = "Arcane Shot" },
    { "multishot",     spell = "Multi-Shot" },
    { "steadyshot",    spell = "Steady Shot" },
    { "killshot",      spell = "Kill Shot" },
    { "silencing",     spell = "Silencing Shot" },
    { "volley",        macro = "Volley" },
    { "huntersmark",   macro = "HMark" },
}

spec.calcAction = function(mode, state)
    local aoe = (mode == Faceroll.MODE_AOE)

    -- Aspect maintenance (Dragonhawk upgrades Hawk at higher levels)
    if not state.b_aspect and not state.b_aspecthawk and Faceroll.isActionAvailable("aspect") then
        return "aspect"

    elseif state.targetingenemy then
        -- Silencing Shot interrupt
        if state.targetcasting and state.s_silencing then
            return "silencing"

        -- Hunter's Mark (ST only)
        elseif not aoe and not state.d_huntersmark and Faceroll.isActionAvailable("huntersmark") then
            return "huntersmark"

        -- Kill Shot execute (< 20% HP)
        elseif state.targethp > 0 and state.targethp < 0.2 and state.s_killshot then
            return "killshot"

        -- Serpent Sting maintenance (ST only, Chimera Shot refreshes it)
        elseif not aoe and not state.d_serpentsting and Faceroll.isActionAvailable("serpentsting") then
            return "serpentsting"

        -- Chimera Shot on CD (ST only, refreshes Serpent Sting)
        elseif not aoe and state.s_chimera then
            return "chimera"

        -- Multi-Shot on CD (AOE only)
        elseif aoe and state.s_multishot then
            return "multishot"

        -- Aimed Shot on CD (ST only)
        elseif not aoe and state.s_aimed then
            return "aimed"

        -- Volley (AOE filler)
        elseif aoe then
            return "volley"

        -- Arcane Shot (ST, leveling filler before Chimera Shot)
        elseif state.s_arcaneshot then
            return "arcaneshot"

        -- Steady Shot (ST filler)
        elseif Faceroll.isActionAvailable("steadyshot") then
            return "steadyshot"

        -- Auto Shot fallback
        else
            return "autoshot"
        end
    end
end
