-----------------------------------------------------------------------------------------
-- Nostalgia Frost Death Knight (2)
--
-- Unbreakable Armor: manually controlled (burst timing)
-- Empower Rune Weapon: manually controlled (burst timing)
-- Icebound Fortitude, Anti-Magic Shell: manually controlled

if Faceroll == nil then
    _, Faceroll = ...
end

local spec = Faceroll.createSpec("FROST", "aaccff", "DEATHKNIGHT-2")

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
    { "b_rime",          "Freezing Fog" },
    { "b_killingmachine", "Killing Machine" },

    "- Debuffs -",
    { "d_frostfever",    "Frost Fever" },
    { "d_bloodplague",   "Blood Plague" },

    "- Spells -",
    { "s_icytouch",      "Icy Touch" },
    { "s_plaguestrike",  "Plague Strike" },
    { "s_obliterate",    "Obliterate" },
    { "s_bloodstrike",   "Blood Strike" },
    { "s_froststrike",   "Frost Strike" },
    { "s_howlingblast",  "Howling Blast" },
    { "s_mindfreeze",    "Mind Freeze" },
    { "s_bloodboil",     "Blood Boil" },
    { "s_deathgrip",     "Death Grip" },
})

-----------------------------------------------------------------------------------------
-- Actions

spec.actions = {
    { "attack",        macro = "Attack" },
    { "obliterate",    spell = "Obliterate" },
    { "froststrike",   spell = "Frost Strike" },
    { "icytouch",      spell = "Icy Touch" },
    { "plaguestrike",  spell = "Plague Strike" },
    { "bloodstrike",   spell = "Blood Strike" },
    { "howlingblast",  spell = "Howling Blast" },
    { "hornofwinter",  spell = "Horn of Winter" },
    { "mindfreeze",    spell = "Mind Freeze" },
    { "bloodboil",     spell = "Blood Boil" },
    { "pestilence",    spell = "Pestilence" },
    { "dnd",           macro = "DnD" },
    { "deathcoil",     spell = "Death Coil" },
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

        -- Rime proc: free Howling Blast (high priority, expires quickly)
        elseif state.b_rime and state.s_howlingblast then
            return "howlingblast"

        -- Killing Machine proc: Frost Strike for auto-crit
        elseif state.b_killingmachine and state.runicpower >= 32 and state.s_froststrike then
            return "froststrike"

        -- Apply Frost Fever
        elseif not state.d_frostfever and state.s_icytouch then
            return "icytouch"

        -- Apply Blood Plague
        elseif not state.d_bloodplague and state.s_plaguestrike then
            return "plaguestrike"

        -- AOE: Death and Decay
        elseif aoe and state.melee and Faceroll.isActionAvailable("dnd") then
            return "dnd"

        -- AOE: Howling Blast (even without Rime)
        elseif aoe and state.s_howlingblast then
            return "howlingblast"

        -- AOE: Pestilence to spread diseases
        elseif aoe and state.d_frostfever and state.d_bloodplague and state.s_bloodboil and Faceroll.isActionAvailable("pestilence") then
            return "pestilence"

        -- AOE: Blood Boil
        elseif aoe and state.melee and state.s_bloodboil then
            return "bloodboil"

        -- Obliterate (main damage, Frost + Unholy runes)
        elseif state.melee and state.s_obliterate then
            return "obliterate"

        -- Blood Strike (Blood runes, converts to Death Runes via Blood of the North)
        elseif state.melee and state.s_bloodstrike then
            return "bloodstrike"

        -- Frost Strike (runic power dump)
        elseif state.runicpower >= 32 and state.s_froststrike then
            return "froststrike"

        -- Death Coil fallback (before Frost Strike is talented)
        elseif state.runicpower >= 40 and Faceroll.isActionAvailable("deathcoil") then
            return "deathcoil"

        -- Horn of Winter as filler (generates RP when runes are on cooldown)
        elseif Faceroll.isActionAvailable("hornofwinter") then
            return "hornofwinter"

        -- Auto-attack filler
        else
            return "attack"
        end
    end
end
