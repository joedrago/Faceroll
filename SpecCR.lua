-----------------------------------------------------------------------------------------
-- Classic Rogue

if Faceroll == nil then
    _, Faceroll = ...
end

local spec = Faceroll.createSpec("CR", "777799", "ROGUE-CLASSIC")

spec.buffs = {}

-----------------------------------------------------------------------------------------
-- States

spec.states = {
    "energy35",
    "energy45",
    "cp3",
    "cp5",
}

spec.calcState = function(state)
    local energy = UnitPower("PLAYER", Enum.PowerType.Energy)
    local cp = UnitPower("PLAYER", Enum.PowerType.ComboPoints)

    if energy >= 35 then
        state.energy35 = true
    end
    if energy >= 45 then
        state.energy45 = true
    end

    if cp >= 3 then
        state.cp3 = true
    end
    if cp >= 5 then
        state.cp5 = true
    end

    if Faceroll.debug ~= Faceroll.DEBUG_OFF then
        local o = ""
        o = o .. "Energy: " .. energy .. "\n"
        o = o .. "CP    : " .. cp .. "\n"
        o = o .. "\n"
        Faceroll.setDebugText(o)
    end

    return state
end

-----------------------------------------------------------------------------------------
-- Actions

spec.actions = {
    "sinisterstrike",
    "eviscerate",
}

spec.calcAction = function(mode, state)
    if mode == Faceroll.MODE_ST then
        -- Single Target

        -- if state.energy35 and state.cp3 then
        if state.cp3 then
            return "eviscerate"

        -- elseif state.energy45 then
        else
            return "sinisterstrike"

        end

    elseif mode == Faceroll.MODE_AOE then
        -- AOE

    end

    return nil
end
