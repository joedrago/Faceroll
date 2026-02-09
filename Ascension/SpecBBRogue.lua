-----------------------------------------------------------------------------------------
-- Ascension WoW Bronzebeard Rogue

if Faceroll == nil then
    _, Faceroll = ...
end

local spec = Faceroll.createSpec("R", "fff469", "ROGUE-ASCENSION")

spec.melee = "Sinister Strike"

-----------------------------------------------------------------------------------------
-- States

spec.overlay = Faceroll.createOverlay({
    -- "- Resources -",
    -- "selfheal",

    "- Buffs -",
    "slice",
    "sinisterfinisher",
    "stealth",

    "- Dots -",
    "rupture",

    "- Spells -",
    "kick",
    -- "judgement",

    "- State -",
    "targetcasting",
})

local healDeadzone = Faceroll.deadzoneCreate("Holy Light", 1.5, 0.5)

spec.calcState = function(state)
    -- Resources --
    Faceroll.deadzoneUpdate(healDeadzone)
    local curHP = UnitHealth("player")
    local maxHP = UnitHealthMax("player")
    local norHP = curHP / maxHP
    if (norHP <= 0.5) and Faceroll.hasManaForSpell("Holy Light") and not Faceroll.deadzoneActive(healDeadzone) then
        state.selfheal = true
    end

    -- Buffs --

    if Faceroll.isBuffActive("Slice and Dice") then
        state.slice = true
    end
    if Faceroll.getBuffStacks("Sinister Finisher") >= 3 then
        state.sinisterfinisher = true
    end
    if Faceroll.isBuffActive("Stealth") then
        state.stealth = true
    end

    if Faceroll.getDotRemainingNorm("Rupture") > 0 then
        state.rupture = true
    end

    -- Spells --

    if Faceroll.getSpellCooldown("Kick") < 1 then -- if Faceroll.isSpellAvailable("Kick") then
        state.kick = true
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
    "kick",
    "rupture",
    "garrote",
}

spec.calcAction = function(mode, state)
    -- local st = (mode == Faceroll.MODE_ST)
    local aoe = (mode == Faceroll.MODE_AOE)

    -- if state.selfheal then
    --     return "heal"

    -- elseif not state.seal then
    --     return "seal"

    -- elseif not state.blessing then
    --     return "blessing"

    -- elseif state.targetingenemy then
    --     -- if state.combat then
    --         -- if not state.melee and state.charge then
    --         --     return "charge"

    --         if not state.autoattack then
    --             return "attack"

    --         elseif state.combat and state.judgement then
    --             return "judgement"

    --         elseif state.combat and state.crusaderstrike then
    --             return "crusaderstrike"
    --         end
    --     -- end
    -- end

    if not aoe and state.stealth then
        return "garrote"

    elseif not aoe and not state.rupture and state.combopoints >= 5 then
        return "rupture"

    elseif not aoe and state.rupture and not state.slice and state.combopoints >= 2 then
        return "slice"

    elseif not aoe and state.targetcasting and state.kick then
        return "kick"

    elseif (not aoe and state.combopoints >= 5) or (aoe and state.sinisterfinisher and state.combopoints >= 3) then
        return "eviscerate"

    else
        return "sinisterstrike"
    end

    return nil
end
