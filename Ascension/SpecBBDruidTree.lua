-----------------------------------------------------------------------------------------
-- Ascension WoW Bronzebeard Druid

if Faceroll == nil then
    _, Faceroll = ...
end

local spec = Faceroll.createSpec("BBD", "006600", "DRUID-Tree")

-- spec.melee = "Growl"

-----------------------------------------------------------------------------------------
-- States

spec.overlay = Faceroll.createOverlay({
    "- Stances -",
    "bearform",
    "catform",

    "- Mode -",
    "cat",
    "bear",
    "boom",

    "- Combat -",
    "hold",

    "- Buffs -",
    "thorns",
    "rejuvenation",
    "tigersfury",

    "- Debuffs -",
    "moonfire",
    "roar",
    "rake",
    "fff",

    "- Spells -",
    "enrage",
    "fffready",
    "maulqueued",
})

spec.options = {
    "hold",
    "bear|mode",
    "cat|mode",
    "boom|mode",
}

spec.calcState = function(state)
    -- Stances --

    if Faceroll.inShapeshiftForm("Bear Form") then
        state.bearform = true
    end
    if Faceroll.inShapeshiftForm("Cat Form") then
        state.catform = true
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

    -- Debuffs --

    if Faceroll.getDotRemainingNorm("Moonfire") > 0.1 then
        state.moonfire = true
    end

    if Faceroll.getDotRemainingNorm("Demoralizing Roar") > 0.1 then
        state.roar = true
    end

    if Faceroll.getDotRemainingNorm("Rake") > 0.1 then
        state.rake = true
    end

    if Faceroll.getDotRemainingNorm("Faerie Fire (Feral)") > 0.1 then
        state.fff = true
    end

    -- Spells --

    if Faceroll.isSpellAvailable("Enrage") then
        state.enrage = true
    end

    if Faceroll.isSpellAvailable("Faerie Fire (Feral)") then
        state.fffready = true
    end

    if IsCurrentSpell("Maul") then
        state.maulqueued = true
    end

    return state
end

-----------------------------------------------------------------------------------------
-- Actions

spec.actions = {
    "bear",
    "moonfire",
    "rejuvenation",
    "roar",
    "swipe",
    "maul",
    "enrage",
    "attack",
    "wrath",
    "fff",
    "cat",
    "claw",
    "rip",
    -- "rake",
    -- "tigersfury",
}

spec.calcActionBoom = function(mode, state)
    -- local st = (mode == Faceroll.MODE_ST)
    -- local aoe = (mode == Faceroll.MODE_AOE)

    -- if state.combat and not state.moonfire then
    --     return "moonfire"
    -- else
        return "wrath"
    -- end
end

spec.calcActionCat = function(mode, state)
    local st = (mode == Faceroll.MODE_ST)
    local aoe = (mode == Faceroll.MODE_AOE)

    if not state.targetingenemy and state.hp < 0.8 and state.mana >= 0.7 and not state.combat and not state.rejuvenation then
        return "rejuvenation"

    elseif not state.catform then
        return "cat"

    elseif state.targetingenemy then

        -- state.hold means "I am fighting bleed immune targets"

        if not state.fff and state.fffready then
            return "fff"

        -- elseif not state.tigersfury and state.energy >= 30 then
        --     return "tigersfury"

        -- elseif not state.hold and state.combopoints >= 3 and state.energy >= 35 then
        --     return "bite"

        -- elseif not state.hold and not state.rake and state.energy >= 35 then
        --     return "rake"

        elseif not state.hold and not state.rip and state.combopoints > 3 then
            return "rip"

        else
            return "claw"
        end
    end
end

spec.calcActionBear = function(mode, state)
    local st = (mode == Faceroll.MODE_ST)
    local aoe = (mode == Faceroll.MODE_AOE)

    if st or aoe then
        -- Bear Form

        if not state.targetingenemy and state.hp < 0.9 and state.mana >= 0.8 and not state.combat and not state.rejuvenation then
            return "rejuvenation"

        elseif state.targetingenemy then
            if state.fffready then -- not state.fff and
                return "fff"

            elseif not state.bearform then
                return "bear"

            elseif not state.autoattack and not state.maulqueued then
                return "attack"

            elseif state.enrage then
                return "enrage"

            elseif not state.roar then
                if state.melee then
                    return "roar"
                end
                -- we want to wait if we can't roar

            elseif aoe then
                return "swipe"
            elseif not state.maulqueued then
                return "maul"
            end
        end

    end

    -- return nil
end

spec.calcAction = function(mode, state)
    if state.bear then
        return spec.calcActionBear(mode, state)
    elseif state.cat then
        return spec.calcActionCat(mode, state)
    elseif state.boom then
        return spec.calcActionBoom(mode, state)
    end
end
