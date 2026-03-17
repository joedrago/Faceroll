-----------------------------------------------------------------------------------------
-- Classic Prot Warrior

if Faceroll == nil then
    _, Faceroll = ...
end

local spec = Faceroll.createSpec("WAR", "ff6666", "WARRIOR-3")

-----------------------------------------------------------------------------------------
-- Macros (/frm)

spec.macros = {

["Heroic"] = [[
/cast !@Heroic Strike@
/startAttack
]],

["Cleave"] = [[
/cast !@Cleave@
/startAttack
]],

}

-----------------------------------------------------------------------------------------
-- States

spec.overlay = Faceroll.createOverlay({
    "- Buffs -",
    "battleshout",

    "- Debuffs -",
    { "d_rend",      "Rend" },
    { "d_demoshout", "Demoralizing Shout" },

    "- Spells -",
    { "s_charge",    "Charge" },
    { "s_clap",      "Thunder Clap" },
    { "s_revenge",   "Revenge" },
    { "s_bloodrage", "Bloodrage" },
})

spec.calcState = function(state)
    return state
end

-----------------------------------------------------------------------------------------
-- Actions

spec.actions = {
    { "strike",     macro = "Heroic" },
    { "charge",     spell = "Charge" },
    { "rend",       spell = "Rend" },
    { "clap",       spell = "Thunder Clap" },
    { "bloodrage",  spell = "Bloodrage" },
    { "demoshout",  spell = "Demoralizing Shout" },
    { "revenge",    spell = "Revenge" },
    { "cleave",     macro = "Cleave" },
}

spec.calcAction = function(mode, state)
    -- local st = (mode == Faceroll.MODE_ST)
    local aoe = (mode == Faceroll.MODE_AOE)

    if state.targetingenemy then
        -- if state.bloodrage then
        --     return "bloodrage"

        if state.s_charge and not state.melee then
            return "charge"

        elseif state.rage >= 20 and state.melee and state.s_clap then
            return "clap"

        elseif state.rage >= 10 and state.melee and not state.d_demoshout and Faceroll.isActionAvailable("demoshout") then
            return "demoshout"

        elseif state.melee and state.s_revenge then
            return "revenge"

        -- elseif state.rage >= 10 and not state.d_rend then
        --     return "rend"

        elseif aoe and Faceroll.isActionAvailable("cleave") then
            return "cleave"
        else
            return "strike"
        end
    end
end
