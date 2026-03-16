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
    "slice",
    "sinisterfinisher",
    "stealth",

    "- Dots -",
    "rupture",

    "- Spells -",
    "kick",
    "riposte",

    "- State -",
    "targetcasting",
})

spec.calcState = function(state)
    -- Buffs --

    if Faceroll.isBuffActive("Slice and Dice") then
        state.slice = true
    end
    if Faceroll.isBuffActive("Stealth") then
        state.stealth = true
    end

    if Faceroll.getDotRemainingNorm("Rupture") > 0 then
        state.rupture = true
    end

    -- Spells --

    if Faceroll.isSpellAvailable("Kick") then
        state.kick = true
    end
    if Faceroll.isSpellAvailable("Riposte") then
        state.riposte = true
    end

    local targetCastingSpell, _, _, _, targetCastingSpellEndTime = UnitCastingInfo("target")
    local targetCastingSpellDone = 0
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

        elseif not aoe and state.stealth then
            return "garrote"

        -- elseif not aoe and not state.rupture and state.combopoints >= 5 then
        --     return "rupture"

        elseif not aoe and state.targetcasting and state.kick then
            return "kick"

        -- not aoe and state.rupture and
        elseif not state.slice and state.combopoints >= 2 then
            return "slice"

        elseif state.combopoints >= 5 then
            return "eviscerate"

        elseif state.riposte then
            return "riposte"

        else
            return "sinisterstrike"
        end

    end
end
