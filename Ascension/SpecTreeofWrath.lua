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
    if mode == Faceroll.MODE_ST  then
        -- Single Target

        if state.targetingenemy then
            if state.lightningbolt then
                return "lightningbolt"
            end
        end

    elseif mode == Faceroll.MODE_AOE then

        if state.targetingenemy then
            if state.chainlightning then
                return "chainlightning"
            end
            if state.lightningbolt then
                return "lightningbolt"
            end
        end

    end

    return nil
end
