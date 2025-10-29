-----------------------------------------------------------------------------------------
-- Ascension WoW Corrupted Bear Form

if Faceroll == nil then
    _, Faceroll = ...
end

local spec = Faceroll.createSpec("CBF", "997799", "HERO-Corrupted Bear Form")

spec.options = {
    "solo",
}

-----------------------------------------------------------------------------------------
-- States

spec.overlay = {
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
}

spec.calcState = function(state)
    local rage = UnitPower("PLAYER", Enum.PowerType.Rage)
    local cp = GetComboPoints("PLAYER", "TARGET")

    if rage >= 20 then
        state.rage20 = true
    end
    if rage >= 40 then
        state.rage40 = true
    end

    for i = 1, GetNumShapeshiftForms() do
        local icon, name, active = GetShapeshiftFormInfo(i)
        if active and (name == "Bear Form" or name == "Dire Bear Form") then
            state.bear = true
        end
    end

    if IsCurrentSpell("Maul") then
        state.maulqueued = true
    end

    if Faceroll.isSpellAvailable("Charge") then
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
    if Faceroll.isBuffActive("Shadow Trance") then
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

    -- Combat
    if Faceroll.targetingEnemy() then
        state.targetingenemy = true
    end
    if Faceroll.inCombat() then
        state.combat = true
    end
    if IsCurrentSpell(6603) then -- Autoattack
        state.autoattack = true
    end
    if IsSpellInRange("Lacerate", "target") == 1 then
        state.melee = true
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
    if mode == Faceroll.MODE_ST or mode == Faceroll.MODE_AOE then
        -- Single Target

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

            elseif not state.taintedwound and state.taintedswipe then
                return "swipe"

            elseif mode == Faceroll.MODE_ST then
                if not state.laceratemax or state.lacerateending then
                    return "lacerate"
                elseif state.corruption then
                    return "swipe"
                else
                    return "maul"
                end
            else
                return "swipe"

            end
        end

    end

    return nil
end
