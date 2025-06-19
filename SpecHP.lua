-----------------------------------------------------------------------------------------
-- Holy Paladin

if Faceroll == nil then
    _, Faceroll = ...
end

local spec = Faceroll.createSpec("HP", "999900", "PALADIN-1")

spec.buffs = {
    "Consecration",
}

spec.abilities = {
    "crusaderstrike",
    "judgment",
    "consecration",
    "hammerofwrath",
}

local bits = Faceroll.createBits({
    "holypower5",
    "crusaderstrike",
    "divinetoll",
    "judgment",
    "hammerofwrath",
    "consecration",
})

spec.calcBits = function()
    bits:reset()

    local holypower = UnitPower("player", Enum.PowerType.HolyPower)
    if holypower < 5 then
        bits:enable("holypower5")
    end

    if Faceroll.isSpellAvailable("Crusader Strike") then
        bits:enable("crusaderstrike")
    end
    if Faceroll.isSpellAvailable("Divine Toll") then
        bits:enable("divinetoll")
    end
    if Faceroll.isSpellAvailable("Judgment") then
        bits:enable("judgment")
    end
    if Faceroll.isSpellAvailable("Hammer of Wrath") then
        bits:enable("hammerofwrath")
    end
    if Faceroll.isSpellAvailable("Consecration") then
        bits:enable("consecration")
    end

    return bits.value
end

spec.nextAction = function(action, rawBits)
    local state = bits:parse(rawBits)

    if action == Faceroll.ACTION_ST then
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

    elseif action == Faceroll.ACTION_AOE then
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

Faceroll.registerSpec(spec)
