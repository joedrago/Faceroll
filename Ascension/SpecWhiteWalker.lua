-----------------------------------------------------------------------------------------
-- Ascension WoW White Walker

if Faceroll == nil then
    _, Faceroll = ...
end

local spec = Faceroll.createSpec("WW", "aaaaff", "HERO-White Walker")

spec.melee = "Sinister Strike"
spec.options = {}

-----------------------------------------------------------------------------------------
-- States

spec.overlay = Faceroll.createOverlay({
    "- Buffs -",
    "sliceanddice",

    "- Abilities -",
    "charge",
})

spec.calcState = function(state)
    -- Buffs
    if Faceroll.getBuffRemaining("Slice and Dice") > 2 then
        state.sliceanddice = true
    end

    -- Abilities
    if Faceroll.isSpellAvailable("Charge") then
        state.charge = true
    end
    return state
end

-----------------------------------------------------------------------------------------
-- Actions

spec.actions = {
    "charge",
    "attack",
    "sinisterstrike",
}

spec.calcAction = function(mode, state)
    local st = (mode == Faceroll.MODE_ST)
    local aoe = (mode == Faceroll.MODE_AOE)
    if state.targetingenemy then
        if not state.melee and state.charge then
            return "charge"

        elseif not state.autoattack then
            return "attack"

        else
            return "sinisterstrike"

        end
    end
    return nil
end
