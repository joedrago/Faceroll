-----------------------------------------------------------------------------------------
-- Nostalgia Classic Paladin (0)
--
-- Avenging Wrath: not available at this level

if Faceroll == nil then
    _, Faceroll = ...
end

local spec = Faceroll.createSpec("PALA", "f58cba", "PALADIN-CLASSIC")

-----------------------------------------------------------------------------------------
-- Macros (/frm)

spec.macros = {

["Attack"] = [[
/startAttack
]],

["Cleanse"] = [[
#showtooltip
/cast [target=player] @Cleanse|Purify@
]],

}

-----------------------------------------------------------------------------------------
-- States

spec.overlay = Faceroll.createOverlay({
    "- Buffs -",
    { "b_seal",          "Seal of Righteousness" },

    "- Spells -",
    { "s_judgement",      "Judgement of Light" },
})

-----------------------------------------------------------------------------------------
-- Actions

spec.actions = {
    { "attack",          macro = "Attack" },
    { "judgement",       spell = "Judgement of Light" },
    { "healself",        spell = "Holy Light", deadzone = true },
    { "seal",            spell = "Seal of Righteousness" },
}

spec.calcAction = function(mode, state)
    local aoe = (mode == Faceroll.MODE_AOE)

    -- Keep seal up
    if not state.b_seal and Faceroll.isActionAvailable("seal") then
        return "seal"

    -- Self-heal when solo and low HP
    elseif not state.combat and not state.group and state.hp < 0.75 and not state.z_healself then
        return "healself"

    elseif state.targetingenemy then

        -- Judgement on cooldown
        if state.s_judgement then
            return "judgement"

        -- Filler
        else
            return "attack"
        end
    end
end
