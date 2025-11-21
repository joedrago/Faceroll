-----------------------------------------------------------------------------------------
-- Ascension WoW Roulette Auto Shot

if Faceroll == nil then
    _, Faceroll = ...
end

local spec = Faceroll.createSpec("ROU", "aaffaa", "HERO-Deathbringer")

spec.options = {
    "duo",
}

-----------------------------------------------------------------------------------------
-- States

spec.overlay = Faceroll.createOverlay({
    "- Combat -",
    "autoshot",
    "duo",
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
        if not state.combat and not state.duo then
            return "sic"
        elseif not state.autoshot then
            return "attack"
        end
    end
    return nil
end
