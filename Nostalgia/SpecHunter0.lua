-----------------------------------------------------------------------------------------
-- Nostalgia Classic Hunter (0)
--
-- Pet management (Call Pet, Mend Pet, etc.): manual
-- Close-range AOE: excluded (ranged class, melee not desirable)

if Faceroll == nil then
    _, Faceroll = ...
end

local spec = Faceroll.createSpec("HUNT", "abd473", "HUNTER-CLASSIC")

spec.buffs = {
    "Aspect of the Hawk",
}

-----------------------------------------------------------------------------------------
-- Macros (/frm)

spec.macros = {

["Raptor"] = [[
#showtooltip
/cast !@Raptor Strike@
/startAttack
]],

}

-----------------------------------------------------------------------------------------
-- States

spec.overlay = Faceroll.createOverlay({
    "- Debuffs -",
    { "d_serpentsting",  "Serpent Sting" },

    "- Spells -",
    { "s_raptor",        "Raptor Strike" },
})

-----------------------------------------------------------------------------------------
-- Actions

spec.actions = {
    { "autoshot",      spell = "Auto Shot" },
    { "serpentsting",  spell = "Serpent Sting" },
    { "raptor",        macro = "Raptor" },
}

spec.calcAction = function(mode, state)
    local aoe = (mode == Faceroll.MODE_AOE)

    if state.targetingenemy then
        -- Apply Serpent Sting if missing
        if not state.d_serpentsting and Faceroll.isActionAvailable("serpentsting") then
            return "serpentsting"

        -- Raptor Strike if in melee range
        elseif state.melee and state.s_raptor then
            return "raptor"

        -- Auto Shot filler (always running at range)
        else
            return "autoshot"
        end
    end
end
