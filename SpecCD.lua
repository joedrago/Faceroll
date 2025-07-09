-----------------------------------------------------------------------------------------
-- Classic Druid

if Faceroll == nil then
    _, Faceroll = ...
end

local spec = Faceroll.createSpec("CD", "006600", "DRUID-CLASSIC")

spec.buffs = {
    "Mark of the Wild",
    "Thorns",
}

-----------------------------------------------------------------------------------------
-- States

spec.states = {
    "bear",
    "targetingenemy",
    "combat",
    "roar",
    "moonfire",
    "thorns",
}

spec.calcState = function(state)
    if GetShapeshiftForm() == 1 then
        state.bear = true
    end

    if Faceroll.targetingEnemy() then
        state.targetingenemy = true
    end

    if UnitAffectingCombat("player") then
        state.combat = true
    end

    if Faceroll.isDotActive("Demoralizing Roar") > 0.1 then
        state.roar = true
    end

    if Faceroll.isDotActive("Moonfire") > 0.1 then
        state.moonfire = true
    end

    if Faceroll.isBuffActive("Thorns") then
        state.thorns = true
    end

    return state
end

-----------------------------------------------------------------------------------------
-- Actions

spec.actions = {
    "bear",
    "thorns",
    "roar",
    "maul",
    "moonfire",
}

spec.calcAction = function(mode, state)
    if mode == Faceroll.MODE_ST or mode == Faceroll.MODE_AOE then

        if state.targetingenemy then
            if not state.combat and not state.thorns then
                return "thorns"

            elseif not state.combat and not state.bear and not state.moonfire then
                return "moonfire"

            elseif not state.bear then
                return "bear"

            elseif not state.roar then
                return "roar"

            else
                return "maul"
            end
        end

    end

    return nil
end
