-----------------------------------------------------------------------------------------
-- Ascension WoW Blood and Guts

if Faceroll == nil then
    _, Faceroll = ...
end

local spec = Faceroll.createSpec("BAG", "ff6666", "HERO-Blood and Guts")

spec.options = {}

-----------------------------------------------------------------------------------------
-- States

spec.overlay = {
    "- Resources -",
    "rage",
    "energy",
    "combopoints",

    "- Buffs -",
    "sliceanddice",

    "- Abilities -",
    "charge",
    "execute",

    "- Combat -",
    "targetingenemy",
    "combat",
    "autoattack",
    "melee",
}

spec.calcState = function(state)
    state.rage = UnitPower("PLAYER", 1)
    state.energy = UnitPower("PLAYER", 3)
    state.combopoints = GetComboPoints("PLAYER", "TARGET")

    -- Buffs
    if Faceroll.getBuffRemaining("Slice and Dice") > 2 then
        state.sliceanddice = true
    end

    -- Abilities
    if Faceroll.isSpellAvailable("Charge") then
        state.charge = true
    end
    if Faceroll.isSpellAvailable("Execute") and state.rage >= 13 then
        state.execute = true
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
    if IsSpellInRange("Backstab", "target") == 1 then
        state.melee = true
    end

    return state
end

-----------------------------------------------------------------------------------------
-- Actions

spec.actions = {
    "charge",
    "attack",
    "mutilate",
    "disembowel",
    "sliceanddice",
    "execute",
}

spec.calcAction = function(mode, state)
    local st = (mode == Faceroll.MODE_ST)
    local aoe = (mode == Faceroll.MODE_AOE)

    if state.targetingenemy then
        if not state.melee and state.charge then
            return "charge"

        elseif not state.autoattack then
            return "attack"

        elseif state.execute then
            return "execute"

        elseif state.combopoints >= 5 and not state.sliceanddice then
            return "sliceanddice"

        elseif state.combopoints >= 5 then
            return "disembowel"

        else
            return "mutilate"

        end
    end

    return nil
end
