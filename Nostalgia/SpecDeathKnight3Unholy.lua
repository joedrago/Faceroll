-----------------------------------------------------------------------------------------
-- Nostalgia Unholy Death Knight (3)
--
-- Summon Gargoyle: manually controlled (snapshot timing with trinkets)
-- Empower Rune Weapon: manually controlled (burst timing)
-- Icebound Fortitude, Anti-Magic Shell: manually controlled
-- Unholy Frenzy: manually controlled (cast on self or ally)

if Faceroll == nil then
    _, Faceroll = ...
end

local spec = Faceroll.createSpec("UNH", "88cc33", "DEATHKNIGHT-3")

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
    { "b_hornofwinter",  "Horn of Winter" },
    { "b_boneshield",    "Bone Shield" },
    { "b_suddendoom",    "Sudden Doom" },

    "- Debuffs -",
    { "d_frostfever",    "Frost Fever" },
    { "d_bloodplague",   "Blood Plague" },

    "- Spells -",
    { "s_icytouch",      "Icy Touch" },
    { "s_plaguestrike",  "Plague Strike" },
    { "s_scourgestrike", "Scourge Strike" },
    { "s_bloodstrike",   "Blood Strike" },
    { "s_deathcoil",     "Death Coil" },
    { "s_mindfreeze",    "Mind Freeze" },
    { "s_bloodboil",     "Blood Boil" },
    { "s_deathstrike",   "Death Strike" },
    { "s_deathgrip",     "Death Grip" },
})

spec.calcState = function(state)
    return state
end

-----------------------------------------------------------------------------------------
-- Actions

spec.actions = {
    { "attack",         macro = "Attack" },
    { "scourgestrike",  spell = "Scourge Strike" },
    { "icytouch",       spell = "Icy Touch" },
    { "plaguestrike",   spell = "Plague Strike" },
    { "bloodstrike",    spell = "Blood Strike" },
    { "deathcoil",      spell = "Death Coil" },
    { "hornofwinter",   spell = "Horn of Winter" },
    { "mindfreeze",     spell = "Mind Freeze" },
    { "bloodboil",      spell = "Blood Boil" },
    { "pestilence",     spell = "Pestilence" },
    { "dnd",            macro = "DnD" },
    { "boneshield",     spell = "Bone Shield" },
    { "deathstrike",    spell = "Death Strike" },
    { "deathgrip",      spell = "Death Grip" },
}

spec.calcAction = function(mode, state)
    -- local st = (mode == Faceroll.MODE_ST)
    local aoe = (mode == Faceroll.MODE_AOE)

    -- Keep Horn of Winter up
    if not state.b_hornofwinter and Faceroll.isActionAvailable("hornofwinter") then
        return "hornofwinter"

    -- Keep Bone Shield up
    elseif not state.b_boneshield and Faceroll.isActionAvailable("boneshield") then
        return "boneshield"

    elseif state.targetingenemy then
        -- Interrupt
        if not aoe and state.targetcasting and state.s_mindfreeze then
            return "mindfreeze"

        -- Death Grip to pull (solo, out of combat)
        elseif not state.combat and not state.group and not state.melee and state.s_deathgrip then
            return "deathgrip"

        -- Sudden Doom proc: free Death Coil (use immediately)
        elseif state.b_suddendoom and state.s_deathcoil then
            return "deathcoil"

        -- Apply Frost Fever
        elseif not state.d_frostfever and state.s_icytouch then
            return "icytouch"

        -- Apply Blood Plague
        elseif not state.d_bloodplague and state.s_plaguestrike then
            return "plaguestrike"

        -- AOE: Death and Decay (enhanced by Unholy talents)
        elseif aoe and state.melee and Faceroll.isActionAvailable("dnd") then
            return "dnd"

        -- AOE: Pestilence to spread diseases
        elseif aoe and state.d_frostfever and state.d_bloodplague and state.s_bloodboil and Faceroll.isActionAvailable("pestilence") then
            return "pestilence"

        -- AOE: Blood Boil
        elseif aoe and state.melee and state.s_bloodboil then
            return "bloodboil"

        -- Scourge Strike (primary damage, Frost + Unholy runes)
        elseif state.melee and state.s_scourgestrike then
            return "scourgestrike"

        -- Blood Strike (Blood runes, converts to Death Runes via Reaping)
        elseif state.melee and state.s_bloodstrike then
            return "bloodstrike"

        -- Death Coil (runic power dump)
        elseif state.runicpower >= 40 and state.s_deathcoil then
            return "deathcoil"

        -- Death Strike fallback (before Scourge Strike is talented)
        elseif state.melee and state.s_deathstrike then
            return "deathstrike"

        -- Horn of Winter as filler (generates RP when runes are on cooldown)
        elseif Faceroll.isActionAvailable("hornofwinter") then
            return "hornofwinter"

        -- Auto-attack filler
        else
            return "attack"
        end
    end
end
