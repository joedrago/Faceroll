-----------------------------------------------------------------------------------------
-- Ascension WoW Thermal Void

if Faceroll == nil then
    _, Faceroll = ...
end

local spec = Faceroll.createSpec("TV", "6666aa", "HERO-Thermal Void")

spec.buffs = {}

-----------------------------------------------------------------------------------------
-- States

spec.overlay = {
    "- Abilities -",
    "charge",
    "absolutezero",
    "judgement",
    "frostblast",
    "invocation",
    "coneofcold",
    "frozenorb",
    "barrier",

    "potion",

    "- Buffs -",
    "seal",

    "- Combat -",
    "targetingenemy",
    "combat",
    "melee",
}

spec.calcState = function(state)
    if Faceroll.isSpellAvailable("Charge") then
        state.charge = true
    end
    if Faceroll.isSpellAvailable("Absolute Zero") then
        state.absolutezero = true
    end
    if Faceroll.isSpellAvailable("Judgement of Wisdom") then
        state.judgement = true
    end
    if Faceroll.isSpellAvailable("Frost Blast") then
        state.frostblast = true
    end
    if Faceroll.isSpellAvailable("Invocation") then
        state.invocation = true
    end
    if Faceroll.isSpellAvailable("Cone of Cold") then
        state.coneofcold = true
    end
    if Faceroll.isSpellAvailable("Frozen Orb") then
        state.frozenorb = true
    end
    if Faceroll.isSpellAvailable("Ice Barrier") then
        state.barrier = true
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

    if Faceroll.isBuffActive("Seal of Wisdom") then
        state.seal = true
    end

    -- Combat
    if Faceroll.targetingEnemy() then
        state.targetingenemy = true
    end
    if Faceroll.inCombat() then
        state.combat = true
    end
    -- if IsCurrentSpell(6603) then -- Autoattack
    --     state.autoattack = true
    -- end
    if IsSpellInRange("Judgement of Wisdom", "target") == 1 then
        state.melee = true
    end

    return state
end

-----------------------------------------------------------------------------------------
-- Actions

spec.actions = {
    "frostbolt",
    "charge",
    "absolutezero",
    "seal",
    "judgement",
    "frostblast",
    "potion",
    "invocation",
    "coneofcold",
    "frozenorb",
    "blizzard",
    "barrier",
}

spec.calcAction = function(mode, state)
    local st = (mode == Faceroll.MODE_ST)
    local aoe = (mode == Faceroll.MODE_AOE)

    if state.targetingenemy then

        if not state.melee and state.charge then
            return "charge"

        elseif state.barrier then
            return "barrier"

        elseif state.potion then
            return "potion"

        elseif state.absolutezero then
            return "absolutezero"

        elseif state.frostblast then
            return "frostblast"

        elseif not state.seal then
            return "seal"

        elseif state.seal and state.judgement then
            return "judgement"

        elseif state.invocation then
            return "invocation"

        elseif state.coneofcold then
            return "coneofcold"

        elseif state.frozenorb then
            return "frozenorb"

        elseif aoe then
            return "blizzard"

        else
            return "frostbolt"

        end

    end

    return nil
end
