-----------------------------------------------------------------------------------------
-- Ascension WoW Evoker

if Faceroll == nil then
    _, Faceroll = ...
end

local spec = Faceroll.createSpec("EVO", "ffaaff", "HERO-Evoker")

spec.options = {
    -- "solo",
}

-----------------------------------------------------------------------------------------
-- States

spec.overlay = {
    "- Abilities -",
    "arcaneorb",
    "frozenorb",
    "meteor",

    "- Buffs -",
    "fireball",
    "barrage",

    "- Combat -",
    "targetingenemy",
    "combat",
}

spec.calcState = function(state)
    if Faceroll.isSpellAvailable("Arcane Orb") then
        state.arcaneorb = true
    end
    if Faceroll.isSpellAvailable("Frozen Orb") then
        state.frozenorb = true
    end
    if Faceroll.isSpellAvailable("Meteor") then
        state.meteor = true
    end

    if Faceroll.isBuffActive("Fireball!") then
        state.fireball = true
    end
    if Faceroll.isBuffActive("Missile Barrage") then
        state.barrage = true
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
    "frostbolt",
    "fireball",
    "missiles",
    "blizzard",
    "meteor",
    "arcaneorb",
    "frozenorb",
}

spec.calcAction = function(mode, state)
    if mode == Faceroll.MODE_ST then
        -- Single Target

        if state.fireball then
            return "fireball"
        elseif state.barrage then
            return "missiles"
        else
            return "frostbolt"
        end

    elseif mode == Faceroll.MODE_AOE then

        if state.meteor then
            return "meteor"
        elseif state.arcaneorb then
            return "arcaneorb"
        elseif state.frozenorb then
            return "frozenorb"
        else
            return "blizzard"
        end
    end

    return nil
end
