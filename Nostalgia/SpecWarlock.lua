-----------------------------------------------------------------------------------------
-- Classic Warlock

if Faceroll == nil then
    _, Faceroll = ...
end

local spec = Faceroll.createSpec("CW", "993399", "WARLOCK-CLASSIC")

spec.buffs = {}

-----------------------------------------------------------------------------------------
-- States

spec.overlay = Faceroll.createOverlay({
    { "d_curseofagony", "Curse of Agony" },
    { "d_corruption",   "Corruption" },
    "drainsoul",
})

spec.calcState = function(state)
    if Faceroll.targetingEnemy() then
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

        elseif not state.d_curseofagony then
            return "curseofagony"

        elseif not state.d_corruption then
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
