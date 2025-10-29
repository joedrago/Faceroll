-----------------------------------------------------------------------------------------
-- Holy Paladin

if Faceroll == nil then
    _, Faceroll = ...
end

local spec = Faceroll.createSpec("HP", "999900", "PALADIN-1")

spec.buffs = {
    "Consecration",
}

-----------------------------------------------------------------------------------------
-- States

spec.overlay = {
    "holypower5",
    "crusaderstrike",
    "divinetoll",
    "judgment",
    "hammerofwrath",
    "consecration",
}

spec.calcState = function(state)
    local holypower = UnitPower("player", Enum.PowerType.HolyPower)
    if holypower < 5 then
        state.holypower5 = true
    end

    if Faceroll.isSpellAvailable("Crusader Strike") then
        state.crusaderstrike = true
    end
    if Faceroll.isSpellAvailable("Divine Toll") then
        state.divinetoll = true
    end
    if Faceroll.isSpellAvailable("Judgment") then
        state.judgment = true
    end
    if Faceroll.isSpellAvailable("Hammer of Wrath") then
        state.hammerofwrath = true
    end
    if Faceroll.isSpellAvailable("Consecration") then
        state.consecration = true
    end

    return state
end

-----------------------------------------------------------------------------------------
-- Actions

spec.actions = {
    "crusaderstrike",
    "judgment",
    "consecration",
    "hammerofwrath",
}

spec.calcAction = function(mode, state)
    if mode == Faceroll.MODE_ST then
        -- Single Target

        if state.hammerofwrath then
            return "hammerofwrath"

        elseif state.judgment then
            return "judgment"

        elseif state.crusaderstrike then
            return "crusaderstrike"

        elseif state.consecration then
            return "consecration"

        end

    elseif mode == Faceroll.MODE_AOE then
        -- AOE

        if state.hammerofwrath then
            return "hammerofwrath"

        elseif state.judgment then
            return "judgment"

        elseif state.crusaderstrike then
            return "crusaderstrike"

        elseif state.consecration then
            return "consecration"

        end

    end

    return nil
end
