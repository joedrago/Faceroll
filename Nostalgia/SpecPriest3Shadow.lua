-----------------------------------------------------------------------------------------
-- Nostalgia Shadow Priest (3)

if Faceroll == nil then
    _, Faceroll = ...
end

local spec = Faceroll.createSpec("SPVE", "dd88dd", "PRIEST-3")

Faceroll.enemyGridTrack(spec, "Shadow Word: Pain", "SWP", "621518")
Faceroll.enemyGridTrack(spec, "Devouring Plague", "DP", "621562")

-----------------------------------------------------------------------------------------
-- States

spec.overlay = Faceroll.createOverlay({
    "- Buffs -",
    { "b_innerfire",      "Inner Fire" },

    "- Debuffs -",
    { "d_pain",           "Shadow Word: Pain" },
    { "d_devouringplague", "Devouring Plague" },
    { "d_vampirictouch",  "Vampiric Touch" },

    "- Spells -",
    { "s_mindblast",      "Mind Blast" },
})

-----------------------------------------------------------------------------------------
-- Actions

spec.actions = {
    { "innerfire",       spell = "Inner Fire", },
    { "pain",            spell = "Shadow Word: Pain", },
    { "devouringplague", spell = "Devouring Plague", },
    { "mindblast",       spell = "Mind Blast", },
    { "mindflay",        spell = "Mind Flay", },
    { "mindsear",        spell = "Mind Sear", },
    { "vampirictouch",   spell = "Vampiric Touch", deadzone = true },
}

spec.calcAction = function(mode, state)
    local aoe = (mode == Faceroll.MODE_AOE)

    if not state.b_innerfire then
        return "innerfire"

    elseif state.targetingenemy then
        if aoe then
            return "mindsear"

        -- When solo and not in combat, lead with Mind Blast before dots
        elseif not state.combat and not state.group and state.s_mindblast then
            return "mindblast"

        elseif not state.d_pain then
            return "pain"

        elseif not state.d_vampirictouch and not state.z_vampirictouch then
            return "vampirictouch"

        elseif not aoe and not state.d_devouringplague then
            return "devouringplague"

        elseif state.s_mindblast then
            return "mindblast"

        else
            return "mindflay"

        end
    end

    return nil
end
