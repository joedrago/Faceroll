-----------------------------------------------------------------------------------------
-- Ascension WoW Bronzebeard Druid

if Faceroll == nil then
    _, Faceroll = ...
end

local spec = Faceroll.createSpec("BAR", "006600", "DRUID-Carnage Incarnate")

-- spec.melee = "Growl"

-----------------------------------------------------------------------------------------
-- States

spec.overlay = Faceroll.createOverlay({
    "- Stances -",
    "bearform",

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
    "thrash",
})

spec.options = {
    "hold",
}

spec.calcState = function(state)
    -- Stances --

    if Faceroll.inShapeshiftForm("Dire Bear Form") then
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

    if Faceroll.isSpellAvailable("Thrash") then
        state.thrash = true
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
    "fff",
    "thrash",
}

spec.calcAction = function(mode, state)
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
                if state.melee then
                    if state.thrash then
                        return "thrash"
                    else
                        return "swipe"
                    end
                end
            elseif not state.maulqueued then
                return "maul"
            end
        end

    end

    -- return nil
end
