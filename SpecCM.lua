-----------------------------------------------------------------------------------------
-- Classic Mage

if Faceroll == nil then
    _, Faceroll = ...
end

local spec = Faceroll.createSpec("CM", "00c7ee", "MAGE-CLASSIC")

spec.buffs = {
    "Frost Armor",
    "Arcane Intellect",
    "Drink",
}

local CONJURED_FOOD_NAME  = "Conjured Bread"
local CONJURED_WATER_NAME = "Conjured Fresh Water"

-----------------------------------------------------------------------------------------
-- States

spec.states = {
    "- Combat -",
    "targetingenemy",
    "combat",
    "combatrecent",
    "melee",
    "moving",
    "hold",
    -- "shoot",

    "- Resources -",
    "hpL50",
    "manaL19",
    "manaL50",
    "manaL80",
    "manafull",

    "- Consume -",
    "drink",
    "drinkending",

    "- Conjure -",
    "waterL1",
    "waterL100",
    "foodL1",
    "foodL100",

    "- Buffs -",
    "frostarmor",
    "arcaneintellect",

    "- Spells -",
    "fireblast",
}

spec.calcState = function(state)
    -- Combat --

    if Faceroll.targetingEnemy() then
        state.targetingenemy = true
    end

    if UnitAffectingCombat("player") then
        state.combat = true
    end

    local timeSinceCombat = GetTime() - Faceroll.leftCombat
    if timeSinceCombat <= 1 then
        state.combatrecent = true
    end

    if CheckInteractDistance("target", 3) then
        state.melee = true
    end

    -- local movingStoppedSince = GetTime() - Faceroll.movingStopped
    if Faceroll.moving then --or (movingStoppedSince < 0.5) then
        state.moving = true
    end

    if Faceroll.hold then
        state.hold = true
    end

    -- local shootButton = nil
    -- local shootButtons = C_ActionBar.FindSpellActionButtons(5019)
    -- if shootButtons then
    --     shootButton = shootButtons[1]
    -- end
    -- if shootButton and IsCurrentAction(shootButton) then
    --     state.shoot = true
    -- end

    -- Resources --

    local curHP = UnitHealth("player")
    local maxHP = UnitHealthMax("player")
    local norHP = curHP / maxHP
    if norHP < 0.5 then
        state.hpL50 = true
    end

    local curMana = UnitPower("player", 0)
    local maxMana = UnitPowerMax("player", 0)
    local norMana = curMana / maxMana
    if norMana < 0.19 then
        state.manaL19 = true
    end
    if norMana < 0.5 then
        state.manaL50 = true
    end
    if norMana < 0.8 then
        state.manaL80 = true
    end
    if norMana > 0.95 then
        state.manafull = true
    end

    local waterCount = GetItemCount(CONJURED_WATER_NAME)
    local foodCount  = GetItemCount(CONJURED_FOOD_NAME)

    if waterCount < 1 then
        state.waterL1 = true
    end
    if waterCount < 100 then
        state.waterL100 = true
    end
    if foodCount < 1 then
        state.foodL1 = true
    end
    if foodCount < 100 then
        state.foodL100 = true
    end

    if state.hold and state.waterL100 and state.foodL100 then
        -- Make food if we have less than water
        if foodCount < waterCount then
            state.waterL100 = false -- lies!
        end
    end

    -- Buffs --

    if Faceroll.isBuffActive("Frost Armor") then
        state.frostarmor = true
    end

    if Faceroll.isBuffActive("Arcane Intellect") then
        state.arcaneintellect = true
    end
    if Faceroll.isBuffActive("Drink") then
        state.drink = true
    end
    if Faceroll.getBuffRemaining("Drink") < 4 then
        state.drinkending = true
    end

    -- Spells --

    if Faceroll.isSpellAvailable("Fire Blast") then
        state.fireblast = true
    end

    -- Extra debug info

    if Faceroll.debug then
        local o = ""
        o = o .. "waterCount: " .. waterCount .. "\n"
        o = o .. "foodCount : " .. foodCount .. "\n"
        o = o .. "\n"
        Faceroll.setDebugText(o)
    end

    return state
end

-----------------------------------------------------------------------------------------
-- Actions

spec.actions = {
    "frostarmor",
    "arcaneintellect",
    "frostbolt",
    "fireblast",
    "shoot",
    "consume",
    "makefood",
    "makewater",
}

spec.calcAction = function(mode, state)
    if mode == Faceroll.MODE_ST or mode == Faceroll.MODE_AOE then
        if not state.combat and state.drink and not state.manafull then
            -- wait for full mana
            return nil

        elseif not state.combat
           and (((state.hold and state.manaL19) or (not state.hold and state.manaL50)) or (state.hpL50))
           and not state.waterL1
           and not state.drink
        --    and not state.combatrecent
           and not state.moving
           then
            -- low on mana or hp, and we've given a second or two to loot
            return "consume"

        elseif not state.combat and state.drink and state.drinkending and state.manaL80 then
            -- we're going to need to drink more to finish drinking
            return "consume"

        elseif not state.combat and state.waterL1 or (state.hold and state.waterL100) then
            -- we're either making one batch because we ran out, or we're doing
            -- a big prep because "hold" == "big prep"
            return "makewater"

        elseif not state.combat and state.foodL1 or (state.hold and state.foodL100) then
            -- we're either making one batch because we ran out, or we're doing
            -- a big prep because "hold" == "big prep"
            return "makefood"

        elseif not state.combat and not state.frostarmor then
            return "frostarmor"

        elseif not state.combat and not state.arcaneintellect then
            return "arcaneintellect"

        elseif not state.combat and state.hold and not state.waterL100 and not state.manafull then
            -- we just finished preparing a big pile of water and buffs, top off
            return "consume"

        elseif state.targetingenemy and not state.hold then
            -- combat

            if mode == Faceroll.MODE_ST then
                -- Single Target

                if state.fireblast and state.melee and not state.manaL19 and state.hpL50 then
                    -- hpL50 here is to take a hit or two while wanding for FSR
                    return "fireblast"

                elseif state.melee or state.manaL19 then
                    return "shoot"

                else
                    return "frostbolt"
                end

            elseif mode == Faceroll.MODE_AOE then
                -- AOE
            end
        end
    end
    return nil
end
