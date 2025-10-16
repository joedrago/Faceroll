-----------------------------------------------------------------------------------------
-- Ascension WoW Lava Sweep

if Faceroll == nil then
    _, Faceroll = ...
end

local spec = Faceroll.createSpec("ALS", "993333", "HERO-Lava Sweep")

spec.buffs = {}

-----------------------------------------------------------------------------------------
-- States

spec.states = {
    "- Abilities -",
    "lavasweep",

    "- Combat -",
    "targetingenemy",
    "combat",
    "autoattack",
}

spec.calcState = function(state)

    if Faceroll.isSpellAvailable("Lava Sweep") then
        state.lavasweep = true
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
    "attack",
    "lavasweep",
}

spec.calcAction = function(mode, state)
    if mode == Faceroll.MODE_ST then
        -- Single Target

        if state.targetingenemy then

            if not state.autoattack then
                return "attack"

            elseif state.lavasweep then
                return "lavasweep"

            end
        end

    elseif mode == Faceroll.MODE_AOE then
        -- AOE

    end

    return nil
end
