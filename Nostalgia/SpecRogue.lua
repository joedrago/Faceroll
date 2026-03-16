-----------------------------------------------------------------------------------------
-- Nostalgia Combat Rogue

if Faceroll == nil then
    _, Faceroll = ...
end

local spec = Faceroll.createSpec("ROGUE", "fff469", "ROGUE-2")

-----------------------------------------------------------------------------------------
-- States

spec.overlay = Faceroll.createOverlay({
    "- Buffs -",
    { "b_slice", "Slice and Dice" },
    "sinisterfinisher",
    { "b_stealth", "Stealth" },

    "- Dots -",
    { "d_rupture", "Rupture" },

    "- Spells -",
    { "s_kick", "Kick" },
    { "s_riposte", "Riposte" },

    "- State -",
    "targetcasting",
})

spec.calcState = function(state)
    local targetCastingSpell, _, _, _, targetCastingSpellEndTime = UnitCastingInfo("target")
    if targetCastingSpell then
        state.targetcasting = true
    end

    return state
end

-----------------------------------------------------------------------------------------
-- Actions

spec.actions = {
    "sinisterstrike",
    "eviscerate",
    "slice",
    "riposte",
    "kick",
    "garrote",
    "fanofknives",
    -- "rupture",
}

spec.calcAction = function(mode, state)
    -- local st = (mode == Faceroll.MODE_ST)
    local aoe = (mode == Faceroll.MODE_AOE)

    if state.targetingenemy then
        if aoe and state.melee then
            return "fanofknives"

        elseif not aoe and state.b_stealth then
            return "garrote"

        -- elseif not aoe and not state.d_rupture and state.combopoints >= 5 then
        --     return "rupture"

        elseif not aoe and state.targetcasting and state.s_kick then
            return "kick"

        -- not aoe and state.d_rupture and
        elseif not state.b_slice and state.combopoints >= 2 then
            return "slice"

        elseif state.combopoints >= 5 then
            return "eviscerate"

        elseif state.s_riposte then
            return "riposte"

        else
            return "sinisterstrike"
        end

    end
end
