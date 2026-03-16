-----------------------------------------------------------------------------------------
-- Classic Shaman

if Faceroll == nil then
    _, Faceroll = ...
end

local spec = Faceroll.createSpec("SHAM", "333399", "SHAMAN-CLASSIC")

-----------------------------------------------------------------------------------------
-- States

spec.overlay = Faceroll.createOverlay({
})

spec.calcState = function(state)
    -- if Faceroll.getDotRemainingNorm("Curse of Agony") > 0.1 then
    --     state.curseofagony = true
    -- end
    -- if Faceroll.getDotRemainingNorm("Corruption") > 0.1 then
    --     state.corruption = true
    -- end

    -- if Faceroll.targetingEnemy() then
    --     state.targetingenemy = true

    --     local targethp = UnitHealth("target")
    --     local targethpmax = UnitHealthMax("target")
    --     local targethpnorm = targethp / targethpmax
    --     if targethpnorm <= 0.20 then
    --         state.drainsoul = true
    --     end
    -- end

    return state
end

-----------------------------------------------------------------------------------------
-- Actions

spec.actions = {
    "lightningbolt",
}

spec.calcAction = function(mode, state)
    return "lightningbolt"
end
