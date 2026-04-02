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

local healDeadzone = Faceroll.deadzoneCreate("Holy Light", 1.5, 0.5)

spec.overlay = Faceroll.createOverlay({
    "- State -",
    "healdeadzone",

    "- Buffs -",
    { "b_seal",          "Seal of Righteousness" },

    "- Spells -",
    { "s_judgement",      "Judgement of Light" },
})

spec.calcState = function(state)
    Faceroll.deadzoneUpdate(healDeadzone)
    if Faceroll.deadzoneActive(healDeadzone) then
        state.healdeadzone = true
    end

    return state
end

-----------------------------------------------------------------------------------------
-- Actions

spec.actions = {
    { "attack",          macro = "Attack" },
    { "judgement",       spell = "Judgement of Light" },
    { "healself",        spell = "Holy Light" },
    { "seal",            spell = "Seal of Righteousness" },
}

spec.calcAction = function(mode, state)
    local aoe = (mode == Faceroll.MODE_AOE)

    -- Keep seal up
    if not state.b_seal and Faceroll.isActionAvailable("seal") then
        return "seal"

    -- Self-heal when solo and low HP
    elseif not state.combat and not state.group and state.hp < 0.75 and not state.healdeadzone then
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
