-----------------------------------------------------------------------------------------
-- Ascension WoW Bronzebeard Druid

if Faceroll == nil then
    _, Faceroll = ...
end

local spec = Faceroll.createSpec("CAT", "006600", "DRUID-Fury Unleashed")

Faceroll.enemyGridTrack(spec, "Rake", "RAKE", "621518")
Faceroll.enemyGridTrack(spec, "Rip", "RIP", "626218")

-----------------------------------------------------------------------------------------
-- States

spec.overlay = Faceroll.createOverlay({
    "catform",
    "group",

    "- Combat -",
    "nobleed",

    "- Resources -",
    "hpL80",
    "manaL70",

    "- Buffs -",
    "rejuvenation",
    "tigersfury",

    "- Debuffs -",
    "rake",
    "fff",
    "fffready",
})

spec.options = {
    "nobleed",
}

spec.calcState = function(state)
    -- Stances --

    if Faceroll.inShapeshiftForm("Cat Form") then
        state.catform = true
    end
    if IsInGroup() then
        state.group = true
    end

    -- Resources --

    local curHP = UnitHealth("player")
    local maxHP = UnitHealthMax("player")
    local norHP = curHP / maxHP
    if norHP < 0.8 then
        state.hpL80 = true
    end

    local curMana = UnitPower("player", 0)
    local maxMana = UnitPowerMax("player", 0)
    local norMana = curMana / maxMana
    if norMana < 0.7 then
        state.manaL70 = true
    end

    -- Buffs --

    if Faceroll.isBuffActive("Rejuvenation") then
        state.rejuvenation = true
    end

    if Faceroll.isSpellAvailable("Tiger's Fury") then
        state.tigersfury = true
    end

    -- Debuffs --

    if Faceroll.getDotRemainingNorm("Rake") > 0.1 then
        state.rake = true
    end

    if Faceroll.getDotRemainingNorm("Faerie Fire (Feral)") > 0.1 then
        state.fff = true
    end

    -- Spells --

    if Faceroll.isSpellAvailable("Faerie Fire (Feral)") then
        state.fffready = true
    end

    return state
end

-----------------------------------------------------------------------------------------
-- Actions

spec.actions = {
    "cat",
    "rejuvenation",
    "attack",
    "fff",
    "claw",
    "shred",
    "rake",
    "rip",
    "bite",
    "tigersfury",
    "swipe",
}

spec.calcAction = function(mode, state)
    local st = (mode == Faceroll.MODE_ST)
    local aoe = (mode == Faceroll.MODE_AOE)

    if not state.targetingenemy and state.hpL80 and not state.manaL70 and not state.combat and not state.rejuvenation then
        return "rejuvenation"

    elseif not state.catform then
        return "cat"

    elseif state.targetingenemy then

        -- state.nobleed means "I am fighting bleed immune targets"

        if not state.group and not state.fff and state.fffready then
            return "fff"

        elseif state.tigersfury and state.melee and state.energy < 55 then
            return "tigersfury"

        elseif (state.nobleed or state.rip) and not aoe and state.combopoints >= 5 then
            return "bite"

        elseif aoe then
            if state.melee then
                return "swipe"
            else
                -- get in range
                return nil
            end

        elseif not state.nobleed and not state.rake then
            return "rake"

        elseif not state.nobleed and not state.rip and state.combopoints >= 5 then
            return "rip"

        elseif state.group then
            return "shred"

        else
            return "claw"
        end
    end
end
