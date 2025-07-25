-----------------------------------------------------------------------------------------
-- Classic Mage

-- Faceroll.hold is special in this implementation: it provides a means to
-- create lots of conjured food and water. If you enable "hold" (/frhold), ST
-- will attempt to create 100 food and 100 water, then self-buff, drink to full,
-- and wait. If using AOE, it behaves the same, but will just make food and
-- water forever (instead of stopping at 100 each).

-- For combat, everything is decided based on:
-- * am I already in combat
-- * am I targeting an enemy
-- * do I have enough mana
--
-- Typically targeting an enemy is a signal that I want to *enter* combat.

if Faceroll == nil then
    _, Faceroll = ...
end

local spec = Faceroll.createSpec("CM", "00c7ee", "MAGE-CLASSIC")

spec.buffs = {
    "Ice Armor",
    "Arcane Intellect",
    "Drink",
    "Mana Shield",
}

local CONJURED_FOOD_NAME  = "Conjured Rye"
local CONJURED_WATER_NAME = "Conjured Spring Water"

-----------------------------------------------------------------------------------------
-- States

spec.states = {
    "- Combat -",
    "targetingenemy",
    "combat",
    "melee",
    "moving",
    "hold",
    "group",
    "channeling",

    "- Resources -",
    "hpL50",
    "manaL25",
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
    "foodLwater",

    "- Buffs -",
    "icearmor",
    "arcaneintellect",
    "manashield",

    "- Spells -",
    "coneofcold",
    "frostbolt",
    "blizzard",
}

spec.calcState = function(state)
    -- Combat --

    if Faceroll.targetingEnemy() then
        state.targetingenemy = true
    end

    if UnitAffectingCombat("player") then
        state.combat = true
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

    if IsInGroup() then
        state.group = true
    end

    local channelingSpell, _, _, _, channelEndMS = UnitChannelInfo("player")
    if channelingSpell then
        -- local channelFinish = channelEndMS/1000 - GetTime()
        state.channeling = true
    end

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
    if norMana < 0.25 then
        state.manaL25 = true
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
    if foodCount < waterCount then
        state.foodLwater = true
    end

    -- Buffs --

    if Faceroll.isBuffActive("Ice Armor") then
        state.icearmor = true
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
    if Faceroll.isBuffActive("Mana Shield") then
        state.manashield = true
    end

    -- Spells --

    if Faceroll.isSpellAvailable("Cone of Cold") then
        state.coneofcold = true
    end

    if Faceroll.hasManaForSpell("Frostbolt") then
        state.frostbolt = true
    end

    if Faceroll.hasManaForSpell("Blizzard") then
        state.blizzard = true
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
    "icearmor",
    "arcaneintellect",
    "frostbolt",
    "coneofcold",
    "shoot",
    "consume",
    "makefood",
    "makewater",
    "blizzard",
    "manashield",
}

spec.calcAction = function(mode, state)
    if mode == Faceroll.MODE_ST or mode == Faceroll.MODE_AOE then
        local makeForever = state.hold and (mode == Faceroll.MODE_AOE)

        if not state.combat and state.drink and state.drinkending and state.manaL80 then
            -- we're going to need to drink more to finish drinking
            return "consume"

        elseif not state.combat and state.drink and not state.manafull then
            -- wait for full mana
            return nil

        -- TODO: make this conditional significantly less ugly
        elseif not state.combat
           and (((state.hold and state.manaL25) or (not state.hold and (state.manaL50 or state.hpL50))) or (not state.hold and state.group and not state.manafull))
           and not state.waterL1
           and not state.drink
           and not state.moving
           and not state.targetingenemy
           then
            -- low on mana or hp, and we've given a second or two to loot
            return "consume"

        elseif not state.combat and not state.foodLwater and (makeForever or state.waterL1 or (state.hold and state.waterL100)) then
            -- we're either making one batch because we ran out, or we're doing
            -- a big prep because "hold" == "big prep"
            return "makewater"

        elseif not state.combat and (makeForever or state.foodL1 or (state.hold and state.foodL100)) then
            -- we're either making one batch because we ran out, or we're doing
            -- a big prep because "hold" == "big prep"
            return "makefood"

        elseif not state.combat and not state.icearmor then
            return "icearmor"

        elseif not state.combat and not state.arcaneintellect then
            return "arcaneintellect"

        elseif not state.combat and state.hold and not state.waterL100 and not state.manafull then
            -- we just finished preparing a big pile of water and buffs, top off
            return "consume"

        elseif not state.hold then
            -- combat

            if mode == Faceroll.MODE_ST then
                -- Single Target

                if state.targetingenemy then
                    if state.coneofcold and state.melee and not state.manaL25 and state.hpL50 then
                        -- hpL50 here is to take a hit or two while wanding for FSR
                        return "coneofcold"

                    elseif not state.group and state.melee and not state.manashield and not state.manaL25 then
                        return "manashield"

                    elseif (state.melee and not state.group and not state.manashield) or not state.frostbolt then
                        return "shoot"

                    else
                        return "frostbolt"
                    end
                end

            elseif mode == Faceroll.MODE_AOE then
                -- AOE

                if not state.channeling and (state.combat or state.targetingenemy) then
                    if state.blizzard then
                        return "blizzard"

                    elseif state.targetingenemy then
                        return "shoot"
                    end
                end
            end
        end
    end
    return nil
end
