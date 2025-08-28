-----------------------------------------------------------------------------------------
-- Balance Druid (Owl)

if Faceroll == nil then
    _, Faceroll = ...
end

local spec = Faceroll.createSpec("OWL", "006600", "DRUID-1")

spec.buffs = {
    "Eclipse (Lunar)",
    "Dreamstate",
    "Warrior of Elune",
}

-----------------------------------------------------------------------------------------
-- States

spec.states = {
    "- Buffs -",
    "eclipse",
    "dreamstate",
    "woestacks",

    "- Dots -",
    "moonfire",
    "sunfire",

    "- Spells -",
    "incarnation",
    "woe",
    "foe",

    "- Resources -",
    "apG36",
    "apG45",
    "apG75",

    "- State -",
    "wrathdeadzone",
    "moving",
    "hold",
}

local wrathDeadzone = Faceroll.deadzoneCreate("Wrath", 0.3, 1)

spec.calcState = function(state)
    if Faceroll.getBuffRemaining("Eclipse (Lunar)") > 1.5 then
        state.eclipse = true
    end

    if Faceroll.getBuffRemaining("Dreamstate") > 1.5 then
        state.dreamstate = true
    end

    if Faceroll.getBuffStacks("Warrior of Elune") > 0 then
        state.woestacks = true
    end

    if Faceroll.isDotActive("Moonfire") > 0.3 then
        state.moonfire = true
    end

    if Faceroll.isDotActive("Sunfire") > 0.3 then
        state.sunfire = true
    end

    if Faceroll.isSpellAvailable("Incarnation: Chosen of Elune") then
        state.incarnation = true
    end

    if Faceroll.isSpellAvailable("Warrior of Elune") then
        state.woe = true
    end

    if Faceroll.isSpellAvailable("Fury of Elune") then
        state.foe = true
    end

    local ap = UnitPower("player", Enum.PowerType.LunarPower)
    if ap >= 36 then
        state.apG36 = true
    end
    if ap >= 45 then
        state.apG45 = true
    end
    if ap >= 75 then
        state.apG75 = true
    end

    local wrathCastCount = C_Spell.GetSpellCastCount("Wrath")
    if wrathCastCount == 1 then
        Faceroll.deadzoneUpdate(wrathDeadzone)
    end
    if Faceroll.deadzoneActive(wrathDeadzone) then
        state.wrathdeadzone = true
    end

    if Faceroll.moving then
        state.moving = true
    end

    if Faceroll.hold then
        state.hold = true
    end

    return state
end

-----------------------------------------------------------------------------------------
-- Actions

spec.actions = {
    "moonfire",
    "sunfire",
    "starfire",
    "wrath",
    "starfall",
    "starsurge",
    "incarnation",
    "woe",
    "foe",
}

spec.calcAction = function(mode, state)
    if mode == Faceroll.MODE_ST then
        -- Single Target

        if not state.sunfire then
            return "sunfire"

        elseif not state.moonfire then
            return "moonfire"

        elseif state.foe then
            return "foe"

        elseif state.incarnation and not state.eclipse and not state.hold then
            return "incarnation"

        elseif not state.eclipse and not state.wrathdeadzone and not state.moving then
            return "wrath"

        elseif state.apG75 or (state.apG36 and state.moving) then
            return "starsurge"

        elseif state.woe and not state.dreamstate then
            return "woe"

        else
            return "starfire"

        end

    elseif mode == Faceroll.MODE_AOE then
        -- AOE


        if not state.sunfire then
            return "sunfire"

        elseif not state.moonfire then
            return "moonfire"

        elseif state.foe and not state.hold then
            return "foe"

        elseif state.incarnation and not state.eclipse and not state.hold then
            return "incarnation"

        elseif not state.eclipse and not state.wrathdeadzone and not state.moving then
            return "wrath"

        elseif state.apG75 or (state.apG45 and state.moving) then
            return "starfall"

        elseif state.woe and not state.hold then
            return "woe"

        else
            return "starfire"

        end

    end

    return nil
end
