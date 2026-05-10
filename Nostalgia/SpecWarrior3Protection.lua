-----------------------------------------------------------------------------------------
-- Nostalgia Protection Warrior (3)
--
-- Shield Wall, Last Stand: manually controlled
-- Bloodrage: manually controlled (rage timing is situational)

if Faceroll == nil then
    _, Faceroll = ...
end

local spec = Faceroll.createSpec("WAR", "ff6666", "WARRIOR-3")

spec.buffs = {
    "Battle Shout",
}

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

["Attack"] = [[
/startAttack
]],

}

-----------------------------------------------------------------------------------------
-- States

spec.overlay = Faceroll.createOverlay({
    "- Buffs -",
    { "b_battleshout", "Battle Shout" },

    "- Debuffs -",
    { "d_rend",      "Rend" },
    { "d_demoshout", "Demoralizing Shout" },

    "- Spells -",
    { "s_charge",    "Charge" },
    { "s_clap",      "Thunder Clap" },
    { "s_revenge",   "Revenge" },
    { "s_victoryrush", "Victory Rush" },
})

-----------------------------------------------------------------------------------------
-- Actions

spec.actions = {
    { "strike",        macro = "Heroic" },
    { "attack",        macro = "Attack" },
    { "charge",        spell = "Charge" },
    { "battleshout",   spell = "Battle Shout" },
    { "rend",          spell = "Rend" },
    { "clap",          spell = "Thunder Clap" },
    { "demoshout",     spell = "Demoralizing Shout" },
    { "revenge",       spell = "Revenge" },
    { "victoryrush",   spell = "Victory Rush" },
    { "cleave",        macro = "Cleave" },
}

spec.calcAction = function(mode, state)
    -- local st = (mode == Faceroll.MODE_ST)
    local aoe = (mode == Faceroll.MODE_AOE)

    -- Keep Battle Shout up
    if state.rage >= 10 and not state.b_battleshout and Faceroll.isActionAvailable("battleshout") then
        return "battleshout"

    elseif state.targetingenemy then
        if state.s_charge and not state.melee then
            return "charge"

        elseif state.melee and state.s_victoryrush then
            return "victoryrush"

        elseif state.rage >= 20 and state.melee and state.s_clap then
            return "clap"

        elseif state.rage >= 10 and state.melee and not state.d_demoshout and Faceroll.isActionAvailable("demoshout") then
            return "demoshout"

        elseif state.melee and state.s_revenge then
            return "revenge"

        elseif state.rage >= 10 and state.melee and not state.d_rend then
            return "rend"

        elseif aoe and Faceroll.isActionAvailable("cleave") then
            return "cleave"
        else
            return "strike"
        end
    end
end
