-----------------------------------------------------------------------------------------
-- Druid Bear

if Faceroll == nil then
    _, Faceroll = ...
end

local spec = Faceroll.createSpec("DB", "006600", "DRUID-3")

spec.buffs = {
    "Galactic Guardian",
    "Frenzied Regeneration",
    "Tooth and Claw",
    "Ironfur",
}

-----------------------------------------------------------------------------------------
-- States

spec.overlay = {
    "- Stances -",
    "bear",

    "- Resources -",
    "rageG40",

    "- Buffs -",
    "galacticguardian",
    "toothandclaw",
    "ironfur",

    "- Spells -",
    "frenziedregeneration",
    "thrash",
    "mangle",
    "lunarbeam",
}

spec.calcState = function(state)
    -- Stances --

    if GetShapeshiftForm() == 1 then
        state.bear = true
    end

    -- Resources --

    local rage = UnitPower("player", Enum.PowerType.Rage)
    if rage >= 40 then
        state.rageG40 = true
    end

    -- Buffs --

    local ggremaining = Faceroll.getBuffRemaining("Galactic Guardian")
    if ggremaining > 0 and ggremaining < 3 then
        state.galacticguardian = true
    end

    if Faceroll.getBuffStacks("Tooth and Claw") > 0 then
        state.toothandclaw = true
    end

    if Faceroll.getBuffStacks("Ironfur") < 2 then
        state.ironfur = true
    end

    -- Spells --

    local hp = UnitHealth("player")
    local hpmax = UnitHealthMax("player")
    local hpnorm = hp / hpmax
    if hpnorm < 0.6 and Faceroll.spellCharges("Frenzied Regeneration") > 0 and Faceroll.getBuffStacks("Frenzied Regeneration") < 2 then
        state.frenziedregeneration = true
    end

    if Faceroll.isSpellAvailable("Thrash") then
        state.thrash = true
    end

    if Faceroll.isSpellAvailable("Mangle") then
        state.mangle = true
    end

    if Faceroll.isSpellAvailable("Lunar Beam") then
        state.lunarbeam = true
    end

    return state
end

-----------------------------------------------------------------------------------------
-- Actions

spec.actions = {
    "thrash",
    "mangle",
    "lunarbeam",
    "moonfire",
    "swipe",
    "raze",
    "bear",
    "ironfur",
    "frenziedregeneration",
}

spec.calcAction = function(mode, state)
    if mode == Faceroll.MODE_ST or mode == Faceroll.MODE_AOE then
        if not state.bear then
            return "bear"

        elseif state.frenziedregeneration then
            return "frenziedregeneration"

        elseif state.ironfur and state.rageG40 then
            return "ironfur"

        elseif state.lunarbeam then
            return "lunarbeam"

        elseif state.thrash then
            return "thrash"

        elseif state.mangle then
            return "mangle"

        elseif state.rageG40 or state.toothandclaw then
            return "raze"

        elseif state.galacticguardian then
            return "moonfire"

        else
            return "swipe"
        end
    end

    return nil
end
