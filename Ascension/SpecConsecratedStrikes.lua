-----------------------------------------------------------------------------------------
-- Ascension WoW Consecrated Strikes

if Faceroll == nil then
    _, Faceroll = ...
end

local spec = Faceroll.createSpec("CS", "ff8833", "HERO-Consecrated Strikes")

spec.options = {
    "autopot",
}

-----------------------------------------------------------------------------------------
-- States

spec.overlay = {
    "- State -",
    "hsqueued",
    "autopot",

    "- Abilities -",
    "charge",
    "judgement",
    "divinestorm",
    "hammerofwrath",
    "executionsentence",
    "lightshammer",

    "potion",

    "- Procs -",
    "artofwar",

    "- Combat -",
    "targetingenemy",
    "combat",
    "autoattack",
    "melee",
}

spec.calcState = function(state)
    if Faceroll.isSpellAvailable("Charge") then
        state.charge = true
    end
    if Faceroll.isSpellAvailable("Judgement of Wisdom") then
        state.judgement = true
    end
    if Faceroll.isSpellAvailable("Divine Storm") then
        state.divinestorm = true
    end
    if Faceroll.isSpellAvailable("Hammer of Wrath") then
        state.hammerofwrath = true
    end
    if Faceroll.isSpellAvailable("Execution Sentence") then
        state.executionsentence = true
    end
    if Faceroll.isSpellAvailable("Light's Hammer") then
        state.lightshammer = true
    end
    if Faceroll.isBuffActive("The Art of War") then
        state.artofwar = true
    end

    local potionStart = GetActionCooldown(1)
    if potionStart > 0 then
        local potionRemaining = GetTime() - potionStart
        if potionRemaining < 1.6 then -- mana potion in slot 1
            state.potion = true
        end
    else
        state.potion = true
    end

    -- Combat
    if Faceroll.targetingEnemy() then
        state.targetingenemy = true
    end
    if UnitAffectingCombat("player") then
        state.combat = true
    end
    if IsCurrentSpell(6603) then -- Autoattack
        state.autoattack = true
    end
    if IsSpellInRange("Holy Strike", "target") == 1 then
        state.melee = true
    end

    return state
end

-----------------------------------------------------------------------------------------
-- Actions

spec.actions = {
    "charge",
    "attack",
    "judgement",
    "crusaderstrike",
    "divinestorm",
    "exorcistslash",
    "executionsentence",
    "lightshammer",
    "potion",
}

spec.calcAction = function(mode, state)
    if mode == Faceroll.MODE_ST or mode == Faceroll.MODE_AOE then
        -- Single Target

        if state.potion and state.autopot then
            return "potion"

        elseif state.targetingenemy then

            if not state.melee and state.charge then
                return "charge"

            elseif not state.autoattack and not state.hsqueued then
                return "attack"

            elseif state.executionsentence then
                return "executionsentence"

            elseif state.lightshammer then
                return "lightshammer"

            elseif state.artofwar then
                return "exorcistslash"

            elseif state.divinestorm then
                return "divinestorm"

            elseif state.judgement then
                return "judgement"

            else
                return "crusaderstrike"

            end

        end

    end

    return nil
end
