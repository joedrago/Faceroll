-----------------------------------------------------------------------------------------
-- Classic Balance Druid

if Faceroll == nil then
    _, Faceroll = ...
end

local spec = Faceroll.createSpec("BAL", "aa6600", "DRUID-1")

-----------------------------------------------------------------------------------------
-- States

spec.overlay = Faceroll.createOverlay({
    "- Stances -",
    "moonkin",

    "- Combat -",
    "group",

    "- Debuffs -",
    "moonfire",
})

spec.calcState = function(state)
    -- Stances --

    if GetShapeshiftForm() == 5 then
        state.moonkin = true
    end

    -- Combat --

    if IsInGroup() then
        state.group = true
    end

    -- Debuffs --

    if Faceroll.getDotRemainingNorm("Moonfire") > 0.1 then
        state.moonfire = true
    end

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
}

spec.calcAction = function(mode, state)
    local aoe = (mode == Faceroll.MODE_AOE)

    if not state.moonkin then
        return "moonkin"

    elseif state.targetingenemy then
        if aoe then
            return "hurricane"

        elseif not state.moonfire then
            return "moonfire"
        else
            return "wrath"
        end
    end
end
