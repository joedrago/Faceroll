-----------------------------------------------------------------------------------------
-- Nostalgia Blood Death Knight (1)
--
-- Vampiric Blood, Icebound Fortitude, Anti-Magic Shell: manually controlled
-- Dancing Rune Weapon: manually controlled (threat/parry timing)
-- Mark of Blood: manually controlled
-- Empower Rune Weapon: manually controlled (burst timing)

if Faceroll == nil then
    _, Faceroll = ...
end

local spec = Faceroll.createSpec("BLOOD", "cc3366", "DEATHKNIGHT-1")

-----------------------------------------------------------------------------------------
-- Macros (/frm)

spec.macros = {

["Attack"] = [[
/startAttack
]],

["RS"] = [[
/cast !@Rune Strike@
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
    { "b_hornofwinter",  "Horn of Winter" },
    { "b_boneshield",    "Bone Shield" },

    "- Debuffs -",
    { "d_frostfever",    "Frost Fever" },
    { "d_bloodplague",   "Blood Plague" },

    "- Spells -",
    { "s_icytouch",      "Icy Touch" },
    { "s_plaguestrike",  "Plague Strike" },
    { "s_heartstrike",   "Heart Strike" },
    { "s_deathstrike",   "Death Strike" },
    { "s_runestrike",    "Rune Strike" },
    { "s_deathcoil",     "Death Coil" },
    { "s_mindfreeze",    "Mind Freeze" },
    { "s_bloodboil",     "Blood Boil" },
    { "s_bloodstrike",   "Blood Strike" },
    { "s_deathgrip",     "Death Grip" },
})

spec.calcState = function(state)
    return state
end

-----------------------------------------------------------------------------------------
-- Actions

spec.actions = {
    { "runestrike",    macro = "RS" },
    { "attack",        macro = "Attack" },
    { "icytouch",      spell = "Icy Touch" },
    { "plaguestrike",  spell = "Plague Strike" },
    { "heartstrike",   spell = "Heart Strike" },
    { "deathstrike",   spell = "Death Strike" },
    { "deathcoil",     spell = "Death Coil" },
    { "hornofwinter",  spell = "Horn of Winter" },
    { "mindfreeze",    spell = "Mind Freeze" },
    { "bloodboil",     spell = "Blood Boil" },
    { "pestilence",    spell = "Pestilence" },
    { "dnd",           macro = "DnD" },
    { "bloodstrike",   spell = "Blood Strike" },
    { "boneshield",    spell = "Bone Shield" },
    { "deathgrip",     spell = "Death Grip" },
}

spec.calcAction = function(mode, state)
    -- local st = (mode == Faceroll.MODE_ST)
    local aoe = (mode == Faceroll.MODE_AOE)

    -- Keep Horn of Winter up
    if not state.b_hornofwinter and Faceroll.isActionAvailable("hornofwinter") then
        return "hornofwinter"

    -- Keep Bone Shield up (if talented via Unholy sub-spec)
    elseif not state.b_boneshield and Faceroll.isActionAvailable("boneshield") then
        return "boneshield"

    elseif state.targetingenemy then
        -- Interrupt
        if not aoe and state.targetcasting and state.s_mindfreeze then
            return "mindfreeze"

        -- Rune Strike (RP dump, on-next-hit — high priority for threat)
        elseif state.melee and state.runicpower >= 20 and state.s_runestrike then
            return "runestrike"

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

        -- Heart Strike (primary Blood rune spender, falls back to Blood Strike)
        elseif state.melee and state.s_heartstrike then
            return "heartstrike"
        elseif state.melee and state.s_bloodstrike then
            return "bloodstrike"

        -- Death Strike (Frost + Unholy runes, self-heal, generates death runes)
        elseif state.melee and state.s_deathstrike then
            return "deathstrike"

        -- Death Coil (RP dump when Rune Strike unavailable)
        elseif state.runicpower >= 40 and state.s_deathcoil then
            return "deathcoil"

        -- Horn of Winter as filler (generates RP when runes are on cooldown)
        elseif state.s_icytouch == false and state.s_plaguestrike == false and Faceroll.isActionAvailable("hornofwinter") then
            return "hornofwinter"

        -- Rune Strike includes /startAttack, prefer it over plain attack
        elseif Faceroll.isActionAvailable("runestrike") then
            return "runestrike"
        else
            return "attack"
        end
    end
end
