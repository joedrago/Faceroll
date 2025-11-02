-----------------------------------------------------------------------------------------
-- Ascension WoW Tree of Wrath

if Faceroll == nil then
    _, Faceroll = ...
end

local spec = Faceroll.createSpec("ATW", "aaffaa", "HERO-Tree of Wrath")

spec.options = {}

-----------------------------------------------------------------------------------------
-- States

spec.overlay = {
    "- Abilities -",
    "lightningbolt",
    "chainlightning",

    "- Combat -",
    "targetingenemy",
    "combat",
}

spec.calcState = function(state)
    if Faceroll.isSpellAvailable("Lightning Bolt") then
        state.lightningbolt = true
    end
    if Faceroll.isSpellAvailable("Chain Lightning") then
        state.chainlightning = true
    end

    -- Combat
    if Faceroll.targetingEnemy() then
        state.targetingenemy = true
    end
    if Faceroll.inCombat() then
        state.combat = true
    end
    return state
end

-----------------------------------------------------------------------------------------
-- Actions

spec.actions = {
    "lightningbolt",
    "chainlightning",
}

spec.calcAction = function(mode, state)
    local st = (mode == Faceroll.MODE_ST)
    local aoe = (mode == Faceroll.MODE_AOE)
    if state.targetingenemy then
        if aoe and state.chainlightning then
            return "chainlightning"
        end
        if state.lightningbolt then
            return "lightningbolt"
        end
    end
    return nil
end
