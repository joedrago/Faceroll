-----------------------------------------------------------------------------------------
-- Arcane Mage

if Faceroll == nil then
    _, Faceroll = ...
end

local spec = Faceroll.createSpec("AM", "995599", "MAGE-1")

spec.buffs = {
    "Clearcasting",
    "Nether Precision",
    "Intuition",
    "Arcane Harmony",
    "Arcane Surge",
}

-----------------------------------------------------------------------------------------
-- States

spec.overlay = {
    "- States -",
    "moving",
    "hold",

    "- Spells -",
    "evocation",
    "arcanesurgeready",
    "touchofthemagi",
    "arcaneorb",
    "shiftingpower",

    "- Buffs -",
    "clearcasting",
    "netherprecision",
    "intuition",
    "arcaneharmony12",
    "arcaneharmony18",
    "arcanesurge",

    "- Resources -",
    "lowmana",
    "arcanechargesG2",
    "arcanechargesG3",
    "arcanechargesG4",
}

spec.options = {
    "hold",
}

spec.calcState = function(state)
    if Faceroll.isBuffActive("Clearcasting") then
        state.clearcasting = true
    end
    if Faceroll.isBuffActive("Nether Precision") then
        state.netherprecision = true
    end
    if Faceroll.isBuffActive("Intuition") then
        state.intuition = true
    end
    if Faceroll.getBuffStacks("Arcane Harmony") >= 12 then
        state.arcaneharmony12 = true
    end
    if Faceroll.getBuffStacks("Arcane Harmony") >= 18 then
        state.arcaneharmony18 = true
    end

    if Faceroll.isSpellAvailable("Evocation") then
        state.evocation = true
    end
    if Faceroll.isSpellAvailable("Arcane Surge") then
        state.arcanesurgeready = true
    end
    if Faceroll.isSpellAvailable("Touch of the Magi") then
        state.touchofthemagi = true
    end
    if Faceroll.isSpellAvailable("Arcane Orb") then
        state.arcaneorb = true
    end
    if Faceroll.isSpellAvailable("Shifting Power") then
        state.shiftingpower = true
    end

    local curMana = UnitPower("player", Enum.PowerType.Mana)
    local maxMana = UnitPowerMax("player", Enum.PowerType.Mana)
    local norMana = curMana / maxMana
    if norMana < 0.1 then
        state.lowmana = true
    end

    local arcaneCharges = UnitPower("player", Enum.PowerType.ArcaneCharges)
    if arcaneCharges >= 2 then
        state.arcanechargesG2 = true
    end
    if arcaneCharges >= 3 then
        state.arcanechargesG3 = true
    end
    if arcaneCharges >= 4 then
        state.arcanechargesG4 = true
    end

    if Faceroll.isBuffActive("Arcane Surge") then
        state.arcanesurge = true
    end

    if Faceroll.moving then
        state.moving = true
    end

    return state
end

-----------------------------------------------------------------------------------------
-- Actions

spec.actions = {
    "arcaneblast",
    "arcaneexplosion",
    "arcanemissiles",
    "arcanebarrage",
    "evocation",
    "arcanesurge",
    "touchofthemagi",
    "arcaneorb",
    "shiftingpower",
}

spec.calcAction = function(mode, state)
    if action == ACTION_Q then
        -- Single Target

        if not state.hold and state.evocation then
            return "evocation"

        elseif not state.hold and state.arcanesurgeready then
            return "arcanesurge"

        elseif not state.hold and state.touchofthemagi then
            return "touchofthemagi"

        elseif not state.hold and not state.arcanesurge and state.shiftingpower and not state.evocation and not state.arcanesurge and not state.touchofthemagi then
            return "shiftingpower"

        elseif state.clearcasting then
            return "arcanemissiles"

        elseif state.arcaneorb and not state.arcanechargesG2 then
            return "arcaneorb"

        elseif state.intuition or state.arcaneharmony18 or state.arcaneorb or state.lowmana then
            return "arcanebarrage"

        else
            return "arcaneblast"

        end

    elseif action == ACTION_E then
        -- AOE

        if not state.hold and state.evocation then
            return "evocation"

        elseif not state.hold and state.arcanesurgeready then
            return "arcanesurge"

        elseif not state.hold and state.touchofthemagi then
            return "touchofthemagi"

        elseif not state.hold and not state.arcanesurge and state.shiftingpower and not state.evocation and not state.arcanesurge and not state.touchofthemagi then
            return "shiftingpower"

        elseif state.clearcasting then
            return "arcanemissiles"

        elseif state.arcaneorb and state.arcanechargesG3 then
            return "arcaneorb"

        elseif state.arcanechargesG4 or state.intuition or state.arcaneharmony12 or state.arcaneorb or state.lowmana then
            return "arcanebarrage"

        elseif state.arcanechargesG3 or (not state.arcanechargesG4 and state.moving) then
            return "arcaneexplosion"

        else
            return "arcaneblast"

        end

    end

    return nil
end
