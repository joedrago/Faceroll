-----------------------------------------------------------------------------------------
-- Classic Druid

if Faceroll == nil then
    _, Faceroll = ...
end

local spec = Faceroll.createSpec("CD", "006600", "DRUID-CLASSIC")

spec.buffs = {
    "Mark of the Wild",
}

spec.actions = {
    "moonfire",
    "wrath",
}

spec.states = {
    "targetingenemy",
    "combat",
    "moonfire",
    "motw",
}

spec.calcState = function(state)
    if Faceroll.targetingEnemy() then
        state.targetingenemy = true
    end

    if UnitAffectingCombat("player") then
        state.combat = true
    end

    if Faceroll.isDotActive("Moonfire") > 0.1 then
        state.moonfire = true
    end

    if Faceroll.isBuffActive("Mark of the Wild") then
        state.motw = true
    end
    return state
end

spec.calcAction = function(mode, state)
    if mode == Faceroll.MODE_ST then
        -- Single Target

        if not state.moonfire and state.combat then
            return "moonfire"

        else
            return "wrath"
        end

    elseif mode == Faceroll.MODE_AOE then
        -- AOE

        if not state.moonfire and state.combat then
            return "moonfire"

        else
            return "wrath"
        end

    end

    return nil
end
