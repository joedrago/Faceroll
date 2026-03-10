-----------------------------------------------------------------------------------------
-- Classic Feral Druid

if Faceroll == nil then
    _, Faceroll = ...
end

local spec = Faceroll.createSpec("FERAL", "00aa00", "DRUID-2")

-----------------------------------------------------------------------------------------
-- States

spec.overlay = Faceroll.createOverlay({
    "- Stances -",
    "cat",

    "- Combat -",
    "group",
    "aoe",
    "nobleed",
    "stealth",

    "- Resources -",
    "hpL80",
    "hpL90",
    "manaL70",
    "manaL80",

    "- Buffs -",
    "thorns",
    "rejuvenation",
    "tigersfury",
    "berserk",

    "- Debuffs -",
    "rake",
    "rip",
    "fff",

    "- Spells -",
    "enrage",
    "mangle",
    "fffready",
    "charge",
})

spec.options = {
    "nobleed",
}

spec.calcState = function(state)
    -- Stances --

    if GetShapeshiftForm() == 1 then
        state.bear = true
    end
    if GetShapeshiftForm() == 3 then
        state.cat = true
    end

    -- Combat --

    if IsInGroup() then
        state.group = true
    end

    local mobCount = 0
    for i = 0, 5, 1 do
        if _G["NamePlate"..i] ~= nil and _G["NamePlate"..i]:IsVisible() then
            mobCount = mobCount + 1
        end
    end
    if mobCount > 1 then
        state.aoe = true
    end

    -- Resources --

    local curHP = UnitHealth("player")
    local maxHP = UnitHealthMax("player")
    local norHP = curHP / maxHP
    if norHP < 0.8 then
        state.hpL80 = true
    end
    if norHP < 0.9 then
        state.hpL90 = true
    end

    -- Buffs --

    if Faceroll.isBuffActive("Thorns") then
        state.thorns = true
    end

    if Faceroll.isBuffActive("Rejuvenation") then
        state.rejuvenation = true
    end

    if Faceroll.isBuffActive("Tiger's Fury") then
        state.tigersfury = true
    end
    if Faceroll.isBuffActive("Prowl") then
        state.stealth = true
    end
    if Faceroll.isBuffActive("Berserk") then
        state.berserk = true
    end

    -- Debuffs --

    if Faceroll.getDotRemainingNorm("Rake") > 0.1 then
        state.rake = true
    end
    if Faceroll.getDotRemainingNorm("Rip") > 0.1 then
        state.rip = true
    end

    if Faceroll.getDotRemainingNorm("Faerie Fire (Feral)") > 0.1 then
        state.fff = true
    end

    -- Spells --

    if Faceroll.isSpellAvailable("Faerie Fire (Feral)") then
        state.fffready = true
    end
    if Faceroll.isSpellAvailable("Feral Charge - Cat") then
        state.charge = true
    end

    return state
end

-----------------------------------------------------------------------------------------
-- Actions

spec.actions = {
    "cat",
    "thorns",
    "rejuvenation",
    "fff",
    "mangle",
    "swipe",
    "rip",
    "bite",
    "rake",
    "tigersfury",
    "charge",
    "ravage",
}

spec.calcAction = function(mode, state)
    local st = (mode == Faceroll.MODE_ST)
    local aoe = (mode == Faceroll.MODE_AOE)

    if not state.group and not state.targetingenemy and state.hpL90 and not state.combat and not state.rejuvenation then
        return "rejuvenation"

    elseif not state.cat then
        return "cat"

    elseif state.targetingenemy then

        -- state.nobleed means "I am fighting bleed immune targets"

        if state.charge and not state.melee then
            return "charge"

        elseif state.stealth and not state.combat then -- and not state.combat then
            return "ravage"

        -- if not state.fff and state.fffready then
        --     return "fff"

        elseif not state.berserk and not state.tigersfury and state.energy <= 30 then
            return "tigersfury"

        elseif aoe then
            return "swipe"

        elseif not state.nobleed and not state.rip and state.combopoints >= 5 then
            return "rip"

        elseif state.combopoints >= 5 then
            return "bite"

        elseif not state.nobleed and not state.rake then
            return "rake"

        else
            return "mangle"
        end
    end

    -- return nil
end
