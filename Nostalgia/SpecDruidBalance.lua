-----------------------------------------------------------------------------------------
-- Classic Balance Druid

if Faceroll == nil then
    _, Faceroll = ...
end

local spec = Faceroll.createSpec("BAL", "aa6600", "DRUID-1")
Faceroll.aliasSpec(spec, "DRUID-CLASSIC") -- pre-talent points

-----------------------------------------------------------------------------------------
-- States

spec.overlay = Faceroll.createOverlay({
    "- Stances -",
    { "f_moonkin", 5 },

    "- Combat -",
    { "b_drink", "Drink" },

    "- Debuffs -",
    { "d_moonfire", "Moonfire" },

    "- Buffs -",
    { "b_lunar", "Eclipse (Lunar)" },
})

spec.calcState = function(state)
    return state
end

-----------------------------------------------------------------------------------------
-- Actions

spec.actions = {
    "moonkin",
    "moonfire",
    "wrath",
    "starfire",
    "hurricane",
    "drink",
    "starfire",
}

spec.calcAction = function(mode, state)
    local aoe = (mode == Faceroll.MODE_AOE)

    if state.level < 20 then
        if state.level >= 4 and not state.d_moonfire and state.combat then
            return "moonfire"
        else
            return "wrath"
        end
    end

    if not state.f_moonkin then
        return "moonkin"

    elseif state.targetingenemy then
        if aoe then
            return "hurricane"

        elseif not state.d_moonfire then
            return "moonfire"
        elseif state.b_lunar then
            return "starfire"
        else
            return "wrath"
        end

    elseif state.mana < 0.9 and not state.combat and not state.b_drink then
        return "drink"
    end
end
