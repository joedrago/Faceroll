-----------------------------------------------------------------------------------------
-- Classic Rogue

if Faceroll == nil then
    _, Faceroll = ...
end

local spec = Faceroll.createSpec("CR", "777799", "ROGUE-CLASSIC")

spec.buffs = {}

-----------------------------------------------------------------------------------------
-- States

spec.overlay = {
    "- Resources -",
    "energy35",
    "energy45",
    "cp3",
    "cp5",

    "- Combat -",
    "targetingenemy",
    "combat",
    "autoattack",
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
    "sinisterstrike",
    "eviscerate",
    "attack",
}

spec.calcAction = function(mode, state)
    if mode == Faceroll.MODE_ST then
        -- Single Target

        if state.targetingenemy then

            if state.combat and not state.autoattack then
                return "attack"

            elseif state.cp3 then -- if state.energy35 and state.cp3 then
                return "eviscerate"

            else --if state.energy45 then
                return "sinisterstrike"

            end
        end

    elseif mode == Faceroll.MODE_AOE then
        -- AOE

    end

    return nil
end
