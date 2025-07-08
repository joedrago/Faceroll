-----------------------------------------------------------------------------------------
-- Beast Mastery Hunter

if Faceroll == nil then
    _, Faceroll = ...
end

local spec = Faceroll.createSpec("BM", "448833", "HUNTER-1")

spec.buffs = {
    "Thrill of the Hunt",
    "Beast Cleave",
    "Hogstrider",
}

-----------------------------------------------------------------------------------------
-- States

spec.states = {
    "barbedshothighprio",
    "bestialwrath",
    "killcommand",
    "explosiveshot",
    "direbeast",
    "barbedshot",
    "barbedshottwochargessoon",
    "hogstrider",
    "beastcleave",
    "beastcleaveending",
    "energyG85",
    "shouldmendpet",
}

spec.calcState = function(state)
    local barbedShotCharges = Faceroll.spellCharges("Barbed Shot")
    local barbedShotTwoChargesSoon = Faceroll.spellChargesSoon("Barbed Shot", 2, 2.5)
    local killCommandCharges = Faceroll.spellCharges("Kill Command")
    if barbedShotCharges > 0 then
        if Faceroll.getBuffRemaining("Thrill of the Hunt") < 2
        or barbedShotTwoChargesSoon
        or barbedShotCharges > killCommandCharges
        or Faceroll.spellCooldown("Bestial Wrath") < 5
        then
            state.barbedshothighprio = true
        end
    end

    if Faceroll.isSpellAvailable("Bestial Wrath") then
        state.bestialwrath = true
    end
    if Faceroll.isSpellAvailable("Kill Command") then
        state.killcommand = true
    end
    if Faceroll.isSpellAvailable("Explosive Shot") then
        state.explosiveshot = true
    end
    if Faceroll.isSpellAvailable("Dire Beast") then
        state.direbeast = true
    end
    if Faceroll.isSpellAvailable("Barbed Shot") then
        state.barbedshot = true
    end
    if barbedShotTwoChargesSoon then
        state.barbedshottwochargessoon = true
    end

    if Faceroll.isBuffActive("Hogstrider") then
        state.hogstrider = true
    end
    if Faceroll.isBuffActive("Beast Cleave") then
        state.beastcleave = true
    end
    if Faceroll.getBuffRemaining("Beast Cleave") < 2.5 then
        state.beastcleaveending = true
    end

    local energy = UnitPower("player")
    if energy >= 85 then
        state.energyG85 = true
    end

    if UnitExists("pet") then
        local hasSpiritMend = false
        for i=1,10 do
            if GetPetActionInfo(i) == "Spirit Mend" then
                hasSpiritMend = true
                break
            end
        end
        if hasSpiritMend then
            local petHealth = UnitHealth("pet") / UnitHealthMax("pet")
            if petHealth < 0.90 and Faceroll.isSpellAvailable("Mend Pet") then
                state.shouldmendpet = true
            end
        end
    end

    return state
end

-----------------------------------------------------------------------------------------
-- Actions

spec.actions = {
    "explosiveshot",
    "cobrashot",
    "direbeast",
    "barbedshot",
    "killcommand",
    "multishot",
    "mendpet",
    "bestialwrath",
}

spec.calcAction = function(mode, state)
    if mode == Faceroll.MODE_ST then
        -- Single Target

        if state.shouldmendpet then
            return "mendpet"

        elseif state.bestialwrath then
            -- Use Bestial Wrath.
            return "bestialwrath"

        elseif state.barbedshothighprio then
            -- Use Barbed Shot if:
            -- * Frenzy has less than 1.5 seconds remaining.
            -- * You are about to reach two charges of Barbed Shot, or you have
            --   more charges of Barbed Shot than Kill Command.
            -- * Frenzy has fewer than 3 stacks and Call of the Wild or Bestial
            --   Wrath are coming off cooldown soon
            return "barbedshot"

        elseif state.direbeast then
            -- Dire Beast.
            return "direbeast"

        elseif state.killcommand then
            -- Use Kill Command.
            return "killcommand"

        elseif state.barbedshot then
            -- Use Barbed Shot.
            return "barbedshot"

        else
            -- Use Cobra Shot.
            return "cobrashot"
        end

    elseif mode == Faceroll.MODE_AOE then
        -- AOE

        if state.shouldmendpet then
            return "mendpet"

        elseif state.bestialwrath then
            -- Use Bestial Wrath. Prioritize targets without Barbed Shot.
            return "bestialwrath"

        elseif state.barbedshothighprio then
            -- Use Barbed Shot if:
            -- * Frenzy has less than 1.5 seconds remaining.
            -- * You are about to reach two charges of Barbed Shot, or you have
            --   more charges of Barbed Shot than Kill Command.
            -- * Frenzy has fewer than 3 stacks and Call of the Wild or Bestial
            --   Wrath are coming off cooldown soon
            return "barbedshot"

        elseif state.beastcleaveending then
            -- Use Multi-Shot if Beast Cleave has less than 2 seconds remaining.
            return "multishot"

        elseif state.direbeast and state.beastcleave then
            -- Use Dire Beast if Beast Cleave is up.
            return "direbeast"

        elseif state.barbedshottwochargessoon then
            -- Use Barbed Shot if you are about to reach 2 charges.
            return "barbedshot"

        elseif state.killcommand then
            -- Use Kill Command.
            return "killcommand"

        elseif state.barbedshot then
            -- Use Barbed Shot.
            return "barbedshot"

        elseif state.hogstrider then
            -- Use Cobra Shot if you have 4 stacks of Hogstrider.
            return "cobrashot"

        elseif state.direbeast then
            -- Dire Beast.
            return "direbeast"

        elseif state.energyG85 then
            -- Use Cobra Shot if you are about to cap on Focus.
            return "cobrashot"

        else
            -- Use Explosive Shot.
            return "explosiveshot"
        end
    end

    return nil
end
