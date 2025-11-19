-----------------------------------------------------------------------------------------
-- Ascension WoW Roulette Auto Shot

if Faceroll == nil then
    _, Faceroll = ...
end

local spec = Faceroll.createSpec("ROU", "aaffaa", "HERO-Harbinger of Flame")
Faceroll.aliasSpec(spec, "HERO-Deathbringer")

-----------------------------------------------------------------------------------------
-- States

spec.overlay = Faceroll.createOverlay({
    "- Combat -",
    "autoshot",
})

spec.calcState = function(state)
    if IsCurrentSpell(75) then -- autoshot
        state.autoshot = true
    end
    return state
end

-----------------------------------------------------------------------------------------
-- Actions

spec.actions = {
    "attack",
    "sic",
}

spec.calcAction = function(mode, state)
    if state.targetingenemy then
        if not state.combat then
            return "sic"
        elseif not state.autoshot then
            return "attack"
        end
    end
    return nil
end
