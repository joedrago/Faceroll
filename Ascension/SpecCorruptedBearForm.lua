-----------------------------------------------------------------------------------------
-- Ascension WoW Corrupted Bear Form

if Faceroll == nil then
    _, Faceroll = ...
end

local spec = Faceroll.createSpec("CBF", "997799", "HERO-Corrupted Bear Form")

spec.melee = "Lacerate"
spec.options = {
    "solo",
}

-----------------------------------------------------------------------------------------
-- States

spec.overlay = Faceroll.createOverlay({
    "- Resources -",
    "rage20",
    "rage40",

    "- State -",
    "bear",
    "maulqueued",
    "solo",

    "- Abilities -",
    "charge",
    "enrage",
    "regen",
    "taintedswipe",
    "shadowtrance",

    "- Debuffs -",
    "taintedwound",
    "lacerateending",
    "laceratemax",
    "corruption",

    "- Combat -",
    "targetingenemy",
    "combat",
    "autoattack",
    "melee",
})

spec.calcState = function(state)
    for i = 1, GetNumShapeshiftForms() do
        local icon, name, active = GetShapeshiftFormInfo(i)
        if active and (name == "Bear Form" or name == "Dire Bear Form") then
            state.bear = true
        end
    end

    if IsCurrentSpell("Maul") then
        state.maulqueued = true
    end

    if Faceroll.isSpellAvailable("Feral Charge - Bear") then
        state.charge = true
    end
    if Faceroll.isSpellAvailable("Enrage") then
        state.enrage = true
    end
    if Faceroll.isSpellAvailable("Frenzied Regeneration") then
        state.regen = true
    end
    if Faceroll.isBuffActive("Tainted Swipe") then
        state.taintedswipe = true
    end
    if Faceroll.isBuffActive("Shadow Trance") or Faceroll.isBuffActive("Backlash") then
        state.shadowtrance = true
    end

    if Faceroll.isDotActive("Tainted Wound") then
        state.taintedwound = true
    end
    if Faceroll.getDotRemainingNorm("Lacerate") < 0.2 then
        state.lacerateending = true
    end
    local maxLacerateStacks = 5
    if state.solo then
        maxLacerateStacks = 1
    end
    if Faceroll.getDotStacks("Lacerate") >= maxLacerateStacks then
        state.laceratemax = true
    end
    if Faceroll.isDotActive("Corruption") then
        state.corruption = true
    end
    return state
end

-----------------------------------------------------------------------------------------
-- Actions

spec.actions = {
    "bear",
    "attack",
    "swipe",
    "maul",
    "charge",
    "lacerate",
    "enrage",
    "regen",
    "shadowbolt",
}

spec.calcAction = function(mode, state)
    local st = (mode == Faceroll.MODE_ST)
    local aoe = (mode == Faceroll.MODE_AOE)

    if state.targetingenemy then

        if not state.bear then
            return "bear"

        elseif state.shadowtrance then
            return "shadowbolt"

        elseif not state.melee and state.charge then
            return "charge"

        elseif not state.autoattack and not state.maulqueued then
            return "attack"

        elseif state.regen then
            return "regen"

        elseif state.enrage then
            return "enrage"

        elseif not state.taintedwound and state.taintedswipe and state.melee then
            return "swipe"

        elseif mode == Faceroll.MODE_ST then
            if not state.laceratemax or state.lacerateending then
                return "lacerate"
            elseif state.corruption and state.melee then
                return "swipe"
            else
                return "maul"
            end
        elseif state.melee then
            return "swipe"

        end
    end

    return nil
end
