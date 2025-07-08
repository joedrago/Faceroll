-----------------------------------------------------------------------------------------
-- Classic Warlock

if Faceroll == nil then
    _, Faceroll = ...
end

local spec = Faceroll.createSpec("CW", "993399", "WARLOCK-CLASSIC")

spec.buffs = {}

-----------------------------------------------------------------------------------------
-- States

spec.states = {
    "curseofagony",
    "corruption",
}

spec.calcState = function(state)
    if Faceroll.isDotActive("Curse of Agony") > 0.1 then
        state.curseofagony = true
    end
    if Faceroll.isDotActive("Corruption") > 0.1 then
        state.corruption = true
    end

    return state
end

-----------------------------------------------------------------------------------------
-- Actions

spec.actions = {
    "curseofagony",
    "corruption",
    "shadowbolt",
    "hellfire",
}

spec.calcAction = function(mode, state)
    if mode == Faceroll.MODE_ST then
        -- Single Target

        if not state.curseofagony then
            return "curseofagony"

        elseif not state.corruption then
            return "corruption"

        else
            return "shadowbolt"

        end

    elseif mode == Faceroll.MODE_AOE then
        -- AOE

        return "hellfire"
    end

    return nil
end
