-----------------------------------------------------------------------------------------
-- Classic Warlock

if Faceroll == nil then
    _, Faceroll = ...
end

local spec = Faceroll.createSpec("CW", "993399", "WARLOCK-CLASSIC")

spec.buffs = {}

-----------------------------------------------------------------------------------------
-- States

spec.overlay = {
    "curseofagony",
    "corruption",
    "drainsoul",
}

spec.calcState = function(state)
    if Faceroll.isDotActive("Curse of Agony") > 0.1 then
        state.curseofagony = true
    end
    if Faceroll.isDotActive("Corruption") > 0.1 then
        state.corruption = true
    end

    if Faceroll.targetingEnemy() then
        state.targetingenemy = true

        local targethp = UnitHealth("target")
        local targethpmax = UnitHealthMax("target")
        local targethpnorm = targethp / targethpmax
        if targethpnorm <= 0.20 then
            state.drainsoul = true
        end
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
    "wand",
    "drainsoul",
}

spec.calcAction = function(mode, state)
    if mode == Faceroll.MODE_ST then
        -- Single Target

        if state.drainsoul then
            return "drainsoul"

        elseif not state.curseofagony then
            return "curseofagony"

        elseif not state.corruption then
            return "corruption"

        else
            return "wand"
        end
        -- -- else
        --     return "shadowbolt"

        -- end

    elseif mode == Faceroll.MODE_AOE then
        -- AOE

        return "hellfire"
    end

    return nil
end
