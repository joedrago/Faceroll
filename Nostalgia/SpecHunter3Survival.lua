-----------------------------------------------------------------------------------------
-- Nostalgia Survival Hunter (3)
--
-- Readiness: manually controlled
-- Pet management (Call Pet, Mend Pet, etc.): manual
-- Close-range AOE: excluded (ranged class, melee not desirable)
-- No spec-specific interrupt (no Silencing Shot)

if Faceroll == nil then
    _, Faceroll = ...
end

local spec = Faceroll.createSpec("SURV", "88aa44", "HUNTER-3")

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
    { "b_lockandload",   "Lock and Load" },

    "- Debuffs -",
    { "d_serpentsting",  "Serpent Sting" },
    { "d_blackarrow",    "Black Arrow" },
    { "d_huntersmark",   "Hunter's Mark" },

    "- Spells -",
    { "s_explosiveshot", "Explosive Shot" },
    { "s_killshot",      "Kill Shot" },
    { "s_multishot",     "Multi-Shot" },
    { "s_blackarrow",    "Black Arrow" },
    { "s_aimed",         "Aimed Shot" },

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
    { "autoshot",       spell = "Auto Shot" },
    { "aspect",         macro = "Aspect" },
    { "serpentsting",   spell = "Serpent Sting" },
    { "explosiveshot",  spell = "Explosive Shot" },
    { "blackarrow",     spell = "Black Arrow" },
    { "aimed",          spell = "Aimed Shot" },
    { "steadyshot",     spell = "Steady Shot" },
    { "killshot",       spell = "Kill Shot" },
    { "multishot",      spell = "Multi-Shot" },
    { "huntersmark",    macro = "HMark" },
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

        -- Explosive Shot on cooldown (Lock and Load allows free back-to-back casts)
        elseif state.s_explosiveshot then
            return "explosiveshot"

        -- Multi-Shot in AOE
        elseif aoe and state.s_multishot then
            return "multishot"

        -- Black Arrow maintenance
        elseif not state.d_blackarrow and state.s_blackarrow then
            return "blackarrow"

        -- Serpent Sting maintenance
        elseif not state.d_serpentsting and Faceroll.isActionAvailable("serpentsting") then
            return "serpentsting"

        -- Aimed Shot
        elseif state.s_aimed then
            return "aimed"

        -- Steady Shot filler
        elseif Faceroll.isActionAvailable("steadyshot") then
            return "steadyshot"

        -- Auto Shot fallback
        else
            return "autoshot"
        end
    end
end
