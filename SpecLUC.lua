-----------------------------------------------------------------------------------------
-- Ascension WoW Lucifur

if Faceroll == nil then
    _, Faceroll = ...
end

local spec = Faceroll.createSpec("LUC", "997799", "HERO-Lucifur")

-----------------------------------------------------------------------------------------
-- States

spec.overlay = {
    -- "- Resources -",
    -- "rage20",
    -- "rage40",

    "- State -",
    "cat",

    "- Combat -",
    "targetingenemy",
    "combat",
    "autoattack",
}

spec.calcState = function(state)
    -- local cp = GetComboPoints("PLAYER", "TARGET")

    local s = nil
    for i = 1, GetNumShapeshiftForms() do
        if select(3, GetShapeshiftFormInfo(i)) then
            s = i
        end
    end
    if s ~= nil then
        state.cat = true
    end

    -- Combat
    if Faceroll.targetingEnemy() then
        state.targetingenemy = true

        -- local targethp = UnitHealth("target")
        -- local targethpmax = UnitHealthMax("target")
        -- local targethpnorm = targethp / targethpmax
        -- if targethpnorm <= 0.40 then
        --     state.target40 = true
        -- end
    end
    if UnitAffectingCombat("player") then
        state.combat = true
    end
    if IsCurrentSpell(6603) then -- Autoattack
        state.autoattack = true
    end

    return state
end

-----------------------------------------------------------------------------------------
-- Actions

spec.actions = {
    "cat",
    "attack",
    "claw",
}

spec.calcAction = function(mode, state)
    if mode == Faceroll.MODE_ST or mode == Faceroll.MODE_AOE then
        -- Single Target

        if state.targetingenemy then

            if not state.cat then
                return "cat"

            elseif not state.autoattack then
                return "attack"

            else
                return "claw"

            end
        end

    end

    return nil
end
